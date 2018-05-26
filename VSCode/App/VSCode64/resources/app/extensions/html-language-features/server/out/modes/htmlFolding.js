/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
var vscode_languageserver_1 = require("vscode-languageserver");
var vscode_html_languageservice_1 = require("vscode-html-languageservice");
var vscode_languageserver_protocol_foldingprovider_1 = require("vscode-languageserver-protocol-foldingprovider");
var arrays_1 = require("../utils/arrays");
function getFoldingRegions(languageModes, document, maxRanges, cancellationToken) {
    var htmlMode = languageModes.getMode('html');
    var range = vscode_html_languageservice_1.Range.create(vscode_languageserver_1.Position.create(0, 0), vscode_languageserver_1.Position.create(document.lineCount, 0));
    var ranges = [];
    if (htmlMode && htmlMode.getFoldingRanges) {
        ranges.push.apply(ranges, htmlMode.getFoldingRanges(document, range));
    }
    var modeRanges = languageModes.getModesInRange(document, range);
    for (var _i = 0, modeRanges_1 = modeRanges; _i < modeRanges_1.length; _i++) {
        var modeRange = modeRanges_1[_i];
        var mode = modeRange.mode;
        if (mode && mode !== htmlMode && mode.getFoldingRanges && !modeRange.attributeValue) {
            ranges.push.apply(ranges, mode.getFoldingRanges(document, modeRange));
        }
    }
    if (maxRanges && ranges.length > maxRanges) {
        ranges = limitRanges(ranges, maxRanges);
    }
    return { ranges: ranges };
}
exports.getFoldingRegions = getFoldingRegions;
function limitRanges(ranges, maxRanges) {
    ranges = ranges.sort(function (r1, r2) {
        var diff = r1.startLine - r2.startLine;
        if (diff === 0) {
            diff = r1.endLine - r2.endLine;
        }
        return diff;
    });
    // compute each range's nesting level in 'nestingLevels'.
    // count the number of ranges for each level in 'nestingLevelCounts'
    var top = void 0;
    var previous = [];
    var nestingLevels = [];
    var nestingLevelCounts = [];
    var setNestingLevel = function (index, level) {
        nestingLevels[index] = level;
        if (level < 30) {
            nestingLevelCounts[level] = (nestingLevelCounts[level] || 0) + 1;
        }
    };
    // compute nesting levels and sanitize
    for (var i = 0; i < ranges.length; i++) {
        var entry = ranges[i];
        if (!top) {
            top = entry;
            setNestingLevel(i, 0);
        }
        else {
            if (entry.startLine > top.startLine) {
                if (entry.endLine <= top.endLine) {
                    previous.push(top);
                    top = entry;
                    setNestingLevel(i, previous.length);
                }
                else if (entry.startLine > top.endLine) {
                    do {
                        top = previous.pop();
                    } while (top && entry.startLine > top.endLine);
                    if (top) {
                        previous.push(top);
                    }
                    top = entry;
                    setNestingLevel(i, previous.length);
                }
            }
        }
    }
    var entries = 0;
    var maxLevel = 0;
    for (var i = 0; i < nestingLevelCounts.length; i++) {
        var n = nestingLevelCounts[i];
        if (n) {
            if (n + entries > maxRanges) {
                maxLevel = i;
                break;
            }
            entries += n;
        }
    }
    return ranges.filter(function (r, index) { return (typeof nestingLevels[index] === 'number') && nestingLevels[index] < maxLevel; });
}
exports.EMPTY_ELEMENTS = ['area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'keygen', 'link', 'menuitem', 'meta', 'param', 'source', 'track', 'wbr'];
function isEmptyElement(e) {
    return !!e && arrays_1.binarySearch(exports.EMPTY_ELEMENTS, e.toLowerCase(), function (s1, s2) { return s1.localeCompare(s2); }) >= 0;
}
exports.isEmptyElement = isEmptyElement;
function getHTMLFoldingRegions(htmlLanguageService, document, range) {
    var scanner = htmlLanguageService.createScanner(document.getText());
    var token = scanner.scan();
    var ranges = [];
    var stack = [];
    var lastTagName = null;
    var prevStart = -1;
    function addRange(range) {
        ranges.push(range);
        prevStart = range.startLine;
    }
    while (token !== vscode_html_languageservice_1.TokenType.EOS) {
        switch (token) {
            case vscode_html_languageservice_1.TokenType.StartTag: {
                var tagName = scanner.getTokenText();
                var startLine = document.positionAt(scanner.getTokenOffset()).line;
                stack.push({ startLine: startLine, tagName: tagName });
                lastTagName = tagName;
                break;
            }
            case vscode_html_languageservice_1.TokenType.EndTag: {
                lastTagName = scanner.getTokenText();
                break;
            }
            case vscode_html_languageservice_1.TokenType.StartTagClose:
                if (!lastTagName || !isEmptyElement(lastTagName)) {
                    break;
                }
            // fallthrough
            case vscode_html_languageservice_1.TokenType.EndTagClose:
            case vscode_html_languageservice_1.TokenType.StartTagSelfClose: {
                var i = stack.length - 1;
                while (i >= 0 && stack[i].tagName !== lastTagName) {
                    i--;
                }
                if (i >= 0) {
                    var stackElement = stack[i];
                    stack.length = i;
                    var line = document.positionAt(scanner.getTokenOffset()).line;
                    var startLine = stackElement.startLine;
                    var endLine = line - 1;
                    if (endLine > startLine && prevStart !== startLine) {
                        addRange({ startLine: startLine, endLine: endLine });
                    }
                }
                break;
            }
            case vscode_html_languageservice_1.TokenType.Comment: {
                var startLine = document.positionAt(scanner.getTokenOffset()).line;
                var text = scanner.getTokenText();
                var m = text.match(/^\s*#(region\b)|(endregion\b)/);
                if (m) {
                    if (m[1]) {
                        stack.push({ startLine: startLine, tagName: '' }); // empty tagName marks region
                    }
                    else {
                        var i = stack.length - 1;
                        while (i >= 0 && stack[i].tagName.length) {
                            i--;
                        }
                        if (i >= 0) {
                            var stackElement = stack[i];
                            stack.length = i;
                            var endLine = startLine;
                            startLine = stackElement.startLine;
                            if (endLine > startLine && prevStart !== startLine) {
                                addRange({ startLine: startLine, endLine: endLine, type: vscode_languageserver_protocol_foldingprovider_1.FoldingRangeType.Region });
                            }
                        }
                    }
                }
                else {
                    var endLine = document.positionAt(scanner.getTokenOffset() + scanner.getTokenLength()).line;
                    if (startLine < endLine) {
                        addRange({ startLine: startLine, endLine: endLine, type: vscode_languageserver_protocol_foldingprovider_1.FoldingRangeType.Comment });
                    }
                }
                break;
            }
        }
        token = scanner.scan();
    }
    return ranges;
}
exports.getHTMLFoldingRegions = getHTMLFoldingRegions;
//# sourceMappingURL=https://ticino.blob.core.windows.net/sourcemaps/3aeede733d9a3098f7b4bdc1f66b63b0f48c1ef9/extensions\html-language-features\server\out/modes\htmlFolding.js.map
