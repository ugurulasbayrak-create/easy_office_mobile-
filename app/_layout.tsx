import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { usePalette } from '../src/ui/theme';

export default function Layout() {
  const p = usePalette();
  return (
    <>
      <StatusBar style={p.bg === '#0B1220' ? 'light' : 'dark'} />
      <Stack screenOptions={{ headerStyle: { backgroundColor: p.card }, headerTintColor: p.text }} />
    </>
  );
}
