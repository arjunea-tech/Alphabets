import React, { useEffect, useState } from 'react';
import { lessonsApi } from '../api/lessons';
import { Lesson } from '../types';
import { Modal } from '../components/common/Modal';
import { useLanguage } from '../context/LanguageContext';
import { Edit2, Trash2, Plus, Loader2, CheckCircle2, XCircle } from 'lucide-react';

export const LessonsPage: React.FC = () => {
  const { t } = useLanguage();
  const [lessons, setLessons] = useState<Lesson[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [currentLesson, setCurrentLesson] = useState<Partial<Lesson> | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    fetchLessons();
  }, []);

  const fetchLessons = async () => {
    setLoading(true);
    try {
      const res = await lessonsApi.getAll(true);
      if (res.success && res.data) {
        setLessons(res.data);
      }
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  };

  const handleOpenAdd = () => {
    setCurrentLesson({
      category_key: '',
      title: '',
      subtitle: '',
      count_text: '',
      button_text: 'கற்கலாம்',
      icon_emoji: '⭐',
      display_order: lessons.length + 1,
      is_active: true,
    });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (lesson: Lesson) => {
    setCurrentLesson(lesson);
    setIsModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm(t('common.confirmDelete'))) {
      return;
    }
    try {
      await lessonsApi.delete(id);
      fetchLessons();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Delete failed');
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentLesson?.title || !currentLesson?.category_key) {
      alert('Required fields missing');
      return;
    }

    setIsSubmitting(true);
    try {
      if (currentLesson.id) {
        await lessonsApi.update(currentLesson.id, currentLesson);
      } else {
        await lessonsApi.create(currentLesson);
      }
      setIsModalOpen(false);
      fetchLessons();
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
          <h2>{t('lessons.pageTitle')}</h2>
          <p>{t('lessons.pageSubtitle')}</p>
        </div>
        <button onClick={handleOpenAdd} className="btn btn-primary">
          <Plus size={16} />
          <span>{t('lessons.addLesson')}</span>
        </button>
      </div>

      <div className="table-wrapper">
        <table>
          <thead>
            <tr>
              <th style={{ width: '60px' }}>{t('lessons.order')}</th>
              <th style={{ width: '60px' }}>{t('lessons.icon')}</th>
              <th>{t('lessons.title')}</th>
              <th>{t('lessons.subtitle')}</th>
              <th>{t('lessons.count')}</th>
              <th>{t('lessons.status')}</th>
              <th style={{ textAlign: 'right' }}>{t('lessons.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={7} style={{ textAlign: 'center', padding: '32px' }}>
                  <Loader2 className="spin" size={24} style={{ margin: '0 auto', color: 'var(--primary)' }} />
                </td>
              </tr>
            ) : lessons.length === 0 ? (
              <tr>
                <td colSpan={7} style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              lessons.map((lesson) => (
                <tr key={lesson.id}>
                  <td style={{ fontWeight: 700, color: 'var(--text-muted)', fontSize: '13px' }}>{lesson.display_order}</td>
                  <td style={{ fontSize: '20px' }}>{lesson.icon_emoji}</td>
                  <td>
                    <div style={{ fontWeight: 600, fontSize: '15px', color: 'var(--text-main)' }}>{lesson.title}</div>
                  </td>
                  <td>
                    <div style={{ color: 'var(--text-muted)', fontSize: '13.5px', lineHeight: 1.4 }}>{lesson.subtitle}</div>
                  </td>
                  <td>
                    <span className="badge badge-secondary">{lesson.count_text}</span>
                  </td>
                  <td>
                    {lesson.is_active ? (
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
                      <button onClick={() => handleOpenEdit(lesson)} className="btn btn-secondary btn-icon" title={t('common.edit')}>
                        <Edit2 size={14} />
                      </button>
                      <button onClick={() => handleDelete(lesson.id)} className="btn btn-danger btn-icon" title={t('common.delete')}>
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
        title={currentLesson?.id ? t('lessons.editLesson') : t('lessons.addLesson')}
      >
        <form onSubmit={handleSave}>
          <div className="form-group">
            <label className="form-label">{t('lessons.categoryKey')}</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. uyir, mei, reading"
              value={currentLesson?.category_key || ''}
              onChange={(e) => setCurrentLesson({ ...currentLesson, category_key: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">{t('lessons.title')}</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. உயிர் எழுத்துகள்"
              value={currentLesson?.title || ''}
              onChange={(e) => setCurrentLesson({ ...currentLesson, title: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">{t('lessons.subtitle')}</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. அ முதல் ஔ வரை"
              value={currentLesson?.subtitle || ''}
              onChange={(e) => setCurrentLesson({ ...currentLesson, subtitle: e.target.value })}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('lessons.icon')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="🍎"
                value={currentLesson?.icon_emoji || ''}
                onChange={(e) => setCurrentLesson({ ...currentLesson, icon_emoji: e.target.value })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">{t('lessons.count')}</label>
              <input
                type="text"
                className="form-control"
                placeholder="12 உயிர் எழுத்துகள்"
                value={currentLesson?.count_text || ''}
                onChange={(e) => setCurrentLesson({ ...currentLesson, count_text: e.target.value })}
              />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">{t('lessons.order')}</label>
              <input
                type="number"
                className="form-control"
                value={currentLesson?.display_order || 1}
                onChange={(e) => setCurrentLesson({ ...currentLesson, display_order: parseInt(e.target.value, 10) })}
              />
            </div>
            <div className="form-group">
              <label className="form-label">{t('lessons.status')}</label>
              <select
                className="form-control"
                value={currentLesson?.is_active ? '1' : '0'}
                onChange={(e) => setCurrentLesson({ ...currentLesson, is_active: e.target.value === '1' })}
              >
                <option value="1">{t('common.active')}</option>
                <option value="0">{t('common.inactive')}</option>
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
