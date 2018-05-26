/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
require("mocha");
var assert = require("assert");
var vscode_css_languageservice_1 = require("vscode-css-languageservice");
var vscode_languageserver_types_1 = require("vscode-languageserver-types");
var vscode_emmet_helper_1 = require("vscode-emmet-helper");
suite('CSS Emmet Support', function () {
    var cssLanguageService = vscode_css_languageservice_1.getCSSLanguageService();
    var scssLanguageService = vscode_css_languageservice_1.getSCSSLanguageService();
    function assertCompletions(syntax, value, expectedProposal, expectedProposalDoc) {
        var offset = value.indexOf('|');
        value = value.substr(0, offset) + value.substr(offset + 1);
        var document = vscode_languageserver_types_1.TextDocument.create('test://test/test.' + syntax, syntax, 0, value);
        var position = document.positionAt(offset);
        var emmetCompletionList = {
            isIncomplete: true,
            items: undefined
        };
        var languageService = syntax === 'scss' ? scssLanguageService : cssLanguageService;
        languageService.setCompletionParticipants([vscode_emmet_helper_1.getEmmetCompletionParticipants(document, position, document.languageId, {}, emmetCompletionList)]);
        var stylesheet = languageService.parseStylesheet(document);
        var list = languageService.doComplete(document, position, stylesheet);
        assert.ok(list);
        assert.ok(emmetCompletionList);
        if (expectedProposal && expectedProposalDoc) {
            var actualLabels = (emmetCompletionList.items || []).map(function (c) { return c.label; }).sort();
            var actualDocs = (emmetCompletionList.items || []).map(function (c) { return c.documentation; }).sort();
            assert.ok(actualLabels.indexOf(expectedProposal) !== -1, 'Not found:' + expectedProposal + ' is ' + actualLabels.join(', '));
            assert.ok(actualDocs.indexOf(expectedProposalDoc) !== -1, 'Not found:' + expectedProposalDoc + ' is ' + actualDocs.join(', '));
        }
        else {
            assert.ok(!emmetCompletionList || !emmetCompletionList.items);
        }
    }
    test('Css Emmet Completions', function () {
        this.skip(); // disabled again (see #29113)
        assertCompletions('css', '.foo { display: none; m10| }', 'margin: 10px;', 'margin: 10px;');
        assertCompletions('css', 'foo { display: none; pos:f| }', 'position: fixed;', 'position: fixed;');
        assertCompletions('css', 'foo { display: none; margin: a| }', null, null);
        assertCompletions('css', 'foo| { display: none; }', null, null);
        assertCompletions('css', 'foo {| display: none; }', null, null);
        assertCompletions('css', 'foo { display: none;| }', null, null);
        assertCompletions('css', 'foo { display: none|; }', null, null);
        assertCompletions('css', '.foo { display: none; -m-m10| }', 'margin: 10px;', '-moz-margin: 10px;\nmargin: 10px;');
    });
    test('Scss Emmet Completions', function () {
        this.skip(); // disabled again (see #29113)
        assertCompletions('scss', '.foo { display: none; .bar { m10| } }', 'margin: 10px;', 'margin: 10px;');
        assertCompletions('scss', 'foo { display: none; .bar { pos:f| } }', 'position: fixed;', 'position: fixed;');
        assertCompletions('scss', 'foo { display: none; margin: a| .bar {}}', null, null);
        assertCompletions('scss', 'foo| { display: none; }', null, null);
        assertCompletions('scss', 'foo {| display: none; }', null, null);
        assertCompletions('scss', 'foo { display: none;| }', null, null);
        assertCompletions('scss', 'foo { display: none|; }', null, null);
        assertCompletions('scss', '.foo { display: none; -m-m10| }', 'margin: 10px;', '-moz-margin: 10px;\nmargin: 10px;');
    });
});
//# sourceMappingURL=https://ticino.blob.core.windows.net/sourcemaps/3aeede733d9a3098f7b4bdc1f66b63b0f48c1ef9/extensions\css-language-features\server\out/test\emmet.test.js.map
