#!/usr/bin/env bash

DIRECTORY=$1

function initialize_project {
  git init
  npx license $(npm get init-license) -o "$(npm get init-author-name)" > LICENSE
  npx gitignore node
  npm init -y
}

function install_dev_dependencies {
  npm i -D eslint \
    eslint-config-airbnb \
    eslint-config-prettier \
    eslint-plugin-import \
    eslint-plugin-react \
    eslint-plugin-jsx-a11y \
    eslint-plugin-prettier \
    mocha \
    chai \
    prettier \
    ts-node \
    typescript \
    @types/node \
    @types/mocha
}

function initial_commit {
  git add -A
  git commit -m "Initial commit"
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

function config_eslint {
cat > .eslintrc <<- "EOF"
{
  "extends": ["airbnb", "prettier"],
  "plugins": ["prettier"],
  "rules": {
    "prettier/prettier": ["error"]
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

function generate_src_code {
mkdir src
cat > src/index.ts <<- "EOF"
console.log("Hello, World!");
EOF
}

function generate_test_code {
mkdir test
cat > test/test.ts <<- "EOF"
const { expect } = require("chai");

describe("This module", () => {
  it("should do something", () => {
    expect(true).to.equal(true);
  });
});
EOF
}

function create_ignore_files {
cat > .eslintignore <<- "EOF"
dist
EOF

cat > .prettierignore <<- "EOF"
dist
EOF
}

mkdir $DIRECTORY && cd $DIRECTORY

initialize_project
install_dev_dependencies
config_eslint
config_prettier
config_typescript
config_package_json
config_nodemon
generate_src_code
generate_test_code
create_ignore_files
initial_commit
