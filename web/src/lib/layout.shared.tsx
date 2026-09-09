import type { BaseLayoutProps } from 'fumadocs-ui/layouts/shared';
import { appName } from './shared';

export function baseOptions(): BaseLayoutProps {
  return {
    nav: {
      // JSX supported
      title: appName,
    },
    // Three states, not two. "System" is a real choice and hiding it forces a
    // reader who follows their OS to keep re-picking a theme.
    themeSwitch: { mode: 'light-dark-system' },
  };
}
