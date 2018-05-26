"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
const tableOfContentsProvider_1 = require("../tableOfContentsProvider");
class MarkdownFoldingProvider {
    constructor(engine) {
        this.engine = engine;
    }
    async provideFoldingRanges(document, context, _token) {
        const tocProvider = new tableOfContentsProvider_1.TableOfContentsProvider(this.engine, document);
        let toc = await tocProvider.getToc();
        if (context.maxRanges && toc.length > context.maxRanges) {
            toc = toc.slice(0, context.maxRanges);
        }
        const foldingRanges = toc.map((entry, startIndex) => {
            const start = entry.line;
            let end = undefined;
            for (let i = startIndex + 1; i < toc.length; ++i) {
                if (toc[i].level <= entry.level) {
                    end = toc[i].line - 1;
                    if (document.lineAt(end).isEmptyOrWhitespace && end >= start + 1) {
                        end = end - 1;
                    }
                    break;
                }
            }
            return new vscode.FoldingRange(start, typeof end === 'number' ? end : document.lineCount - 1);
        });
        return new vscode.FoldingRangeList(foldingRanges);
    }
}
exports.default = MarkdownFoldingProvider;
//# sourceMappingURL=https://ticino.blob.core.windows.net/sourcemaps/3aeede733d9a3098f7b4bdc1f66b63b0f48c1ef9/extensions\markdown-language-features\out/features\foldingProvider.js.map
