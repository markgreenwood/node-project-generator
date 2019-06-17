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

function config_eslint {
cat > .eslintrc <<- "EOF"
{
  "parser": "@typescript-eslint/parser",
  "extends": ["airbnb", "prettier", "plugin:import/typescript"],
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
