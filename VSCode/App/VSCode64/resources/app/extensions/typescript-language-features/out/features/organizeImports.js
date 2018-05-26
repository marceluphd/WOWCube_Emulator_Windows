"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
const typeconverts = require("../utils/typeConverters");
const languageModeIds_1 = require("../utils/languageModeIds");
class OrganizeImportsCommand {
    constructor(lazyClientHost) {
        this.lazyClientHost = lazyClientHost;
        this.id = OrganizeImportsCommand.Ids;
    }
    async execute() {
        // Don't force activation
        if (!this.lazyClientHost.hasValue) {
            return false;
        }
        const client = this.lazyClientHost.value.serviceClient;
        if (!client.apiVersion.has280Features()) {
            return false;
        }
        const editor = vscode.window.activeTextEditor;
        if (!editor || !languageModeIds_1.isSupportedLanguageMode(editor.document)) {
            return false;
        }
        const file = client.normalizePath(editor.document.uri);
        if (!file) {
            return false;
        }
        const args = {
            scope: {
                type: 'file',
                args: {
                    file
                }
            }
        };
        const response = await client.execute('organizeImports', args);
        if (!response || !response.success) {
            return false;
        }
        const edits = typeconverts.WorkspaceEdit.fromFromFileCodeEdits(client, response.body);
        return await vscode.workspace.applyEdit(edits);
    }
}
OrganizeImportsCommand.Ids = ['javascript.organizeImports', 'typescript.organizeImports'];
exports.OrganizeImportsCommand = OrganizeImportsCommand;
/**
 * When clause context set when the ts version supports organize imports.
 */
const contextName = 'typescript.canOrganizeImports';
class OrganizeImportsContextManager {
    constructor() {
        this.currentValue = false;
    }
    onDidChangeApiVersion(apiVersion) {
        this.updateContext(apiVersion.has280Features());
    }
    updateContext(newValue) {
        if (newValue === this.currentValue) {
            return;
        }
        vscode.commands.executeCommand('setContext', contextName, newValue);
        this.currentValue = newValue;
    }
}
exports.OrganizeImportsContextManager = OrganizeImportsContextManager;
//# sourceMappingURL=https://ticino.blob.core.windows.net/sourcemaps/3aeede733d9a3098f7b4bdc1f66b63b0f48c1ef9/extensions\typescript-language-features\out/features\organizeImports.js.map
