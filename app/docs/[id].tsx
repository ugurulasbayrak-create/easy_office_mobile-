import { useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { Text, View } from 'react-native';
import { Btn, Input, Notices, Outputs, Row, Screen, Txt } from '../../src/ui/kit';
import { useT } from '../../src/i18n';
import { useApp } from '../../src/state/store';
import { countWords, parseMarkdown } from '../../src/core/markdown.ts';
import { convert, type Target } from '../../src/core/convert.ts';
import { utf8Encode } from '../../src/core/text.ts';
import { loadPdfFonts } from '../../src/platform/files';
import { useAction } from '../../src/ui/useAction';
import { usePalette } from '../../src/ui/theme';
import type { Block, Inline, Notice, OutputFile } from '../../src/core/types.ts';

function Runs({ runs }: { runs: Inline[] }) {
  return <>{runs.map((r, i) => <Text key={i} style={{ fontWeight: r.bold ? '700' : '400', fontStyle: r.italic ? 'italic' : 'normal', fontFamily: r.code ? 'monospace' : undefined }}>{r.text}</Text>)}</>;
}

function Preview({ blocks }: { blocks: Block[] }) {
  const p = usePalette();
  return (
    <View style={{ gap: 8 }}>
      {blocks.map((b, i) => {
        const st = { color: p.text };
        if (b.type === 'heading') return <Text key={i} style={[st, { fontWeight: '700', fontSize: 26 - b.level * 2 }]}><Runs runs={b.runs} /></Text>;
        if (b.type === 'paragraph') return <Text key={i} style={st}><Runs runs={b.runs} /></Text>;
        if (b.type === 'list') return <View key={i}>{b.items.map((it, j) => <Text key={j} style={st}>{b.ordered ? `${j + 1}. ` : '• '}<Runs runs={it} /></Text>)}</View>;
        if (b.type === 'code') return <Text key={i} style={[st, { fontFamily: 'monospace', backgroundColor: p.border, padding: 8 }]}>{b.text}</Text>;
        if (b.type === 'hr') return <View key={i} style={{ height: 1, backgroundColor: p.border }} />;
        return <View key={i}>{b.rows.map((row, ri) => <Text key={ri} style={[st, { fontWeight: b.header && ri === 0 ? '700' : '400' }]}>{row.map((c) => c.map((r) => r.text).join('')).join('  |  ')}</Text>)}</View>;
      })}
    </View>
  );
}

export default function DocEditor() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const t = useT();
  const doc = useApp((s) => s.docs.find((d) => d.id === id));
  const upsert = useApp((s) => s.upsertDoc);
  const [tab, setTab] = useState<'edit' | 'preview'>('edit');
  const [files, setFiles] = useState<OutputFile[]>([]);
  const [notices, setNotices] = useState<Notice[]>([]);
  const { busy, error, run } = useAction();
  if (!doc) return <Screen title={t('docs')}><Txt sub>{t('empty')}</Txt></Screen>;
  const patch = (x: Partial<typeof doc>) => upsert({ ...doc, ...x, updated: Date.now() });
  const exportAs = (target: Target) => run(async () => {
    const r = await convert({ name: (doc.title || 'doc') + '.md', bytes: utf8Encode(doc.md) }, target, await loadPdfFonts());
    setFiles(r.files); setNotices(r.notices);
  });
  return (
    <Screen title={doc.title || t('untitled')}>
      <Input value={doc.title} onChangeText={(v) => patch({ title: v })} />
      <Row>
        <Btn label={t('edit')} kind={tab === 'edit' ? 'primary' : 'ghost'} onPress={() => setTab('edit')} />
        <Btn label={t('preview')} kind={tab === 'preview' ? 'primary' : 'ghost'} onPress={() => setTab('preview')} />
      </Row>
      {tab === 'edit'
        ? <Input multiline value={doc.md} onChangeText={(v) => patch({ md: v })} style={{ minHeight: 280, textAlignVertical: 'top' }} />
        : <Preview blocks={parseMarkdown(doc.md)} />}
      <Txt sub>{countWords(doc.md)} {t('words')}</Txt>
      <Row>
        <Btn label={t('exportPdf')} disabled={busy} onPress={() => void exportAs('pdf')} />
        <Btn label={t('exportDocx')} disabled={busy} kind="ghost" onPress={() => void exportAs('docx')} />
        <Btn label={t('exportMd')} disabled={busy} kind="ghost" onPress={() => void exportAs('md')} />
      </Row>
      {error !== '' && <Txt>{error}</Txt>}
      <Notices list={notices} />
      <Outputs files={files} />
    </Screen>
  );
}
