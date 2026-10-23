// All device I/O lives here so API changes in Expo only touch this file.
// NOTE: written against expo-file-system's string-based API
// (`expo-file-system/legacy` in recent SDKs). Not yet run on a device.
import * as DocumentPicker from 'expo-document-picker';
import * as Sharing from 'expo-sharing';
import * as FileSystem from 'expo-file-system/legacy';
import { Asset } from 'expo-asset';
import { fromBase64, toBase64 } from '../core/base64.ts';
import type { OutputFile, PdfFonts } from '../core/types.ts';
import type { Input } from '../core/convert.ts';

export async function readUri(uri: string): Promise<Uint8Array> {
  const b64 = await FileSystem.readAsStringAsync(uri, { encoding: FileSystem.EncodingType.Base64 });
  return fromBase64(b64);
}

export async function pickFiles(opts: { types?: string[]; multiple?: boolean } = {}): Promise<Input[]> {
  const res = await DocumentPicker.getDocumentAsync({
    type: opts.types ?? '*/*',
    multiple: !!opts.multiple,
    copyToCacheDirectory: true,
  });
  if (res.canceled) return [];
  const out: Input[] = [];
  for (const a of res.assets) out.push({ name: a.name, bytes: await readUri(a.uri) });
  return out;
}

export async function shareFile(f: OutputFile): Promise<void> {
  const uri = (FileSystem.cacheDirectory ?? '') + f.name.replace(/[\\/:*?"<>|]/g, '_');
  await FileSystem.writeAsStringAsync(uri, toBase64(f.bytes), { encoding: FileSystem.EncodingType.Base64 });
  if (await Sharing.isAvailableAsync()) await Sharing.shareAsync(uri, { mimeType: f.mime, dialogTitle: f.name });
}

let fontCache: PdfFonts | null = null;
export async function loadPdfFonts(): Promise<PdfFonts> {
  if (fontCache) return fontCache;
  const load = async (mod: number) => {
    const asset = Asset.fromModule(mod);
    await asset.downloadAsync();
    return readUri(asset.localUri ?? asset.uri);
  };
  fontCache = {
    regular: await load(require('../../assets/fonts/DejaVuSans.ttf')),
    bold: await load(require('../../assets/fonts/DejaVuSans-Bold.ttf')),
  };
  return fontCache;
}
