'use client';

import { createContext, useContext, useState, useEffect, type ReactNode } from 'react';

// ============================================
// Theme palette — mapped from FX/Themes.lua
// ============================================
export interface ThemePalette {
  bg: string;
  panel: string;
  border: string;
  accent: string;
  gold: string;
  text: string;
  dim: string;
  muted: string;
}

function rgb(r: number, g: number, b: number): string {
  return `#${Math.round(r * 255).toString(16).padStart(2, '0')}${Math.round(g * 255).toString(16).padStart(2, '0')}${Math.round(b * 255).toString(16).padStart(2, '0')}`;
}

function rgba(r: number, g: number, b: number, a: number): string {
  return `rgba(${Math.round(r * 255)}, ${Math.round(g * 255)}, ${Math.round(b * 255)}, ${a})`;
}

export const THEME_PALETTES: Record<string, { name: string; colors: ThemePalette }> = {
  dark: {
    name: 'Sombre',
    colors: {
      bg:     rgba(0.05, 0.06, 0.11, 0.97),
      panel:  rgba(0.08, 0.09, 0.16, 0.90),
      border: rgba(0.20, 0.26, 0.46, 0.60),
      accent: rgb(0.00, 0.68, 1.00),
      gold:   rgb(1.00, 0.84, 0.00),
      text:   rgb(0.92, 0.93, 0.96),
      dim:    rgb(0.55, 0.58, 0.66),
      muted:  rgb(0.36, 0.38, 0.46),
    },
  },
  light: {
    name: 'Clair',
    colors: {
      bg:     rgba(0.95, 0.96, 0.98, 0.97),
      panel:  rgba(0.98, 0.98, 0.99, 0.95),
      border: rgba(0.70, 0.75, 0.85, 0.80),
      accent: rgb(0.20, 0.55, 0.85),
      gold:   rgb(0.85, 0.65, 0.10),
      text:   rgb(0.10, 0.12, 0.15),
      dim:    rgb(0.40, 0.45, 0.50),
      muted:  rgb(0.55, 0.60, 0.65),
    },
  },
  purple: {
    name: 'R\u00eave Violet',
    colors: {
      bg:     rgba(0.08, 0.05, 0.12, 0.97),
      panel:  rgba(0.10, 0.07, 0.16, 0.90),
      border: rgba(0.35, 0.25, 0.50, 0.60),
      accent: rgb(0.75, 0.35, 1.00),
      gold:   rgb(1.00, 0.84, 0.00),
      text:   rgb(0.95, 0.92, 0.98),
      dim:    rgb(0.65, 0.58, 0.72),
      muted:  rgb(0.50, 0.42, 0.58),
    },
  },
  green: {
    name: 'For\u00eat',
    colors: {
      bg:     rgba(0.05, 0.10, 0.08, 0.97),
      panel:  rgba(0.07, 0.12, 0.10, 0.90),
      border: rgba(0.25, 0.40, 0.32, 0.60),
      accent: rgb(0.30, 0.90, 0.50),
      gold:   rgb(1.00, 0.84, 0.00),
      text:   rgb(0.92, 0.96, 0.94),
      dim:    rgb(0.58, 0.70, 0.64),
      muted:  rgb(0.38, 0.48, 0.42),
    },
  },
  blue: {
    name: 'Oc\u00e9an',
    colors: {
      bg:     rgba(0.04, 0.08, 0.14, 0.97),
      panel:  rgba(0.06, 0.10, 0.18, 0.90),
      border: rgba(0.18, 0.30, 0.48, 0.60),
      accent: rgb(0.15, 0.70, 0.95),
      gold:   rgb(1.00, 0.84, 0.00),
      text:   rgb(0.92, 0.94, 0.98),
      dim:    rgb(0.58, 0.64, 0.74),
      muted:  rgb(0.38, 0.44, 0.54),
    },
  },
  amber: {
    name: 'Ambre',
    colors: {
      bg:     rgba(0.10, 0.08, 0.05, 0.97),
      panel:  rgba(0.14, 0.11, 0.07, 0.90),
      border: rgba(0.40, 0.32, 0.22, 0.60),
      accent: rgb(1.00, 0.70, 0.20),
      gold:   rgb(1.00, 0.84, 0.00),
      text:   rgb(0.96, 0.94, 0.90),
      dim:    rgb(0.72, 0.66, 0.58),
      muted:  rgb(0.54, 0.48, 0.40),
    },
  },
};

export const THEME_IDS = Object.keys(THEME_PALETTES);

// ============================================
// Context
// ============================================
interface ThemeContextType {
  currentTheme: string;
  colors: ThemePalette;
  setTheme: (id: string) => void;
}

const defaultColors = THEME_PALETTES.dark.colors;

const ThemeContext = createContext<ThemeContextType>({
  currentTheme: 'dark',
  colors: defaultColors,
  setTheme: () => {},
});

const STORAGE_KEY = 'cr-theme';

export function DashboardThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setThemeState] = useState('dark');

  useEffect(() => {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved && THEME_PALETTES[saved]) {
      setThemeState(saved);
    }
  }, []);

  const setTheme = (id: string) => {
    if (THEME_PALETTES[id]) {
      setThemeState(id);
      localStorage.setItem(STORAGE_KEY, id);
    }
  };

  const colors = THEME_PALETTES[theme]?.colors || defaultColors;

  return (
    <ThemeContext.Provider value={{ currentTheme: theme, colors, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  return useContext(ThemeContext);
}
