import { useRouter } from 'expo-router';
import { Btn, Card, Screen, Txt } from '../src/ui/kit';
import { useT } from '../src/i18n';
import { newId, useApp } from '../src/state/store';
import { DECK_TEMPLATES, DOC_TEMPLATES, SHEET_TEMPLATES } from '../src/templates';

export default function Templates() {
  const t = useT();
  const r = useRouter();
  const { lang, upsertDoc, upsertSheet, upsertDeck } = useApp();
  return (
    <Screen title={t('templates')}>
      <Txt sub>{t('tplIntro')}</Txt>
      {DOC_TEMPLATES.map((x) => (
        <Card key={x.id}>
          <Txt bold>{t('docs')}: {x[lang]}</Txt>
          <Btn label={t('useTemplate')} onPress={() => { const id = newId(); upsertDoc({ id, title: x[lang], md: x.md, updated: Date.now() }); r.push(`/docs/${id}`); }} />
        </Card>
      ))}
      {SHEET_TEMPLATES.map((x) => (
        <Card key={x.id}>
          <Txt bold>{t('sheets')}: {x[lang]}</Txt>
          <Btn label={t('useTemplate')} onPress={() => { const id = newId(); upsertSheet({ id, title: x[lang], grid: x.grid, rows: 20, cols: 8, updated: Date.now() }); r.push(`/sheets/${id}`); }} />
        </Card>
      ))}
      {DECK_TEMPLATES.map((x) => (
        <Card key={x.id}>
          <Txt bold>{t('slides')}: {x[lang]}</Txt>
          <Btn label={t('useTemplate')} onPress={() => { const id = newId(); upsertDeck({ id, title: x[lang], slides: x.slides, updated: Date.now() }); r.push(`/slides/${id}`); }} />
        </Card>
      ))}
    </Screen>
  );
}
