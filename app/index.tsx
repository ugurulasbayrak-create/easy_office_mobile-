import { useRouter, type Href } from 'expo-router';
import { Card, Screen, Txt } from '../src/ui/kit';
import { useT, type Dict } from '../src/i18n';

const items: Array<[keyof Dict, Href]> = [
  ['docs', '/docs'], ['sheets', '/sheets'], ['slides', '/slides'], ['convert', '/convert'],
  ['pdfTools', '/pdf'], ['ocr', '/ocr'], ['templates', '/templates'], ['ai', '/ai'], ['settings', '/settings'],
];

export default function Home() {
  const t = useT();
  const r = useRouter();
  return (
    <Screen title={t('appName')}>
      {items.map(([k, href]) => (
        <Card key={k} onPress={() => r.push(href)}>
          <Txt bold size={17}>{t(k)}</Txt>
        </Card>
      ))}
    </Screen>
  );
}
