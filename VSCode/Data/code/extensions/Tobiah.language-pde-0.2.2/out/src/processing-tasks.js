"use strict";
var path = require('path');
/**
 * Dyanmically build the args to pass to the `processing-java` command.
 *
 * @param base the base directory of the sketch
 */
function buildProcessingArgs(base) {
    return [
        "--force",
        ("--sketch=" + base),
        path.join("--output=" + base, "out"),
        "--run"
    ];
}
exports.buildProcessingArgs = buildProcessingArgs;
exports.processingCommand = "processing-java";
exports.processingTaskFilename = "ProcessingTasks.json";
//# sourceMappingURL=processing-tasks.js.map