/**
 * Quizzes API Services
 */
import { apiClient } from './client';
import { ApiResponse, Quiz, QuizQuestion } from '../types';

export const quizzesApi = {
  getAll: async (params?: { category?: string; all?: boolean }) => {
    const res = await apiClient.get<ApiResponse<Quiz[]>>('/quizzes', {
      params: { all: true, ...params },
    });
    return res.data;
  },

  getById: async (id: string, includeAnswers = true) => {
    const res = await apiClient.get<ApiResponse<Quiz>>(`/quizzes/${id}`, {
      params: { includeAnswers },
    });
    return res.data;
  },

  create: async (data: Partial<Quiz>) => {
    const res = await apiClient.post<ApiResponse<Quiz>>('/admin/quizzes', data);
    return res.data;
  },

  update: async (id: string, data: Partial<Quiz>) => {
    const res = await apiClient.put<ApiResponse<Quiz>>(`/admin/quizzes/${id}`, data);
    return res.data;
  },

  delete: async (id: string) => {
    const res = await apiClient.delete<ApiResponse<void>>(`/admin/quizzes/${id}`);
    return res.data;
  },

  addQuestion: async (quizId: string, questionData: Partial<QuizQuestion>) => {
    const res = await apiClient.post<ApiResponse<{ questionId: string; quiz: Quiz }>>(
      `/admin/quizzes/${quizId}/questions`,
      questionData
    );
    return res.data;
  },

  deleteQuestion: async (quizId: string, questionId: string) => {
    const res = await apiClient.delete<ApiResponse<void>>(
      `/admin/quizzes/${quizId}/questions/${questionId}`
    );
    return res.data;
  },
};
