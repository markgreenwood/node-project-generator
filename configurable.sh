#!/usr/bin/env bash

source ~/Documents/Projects/node-project-generator/utilities.sh

TEST_DEV_DEPENDENCIES="
mocha
chai
"

STATIC_TOOLS_DEV_DEPENDENCIES="
eslint
eslint-config-airbnb
eslint-config-prettier
eslint-plugin-import
eslint-plugin-prettier
prettier
"

STATIC_TOOLS_REACT_DEV_DEPENDENCIES="
eslint-plugin-react
eslint-plugin-jsx-a11y
"

TS_DEV_DEPENDENCIES="
ts-node
typescript
@types/node
@types/mocha
@types/chai
@typescript-eslint/eslint-plugin
@typescript-eslint/parser
"

DEV_DEPENDENCIES="
$TEST_DEV_DEPENDENCIES
$STATIC_TOOLS_DEV_DEPENDENCIES
"

function install_dev_dependencies {
  echo "Installing devDependencies $DEV_DEPENDENCIES"
  npm i -D $DEV_DEPENDENCIES
}

function install_dependencies {
  echo "Installing dependencies $DEPENDENCIES"
  npm i -S $DEPENDENCIES
}

function add_static_analysis() {
  echo "Adding static analysis tools..."
  config_eslint
  config_prettier
  install_dev_dependencies
}

function mainmenu() {
  while :
  do
    clear
    echo "1. Create a new Node.JS project"
    echo "2. Add static analysis tools (eslint, prettier)"
    echo "3. Quit"
    echo "Enter your choice [1-3]:"
    read menu_opt

    case "$menu_opt" in
      1) echo "Enter name"; read proj_name; mkdir "$proj_name" && cd "$proj_name"; initialize_project;;
      2) add_static_analysis;;
      3) exit;;
      *) echo "Press <Enter> to continue"; read;;
    esac
  done
}

mainmenu
