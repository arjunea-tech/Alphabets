import React, { useEffect, useState } from 'react';
import { videosApi } from '../api/videos';
import { VideoItem } from '../types';
import { Modal } from '../components/common/Modal';
import { FileUpload } from '../components/common/FileUpload';
import { useLanguage } from '../context/LanguageContext';
import { Plus, Edit2, Trash2, Play, Eye, Loader2, Sparkles, Video as VideoIcon } from 'lucide-react';
import { resolveMediaUrl } from '../api/client';

const VOWEL_LETTERS = ['A', 'E', 'I', 'O', 'U'];
const CONSONANT_LETTERS = [
  'B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M',
  'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Y', 'Z'
];

export const VideosPage: React.FC = () => {
  const { t } = useLanguage();
  const [videos, setVideos] = useState<VideoItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedFilter, setSelectedFilter] = useState('all');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [currentVideo, setCurrentVideo] = useState<Partial<VideoItem> | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [previewingVideo, setPreviewingVideo] = useState<VideoItem | null>(null);

  useEffect(() => {
    fetchVideos();
  }, []);

  const fetchVideos = async () => {
    setLoading(true);
    try {
      const res = await videosApi.getAll({ all: true });
      if (res.success && res.data) {
        setVideos(res.data);
      }
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  };

  const handleOpenAdd = (defaultCat: string = 'Alphabet Song') => {
    setCurrentVideo({
      title: '',
      description: '',
      category: defaultCat,
      duration: '00:10',
      thumbnail_emoji: '🎬',
      video_url: '',
      display_order: videos.length + 1,
      is_published: true,
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (video: VideoItem) => {
    setCurrentVideo(video);
    setIsModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm(t('common.confirmDelete'))) return;
    try {
      await videosApi.delete(id);
      fetchVideos();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Delete failed');
    }
  };

  const handleQuickLetterPick = (letter: string, index: number) => {
    if (!currentVideo) return;
    setCurrentVideo({
      ...currentVideo,
      title: `Letter ${letter} Phonics Video`,
      thumbnail_emoji: `🎬${letter}`,
      display_order: index + 1,
    });
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentVideo?.title) {
      alert('Title is required');
      return;
    }
    if (!currentVideo?.video_url) {
      alert('Please upload a video file or provide a video URL');
      return;
    }

    setIsSubmitting(true);
    try {
      if (currentVideo.id) {
        await videosApi.update(currentVideo.id, currentVideo);
      } else {
        await videosApi.create(currentVideo);
      }
      setIsModalOpen(false);
      fetchVideos();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Save failed');
    } finally {
      setIsSubmitting(false);
    }
  };

  const vowelsCount = videos.filter((v) => v.category?.toLowerCase().includes('vowel') || VOWEL_LETTERS.some(l => v.title.includes(l))).length;
  const consonantsCount = videos.filter((v) => v.category?.toLowerCase().includes('consonant')).length;
  const songsCount = videos.filter((v) => v.category?.toLowerCase().includes('song')).length;
  const phonicsCount = videos.filter((v) => v.category?.toLowerCase().includes('phonic')).length;

  const filteredVideos = videos.filter((vid) => {
    if (selectedFilter === 'all') return true;
    if (selectedFilter === 'vowels') return vid.category?.toLowerCase().includes('vowel') || VOWEL_LETTERS.some(l => vid.title.includes(l));
    if (selectedFilter === 'consonants') return vid.category?.toLowerCase().includes('consonant');
    if (selectedFilter === 'song') return vid.category?.toLowerCase().includes('song');
    if (selectedFilter === 'phonics') return vid.category?.toLowerCase().includes('phonic');
    return true;
  });

  return (
    <div>
      <div className="page-header">
        <div className="page-title-group">
          <h2>{t('videos.pageTitle')}</h2>
          <p>Manage English 26 Alphabets (A-Z) phonics, songs, and animated learning videos</p>
        </div>
        <div style={{ display: 'flex', gap: '8px' }}>
          <button
            onClick={() => handleOpenAdd('Alphabet Song')}
            className="btn btn-primary"
            style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
          >
            <Plus size={16} />
            <span>+ {t('videos.addVideo')}</span>
          </button>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="tabs-header" style={{ marginBottom: '16px', display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
        <button
          className={`tab-btn ${selectedFilter === 'all' ? 'active' : ''}`}
          onClick={() => setSelectedFilter('all')}
        >
          All Videos ({videos.length})
        </button>
        <button
          className={`tab-btn ${selectedFilter === 'song' ? 'active' : ''}`}
          onClick={() => setSelectedFilter('song')}
        >
          🎵 Alphabet Songs ({songsCount})
        </button>
        <button
          className={`tab-btn ${selectedFilter === 'phonics' ? 'active' : ''}`}
          onClick={() => setSelectedFilter('phonics')}
        >
          🔤 Phonics & Sounds ({phonicsCount})
        </button>
        <button
          className={`tab-btn ${selectedFilter === 'vowels' ? 'active' : ''}`}
          onClick={() => setSelectedFilter('vowels')}
        >
          🅰️ Vowels (5) ({vowelsCount})
        </button>
        {consonantsCount > 0 && (
          <button
            className={`tab-btn ${selectedFilter === 'consonants' ? 'active' : ''}`}
            onClick={() => setSelectedFilter('consonants')}
          >
            ✍️ Consonants ({consonantsCount})
          </button>
        )}
      </div>

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th style={{ width: '60px' }}>{t('videos.order')}</th>
              <th>{t('videos.thumbnail')}</th>
              <th>{t('videos.title')}</th>
              <th>{t('videos.category')}</th>
              <th>{t('videos.duration')}</th>
              <th>Video</th>
              <th>{t('videos.status')}</th>
              <th style={{ textAlign: 'right' }}>{t('videos.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '32px' }}>
                  <Loader2 className="spin" size={24} style={{ margin: '0 auto', color: 'var(--primary)' }} />
                </td>
              </tr>
            ) : filteredVideos.length === 0 ? (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '40px 16px', color: 'var(--text-muted)' }}>
                  <div style={{ fontSize: '32px', marginBottom: '8px' }}>🎬</div>
                  <div style={{ fontWeight: 600, fontSize: '15px' }}>No videos found in this category</div>
                  <div style={{ marginTop: '8px' }}>
                    <button
                      onClick={() => handleOpenAdd('Alphabet Song')}
                      className="btn btn-primary btn-sm"
                      style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}
                    >
                      <Plus size={14} />
                      <span>Add New Video</span>
                    </button>
                  </div>
                </td>
              </tr>
            ) : (
              filteredVideos.map((vid) => (
                <tr key={vid.id}>
                  <td style={{ fontWeight: 600, color: 'var(--text-muted)' }}>
                    {vid.display_order}
                  </td>
                  <td>
                    <div
                      style={{
                        width: '42px',
                        height: '42px',
                        borderRadius: '10px',
                        background: 'linear-gradient(135deg, #EFF6FF, #DBEAFE)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '20px',
                        border: '1px solid #BFDBFE',
                      }}
                    >
                      {vid.thumbnail_emoji || '🎬'}
                    </div>
                  </td>
                  <td>
                    <div style={{ fontWeight: 700, color: 'var(--text-dark, #1E293B)', fontSize: '14px' }}>
                      {vid.title}
                    </div>
                    {vid.description && (
                      <div
                        style={{
                          fontSize: '12px',
                          color: 'var(--text-muted)',
                          maxWidth: '300px',
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                          whiteSpace: 'nowrap',
                          marginTop: '2px',
                        }}
                      >
                        {vid.description}
                      </div>
                    )}
                  </td>
                  <td>
                    <span className="badge badge-primary" style={{ fontSize: '11px' }}>
                      {vid.category}
                    </span>
                  </td>
                  <td>
                    <span style={{ fontSize: '13px', color: 'var(--text-muted)', fontFamily: 'monospace' }}>
                      ⏱️ {vid.duration || '00:10'}
                    </span>
                  </td>
                  <td>
                    {vid.video_url ? (
                      <button
                        onClick={() => setPreviewingVideo(vid)}
                        className="btn btn-sm btn-secondary"
                        style={{
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: '5px',
                          padding: '4px 10px',
                          fontSize: '12px',
                          fontWeight: 600,
                          color: 'var(--primary)',
                          borderColor: 'var(--primary)',
                        }}
                        title="Play Preview"
                      >
                        <Play size={13} fill="currentColor" />
                        <span>Play</span>
                      </button>
                    ) : (
                      <span style={{ color: 'var(--text-muted)', fontSize: '12px' }}>None</span>
                    )}
                  </td>
                  <td>
                    <span className={`badge ${vid.is_published ? 'badge-success' : 'badge-secondary'}`}>
                      {vid.is_published ? 'Published' : 'Draft'}
                    </span>
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <div style={{ display: 'inline-flex', gap: '6px' }}>
                      {vid.video_url && (
                        <button
                          onClick={() => setPreviewingVideo(vid)}
                          className="btn btn-secondary btn-sm"
                          style={{ padding: '6px', color: 'var(--primary)' }}
                          title="Preview Video"
                        >
                          <Eye size={14} />
                        </button>
                      )}
                      <button
                        onClick={() => handleOpenEdit(vid)}
                        className="btn btn-secondary btn-sm"
                        style={{ padding: '6px' }}
                        title="Edit"
                      >
                        <Edit2 size={14} />
                      </button>
                      <button
                        onClick={() => handleDelete(vid.id)}
                        className="btn btn-danger btn-sm"
                        style={{ padding: '6px' }}
                        title="Delete"
                      >
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

      {/* Add / Edit Video Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={currentVideo?.id ? t('videos.editVideo') : t('videos.addVideo')}
        maxWidth="640px"
      >
        <form onSubmit={handleSave}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label" style={{ fontWeight: 700 }}>
                {t('videos.category')} <span style={{ color: 'var(--danger)' }}>*</span>
              </label>
              <select
                className="form-control"
                value={currentVideo?.category || 'Alphabet Song'}
                onChange={(e) => setCurrentVideo({ ...currentVideo, category: e.target.value })}
              >
                <option value="Alphabet Song">🎵 Alphabet Song</option>
                <option value="Phonics & Rhymes">🔤 Phonics & Rhymes</option>
                <option value="Stories & Phonics">📖 Stories & Phonics</option>
                <option value="Vowels (A, E, I, O, U)">🅰️ Vowels (A, E, I, O, U)</option>
                <option value="Consonants (B-Z)">✍️ Consonants (B-Z)</option>
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">{t('videos.duration')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="00:10"
                value={currentVideo?.duration || '00:10'}
                onChange={(e) => setCurrentVideo({ ...currentVideo, duration: e.target.value })}
              />
            </div>
          </div>

          {/* Quick Letter Pickers for Vowels */}
          {currentVideo?.category === 'Vowels (A, E, I, O, U)' && (
            <div className="form-group" style={{ background: '#FDF2F8', padding: '12px', borderRadius: '12px', border: '1px solid #FBCFE8' }}>
              <label className="form-label" style={{ color: '#BE185D', fontWeight: 700, fontSize: '12px', marginBottom: '8px', display: 'block' }}>
                ⚡ Quick Vowel Picker (Click to autofill):
              </label>
              <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                {VOWEL_LETTERS.map((letter, idx) => (
                  <button
                    key={letter}
                    type="button"
                    onClick={() => handleQuickLetterPick(letter, idx)}
                    className="btn btn-sm"
                    style={{
                      background: currentVideo?.title?.includes(letter) ? '#DB2777' : 'white',
                      color: currentVideo?.title?.includes(letter) ? 'white' : '#BE185D',
                      borderColor: '#F472B6',
                      fontWeight: 700,
                      minWidth: '34px',
                      padding: '4px 8px',
                    }}
                  >
                    {letter}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Quick Letter Pickers for Consonants */}
          {currentVideo?.category === 'Consonants (B-Z)' && (
            <div className="form-group" style={{ background: '#EFF6FF', padding: '12px', borderRadius: '12px', border: '1px solid #BFDBFE' }}>
              <label className="form-label" style={{ color: '#1D4ED8', fontWeight: 700, fontSize: '12px', marginBottom: '8px', display: 'block' }}>
                ⚡ Quick Consonant Picker (Click to autofill):
              </label>
              <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                {CONSONANT_LETTERS.map((letter, idx) => (
                  <button
                    key={letter}
                    type="button"
                    onClick={() => handleQuickLetterPick(letter, idx)}
                    className="btn btn-sm"
                    style={{
                      background: currentVideo?.title?.includes(letter) ? '#2563EB' : 'white',
                      color: currentVideo?.title?.includes(letter) ? 'white' : '#1D4ED8',
                      borderColor: '#60A5FA',
                      fontWeight: 700,
                      minWidth: '34px',
                      padding: '4px 8px',
                    }}
                  >
                    {letter}
                  </button>
                ))}
              </div>
            </div>
          )}

          <div className="form-group">
            <label className="form-label" style={{ fontWeight: 700 }}>
              {t('videos.title')} <span style={{ color: 'var(--danger)' }}>*</span>
            </label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. ABC Phonics Song or Letter A Fun"
              value={currentVideo?.title || ''}
              onChange={(e) => setCurrentVideo({ ...currentVideo, title: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">{t('videos.description')}</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. Educational video song teaching 26 English Alphabets"
              value={currentVideo?.description || ''}
              onChange={(e) => setCurrentVideo({ ...currentVideo, description: e.target.value })}
            />
          </div>

          {/* Video File Upload */}
          <FileUpload
            type="video"
            label="🎥 Video File (MP4, WebM, MOV)"
            currentValue={currentVideo?.video_url}
            onUploaded={(path) => setCurrentVideo((prev) => (prev ? { ...prev, video_url: path } : prev))}
            onClear={() => setCurrentVideo((prev) => (prev ? { ...prev, video_url: '' } : prev))}
          />

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('videos.thumbnail')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="🎬"
                value={currentVideo?.thumbnail_emoji || '🎬'}
                onChange={(e) => setCurrentVideo({ ...currentVideo, thumbnail_emoji: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Order</label>
              <input
                type="number"
                className="form-control"
                value={currentVideo?.display_order || 1}
                onChange={(e) => setCurrentVideo({ ...currentVideo, display_order: parseInt(e.target.value) || 1 })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">{t('videos.status')}</label>
              <select
                className="form-control"
                value={currentVideo?.is_published ? '1' : '0'}
                onChange={(e) => setCurrentVideo({ ...currentVideo, is_published: e.target.value === '1' })}
              >
                <option value="1">{t('common.active')} (Published)</option>
                <option value="0">{t('common.inactive')} (Draft)</option>
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

      {/* Video Player Preview Modal */}
      {previewingVideo && (
        <Modal
          isOpen={true}
          onClose={() => setPreviewingVideo(null)}
          title={`▶ ${previewingVideo.title}`}
          maxWidth="640px"
        >
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <div style={{ borderRadius: '12px', overflow: 'hidden', background: '#000', boxShadow: '0 4px 16px rgba(0,0,0,0.2)' }}>
              <video
                controls
                autoPlay
                src={resolveMediaUrl(previewingVideo.video_url)}
                style={{ width: '100%', maxHeight: '360px', display: 'block' }}
              >
                Your browser does not support HTML5 video.
              </video>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '6px' }}>
              <div>
                <span className="badge badge-secondary" style={{ marginRight: '8px' }}>
                  {previewingVideo.category}
                </span>
                <span style={{ fontSize: '13px', color: 'var(--text-muted)' }}>
                  Duration: {previewingVideo.duration || '00:10'}
                </span>
              </div>
              <span className="badge badge-success">Status: Published</span>
            </div>
            {previewingVideo.description && (
              <p style={{ fontSize: '14px', color: 'var(--text-dark, #334155)', margin: 0 }}>
                {previewingVideo.description}
              </p>
            )}
            <div style={{ textAlign: 'right', marginTop: '12px' }}>
              <button
                type="button"
                onClick={() => setPreviewingVideo(null)}
                className="btn btn-secondary"
              >
                Close
              </button>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
};
