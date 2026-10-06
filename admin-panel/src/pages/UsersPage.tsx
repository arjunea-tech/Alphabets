import React, { useEffect, useState } from 'react';
import { dashboardApi } from '../api/dashboard';
import { ChildUser, QuizResultRecord } from '../types';
import { useLanguage } from '../context/LanguageContext';
import {
  Users,
  Award,
  Search,
  Star,
  Loader2,
  RefreshCw,
  X,
  UserCheck,
  UserX,
} from 'lucide-react';

export const UsersPage: React.FC = () => {
  const { t, language } = useLanguage();
  const [activeTab, setActiveTab] = useState<'users' | 'quizResults'>('users');
  const [users, setUsers] = useState<ChildUser[]>([]);
  const [quizResults, setQuizResults] = useState<QuizResultRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all');

  useEffect(() => {
    fetchData();
  }, [activeTab]);

  const fetchData = async () => {
    setLoading(true);
    try {
      if (activeTab === 'users') {
        const res = await dashboardApi.getUsers({ limit: 200 });
        if (res.success && res.data) {
          setUsers(res.data.users || []);
        }
      } else {
        const res = await dashboardApi.getQuizResults({ limit: 200 });
        if (res.success && res.data) {
          setQuizResults(res.data || []);
        }
      }
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  };

  const filteredUsers = users.filter((u) => {
    const nameMatch = u.child_name ? u.child_name.toLowerCase().includes(searchQuery.toLowerCase()) : false;
    const emailMatch = u.email ? u.email.toLowerCase().includes(searchQuery.toLowerCase()) : false;
    const idMatch = u.id ? u.id.toLowerCase().includes(searchQuery.toLowerCase()) : false;
    const matchesSearch = nameMatch || emailMatch || idMatch || searchQuery === '';

    const isActive = u.is_active === 1 || u.is_active === true || u.is_active === undefined;
    if (statusFilter === 'active') return matchesSearch && isActive;
    if (statusFilter === 'inactive') return matchesSearch && !isActive;
    return matchesSearch;
  });

  const filteredResults = quizResults.filter((r) => {
    const studentMatch = r.child_name ? r.child_name.toLowerCase().includes(searchQuery.toLowerCase()) : false;
    const titleMatch = r.quiz_title ? r.quiz_title.toLowerCase().includes(searchQuery.toLowerCase()) : false;
    return studentMatch || titleMatch || searchQuery === '';
  });

  return (
    <div>
      {/* Page Header */}
      <div className="page-header">
        <div className="page-title-group">
          <h2>{t('users.pageTitle')}</h2>
          <p>{t('users.pageSubtitle')}</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="tabs-header">
        <button
          className={`tab-btn ${activeTab === 'users' ? 'active' : ''}`}
          onClick={() => {
            setActiveTab('users');
            setSearchQuery('');
          }}
        >
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
            <Users size={16} /> {t('users.registeredLearners')} ({users.length})
          </span>
        </button>
        <button
          className={`tab-btn ${activeTab === 'quizResults' ? 'active' : ''}`}
          onClick={() => {
            setActiveTab('quizResults');
            setSearchQuery('');
          }}
        >
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
            <Award size={16} /> {t('users.quizResultsTab')} ({quizResults.length})
          </span>
        </button>
      </div>

      {/* Search & Filter Toolbar */}
      <div
        className="table-toolbar"
        style={{
          background: 'white',
          borderRadius: 'var(--radius-lg)',
          marginBottom: '16px',
          display: 'flex',
          gap: '12px',
          alignItems: 'center',
          flexWrap: 'wrap',
        }}
      >
        <div className="search-input" style={{ flex: 1, minWidth: '260px' }}>
          <Search size={16} color="#94A3B8" />
          <input
            type="text"
            placeholder={t('users.searchPlaceholder')}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#94A3B8', padding: '0 8px' }}
            >
              <X size={14} />
            </button>
          )}
        </div>

        {activeTab === 'users' && (
          <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
            <select
              className="form-control"
              style={{ width: 'auto', padding: '8px 12px', fontSize: '13px' }}
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as any)}
            >
              <option value="all">{language === 'ta' ? 'அனைத்து நிலைகள்' : 'All Status'}</option>
              <option value="active">{language === 'ta' ? 'நேரலை (Active)' : 'Active'}</option>
              <option value="inactive">{language === 'ta' ? 'முடக்கம் (Inactive)' : 'Inactive'}</option>
            </select>
          </div>
        )}

        <button
          onClick={fetchData}
          className="btn btn-secondary btn-sm"
          title={language === 'ta' ? 'புதுப்பி' : 'Refresh'}
        >
          <RefreshCw size={15} />
        </button>
      </div>

      {/* Table Content */}
      <div className="table-wrapper" style={{ marginTop: 0 }}>
        {activeTab === 'users' ? (
          <table>
            <thead>
              <tr>
                <th>{t('users.childName')}</th>
                <th>{t('users.userId')}</th>
                <th>{t('users.email')}</th>
                <th>{t('users.age')}</th>
                <th>{t('users.stars')}</th>
                <th>{t('users.quizzesTaken')}</th>
                <th>{t('users.status')}</th>
                <th>{t('users.joinedDate')}</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={8} style={{ textAlign: 'center', padding: '40px' }}>
                    <Loader2 className="spin" size={28} style={{ margin: '0 auto', color: 'var(--primary)' }} />
                  </td>
                </tr>
              ) : filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={8} style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
                    {t('users.empty')}
                  </td>
                </tr>
              ) : (
                filteredUsers.map((u) => {
                  const initial = (u.child_name || 'U').trim().charAt(0).toUpperCase();
                  const isActive = u.is_active === 1 || u.is_active === true || u.is_active === undefined;
                  return (
                    <tr key={u.id}>
                      {/* Student Name & Avatar */}
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                          <div
                            style={{
                              width: '36px',
                              height: '36px',
                              borderRadius: '50%',
                              background: 'linear-gradient(135deg, #FF6B6B, #FF8E53)',
                              color: 'white',
                              fontWeight: 800,
                              fontSize: '15px',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
                              flexShrink: 0,
                            }}
                          >
                            {initial}
                          </div>
                          <div>
                            <div style={{ fontWeight: 700, fontSize: '15px', color: 'var(--text-main)' }}>
                              {u.child_name}
                            </div>
                            <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
                              {u.email ? (
                                <span style={{ color: '#10B981', fontWeight: 600 }}>✓ {t('users.registeredUser')}</span>
                              ) : (
                                <span style={{ color: '#F59E0B' }}>• {t('users.guestUser')}</span>
                              )}
                            </div>
                          </div>
                        </div>
                      </td>

                      {/* User ID */}
                      <td>
                        <code
                          style={{
                            background: 'var(--bg-muted)',
                            padding: '3px 8px',
                            borderRadius: '4px',
                            fontSize: '12.5px',
                            color: 'var(--text-main)',
                            fontWeight: 600,
                          }}
                        >
                          {u.id}
                        </code>
                      </td>

                      {/* Email */}
                      <td style={{ fontSize: '14px' }}>
                        {u.email ? (
                          <span style={{ color: 'var(--primary)', fontWeight: 500 }}>{u.email}</span>
                        ) : (
                          <span style={{ color: 'var(--text-muted)', fontStyle: 'italic' }}>-</span>
                        )}
                      </td>

                      {/* Age */}
                      <td>
                        <span className="badge badge-secondary" style={{ fontSize: '13px' }}>
                          {u.age} {language === 'ta' ? 'வயது' : 'yrs'}
                        </span>
                      </td>

                      {/* Total Stars */}
                      <td>
                        <span
                          style={{
                            color: '#EAB308',
                            fontWeight: 800,
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: '4px',
                            fontSize: '14px',
                            background: '#FEFCE8',
                            padding: '4px 10px',
                            borderRadius: 'var(--radius-full)',
                            border: '1px solid #FEF08A',
                          }}
                        >
                          <Star size={14} fill="#EAB308" /> {u.total_stars} ⭐
                        </span>
                      </td>

                      {/* Quizzes Taken */}
                      <td>
                        <span
                          className="badge"
                          style={{
                            background: '#EFF6FF',
                            color: '#3B82F6',
                            border: '1px solid #BFDBFE',
                            fontSize: '13px',
                          }}
                        >
                          {u.total_quizzes_taken || 0} {language === 'ta' ? 'வினாடிகள்' : 'quizzes'}
                        </span>
                      </td>

                      {/* Status */}
                      <td>
                        {isActive ? (
                          <span className="badge badge-success" style={{ fontSize: '12px' }}>
                            <UserCheck size={12} style={{ marginRight: '3px' }} />
                            {language === 'ta' ? 'நேரலை' : 'Active'}
                          </span>
                        ) : (
                          <span className="badge badge-danger" style={{ fontSize: '12px' }}>
                            <UserX size={12} style={{ marginRight: '3px' }} />
                            {language === 'ta' ? 'முடக்கம்' : 'Inactive'}
                          </span>
                        )}
                      </td>

                      {/* Joined Date */}
                      <td style={{ color: 'var(--text-muted)', fontSize: '13px' }}>
                        {new Date(u.created_at).toLocaleDateString(language === 'ta' ? 'ta-IN' : 'en-US')}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        ) : (
          <table>
            <thead>
              <tr>
                <th style={{ width: '60px' }}>#ID</th>
                <th>{t('users.student')}</th>
                <th>{t('users.quizTitle')}</th>
                <th>{t('users.score')}</th>
                <th>{t('users.starsEarned')}</th>
                <th>{t('users.attemptDate')}</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '40px' }}>
                    <Loader2 className="spin" size={28} style={{ margin: '0 auto', color: 'var(--primary)' }} />
                  </td>
                </tr>
              ) : filteredResults.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '40px', color: 'var(--text-muted)' }}>
                    {t('common.noData')}
                  </td>
                </tr>
              ) : (
                filteredResults.map((r) => (
                  <tr key={r.id}>
                    <td style={{ color: 'var(--text-muted)', fontWeight: 600 }}>#{r.id}</td>
                    <td style={{ fontWeight: 700, fontSize: '15px' }}>{r.child_name || r.user_id}</td>
                    <td style={{ fontSize: '14px' }}>{r.quiz_title || r.quiz_id}</td>
                    <td>
                      <span className="badge badge-primary" style={{ fontSize: '13px' }}>
                        {r.score} / {r.total_questions} ({r.correct_answers} {language === 'ta' ? 'சரி' : 'correct'})
                      </span>
                    </td>
                    <td>
                      <span
                        style={{
                          color: '#EAB308',
                          fontWeight: 800,
                          fontSize: '14px',
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: '4px',
                        }}
                      >
                        ⭐ +{r.stars_earned}
                      </span>
                    </td>
                    <td style={{ color: 'var(--text-muted)', fontSize: '13.5px' }}>
                      {new Date(r.attempt_date).toLocaleString(language === 'ta' ? 'ta-IN' : 'en-US')}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};
