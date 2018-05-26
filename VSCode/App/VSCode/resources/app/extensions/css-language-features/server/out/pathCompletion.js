/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
var path = require("path");
var fs = require("fs");
var vscode_uri_1 = require("vscode-uri");
var vscode_languageserver_types_1 = require("vscode-languageserver-types");
var strings_1 = require("./utils/strings");
function getPathCompletionParticipant(document, workspaceFolders, result) {
    return {
        onURILiteralValue: function (context) {
            if (!workspaceFolders || workspaceFolders.length === 0) {
                return;
            }
            var workspaceRoot = resolveWorkspaceRoot(document, workspaceFolders);
            // Handle quoted values
            var uriValue = context.uriValue;
            var range = context.range;
            if (strings_1.startsWith(uriValue, "'") || strings_1.startsWith(uriValue, "\"")) {
                uriValue = uriValue.slice(1, -1);
                range = getRangeWithoutQuotes(range);
            }
            var suggestions = providePathSuggestions(uriValue, range, vscode_uri_1.default.parse(document.uri).fsPath, workspaceRoot);
            result.items = suggestions.concat(result.items);
        }
    };
}
exports.getPathCompletionParticipant = getPathCompletionParticipant;
function providePathSuggestions(value, range, activeDocFsPath, root) {
    if (strings_1.startsWith(value, '/') && !root) {
        return [];
    }
    var replaceRange;
    var lastIndexOfSlash = value.lastIndexOf('/');
    if (lastIndexOfSlash === -1) {
        replaceRange = getFullReplaceRange(range);
    }
    else {
        var valueAfterLastSlash = value.slice(lastIndexOfSlash + 1);
        replaceRange = getReplaceRange(range, valueAfterLastSlash);
    }
    var valueBeforeLastSlash = value.slice(0, lastIndexOfSlash + 1);
    var parentDir = strings_1.startsWith(value, '/')
        ? path.resolve(root, '.' + valueBeforeLastSlash)
        : path.resolve(activeDocFsPath, '..', valueBeforeLastSlash);
    try {
        return fs.readdirSync(parentDir).map(function (f) {
            if (isDir(path.resolve(parentDir, f))) {
                return {
                    label: f + '/',
                    kind: vscode_languageserver_types_1.CompletionItemKind.Folder,
                    textEdit: vscode_languageserver_types_1.TextEdit.replace(replaceRange, f + '/'),
                    command: {
                        title: 'Suggest',
                        command: 'editor.action.triggerSuggest'
                    }
                };
            }
            else {
                return {
                    label: f,
                    kind: vscode_languageserver_types_1.CompletionItemKind.File,
                    textEdit: vscode_languageserver_types_1.TextEdit.replace(replaceRange, f)
                };
            }
        });
    }
    catch (e) {
        return [];
    }
}
exports.providePathSuggestions = providePathSuggestions;
var isDir = function (p) {
    try {
        return fs.statSync(p).isDirectory();
    }
    catch (e) {
        return false;
    }
};
function resolveWorkspaceRoot(activeDoc, workspaceFolders) {
    for (var i = 0; i < workspaceFolders.length; i++) {
        if (strings_1.startsWith(activeDoc.uri, workspaceFolders[i].uri)) {
            return path.resolve(vscode_uri_1.default.parse(workspaceFolders[i].uri).fsPath);
        }
    }
}
function getFullReplaceRange(valueRange) {
    var start = vscode_languageserver_types_1.Position.create(valueRange.end.line, valueRange.start.character);
    var end = vscode_languageserver_types_1.Position.create(valueRange.end.line, valueRange.end.character);
    return vscode_languageserver_types_1.Range.create(start, end);
}
function getReplaceRange(valueRange, valueAfterLastSlash) {
    var start = vscode_languageserver_types_1.Position.create(valueRange.end.line, valueRange.end.character - valueAfterLastSlash.length);
    var end = vscode_languageserver_types_1.Position.create(valueRange.end.line, valueRange.end.character);
    return vscode_languageserver_types_1.Range.create(start, end);
}
function getRangeWithoutQuotes(range) {
    var start = vscode_languageserver_types_1.Position.create(range.start.line, range.start.character + 1);
    var end = vscode_languageserver_types_1.Position.create(range.end.line, range.end.character - 1);
    return vscode_languageserver_types_1.Range.create(start, end);
}
//# sourceMappingURL=https://ticino.blob.core.windows.net/sourcemaps/3aeede733d9a3098f7b4bdc1f66b63b0f48c1ef9/extensions\css-language-features\server\out/pathCompletion.js.map
