import { ItemList } from '../../src/ui/list';
import { useT } from '../../src/i18n';
import { newId, useApp } from '../../src/state/store';

export default function Sheets() {
  const t = useT();
  const { sheets, upsertSheet, remove } = useApp();
  return (
    <ItemList title={t('sheets')} base="/sheets" items={sheets}
      onNew={() => { const id = newId(); upsertSheet({ id, title: t('untitled'), grid: {}, rows: 20, cols: 8, updated: Date.now() }); return id; }}
      onDelete={(id) => remove('sheets', id)} />
  );
}
