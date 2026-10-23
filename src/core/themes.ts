import type { ThemeName } from './types.ts';

export interface SlideColors {
  bg: string; // hex without '#'
  title: string;
  subtitle: string;
  body: string;
}

export const SLIDE_THEMES: Record<ThemeName, SlideColors> = {
  dark: { bg: '0F172A', title: 'FFFFFF', subtitle: '22D3EE', body: 'E2E8F0' },
  emerald: { bg: '064E3B', title: 'ECFDF5', subtitle: '6EE7B7', body: 'D1FAE5' },
  navy: { bg: '1E3A8A', title: 'FFFFFF', subtitle: '93C5FD', body: 'DBEAFE' },
  sunset: { bg: '7C2D12', title: 'FFF7ED', subtitle: 'FDBA74', body: 'FFEDD5' },
};

export const THEME_NAMES: ThemeName[] = ['dark', 'emerald', 'navy', 'sunset'];

export function themeByIndex(i: number): ThemeName {
  return THEME_NAMES[((i % THEME_NAMES.length) + THEME_NAMES.length) % THEME_NAMES.length];
}
