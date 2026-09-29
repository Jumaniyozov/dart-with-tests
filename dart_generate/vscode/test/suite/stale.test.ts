import * as assert from 'node:assert';
import * as vscode from 'vscode';
import { StaleScan } from '../../src/stale';
import { FakeHelper, openPoint, pointText } from './fakes';

describe('stale members', () => {
  let helper: FakeHelper;
  let scan: StaleScan;
  let editor: vscode.TextEditor;

  beforeEach(async () => {
    helper = new FakeHelper();
    scan = new StaleScan(helper);
    editor = await openPoint(pointText);
  });

  afterEach(async () => {
    scan.dispose();
    await vscode.commands.executeCommand('workbench.action.revertAndCloseActiveEditor');
  });

  const items = {
    items: [
      {
        offset: 6,
        length: 5,
        id: 'copyWith',
        severity: 'warning',
        message: 'copyWith() does not cover y.',
        missing: ['y'],
      },
      {
        offset: 21,
        length: 1,
        id: 'toString',
        severity: 'hint',
        message: 'toString() does not show y.',
        missing: ['y'],
      },
    ],
  };

  function marks(): [string, vscode.DiagnosticSeverity, string | number | undefined][] {
    return scan.diagnostics
      .get(editor.document.uri)!
      .map((d) => [d.message, d.severity, d.code as string]);
  }

  it('turns items into warnings and hints with the member range', async () => {
    helper.answers.stale = () => items;
    await scan.scan(editor.document);
    assert.deepStrictEqual(marks(), [
      ['copyWith() does not cover y.', vscode.DiagnosticSeverity.Warning, 'copyWith'],
      ['toString() does not show y.', vscode.DiagnosticSeverity.Hint, 'toString'],
    ]);
    const range = scan.diagnostics.get(editor.document.uri)![0].range;
    assert.strictEqual(editor.document.getText(range), 'Point');
  });

  it('keeps the previous marks for a file with a syntax error', async () => {
    helper.answers.stale = () => items;
    await scan.scan(editor.document);
    helper.answers.stale = () => ({ skipped: true });
    await scan.scan(editor.document);
    assert.strictEqual(marks().length, 2);
  });

  it('drops a result for an older version of the document', async () => {
    helper.answers.stale = async () => {
      await editor.edit((b) => b.insert(new vscode.Position(0, 0), '// typed\n'));
      return items;
    };
    await scan.scan(editor.document);
    assert.strictEqual(scan.diagnostics.get(editor.document.uri)?.length ?? 0, 0);
  });

  it('clears the marks of a closed document', async () => {
    helper.answers.stale = () => items;
    await scan.scan(editor.document);
    scan.closed(editor.document);
    assert.strictEqual(scan.diagnostics.get(editor.document.uri)?.length ?? 0, 0);
  });
});
