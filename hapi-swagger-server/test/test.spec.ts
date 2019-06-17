import { expect } from "chai";
import { ServerInjectResponse } from "@hapi/hapi";

import server from "../src/server";

describe("GET /health", () => {
  it("should return a healthcheck", () => {
    return server
      .inject({ method: "GET", url: "/health" })
      .then((response: ServerInjectResponse) => expect(response).to.be.ok);
  });
});
