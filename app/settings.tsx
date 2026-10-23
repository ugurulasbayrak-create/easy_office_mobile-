import { Btn, Row, Screen, Txt } from '../src/ui/kit';
import { useT } from '../src/i18n';
import { useApp } from '../src/state/store';

export default function Settings() {
  const t = useT();
  const { lang, mode, setLang, setMode } = useApp();
  return (
    <Screen title={t('settings')}>
      <Txt bold>{t('language')}</Txt>
      <Row>
        <Btn label="Türkçe" kind={lang === 'tr' ? 'primary' : 'ghost'} onPress={() => setLang('tr')} />
        <Btn label="English" kind={lang === 'en' ? 'primary' : 'ghost'} onPress={() => setLang('en')} />
      </Row>
      <Txt bold>{t('themeMode')}</Txt>
      <Row>
        <Btn label={t('system')} kind={mode === 'system' ? 'primary' : 'ghost'} onPress={() => setMode('system')} />
        <Btn label={t('light')} kind={mode === 'light' ? 'primary' : 'ghost'} onPress={() => setMode('light')} />
        <Btn label={t('darkMode')} kind={mode === 'dark' ? 'primary' : 'ghost'} onPress={() => setMode('dark')} />
      </Row>
    </Screen>
  );
}
