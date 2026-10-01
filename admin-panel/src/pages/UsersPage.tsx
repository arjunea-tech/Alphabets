import React, { useEffect, useState } from 'react';
import { dashboardApi } from '../api/dashboard';
import { ChildUser, QuizResultRecord } from '../types';
import { useLanguage } from '../context/LanguageContext';
import { Users, Award, Search, Star, Loader2 } from 'lucide-react';

export const UsersPage: React.FC = () => {
  const { t, language } = useLanguage();
  const [activeTab, setActiveTab] = useState<'users' | 'quizResults'>('users');
  const [users, setUsers] = useState<ChildUser[]>([]);
  const [quizResults, setQuizResults] = useState<QuizResultRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    fetchData();
  }, [activeTab]);

  const fetchData = async () => {
    setLoading(true);
    try {
      if (activeTab === 'users') {
        const res = await dashboardApi.getUsers({ limit: 100 });
        if (res.success && res.data) {
          setUsers(res.data.users);
        }
      } else {
        const res = await dashboardApi.getQuizResults({ limit: 100 });
        if (res.success && res.data) {
          setQuizResults(res.data);
        }
      }
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  };

  const filteredUsers = users.filter(
    (u) =>
      u.child_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (u.email && u.email.toLowerCase().includes(searchQuery.toLowerCase())) ||
      u.id.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredResults = quizResults.filter(
    (r) =>
      (r.child_name && r.child_name.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (r.quiz_title && r.quiz_title.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  return (
    <div>
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

      {/* Search Toolbar */}
      <div className="table-toolbar" style={{ background: 'white', borderRadius: 'var(--radius-lg)', marginBottom: '16px' }}>
        <div className="search-input">
          <Search size={16} color="#94A3B8" />
          <input
            type="text"
            placeholder={t('letters.searchPlaceholder')}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
      </div>

      {/* Table */}
      <div className="table-wrapper" style={{ marginTop: 0 }}>
        {activeTab === 'users' ? (
          <table>
            <thead>
              <tr>
                <th>{t('users.userId')}</th>
                <th>{t('users.childName')}</th>
                <th>{t('users.email')}</th>
                <th>{t('users.age')}</th>
                <th>{t('users.avatar')}</th>
                <th>{t('users.stars')}</th>
                <th>{t('users.joinedDate')}</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={7} style={{ textAlign: 'center', padding: '32px' }}>
                    <Loader2 className="spin" size={24} style={{ margin: '0 auto', color: 'var(--primary)' }} />
                  </td>
                </tr>
              ) : filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={7} style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                    {t('common.noData')}
                  </td>
                </tr>
              ) : (
                filteredUsers.map((u) => (
                  <tr key={u.id}>
                    <td>
                      <code style={{ background: 'var(--bg-muted)', padding: '3px 8px', borderRadius: '4px', fontSize: '13px' }}>
                        {u.id}
                      </code>
                    </td>
                    <td style={{ fontWeight: 700, fontSize: '15px' }}>{u.child_name}</td>
                    <td style={{ fontSize: '14px', color: 'var(--text-main)', fontWeight: 500 }}>
                      {u.email ? (
                        <span style={{ color: 'var(--primary)' }}>{u.email}</span>
                      ) : (
                        <span style={{ color: 'var(--text-muted)' }}>-</span>
                      )}
                    </td>
                    <td>{u.age} {language === 'ta' ? 'வயது' : 'years'}</td>
                    <td>
                      <span className="badge badge-secondary">{u.avatar_asset}</span>
                    </td>
                    <td>
                      <span style={{ color: '#EAB308', fontWeight: 800, display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                        <Star size={14} fill="#EAB308" /> {u.total_stars} ⭐
                      </span>
                    </td>
                    <td style={{ color: 'var(--text-muted)', fontSize: '14px' }}>
                      {new Date(u.created_at).toLocaleDateString(language === 'ta' ? 'ta-IN' : 'en-US')}
                    </td>
                  </tr>
                ))
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
                  <td colSpan={6} style={{ textAlign: 'center', padding: '32px' }}>
                    <Loader2 className="spin" size={24} style={{ margin: '0 auto', color: 'var(--primary)' }} />
                  </td>
                </tr>
              ) : filteredResults.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '32px', color: 'var(--text-muted)' }}>
                    {t('common.noData')}
                  </td>
                </tr>
              ) : (
                filteredResults.map((r) => (
                  <tr key={r.id}>
                    <td style={{ color: 'var(--text-muted)', fontWeight: 600 }}>#{r.id}</td>
                    <td style={{ fontWeight: 700 }}>{r.child_name || r.user_id}</td>
                    <td>{r.quiz_title || r.quiz_id}</td>
                    <td>
                      <span className="badge badge-primary">
                        {r.score} / {r.total_questions} ({r.correct_answers} {language === 'ta' ? 'சரி' : 'correct'})
                      </span>
                    </td>
                    <td>
                      <span style={{ color: '#EAB308', fontWeight: 800 }}>⭐ +{r.stars_earned}</span>
                    </td>
                    <td style={{ color: 'var(--text-muted)', fontSize: '14px' }}>
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
