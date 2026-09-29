// Runs the Mocha suite in VS Code 1.139.1. The window opens test/workspace
// with the stub extension, so no real helper starts by itself.
import { runTests } from '@vscode/test-electron';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const root = resolve(__dirname, '../..');
// macOS limits a socket path to 103 characters, and VS Code puts its socket
// in the user data folder. A folder under the temp folder stays short.
const userData = mkdtempSync(join(tmpdir(), 'dart-generate-test-'));

runTests({
  version: '1.139.1',
  extensionDevelopmentPath: resolve(root, 'test/stub'),
  extensionTestsPath: resolve(__dirname, 'suite/index'),
  launchArgs: [
    resolve(root, 'test/workspace'),
    '--disable-extensions',
    `--user-data-dir=${userData}`,
  ],
}).catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
