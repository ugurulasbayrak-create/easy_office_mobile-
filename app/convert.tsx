import { useState } from 'react';
import { Btn, Notices, Outputs, Row, Screen, Txt } from '../src/ui/kit';
import { useT } from '../src/i18n';
import { convert, targetsFor, type Target } from '../src/core/convert.ts';
import { extOf } from '../src/core/text.ts';
import type { Input } from '../src/core/convert.ts';
import type { Notice, OutputFile } from '../src/core/types.ts';
import { loadPdfFonts, pickFiles } from '../src/platform/files';
import { useAction } from '../src/ui/useAction';

export default function Convert() {
  const t = useT();
  const [file, setFile] = useState<Input | null>(null);
  const [target, setTarget] = useState<Target | null>(null);
  const [files, setFiles] = useState<OutputFile[]>([]);
  const [notices, setNotices] = useState<Notice[]>([]);
  const { busy, error, run } = useAction();
  const targets = file ? targetsFor(extOf(file.name)) : [];
  return (
    <Screen title={t('convert')}>
      <Btn label={t('pickFile')} onPress={() => void run(async () => {
        const [f] = await pickFiles();
        if (f) { setFile(f); setTarget(targetsFor(extOf(f.name))[0] ?? null); setFiles([]); setNotices([]); }
      })} />
      {file && <Txt bold>{file.name}</Txt>}
      {file && targets.length === 0 && <Txt>{t('err_unsupported')}</Txt>}
      {targets.length > 0 && (
        <>
          <Txt sub>{t('chooseTarget')}</Txt>
          <Row>{targets.map((x) => <Btn key={x} kind={x === target ? 'primary' : 'ghost'} label={x.toUpperCase()} onPress={() => setTarget(x)} />)}</Row>
          <Btn label={busy ? t('working') : t('run')} disabled={busy || !target} onPress={() => void run(async () => {
            const r = await convert(file!, target!, await loadPdfFonts());
            setFiles(r.files); setNotices(r.notices);
          })} />
        </>
      )}
      {error !== '' && <Txt>{error}</Txt>}
      <Notices list={notices} />
      <Outputs files={files} />
    </Screen>
  );
}
