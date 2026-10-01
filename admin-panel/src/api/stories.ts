/**
 * Reading Stories API Services
 */
import { apiClient } from './client';
import { ApiResponse, ReadingStory, StoryPage } from '../types';

export const storiesApi = {
  getAll: async (all = true) => {
    const res = await apiClient.get<ApiResponse<ReadingStory[]>>('/stories', {
      params: { all },
    });
    return res.data;
  },

  getById: async (id: string) => {
    const res = await apiClient.get<ApiResponse<ReadingStory>>(`/stories/${id}`);
    return res.data;
  },

  create: async (data: Partial<ReadingStory> & { pages?: StoryPage[] }) => {
    const res = await apiClient.post<ApiResponse<ReadingStory>>('/admin/stories', data);
    return res.data;
  },

  update: async (id: string, data: Partial<ReadingStory>) => {
    const res = await apiClient.put<ApiResponse<ReadingStory>>(`/admin/stories/${id}`, data);
    return res.data;
  },

  delete: async (id: string) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/admin/stories/${id}`);
    return res.data;
  },

  addPage: async (storyId: string, pageData: Partial<StoryPage>) => {
    const res = await apiClient.post<ApiResponse<{ pageId: number; story: ReadingStory }>>(
      `/admin/stories/${storyId}/pages`,
      pageData
    );
    return res.data;
  },

  updatePage: async (storyId: string, pageId: number, pageData: Partial<StoryPage>) => {
    const res = await apiClient.put<ApiResponse<void>>(
      `/admin/stories/${storyId}/pages/${pageId}`,
      pageData
    );
    return res.data;
  },

  deletePage: async (storyId: string, pageId: number) => {
    const res = await apiClient.delete<ApiResponse<void>>(
      `/admin/stories/${storyId}/pages/${pageId}`
    );
    return res.data;
  },
};
