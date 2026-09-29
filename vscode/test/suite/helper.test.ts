import * as assert from 'node:assert';
import { mkdirSync, mkdtempSync, realpathSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import * as vscode from 'vscode';
import { HelperProcess } from '../../src/helper';
import { served } from '../../src/protocol';
import { sdkOf } from '../../src/sdk';

describe('the helper process', () => {
  // One channel for the whole block. VS Code caches a log channel by its name.
  // A channel that a test disposes before its set-up ends stays in that cache.
  // The next createOutputChannel with the same name then returns it, closed.
  let channel: vscode.LogOutputChannel;
  before(() => {
    channel = vscode.window.createOutputChannel('Dart Generate test', { log: true });
  });
  after(() => channel.dispose());

  it('restarts a crashing helper 3 times, then gives up', async () => {
    let starts = 0;
    const gaveUp = new Promise<string>((resolve) => {
      const helper = new HelperProcess(
        '/bin/sh',
        ['-c', 'exit 3'],
        () => {
          starts++;
          return { sdkPath: '/sdk', folders: [] };
        },
        channel,
        resolve,
      );
      void helper.start();
    });
    assert.strictEqual(await gaveUp, 'the helper keeps crashing.');
    assert.strictEqual(starts, 4);
  });

  it('without an SDK, says so and answers undefined', async () => {
    const failures: string[] = [];
    const helper = new HelperProcess('/bin/sh', [], () => undefined, channel, (m) =>
      failures.push(m),
    );
    await helper.start();
    assert.deepStrictEqual(failures, ['the helper did not start.']);
    assert.strictEqual(await helper.request('actions', {}, false), undefined);
  });

  it('stops a helper that answers initialize with an error', async () => {
    // A fake helper. It reads the header of the first request, answers it with
    // an internal error (id 0: vscode-jsonrpc numbers its requests from 0),
    // and then stays alive.
    const body = '{"jsonrpc":"2.0","id":0,"error":{"code":-32603,"message":"no SDK"}}';
    const script =
      `read -r _; printf 'Content-Length: ${Buffer.byteLength(body)}\\r\\n\\r\\n%s' '${body}'; ` +
      'exec sleep 30';
    let starts = 0;
    const failures: string[] = [];
    const helper = new HelperProcess(
      '/bin/sh',
      ['-c', script],
      () => {
        starts++;
        return { sdkPath: '/sdk', folders: [] };
      },
      channel,
      (m) => failures.push(m),
    );
    try {
      await helper.start();
      assert.deepStrictEqual(failures, ['the helper did not start.']);
      // A helper that is still wired in would hold this request for the 5 s
      // timeout of an automatic request.
      const began = Date.now();
      assert.strictEqual(await helper.request('actions', {}, false), undefined);
      assert.ok(Date.now() - began < 1000, 'the request reached a stopped helper');
      // Stopping the helper ends its process. That end is not a crash.
      await new Promise((resolve) => setTimeout(resolve, 300));
      assert.strictEqual(starts, 1);
      assert.strictEqual(failures.length, 1);
    } finally {
      helper.dispose();
    }
  });

  it('answers undefined after the helper closes its stdout', async () => {
    // A fake helper. It answers initialize (id 0), closes its stdout, and
    // then stays alive. Until its exit, vscode-jsonrpc throws at once on each
    // send: "Connection is closed."
    const body = '{"jsonrpc":"2.0","id":0,"result":{"warning":null}}';
    const script =
      `read -r _; printf 'Content-Length: ${Buffer.byteLength(body)}\\r\\n\\r\\n%s' '${body}'; ` +
      'exec 1>&-; exec sleep 30';
    const failures: string[] = [];
    const helper = new HelperProcess(
      '/bin/sh',
      ['-c', script],
      () => ({ sdkPath: '/sdk', folders: [] }),
      channel,
      (m) => failures.push(m),
    );
    try {
      await helper.start();
      assert.deepStrictEqual(failures, []);
      // The connection sees the closed stdout after a moment.
      await new Promise((resolve) => setTimeout(resolve, 300));
      // A request that reached the helper would wait for the 5 s timeout.
      const began = Date.now();
      assert.strictEqual(await helper.request('actions', {}, false), undefined);
      assert.ok(Date.now() - began < 1000, 'the request did not meet a closed connection');
      assert.doesNotThrow(() => helper.notify('closed', { path: 'x' }));
    } finally {
      helper.dispose();
    }
  });
});

describe('the SDK path', () => {
  // realpath: on macOS, /var is a link to /private/var.
  const root = realpathSync(mkdtempSync(join(tmpdir(), 'dart_generate_sdk_')));

  it('is two levels above the real dart executable', () => {
    mkdirSync(join(root, 'sdk/bin'), { recursive: true });
    writeFileSync(join(root, 'sdk/bin/dart'), '');
    mkdirSync(join(root, 'links'));
    symlinkSync(join(root, 'sdk/bin/dart'), join(root, 'links/dart'));
    assert.strictEqual(sdkOf(join(root, 'links/dart')), join(root, 'sdk'));
  });

  it('is bin/cache/dart-sdk for the Flutter wrapper', () => {
    mkdirSync(join(root, 'flutter/bin/cache/dart-sdk'), { recursive: true });
    writeFileSync(join(root, 'flutter/bin/dart'), '');
    assert.strictEqual(
      sdkOf(join(root, 'flutter/bin/dart')),
      join(root, 'flutter/bin/cache/dart-sdk'),
    );
  });
});

describe('served documents', () => {
  it('skips a document for each check that it fails', async () => {
    const folder = vscode.workspace.workspaceFolders![0].uri;
    const inFolder = (name: string) => vscode.Uri.joinPath(folder, 'lib', name);
    // served reads only languageId, uri and getText.
    const fake = (uri: vscode.Uri, text = 'class A {}\n', languageId = 'dart') =>
      ({ languageId, uri, getText: () => text }) as vscode.TextDocument;
    const point = await vscode.workspace.openTextDocument(inFolder('point.dart'));
    // Each row fails one check. Only the untitled row fails a second one: an
    // untitled document has no workspace folder.
    const rows: [string, vscode.TextDocument, boolean][] = [
      ['a Dart file in the workspace', point, true],
      ['not Dart', fake(inFolder('notes.txt'), undefined, 'plaintext'), false],
      ['not a file: document', fake(vscode.Uri.parse('untitled:Untitled-1')), false],
      [
        'outside every workspace folder',
        fake(vscode.Uri.file(join(tmpdir(), 'outside.dart'))),
        false,
      ],
      ['.g.dart', fake(inFolder('point.g.dart')), false],
      ['.freezed.dart', fake(inFolder('point.freezed.dart')), false],
      [
        'generated header',
        fake(inFolder('header.dart'), '// GENERATED CODE - DO NOT MODIFY BY HAND\nclass A {}\n'),
        false,
      ],
    ];
    for (const [name, document, expected] of rows) {
      assert.strictEqual(served(document), expected, name);
    }
  });
});
