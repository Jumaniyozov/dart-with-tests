import * as vscode from 'vscode';
import { Picker } from '../../src/actions';
import { Helper } from '../../src/protocol';

/** One call that the fake helper received. */
export interface Call {
  method: string;
  params: Record<string, unknown>;
  explicit: boolean;
}

/** A helper that answers from [answers] and records each call. */
export class FakeHelper implements Helper {
  readonly calls: Call[] = [];
  answers: Record<string, (params: Record<string, unknown>) => unknown> = {};

  async request<T>(method: string, params: object, explicit: boolean): Promise<T | undefined> {
    const p = params as Record<string, unknown>;
    this.calls.push({ method, params: p, explicit });
    return (await this.answers[method]?.(p)) as T | undefined;
  }

  notify(method: string, params: object): void {
    this.calls.push({ method, params: params as Record<string, unknown>, explicit: false });
  }

  called(method: string): Call[] {
    return this.calls.filter((c) => c.method === method);
  }
}

/** A picker that records its arguments and answers [answer]. */
export class FakePicker {
  readonly opened: { title: string; ticked: string[] }[] = [];
  answer: string[] | undefined = undefined;
  readonly pick: Picker = async (title, _fields, ticked) => {
    this.opened.push({ title, ticked });
    return this.answer;
  };
}

/** Opens test/workspace/lib/point.dart with [text] in a fresh editor. */
export async function openPoint(text: string): Promise<vscode.TextEditor> {
  const folder = vscode.workspace.workspaceFolders![0].uri;
  const uri = vscode.Uri.joinPath(folder, 'lib', 'point.dart');
  const document = await vscode.workspace.openTextDocument(uri);
  const editor = await vscode.window.showTextDocument(document);
  await editor.edit((b) =>
    b.replace(new vscode.Range(0, 0, document.lineCount, 0), text),
  );
  return editor;
}

export const pointText = `class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);
}
`;

export function dispose(disposables: vscode.Disposable[]): void {
  for (const d of disposables.splice(0)) d.dispose();
}
