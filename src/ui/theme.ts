import { useColorScheme } from 'react-native';
import { useApp } from '../state/store';

export interface Palette { bg: string; card: string; text: string; sub: string; accent: string; onAccent: string; border: string; danger: string }
const light: Palette = { bg: '#F6F7FB', card: '#FFFFFF', text: '#0F172A', sub: '#64748B', accent: '#2563EB', onAccent: '#FFFFFF', border: '#E2E8F0', danger: '#DC2626' };
const dark: Palette = { bg: '#0B1220', card: '#131C2E', text: '#E5E7EB', sub: '#94A3B8', accent: '#60A5FA', onAccent: '#0B1220', border: '#24304A', danger: '#F87171' };

export function usePalette(): Palette {
  const mode = useApp((s) => s.mode);
  const sys = useColorScheme();
  const eff = mode === 'system' ? (sys === 'dark' ? 'dark' : 'light') : mode;
  return eff === 'dark' ? dark : light;
}
