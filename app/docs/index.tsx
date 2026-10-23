import { ItemList } from '../../src/ui/list';
import { useT } from '../../src/i18n';
import { newId, useApp } from '../../src/state/store';

export default function Docs() {
  const t = useT();
  const { docs, upsertDoc, remove } = useApp();
  return (
    <ItemList title={t('docs')} base="/docs" items={docs}
      onNew={() => { const id = newId(); upsertDoc({ id, title: t('untitled'), md: '', updated: Date.now() }); return id; }}
      onDelete={(id) => remove('docs', id)} />
  );
}
