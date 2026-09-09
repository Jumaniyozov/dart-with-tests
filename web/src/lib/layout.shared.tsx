import type { BaseLayoutProps } from 'fumadocs-ui/layouts/shared';
import { Lockup } from '@/components/mark';
import { appName } from './shared';

export function baseOptions(): BaseLayoutProps {
  return {
    nav: {
      // The mark rides on `--rail` cloth, which is the same colour in both
      // themes, so the nav needs no light and dark variant of the logo.
      title: <Lockup appName={appName} />,
    },
    // Three states, not two. "System" is a real choice and hiding it forces a
    // reader who follows their OS to keep re-picking a theme.
    themeSwitch: { mode: 'light-dark-system' },
  };
}
