import React, { useEffect, useState } from 'react';
import { gamesApi } from '../api/games';
import { GameItem } from '../types';
import { Modal } from '../components/common/Modal';
import { useLanguage } from '../context/LanguageContext';
import { Plus, Edit2, Trash2, CheckCircle2, XCircle, Loader2 } from 'lucide-react';

export const GamesPage: React.FC = () => {
  const { t } = useLanguage();
  const [games, setGames] = useState<GameItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [currentGame, setCurrentGame] = useState<Partial<GameItem> | null>(null);
  const [optionsStr, setOptionsStr] = useState('அ, ஆ, இ, ஈ');
  const [isSubmitting, setIsSubmitting] = useState(false);

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
      game_type: 'puzzle',
      title: '',
      prompt: '',
      clue: '',
      correct_index: 0,
      options: ['அ', 'ஆ', 'இ', 'ஈ'],
      success_praise: 'சூப்பர்! ⭐',
      stars_reward: 3,
      display_order: games.length + 1,
      is_active: true,
    });
    setOptionsStr('அ, ஆ, இ, ஈ');
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

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th style={{ width: '60px' }}>{t('games.order')}</th>
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
                <td colSpan={9} style={{ textAlign: 'center', padding: '32px' }}>
                  <Loader2 className="spin" size={24} style={{ margin: '0 auto', color: 'var(--primary)' }} />
                </td>
              </tr>
            ) : games.length === 0 ? (
              <tr>
                <td colSpan={9} style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              games.map((g) => (
                <tr key={g.id}>
                  <td style={{ color: 'var(--text-muted)', fontWeight: 600 }}>{g.display_order}</td>
                  <td>
                    <span className="badge badge-secondary">{g.game_type.toUpperCase()}</span>
                  </td>
                  <td style={{ fontWeight: 700 }}>{g.title}</td>
                  <td style={{ fontSize: '14px' }}>{g.prompt}</td>
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
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Game Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={currentGame?.id ? t('games.editGame') : t('games.addGame')}
      >
        <form onSubmit={handleSave}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('games.gameType')}</label>
              <select
                className="form-control"
                value={currentGame?.game_type || 'puzzle'}
                onChange={(e) => setCurrentGame({ ...currentGame, game_type: e.target.value })}
              >
                <option value="puzzle">எழுத்துப் புதிர் (Puzzle)</option>
                <option value="balloon">பலூன் வெடிப்பு (Balloon Pop)</option>
                <option value="matching">பொருத்துதல் (Matching)</option>
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">{t('games.title')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. எழுத்துப் புதிர் 1"
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
              placeholder="e.g. அம்மா சொல்லின் முதல் எழுத்தைத் தொடுக!"
              value={currentGame?.prompt || ''}
              onChange={(e) => setCurrentGame({ ...currentGame, prompt: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">{t('games.options')} (Comma-separated)</label>
            <input
              type="text"
              className="form-control"
              placeholder="அ, ஆ, இ, ஈ"
              value={optionsStr}
              onChange={(e) => setOptionsStr(e.target.value)}
              required
            />
            <small style={{ color: 'var(--text-muted)', fontSize: '12px' }}>
              காற்புள்ளி (comma) மூலம் பிரித்து உள்ளிடவும். எ.கா: அ, ஆ, இ, ஈ
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

          <div className="form-group">
            <label className="form-label">{t('games.successPraise')}</label>
            <input
              type="text"
              className="form-control"
              placeholder="அற்புதம்! ⭐"
              value={currentGame?.success_praise || 'சூப்பர்! ⭐'}
              onChange={(e) => setCurrentGame({ ...currentGame, success_praise: e.target.value })}
            />
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
