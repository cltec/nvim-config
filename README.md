# Neovim configuration

Shared configuration for macOS, Linux, and Windows. Requires **Neovim 0.12+**
(required by the locked Tree-sitter plugin), Git, a C compiler, and **tree-sitter
CLI 0.26.1+** for parser builds. Keep `lazy-lock.json` committed so machines use
the same plugin revisions; use `:Lazy restore` to install those revisions.

## macOS

Install Apple's command-line tools (`xcode-select --install`) and
[Homebrew](https://brew.sh), then:

```sh
brew install neovim ripgrep fd node python@3.13 go openjdk@25 tree-sitter-cli
# Optional project JDKs (e.g. Java 21): brew install openjdk@21
mkdir -p ~/.config
git clone https://github.com/cltec/nvim-config.git ~/.config/nvim
```

If using SSH, replace the clone URL with `git@github.com:cltec/nvim-config.git`
after adding your SSH key to GitHub.

Add to `~/.zprofile` (use `/usr/local` instead of `/opt/homebrew` on Intel):

```sh
eval "$(/opt/homebrew/bin/brew shellenv)"
export JAVA_HOME="$HOMEBREW_PREFIX/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$HOMEBREW_PREFIX/opt/python@3.13/libexec/bin:$PATH"
```

Open a new terminal, run `nvim`, and let plugins and Mason tools install.
Alternatively, install the locked plugins with:

```sh
nvim --headless '+Lazy! restore' +qa
```

Open a Java/Python/Go/Lua/Markdown/TypeScript file to load the corresponding LSP
configuration; Mason installs its servers on demand. Use `:Mason` to watch
progress, then restart Neovim after the first installation completes. Use
`:checkhealth` to diagnose prerequisites. Optional provider/tool warnings (e.g.
Ruby/Perl providers, PHP, Cargo, or unused LuaRocks) do not block this config.
Python tests need `pytest`
in the project's virtual environment; Flutter/Dart projects need a Flutter SDK
on PATH (not installed by these commands).

A Nerd Font is recommended for icons, for example:

```sh
brew install --cask font-jetbrains-mono-nerd-font
```

Select that font in your terminal settings. Configure Option as Meta/Alt for
Harpoon's `<M-1>` etc. Terminal.app calls this “Use Option as Meta key”. macOS
may also intercept Ctrl+arrow keys (Mission Control) and Ctrl+Space (input
source switching); change those shortcuts in System Settings if needed.

## Linux and Windows

Install equivalent dependencies with your package manager. Use
`~/.config/nvim` on Linux and `%LOCALAPPDATA%\nvim` on Windows (or the locations
reported by `:lua print(vim.fn.stdpath('config'))`). On Windows, install a
supported C toolchain for Tree-sitter and ensure Git, Node/npm, Python, Go, and
Java are on PATH. Clipboard integration uses Neovim's native macOS/Windows
providers; Linux needs a provider such as `wl-clipboard` or `xclip`.

## Portable paths and local settings

- Undo files live under `stdpath('state')/undo`, not in the config repository.
- Mason paths always derive from Mason's install root, including Lombok.
- Java project runtimes are discovered from `JAVA_HOME_<major>` (e.g.
  `JAVA_HOME_17`, `JAVA_HOME_21`), `JAVA_HOME`, SDKMAN, and standard OS locations.
  macOS also checks Homebrew's keg-only JDKs. Only existing JDKs with a `release`
  file are included, using JDTLS names such as `JavaSE-17`. Use environment
  variables for custom JDK locations; do not commit user-specific paths.
- The current Mason JDTLS package needs Java 25+ on PATH/`JAVA_HOME`, independently
  of a project's target runtime. Older JDTLS versions may still run on Java 21;
  the shared configuration does not force a specific JDK version.
- Python tests use neotest's virtualenv detection instead of assuming every
  project has a `.venv`. Python debugging uses Mason's separate debugpy venv.
- Authenticate Copilot manually with `:Copilot auth`; installation never starts
  an interactive login. CodeCompanion's OpenAI adapter needs `OPENAI_API_KEY` in
  the environment. Never commit credentials.

## TypeScript / JavaScript

- **vtsls** provides JS/JSX/TS/TSX completion, navigation, diagnostics, and code
  actions. It automatically prefers the workspace TypeScript installation.
  `ts_ls` is disabled, including Mason automatic activation. On other machines,
  optionally remove the old package with `:MasonUninstall typescript-language-server`.
- **ESLint** attaches only where an ESLint configuration is present; install
  ESLint (and any required TypeScript parser/plugins) in that project. Use
  `<leader>ca` for code actions or `:LspEslintFixAll` for fixes. ESLint and vtsls
  do not compete with the formatter for formatting.
- **Formatting** uses project-local Prettier, or project-local Biome when a
  `biome.json`/`biome.jsonc` is found. There is no global-tool or `npx` download
  fallback. Existing format-on-save and `<C-f>` apply. Tools are resolved from
  ancestor `node_modules`, including hoisted workspace dependencies. Yarn PnP
  without `node_modules` needs additional project-specific configuration.
- JavaScript, TypeScript, TSX, JSON and JSONC syntax parsers are installed.

Install only the tools adopted by your project, using its package manager. For
example, a new npm/Vitest project might use:

```sh
npm install --save-dev typescript tsx prettier vitest
```

### Debugging

Mason installs Microsoft's **js-debug-adapter**. Existing DAP mappings apply:
`<leader>db` breakpoint, `<leader>dc` choose configuration/continue,
`<leader>dO` step over, `<leader>di` step into, `<leader>du` debugger UI, and
`<leader>de` inspect an expression.

Available configurations include:

- Attach to a Node process, or an inspector at `127.0.0.1:9229` (start your app
  with `node --inspect-brk ...`, or the equivalent flags for your runner).
- Launch the current TypeScript file with `node --import tsx` (requires local
  `tsx` and a compatible modern Node version, normally Node 20.6+).
- Launch a compiled JavaScript entry (prompted), or the current JavaScript file.
- Launch Chrome at a prompted frontend URL. Start the dev server separately;
  Chrome/Chromium must be installed. Framework output/web-root layouts may need
  a project-specific configuration.

For compiled TypeScript, enable `sourceMap` and preferably `inlineSources` in
`tsconfig.json`, and build before debugging. Source maps must point back to the
original sources. Custom output layouts may also need `outFiles` in the launch
configuration; the shared config does not assume `dist` or another output path.

The locked nvim-dap reads `.vscode/launch.json` automatically on each run. Open
Neovim from the project root (or `:cd` there) so `${workspaceFolder}` and the
launch file resolve correctly. Both `node`/`chrome` and `pwa-node`/`pwa-chrome`
adapter types work. VS Code tasks and extension-specific substitutions are not
implemented by this configuration.

### Tests

Neotest has **Vitest** and **Jest** adapters, selected by the project's declared
dependencies and test filenames. Install the appropriate runner and any required
TypeScript transforms in the project; the editor does not install project tools.
`<leader>tr` runs the nearest test, `<leader>tt` runs the file, `<leader>ts` opens
the summary, and `<leader>td` debugs the nearest test. Debug runs limit workers
and enable child-process debugging.

Projects mixing Jest and Vitest in the same package, unusual test naming, custom
runner configs, and complex monorepos may need explicit adapter configuration in
`lua/plugins/test/init.lua`. No project-specific test command is hard-coded.

## Checks

Run the portable configuration tests without loading/installing plugins:

```sh
nvim --headless -u NONE -l tests/java.lua
nvim --headless -u NONE -l tests/markdown.lua
nvim --headless -u NONE -l tests/typescript.lua
```

The tests simulate Linux, macOS, and Windows JDK discovery and Markdown builds
(including Windows command wrappers and paths with spaces). TypeScript tests
cover local/hoisted tool resolution, Biome selection, test debug commands, and
portable DAP setup. Actual runtime/plugin checks should also be performed on
each OS before a broad rollout.
