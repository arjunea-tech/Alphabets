import React, { useEffect, useMemo, useState } from 'react';
import { lettersApi } from '../api/letters';
import { Letter } from '../types';
import { Modal } from '../components/common/Modal';
import { FileUpload } from '../components/common/FileUpload';
import { useLanguage } from '../context/LanguageContext';
import { Loader2, Play, Trash2, UploadCloud, RefreshCw, CheckCircle2 } from 'lucide-react';
import { resolveMediaUrl } from '../api/client';

const A_TO_Z = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
const VOWELS = new Set(['A', 'E', 'I', 'O', 'U']);

type Filter = 'all' | 'with' | 'without';

/**
 * Videos page: one teaching video per English letter (A–Z).
 * The video is stored on the letter itself (letters.video_url), so it is the
 * same video shown in "Edit Letter" and in the app's letter screen + Videos tab.
 */
export const VideosPage: React.FC = () => {
  const { t } = useLanguage();
  const [letters, setLetters] = useState<Letter[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<Filter>('all');
  const [editing, setEditing] = useState<Letter | null>(null);
  const [pendingUrl, setPendingUrl] = useState<string>('');
  const [saving, setSaving] = useState(false);
  const [previewing, setPreviewing] = useState<Letter | null>(null);

  useEffect(() => {
    fetchLetters();
  }, []);

  const fetchLetters = async () => {
    setLoading(true);
    try {
      const res = await lettersApi.getAll({ all: true });
      if (res.success && res.data) setLetters(res.data);
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  };

  // Map each A–Z slot to its letter record (first match by letter character).
  const slots = useMemo(
    () =>
      A_TO_Z.map((ch) => ({
        ch,
        letter: letters.find((l) => l.letter?.trim().toUpperCase() === ch) || null,
      })),
    [letters]
  );

  const withVideo = slots.filter((s) => s.letter?.video_url).length;

  const visibleSlots = slots.filter((s) => {
    if (filter === 'with') return !!s.letter?.video_url;
    if (filter === 'without') return !s.letter?.video_url;
    return true;
  });

  const openUpload = (letter: Letter) => {
    setEditing(letter);
    setPendingUrl(letter.video_url || '');
  };

  const handleSave = async () => {
    if (!editing) return;
    if (!pendingUrl) {
      alert('Please upload a video file first');
      return;
    }
    setSaving(true);
    try {
      await lettersApi.update(editing.id, { video_url: pendingUrl });
      setEditing(null);
      fetchLetters();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Save failed');
    } finally {
      setSaving(false);
    }
  };

  const handleRemove = async (letter: Letter) => {
    if (!window.confirm(`Remove the video for letter ${letter.letter}?`)) return;
    try {
      await lettersApi.update(letter.id, { video_url: null });
      fetchLetters();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Remove failed');
    }
  };

  return (
    <div>
      <div className="page-header">
        <div className="page-title-group">
          <h2>{t('videos.pageTitle')}</h2>
          <p>One teaching video for each of the 26 English letters (A–Z). Videos appear in the app's Videos tab and on the letter screen.</p>
        </div>
      </div>

      <div className="tabs-header" style={{ marginBottom: '16px', display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
        <button className={`tab-btn ${filter === 'all' ? 'active' : ''}`} onClick={() => setFilter('all')}>
          All Letters (26)
        </button>
        <button className={`tab-btn ${filter === 'with' ? 'active' : ''}`} onClick={() => setFilter('with')}>
          With Video ({withVideo})
        </button>
        <button className={`tab-btn ${filter === 'without' ? 'active' : ''}`} onClick={() => setFilter('without')}>
          Missing Video ({26 - withVideo})
        </button>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '48px' }}>
          <Loader2 className="spin" size={28} style={{ color: 'var(--primary)' }} />
        </div>
      ) : (
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(190px, 1fr))',
            gap: '14px',
          }}
        >
          {visibleSlots.map(({ ch, letter }) => {
            const hasVideo = !!letter?.video_url;
            const isVowel = VOWELS.has(ch);
            return (
              <div
                key={ch}
                style={{
                  background: 'white',
                  borderRadius: '16px',
                  border: `1.5px solid ${hasVideo ? '#BBF7D0' : '#E2E8F0'}`,
                  padding: '14px',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '10px',
                  boxShadow: '0 2px 8px rgba(15,23,42,0.04)',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <div
                    style={{
                      width: '52px',
                      height: '52px',
                      borderRadius: '14px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '26px',
                      fontWeight: 900,
                      background: isVowel ? '#FFE4E6' : '#E0F2FE',
                      color: isVowel ? '#BE123C' : '#0369A1',
                      flexShrink: 0,
                    }}
                  >
                    {ch}
                  </div>
                  <div style={{ minWidth: 0 }}>
                    <div style={{ fontWeight: 700, fontSize: '14px', color: 'var(--text-dark, #1E293B)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                      {letter ? `${letter.icon_emoji || ''} ${letter.word || ''}`.trim() || `Letter ${ch}` : `Letter ${ch}`}
                    </div>
                    {hasVideo ? (
                      <span className="badge badge-success" style={{ fontSize: '11px', display: 'inline-flex', alignItems: 'center', gap: '4px', marginTop: '4px' }}>
                        <CheckCircle2 size={11} /> Video added
                      </span>
                    ) : (
                      <span className="badge badge-secondary" style={{ fontSize: '11px', marginTop: '4px', display: 'inline-block' }}>
                        No video
                      </span>
                    )}
                  </div>
                </div>

                {!letter ? (
                  <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
                    Letter {ch} is not set up yet. Add it from the Alphabets page first.
                  </div>
                ) : hasVideo ? (
                  <div style={{ display: 'flex', gap: '6px' }}>
                    <button
                      className="btn btn-sm btn-secondary"
                      style={{ flex: 1, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: '4px', color: 'var(--primary)' }}
                      onClick={() => setPreviewing(letter)}
                      title="Play"
                    >
                      <Play size={13} fill="currentColor" /> Play
                    </button>
                    <button
                      className="btn btn-sm btn-secondary"
                      style={{ padding: '6px' }}
                      onClick={() => openUpload(letter)}
                      title="Replace video"
                    >
                      <RefreshCw size={14} />
                    </button>
                    <button
                      className="btn btn-sm btn-danger"
                      style={{ padding: '6px' }}
                      onClick={() => handleRemove(letter)}
                      title="Remove video"
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                ) : (
                  <button
                    className="btn btn-sm btn-primary"
                    style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: '6px' }}
                    onClick={() => openUpload(letter)}
                  >
                    <UploadCloud size={14} /> Add Video
                  </button>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* Upload / Replace modal */}
      {editing && (
        <Modal isOpen={true} onClose={() => setEditing(null)} title={`Video for Letter '${editing.letter}'`} maxWidth="640px">
          <FileUpload
            type="video"
            label={`🎥 Letter ${editing.letter} Video (MP4, WebM, MOV)`}
            currentValue={pendingUrl}
            onUploaded={(url) => setPendingUrl(url)}
            onClear={() => setPendingUrl('')}
          />
          <div className="modal-footer" style={{ margin: '20px -24px -24px', padding: '16px 24px' }}>
            <button type="button" onClick={() => setEditing(null)} className="btn btn-secondary">
              {t('common.cancel')}
            </button>
            <button type="button" onClick={handleSave} className="btn btn-primary" disabled={saving || !pendingUrl}>
              {saving ? t('common.saving') : t('common.save')}
            </button>
          </div>
        </Modal>
      )}

      {/* Preview modal */}
      {previewing && (
        <Modal isOpen={true} onClose={() => setPreviewing(null)} title={`▶ Letter ${previewing.letter} – ${previewing.word || ''}`} maxWidth="640px">
          <div style={{ borderRadius: '12px', overflow: 'hidden', background: '#000' }}>
            <video
              controls
              autoPlay
              src={resolveMediaUrl(previewing.video_url || '')}
              style={{ width: '100%', maxHeight: '360px', display: 'block' }}
            >
              Your browser does not support HTML5 video.
            </video>
          </div>
          <div style={{ textAlign: 'right', marginTop: '12px' }}>
            <button type="button" onClick={() => setPreviewing(null)} className="btn btn-secondary">
              Close
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
};
