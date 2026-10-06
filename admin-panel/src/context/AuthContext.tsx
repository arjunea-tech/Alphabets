/**
 * Authentication Context & State Management
 */
import React, { createContext, useContext, useState, useEffect } from 'react';
import { AdminUser } from '../types';
import { authApi } from '../api/auth';

interface AuthContextType {
  admin: AdminUser | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (credentials: { username: string; password: string }) => Promise<void>;
  logout: () => void;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const normalizeAdmin = (data: any): AdminUser | null => {
  if (!data) return null;
  const fullName = data.fullName || data.full_name || data.username || 'Admin';
  return {
    ...data,
    id: data.id,
    username: data.username || data.email || 'admin',
    email: data.email || '',
    fullName: fullName,
    full_name: fullName,
    role: data.role || 'content_admin',
    is_active: data.is_active !== undefined ? data.is_active : true,
  };
};

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [admin, setAdmin] = useState<AdminUser | null>(() => {
    const savedUser = localStorage.getItem('agaram_admin_user');
    if (savedUser) {
      try {
        return normalizeAdmin(JSON.parse(savedUser));
      } catch {
        return null;
      }
    }
    return null;
  });
  const [token, setToken] = useState<string | null>(localStorage.getItem('agaram_admin_token'));
  const [isLoading, setIsLoading] = useState<boolean>(true);

  // Initialize auth state from localStorage and verify with backend
  useEffect(() => {
    const initAuth = async () => {
      const savedToken = localStorage.getItem('agaram_admin_token');
      const savedUser = localStorage.getItem('agaram_admin_user');

      if (savedToken) {
        setToken(savedToken);
        if (savedUser) {
          try {
            setAdmin(normalizeAdmin(JSON.parse(savedUser)));
          } catch {
            // ignore
          }
        }
        // Verify with /me
        try {
          const res = await authApi.getProfile();
          if (res.success && res.data) {
            const normalized = normalizeAdmin(res.data);
            setAdmin(normalized);
            localStorage.setItem('agaram_admin_user', JSON.stringify(normalized));
          }
        } catch {
          // Token expired or invalid
          logout();
        }
      }
      setIsLoading(false);
    };

    initAuth();
  }, []);

  const login = async (credentials: { username: string; password: string }) => {
    const res = await authApi.login(credentials);
    if (res.success && res.data) {
      const normalized = normalizeAdmin(res.data.admin);
      setToken(res.data.token);
      setAdmin(normalized);
      localStorage.setItem('agaram_admin_token', res.data.token);
      localStorage.setItem('agaram_admin_user', JSON.stringify(normalized));
    } else {
      throw new Error(res.message || 'Login failed');
    }
  };

  const logout = () => {
    setToken(null);
    setAdmin(null);
    localStorage.removeItem('agaram_admin_token');
    localStorage.removeItem('agaram_admin_user');
  };

  const refreshProfile = async () => {
    try {
      const res = await authApi.getProfile();
      if (res.success && res.data) {
        const normalized = normalizeAdmin(res.data);
        setAdmin(normalized);
        localStorage.setItem('agaram_admin_user', JSON.stringify(normalized));
      }
    } catch {
      // ignore
    }
  };

  return (
    <AuthContext.Provider
      value={{
        admin,
        token,
        isAuthenticated: !!token,
        isLoading,
        login,
        logout,
        refreshProfile,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
