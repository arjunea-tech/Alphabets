/**
 * Admin Authentication API Services
 */
import { apiClient } from './client';
import { ApiResponse, AdminUser } from '../types';

export const authApi = {
  login: async (credentials: { username: string; password: string }) => {
    const res = await apiClient.post<ApiResponse<{ token: string; admin: AdminUser }>>(
      '/auth/admin/login',
      credentials
    );
    return res.data;
  },

  getProfile: async () => {
    const res = await apiClient.get<ApiResponse<AdminUser>>('/auth/admin/me');
    return res.data;
  },

  changePassword: async (passwords: { currentPassword: string; newPassword: string }) => {
    const res = await apiClient.post<ApiResponse<void>>(
      '/auth/admin/change-password',
      passwords
    );
    return res.data;
  },
};
