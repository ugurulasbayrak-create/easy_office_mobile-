import { useState } from 'react';
import { Btn, Card, Input, Notices, Outputs, Row, Screen, Txt } from '../src/ui/kit';
import { useT } from '../src/i18n';
import { SignaturePad, type Stroke } from '../src/ui/SignaturePad';
import { extractPages, imagesToPdf, mergePdfs, optimizePdf, pageCount, rotatePages, splitPages, stampSignature } from '../src/core/pdftools.ts';
import { baseName } from '../src/core/text.ts';
import { MIME, type Notice, type OutputFile } from '../src/core/types.ts';
import type { Input as FileIn } from '../src/core/convert.ts';
import { pickFiles } from '../src/platform/files';
import { useAction } from '../src/ui/useAction';

type Tool = 'merge' | 'split' | 'extract' | 'rotate' | 'optimize' | 'images' | 'sign';
const TOOLS: Tool[] = ['merge', 'split', 'extract', 'rotate', 'optimize', 'images', 'sign'];
const pdf = (name: string, bytes: Uint8Array): OutputFile => ({ name, mime: MIME.pdf, bytes });

export default function PdfTools() {
  const t = useT();
  const [tool, setTool] = useState<Tool>('merge');
  const [ins, setIns] = useState<FileIn[]>([]);
  const [spec, setSpec] = useState('1');
  const [angle, setAngle] = useState(90);
  const [strokes, setStrokes] = useState<Stroke[]>([]);
  const [signPage, setSignPage] = useState('1');
  const [files, setFiles] = useState<OutputFile[]>([]);
  const [notices, setNotices] = useState<Notice[]>([]);
  const [sizes, setSizes] = useState<{ before: number; after: number } | null>(null);
  const { busy, error, run } = useAction();
  const label: Record<Tool, string> = { merge: t('merge'), split: t('split'), extract: t('extract'), rotate: t('rotate'), optimize: t('optimize'), images: t('imagesToPdf'), sign: t('sign') };
  const multi = tool === 'merge' || tool === 'images';
  const first = ins[0];
  const stem = first ? baseName(first.name) : 'out';

  const pick = () => run(async () => {
    const got = await pickFiles({ types: tool === 'images' ? ['image/png', 'image/jpeg'] : ['application/pdf'], multiple: multi });
    if (got.length) { setIns(got); setFiles([]); setNotices([]); setSizes(null); }
  });
  const go = () => run(async () => {
    if (!ins.length) throw Object.assign(new Error('empty'), { code: 'empty' });
    const b = first.bytes;
    setSizes(null); setNotices([]);
    if (tool === 'merge') setFiles([pdf('merged.pdf', await mergePdfs(ins.map((x) => x.bytes)))]);
    else if (tool === 'images') setFiles([pdf('images.pdf', await imagesToPdf(ins.map((x) => x.bytes)))]);
    else if (tool === 'split') setFiles((await splitPages(b)).map((x, i) => pdf(`${stem}-${i + 1}.pdf`, x)));
    else if (tool === 'extract') setFiles([pdf(`${stem}-pages.pdf`, await extractPages(b, spec))]);
    else if (tool === 'rotate') setFiles([pdf(`${stem}-rotated.pdf`, await rotatePages(b, angle, spec))]);
    else if (tool === 'optimize') {
      const r = await optimizePdf(b);
      setFiles([pdf(`${stem}-optimized.pdf`, r.bytes)]); setNotices(r.notices); setSizes({ before: r.before, after: r.after });
    } else {
      const n = await pageCount(b);
      const page = parseInt(signPage, 10);
      if (!(page >= 1 && page <= n)) throw Object.assign(new Error('range'), { code: 'bad_range' });
      setFiles([pdf(`${stem}-signed.pdf`, await stampSignature(b, strokes, { page: page - 1, x: 0.55, y: 0.85, w: 0.35, h: 0.1 }))]);
    }
  });
  return (
    <Screen title={t('pdfTools')}>
      <Row>{TOOLS.map((x) => <Btn key={x} kind={x === tool ? 'primary' : 'ghost'} label={label[x]} onPress={() => { setTool(x); setIns([]); setFiles([]); setNotices([]); setSizes(null); }} />)}</Row>
      <Btn label={t('pickFile')} onPress={() => void pick()} />
      {ins.map((f, i) => <Txt key={i}>{f.name}</Txt>)}
      {(tool === 'extract' || tool === 'rotate') && <Input value={spec} onChangeText={setSpec} placeholder={t('pagesSpec')} autoCapitalize="none" />}
      {tool === 'rotate' && <Row>{[90, 180, 270].map((a) => <Btn key={a} kind={a === angle ? 'primary' : 'ghost'} label={`${a}°`} onPress={() => setAngle(a)} />)}</Row>}
      {tool === 'sign' && (
        <Card>
          <Txt sub>{t('signHere')}</Txt>
          <SignaturePad strokes={strokes} onChange={setStrokes} />
          <Row>
            <Btn kind="ghost" label={t('clear')} onPress={() => setStrokes([])} />
            <Input value={signPage} onChangeText={setSignPage} keyboardType="number-pad" placeholder={t('page')} style={{ width: 90 }} />
          </Row>
        </Card>
      )}
      <Btn label={busy ? t('working') : t('run')} disabled={busy || ins.length === 0 || (tool === 'sign' && strokes.length === 0)} onPress={() => void go()} />
      {error !== '' && <Txt>{error}</Txt>}
      {sizes && <Txt>{t('before')}: {(sizes.before / 1024).toFixed(1)} KB → {t('after')}: {(sizes.after / 1024).toFixed(1)} KB</Txt>}
      <Notices list={notices} />
      <Outputs files={files} />
    </Screen>
  );
}
