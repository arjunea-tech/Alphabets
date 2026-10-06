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

  getUsers: async (params?: { limit?: number; offset?: number; search?: string }) => {
    const res = await apiClient.get<ApiResponse<{ total: number; users: ChildUser[] }>>(
      '/admin/dashboard/users',
      { params }
    );
    return res.data;
  },

  createUser: async (data: { child_name: string; email?: string; password?: string; age?: number; avatar_asset?: string; total_stars?: number }) => {
    const res = await apiClient.post<ApiResponse<ChildUser>>('/admin/dashboard/users', data);
    return res.data;
  },

  updateUser: async (id: string, data: Partial<ChildUser> & { password?: string }) => {
    const res = await apiClient.put<ApiResponse<ChildUser>>(`/admin/dashboard/users/${id}`, data);
    return res.data;
  },

  deleteUser: async (id: string) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/admin/dashboard/users/${id}`);
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
