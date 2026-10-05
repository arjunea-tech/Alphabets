/**
 * Media Upload API Service
 * Implements Option 2: Direct signed upload from browser to Cloudinary
 * with automatic fallback to Backend stream upload.
 */
import axios from 'axios';
import { apiClient } from './client';
import { ApiResponse } from '../types';

export interface UploadResult {
  filename: string;
  path: string;
  url: string;
  mimetype: string;
  size: number;
  publicId?: string;
  duration?: number;
}

interface CloudinarySignatureResponse {
  timestamp: number;
  signature: string;
  apiKey: string;
  cloudName: string;
  folder: string;
  uploadUrl: string;
}

/**
 * Direct upload helper to Cloudinary using signed parameters
 */
async function uploadDirectToCloudinary(
  file: File,
  resourceType: 'image' | 'video' | 'auto',
  folderSuffix: string,
  onProgress?: (percent: number) => void
): Promise<UploadResult> {
  // 1. Get upload signature from backend
  const sigRes = await apiClient.get<ApiResponse<CloudinarySignatureResponse>>(
    `/admin/upload/signature?resourceType=${resourceType}&folder=agaram_media/${folderSuffix}`
  );

  if (!sigRes.data?.success || !sigRes.data?.data) {
    throw new Error('Failed to obtain Cloudinary upload signature from backend');
  }

  const { timestamp, signature, apiKey, cloudName, folder, uploadUrl } = sigRes.data.data;

  // 2. Prepare FormData for Cloudinary Direct Upload
  const formData = new FormData();
  formData.append('file', file);
  formData.append('api_key', apiKey);
  formData.append('timestamp', timestamp.toString());
  formData.append('signature', signature);
  formData.append('folder', folder);

  const targetUrl =
    uploadUrl ||
    `https://api.cloudinary.com/v1_1/${cloudName}/${resourceType === 'video' ? 'video' : 'auto'}/upload`;

  // 3. Post directly to Cloudinary (using clean axios without app authorization headers)
  const cldResponse = await axios.post(targetUrl, formData, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
    onUploadProgress: (progressEvent) => {
      if (progressEvent.total && onProgress) {
        const percent = Math.round((progressEvent.loaded * 100) / progressEvent.total);
        onProgress(percent);
      }
    },
  });

  const data = cldResponse.data;
  return {
    filename: file.name,
    path: data.secure_url,
    url: data.secure_url,
    publicId: data.public_id,
    mimetype: file.type,
    size: data.bytes || file.size,
    duration: data.duration,
  };
}

export const uploadApi = {
  uploadImage: async (file: File, onProgress?: (percent: number) => void): Promise<ApiResponse<UploadResult>> => {
    try {
      // Try Option 2 (Direct Signed Cloudinary Upload)
      const result = await uploadDirectToCloudinary(file, 'image', 'images', onProgress);
      return {
        success: true,
        message: 'Image uploaded directly to Cloudinary',
        data: result,
      };
    } catch (directErr) {
      console.warn('Cloudinary direct upload failed, falling back to backend stream:', directErr);
      // Fallback: Backend upload
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
    }
  },

  uploadAudio: async (file: File, onProgress?: (percent: number) => void): Promise<ApiResponse<UploadResult>> => {
    try {
      // Cloudinary handles audio files under 'video' resource type
      const result = await uploadDirectToCloudinary(file, 'video', 'audio', onProgress);
      return {
        success: true,
        message: 'Audio uploaded directly to Cloudinary',
        data: result,
      };
    } catch (directErr) {
      console.warn('Cloudinary direct audio upload fallback:', directErr);
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
    }
  },

  uploadVideo: async (file: File, onProgress?: (percent: number) => void): Promise<ApiResponse<UploadResult>> => {
    try {
      // Option 2 (Direct Signed Cloudinary Upload for Videos)
      const result = await uploadDirectToCloudinary(file, 'video', 'videos', onProgress);
      return {
        success: true,
        message: 'Video uploaded directly to Cloudinary',
        data: result,
      };
    } catch (directErr) {
      console.warn('Cloudinary direct video upload failed, falling back to backend stream:', directErr);
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
    }
  },
};
