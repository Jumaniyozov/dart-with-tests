import { ChildProcess, spawn } from 'node:child_process';
import * as vscode from 'vscode';
import {
  CancellationTokenSource,
  createMessageConnection,
  MessageConnection,
  StreamMessageReader,
  StreamMessageWriter,
} from 'vscode-jsonrpc/node';
import { Helper } from './protocol';

/** What the helper needs at each start. */
export interface Setup {
  sdkPath: string;
  folders: string[];
}

/**
 * The helper process. A crash restarts it, up to 3 times in 3 minutes.
 * After that, or when the helper cannot start, [onFailed] runs.
 */
export class HelperProcess implements Helper, vscode.Disposable {
  private child?: ChildProcess;
  private connection?: MessageConnection;
  private crashes: number[] = [];
  private warned = false;

  constructor(
    private readonly command: string,
    private readonly args: string[],
    private readonly setup: () => Setup | undefined,
    private readonly channel: vscode.LogOutputChannel,
    /** Shows a failure that the user must act on. */
    private readonly onFailed: (message: string) => void,
    /** Runs after each start, for example to scan the visible editors. */
    private readonly onStarted: () => void = () => {},
  ) {}

  /** Starts the helper, or restarts it with a new setup. */
  async start(): Promise<void> {
    this.stop();
    const setup = this.setup();
    if (!setup) {
      this.onFailed('the helper did not start.');
      return;
    }
    const child = spawn(this.command, this.args, { stdio: 'pipe' });
    const connection = createMessageConnection(
      new StreamMessageReader(child.stdout),
      new StreamMessageWriter(child.stdin),
    );
    this.child = child;
    this.connection = connection;
    child.stderr.setEncoding('utf8');
    child.stderr.on('data', (text: string) => {
      for (const line of text.trimEnd().split('\n')) {
        if (line.startsWith('ERROR')) this.channel.error(line);
        else this.channel.info(line);
      }
    });
    // A failed spawn gives 'error' and no 'exit'. Either one ends this run.
    const ended = (why: string) => {
      if (this.child !== child) return;
      this.stop();
      this.channel.error(why);
      this.crashed();
    };
    child.on('error', (error) => ended(`The helper did not start: ${error}`));
    child.on('exit', (code) => ended(`The helper exited with code ${code}.`));
    connection.listen();
    let result: { warning: string | null };
    try {
      result = await connection.sendRequest('initialize', setup);
    } catch (error: unknown) {
      // A crash, a restart and dispose() end this run first: stop() clears
      // this.connection before this catch runs. Any other rejection, such as
      // an error answer for a wrong SDK path, leaves a live helper that never
      // initialized. Stop it, so that no request reaches it.
      if (this.connection !== connection) return;
      this.channel.error(
        `initialize: ${error instanceof Error ? error.message : error}`,
      );
      this.stop();
      this.onFailed('the helper did not start.');
      return;
    }
    if (result.warning && !this.warned) {
      this.warned = true;
      void vscode.window.showWarningMessage(result.warning);
    }
    this.onStarted();
  }

  private crashed(): void {
    const now = Date.now();
    this.crashes = this.crashes.filter((t) => now - t < 180_000);
    this.crashes.push(now);
    if (this.crashes.length > 3) {
      this.onFailed('the helper keeps crashing.');
      return;
    }
    void this.start();
  }

  async request<T>(
    method: string,
    params: object,
    explicit: boolean,
    token?: vscode.CancellationToken,
  ): Promise<T | undefined> {
    const connection = this.connection;
    if (!connection) return undefined;
    const source = new CancellationTokenSource();
    const cancel = token?.onCancellationRequested(() => source.cancel());
    try {
      // After the helper's stdout closes and before its exit event, the
      // connection is closed, and sendRequest throws at once.
      const call = connection
        .sendRequest<T>(method, params, source.token)
        .catch((error: unknown) => {
          if (!source.token.isCancellationRequested) {
            this.channel.error(`${method}: ${error}`);
          }
          return undefined;
        });
      if (explicit) {
        return await vscode.window.withProgress(
          {
            location: vscode.ProgressLocation.Window,
            title: 'Dart Generate: analyzing…',
          },
          () => call,
        );
      }
      let timer: NodeJS.Timeout | undefined;
      const timeout = new Promise<undefined>((resolve) => {
        timer = setTimeout(() => {
          source.cancel();
          resolve(undefined);
        }, 5000);
      });
      const result = await Promise.race([call, timeout]);
      clearTimeout(timer);
      return result;
    } catch (error: unknown) {
      this.channel.error(`${method}: ${error}`);
      return undefined;
    } finally {
      cancel?.dispose();
      source.dispose();
    }
  }

  notify(method: string, params: object): void {
    // A closed connection throws at once, as in request().
    try {
      void this.connection?.sendNotification(method, params);
    } catch (error: unknown) {
      this.channel.error(`${method}: ${error}`);
    }
  }

  private stop(): void {
    const child = this.child;
    this.child = undefined;
    this.connection?.dispose();
    this.connection = undefined;
    child?.kill();
  }

  dispose(): void {
    this.stop();
  }
}
