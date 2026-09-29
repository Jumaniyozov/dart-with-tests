// The JSON-RPC messages between the extension and the Dart helper. The
// helper's side is in helper/lib/src/helper.dart.

import * as vscode from 'vscode';

/** A replacement in the text of the request, in UTF-16 offsets. */
export interface Edit {
  offset: number;
  length: number;
  text: string;
}

export interface Pick {
  fields: { name: string; type: string }[];
  /** The fields ticked when the picker opens. */
  ticked: string[];
}

export interface Action {
  id: string;
  title: string;
  disabledReason: string | null;
  edits?: Edit[];
  replaces?: boolean;
  pick?: Pick;
}

export interface Generated {
  edits: Edit[];
  replaces: boolean;
  skipped: string[];
}

export interface StaleItem {
  offset: number;
  length: number;
  id: string;
  severity: 'warning' | 'hint';
  message: string;
  missing: string[];
}

export type StaleResult = { skipped: true } | { items: StaleItem[] };

/** The helper as the providers see it. */
export interface Helper {
  /**
   * Sends a request. It resolves to `undefined` when the helper is not
   * running, when it answers with an error, or when an automatic request
   * takes longer than 5 s. An explicit request waits and shows progress.
   */
  request<T>(
    method: string,
    params: object,
    explicit: boolean,
    token?: vscode.CancellationToken,
  ): Promise<T | undefined>;
  notify(method: string, params: object): void;
}

/** The path, text, line ending and selection of a request. */
export function documentParams(document: vscode.TextDocument, range: vscode.Range) {
  const offset = document.offsetAt(range.start);
  return {
    path: document.uri.fsPath,
    text: document.getText(),
    eol: document.eol === vscode.EndOfLine.CRLF ? '\r\n' : '\n',
    offset,
    length: document.offsetAt(range.end) - offset,
  };
}

/**
 * Whether the extension serves [document]: a Dart file inside a workspace
 * folder that is not generated code.
 */
export function served(document: vscode.TextDocument): boolean {
  return (
    document.languageId === 'dart' &&
    document.uri.scheme === 'file' &&
    vscode.workspace.getWorkspaceFolder(document.uri) !== undefined &&
    !/\.(g|freezed)\.dart$/.test(document.uri.path) &&
    !document.getText().slice(0, 500).includes('GENERATED CODE - DO NOT MODIFY')
  );
}

/** A workspace edit for [edits]. A replacement opens the refactor preview. */
export function workspaceEdit(
  document: vscode.TextDocument,
  edits: Edit[],
  replaces: boolean,
): vscode.WorkspaceEdit {
  const edit = new vscode.WorkspaceEdit();
  const metadata = replaces
    ? { label: 'Dart Generate', needsConfirmation: true }
    : undefined;
  for (const e of edits) {
    const range = new vscode.Range(
      document.positionAt(e.offset),
      document.positionAt(e.offset + e.length),
    );
    edit.replace(document.uri, range, e.text, metadata);
  }
  return edit;
}
