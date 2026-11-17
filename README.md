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

## Checks

Run the portable configuration tests without loading/installing plugins:

```sh
nvim --headless -u NONE -l tests/java.lua
nvim --headless -u NONE -l tests/markdown.lua
```

The tests simulate Linux, macOS, and Windows JDK discovery and Markdown builds
(including Windows command wrappers and paths with spaces). Actual runtime/plugin
checks should also be performed on each OS before a broad rollout.
