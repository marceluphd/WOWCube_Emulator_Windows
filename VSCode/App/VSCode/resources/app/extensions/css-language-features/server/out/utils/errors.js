/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
function formatError(message, err) {
    if (err instanceof Error) {
        var error = err;
        return message + ": " + error.message + "\n" + error.stack;
    }
    else if (typeof err === 'string') {
        return message + ": " + err;
    }
    else if (err) {
        return message + ": " + err.toString();
    }
    return message;
}
exports.formatError = formatError;
function runSafe(func, errorVal, errorMessage) {
    try {
        var t = func();
        if (t instanceof Promise) {
            return t.then(void 0, function (e) {
                console.error(formatError(errorMessage, e));
                return errorVal;
            });
        }
        return t;
    }
    catch (e) {
        console.error(formatError(errorMessage, e));
        return errorVal;
    }
}
exports.runSafe = runSafe;
//# sourceMappingURL=https://ticino.blob.core.windows.net/sourcemaps/3aeede733d9a3098f7b4bdc1f66b63b0f48c1ef9/extensions\css-language-features\server\out/utils\errors.js.map
