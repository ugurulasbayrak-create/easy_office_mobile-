import { ItemList } from '../../src/ui/list';
import { useT } from '../../src/i18n';
import { newId, useApp } from '../../src/state/store';

export default function Decks() {
  const t = useT();
  const { decks, upsertDeck, remove } = useApp();
  return (
    <ItemList title={t('slides')} base="/slides" items={decks}
      onNew={() => { const id = newId(); upsertDeck({ id, title: t('untitled'), slides: [{ title: '', subtitle: '', bullets: [], theme: 'dark' }], updated: Date.now() }); return id; }}
      onDelete={(id) => remove('decks', id)} />
  );
}
