import React, { useEffect, useState } from 'react';
import { lettersApi } from '../api/letters';
import { Letter } from '../types';
import { Modal } from '../components/common/Modal';
import { FileUpload } from '../components/common/FileUpload';
import { useLanguage } from '../context/LanguageContext';
import { Edit2, Trash2, Plus, Search, Loader2, Volume2 } from 'lucide-react';

const MEDIA_BASE_URL = import.meta.env.VITE_MEDIA_BASE_URL || 'http://localhost:5000';
const resolveMediaUrl = (path?: string | null) => {
  if (!path) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  const clean = path.startsWith('/') ? path.slice(1) : path;
  return `${MEDIA_BASE_URL}/${clean}`;
};

const MEI_VARISAIS = [
  { mei: 'க்', title: 'க வரிசை (12)' },
  { mei: 'ங்', title: 'ங வரிசை (12)' },
  { mei: 'ச்', title: 'ச வரிசை (12)' },
  { mei: 'ஞ்', title: 'ஞ வரிசை (12)' },
  { mei: 'ட்', title: 'ட வரிசை (12)' },
  { mei: 'ண்', title: 'ண வரிசை (12)' },
  { mei: 'த்', title: 'த வரிசை (12)' },
  { mei: 'ந்', title: 'ந வரிசை (12)' },
  { mei: 'ப்', title: 'ப வரிசை (12)' },
  { mei: 'ம்', title: 'ம வரிசை (12)' },
  { mei: 'ய்', title: 'ய வரிசை (12)' },
  { mei: 'ர்', title: 'ர வரிசை (12)' },
  { mei: 'ல்', title: 'ல வரிசை (12)' },
  { mei: 'வ்', title: 'வ வரிசை (12)' },
  { mei: 'ழ்', title: 'ழ வரிசை (12)' },
  { mei: 'ள்', title: 'ள வரிசை (12)' },
  { mei: 'ற்', title: 'ற வரிசை (12)' },
  { mei: 'ன்', title: 'ன வரிசை (12)' },
];

export const LettersPage: React.FC = () => {
  const { t } = useLanguage();
  const [letters, setLetters] = useState<Letter[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedType, setSelectedType] = useState<string>('all');
  const [selectedVarisai, setSelectedVarisai] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [currentLetter, setCurrentLetter] = useState<Partial<Letter> | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    setSelectedVarisai('all');
    fetchLetters();
  }, [selectedType]);

  const fetchLetters = async () => {
    setLoading(true);
    try {
      const type = selectedType === 'all' ? undefined : selectedType;
      const res = await lettersApi.getAll({ type, all: true });
      if (res.success && res.data) {
        setLetters(res.data);
      }
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  };

  const filteredLetters = letters.filter((l) => {
    const matchesSearch =
      l.letter.toLowerCase().includes(searchQuery.toLowerCase()) ||
      l.word.toLowerCase().includes(searchQuery.toLowerCase()) ||
      l.meaning.toLowerCase().includes(searchQuery.toLowerCase()) ||
      l.phonetic.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesVarisai =
      selectedType !== 'uyirmei' ||
      selectedVarisai === 'all' ||
      l.mei_base === selectedVarisai;

    return matchesSearch && matchesVarisai;
  });

  const handleOpenAdd = () => {
    setCurrentLetter({
      letter: '',
      type: (selectedType !== 'all' ? selectedType : 'uyir') as any,
      word: '',
      meaning: '',
      phonetic: '',
      icon_emoji: '⭐',
      explanation: '',
      audio_path: null,
      image_path: null,
      video_url: null,
      display_order: letters.length + 1,
      is_active: true,
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (letter: Letter) => {
    setCurrentLetter(letter);
    setIsModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm(t('common.confirmDelete'))) return;
    try {
      await lettersApi.delete(id);
      fetchLetters();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Delete failed');
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentLetter?.letter || !currentLetter?.word || !currentLetter?.type) {
      alert('Letter, word and type are required');
      return;
    }

    setIsSubmitting(true);
    try {
      if (currentLetter.id) {
        await lettersApi.update(currentLetter.id, currentLetter);
      } else {
        await lettersApi.create(currentLetter);
      }
      setIsModalOpen(false);
      fetchLetters();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Save failed');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div>
      {/* Header */}
      {/* Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h2>{t('letters.pageTitle')}</h2>
          <p>{t('letters.pageSubtitle')}</p>
        </div>
        <button onClick={handleOpenAdd} className="btn btn-primary">
          <Plus size={16} />
          <span>{t('letters.addLetter')}</span>
        </button>
      </div>

      {/* Type Filter Tabs */}
      <div className="tabs-header">
        <button
          className={`tab-btn ${selectedType === 'all' ? 'active' : ''}`}
          onClick={() => setSelectedType('all')}
        >
          {t('letters.allLetters')}
        </button>
        <button
          className={`tab-btn ${selectedType === 'uyir' ? 'active' : ''}`}
          onClick={() => setSelectedType('uyir')}
        >
          {t('letters.uyir')} (12)
        </button>
        <button
          className={`tab-btn ${selectedType === 'mei' ? 'active' : ''}`}
          onClick={() => setSelectedType('mei')}
        >
          {t('letters.mei')} (18)
        </button>
        <button
          className={`tab-btn ${selectedType === 'aytham' ? 'active' : ''}`}
          onClick={() => setSelectedType('aytham')}
        >
          {t('letters.aytham')} (1)
        </button>
        <button
          className={`tab-btn ${selectedType === 'uyirmei' ? 'active' : ''}`}
          onClick={() => setSelectedType('uyirmei')}
        >
          {t('letters.uyirmei')} (216)
        </button>
      </div>

      {/* Toolbar with Search and Varisai Filter */}
      <div className="table-toolbar" style={{ background: 'white', borderRadius: 'var(--radius-lg)', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
        <div className="search-input" style={{ flex: 1, minWidth: '220px' }}>
          <Search size={16} color="#94A3B8" />
          <input
            type="text"
            placeholder={t('letters.searchPlaceholder')}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        {selectedType === 'uyirmei' && (
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '13px', fontWeight: 600, color: 'var(--text-muted)' }}>வரிசை:</span>
            <select
              className="form-control"
              style={{ width: '220px', fontWeight: 600 }}
              value={selectedVarisai}
              onChange={(e) => setSelectedVarisai(e.target.value)}
            >
              <option value="all">அனைத்து வரிசைகளும் (All 216)</option>
              {MEI_VARISAIS.map((v) => (
                <option key={v.mei} value={v.mei}>
                  {v.title}
                </option>
              ))}
            </select>
          </div>
        )}

        <div style={{ fontSize: '14px', color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>
          {t('common.total')}: <strong>{filteredLetters.length}</strong>
        </div>
      </div>

      {/* Table */}
      <div className="table-wrapper" style={{ marginTop: 0 }}>
        <table>
          <thead>
            <tr>
              <th style={{ width: '60px' }}>{t('letters.order')}</th>
              <th>{t('letters.letter')}</th>
              <th>{t('letters.type')}</th>
              <th>{t('letters.word')}</th>
              <th>{t('letters.meaning')}</th>
              <th>{t('letters.phonetic')}</th>
              <th>{t('letters.media')}</th>
              <th style={{ textAlign: 'right' }}>{t('letters.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '32px' }}>
                  <Loader2 className="spin" size={24} style={{ margin: '0 auto', color: 'var(--primary)' }} />
                </td>
              </tr>
            ) : filteredLetters.length === 0 ? (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              filteredLetters.map((item) => (
                <tr key={item.id}>
                  <td style={{ color: 'var(--text-muted)', fontWeight: 600 }}>{item.display_order}</td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                      <span
                        style={{
                          fontSize: '24px',
                          fontWeight: 800,
                          width: '46px',
                          height: '46px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          background: 'var(--bg-muted)',
                          borderRadius: 'var(--radius-md)',
                          color: 'var(--primary)',
                        }}
                      >
                        {item.letter}
                      </span>
                      <span style={{ fontSize: '20px' }}>{item.icon_emoji}</span>
                    </div>
                  </td>
                  <td>
                    <span className="badge badge-secondary">{item.type.toUpperCase()}</span>
                  </td>
                  <td style={{ fontWeight: 700 }}>{item.word}</td>
                  <td style={{ color: 'var(--text-muted)' }}>{item.meaning}</td>
                  <td>
                    <code style={{ background: 'var(--bg-muted)', padding: '3px 8px', borderRadius: '4px', fontSize: '14px' }}>
                      /{item.phonetic}/
                    </code>
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      {item.image_path ? (
                        <div
                          style={{
                            width: '38px',
                            height: '38px',
                            borderRadius: '6px',
                            overflow: 'hidden',
                            border: '1px solid var(--border-color)',
                            background: 'var(--bg-muted)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                          }}
                          title={item.image_path}
                        >
                          <img
                            src={resolveMediaUrl(item.image_path)}
                            alt={item.letter}
                            style={{ width: '100%', height: '100%', objectFit: 'contain' }}
                            onError={(e) => {
                              (e.target as HTMLElement).style.display = 'none';
                            }}
                          />
                        </div>
                      ) : (
                        <span style={{ color: '#CBD5E1', fontSize: '13px' }}>-</span>
                      )}
                      {item.audio_path && (
                        <span className="badge badge-success" style={{ gap: '4px' }}>
                          <Volume2 size={12} /> Audio
                        </span>
                      )}
                    </div>
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <div className="action-btn-group">
                      <button onClick={() => handleOpenEdit(item)} className="btn btn-secondary btn-icon" title={t('common.edit')}>
                        <Edit2 size={14} />
                      </button>
                      <button onClick={() => handleDelete(item.id)} className="btn btn-danger btn-icon" title={t('common.delete')}>
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

      {/* Add / Edit Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={currentLetter?.id ? t('letters.editLetter') : t('letters.addLetter')}
        maxWidth="650px"
      >
        <form onSubmit={handleSave}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('letters.letter')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. அ"
                value={currentLetter?.letter || ''}
                onChange={(e) => setCurrentLetter({ ...currentLetter, letter: e.target.value })}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">{t('letters.type')}</label>
              <select
                className="form-control"
                value={currentLetter?.type || 'uyir'}
                onChange={(e) => setCurrentLetter({ ...currentLetter, type: e.target.value as any })}
              >
                <option value="uyir">{t('letters.uyir')}</option>
                <option value="mei">{t('letters.mei')}</option>
                <option value="aytham">{t('letters.aytham')}</option>
                <option value="uyirmei">{t('letters.uyirmei')}</option>
              </select>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('letters.word')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. அம்மா"
                value={currentLetter?.word || ''}
                onChange={(e) => setCurrentLetter({ ...currentLetter, word: e.target.value })}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">{t('letters.meaning')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. Mother"
                value={currentLetter?.meaning || ''}
                onChange={(e) => setCurrentLetter({ ...currentLetter, meaning: e.target.value })}
                required
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('letters.phonetic')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. a"
                value={currentLetter?.phonetic || ''}
                onChange={(e) => setCurrentLetter({ ...currentLetter, phonetic: e.target.value })}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">{t('letters.icon')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="👩"
                value={currentLetter?.icon_emoji || '⭐'}
                onChange={(e) => setCurrentLetter({ ...currentLetter, icon_emoji: e.target.value })}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">{t('letters.explanation')}</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. அன்பான அம்மா"
              value={currentLetter?.explanation || ''}
              onChange={(e) => setCurrentLetter({ ...currentLetter, explanation: e.target.value })}
            />
          </div>

          {/* Upload Audio and Image */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <FileUpload
              type="audio"
              label={t('letters.audioFile')}
              currentValue={currentLetter?.audio_path}
              onUploaded={(path) => setCurrentLetter((prev) => (prev ? { ...prev, audio_path: path } : prev))}
              onClear={() => setCurrentLetter((prev) => (prev ? { ...prev, audio_path: null } : prev))}
            />
            <FileUpload
              type="image"
              label={t('letters.imageFile')}
              currentValue={currentLetter?.image_path}
              onUploaded={(path) => setCurrentLetter((prev) => (prev ? { ...prev, image_path: path } : prev))}
              onClear={() => setCurrentLetter((prev) => (prev ? { ...prev, image_path: null } : prev))}
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
