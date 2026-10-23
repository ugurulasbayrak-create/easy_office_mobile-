import { useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { Pressable, Text, View } from 'react-native';
import { Btn, Card, Input, Outputs, Row, Screen, Txt } from '../../src/ui/kit';
import { useT } from '../../src/i18n';
import { useApp } from '../../src/state/store';
import { writePptx } from '../../src/core/pptx.ts';
import { renderSlidesToPdf } from '../../src/core/pdfdoc.ts';
import { SLIDE_THEMES, THEME_NAMES } from '../../src/core/themes.ts';
import { MIME, type OutputFile, type Slide } from '../../src/core/types.ts';
import { loadPdfFonts } from '../../src/platform/files';
import { useAction } from '../../src/ui/useAction';

function SlideView({ s, big }: { s: Slide; big?: boolean }) {
  const c = SLIDE_THEMES[s.theme];
  const k = big ? 1.6 : 1;
  return (
    <View style={{ backgroundColor: '#' + c.bg, aspectRatio: 16 / 9, padding: 14 * k, borderRadius: 8, justifyContent: 'center' }}>
      <Text style={{ color: '#' + c.title, fontWeight: '700', fontSize: 18 * k }}>{s.title}</Text>
      {s.subtitle !== '' && <Text style={{ color: '#' + c.subtitle, fontSize: 12 * k }}>{s.subtitle}</Text>}
      {s.bullets.map((b, i) => <Text key={i} style={{ color: '#' + c.body, fontSize: 11 * k }}>• {b}</Text>)}
    </View>
  );
}

export default function DeckEditor() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const t = useT();
  const deck = useApp((s) => s.decks.find((d) => d.id === id));
  const upsert = useApp((s) => s.upsertDeck);
  const [idx, setIdx] = useState(0);
  const [presenting, setPresenting] = useState(false);
  const [files, setFiles] = useState<OutputFile[]>([]);
  const { busy, error, run } = useAction();
  if (!deck) return <Screen title={t('slides')}><Txt sub>{t('empty')}</Txt></Screen>;
  const i = Math.min(idx, deck.slides.length - 1);
  const cur = deck.slides[i];
  const patch = (x: Partial<typeof deck>) => upsert({ ...deck, ...x, updated: Date.now() });
  const setSlide = (x: Partial<Slide>) => patch({ slides: deck.slides.map((s, j) => (j === i ? { ...s, ...x } : s)) });

  if (presenting) {
    return (
      <Screen title={deck.title}>
        <Pressable onPress={() => setIdx((i + 1) % deck.slides.length)}><SlideView s={cur} big /></Pressable>
        <Row>
          <Btn kind="ghost" label={t('prev')} onPress={() => setIdx(Math.max(0, i - 1))} />
          <Btn kind="ghost" label={t('next')} onPress={() => setIdx(Math.min(deck.slides.length - 1, i + 1))} />
          <Btn label={t('cancel')} onPress={() => setPresenting(false)} />
        </Row>
      </Screen>
    );
  }
  const exportAs = (kind: 'pptx' | 'pdf') => run(async () => {
    const name = deck.title || 'deck';
    const f: OutputFile = kind === 'pptx'
      ? { name: name + '.pptx', mime: MIME.pptx, bytes: await writePptx(deck.slides, { title: name }) }
      : { name: name + '.pdf', mime: MIME.pdf, bytes: renderSlidesToPdf(deck.slides, await loadPdfFonts(), { title: name }) };
    setFiles([f]);
  });
  return (
    <Screen title={deck.title || t('untitled')}>
      <Input value={deck.title} onChangeText={(v) => patch({ title: v })} />
      <SlideView s={cur} />
      <Row>
        {deck.slides.map((_, j) => <Btn key={j} kind={j === i ? 'primary' : 'ghost'} label={String(j + 1)} onPress={() => setIdx(j)} />)}
        <Btn kind="ghost" label={t('addSlide')} onPress={() => { patch({ slides: [...deck.slides, { title: '', subtitle: '', bullets: [], theme: cur.theme }] }); setIdx(deck.slides.length); }} />
      </Row>
      <Card>
        <Input placeholder={t('slideTitle')} value={cur.title} onChangeText={(v) => setSlide({ title: v })} />
        <Input placeholder={t('slideSubtitle')} value={cur.subtitle} onChangeText={(v) => setSlide({ subtitle: v })} />
        <Input multiline placeholder={t('slideBullets')} value={cur.bullets.join('\n')} onChangeText={(v) => setSlide({ bullets: v.split('\n') })} style={{ minHeight: 100, textAlignVertical: 'top' }} />
        <Txt sub>{t('theme')}</Txt>
        <Row>{THEME_NAMES.map((n) => <Btn key={n} kind={cur.theme === n ? 'primary' : 'ghost'} label={n} onPress={() => setSlide({ theme: n })} />)}</Row>
        {deck.slides.length > 1 && <Btn kind="danger" label={t('delete')} onPress={() => { patch({ slides: deck.slides.filter((_, j) => j !== i) }); setIdx(0); }} />}
      </Card>
      <Row>
        <Btn label={t('present')} onPress={() => setPresenting(true)} />
        <Btn kind="ghost" label={t('exportPptx')} disabled={busy} onPress={() => void exportAs('pptx')} />
        <Btn kind="ghost" label={t('exportPdf')} disabled={busy} onPress={() => void exportAs('pdf')} />
      </Row>
      {error !== '' && <Txt>{error}</Txt>}
      <Outputs files={files} />
    </Screen>
  );
}
