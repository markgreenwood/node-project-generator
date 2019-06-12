function initialize_and_install {
  git init
  npx license $(npm get init-license) -o "$(npm get init-author-name)" > LICENSE
  npx gitignore node
  npm init -y
  npm i -D eslint \
    eslint-config-airbnb \
    eslint-config-prettier \
    eslint-plugin-import \
    eslint-plugin-react \
    eslint-plugin-jsx-a11y \
    eslint-plugin-prettier \
    prettier \
    typescript
}

function initial_commit {
  git add -A
  git commit -m "Initial commit"
}

function add_scripts_to_package_json {
  mv package.json template.json
  cat template.json | jq '.scripts += {"start":"node ."}' > package.json
  rm template.json
}

initialize_and_install

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

mkdir src

cat > src/index.ts <<- "EOF"
console.log("Hello, World!");
EOF

add_scripts_to_package_json

initial_commit
