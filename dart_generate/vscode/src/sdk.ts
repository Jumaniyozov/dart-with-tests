import { existsSync, realpathSync } from 'node:fs';
import { delimiter, dirname, join } from 'node:path';
import * as vscode from 'vscode';

/** The part of the Dart extension's public API that this extension uses. */
export interface DartApi {
  sdks: { dart?: string };
  onSdksChanged: (listener: () => void) => vscode.Disposable;
}

/** The Dart extension's API, or `undefined` when it is not installed. */
export async function dartApi(): Promise<DartApi | undefined> {
  const extension = vscode.extensions.getExtension<DartApi>('Dart-Code.dart-code');
  if (!extension) return undefined;
  return extension.isActive ? extension.exports : await extension.activate();
}

/** The SDK of the first `dart` on PATH, or `undefined`. */
export function sdkFromPath(): string | undefined {
  for (const dir of (process.env.PATH ?? '').split(delimiter)) {
    const dart = join(dir, 'dart');
    if (existsSync(dart)) return sdkOf(dart);
  }
  return undefined;
}

/**
 * The SDK of a `dart` executable. For Flutter's wrapper script,
 * `<flutter>/bin/dart`, it is `<flutter>/bin/cache/dart-sdk`.
 */
export function sdkOf(dart: string): string {
  const bin = dirname(realpathSync(dart));
  const flutter = join(bin, 'cache', 'dart-sdk');
  return existsSync(flutter) ? flutter : dirname(bin);
}
