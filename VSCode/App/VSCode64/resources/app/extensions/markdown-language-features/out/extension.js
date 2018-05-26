"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
const markdownEngine_1 = require("./markdownEngine");
const security_1 = require("./security");
const logger_1 = require("./logger");
const commandManager_1 = require("./commandManager");
const commands = require("./commands/index");
const telemetryReporter_1 = require("./telemetryReporter");
const markdownExtensions_1 = require("./markdownExtensions");
const documentLinkProvider_1 = require("./features/documentLinkProvider");
const documentSymbolProvider_1 = require("./features/documentSymbolProvider");
const previewContentProvider_1 = require("./features/previewContentProvider");
const previewManager_1 = require("./features/previewManager");
const foldingProvider_1 = require("./features/foldingProvider");
function activate(context) {
    const telemetryReporter = telemetryReporter_1.loadDefaultTelemetryReporter();
    context.subscriptions.push(telemetryReporter);
    const contributions = markdownExtensions_1.getMarkdownExtensionContributions();
    const cspArbiter = new security_1.ExtensionContentSecurityPolicyArbiter(context.globalState, context.workspaceState);
    const engine = new markdownEngine_1.MarkdownEngine(contributions);
    const logger = new logger_1.Logger();
    const selector = 'markdown';
    const contentProvider = new previewContentProvider_1.MarkdownContentProvider(engine, context, cspArbiter, contributions, logger);
    const previewManager = new previewManager_1.MarkdownPreviewManager(contentProvider, logger, contributions);
    context.subscriptions.push(previewManager);
    context.subscriptions.push(vscode.languages.registerDocumentSymbolProvider(selector, new documentSymbolProvider_1.default(engine)));
    context.subscriptions.push(vscode.languages.registerDocumentLinkProvider(selector, new documentLinkProvider_1.default()));
    context.subscriptions.push(vscode.languages.registerFoldingProvider(selector, new foldingProvider_1.default(engine)));
    const previewSecuritySelector = new security_1.PreviewSecuritySelector(cspArbiter, previewManager);
    const commandManager = new commandManager_1.CommandManager();
    context.subscriptions.push(commandManager);
    commandManager.register(new commands.ShowPreviewCommand(previewManager, telemetryReporter));
    commandManager.register(new commands.ShowPreviewToSideCommand(previewManager, telemetryReporter));
    commandManager.register(new commands.ShowLockedPreviewToSideCommand(previewManager, telemetryReporter));
    commandManager.register(new commands.ShowSourceCommand(previewManager));
    commandManager.register(new commands.RefreshPreviewCommand(previewManager));
    commandManager.register(new commands.MoveCursorToPositionCommand());
    commandManager.register(new commands.ShowPreviewSecuritySelectorCommand(previewSecuritySelector, previewManager));
    commandManager.register(new commands.OnPreviewStyleLoadErrorCommand());
    commandManager.register(new commands.OpenDocumentLinkCommand(engine));
    commandManager.register(new commands.ToggleLockCommand(previewManager));
    context.subscriptions.push(vscode.workspace.onDidChangeConfiguration(() => {
        logger.updateConfiguration();
        previewManager.updateConfiguration();
    }));
}
exports.activate = activate;
//# sourceMappingURL=https://ticino.blob.core.windows.net/sourcemaps/3aeede733d9a3098f7b4bdc1f66b63b0f48c1ef9/extensions\markdown-language-features\out/extension.js.map
