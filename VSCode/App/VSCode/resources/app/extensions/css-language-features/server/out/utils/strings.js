/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
function startsWith(haystack, needle) {
    if (haystack.length < needle.length) {
        return false;
    }
    for (var i = 0; i < needle.length; i++) {
        if (haystack[i] !== needle[i]) {
            return false;
        }
    }
    return true;
}
exports.startsWith = startsWith;
//# sourceMappingURL=https://ticino.blob.core.windows.net/sourcemaps/3aeede733d9a3098f7b4bdc1f66b63b0f48c1ef9/extensions\css-language-features\server\out/utils\strings.js.map
