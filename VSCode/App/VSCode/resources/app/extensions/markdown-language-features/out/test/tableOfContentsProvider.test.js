"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
Object.defineProperty(exports, "__esModule", { value: true });
const assert = require("assert");
const vscode = require("vscode");
require("mocha");
const tableOfContentsProvider_1 = require("../tableOfContentsProvider");
const markdownEngine_1 = require("../markdownEngine");
const inMemoryDocument_1 = require("./inMemoryDocument");
const testFileName = vscode.Uri.parse('test.md');
suite('markdown.TableOfContentsProvider', () => {
    test('Lookup should not return anything for empty document', async () => {
        const doc = new inMemoryDocument_1.InMemoryDocument(testFileName, '');
        const provider = new tableOfContentsProvider_1.TableOfContentsProvider(newEngine(), doc);
        assert.strictEqual(await provider.lookup(''), undefined);
        assert.strictEqual(await provider.lookup('foo'), undefined);
    });
    test('Lookup should not return anything for document with no headers', async () => {
        const doc = new inMemoryDocument_1.InMemoryDocument(testFileName, 'a *b*\nc');
        const provider = new tableOfContentsProvider_1.TableOfContentsProvider(newEngine(), doc);
        assert.strictEqual(await provider.lookup(''), undefined);
        assert.strictEqual(await provider.lookup('foo'), undefined);
        assert.strictEqual(await provider.lookup('a'), undefined);
        assert.strictEqual(await provider.lookup('b'), undefined);
    });
    test('Lookup should return basic #header', async () => {
        const doc = new inMemoryDocument_1.InMemoryDocument(testFileName, `# a\nx\n# c`);
        const provider = new tableOfContentsProvider_1.TableOfContentsProvider(newEngine(), doc);
        {
            const entry = await provider.lookup('a');
            assert.ok(entry);
            assert.strictEqual(entry.line, 0);
        }
        {
            assert.strictEqual(await provider.lookup('x'), undefined);
        }
        {
            const entry = await provider.lookup('c');
            assert.ok(entry);
            assert.strictEqual(entry.line, 2);
        }
    });
    test('Lookups should be case in-sensitive', async () => {
        const doc = new inMemoryDocument_1.InMemoryDocument(testFileName, `# fOo\n`);
        const provider = new tableOfContentsProvider_1.TableOfContentsProvider(newEngine(), doc);
        assert.strictEqual((await provider.lookup('fOo')).line, 0);
        assert.strictEqual((await provider.lookup('foo')).line, 0);
        assert.strictEqual((await provider.lookup('FOO')).line, 0);
    });
    test('Lookups should ignore leading and trailing white-space, and collapse internal whitespace', async () => {
        const doc = new inMemoryDocument_1.InMemoryDocument(testFileName, `#      f o  o    \n`);
        const provider = new tableOfContentsProvider_1.TableOfContentsProvider(newEngine(), doc);
        assert.strictEqual((await provider.lookup('f o  o')).line, 0);
        assert.strictEqual((await provider.lookup('  f o  o')).line, 0);
        assert.strictEqual((await provider.lookup('  f o  o  ')).line, 0);
        assert.strictEqual((await provider.lookup('f o o')).line, 0);
        assert.strictEqual((await provider.lookup('f o       o')).line, 0);
        assert.strictEqual(await provider.lookup('f'), undefined);
        assert.strictEqual(await provider.lookup('foo'), undefined);
        assert.strictEqual(await provider.lookup('fo o'), undefined);
    });
    test('should normalize special characters #44779', async () => {
        const doc = new inMemoryDocument_1.InMemoryDocument(testFileName, `# Indentação\n`);
        const provider = new tableOfContentsProvider_1.TableOfContentsProvider(newEngine(), doc);
        assert.strictEqual((await provider.lookup('indentacao')).line, 0);
    });
});
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
//# sourceMappingURL=https://ticino.blob.core.windows.net/sourcemaps/3aeede733d9a3098f7b4bdc1f66b63b0f48c1ef9/extensions\markdown-language-features\out/test\tableOfContentsProvider.test.js.map
