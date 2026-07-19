/*
 * SwoftLang VS Code extension entry point.
 *
 *  - Launches the LSP server (out/src/server.js) over Node IPC.
 *  - Registers the debug tracer (WebSocket client + editor decorations).
 *  - Wires the connect/disconnect commands and the settings.
 *
 * The TextMate grammar and the language contribution are declared in
 * package.json, so highlighting works without any code here.
 */
import * as path from 'path';
import * as vscode from 'vscode';
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind,
} from 'vscode-languageclient/node';
import { DebugTracer, TracerHost, scriptsRelativeToUri } from './tracer';

let client: LanguageClient | undefined;
let tracer: DebugTracer | undefined;

function cfg(): vscode.WorkspaceConfiguration {
  return vscode.workspace.getConfiguration('swoftlang');
}

function workspaceRoot(): string | undefined {
  const folders = vscode.workspace.workspaceFolders;
  return folders && folders.length > 0 ? folders[0].uri.fsPath : undefined;
}

export function activate(context: vscode.ExtensionContext): void {
  startLanguageClient(context);

  // hello.scriptsDir is remembered here so trace paths can be resolved even
  // before the setting is filled in.
  let helloScriptsDir: string | undefined;

  const host: TracerHost = {
    resolveFile(file: string): vscode.Uri | undefined {
      const scriptsDir = this.scriptsDir();
      const fsPath = scriptsRelativeToUri(scriptsDir, file, workspaceRoot());
      return fsPath ? vscode.Uri.file(fsPath) : undefined;
    },
    scriptsDir(): string | undefined {
      const setting = cfg().get<string>('scriptsDir');
      if (setting && setting.trim()) return setting.trim();
      if (helloScriptsDir) return helloScriptsDir;
      const root = workspaceRoot();
      return root ? path.join(root, 'scripts') : undefined;
    },
    setScriptsDirFromHello(dir: string): void {
      helloScriptsDir = dir;
    },
    autoReveal(): boolean {
      return cfg().get<boolean>('debug.autoReveal', true);
    },
    followExecution(): boolean {
      return cfg().get<boolean>('debug.followExecution', false);
    },
  };

  tracer = new DebugTracer(
    host,
    context,
    () => cfg().get<number>('debugPort', 25580),
    () => 'localhost',
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('swoftlang.debug.connect', () => {
      tracer?.connect();
    }),
    vscode.commands.registerCommand('swoftlang.debug.disconnect', () => {
      tracer?.disconnect();
    }),
  );

  if (cfg().get<boolean>('debug.autoConnect', false)) {
    tracer.connect();
  }
}

function startLanguageClient(context: vscode.ExtensionContext): void {
  const serverModule = context.asAbsolutePath(path.join('out', 'src', 'server.js'));
  const debugOpts = { execArgv: ['--nolazy', '--inspect=6009'] };

  const serverOptions: ServerOptions = {
    run: { module: serverModule, transport: TransportKind.ipc },
    debug: { module: serverModule, transport: TransportKind.ipc, options: debugOpts },
  };

  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: 'file', language: 'swoftlang' }],
    synchronize: {
      configurationSection: 'swoftlang',
      fileEvents: vscode.workspace.createFileSystemWatcher('**/*.sw'),
    },
    initializationOptions: {
      swoftcPath: cfg().get<string>('swoftcPath', ''),
      scriptsDir: cfg().get<string>('scriptsDir', ''),
    },
  };

  client = new LanguageClient(
    'swoftlang',
    'SwoftLang Language Server',
    serverOptions,
    clientOptions,
  );
  client.start();
  context.subscriptions.push({ dispose: () => client?.stop() });
}

export function deactivate(): Thenable<void> | undefined {
  tracer?.dispose();
  return client ? client.stop() : undefined;
}
