"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
Object.defineProperty(exports, "__esModule", { value: true });
const assert = require("assert");
const vscode = require("vscode");
require("mocha");
const markdownEngine_1 = require("../markdownEngine");
const foldingProvider_1 = require("../features/foldingProvider");
const inMemoryDocument_1 = require("./inMemoryDocument");
const testFileName = vscode.Uri.parse('test.md');
suite('markdown.FoldingProvider', () => {
    test('Should not return anything for empty document', async () => {
        const folds = await getFoldsForDocument(``);
        assert.strictEqual(folds.ranges.length, 0);
    });
    test('Should not return anything for document without headers', async () => {
        const folds = await getFoldsForDocument(`a
**b** afas
a#b
a`);
        assert.strictEqual(folds.ranges.length, 0);
    });
    test('Should fold from header to end of document', async () => {
        const folds = await getFoldsForDocument(`a
# b
c
d`);
        assert.strictEqual(folds.ranges.length, 1);
        const firstFold = folds.ranges[0];
        assert.strictEqual(firstFold.startLine, 1);
        assert.strictEqual(firstFold.endLine, 3);
    });
    test('Should leave single newline before next header', async () => {
        const folds = await getFoldsForDocument(`
# a
x

# b
y`);
        assert.strictEqual(folds.ranges.length, 2);
        const firstFold = folds.ranges[0];
        assert.strictEqual(firstFold.startLine, 1);
        assert.strictEqual(firstFold.endLine, 3);
    });
    test('Should collapse multuple newlines to single newline before next header', async () => {
        const folds = await getFoldsForDocument(`
# a
x



# b
y`);
        assert.strictEqual(folds.ranges.length, 2);
        const firstFold = folds.ranges[0];
        assert.strictEqual(firstFold.startLine, 1);
        assert.strictEqual(firstFold.endLine, 5);
    });
    test('Should not collapse if there is no newline before next header', async () => {
        const folds = await getFoldsForDocument(`
# a
x
# b
y`);
        assert.strictEqual(folds.ranges.length, 2);
        const firstFold = folds.ranges[0];
        assert.strictEqual(firstFold.startLine, 1);
        assert.strictEqual(firstFold.endLine, 2);
    });
});
async function getFoldsForDocument(contents) {
    const doc = new inMemoryDocument_1.InMemoryDocument(testFileName, contents);
    const provider = new foldingProvider_1.default(newEngine());
    return await provider.provideFoldingRanges(doc, {}, new vscode.CancellationTokenSource().token);
}
function newEngine() {
    return new markdownEngine_1.MarkdownEngine(new class {
        constructor() {
            this.previewScripts = [];
            this.previewStyles = [];
            this.previewResourceRoots = [];
            this.markdownItPlugins = [];
        }
    });
}
//# sourceMappingURL=https://ticino.blob.core.windows.net/sourcemaps/3aeede733d9a3098f7b4bdc1f66b63b0f48c1ef9/extensions\markdown-language-features\out/test\foldingProvider.test.js.map
