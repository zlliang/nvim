# Neovim 🌚

My Neovim configuration: a single [`init.lua`](init.lua), no plugin manager beyond the built-in `vim.pack`.

Requires Neovim 0.12 or newer. Plugins install on first launch; `nvim-pack-lock.json` is machine-local and gitignored.

Inside: GitHub theme following the terminal background, lualine, which-key, tree-sitter, blink.cmp, mason with nvim-lspconfig, telescope with fzf-native, and gitsigns.

## Install

```bash
git clone https://github.com/zlliang/nvim.git ~/.config/nvim
```

On my own machines this repository is checked out to `~/workspace/github/zlliang/nvim` and copied to `~/.config/nvim` by [zlliang/dotfiles](https://github.com/zlliang/dotfiles).

## License

[MIT](LICENSE.md)
