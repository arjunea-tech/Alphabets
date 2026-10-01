/**
 * Media Upload API Service
 */
import { apiClient } from './client';
import { ApiResponse } from '../types';

export interface UploadResult {
  filename: string;
  path: string;
  url: string;
  mimetype: string;
  size: number;
}

export const uploadApi = {
  uploadImage: async (file: File, onProgress?: (percent: number) => void) => {
    const formData = new FormData();
    formData.append('image', file);
    const res = await apiClient.post<ApiResponse<UploadResult>>('/admin/upload/image', formData, {
      onUploadProgress: (progressEvent) => {
        if (progressEvent.total && onProgress) {
          const percent = Math.round((progressEvent.loaded * 100) / progressEvent.total);
          onProgress(percent);
        }
      },
    });
    return res.data;
  },

  uploadAudio: async (file: File, onProgress?: (percent: number) => void) => {
    const formData = new FormData();
    formData.append('audio', file);
    const res = await apiClient.post<ApiResponse<UploadResult>>('/admin/upload/audio', formData, {
      onUploadProgress: (progressEvent) => {
        if (progressEvent.total && onProgress) {
          const percent = Math.round((progressEvent.loaded * 100) / progressEvent.total);
          onProgress(percent);
        }
      },
    });
    return res.data;
  },

  uploadVideo: async (file: File, onProgress?: (percent: number) => void) => {
    const formData = new FormData();
    formData.append('video', file);
    const res = await apiClient.post<ApiResponse<UploadResult>>('/admin/upload/video', formData, {
      onUploadProgress: (progressEvent) => {
        if (progressEvent.total && onProgress) {
          const percent = Math.round((progressEvent.loaded * 100) / progressEvent.total);
          onProgress(percent);
        }
      },
    });
    return res.data;
  },
};
