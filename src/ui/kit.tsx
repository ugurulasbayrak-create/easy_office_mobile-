import React from 'react';
import { Pressable, ScrollView, StyleSheet, Text, TextInput, View, type TextInputProps } from 'react-native';
import { Stack } from 'expo-router';
import { usePalette } from './theme';
import { useNotice } from '../i18n';
import type { Notice, OutputFile } from '../core/types.ts';
import { shareFile } from '../platform/files';
import { useT } from '../i18n';

export function Screen({ title, children, scroll = true }: { title: string; children: React.ReactNode; scroll?: boolean }) {
  const p = usePalette();
  const body = scroll ? (
    <ScrollView contentContainerStyle={s.pad} keyboardShouldPersistTaps="handled">{children}</ScrollView>
  ) : (
    <View style={s.pad}>{children}</View>
  );
  return (
    <View style={{ flex: 1, backgroundColor: p.bg }}>
      <Stack.Screen options={{ title, headerStyle: { backgroundColor: p.card }, headerTintColor: p.text }} />
      {body}
    </View>
  );
}

export function Btn({ label, onPress, kind = 'primary', disabled }: { label: string; onPress: () => void; kind?: 'primary' | 'ghost' | 'danger'; disabled?: boolean }) {
  const p = usePalette();
  const bg = kind === 'primary' ? p.accent : 'transparent';
  const fg = kind === 'primary' ? p.onAccent : kind === 'danger' ? p.danger : p.accent;
  return (
    <Pressable accessibilityRole="button" disabled={disabled} onPress={onPress}
      style={[s.btn, { backgroundColor: bg, borderColor: kind === 'primary' ? bg : p.border, opacity: disabled ? 0.5 : 1 }]}>
      <Text style={{ color: fg, fontWeight: '600' }}>{label}</Text>
    </Pressable>
  );
}

export function Input(props: TextInputProps) {
  const p = usePalette();
  return <TextInput placeholderTextColor={p.sub} {...props} style={[s.input, { color: p.text, borderColor: p.border, backgroundColor: p.card }, props.style]} />;
}

export function Txt({ children, sub, bold, size }: { children: React.ReactNode; sub?: boolean; bold?: boolean; size?: number }) {
  const p = usePalette();
  return <Text style={{ color: sub ? p.sub : p.text, fontWeight: bold ? '700' : '400', fontSize: size ?? 15 }}>{children}</Text>;
}

export function Card({ children, onPress }: { children: React.ReactNode; onPress?: () => void }) {
  const p = usePalette();
  const st = [s.card, { backgroundColor: p.card, borderColor: p.border }];
  return onPress ? <Pressable onPress={onPress} style={st}>{children}</Pressable> : <View style={st}>{children}</View>;
}

export function Row({ children }: { children: React.ReactNode }) {
  return <View style={s.row}>{children}</View>;
}

export function Notices({ list }: { list: Notice[] }) {
  const f = useNotice();
  const p = usePalette();
  if (!list.length) return null;
  return (
    <View style={[s.card, { backgroundColor: p.card, borderColor: p.border }]}>
      {list.map((n, i) => <Text key={i} style={{ color: p.sub }}>• {f(n)}</Text>)}
    </View>
  );
}

export function Outputs({ files }: { files: OutputFile[] }) {
  const t = useT();
  return (
    <View style={{ gap: 8 }}>
      {files.map((f) => (
        <Card key={f.name}>
          <Txt bold>{f.name}</Txt>
          <Txt sub>{(f.bytes.length / 1024).toFixed(1)} KB</Txt>
          <Btn label={t('share')} onPress={() => void shareFile(f)} />
        </Card>
      ))}
    </View>
  );
}

const s = StyleSheet.create({
  pad: { padding: 16, gap: 12 },
  btn: { paddingVertical: 12, paddingHorizontal: 16, borderRadius: 10, borderWidth: 1, alignItems: 'center' },
  input: { borderWidth: 1, borderRadius: 10, padding: 10, fontSize: 15 },
  card: { borderWidth: 1, borderRadius: 12, padding: 14, gap: 6 },
  row: { flexDirection: 'row', gap: 8, flexWrap: 'wrap' },
});
