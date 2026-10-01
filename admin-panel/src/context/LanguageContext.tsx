import React, { createContext, useContext, useState, useEffect } from 'react';
import { Language, translations } from '../i18n/translations';

interface LanguageContextType {
  language: Language;
  setLanguage: (lang: Language) => void;
  toggleLanguage: () => void;
  t: (key: string, params?: Record<string, string | number>) => string;
}

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

export const LanguageProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [language, setLanguageState] = useState<Language>(() => {
    const saved = localStorage.getItem('agaram_admin_lang');
    return saved === 'en' ? 'en' : 'ta';
  });

  useEffect(() => {
    localStorage.setItem('agaram_admin_lang', language);
    document.documentElement.lang = language;
  }, [language]);

  const setLanguage = (lang: Language) => {
    setLanguageState(lang);
  };

  const toggleLanguage = () => {
    setLanguageState((prev) => (prev === 'ta' ? 'en' : 'ta'));
  };

  /**
   * Translate key with optional parameter substitution and smart fallback resolution
   * Example: t('lessons.pageTitle') -> "பாடப்பிரிவுகள்"
   */
  const t = (key: string, params?: Record<string, string | number>): string => {
    const langDict = (translations[language] || {}) as Record<string, string>;
    const fallbackDict = (translations.en || {}) as Record<string, string>;

    // 1. Direct key match in selected language or English fallback
    let text = langDict[key] || fallbackDict[key];

    // 2. Fallback: If dot notation key is missing, check alternative snake_case keys
    if (!text && key.includes('.')) {
      const parts = key.split('.');
      const snake1 = parts.join('_');
      const snake2 = `${parts[0]}_col_${parts[1]}`;
      const snake3 = `${parts[0]}_field_${parts[1]}`;
      text = langDict[snake1] || fallbackDict[snake1] ||
             langDict[snake2] || fallbackDict[snake2] ||
             langDict[snake3] || fallbackDict[snake3];
    }

    // 3. Fallback to key itself if still not found
    if (!text) {
      text = key;
    }

    if (params) {
      Object.entries(params).forEach(([paramKey, paramVal]) => {
        text = text.replace(new RegExp(`\\{${paramKey}\\}`, 'g'), String(paramVal));
      });
    }

    return text;
  };

  return (
    <LanguageContext.Provider value={{ language, setLanguage, toggleLanguage, t }}>
      {children}
    </LanguageContext.Provider>
  );
};

export const useLanguage = () => {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error('useLanguage must be used within a LanguageProvider');
  }
  return context;
};
