import { useLocalSearchParams } from 'expo-router';
import { useMemo, useState } from 'react';
import { Pressable, ScrollView, Text, View } from 'react-native';
import { Btn, Input, Notices, Outputs, Row, Screen, Txt } from '../../src/ui/kit';
import { useT } from '../../src/i18n';
import { useApp } from '../../src/state/store';
import { colName, refOf, gridToMatrix } from '../../src/core/sheet.ts';
import { displayGrid, writeXlsx } from '../../src/core/xlsx.ts';
import { toCsv } from '../../src/core/csv.ts';
import { renderSheetsToPdf } from '../../src/core/pdfdoc.ts';
import { utf8Encode } from '../../src/core/text.ts';
import { MIME, type OutputFile } from '../../src/core/types.ts';
import { loadPdfFonts } from '../../src/platform/files';
import { useAction } from '../../src/ui/useAction';
import { usePalette } from '../../src/ui/theme';

const CW = 92;
const RH = 38;

export default function SheetEditor() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const t = useT();
  const p = usePalette();
  const sheet = useApp((s) => s.sheets.find((d) => d.id === id));
  const upsert = useApp((s) => s.upsertSheet);
  const [sel, setSel] = useState('A1');
  const [files, setFiles] = useState<OutputFile[]>([]);
  const { busy, error, run } = useAction();
  const shown = useMemo(() => (sheet ? displayGrid({ grid: sheet.grid }) : {}), [sheet]);
  if (!sheet) return <Screen title={t('sheets')}><Txt sub>{t('empty')}</Txt></Screen>;
  const patch = (x: Partial<typeof sheet>) => upsert({ ...sheet, ...x, updated: Date.now() });
  const setCell = (ref: string, v: string) => {
    const g = { ...sheet.grid };
    if (v === '') delete g[ref]; else g[ref] = v;
    patch({ grid: g });
  };
  const exportAs = (kind: 'xlsx' | 'csv' | 'pdf') => run(async () => {
    const name = sheet.title || 'sheet';
    const m = gridToMatrix(displayGrid({ grid: sheet.grid }));
    let f: OutputFile;
    if (kind === 'xlsx') f = { name: name + '.xlsx', mime: MIME.xlsx, bytes: await writeXlsx([{ name, grid: sheet.grid }], { headerBold: true }) };
    else if (kind === 'csv') f = { name: name + '.csv', mime: MIME.csv, bytes: utf8Encode(toCsv(m)) };
    else f = { name: name + '.pdf', mime: MIME.pdf, bytes: renderSheetsToPdf([{ name, rows: m }], await loadPdfFonts(), { title: name }) };
    setFiles([f]);
  });
  return (
    <Screen title={sheet.title || t('untitled')}>
      <Input value={sheet.title} onChangeText={(v) => patch({ title: v })} />
      <Row>
        <Txt bold>{sel}</Txt>
        <View style={{ flex: 1, minWidth: 160 }}>
          <Input placeholder={t('formula')} autoCapitalize="none" autoCorrect={false} value={sheet.grid[sel] ?? ''} onChangeText={(v) => setCell(sel, v)} />
        </View>
      </Row>
      <ScrollView horizontal>
        <View>
          <View style={{ flexDirection: 'row' }}>
            <View style={{ width: 36 }} />
            {Array.from({ length: sheet.cols }, (_, c) => <View key={c} style={{ width: CW, alignItems: 'center' }}><Txt sub>{colName(c)}</Txt></View>)}
          </View>
          {Array.from({ length: sheet.rows }, (_, r) => (
            <View key={r} style={{ flexDirection: 'row' }}>
              <View style={{ width: 36, height: RH, justifyContent: 'center' }}><Txt sub>{r + 1}</Txt></View>
              {Array.from({ length: sheet.cols }, (_, c) => {
                const ref = refOf(c, r);
                const active = ref === sel;
                return (
                  <Pressable key={c} onPress={() => setSel(ref)}
                    style={{ width: CW, height: RH, borderWidth: active ? 2 : 1, borderColor: active ? p.accent : p.border, backgroundColor: p.card, justifyContent: 'center', paddingHorizontal: 6 }}>
                    <Text numberOfLines={1} style={{ color: p.text }}>{shown[ref] ?? ''}</Text>
                  </Pressable>
                );
              })}
            </View>
          ))}
        </View>
      </ScrollView>
      <Row>
        <Btn kind="ghost" label={t('addRow')} onPress={() => patch({ rows: sheet.rows + 10 })} />
        <Btn kind="ghost" label={t('addCol')} onPress={() => patch({ cols: sheet.cols + 2 })} />
      </Row>
      <Row>
        <Btn label={t('exportXlsx')} disabled={busy} onPress={() => void exportAs('xlsx')} />
        <Btn kind="ghost" label={t('exportCsv')} disabled={busy} onPress={() => void exportAs('csv')} />
        <Btn kind="ghost" label={t('exportPdf')} disabled={busy} onPress={() => void exportAs('pdf')} />
      </Row>
      {error !== '' && <Txt>{error}</Txt>}
      <Notices list={[]} />
      <Outputs files={files} />
    </Screen>
  );
}
