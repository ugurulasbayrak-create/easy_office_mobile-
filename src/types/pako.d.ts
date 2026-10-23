declare module 'pako' {
  export function deflate(data: Uint8Array, options?: { level?: number }): Uint8Array;
  const pako: { deflate: typeof deflate };
  export default pako;
}
