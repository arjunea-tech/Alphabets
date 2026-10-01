/**
 * Dashboard & Analytics API Services
 */
import { apiClient } from './client';
import { ApiResponse, DashboardStats, ChildUser, QuizResultRecord } from '../types';

export const dashboardApi = {
  getStats: async () => {
    const res = await apiClient.get<ApiResponse<DashboardStats>>('/admin/dashboard/stats');
    return res.data;
  },

  getUsers: async (params?: { limit?: number; offset?: number }) => {
    const res = await apiClient.get<ApiResponse<{ total: number; users: ChildUser[] }>>(
      '/admin/dashboard/users',
      { params }
    );
    return res.data;
  },

  getQuizResults: async (params?: { limit?: number; offset?: number }) => {
    const res = await apiClient.get<ApiResponse<QuizResultRecord[]>>(
      '/admin/dashboard/quiz-results',
      { params }
    );
    return res.data;
  },
};
