/**
 * Lessons Categories API Services
 */
import { apiClient } from './client';
import { ApiResponse, Lesson } from '../types';

export const lessonsApi = {
  getAll: async (all = true) => {
    const res = await apiClient.get<ApiResponse<Lesson[]>>('/lessons', {
      params: { all },
    });
    return res.data;
  },

  getById: async (id: string) => {
    const res = await apiClient.get<ApiResponse<Lesson>>(`/lessons/${id}`);
    return res.data;
  },

  create: async (data: Partial<Lesson>) => {
    const res = await apiClient.post<ApiResponse<Lesson>>('/admin/lessons', data);
    return res.data;
  },

  update: async (id: string, data: Partial<Lesson>) => {
    const res = await apiClient.put<ApiResponse<Lesson>>(`/admin/lessons/${id}`, data);
    return res.data;
  },

  delete: async (id: string) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/admin/lessons/${id}`);
    return res.data;
  },
};
