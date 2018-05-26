"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
const typeConverters = require("../utils/typeConverters");
class TypeScriptFoldingProvider {
    constructor(client) {
        this.client = client;
    }
    async provideFoldingRanges(document, _context, token) {
        if (!this.client.apiVersion.has280Features()) {
            return;
        }
        const file = this.client.normalizePath(document.uri);
        if (!file) {
            return;
        }
        const args = { file };
        const response = await this.client.execute('getOutliningSpans', args, token);
        if (!response || !response.body) {
            return;
        }
        return new vscode.FoldingRangeList(response.body.map(span => {
            const range = typeConverters.Range.fromTextSpan(span.textSpan);
            return new vscode.FoldingRange(range.start.line, range.end.line);
        }));
    }
}
exports.default = TypeScriptFoldingProvider;
//# sourceMappingURL=https://ticino.blob.core.windows.net/sourcemaps/3aeede733d9a3098f7b4bdc1f66b63b0f48c1ef9/extensions\typescript-language-features\out/features\folderingProvider.js.map
