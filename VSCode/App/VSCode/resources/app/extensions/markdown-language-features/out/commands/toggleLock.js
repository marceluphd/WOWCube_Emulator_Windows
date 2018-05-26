"use strict";
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
Object.defineProperty(exports, "__esModule", { value: true });
class ToggleLockCommand {
    constructor(previewManager) {
        this.previewManager = previewManager;
        this.id = 'markdown.preview.toggleLock';
    }
    execute() {
        this.previewManager.toggleLock();
    }
}
exports.ToggleLockCommand = ToggleLockCommand;
//# sourceMappingURL=https://ticino.blob.core.windows.net/sourcemaps/3aeede733d9a3098f7b4bdc1f66b63b0f48c1ef9/extensions\markdown-language-features\out/commands\toggleLock.js.map
