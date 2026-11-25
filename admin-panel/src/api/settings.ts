/**
 * App Settings API (content price shown on the app's unlock popup)
 */
import { apiClient } from './client';
import { ApiResponse } from '../types';

export interface PricingSettings {
  price_inr: number;
  currency: string;
}

export const settingsApi = {
  getPricing: async () => {
    const res = await apiClient.get<ApiResponse<PricingSettings>>('/admin/settings/pricing');
    return res.data;
  },

  updatePricing: async (price_inr: number) => {
    const res = await apiClient.put<ApiResponse<PricingSettings>>('/admin/settings/pricing', { price_inr });
    return res.data;
  },
};
