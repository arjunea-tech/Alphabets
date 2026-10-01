/**
 * Educational Games API Services
 */
import { apiClient } from './client';
import { ApiResponse, GameItem } from '../types';

export const gamesApi = {
  getAll: async (params?: { gameType?: string; all?: boolean }) => {
    const res = await apiClient.get<ApiResponse<GameItem[]>>('/games', {
      params: { all: true, ...params },
    });
    return res.data;
  },

  getById: async (id: string) => {
    const res = await apiClient.get<ApiResponse<GameItem>>(`/games/${id}`);
    return res.data;
  },

  create: async (data: Partial<GameItem>) => {
    const res = await apiClient.post<ApiResponse<GameItem>>('/admin/games', data);
    return res.data;
  },

  update: async (id: string, data: Partial<GameItem>) => {
    const res = await apiClient.put<ApiResponse<GameItem>>(`/admin/games/${id}`, data);
    return res.data;
  },

  delete: async (id: string) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/admin/games/${id}`);
    return res.data;
  },
};
