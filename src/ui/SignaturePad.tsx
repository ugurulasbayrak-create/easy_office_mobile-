import { useMemo, useRef, useState } from 'react';
import { PanResponder, View } from 'react-native';
import { usePalette } from './theme';

export type Stroke = Array<{ x: number; y: number }>;

/** Finger drawing surface. Emits strokes normalized to 0..1 (origin top-left). */
export function SignaturePad({ strokes, onChange, height = 160 }: { strokes: Stroke[]; onChange: (s: Stroke[]) => void; height?: number }) {
  const p = usePalette();
  const [size, setSize] = useState({ w: 1, h: 1 });
  const ref = useRef({ strokes, size, onChange });
  ref.current = { strokes, size, onChange };
  const pan = useMemo(() => PanResponder.create({
    onStartShouldSetPanResponder: () => true,
    onMoveShouldSetPanResponder: () => true,
    onPanResponderTerminationRequest: () => false,
    onPanResponderGrant: (e) => {
      const { size: sz, strokes: cur, onChange: cb } = ref.current;
      cb([...cur, [{ x: e.nativeEvent.locationX / sz.w, y: e.nativeEvent.locationY / sz.h }]]);
    },
    onPanResponderMove: (e) => {
      const { size: sz, strokes: cur, onChange: cb } = ref.current;
      if (!cur.length) return;
      const last = cur[cur.length - 1];
      const pt = { x: Math.min(1, Math.max(0, e.nativeEvent.locationX / sz.w)), y: Math.min(1, Math.max(0, e.nativeEvent.locationY / sz.h)) };
      cb([...cur.slice(0, -1), [...last, pt]]);
    },
  }), []);
  return (
    <View {...pan.panHandlers} onLayout={(e) => setSize({ w: e.nativeEvent.layout.width || 1, h: e.nativeEvent.layout.height || 1 })}
      style={{ height, borderWidth: 1, borderColor: p.border, borderRadius: 10, backgroundColor: p.card, overflow: 'hidden' }}>
      {strokes.map((st, i) => st.map((pt, j) => (
        <View key={i + '-' + j} pointerEvents="none"
          style={{ position: 'absolute', left: pt.x * size.w - 1.5, top: pt.y * size.h - 1.5, width: 3, height: 3, borderRadius: 1.5, backgroundColor: '#1E3A8A' }} />
      )))}
    </View>
  );
}
