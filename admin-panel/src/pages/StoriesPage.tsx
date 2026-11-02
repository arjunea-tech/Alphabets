import React, { useEffect, useState } from 'react';
import { storiesApi } from '../api/stories';
import { ReadingStory, StoryPage } from '../types';
import { Modal } from '../components/common/Modal';
import { FileUpload } from '../components/common/FileUpload';
import { useLanguage } from '../context/LanguageContext';
import { Plus, Edit2, Trash2, Layers, CheckCircle2, XCircle, Loader2 } from 'lucide-react';
import { resolveMediaUrl } from '../api/client';

export const StoriesPage: React.FC = () => {
  const { t } = useLanguage();
  const [stories, setStories] = useState<ReadingStory[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [currentStory, setCurrentStory] = useState<Partial<ReadingStory> | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Pages Manager Modal
  const [selectedStoryForPages, setSelectedStoryForPages] = useState<ReadingStory | null>(null);
  const [isPageModalOpen, setIsPageModalOpen] = useState(false);
  const [newPage, setNewPage] = useState<Partial<StoryPage>>({
    pageNumber: 1,
    text: '',
    emojiIllustration: '🐰',
    characterName: '',
  });

  useEffect(() => {
    fetchStories();
  }, []);

  const fetchStories = async () => {
    setLoading(true);
    try {
      const res = await storiesApi.getAll(true);
      if (res.success && res.data) {
        setStories(res.data);
      }
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  };

  const handleOpenAdd = () => {
    setCurrentStory({
      title: '',
      subtitle: '',
      cover_emoji: '📖',
      cover_image: '',
      content: '',
      moral: '',
      display_order: stories.length + 1,
      is_published: true,
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (story: ReadingStory) => {
    setCurrentStory({
      ...story,
      content: story.content || '',
    });
    setIsModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm(t('common.confirmDelete'))) return;
    try {
      await storiesApi.delete(id);
      fetchStories();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Delete failed');
    }
  };

  const handleSaveStory = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentStory?.title) {
      alert('Title is required');
      return;
    }

    setIsSubmitting(true);
    try {
      if (currentStory.id) {
        await storiesApi.update(currentStory.id, currentStory);
      } else {
        await storiesApi.create(currentStory);
      }
      setIsModalOpen(false);
      fetchStories();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Save failed');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Manage Pages
  const handleOpenPages = async (story: ReadingStory) => {
    try {
      const res = await storiesApi.getById(story.id);
      if (res.success && res.data) {
        setSelectedStoryForPages(res.data);
        setNewPage({
          pageNumber: (res.data.pages?.length || 0) + 1,
          text: '',
          emojiIllustration: '🐰',
          characterName: '',
        });
        setIsPageModalOpen(true);
      }
    } catch (err: any) {
      alert(err.message || 'Failed to load story pages');
    }
  };

  const handleAddPage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedStoryForPages || !newPage.text) {
      alert('Page story text is required');
      return;
    }

    try {
      await storiesApi.addPage(selectedStoryForPages.id, newPage);
      const res = await storiesApi.getById(selectedStoryForPages.id);
      if (res.success && res.data) {
        setSelectedStoryForPages(res.data);
        setNewPage({
          pageNumber: (res.data.pages?.length || 0) + 1,
          text: '',
          emojiIllustration: '🐰',
          characterName: '',
        });
      }
      fetchStories();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to add page');
    }
  };

  const handleDeletePage = async (pageId?: number) => {
    if (!pageId || !selectedStoryForPages) return;
    if (!window.confirm(t('common.confirmDelete'))) return;
    try {
      await storiesApi.deletePage(selectedStoryForPages.id, pageId);
      const res = await storiesApi.getById(selectedStoryForPages.id);
      if (res.success && res.data) {
        setSelectedStoryForPages(res.data);
      }
      fetchStories();
    } catch (err: any) {
      alert(err.message || 'Failed to delete page');
    }
  };

  return (
    <div>
      <div className="page-header">
        <div className="page-title-group">
          <h2>{t('stories.pageTitle')}</h2>
          <p>{t('stories.pageSubtitle')}</p>
        </div>
        <button onClick={handleOpenAdd} className="btn btn-primary">
          <Plus size={16} />
          <span>{t('stories.addStory')}</span>
        </button>
      </div>

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th style={{ width: '60px' }}>{t('stories.order')}</th>
              <th>{t('stories.coverEmoji')}</th>
              <th>{t('stories.title')}</th>
              <th>{t('stories.subtitle')}</th>
              <th>{t('stories.pages')}</th>
              <th>{t('stories.moral')}</th>
              <th>{t('stories.status')}</th>
              <th style={{ textAlign: 'right' }}>{t('stories.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '32px' }}>
                  <Loader2 className="spin" size={24} style={{ margin: '0 auto', color: 'var(--primary)' }} />
                </td>
              </tr>
            ) : stories.length === 0 ? (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              stories.map((story) => (
                <tr key={story.id}>
                  <td style={{ color: 'var(--text-muted)', fontWeight: 600 }}>{story.display_order}</td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span style={{ fontSize: '24px' }}>{story.cover_emoji}</span>
                      {story.cover_image && (
                        <img
                          src={resolveMediaUrl(story.cover_image)}
                          alt=""
                          style={{ width: '36px', height: '36px', borderRadius: '4px', objectFit: 'cover' }}
                        />
                      )}
                    </div>
                  </td>
                  <td>
                    <div style={{ fontWeight: 700 }}>{story.title}</div>
                    {story.content && (
                      <div style={{ fontSize: '12px', color: 'var(--text-muted)', maxWidth: '250px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {story.content}
                      </div>
                    )}
                  </td>
                  <td style={{ color: 'var(--text-muted)', fontSize: '14px' }}>{story.subtitle}</td>
                  <td>
                    <button
                      onClick={() => handleOpenPages(story)}
                      className="btn btn-secondary btn-sm"
                      style={{ gap: '6px' }}
                    >
                      <Layers size={14} />
                      <span>{story.page_count || 0} {t('stories.pages')} ({t('stories.managePages')})</span>
                    </button>
                  </td>
                  <td>
                    <span style={{ fontSize: '13px', fontStyle: 'italic', color: 'var(--primary)' }}>
                      "{story.moral}"
                    </span>
                  </td>
                  <td>
                    {story.is_published ? (
                      <span className="badge badge-success">
                        <span className="badge-dot" />
                        {t('stories.published')}
                      </span>
                    ) : (
                      <span className="badge badge-danger">
                        <span className="badge-dot" />
                        {t('stories.draft')}
                      </span>
                    )}
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <div className="action-btn-group">
                      <button onClick={() => handleOpenEdit(story)} className="btn btn-secondary btn-icon" title={t('common.edit')}>
                        <Edit2 size={14} />
                      </button>
                      <button onClick={() => handleDelete(story.id)} className="btn btn-danger btn-icon" title={t('common.delete')}>
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

      {/* Story Add / Edit Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={currentStory?.id ? t('stories.editStory') : t('stories.addStory')}
        maxWidth="700px"
      >
        <form onSubmit={handleSaveStory}>
          <div className="form-group">
            <label className="form-label">{t('stories.title')}</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. The Hare and the Tortoise"
              value={currentStory?.title || ''}
              onChange={(e) => setCurrentStory({ ...currentStory, title: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">{t('stories.subtitle')}</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. Slow and steady wins the race"
              value={currentStory?.subtitle || ''}
              onChange={(e) => setCurrentStory({ ...currentStory, subtitle: e.target.value })}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('stories.coverEmoji')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="🐢"
                value={currentStory?.cover_emoji || '📖'}
                onChange={(e) => setCurrentStory({ ...currentStory, cover_emoji: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">{t('stories.order')}</label>
              <input
                type="number"
                className="form-control"
                value={currentStory?.display_order || 1}
                onChange={(e) => setCurrentStory({ ...currentStory, display_order: parseInt(e.target.value, 10) })}
              />
            </div>
          </div>

          {/* Cover Image Upload */}
          <div className="form-group">
            <FileUpload
              type="image"
              label={t('stories.coverImage')}
              currentValue={currentStory?.cover_image}
              onUploaded={(path) => setCurrentStory({ ...currentStory, cover_image: path })}
            />
          </div>

          {/* Story Content (Multi-paragraph) */}
          <div className="form-group">
            <label className="form-label">{t('stories.content')}</label>
            <textarea
              className="form-control"
              rows={6}
              placeholder={t('stories.contentPlaceholder')}
              value={currentStory?.content || ''}
              onChange={(e) => setCurrentStory({ ...currentStory, content: e.target.value })}
              style={{ lineHeight: 1.6, fontSize: '15px' }}
            />
            <span style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
              Enter the full story text in multiple paragraphs.
            </span>
          </div>

          <div className="form-group">
            <label className="form-label">{t('stories.moral')}</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. Slow and steady wins the race!"
              value={currentStory?.moral || ''}
              onChange={(e) => setCurrentStory({ ...currentStory, moral: e.target.value })}
            />
          </div>

          <div className="form-group">
            <label className="form-label">{t('stories.status')}</label>
            <select
              className="form-control"
              value={currentStory?.is_published ? '1' : '0'}
              onChange={(e) => setCurrentStory({ ...currentStory, is_published: e.target.value === '1' })}
            >
              <option value="1">{t('stories.published')}</option>
              <option value="0">{t('stories.draft')}</option>
            </select>
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

      {/* Pages Manager Modal */}
      <Modal
        isOpen={isPageModalOpen}
        onClose={() => setIsPageModalOpen(false)}
        title={`${t('stories.pages')}: ${selectedStoryForPages?.title || ''}`}
        maxWidth="750px"
      >
        <div>
          {/* Current Pages List */}
          <h4 style={{ fontSize: '16px', fontWeight: 700, marginBottom: '12px' }}>
            {t('stories.pages')} ({selectedStoryForPages?.pages?.length || 0})
          </h4>

          {selectedStoryForPages?.pages && selectedStoryForPages.pages.length > 0 ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', marginBottom: '24px' }}>
              {selectedStoryForPages.pages.map((p) => (
                <div
                  key={p.id}
                  style={{
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: '12px',
                    padding: '12px',
                    borderRadius: 'var(--radius-md)',
                    background: 'var(--bg-muted)',
                    border: '1px solid var(--border-color)',
                  }}
                >
                  <span style={{ fontWeight: 800, color: 'var(--primary)', minWidth: '24px' }}>#{p.pageNumber}</span>
                  <span style={{ fontSize: '20px' }}>{p.emojiIllustration}</span>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: 600, fontSize: '14px' }}>{p.characterName || 'Character'}</div>
                    <div style={{ fontSize: '14px', color: 'var(--text-main)', marginTop: '2px', lineHeight: 1.6 }}>{p.text}</div>
                  </div>
                  <button
                    onClick={() => handleDeletePage(p.id)}
                    className="btn btn-danger btn-sm"
                    style={{ padding: '4px 8px' }}
                    title={t('common.delete')}
                  >
                    <Trash2 size={12} />
                  </button>
                </div>
              ))}
            </div>
          ) : (
            <p style={{ color: 'var(--text-muted)', fontSize: '14px', marginBottom: '20px' }}>
              {t('common.noData')}
            </p>
          )}

          {/* Add Page Form */}
          <div style={{ borderTop: '2px dashed var(--border-color)', paddingTop: '16px' }}>
            <h4 style={{ fontSize: '15px', fontWeight: 700, marginBottom: '12px' }}>+ {t('stories.addPage')}</h4>
            <form onSubmit={handleAddPage}>
              <div style={{ display: 'grid', gridTemplateColumns: '100px 1fr 120px', gap: '10px' }}>
                <div className="form-group">
                  <label className="form-label">{t('stories.pageNumber')}</label>
                  <input
                    type="number"
                    className="form-control"
                    value={newPage.pageNumber || 1}
                    onChange={(e) => setNewPage({ ...newPage, pageNumber: parseInt(e.target.value, 10) })}
                    required
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">{t('stories.character')}</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Rabbit"
                    value={newPage.characterName || ''}
                    onChange={(e) => setNewPage({ ...newPage, characterName: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">{t('stories.emoji')}</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="🐇"
                    value={newPage.emojiIllustration || '🐰'}
                    onChange={(e) => setNewPage({ ...newPage, emojiIllustration: e.target.value })}
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">{t('stories.pageText')}</label>
                <textarea
                  className="form-control"
                  rows={3}
                  placeholder="Enter the story text for this page..."
                  value={newPage.text || ''}
                  onChange={(e) => setNewPage({ ...newPage, text: e.target.value })}
                  required
                />
              </div>

              <button type="submit" className="btn btn-primary btn-sm">
                <Plus size={14} />
                <span>{t('stories.addPage')}</span>
              </button>
            </form>
          </div>
        </div>
      </Modal>
    </div>
  );
};
