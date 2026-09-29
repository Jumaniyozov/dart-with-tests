import * as assert from 'node:assert';
import * as vscode from 'vscode';
import { fixKind, generateKind, Generator } from '../../src/actions';
import { register } from '../../src/extension';
import { Action } from '../../src/protocol';
import { dispose, FakeHelper, FakePicker, openPoint, pointText } from './fakes';

const menu: Action[] = [
  { id: 'dataClass', title: 'Generate data class', disabledReason: null },
  {
    id: 'toString',
    title: 'Generate toString()…',
    disabledReason: null,
    pick: {
      fields: [
        { name: 'x', type: 'int' },
        { name: 'y', type: 'int' },
      ],
      ticked: ['x'],
    },
  },
  {
    id: 'equality',
    title: 'Generate ==() and hashCode…',
    disabledReason: 'a field is not final (mutableClass)',
  },
  {
    id: 'copyWith',
    title: 'Generate copyWith()',
    disabledReason: null,
    edits: [{ offset: 0, length: 0, text: '// copyWith\n' }],
    replaces: false,
  },
];

describe('code actions', () => {
  const disposables: vscode.Disposable[] = [];
  let helper: FakeHelper;
  let picker: FakePicker;
  let editor: vscode.TextEditor;
  let generator: Generator;

  beforeEach(async () => {
    helper = new FakeHelper();
    picker = new FakePicker();
    helper.answers.actions = () => menu;
    generator = register(disposables, helper, picker.pick).generator;
    editor = await openPoint(pointText);
    editor.selection = new vscode.Selection(0, 6, 0, 6);
  });

  afterEach(async () => {
    dispose(disposables);
    await vscode.commands.executeCommand('workbench.action.revertAndCloseActiveEditor');
  });

  async function codeActions(kind?: string): Promise<vscode.CodeAction[]> {
    return vscode.commands.executeCommand<vscode.CodeAction[]>(
      'vscode.executeCodeActionProvider',
      editor.document.uri,
      editor.selection,
      kind,
    );
  }

  /**
   * Calls [target] as VS Code does for a request of [only]. A direct call
   * sees disabled actions, and VS Code's own automatic requests cannot race
   * it.
   */
  function provide(
    only?: vscode.CodeActionKind,
    target = generator,
    diagnostics: vscode.Diagnostic[] = [],
  ) {
    return target.provideCodeActions(
      editor.document,
      editor.selection,
      { only, diagnostics, triggerKind: vscode.CodeActionTriggerKind.Invoke },
      new vscode.CancellationTokenSource().token,
    );
  }

  it('Generate… resolves once and lists the extension kinds with reasons', async () => {
    await vscode.commands.executeCommand('dartGenerate.generate');
    await vscode.commands.executeCommand('hideCodeActionWidget');
    // vscode.executeCodeActionProvider drops disabled actions, so this asks
    // the provider directly, with the kind that the menu asks for.
    const actions = await provide(generateKind);
    assert.deepStrictEqual(
      actions.map((a) => [a.kind?.value, a.disabled?.reason]),
      [
        ['refactor.generate.dartGenerate.dataClass', undefined],
        ['refactor.generate.dartGenerate.toString', undefined],
        ['refactor.generate.dartGenerate.equality', 'a field is not final (mutableClass)'],
        ['refactor.generate.dartGenerate.copyWith', undefined],
      ],
    );
    // VS Code may add automatic requests of its own. Generate… asked once.
    assert.strictEqual(helper.called('actions').filter((c) => c.explicit).length, 1);
  });

  it('a Generate… request does not list the plugin kinds', async () => {
    disposables.push(
      vscode.languages.registerCodeActionsProvider('dart', {
        provideCodeActions: () => [
          new vscode.CodeAction(
            'Generate toString()',
            vscode.CodeActionKind.Refactor.append('generate').append('toString'),
          ),
        ],
      }),
    );
    const kinds = (await codeActions(generateKind.value)).map((a) => a.kind?.value);
    assert.ok(!kinds.includes('refactor.generate.toString'), `${kinds}`);
  });

  it('Cmd+. asks without explicit, and a source request asks nothing', async () => {
    // A provider that VS Code does not know, so only these calls reach it.
    const own = new FakeHelper();
    const unregistered = new Generator(own, picker.pick);
    await provide(undefined, unregistered);
    await provide(vscode.CodeActionKind.Source.append('organizeImports'), unregistered);
    assert.deepStrictEqual(
      own.called('actions').map((c) => c.explicit),
      [false],
    );
  });

  it('a plain edit applies at once', async () => {
    const copyWith = (await provide(generateKind)).find(
      (a) => a.kind?.value === 'refactor.generate.dartGenerate.copyWith',
    )!;
    await vscode.workspace.applyEdit(copyWith.edit!);
    assert.ok(editor.document.getText().startsWith('// copyWith\n'));
  });

  it('a replacement waits in the refactor preview', async () => {
    helper.answers.generate = () => ({
      edits: [{ offset: 0, length: 5, text: 'final class' }],
      replaces: true,
      skipped: [],
    });
    const done = vscode.commands.executeCommand('dartGenerate.run', editor.document.uri, {
      id: 'json',
      title: 'Regenerate toJson() and fromJson()',
      offset: 6,
      length: 0,
    });
    // The preview opens after a moment, with the change unticked. Until the
    // run ends, the text stays as it was, and Discard ends the run.
    let ended = false;
    void done.then(() => (ended = true));
    while (!ended) {
      assert.strictEqual(editor.document.getText(), pointText, 'applied without a preview');
      await vscode.commands.executeCommand('refactorPreview.discard');
      await new Promise((r) => setTimeout(r, 50));
    }
    assert.strictEqual(editor.document.getText(), pointText);
  });

  it('the picker opens with the ticks of the pick', async () => {
    picker.answer = ['y'];
    helper.answers.generate = () => ({ edits: [], replaces: false, skipped: [] });
    const toString = (await provide(generateKind)).find(
      (a) => a.kind?.value === 'refactor.generate.dartGenerate.toString',
    )!;
    await vscode.commands.executeCommand(
      toString.command!.command,
      ...toString.command!.arguments!,
    );
    assert.deepStrictEqual(picker.opened, [{ title: 'Generate toString()', ticked: ['x'] }]);
    assert.deepStrictEqual(helper.called('generate')[0].params.fields, ['y']);
  });

  it('Escape in the picker changes nothing', async () => {
    picker.answer = undefined;
    await vscode.commands.executeCommand('dartGenerate.run', editor.document.uri, {
      id: 'toString',
      title: 'Generate toString()',
      offset: 6,
      length: 0,
      pick: menu[1].pick,
    });
    assert.strictEqual(helper.called('generate').length, 0);
  });

  it('a quick fix on a hint opens the picker with every field ticked', async () => {
    picker.answer = ['x', 'y'];
    helper.answers.generate = () => ({ edits: [], replaces: false, skipped: [] });
    const diagnostic = new vscode.Diagnostic(
      new vscode.Range(0, 6, 0, 11),
      'toString() does not show y.',
      vscode.DiagnosticSeverity.Hint,
    );
    diagnostic.source = 'dart_generate';
    diagnostic.code = 'toString';
    const fix = (await provide(undefined, generator, [diagnostic]))[0];
    assert.strictEqual(fix.kind?.value, fixKind.value);
    assert.ok(fix.isPreferred);
    assert.strictEqual(fix.title, 'Regenerate toString()…');
    await vscode.commands.executeCommand(fix.command!.command, ...fix.command!.arguments!);
    assert.deepStrictEqual(picker.opened, [
      { title: 'Regenerate toString()', ticked: ['x', 'y'] },
    ]);
  });

  it('asks again when the document changes during the request', async () => {
    let first = true;
    helper.answers.generate = async () => {
      if (first) {
        first = false;
        // An edit after the cursor: the text before it stays the same.
        const end = editor.document.positionAt(editor.document.getText().length);
        await editor.edit((b) => b.insert(end, '// typed\n'));
      }
      return { edits: [{ offset: 0, length: 0, text: '// generated\n' }], replaces: false, skipped: [] };
    };
    await vscode.commands.executeCommand('dartGenerate.run', editor.document.uri, {
      id: 'dataClass',
      title: 'Generate data class',
      offset: 6,
      length: 0,
    });
    const calls = helper.called('generate');
    assert.strictEqual(calls.length, 2);
    assert.ok(String(calls[1].params.text).includes('// typed\n'));
    assert.strictEqual(editor.document.getText(), `// generated\n${pointText}// typed\n`);
  });

  it('stops when the text before the cursor changes during the request', async () => {
    let first = true;
    helper.answers.generate = async () => {
      if (first) {
        first = false;
        // An edit above the class: the same line and character now point
        // somewhere else.
        await editor.edit((b) => b.insert(new vscode.Position(0, 0), '// typed\n'));
      }
      return { edits: [{ offset: 0, length: 0, text: '// generated\n' }], replaces: false, skipped: [] };
    };
    await vscode.commands.executeCommand('dartGenerate.run', editor.document.uri, {
      id: 'dataClass',
      title: 'Generate data class',
      offset: 6,
      length: 0,
    });
    assert.strictEqual(helper.called('generate').length, 1);
    assert.strictEqual(editor.document.getText(), `// typed\n${pointText}`);
  });

  it('Generate… does not reuse a menu that was made for older text', async () => {
    let first = true;
    helper.answers.actions = async () => {
      if (first) {
        first = false;
        // An edit after the cursor: the version changes, the cursor does not.
        const end = editor.document.positionAt(editor.document.getText().length);
        await editor.edit((b) => b.insert(end, '// typed\n'));
      }
      return menu;
    };
    await vscode.commands.executeCommand('dartGenerate.generate');
    await vscode.commands.executeCommand('hideCodeActionWidget');
    // The menu asks the provider for the text that it has now. That request
    // must reach the helper, and not be answered with the first result.
    await provide(generateKind);
    const asked = helper.called('actions').filter((c) => c.explicit);
    assert.ok(asked.length >= 2, `${asked.length} explicit requests`);
    assert.strictEqual(asked[asked.length - 1].params.text, editor.document.getText());
  });
});
