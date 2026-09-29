import * as vscode from 'vscode';
import { Helper, served, StaleResult } from './protocol';

/** The marks on stale generated members (ADR 0008). */
export class StaleScan implements vscode.Disposable {
  readonly diagnostics = vscode.languages.createDiagnosticCollection('dart_generate');
  private readonly timers = new Map<string, NodeJS.Timeout>();

  constructor(private readonly helper: Helper) {}

  /** Scans [document] 500 ms after the last call for it. */
  schedule(document: vscode.TextDocument): void {
    const key = document.uri.toString();
    clearTimeout(this.timers.get(key));
    this.timers.set(
      key,
      setTimeout(() => {
        this.timers.delete(key);
        void this.scan(document);
      }, 500),
    );
  }

  /** Scans each document that a visible editor shows. */
  scanVisible(): void {
    const documents = new Set(vscode.window.visibleTextEditors.map((e) => e.document));
    for (const document of documents) void this.scan(document);
  }

  async scan(document: vscode.TextDocument): Promise<void> {
    if (!served(document)) return;
    const version = document.version;
    const result = await this.helper.request<StaleResult>(
      'stale',
      { path: document.uri.fsPath, text: document.getText() },
      false,
    );
    // A syntax error keeps the previous marks, so they do not flicker.
    if (!result || 'skipped' in result) return;
    if (document.isClosed || document.version !== version) return;
    this.diagnostics.set(
      document.uri,
      result.items.map((item) => {
        const range = new vscode.Range(
          document.positionAt(item.offset),
          document.positionAt(item.offset + item.length),
        );
        const diagnostic = new vscode.Diagnostic(
          range,
          item.message,
          item.severity === 'warning'
            ? vscode.DiagnosticSeverity.Warning
            : vscode.DiagnosticSeverity.Hint,
        );
        diagnostic.source = 'dart_generate';
        diagnostic.code = item.id;
        return diagnostic;
      }),
    );
  }

  closed(document: vscode.TextDocument): void {
    clearTimeout(this.timers.get(document.uri.toString()));
    this.diagnostics.delete(document.uri);
  }

  dispose(): void {
    for (const timer of this.timers.values()) clearTimeout(timer);
    this.diagnostics.dispose();
  }
}
