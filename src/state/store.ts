import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { Grid, Slide } from '../core/types.ts';

export type Mode = 'system' | 'light' | 'dark';

export interface DocItem { id: string; title: string; md: string; updated: number }
export interface SheetItem { id: string; title: string; grid: Grid; rows: number; cols: number; updated: number }
export interface DeckItem { id: string; title: string; slides: Slide[]; updated: number }

interface State {
  lang: 'tr' | 'en';
  mode: Mode;
  docs: DocItem[];
  sheets: SheetItem[];
  decks: DeckItem[];
  setLang(l: 'tr' | 'en'): void;
  setMode(m: Mode): void;
  upsertDoc(d: DocItem): void;
  upsertSheet(s: SheetItem): void;
  upsertDeck(d: DeckItem): void;
  remove(kind: 'docs' | 'sheets' | 'decks', id: string): void;
}

const upsert = <T extends { id: string }>(list: T[], item: T) =>
  list.some((x) => x.id === item.id) ? list.map((x) => (x.id === item.id ? item : x)) : [item, ...list];

export const useApp = create<State>()(
  persist(
    (set) => ({
      lang: 'tr',
      mode: 'system',
      docs: [],
      sheets: [],
      decks: [],
      setLang: (lang) => set({ lang }),
      setMode: (mode) => set({ mode }),
      upsertDoc: (d) => set((s) => ({ docs: upsert(s.docs, d) })),
      upsertSheet: (d) => set((s) => ({ sheets: upsert(s.sheets, d) })),
      upsertDeck: (d) => set((s) => ({ decks: upsert(s.decks, d) })),
      remove: (kind, id) => set((s) => ({ [kind]: (s[kind] as { id: string }[]).filter((x) => x.id !== id) }) as Partial<State>),
    }),
    { name: 'easy-office-v2', storage: createJSONStorage(() => AsyncStorage) },
  ),
);

export const newId = () => Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
