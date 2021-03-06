"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
Object.defineProperty(exports, "__esModule", { value: true });
const vscode_1 = require("vscode");
const typeConverters = require("../utils/typeConverters");
class TypeScriptDocumentHighlightProvider {
    constructor(client) {
        this.client = client;
    }
    async provideDocumentHighlights(resource, position, token) {
        const file = this.client.normalizePath(resource.uri);
        if (!file) {
            return [];
        }
        const args = typeConverters.Position.toFileLocationRequestArgs(file, position);
        try {
            const response = await this.client.execute('occurrences', args, token);
            if (response && response.body) {
                return response.body
                    .filter(x => !x.isInString)
                    .map(documentHighlightFromOccurance);
            }
        }
        catch (_a) {
            // noop
        }
        return [];
    }
}
exports.default = TypeScriptDocumentHighlightProvider;
function documentHighlightFromOccurance(occurrence) {
    return new vscode_1.DocumentHighlight(typeConverters.Range.fromTextSpan(occurrence), occurrence.isWriteAccess ? vscode_1.DocumentHighlightKind.Write : vscode_1.DocumentHighlightKind.Read);
}
//# sourceMappingURL=https://ticino.blob.core.windows.net/sourcemaps/3aeede733d9a3098f7b4bdc1f66b63b0f48c1ef9/extensions\typescript-language-features\out/features\documentHighlightProvider.js.map
