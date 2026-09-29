import * as vscode from 'vscode';
import {
  Action,
  documentParams,
  Generated,
  Helper,
  Pick,
  served,
  workspaceEdit,
} from './protocol';

/** The extension's kinds. The plugin's kinds are `refactor.generate.<id>`. */
export const generateKind = vscode.CodeActionKind.Refactor.append('generate').append(
  'dartGenerate',
);
export const fixKind = vscode.CodeActionKind.QuickFix.append('dartGenerate');

/** Opens a field picker. Resolves to the picked names, or `undefined`. */
export type Picker = (
  title: string,
  fields: Pick['fields'],
  ticked: string[],
) => Promise<string[] | undefined>;

/** What `dartGenerate.run` gets from a menu item or a quick fix. */
export interface Run {
  id: string;
  /** The title without "…", for the picker. */
  title: string;
  offset: number;
  length: number;
  pick?: Pick;
  /** A quick fix on a hint: the picker opens with every field ticked. */
  tickAll?: boolean;
}

const fixTitles: Record<string, string> = {
  toString: 'Regenerate toString()…',
  equality: 'Regenerate ==() and hashCode…',
  copyWith: 'Regenerate copyWith()',
  json: 'Regenerate toJson() and fromJson()',
};

/** The Generate… command, the code action provider and the quick fixes. */
export class Generator implements vscode.CodeActionProvider {
  /** The last Generate… result, so the menu does not resolve again. */
  private menu?: { key: string; actions: Action[] };

  constructor(
    private readonly helper: Helper,
    private readonly pick: Picker,
  ) {}

  /** Generate…: asks for every action, then opens the menu with them. */
  async generate(): Promise<void> {
    const editor = vscode.window.activeTextEditor;
    if (!editor || !served(editor.document)) return;
    const document = editor.document;
    const params = documentParams(document, editor.selection);
    // The key names the text that the actions were made for. Read it before
    // the request: an edit during the request must make the menu ask again.
    const key = menuKey(document, params);
    const actions = await this.helper.request<Action[]>(
      'actions',
      { ...params, explicit: true },
      true,
    );
    if (!actions) return;
    if (actions.length === 0) {
      vscode.window.setStatusBarMessage('Put the cursor inside a class.', 5000);
      return;
    }
    this.menu = { key, actions };
    await vscode.commands.executeCommand('editor.action.codeAction', {
      kind: generateKind.value,
      apply: 'never',
    });
  }

  async provideCodeActions(
    document: vscode.TextDocument,
    range: vscode.Range,
    context: vscode.CodeActionContext,
    token: vscode.CancellationToken,
  ): Promise<vscode.CodeAction[]> {
    if (!served(document)) return [];
    const result = context.diagnostics
      .filter((d) => d.source === 'dart_generate')
      .map((d) => this.fix(document, d));
    // Code actions on save ask for `source.*` kinds: no request then.
    if (context.only && !generateKind.intersects(context.only)) return result;
    const explicit = context.only !== undefined && generateKind.contains(context.only);
    const params = documentParams(document, range);
    const key = menuKey(document, params);
    const actions =
      explicit && this.menu?.key === key
        ? this.menu.actions
        : await this.helper.request<Action[]>(
            'actions',
            { ...params, explicit },
            explicit,
            token,
          );
    for (const action of actions ?? []) {
      result.push(this.codeAction(document, params, action));
    }
    return result;
  }

  private codeAction(
    document: vscode.TextDocument,
    params: { offset: number; length: number },
    action: Action,
  ): vscode.CodeAction {
    const item = new vscode.CodeAction(action.title, generateKind.append(action.id));
    if (action.disabledReason) {
      item.disabled = { reason: action.disabledReason };
    } else if (action.edits) {
      item.edit = workspaceEdit(document, action.edits, action.replaces ?? false);
    } else {
      const run: Run = {
        id: action.id,
        title: action.title.replace(/…$/, ''),
        offset: params.offset,
        length: params.length,
        pick: action.pick,
      };
      item.command = {
        title: action.title,
        command: 'dartGenerate.run',
        arguments: [document.uri, run],
      };
    }
    return item;
  }

  /** "Regenerate X" for a stale member, marked as preferred. */
  private fix(
    document: vscode.TextDocument,
    diagnostic: vscode.Diagnostic,
  ): vscode.CodeAction {
    const id = String(diagnostic.code);
    const item = new vscode.CodeAction(fixTitles[id], fixKind);
    item.diagnostics = [diagnostic];
    item.isPreferred = true;
    const run: Run = {
      id,
      title: fixTitles[id].replace(/…$/, ''),
      offset: document.offsetAt(diagnostic.range.start),
      length: 0,
      tickAll: true,
    };
    item.command = {
      title: item.title,
      command: 'dartGenerate.run',
      arguments: [document.uri, run],
    };
    return item;
  }

  /**
   * Runs an action that needs a picker, a composite action, or a quick fix.
   * If the document changes during the request, it asks again. If the text
   * before the offset changed too, it stops: the same line and character can
   * now point into another class.
   */
  async run(uri: vscode.Uri, run: Run): Promise<void> {
    const document = vscode.workspace.textDocuments.find(
      (d) => d.uri.toString() === uri.toString(),
    );
    if (!document) return;
    const range = new vscode.Range(
      document.positionAt(run.offset),
      document.positionAt(run.offset + run.length),
    );
    let fields: string[] | undefined;
    let pick = run.pick;
    if (!pick && run.tickAll && (run.id === 'toString' || run.id === 'equality')) {
      const actions = await this.helper.request<Action[]>(
        'actions',
        { ...documentParams(document, range), explicit: true },
        true,
      );
      pick = actions?.find((a) => a.id === run.id)?.pick;
      if (!pick) return;
    }
    if (pick) {
      const ticked = run.tickAll ? pick.fields.map((f) => f.name) : pick.ticked;
      fields = await this.pick(run.title, pick.fields, ticked);
      if (!fields) return;
    }
    for (let attempt = 0; attempt < 3; attempt++) {
      const version = document.version;
      const params = documentParams(document, range);
      const result = await this.helper.request<Generated>(
        'generate',
        { ...params, action: run.id, fields },
        true,
      );
      if (!result) return;
      if (document.version !== version) {
        const before = params.text.slice(0, params.offset);
        if (document.getText().slice(0, params.offset) !== before) {
          vscode.window.setStatusBarMessage('The file changed. Run the action again.', 5000);
          return;
        }
        continue;
      }
      if (result.edits.length > 0) {
        await vscode.workspace.applyEdit(
          workspaceEdit(document, result.edits, result.replaces),
        );
      }
      if (result.skipped.length > 0) {
        void vscode.window.showInformationMessage(
          `Skipped ${result.skipped.join('; ')}`,
        );
      }
      return;
    }
  }
}

function menuKey(
  document: vscode.TextDocument,
  params: { offset: number; length: number },
): string {
  return `${document.uri} ${document.version} ${params.offset} ${params.length}`;
}

/** The field picker: a QuickPick with a tick box for each field. */
export const quickPick: Picker = (title, fields, ticked) =>
  new Promise((resolve) => {
    const picker = vscode.window.createQuickPick<vscode.QuickPickItem & { name: string }>();
    picker.title = title;
    picker.canSelectMany = true;
    picker.items = fields.map((f) => ({ label: f.name, description: f.type, name: f.name }));
    picker.selectedItems = picker.items.filter((i) => ticked.includes(i.name));
    let picked: string[] | undefined;
    picker.onDidAccept(() => {
      if (picker.selectedItems.length === 0) {
        picker.prompt = 'Pick at least one field';
        return;
      }
      picked = picker.selectedItems.map((i) => i.name);
      picker.hide();
    });
    picker.onDidHide(() => {
      picker.dispose();
      resolve(picked);
    });
    picker.show();
  });
