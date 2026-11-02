import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { dashboardApi } from '../api/dashboard';
import { DashboardStats } from '../types';
import { StatCard } from '../components/common/StatCard';
import { useLanguage } from '../context/LanguageContext';
import { useAuth } from '../context/AuthContext';
import {
  Users,
  GraduationCap,
  BookOpen,
  Library,
  Video,
  HelpCircle,
  Star,
  Award,
  Loader2,
  AlertCircle,
  PlusCircle,
} from 'lucide-react';

export const DashboardPage: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { t, language } = useLanguage();
  const { admin } = useAuth();

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await dashboardApi.getStats();
      if (res.success && res.data) {
        setStats(res.data);
      }
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || t('dash_load_error'));
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '320px', gap: '12px' }}>
        <Loader2 size={30} className="spin" color="var(--primary)" />
        <span style={{ fontSize: '16px', color: 'var(--text-muted)' }}>{t('loading')}</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="card" style={{ textAlign: 'center', padding: '40px', background: 'var(--danger-light)', borderColor: 'var(--danger)' }}>
        <AlertCircle size={38} color="var(--danger)" style={{ margin: '0 auto 12px' }} />
        <h3 style={{ color: 'var(--danger)', marginBottom: '8px' }}>{error}</h3>
        <button onClick={fetchStats} className="btn btn-primary btn-sm">{t('retry')}</button>
      </div>
    );
  }

  const s = stats?.summary;
  const locale = language === 'ta' ? 'ta-IN' : 'en-US';
  const adminDisplayName = admin?.fullName || admin?.full_name || admin?.username || ('Administrator');
  const welcomeGreeting = `Welcome, ${adminDisplayName}! 👋`;

  return (
    <div>
      {/* Welcome Banner */}
      <div
        style={{
          background: 'linear-gradient(135deg, #1E293B, #0F172A)',
          borderRadius: 'var(--radius-lg)',
          padding: '20px 24px',
          color: 'white',
          marginBottom: '20px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: '14px',
          boxShadow: 'var(--shadow-sm)',
        }}
      >
        <div>
          <h2 style={{ fontSize: '22px', fontWeight: 700, marginBottom: '4px' }}>
            {welcomeGreeting}
          </h2>
          <p style={{ color: '#CBD5E1', fontSize: '14px' }}>
            {t('dash_welcome_desc')}
          </p>
        </div>
        <div style={{ display: 'flex', gap: '12px' }}>
          <Link to="/letters" className="btn btn-primary">
            <PlusCircle size={17} />
            <span>{t('dash_add_letter_quick')}</span>
          </Link>
          <Link
            to="/quizzes"
            className="btn btn-secondary"
            style={{ background: 'rgba(255,255,255,0.12)', color: 'white', borderColor: 'transparent' }}
          >
            <span>{t('dash_quiz_quick')}</span>
          </Link>
        </div>
      </div>

      {/* KPI Stats Grid */}
      <div className="stats-grid">
        <StatCard
          label={t('dash_total_users')}
          value={s?.totalUsers || 0}
          icon={<Users size={26} />}
          color="#3B82F6"
          bgLight="#EFF6FF"
        />
        <StatCard
          label={t('dash_total_lessons')}
          value={s?.totalLessons || 0}
          icon={<GraduationCap size={26} />}
          color="#10B981"
          bgLight="#ECFDF5"
        />
        <StatCard
          label={t('dash_total_letters')}
          value={s?.totalLetters || 0}
          icon={<BookOpen size={26} />}
          color="#FF5A5F"
          bgLight="#FFF0F0"
        />
        <StatCard
          label={t('dash_total_stories')}
          value={s?.totalStories || 0}
          icon={<Library size={26} />}
          color="#F59E0B"
          bgLight="#FFFBEB"
        />
        <StatCard
          label={t('dash_total_videos')}
          value={s?.totalVideos || 0}
          icon={<Video size={26} />}
          color="#8B5CF6"
          bgLight="#F5F3FF"
        />
        <StatCard
          label={t('dash_total_quizzes')}
          value={s?.totalQuizzes || 0}
          icon={<HelpCircle size={26} />}
          color="#EC4899"
          bgLight="#FDF2F8"
        />
        <StatCard
          label={t('dash_total_attempts')}
          value={s?.totalQuizAttempts || 0}
          icon={<Award size={26} />}
          color="#6366F1"
          bgLight="#EEF2FF"
        />
        <StatCard
          label={t('dash_total_stars')}
          value={s?.totalStarsAwarded || 0}
          icon={<Star size={26} />}
          color="#EAB308"
          bgLight="#FEFCE8"
        />
      </div>

      {/* Recent Quiz Attempts Table */}
      <div className="card" style={{ marginTop: '24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '18px', flexWrap: 'wrap', gap: '12px' }}>
          <div>
            <h3 style={{ fontSize: '19px', fontWeight: 700 }}>{t('dash_recent_activity_title')}</h3>
            <p style={{ fontSize: '13px', color: 'var(--text-muted)' }}>{t('dash_recent_activity_desc')}</p>
          </div>
          <Link to="/users" className="btn btn-secondary btn-sm">{t('view_all')}</Link>
        </div>

        <div className="table-wrapper" style={{ margin: 0 }}>
          <table>
            <thead>
              <tr>
                <th>{t('dash_th_student')}</th>
                <th>{t('dash_th_quiz')}</th>
                <th>{t('dash_th_score')}</th>
                <th>{t('dash_th_stars')}</th>
                <th>{t('dash_th_date')}</th>
              </tr>
            </thead>
            <tbody>
              {stats?.recentQuizAttempts && stats.recentQuizAttempts.length > 0 ? (
                stats.recentQuizAttempts.map((att) => (
                  <tr key={att.id}>
                    <td style={{ fontWeight: 600, fontSize: '15px' }}>{att.child_name}</td>
                    <td style={{ fontSize: '15px' }}>{att.quiz_title}</td>
                    <td>
                      <span className="badge badge-primary" style={{ fontSize: '13px' }}>
                        {att.score} / {att.total_questions}
                      </span>
                    </td>
                    <td>
                      <span style={{ color: '#EAB308', fontWeight: 800, display: 'inline-flex', alignItems: 'center', gap: '4px', fontSize: '14px' }}>
                        ⭐ +{att.stars_earned}
                      </span>
                    </td>
                    <td style={{ color: 'var(--text-muted)', fontSize: '14px' }}>
                      {new Date(att.attempt_date).toLocaleString(locale)}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={5} style={{ textAlign: 'center', padding: '36px', color: 'var(--text-muted)', fontSize: '15px' }}>
                    {t('dash_no_activity')}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
