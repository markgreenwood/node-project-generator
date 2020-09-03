#!/usr/bin/env bash

DIRECTORY=$1

if [ -z $1 ]; then
  echo "Usage: create-hapi-server <project-name>"
  exit 0
fi

MAIN_TARGET="server"

DEV_DEPENDENCIES="
eslint
eslint-config-airbnb-base
eslint-config-prettier
eslint-plugin-import
eslint-plugin-prettier
mocha
chai
prettier
ts-node
typescript
@types/node
@types/mocha
@types/chai
@types/hapi__hapi
@types/hapi__inert
@types/hapi__vision
@types/hapi__joi
@typescript-eslint/eslint-plugin
@typescript-eslint/parser
"

DEPENDENCIES="
@hapi/hapi
@hapi/inert
@hapi/vision
@hapi/joi
@hapi/good
@hapi/good-squeeze
@hapi/good-console
hapi-swagger
"

function initialize_project {
  git init
  npx license $(npm get init-license) -o "$(npm get init-author-name)" > LICENSE
  npx gitignore node
  npm init -y
}

function initial_commit {
  git add -A
  git commit -m "Initial commit"
}

function create_ignore_files {
cat > .eslintignore <<- "EOF"
dist
EOF

cat > .prettierignore <<- "EOF"
dist
EOF
}

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
      message: `Responding to request for qparam: ${request.query.qparam}`,
    }),
    options: {
      tags: ["api"],
      validate: {
        query: Joi.object({
          qparam: Joi.string().required(),
        }),
      },
    },
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

function config_eslint {
cat > .eslintrc <<- "EOF"
{
  "parser": "@typescript-eslint/parser",
  "extends": ["airbnb-base", "prettier", "plugin:import/typescript"],
  "plugins": ["prettier", "@typescript-eslint"],
  "rules": {
    "prettier/prettier": ["error"],
    "no-unused-vars": "off",
    "@typescript-eslint/no-unused-vars": ["error", { "vars": "all", "args": "after-used", "ignoreRestSiblings": false }]
  },
  "env": {
    "mocha": true
  }
}
EOF
}

function config_prettier {
cat > .prettierrc <<- "EOF"
{
  "arrowParens": "avoid",
  "bracketSpacing": true,
  "htmlWhitespaceSensitivity": "css",
  "insertPragma": false,
  "jsxBracketSameLine": false,
  "jsxSingleQuote": false,
  "printWidth": 80,
  "proseWrap": "preserve",
  "requirePragma": false,
  "semi": true,
  "singleQuote": false,
  "tabWidth": 2,
  "trailingComma": "all",
  "useTabs": false
}
EOF
}

function config_typescript {
cat > tsconfig.json <<- "EOF"
{
  "compilerOptions": {
    "allowJs": true,
    "module": "commonjs",
    "esModuleInterop": true,
    "target": "es6",
    "noImplicitAny": true,
    "moduleResolution": "node",
    "sourceMap": true,
    "outDir": "dist",
    "baseUrl": ".",
    "paths": {
      "*": [
        "node_modules/*"
      ]
    }
  },
  "include": [
    "src/**/*"
  ]
}
EOF
}

function config_nodemon {
cat > nodemon.json <<- "EOF"
{
  "restartable": "rs",
  "ignore": [".git", "node_modules/**/node_modules"],
  "verbose": true,
  "execMap": {
    "ts": "node --require ts-node/register"
  },
  "watch": ["src/"],
  "env": {
    "NODE_ENV": "development"
  },
  "ext": "js,json,ts"
}
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

generate_hapi_swagger_server
generate_hapi_test_code

create_ignore_files

echo "Installing dependencies"
echo $DEPENDENCIES
install_dependencies

echo "Installing devDependencies"
echo $DEV_DEPENDENCIES
install_dev_dependencies

echo "Making initial commit"
initial_commit
