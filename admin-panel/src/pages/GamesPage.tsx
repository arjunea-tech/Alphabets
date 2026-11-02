import React, { useEffect, useState } from 'react';
import { gamesApi } from '../api/games';
import { GameItem } from '../types';
import { Modal } from '../components/common/Modal';
import { FileUpload } from '../components/common/FileUpload';
import { useLanguage } from '../context/LanguageContext';
import { Plus, Edit2, Trash2, CheckCircle2, XCircle, Loader2, Gamepad2, Image as ImageIcon } from 'lucide-react';
import { resolveMediaUrl } from '../api/client';

const GAME_TYPE_LABELS: Record<string, { label: string; shortLabel: string; color: string; bg: string }> = {
  runner: { label: '🏃 Alphabet Runner (2D Runner)', shortLabel: '🏃 Runner', color: '#16A34A', bg: '#DCFCE7' },
  candy: { label: '🍬 Candy Match (Match-3)', shortLabel: '🍬 Candy Match', color: '#DB2777', bg: '#FCE7F3' },
  fishing: { label: '🎣 Letter Fishing', shortLabel: '🎣 Fishing', color: '#0284C7', bg: '#E0F2FE' },
  basket: { label: '🧺 Letter Basket', shortLabel: '🧺 Basket', color: '#D97706', bg: '#FEF3C7' },
  racing: { label: '🚗 Alphabet Car Racing', shortLabel: '🚗 Racing', color: '#2563EB', bg: '#DBEAFE' },
  puzzle: { label: '🧩 Word Puzzle', shortLabel: '🧩 Puzzle', color: '#7C3AED', bg: '#EDE9FE' },
  balloon: { label: '🎈 Balloon Pop', shortLabel: '🎈 Balloon', color: '#DC2626', bg: '#FEE2E2' },
  matching: { label: '🔄 Letter Matching', shortLabel: '🔄 Matching', color: '#4B5563', bg: '#F3F4F6' },
};

export const GamesPage: React.FC = () => {
  const { t } = useLanguage();
  const [games, setGames] = useState<GameItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [currentGame, setCurrentGame] = useState<Partial<GameItem> | null>(null);
  const [optionsStr, setOptionsStr] = useState('A, B, C, D');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [selectedFilter, setSelectedFilter] = useState<string>('all');

  useEffect(() => {
    fetchGames();
  }, []);

  const fetchGames = async () => {
    setLoading(true);
    try {
      const res = await gamesApi.getAll({ all: true });
      if (res.success && res.data) {
        setGames(res.data);
      }
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  };

  const handleOpenAdd = () => {
    setCurrentGame({
      game_type: 'runner',
      title: '',
      prompt: '',
      clue: '',
      clue_image: '',
      correct_index: 0,
      options: ['A', 'B', 'C', 'D'],
      success_praise: 'Awesome! ⭐',
      stars_reward: 3,
      display_order: games.length + 1,
      is_active: true,
    });
    setOptionsStr('A, B, C, D');
    setIsModalOpen(true);
  };

  const handleOpenEdit = (game: GameItem) => {
    setCurrentGame(game);
    setOptionsStr(Array.isArray(game.options) ? game.options.join(', ') : '');
    setIsModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm(t('common.confirmDelete'))) return;
    try {
      await gamesApi.delete(id);
      fetchGames();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Delete failed');
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentGame?.title || !currentGame?.prompt) {
      alert('Title and prompt are required');
      return;
    }

    const opts = optionsStr
      .split(',')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    if (opts.length < 2) {
      alert('Please provide at least 2 options');
      return;
    }

    setIsSubmitting(true);
    try {
      const payload = {
        ...currentGame,
        options: opts,
      };

      if (currentGame.id) {
        await gamesApi.update(currentGame.id, payload);
      } else {
        await gamesApi.create(payload);
      }
      setIsModalOpen(false);
      fetchGames();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Save failed');
    } finally {
      setIsSubmitting(false);
    }
  };

  const filteredGames = selectedFilter === 'all'
    ? games
    : games.filter((g) => g.game_type === selectedFilter);

  const getMediaUrl = resolveMediaUrl;

  return (
    <div>
      <div className="page-header">
        <div className="page-title-group">
          <h2>{t('games.pageTitle')}</h2>
          <p>{t('games.pageSubtitle')}</p>
        </div>
        <button onClick={handleOpenAdd} className="btn btn-primary">
          <Plus size={16} />
          <span>{t('games.addGame')}</span>
        </button>
      </div>

      {/* Filter Tabs */}
      <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', marginBottom: '16px' }}>
        <button
          onClick={() => setSelectedFilter('all')}
          className={`btn btn-sm ${selectedFilter === 'all' ? 'btn-primary' : 'btn-secondary'}`}
        >
          All Games ({games.length})
        </button>
        {Object.entries(GAME_TYPE_LABELS).map(([key, info]) => {
          const count = games.filter((g) => g.game_type === key).length;
          if (count === 0 && selectedFilter !== key) return null;
          return (
            <button
              key={key}
              onClick={() => setSelectedFilter(key)}
              className={`btn btn-sm ${selectedFilter === key ? 'btn-primary' : 'btn-secondary'}`}
              style={{
                borderColor: selectedFilter === key ? undefined : info.color,
                color: selectedFilter === key ? undefined : info.color,
              }}
            >
              {info.shortLabel} ({count})
            </button>
          );
        })}
      </div>

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th style={{ width: '50px' }}>{t('games.order')}</th>
              <th style={{ width: '60px' }}>Image</th>
              <th>{t('games.gameType')}</th>
              <th>{t('games.title')}</th>
              <th>{t('games.prompt')}</th>
              <th>{t('games.options')}</th>
              <th>{t('games.correctAnswer')}</th>
              <th>{t('games.starsReward')}</th>
              <th>{t('games.status')}</th>
              <th style={{ textAlign: 'right' }}>{t('games.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={10} style={{ textAlign: 'center', padding: '32px' }}>
                  <Loader2 className="spin" size={24} style={{ margin: '0 auto', color: 'var(--primary)' }} />
                </td>
              </tr>
            ) : filteredGames.length === 0 ? (
              <tr>
                <td colSpan={10} style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              filteredGames.map((g) => {
                const typeInfo = GAME_TYPE_LABELS[g.game_type] || {
                  label: g.game_type,
                  color: 'var(--text-dark)',
                  bg: 'var(--bg-muted)',
                };

                return (
                  <tr key={g.id}>
                    <td style={{ color: 'var(--text-muted)', fontWeight: 600 }}>{g.display_order}</td>
                    <td>
                      {g.clue_image ? (
                        <img
                          src={getMediaUrl(g.clue_image)}
                          alt=""
                          style={{
                            width: '40px',
                            height: '40px',
                            borderRadius: '8px',
                            objectFit: 'cover',
                            border: '1px solid var(--border-color)',
                            background: 'white',
                          }}
                          onError={(e) => {
                            (e.target as HTMLElement).style.display = 'none';
                          }}
                        />
                      ) : (
                        <div
                          style={{
                            width: '40px',
                            height: '40px',
                            borderRadius: '8px',
                            background: typeInfo.bg,
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            color: typeInfo.color,
                          }}
                        >
                          <Gamepad2 size={20} />
                        </div>
                      )}
                    </td>
                    <td>
                      <span
                        style={{
                          padding: '4px 10px',
                          borderRadius: '12px',
                          fontSize: '12px',
                          fontWeight: 700,
                          color: typeInfo.color,
                          background: typeInfo.bg,
                          border: `1px solid ${typeInfo.color}33`,
                          display: 'inline-block',
                          whiteSpace: 'nowrap',
                        }}
                      >
                        {typeInfo.label}
                      </span>
                    </td>
                    <td>
                      <div style={{ fontWeight: 700, color: 'var(--text-dark)' }}>{g.title}</div>
                      {g.clue && (
                        <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>{g.clue}</div>
                      )}
                    </td>
                    <td style={{ fontSize: '14px', maxWidth: '220px' }}>{g.prompt}</td>
                    <td>
                      <div style={{ display: 'flex', gap: '4px', flexWrap: 'wrap' }}>
                        {Array.isArray(g.options) &&
                          g.options.map((opt, i) => (
                            <span
                              key={i}
                              style={{
                                padding: '2px 8px',
                                background: i === g.correct_index ? '#DCFCE7' : 'var(--bg-muted)',
                                border: `1px solid ${i === g.correct_index ? '#86EFAC' : 'var(--border-color)'}`,
                                borderRadius: '4px',
                                fontSize: '12px',
                                fontWeight: i === g.correct_index ? 700 : 400,
                              }}
                            >
                              {opt}
                            </span>
                          ))}
                      </div>
                    </td>
                    <td style={{ fontWeight: 700, color: 'var(--success)' }}>
                      {Array.isArray(g.options) ? g.options[g.correct_index] : ''}
                    </td>
                    <td style={{ color: '#EAB308', fontWeight: 700 }}>⭐ +{g.stars_reward}</td>
                    <td>
                      {g.is_active ? (
                        <span className="badge badge-success">
                          <span className="badge-dot" />
                          {t('common.active')}
                        </span>
                      ) : (
                        <span className="badge badge-danger">
                          <span className="badge-dot" />
                          {t('common.inactive')}
                        </span>
                      )}
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div className="action-btn-group">
                        <button onClick={() => handleOpenEdit(g)} className="btn btn-secondary btn-icon" title={t('common.edit')}>
                          <Edit2 size={14} />
                        </button>
                        <button onClick={() => handleDelete(g.id)} className="btn btn-danger btn-icon" title={t('common.delete')}>
                          <Trash2 size={14} />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Game Add / Edit Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={currentGame?.id ? t('games.editGame') : t('games.addGame')}
        maxWidth="680px"
      >
        <form onSubmit={handleSave}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('games.gameType')}</label>
              <select
                className="form-control"
                value={currentGame?.game_type || 'runner'}
                onChange={(e) => setCurrentGame({ ...currentGame, game_type: e.target.value })}
              >
                <option value="runner">🏃 Alphabet Runner (2D Runner Game)</option>
                <option value="candy">🍬 Candy Match (Match-3 Candy)</option>
                <option value="fishing">🎣 Letter Fishing</option>
                <option value="basket">🧺 Letter Basket</option>
                <option value="racing">🚗 Alphabet Car Racing</option>
                <option value="puzzle">🧩 Word Puzzle</option>
                <option value="balloon">🎈 Balloon Pop</option>
                <option value="matching">🔄 Letter Matching</option>
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">{t('games.title')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. Alphabet Runner"
                value={currentGame?.title || ''}
                onChange={(e) => setCurrentGame({ ...currentGame, title: e.target.value })}
                required
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">{t('games.prompt')}</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. Run and jump to collect letters!"
              value={currentGame?.prompt || ''}
              onChange={(e) => setCurrentGame({ ...currentGame, prompt: e.target.value })}
              required
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">Game Clue / Subtitle</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. Fun 2D Alphabet Runner"
                value={currentGame?.clue || ''}
                onChange={(e) => setCurrentGame({ ...currentGame, clue: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">{t('games.order')}</label>
              <input
                type="number"
                className="form-control"
                value={currentGame?.display_order || 1}
                onChange={(e) => setCurrentGame({ ...currentGame, display_order: parseInt(e.target.value, 10) })}
              />
            </div>
          </div>

          {/* Game Thumbnail / Clue Image Upload */}
          <div className="form-group">
            <FileUpload
              type="image"
              label="Game Image / Thumbnail"
              currentValue={currentGame?.clue_image}
              onUploaded={(path) => setCurrentGame({ ...currentGame, clue_image: path })}
            />
          </div>

          <div className="form-group">
            <label className="form-label">{t('games.options')} (Comma-separated)</label>
            <input
              type="text"
              className="form-control"
              placeholder="A, B, C, D"
              value={optionsStr}
              onChange={(e) => setOptionsStr(e.target.value)}
              required
            />
            <small style={{ color: 'var(--text-muted)', fontSize: '12px' }}>
              Separate choices with comma. E.g.: A, B, C, D
            </small>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('games.correctAnswer')} Index (0-indexed)</label>
              <input
                type="number"
                min="0"
                max="5"
                className="form-control"
                value={currentGame?.correct_index || 0}
                onChange={(e) => setCurrentGame({ ...currentGame, correct_index: parseInt(e.target.value, 10) })}
              />
              <small style={{ color: 'var(--text-muted)', fontSize: '12px' }}>First option = 0, Second = 1</small>
            </div>

            <div className="form-group">
              <label className="form-label">{t('games.starsReward')}</label>
              <input
                type="number"
                className="form-control"
                value={currentGame?.stars_reward || 3}
                onChange={(e) => setCurrentGame({ ...currentGame, stars_reward: parseInt(e.target.value, 10) })}
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('games.successPraise')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="Great Job! ⭐"
                value={currentGame?.success_praise || 'Awesome! ⭐'}
                onChange={(e) => setCurrentGame({ ...currentGame, success_praise: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">{t('games.status')}</label>
              <select
                className="form-control"
                value={currentGame?.is_active ? 'true' : 'false'}
                onChange={(e) => setCurrentGame({ ...currentGame, is_active: e.target.value === 'true' })}
              >
                <option value="true">{t('common.active')}</option>
                <option value="false">{t('common.inactive')}</option>
              </select>
            </div>
          </div>

          <div className="modal-footer" style={{ margin: '20px -24px -24px', padding: '16px 24px' }}>
            <button type="button" onClick={() => setIsModalOpen(false)} className="btn btn-secondary">
              {t('common.cancel')}
            </button>
            <button type="submit" className="btn btn-primary" disabled={isSubmitting}>
              {isSubmitting ? t('common.saving') : t('common.save')}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
