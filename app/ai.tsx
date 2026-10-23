import { Card, Screen, Txt } from '../src/ui/kit';
import { useT } from '../src/i18n';

// Intentionally has no chat UI and no canned replies: no AI service is connected.
export default function Ai() {
  const t = useT();
  return (
    <Screen title={t('ai')}>
      <Card>
        <Txt bold size={17}>{t('aiTitle')}</Txt>
        <Txt sub>{t('aiBody')}</Txt>
      </Card>
    </Screen>
  );
}
