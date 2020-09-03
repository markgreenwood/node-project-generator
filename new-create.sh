#!/usr/bin/env bash

DIRECTORY=$1
PROJECT_TYPE=$2

if [ -z $1 ] || [ -z $2 ]; then
  echo "Usage: create <project-name> <project-type>"
  exit 0
fi

source ~/Documents/Projects/node-project-generator/utilities.sh

MAIN_TARGET="index"

BASE_DEV_DEPENDENCIES="
eslint
eslint-config-airbnb-base
eslint-config-prettier
eslint-plugin-import
eslint-plugin-prettier
mocha
chai
prettier
"

REACT_DEV_DEPENDENCIES="
eslint-config-airbnb
eslint-plugin-react
eslint-plugin-jsx-a11y
"

TYPESCRIPT_DEV_DEPENDENCIES="
ts-node
typescript
@types/node
@types/mocha
@types/chai
@typescript-eslint/eslint-plugin
@typescript-eslint/parser
"

DEV_DEPENDENCIES="$BASE_DEV_DEPENDENCIES $TYPESCRIPT_DEV_DEPENDENCIES"
DEPENDENCIES=""

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

generate_hello_world
generate_test_code

create_ignore_files

echo "Installing dependencies"
echo $DEPENDENCIES
install_dependencies

echo "Installing devDependencies"
echo $DEV_DEPENDENCIES
install_dev_dependencies

echo "Making initial commit"
initial_commit
