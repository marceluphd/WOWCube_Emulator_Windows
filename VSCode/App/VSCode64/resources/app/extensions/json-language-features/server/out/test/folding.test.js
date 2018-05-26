/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
require("mocha");
var assert = require("assert");
var vscode_languageserver_1 = require("vscode-languageserver");
var jsonFolding_1 = require("../jsonFolding");
function assertRanges(lines, expected, nRanges) {
    var document = vscode_languageserver_1.TextDocument.create('test://foo/bar.json', 'json', 1, lines.join('\n'));
    var actual = jsonFolding_1.getFoldingRegions(document, nRanges, null).ranges;
    var actualRanges = [];
    for (var i = 0; i < actual.length; i++) {
        actualRanges[i] = r(actual[i].startLine, actual[i].endLine, actual[i].type);
    }
    actualRanges = actualRanges.sort(function (r1, r2) { return r1.startLine - r2.startLine; });
    assert.deepEqual(actualRanges, expected);
}
function r(startLine, endLine, type) {
    return { startLine: startLine, endLine: endLine, type: type };
}
suite('JSON Folding', function () {
    test('Fold one level', function () {
        var input = [
            /*0*/ '{',
            /*1*/ '"foo":"bar"',
            /*2*/ '}'
        ];
        assertRanges(input, [r(0, 1, 'object')]);
    });
    test('Fold two level', function () {
        var input = [
            /*0*/ '[',
            /*1*/ '{',
            /*2*/ '"foo":"bar"',
            /*3*/ '}',
            /*4*/ ']'
        ];
        assertRanges(input, [r(0, 3, 'array'), r(1, 2, 'object')]);
    });
    test('Fold Arrays', function () {
        var input = [
            /*0*/ '[',
            /*1*/ '[',
            /*2*/ '],[',
            /*3*/ '1',
            /*4*/ ']',
            /*5*/ ']'
        ];
        assertRanges(input, [r(0, 4, 'array'), r(2, 3, 'array')]);
    });
    test('Filter start on same line', function () {
        var input = [
            /*0*/ '[[',
            /*1*/ '[',
            /*2*/ '],[',
            /*3*/ '1',
            /*4*/ ']',
            /*5*/ ']]'
        ];
        assertRanges(input, [r(0, 4, 'array'), r(2, 3, 'array')]);
    });
    test('Fold commment', function () {
        var input = [
            /*0*/ '/*',
            /*1*/ ' multi line',
            /*2*/ '*/',
        ];
        assertRanges(input, [r(0, 2, 'comment')]);
    });
    test('Incomplete commment', function () {
        var input = [
            /*0*/ '/*',
            /*1*/ '{',
            /*2*/ '"foo":"bar"',
            /*3*/ '}',
        ];
        assertRanges(input, [r(1, 2, 'object')]);
    });
    test('Fold regions', function () {
        var input = [
            /*0*/ '// #region',
            /*1*/ '{',
            /*2*/ '}',
            /*3*/ '// #endregion',
        ];
        assertRanges(input, [r(0, 3, 'region')]);
    });
    test('Test limit', function () {
        var input = [
            /* 0*/ '[',
            /* 1*/ ' [',
            /* 2*/ '  [',
            /* 3*/ '  ',
            /* 4*/ '  ],',
            /* 5*/ '  [',
            /* 6*/ '   [',
            /* 7*/ '  ',
            /* 8*/ '   ],',
            /* 9*/ '   [',
            /*10*/ '  ',
            /*11*/ '   ],',
            /*12*/ '  ],',
            /*13*/ '  [',
            /*14*/ '  ',
            /*15*/ '  ],',
            /*16*/ '  [',
            /*17*/ '  ',
            /*18*/ '  ]',
            /*19*/ ' ]',
            /*20*/ ']',
        ];
        assertRanges(input, [r(0, 19, 'array'), r(1, 18, 'array'), r(2, 3, 'array'), r(5, 11, 'array'), r(6, 7, 'array'), r(9, 10, 'array'), r(13, 14, 'array'), r(16, 17, 'array')], void 0);
        assertRanges(input, [r(0, 19, 'array'), r(1, 18, 'array'), r(2, 3, 'array'), r(5, 11, 'array'), r(6, 7, 'array'), r(9, 10, 'array'), r(13, 14, 'array'), r(16, 17, 'array')], 8);
        assertRanges(input, [r(0, 19, 'array'), r(1, 18, 'array'), r(2, 3, 'array'), r(5, 11, 'array'), r(13, 14, 'array'), r(16, 17, 'array')], 7);
        assertRanges(input, [r(0, 19, 'array'), r(1, 18, 'array'), r(2, 3, 'array'), r(5, 11, 'array'), r(13, 14, 'array'), r(16, 17, 'array')], 6);
        assertRanges(input, [r(0, 19, 'array'), r(1, 18, 'array')], 5);
        assertRanges(input, [r(0, 19, 'array'), r(1, 18, 'array')], 4);
        assertRanges(input, [r(0, 19, 'array'), r(1, 18, 'array')], 3);
        assertRanges(input, [r(0, 19, 'array'), r(1, 18, 'array')], 2);
        assertRanges(input, [r(0, 19, 'array')], 1);
    });
});
//# sourceMappingURL=https://ticino.blob.core.windows.net/sourcemaps/3aeede733d9a3098f7b4bdc1f66b63b0f48c1ef9/extensions\json-language-features\server\out/test\folding.test.js.map
