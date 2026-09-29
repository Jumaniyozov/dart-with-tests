import * as vscode from 'vscode';
import { Generator, generateKind, fixKind, Picker, quickPick, Run } from './actions';
import { HelperProcess } from './helper';
import { Helper, served } from './protocol';
import { dartApi, sdkFromPath } from './sdk';
import { StaleScan } from './stale';

export async function activate(context: vscode.ExtensionContext): Promise<void> {
  const channel = vscode.window.createOutputChannel('Dart Generate', { log: true });
  // The Dart extension is not a hard dependency: without its API, the SDK
  // comes from PATH.
  const dart = await dartApi().catch((error: unknown) => {
    channel.error(`Dart extension: ${error}`);
    return undefined;
  });
  const helper = new HelperProcess(
    context.asAbsolutePath('bin/helper'),
    [],
    () => {
      const sdkPath = dart?.sdks.dart ?? sdkFromPath();
      if (!sdkPath) {
        channel.error('No Dart SDK: install the Dart extension or put dart on PATH.');
        return undefined;
      }
      const folders = (vscode.workspace.workspaceFolders ?? [])
        .filter((f) => f.uri.scheme === 'file')
        .map((f) => f.uri.fsPath);
      return { sdkPath, folders };
    },
    channel,
    (message) => {
      void vscode.window
        .showErrorMessage(`Dart Generate: ${message}`, 'Show Output')
        .then((choice) => choice && channel.show());
    },
    // The stale scan of the visible files also resolves them.
    () => stale.scanVisible(),
  );
  context.subscriptions.push(
    channel,
    helper,
    vscode.commands.registerCommand('dartGenerate.restartHelper', () => helper.start()),
    vscode.commands.registerCommand('dartGenerate.showOutput', () => channel.show()),
    vscode.workspace.onDidChangeWorkspaceFolders(() => helper.start()),
  );
  if (dart) context.subscriptions.push(dart.onSdksChanged(() => void helper.start()));
  const { stale } = register(context.subscriptions, helper, quickPick);
  await helper.start();
}

/**
 * Registers the provider, the commands and the stale scan on [helper]. The
 * tests call it with a fake helper and a fake picker.
 */
export function register(
  subscriptions: vscode.Disposable[],
  helper: Helper,
  pick: Picker,
): { generator: Generator; stale: StaleScan } {
  const generator = new Generator(helper, pick);
  const stale = new StaleScan(helper);
  const watcher = vscode.workspace.createFileSystemWatcher('**/*.dart');
  // A checkout changes many files at once. schedule() waits for the last one.
  const changed = (uri: vscode.Uri) => {
    helper.notify('filesChanged', { paths: [uri.fsPath] });
    for (const editor of vscode.window.visibleTextEditors) stale.schedule(editor.document);
  };
  subscriptions.push(
    stale,
    watcher,
    vscode.languages.registerCodeActionsProvider(
      { language: 'dart', scheme: 'file' },
      generator,
      { providedCodeActionKinds: [generateKind, fixKind] },
    ),
    vscode.commands.registerCommand('dartGenerate.generate', () => generator.generate()),
    vscode.commands.registerCommand('dartGenerate.run', (uri: vscode.Uri, run: Run) =>
      generator.run(uri, run),
    ),
    vscode.window.onDidChangeVisibleTextEditors(() => stale.scanVisible()),
    vscode.workspace.onDidChangeTextDocument((e) => {
      if (vscode.window.visibleTextEditors.some((v) => v.document === e.document)) {
        stale.schedule(e.document);
      }
    }),
    vscode.workspace.onDidCloseTextDocument((document) => {
      stale.closed(document);
      if (served(document)) helper.notify('closed', { path: document.uri.fsPath });
    }),
    watcher.onDidChange(changed),
    watcher.onDidCreate(changed),
    watcher.onDidDelete(changed),
  );
  return { generator, stale };
}
