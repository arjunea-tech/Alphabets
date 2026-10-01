import React, { useEffect, useState } from 'react';
import { videosApi } from '../api/videos';
import { VideoItem } from '../types';
import { Modal } from '../components/common/Modal';
import { FileUpload } from '../components/common/FileUpload';
import { useLanguage } from '../context/LanguageContext';
import { Plus, Edit2, Trash2, Play, Eye, Loader2, Video as VideoIcon, Sparkles } from 'lucide-react';

const MEDIA_BASE_URL = import.meta.env.VITE_MEDIA_BASE_URL || 'http://localhost:5000';
const resolveMediaUrl = (path?: string | null) => {
  if (!path) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  const clean = path.startsWith('/') ? path.slice(1) : path;
  return `${MEDIA_BASE_URL}/${clean}`;
};

export const VideosPage: React.FC = () => {
  const { t } = useLanguage();
  const [videos, setVideos] = useState<VideoItem[]>([]);
  const [loading, setLoading] = useState(true);
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

  const handleOpenAdd = () => {
    setCurrentVideo({
      title: '',
      description: '',
      category: 'பாடல்',
      duration: '03:00',
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

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentVideo?.title) {
      alert('காணொளி தலைப்பு அவசியம் (Title is required)');
      return;
    }
    if (!currentVideo?.video_url) {
      alert('தயவுசெய்து காணொளிக் கோப்பைத் தேர்ந்தெடுத்து பதிவேற்றவும் (Please upload a video file)');
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

  return (
    <div>
      <div className="page-header">
        <div className="page-title-group">
          <h2>{t('videos.pageTitle')}</h2>
          <p>{t('videos.pageSubtitle')}</p>
        </div>
        <button onClick={handleOpenAdd} className="btn btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
          <Plus size={16} />
          <span>{t('videos.addVideo')}</span>
        </button>
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
              <th>காணொளி (Video)</th>
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
            ) : videos.length === 0 ? (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              videos.map((vid) => (
                <tr key={vid.id}>
                  <td style={{ color: 'var(--text-muted)', fontWeight: 600 }}>{vid.display_order}</td>
                  <td style={{ fontSize: '24px' }}>{vid.thumbnail_emoji || '🎬'}</td>
                  <td>
                    <div style={{ fontWeight: 700, color: 'var(--text-dark, #1E293B)' }}>{vid.title}</div>
                    {vid.description && (
                      <div style={{ fontSize: '13px', color: 'var(--text-muted)' }}>{vid.description}</div>
                    )}
                  </td>
                  <td>
                    <span
                      className="badge"
                      style={{
                        background: vid.category === 'பாடல்' ? '#EDE9FE' : vid.category === 'கதை' ? '#FEF3C7' : '#E0F2FE',
                        color: vid.category === 'பாடல்' ? '#6D28D9' : vid.category === 'கதை' ? '#B45309' : '#0369A1',
                        fontWeight: 700,
                      }}
                    >
                      {vid.category}
                    </span>
                  </td>
                  <td style={{ fontSize: '13px', fontWeight: 600, color: 'var(--text-muted)' }}>{vid.duration || '03:00'}</td>
                  <td>
                    {vid.video_url ? (
                      <button
                        type="button"
                        onClick={() => setPreviewingVideo(vid)}
                        className="btn btn-secondary btn-sm"
                        style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', fontSize: '12px', fontWeight: 700, padding: '4px 10px', background: '#FAF5FF', borderColor: '#E9D5FF', color: '#7E22CE' }}
                        title="காணொளி முன்னோட்டம் (Play Preview)"
                      >
                        <Play size={12} fill="#7E22CE" />
                        <span>▶ Preview</span>
                      </button>
                    ) : (
                      <span style={{ color: 'var(--text-muted)', fontSize: '12px' }}>இல்லை</span>
                    )}
                  </td>
                  <td>
                    {vid.is_published ? (
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
                      <button
                        onClick={() => setPreviewingVideo(vid)}
                        className="btn btn-secondary btn-icon"
                        title="முன்னோட்டம் (Preview)"
                      >
                        <Eye size={14} />
                      </button>
                      <button onClick={() => handleOpenEdit(vid)} className="btn btn-secondary btn-icon" title={t('common.edit')}>
                        <Edit2 size={14} />
                      </button>
                      <button onClick={() => handleDelete(vid.id)} className="btn btn-danger btn-icon" title={t('common.delete')}>
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

      {/* Video Modal Form */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={currentVideo?.id ? t('videos.editVideo') : t('videos.addVideo')}
        maxWidth="620px"
      >
        <form onSubmit={handleSave}>
          <div className="form-group">
            <label className="form-label" style={{ fontWeight: 700 }}>
              {t('videos.title')} <span style={{ color: 'var(--danger)' }}>*</span>
            </label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. உயிர் எழுத்துகள் பாடல்"
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
              placeholder="e.g. அ முதல் ஔ வரையிலான குட்டிப் பாடல்"
              value={currentVideo?.description || ''}
              onChange={(e) => setCurrentVideo({ ...currentVideo, description: e.target.value })}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label" style={{ fontWeight: 700 }}>{t('videos.category')}</label>
              <select
                className="form-control"
                value={currentVideo?.category || 'பாடல்'}
                onChange={(e) => setCurrentVideo({ ...currentVideo, category: e.target.value })}
              >
                <option value="பாடல்">பாடல் (Song / Rhyme)</option>
                <option value="கதை">கதை (Story / Tale)</option>
                <option value="பாடம்">பாடம் (Lesson / Educational)</option>
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">{t('videos.duration')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="03:15"
                value={currentVideo?.duration || '03:00'}
                onChange={(e) => setCurrentVideo({ ...currentVideo, duration: e.target.value })}
              />
            </div>
          </div>

          {/* Actual Video File Upload */}
          <FileUpload
            type="video"
            label="🎥 காணொளி கோப்பு (Video File - MP4, WebM, MOV)"
            currentValue={currentVideo?.video_url}
            onUploaded={(path) => setCurrentVideo((prev) => (prev ? { ...prev, video_url: path } : prev))}
            onClear={() => setCurrentVideo((prev) => (prev ? { ...prev, video_url: '' } : prev))}
          />

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('videos.thumbnail')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="🎵"
                value={currentVideo?.thumbnail_emoji || '🎬'}
                onChange={(e) => setCurrentVideo({ ...currentVideo, thumbnail_emoji: e.target.value })}
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
                உங்கள் உலாவி காணொளியை ஆதரிக்கவில்லை (Your browser does not support HTML5 video).
              </video>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '6px' }}>
              <div>
                <span className="badge badge-secondary" style={{ marginRight: '8px' }}>
                  {previewingVideo.category}
                </span>
                <span style={{ fontSize: '13px', color: 'var(--text-muted)' }}>
                  கால அளவு: {previewingVideo.duration || '03:00'}
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
                மூடுக (Close)
              </button>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
};

