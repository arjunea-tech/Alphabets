import React, { useEffect, useState } from 'react';
import { lettersApi } from '../api/letters';
import { Letter } from '../types';
import { Modal } from '../components/common/Modal';
import { FileUpload } from '../components/common/FileUpload';
import { useLanguage } from '../context/LanguageContext';
import { Edit2, Trash2, Plus, Search, Loader2, Volume2 } from 'lucide-react';
import { resolveMediaUrl } from '../api/client';

export const LettersPage: React.FC = () => {
  const { t } = useLanguage();
  const [letters, setLetters] = useState<Letter[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedType, setSelectedType] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [currentLetter, setCurrentLetter] = useState<Partial<Letter> | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
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

    const matchesType =
      selectedType === 'all' ||
      l.type.toLowerCase() === selectedType.toLowerCase();

    return matchesSearch && matchesType;
  });

  const handleOpenAdd = () => {
    setCurrentLetter({
      letter: '',
      type: (selectedType !== 'all' ? selectedType : 'consonant') as any,
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
    if (!window.confirm('Are you sure you want to delete this alphabet letter?')) return;
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

  const vowelCount = letters.filter((l) => l.type === 'vowel').length;
  const consonantCount = letters.filter((l) => l.type === 'consonant').length;

  return (
    <div>
      {/* Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h2>English Alphabets</h2>
          <p>Manage the 26 English Alphabet letters (A to Z), words, pronunciations and pictures</p>
        </div>
        <button onClick={handleOpenAdd} className="btn btn-primary">
          <Plus size={16} />
          <span>Add Letter</span>
        </button>
      </div>

      {/* Type Filter Tabs: All (26), Vowels (5), Consonants (21) */}
      <div className="tabs-header">
        <button
          className={`tab-btn ${selectedType === 'all' ? 'active' : ''}`}
          onClick={() => setSelectedType('all')}
        >
          All Alphabets ({letters.length || 26})
        </button>
        <button
          className={`tab-btn ${selectedType === 'vowel' ? 'active' : ''}`}
          onClick={() => setSelectedType('vowel')}
        >
          Vowels ({vowelCount || 5})
        </button>
        <button
          className={`tab-btn ${selectedType === 'consonant' ? 'active' : ''}`}
          onClick={() => setSelectedType('consonant')}
        >
          Consonants ({consonantCount || 21})
        </button>
      </div>

      {/* Toolbar with Search */}
      <div className="table-toolbar" style={{ background: 'white', borderRadius: 'var(--radius-lg)', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
        <div className="search-input" style={{ flex: 1, minWidth: '240px' }}>
          <Search size={16} color="#94A3B8" />
          <input
            type="text"
            placeholder="Search alphabet letter, word, or phonetic..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>

        <div style={{ fontSize: '14px', color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>
          Total Showing: <strong>{filteredLetters.length}</strong> of {letters.length}
        </div>
      </div>

      {/* Table */}
      <div className="table-wrapper" style={{ marginTop: 0 }}>
        <table>
          <thead>
            <tr>
              <th style={{ width: '60px' }}>#</th>
              <th>Letter</th>
              <th>Type</th>
              <th>Word</th>
              <th>Meaning</th>
              <th>Phonetic</th>
              <th>Image / Media</th>
              <th style={{ textAlign: 'right' }}>Actions</th>
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
                  No alphabet letters found.
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
                          fontSize: '22px',
                          fontWeight: 800,
                          width: '44px',
                          height: '44px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          background: item.type === 'vowel' ? '#FFF1F2' : 'var(--bg-muted)',
                          borderRadius: 'var(--radius-md)',
                          color: item.type === 'vowel' ? '#E11D48' : 'var(--primary)',
                          border: `1px solid ${item.type === 'vowel' ? '#FECDD3' : '#E2E8F0'}`,
                        }}
                      >
                        {item.letter}
                      </span>
                      <span style={{ fontSize: '20px' }}>{item.icon_emoji}</span>
                    </div>
                  </td>
                  <td>
                    <span
                      className="badge"
                      style={{
                        background: item.type === 'vowel' ? '#FFE4E6' : '#E0F2FE',
                        color: item.type === 'vowel' ? '#BE123C' : '#0369A1',
                        fontWeight: 700,
                        textTransform: 'uppercase',
                        letterSpacing: '0.5px',
                      }}
                    >
                      {item.type}
                    </span>
                  </td>
                  <td style={{ fontWeight: 700, fontSize: '15px' }}>{item.word}</td>
                  <td style={{ color: 'var(--text-muted)' }}>{item.meaning}</td>
                  <td>
                    <code style={{ background: 'var(--bg-muted)', padding: '3px 8px', borderRadius: '4px', fontSize: '14px', color: '#475569' }}>
                      {item.phonetic.startsWith('/') ? item.phonetic : `/${item.phonetic}/`}
                    </code>
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      {item.image_path ? (
                        <div
                          style={{
                            width: '40px',
                            height: '40px',
                            borderRadius: '6px',
                            overflow: 'hidden',
                            border: '1px solid var(--border-color)',
                            background: '#FFFFFF',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            padding: '2px',
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
                      <button onClick={() => handleOpenEdit(item)} className="btn btn-secondary btn-icon" title="Edit Letter">
                        <Edit2 size={14} />
                      </button>
                      <button onClick={() => handleDelete(item.id)} className="btn btn-danger btn-icon" title="Delete Letter">
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
        title={currentLetter?.id ? `Edit Letter '${currentLetter?.letter || ''}'` : 'Add Alphabet Letter'}
        maxWidth="650px"
      >
        <form onSubmit={handleSave}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">Letter (A-Z)</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. A"
                maxLength={2}
                value={currentLetter?.letter || ''}
                onChange={(e) => setCurrentLetter({ ...currentLetter, letter: e.target.value.toUpperCase() })}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">Letter Type</label>
              <select
                className="form-control"
                value={currentLetter?.type || 'consonant'}
                onChange={(e) => setCurrentLetter({ ...currentLetter, type: e.target.value as any })}
              >
                <option value="vowel">Vowel (A, E, I, O, U)</option>
                <option value="consonant">Consonant</option>
              </select>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">Sample Word</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. Apple"
                value={currentLetter?.word || ''}
                onChange={(e) => setCurrentLetter({ ...currentLetter, word: e.target.value })}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">Word Meaning</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. Sweet red fruit"
                value={currentLetter?.meaning || ''}
                onChange={(e) => setCurrentLetter({ ...currentLetter, meaning: e.target.value })}
                required
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">Phonetic Pronunciation</label>
              <input
                type="text"
                className="form-control"
                placeholder="e.g. /ˈæp.əl/"
                value={currentLetter?.phonetic || ''}
                onChange={(e) => setCurrentLetter({ ...currentLetter, phonetic: e.target.value })}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">Icon Emoji</label>
              <input
                type="text"
                className="form-control"
                placeholder="🍎"
                value={currentLetter?.icon_emoji || '⭐'}
                onChange={(e) => setCurrentLetter({ ...currentLetter, icon_emoji: e.target.value })}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Child Explanation & Sentence</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. A is for Apple. Sweet and crunchy!"
              value={currentLetter?.explanation || ''}
              onChange={(e) => setCurrentLetter({ ...currentLetter, explanation: e.target.value })}
            />
          </div>

          {/* Upload Audio and Image */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <FileUpload
              type="audio"
              label="Audio Pronunciation"
              currentValue={currentLetter?.audio_path}
              onUploaded={(path) => setCurrentLetter((prev) => (prev ? { ...prev, audio_path: path } : prev))}
              onClear={() => setCurrentLetter((prev) => (prev ? { ...prev, audio_path: null } : prev))}
            />
            <div>
              <FileUpload
                type="image"
                label="Alphabet Illustration Image"
                currentValue={currentLetter?.image_path}
                onUploaded={(path) => setCurrentLetter((prev) => (prev ? { ...prev, image_path: path } : prev))}
                onClear={() => setCurrentLetter((prev) => (prev ? { ...prev, image_path: null } : prev))}
              />
              <div className="form-group" style={{ marginTop: '8px' }}>
                <label className="form-label" style={{ fontSize: '12px', fontWeight: 600 }}>Image Asset Path or Cloudinary URL</label>
                <input
                  type="text"
                  className="form-control"
                  style={{ fontSize: '13px' }}
                  placeholder="assets/images/alphabets/apple.png or https://..."
                  value={currentLetter?.image_path || ''}
                  onChange={(e) => setCurrentLetter((prev) => (prev ? { ...prev, image_path: e.target.value } : prev))}
                />
              </div>
            </div>
          </div>

          {/* Optional Video File Upload */}
          <FileUpload
            type="video"
            label="🎥 Letter Teaching Video (Optional)"
            currentValue={currentLetter?.video_url}
            onUploaded={(path) => setCurrentLetter((prev) => (prev ? { ...prev, video_url: path } : prev))}
            onClear={() => setCurrentLetter((prev) => (prev ? { ...prev, video_url: null } : prev))}
          />

          <div className="modal-footer" style={{ margin: '20px -24px -24px', padding: '16px 24px' }}>
            <button type="button" onClick={() => setIsModalOpen(false)} className="btn btn-secondary">
              Cancel
            </button>
            <button type="submit" className="btn btn-primary" disabled={isSubmitting}>
              {isSubmitting ? 'Saving...' : 'Save Letter'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
