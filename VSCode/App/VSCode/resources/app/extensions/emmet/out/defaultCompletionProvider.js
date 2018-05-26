"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
Object.defineProperty(exports, "__esModule", { value: true });
const vscode = require("vscode");
const abbreviationActions_1 = require("./abbreviationActions");
const util_1 = require("./util");
class DefaultCompletionItemProvider {
    provideCompletionItems(document, position, token, context) {
        const emmetConfig = vscode.workspace.getConfiguration('emmet');
        const excludedLanguages = emmetConfig['excludeLanguages'] ? emmetConfig['excludeLanguages'] : [];
        if (excludedLanguages.indexOf(document.languageId) > -1) {
            return;
        }
        const mappedLanguages = util_1.getMappingForIncludedLanguages();
        const isSyntaxMapped = mappedLanguages[document.languageId] ? true : false;
        let syntax = util_1.getEmmetMode((isSyntaxMapped ? mappedLanguages[document.languageId] : document.languageId), excludedLanguages);
        if (!syntax
            || emmetConfig['showExpandedAbbreviation'] === 'never'
            || ((isSyntaxMapped || syntax === 'jsx') && emmetConfig['showExpandedAbbreviation'] !== 'always')) {
            return;
        }
        const helper = util_1.getEmmetHelper();
        const extractAbbreviationResults = helper.extractAbbreviation(document, position, !util_1.isStyleSheet(syntax));
        if (!extractAbbreviationResults || !helper.isAbbreviationValid(syntax, extractAbbreviationResults.abbreviation)) {
            return;
        }
        let validateLocation = false;
        let rootNode = undefined;
        if (context.triggerKind !== vscode.CompletionTriggerKind.TriggerForIncompleteCompletions) {
            validateLocation = syntax === 'html' || util_1.isStyleSheet(document.languageId);
            // If document can be css parsed, get currentNode
            if (util_1.isStyleSheet(document.languageId)) {
                let usePartialParsing = vscode.workspace.getConfiguration('emmet')['optimizeStylesheetParsing'] === true;
                rootNode = usePartialParsing && document.lineCount > 1000 ? util_1.parsePartialStylesheet(document, position) : util_1.parseDocument(document, false);
                if (!rootNode) {
                    return;
                }
            }
        }
        if (validateLocation && !abbreviationActions_1.isValidLocationForEmmetAbbreviation(document, rootNode, syntax, position, extractAbbreviationResults.abbreviationRange)) {
            return;
        }
        let noiseCheckPromise = Promise.resolve();
        // Fix for https://github.com/Microsoft/vscode/issues/32647
        // Check for document symbols in js/ts/jsx/tsx and avoid triggering emmet for abbreviations of the form symbolName.sometext
        // Presence of > or * or + in the abbreviation denotes valid abbreviation that should trigger emmet
        if (!util_1.isStyleSheet(syntax) && (document.languageId === 'javascript' || document.languageId === 'javascriptreact' || document.languageId === 'typescript' || document.languageId === 'typescriptreact')) {
            let abbreviation = extractAbbreviationResults.abbreviation;
            if (abbreviation.startsWith('this.')) {
                noiseCheckPromise = Promise.resolve(true);
            }
            else {
                noiseCheckPromise = vscode.commands.executeCommand('vscode.executeDocumentSymbolProvider', document.uri).then((symbols) => {
                    return symbols && symbols.find(x => abbreviation === x.name || (abbreviation.startsWith(x.name + '.') && !/>|\*|\+/.test(abbreviation)));
                });
            }
        }
        return noiseCheckPromise.then((noise) => {
            if (noise) {
                return;
            }
            let result = helper.doComplete(document, position, syntax, util_1.getEmmetConfiguration(syntax));
            let newItems = [];
            if (result && result.items) {
                result.items.forEach((item) => {
                    let newItem = new vscode.CompletionItem(item.label);
                    newItem.documentation = item.documentation;
                    newItem.detail = item.detail;
                    newItem.insertText = new vscode.SnippetString(item.textEdit.newText);
                    let oldrange = item.textEdit.range;
                    newItem.range = new vscode.Range(oldrange.start.line, oldrange.start.character, oldrange.end.line, oldrange.end.character);
                    newItem.filterText = item.filterText;
                    newItem.sortText = item.sortText;
                    if (emmetConfig['showSuggestionsAsSnippets'] === true) {
                        newItem.kind = vscode.CompletionItemKind.Snippet;
                    }
                    newItems.push(newItem);
                });
            }
            return new vscode.CompletionList(newItems, true);
        });
    }
}
exports.DefaultCompletionItemProvider = DefaultCompletionItemProvider;
//# sourceMappingURL=https://ticino.blob.core.windows.net/sourcemaps/3aeede733d9a3098f7b4bdc1f66b63b0f48c1ef9/extensions\emmet\out/defaultCompletionProvider.js.map
