#!/usr/bin/env bash

DIRECTORY=$1
PROJECT_TYPE=$2

if [ -z $1 ] || [ -z $2 ]; then
  echo "Usage: create <project-name> <project-type>"
  exit 0
fi

source utilities.sh

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

function install_dev_dependencies {
  npm i -D $DEV_DEPENDENCIES
}

function install_dependencies {
  npm i -S $DEPENDENCIES
}

function config_package_json {
  mv package.json template.json
  cat template.json |
    jq '.scripts.test = "mocha --require ts-node/register test/**/*.ts"' |
    jq '.scripts += {"prestart":"npm run build"}' |
    jq '.scripts += {"start":"node ."}' |
    jq '.scripts += {"start:dev":"nodemon src/index.ts"}' |
    jq '.scripts += {"lint":"eslint . --ext .ts,.js"}' |
    jq '.scripts += {"pretest":"npm run lint"}' |
    jq '.scripts += {"build":"tsc"}' |
    jq '.main = "dist/index.js"' \
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
  DEPENDENCIES="$DEPENDENCIES @hapi/hapi"
  DEV_DEPENDENCIES="$DEV_DEPENDENCIES @types/hapi__hapi"

  mkdir src

  cat > src/server.ts <<- "EOF"
import * as Hapi from "@hapi/hapi";

const server: Hapi.Server = new Hapi.Server({ host: "localhost", port: 3000 });

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

export default server;
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

const server = require("../src/server.ts");

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

if [ "$2" == "hapi" ]; then
  generate_hapi_server
  generate_hapi_test_code
else
  generate_hello_world
  generate_test_code
fi

create_ignore_files

echo "Installing dependencies"
install_dependencies

echo "Installing devDependencies"
install_dev_dependencies

echo "Making initial commit"
initial_commit
