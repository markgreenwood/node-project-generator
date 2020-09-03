#!/usr/bin/env bash

TS_DEPENDENCIES="
ts-node
typescript
@typescript-eslint/eslint-plugin
@typescript-eslint/parser
@types/node
@types/mocha
@types/chai
"

# install dependencies
npm i -D $TS_DEPENDENCIES

# make a tsconfig.json file

# update package.json so "start" runs from dist and "prestart" has a build step

# fix nodemon to work with TS
