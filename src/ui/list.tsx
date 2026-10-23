import { useRouter, type Href } from 'expo-router';
import { Btn, Card, Row, Screen, Txt } from './kit';
import { useT } from '../i18n';

export function ItemList({ title, base, items, onNew, onDelete }: {
  title: string; base: string; items: Array<{ id: string; title: string; updated: number }>;
  onNew: () => string; onDelete: (id: string) => void;
}) {
  const t = useT();
  const r = useRouter();
  return (
    <Screen title={title}>
      <Btn label={t('newItem')} onPress={() => r.push(`${base}/${onNew()}` as Href)} />
      {items.length === 0 && <Txt sub>{t('empty')}</Txt>}
      {items.map((it) => (
        <Card key={it.id} onPress={() => r.push(`${base}/${it.id}` as Href)}>
          <Txt bold>{it.title || t('untitled')}</Txt>
          <Txt sub>{new Date(it.updated).toLocaleString()}</Txt>
          <Row><Btn kind="danger" label={t('delete')} onPress={() => onDelete(it.id)} /></Row>
        </Card>
      ))}
    </Screen>
  );
}
