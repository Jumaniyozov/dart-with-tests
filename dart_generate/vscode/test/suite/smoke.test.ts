import * as assert from 'node:assert';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import * as vscode from 'vscode';
import { generateKind } from '../../src/actions';
import { register } from '../../src/extension';
import { HelperProcess } from '../../src/helper';
import { sdkFromPath } from '../../src/sdk';
import { dispose, FakePicker, openPoint } from './fakes';

/** Runs only after `npm run package` built bin/helper. */
describe('smoke: the compiled helper', function () {
  const binary = resolve(__dirname, '../../../bin/helper');
  const disposables: vscode.Disposable[] = [];

  before(function () {
    if (!existsSync(binary)) this.skip();
  });

  after(async () => {
    dispose(disposables);
    await vscode.commands.executeCommand('workbench.action.revertAndCloseActiveEditor');
  });

  it('lists the menu and marks a stale toString', async () => {
    const channel = vscode.window.createOutputChannel('Dart Generate smoke', { log: true });
    const folder = vscode.workspace.workspaceFolders![0].uri.fsPath;
    const helper = new HelperProcess(
      binary,
      [],
      () => ({ sdkPath: sdkFromPath()!, folders: [folder] }),
      channel,
      () => assert.fail('the helper crashed'),
    );
    disposables.push(channel, helper);
    await helper.start();
    const { generator, stale } = register(disposables, helper, new FakePicker().pick);
    const editor = await openPoint(`class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);

  @override
  String toString() => 'Point(x: $x)';
}
`);
    const actions = await generator.provideCodeActions(
      editor.document,
      new vscode.Range(0, 6, 0, 6),
      { only: generateKind, diagnostics: [], triggerKind: vscode.CodeActionTriggerKind.Invoke },
      new vscode.CancellationTokenSource().token,
    );
    assert.deepStrictEqual(
      actions.map((a) => a.title),
      [
        'Regenerate data class',
        'Regenerate toString()…',
        'Generate ==() and hashCode…',
        'Generate copyWith()',
        'Generate toJson() and fromJson()',
        'Generate getter…',
        'Convert to primary constructor',
      ],
    );
    await stale.scan(editor.document);
    assert.deepStrictEqual(
      stale.diagnostics.get(editor.document.uri)!.map((d) => d.message),
      ['toString() does not show y.'],
    );
  });

  it('says that it did not start for a wrong SDK path', async () => {
    const channel = vscode.window.createOutputChannel('Dart Generate smoke', { log: true });
    let helper: HelperProcess | undefined;
    const failed = new Promise<string>((resolve) => {
      helper = new HelperProcess(
        binary,
        [],
        () => ({ sdkPath: '/no/such/sdk', folders: [] }),
        channel,
        resolve,
      );
      void helper.start();
    });
    disposables.push(channel, helper!);
    assert.strictEqual(await failed, 'the helper did not start.');
  });
});
