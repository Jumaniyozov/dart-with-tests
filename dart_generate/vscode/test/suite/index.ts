import Mocha from 'mocha';
import { readdirSync } from 'node:fs';
import { join } from 'node:path';

export function run(): Promise<void> {
  const mocha = new Mocha({ ui: 'bdd', timeout: 20_000 });
  for (const file of readdirSync(__dirname)) {
    if (file.endsWith('.test.js')) mocha.addFile(join(__dirname, file));
  }
  return new Promise((resolve, reject) =>
    mocha.run((failures) =>
      failures > 0 ? reject(new Error(`${failures} tests failed`)) : resolve(),
    ),
  );
}
