/**
 * Videos API Services
 */
import { apiClient } from './client';
import { ApiResponse, VideoItem } from '../types';

export const videosApi = {
  getAll: async (params?: { category?: string; all?: boolean }) => {
    const res = await apiClient.get<ApiResponse<VideoItem[]>>('/videos', {
      params: { all: true, ...params },
    });
    return res.data;
  },

  getById: async (id: string) => {
    const res = await apiClient.get<ApiResponse<VideoItem>>(`/videos/${id}`);
    return res.data;
  },

  create: async (data: Partial<VideoItem>) => {
    const res = await apiClient.post<ApiResponse<VideoItem>>('/admin/videos', data);
    return res.data;
  },

  update: async (id: string, data: Partial<VideoItem>) => {
    const res = await apiClient.put<ApiResponse<VideoItem>>(`/admin/videos/${id}`, data);
    return res.data;
  },

  delete: async (id: string) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/admin/videos/${id}`);
    return res.data;
  },
};
