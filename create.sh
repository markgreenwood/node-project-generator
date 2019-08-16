#!/usr/bin/env bash

DIRECTORY=$1
PROJECT_TYPE=$2

if [ -z $1 ] || [ -z $2 ]; then
  echo "Usage: create <project-name> <project-type>"
  exit 0
fi

source utilities.sh

MAIN_TARGET="index"

DEV_DEPENDENCIES="
eslint
eslint-config-airbnb
eslint-config-prettier
eslint-plugin-import
eslint-plugin-react
eslint-plugin-jsx-a11y
eslint-plugin-prettier
mocha
chai
prettier
ts-node
typescript
@types/node
@types/mocha
@types/chai
@typescript-eslint/eslint-plugin
@typescript-eslint/parser
"

DEPENDENCIES=""

if [[ "$2" == "hapi"* ]]; then
  echo "It's a hapi project!"
  MAIN_TARGET="server"
  DEPENDENCIES="$DEPENDENCIES @hapi/hapi"
  DEV_DEPENDENCIES="$DEV_DEPENDENCIES @types/hapi__hapi"
fi

if [ "$2" == "hapi-swagger" ]; then
  echo "It's a hapi-swagger project!"
  DEPENDENCIES="$DEPENDENCIES
  @hapi/inert
  @hapi/vision
  @hapi/joi
  @hapi/good
  @hapi/good-squeeze
  @hapi/good-console
  hapi-swagger
  "
  DEV_DEPENDENCIES="$DEV_DEPENDENCIES
  @types/hapi__inert
  @types/hapi__vision
  @types/hapi__joi
  "
fi

function install_dev_dependencies {
  echo "Installing devDependencies $DEV_DEPENDENCIES"
  npm i -D $DEV_DEPENDENCIES
}

function install_dependencies {
  echo "Installing dependencies $DEPENDENCIES"
  npm i -S $DEPENDENCIES
}

function config_package_json {
  mv package.json template.json
  cat template.json |
    jq '.scripts.test = "mocha --require ts-node/register test/**/*.ts"' |
    jq '.scripts += {"prestart":"npm run build"}' |
    jq '.scripts += {"start":"node ."}' |
    jq --arg MAIN_TARGET "$MAIN_TARGET" '.scripts += {"start:dev":("nodemon src/" + $MAIN_TARGET + ".ts")}' |
    jq '.scripts += {"lint":"eslint . --ext .ts,.js"}' |
    jq '.scripts += {"pretest":"npm run lint"}' |
    jq '.scripts += {"build":"tsc"}' |
    jq --arg MAIN_TARGET "$MAIN_TARGET" '.main = ("dist/" + $MAIN_TARGET + ".js")' \
    > package.json
  rm template.json
}

function generate_hello_world {
mkdir src
cat > src/index.ts <<- "EOF"
console.log("Hello, World!");
EOF
}

function generate_hapi_server {
  mkdir src

  cat > src/server.ts <<- "EOF"
import * as Hapi from "@hapi/hapi";

const init = async (server: Hapi.Server) => {
  await server.start();
  console.log("Server running on port: ", server.info.uri);
};

const server: Hapi.Server = new Hapi.Server({ host: "localhost", port: 3000 });

server.route([
  {
    method: "GET",
    path: "/health",
    handler: () => ({ status: "OK" }),
  },
]);

process.on("unhandledRejection", err => {
  console.log(err);
  process.exit(1);
});

if (require.main === module) {
  init(server);
  console.log(`Server started and running on ${server.info.uri}`);
}

export default server;
EOF
}

function generate_hapi_swagger_server {
  mkdir src

  cat > src/server.ts <<- "EOF"
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
EOF
}

function generate_test_code {
  mkdir test
  cat > test/test.spec.ts <<- "EOF"
const { expect } = require("chai");

describe("This module", () => {
  it("should do something", () => {
    expect(true).to.equal(true);
  });
});
EOF
}

function generate_hapi_test_code {
  mkdir test
  cat > test/test.spec.ts <<- "EOF"
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
EOF
}

echo "Creating $DIRECTORY"

mkdir $DIRECTORY && cd $DIRECTORY

echo "Initializing project"
initialize_project

echo "Configuring linting, etc."
config_eslint
config_prettier
config_typescript

echo "Configuring package.json"
config_package_json
config_nodemon

if [ "$2" == "hapi-basic" ]; then
  generate_hapi_server
  generate_hapi_test_code
elif [ "$2" == "hapi-swagger" ]; then
  generate_hapi_swagger_server
  generate_hapi_test_code
else
  generate_hello_world
  generate_test_code
fi

create_ignore_files

echo "Installing dependencies"
echo $DEPENDENCIES
install_dependencies

echo "Installing devDependencies"
echo $DEV_DEPENDENCIES
install_dev_dependencies

echo "Making initial commit"
initial_commit
