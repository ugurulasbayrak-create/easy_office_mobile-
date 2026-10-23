// Shared types for the Easy Office core engine.
// The core is pure TypeScript: no React Native, no Node-only APIs.

export type DocKind = 'doc' | 'sheet' | 'slide' | 'pdf';

/** Raw cell inputs keyed by A1 reference, e.g. { A1: 'Name', B2: '=SUM(B3:B9)' } */
export type Grid = Record<string, string>;

export type ThemeName = 'dark' | 'emerald' | 'navy' | 'sunset';

export interface Slide {
  title: string;
  subtitle: string;
  bullets: string[];
  theme: ThemeName;
}

export interface Inline {
  text: string;
  bold?: boolean;
  italic?: boolean;
  code?: boolean;
}

export type Block =
  | { type: 'heading'; level: 1 | 2 | 3 | 4 | 5 | 6; runs: Inline[] }
  | { type: 'paragraph'; runs: Inline[] }
  | { type: 'list'; ordered: boolean; items: Inline[][] }
  | { type: 'table'; rows: Inline[][][]; header: boolean }
  | { type: 'code'; text: string }
  | { type: 'hr' };

/**
 * A machine-readable note about a conversion. The UI turns codes into
 * localized sentences; the engine never produces user-facing prose.
 */
export interface Notice {
  code:
    | 'images_skipped'
    | 'no_text_found'
    | 'layout_not_preserved'
    | 'sheet_truncated'
    | 'formulas_as_values'
    | 'encrypted'
    | 'no_size_gain'
    | 'only_first_sheet'
    | 'text_only';
  n?: number;
}

export interface OutputFile {
  name: string;
  mime: string;
  bytes: Uint8Array;
}

export interface PdfFonts {
  regular: Uint8Array;
  bold: Uint8Array;
}

export const MIME = {
  pdf: 'application/pdf',
  docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  pptx: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  csv: 'text/csv',
  txt: 'text/plain',
  md: 'text/markdown',
} as const;
