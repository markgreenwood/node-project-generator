/* eslint-disable no-console */
import * as Hapi from "@hapi/hapi";
// @ts-ignore
import good from "@hapi/good";
import Inert from "@hapi/inert";
import Vision from "@hapi/vision";
import Joi from "@hapi/joi";
import HapiSwagger from "hapi-swagger";

const routes = [
  {
    method: "GET",
    path: "/health",
    handler: () => ({ status: "OK" }),
  },
  {
    method: "GET",
    path: "/test-route",
    handler: (request: Hapi.Request) => ({
      message: `Responding to request for qparam: ${request.query.qparam}`
    }),
    options: {
      tags: ["api"],
      validate: {
        query: {
          qparam: Joi.string().required()
        }
      }
    }
  },
];

const pkg = require("../package"); // eslint-disable-line import/no-unresolved

const theServer = new Hapi.Server({ host: "localhost", port: 3000 });

// Register plugins
const goodOptions = {
  ops: {
    interval: 1000,
  },
  reporters: {
    myConsoleReporter: [
      {
        module: "@hapi/good-squeeze",
        name: "Squeeze",
        args: [{ log: "*", response: "*" }],
      },
      {
        module: "@hapi/good-console",
      },
      "stdout",
    ],
  },
};

const swaggerOptions: HapiSwagger.RegisterOptions = {
  info: {
    title: "Test API Documentation",
    version: pkg.version,
  },
};

theServer.route(routes);

const init = async (server: Hapi.Server) => {
  await server.register([
    {
      plugin: Inert,
    },
    {
      plugin: Vision,
    },
    {
      plugin: HapiSwagger,
      options: swaggerOptions,
    },
    {
      plugin: good,
      options: goodOptions,
    },
  ]);
  await server.start();
  console.log("Server running on port: ", server.info.uri);
};

process.on("unhandledRejection", err => {
  console.log(err);
  process.exit(1);
});

if (require.main === module) {
  init(theServer);
}

export default theServer;
