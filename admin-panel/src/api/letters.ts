/**
 * Letters and Letter Groups API Services
 */
import { apiClient } from './client';
import { ApiResponse, Letter, LetterGroup } from '../types';

export const lettersApi = {
  getAll: async (params?: { type?: string; groupId?: string; all?: boolean }) => {
    const res = await apiClient.get<ApiResponse<Letter[]>>('/letters', {
      params: { all: true, ...params },
    });
    return res.data;
  },

  getById: async (id: string) => {
    const res = await apiClient.get<ApiResponse<Letter>>(`/letters/${id}`);
    return res.data;
  },

  getGroups: async (letterType?: string) => {
    const res = await apiClient.get<ApiResponse<LetterGroup[]>>('/letters/groups', {
      params: { letterType },
    });
    return res.data;
  },

  create: async (data: Partial<Letter>) => {
    const res = await apiClient.post<ApiResponse<Letter>>('/admin/letters', data);
    return res.data;
  },

  update: async (id: string, data: Partial<Letter>) => {
    const res = await apiClient.put<ApiResponse<Letter>>(`/admin/letters/${id}`, data);
    return res.data;
  },

  delete: async (id: string) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/admin/letters/${id}`);
    return res.data;
  },

  uploadVideo: async (id: string, file: File) => {
    const formData = new FormData();
    formData.append('video', file);
    const res = await apiClient.post<ApiResponse<{ letter: Letter; videoUrl: string; path: string }>>(
      `/admin/letters/${id}/video`,
      formData
    );
    return res.data;
  },

  deleteVideo: async (id: string) => {
    const res = await apiClient.delete<ApiResponse<Letter>>(`/admin/letters/${id}/video`);
    return res.data;
  },

  createGroup: async (data: Partial<LetterGroup>) => {
    const res = await apiClient.post<ApiResponse<LetterGroup>>('/admin/letters/groups', data);
    return res.data;
  },
};

