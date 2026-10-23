import { useRouter } from 'expo-router';
import * as ImagePicker from 'expo-image-picker';
import { useState } from 'react';
import { Btn, Input, Screen, Txt } from '../src/ui/kit';
import { useT } from '../src/i18n';
import { newId, useApp } from '../src/state/store';
import { useAction } from '../src/ui/useAction';

// On-device OCR via ML Kit. Needs a development build (native module).
// Not yet verified on a device.
async function recognize(uri: string): Promise<string> {
  let mod: any;
  try {
    mod = await import('@react-native-ml-kit/text-recognition');
  } catch {
    throw Object.assign(new Error('ocr_unavailable'), { code: 'ocr_unavailable' });
  }
  const TextRecognition = mod.default ?? mod;
  const res = await TextRecognition.recognize(uri);
  return String(res?.text ?? '');
}

export default function Ocr() {
  const t = useT();
  const r = useRouter();
  const upsertDoc = useApp((s) => s.upsertDoc);
  const [text, setText] = useState('');
  const [unavailable, setUnavailable] = useState(false);
  const { busy, error, run } = useAction();
  return (
    <Screen title={t('ocr')}>
      <Txt sub>{t('ocrIntro')}</Txt>
      <Btn label={busy ? t('working') : t('ocrPick')} disabled={busy} onPress={() => void run(async () => {
        const pick = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ['images'], quality: 1 });
        if (pick.canceled) return;
        try {
          setUnavailable(false);
          setText(await recognize(pick.assets[0].uri));
        } catch (e: any) {
          if (e?.code === 'ocr_unavailable') setUnavailable(true); else throw e;
        }
      })} />
      {unavailable && <Txt>{t('ocrUnavailable')}</Txt>}
      {error !== '' && <Txt>{error}</Txt>}
      {text !== '' && (
        <>
          <Txt bold>{t('ocrResult')}</Txt>
          <Input multiline value={text} onChangeText={setText} style={{ minHeight: 200, textAlignVertical: 'top' }} />
          <Btn label={t('ocrCopyDoc')} onPress={() => { const id = newId(); upsertDoc({ id, title: t('ocr'), md: text, updated: Date.now() }); r.push(`/docs/${id}`); }} />
        </>
      )}
    </Screen>
  );
}
