"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
function equals(one, other, itemEquals = (a, b) => a === b) {
    if (one.length !== other.length) {
        return false;
    }
    for (let i = 0, len = one.length; i < len; i++) {
        if (!itemEquals(one[i], other[i])) {
            return false;
        }
    }
    return true;
}
exports.equals = equals;
//# sourceMappingURL=https://ticino.blob.core.windows.net/sourcemaps/3aeede733d9a3098f7b4bdc1f66b63b0f48c1ef9/extensions\typescript-language-features\out/utils\arrays.js.map
