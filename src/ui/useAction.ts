import { useCallback, useState } from 'react';
import { useErr } from '../i18n';

/** Runs an async job with busy/error state. */
export function useAction() {
  const errText = useErr();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const run = useCallback(async <T,>(fn: () => Promise<T>): Promise<T | undefined> => {
    setBusy(true);
    setError('');
    try {
      return await fn();
    } catch (e) {
      setError(errText(e));
      return undefined;
    } finally {
      setBusy(false);
    }
  }, [errText]);
  return { busy, error, run };
}
