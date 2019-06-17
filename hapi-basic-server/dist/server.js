"use strict";
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (Object.hasOwnProperty.call(mod, k)) result[k] = mod[k];
    result["default"] = mod;
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
const Hapi = __importStar(require("@hapi/hapi"));
const server = new Hapi.Server({ host: "localhost", port: 3000 });
server.route([
    {
        method: "GET",
        path: "/health",
        handler: () => ({ status: "OK" }),
    },
]);
server.start().then(() => {
    console.log(`Server started and running on ${server.info.uri}`);
});
exports.default = server;
//# sourceMappingURL=server.js.map