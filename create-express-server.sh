#!/usr/bin/env bash

DIRECTORY=$1

if [ -z $1 ]; then
  echo "Usage: create-express-server <project-name>"
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
@types/express
@typescript-eslint/eslint-plugin
@typescript-eslint/parser
"

DEPENDENCIES="
express
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

function generate_express_server {
  mkdir src

  cat > src/server.ts <<- "EOF"
import express from "express";
EOF
}

function generate_express_test_code {
  mkdir test
  cat > test/test.spec.ts <<- "EOF"
import { expect } from "chai";

import server from "../src/server";

describe("GET /health", () => {
  it("should return a healthcheck", () => {
    return server
      .inject({ method: "GET", url: "/health" })
      .then((response) => expect(response).to.be.ok);
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

generate_express_server
generate_express_test_code

create_ignore_files

echo "Installing dependencies"
echo $DEPENDENCIES
install_dependencies

echo "Installing devDependencies"
echo $DEV_DEPENDENCIES
install_dev_dependencies

echo "Making initial commit"
initial_commit
