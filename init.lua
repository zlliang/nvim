-- ====================================================================
-- Options
-- ====================================================================

vim.loader.enable()

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.o.number = true
vim.o.signcolumn = 'yes'

vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = -1
vim.o.shiftround = true

vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.inccommand = 'split'

vim.o.scrolloff = 10
vim.o.cursorline = true
vim.o.confirm = true
vim.o.undofile = true

vim.o.splitbelow = true
vim.o.splitright = true

-- Keep code on one line; prose file types use wrapping.
vim.o.breakindent = true
vim.o.wrap = false
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'text' },
  callback = function() vim.opt_local.wrap = true end,
})

-- Telescope handles directory buffers, so disable netrw globally.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Sync clipboard between OS and Neovim.
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

-- Highlight when yanking (copying) text.
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function() vim.hl.on_yank() end,
})

-- Disable cursor blinking for terminal mode.
vim.opt.guicursor:append('t:blinkon0')

-- Enter Terminal mode when opening a terminal.
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function() vim.cmd.startinsert() end,
})

-- ====================================================================
-- Mouse
-- ====================================================================

require('mouse').setup()

-- ====================================================================
-- General keymaps
-- ====================================================================

vim.keymap.set('n', '<Esc>', '<Cmd>nohlsearch<CR>', { desc = 'Clear search highlights' })

vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Focus left window' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Focus lower window' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Focus upper window' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Focus right window' })

vim.keymap.set('n', '<leader>sh', '<Cmd>split<CR>', { desc = 'Split window horizontally' })
vim.keymap.set('n', '<leader>sv', '<Cmd>vsplit<CR>', { desc = 'Split window vertically' })

vim.keymap.set('n', '<leader>th', '<Cmd>split | resize 15 | terminal<CR>', { desc = 'Open terminal in horizontal split' })
vim.keymap.set('n', '<leader>tv', '<Cmd>vsplit | terminal<CR>', { desc = 'Open terminal in vertical split' })
vim.keymap.set('n', '<leader>tf', '<Cmd>terminal<CR>', { desc = 'Open terminal in current window' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('n', '[b', '<Cmd>bprevious<CR>', { desc = 'Previous buffer' })
vim.keymap.set('n', ']b', '<Cmd>bnext<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<leader>bd', '<Cmd>bdelete<CR>', { desc = 'Delete buffer' })

-- ====================================================================
-- Helpers
-- ====================================================================

---Expands `owner/repo` into a clone URL, as most plugins live on GitHub.
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

---Ensures a plugin's native library is built after install/update and at startup.
---@param name string Plugin directory name.
---@param build fun(path: string) Build the library if needed.
local function ensure_built(name, build)
  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(args)
      local data = args.data
      if data.spec.name == name and (data.kind == 'install' or data.kind == 'update') then
        build(data.path)
      end
    end,
  })

  local path = vim.pack.get({ name })[1].path
  build(path)
end

-- ====================================================================
-- Common dependencies
-- ====================================================================

vim.pack.add {
  gh 'nvim-lua/plenary.nvim',
  gh 'nvim-tree/nvim-web-devicons',
}

-- ====================================================================
-- Notifications
-- ====================================================================

vim.pack.add {
  gh 'nvim-mini/mini.notify',
}

local notify = require('mini.notify')

notify.setup {
  content = {
    format = function(notification) return notification.msg end,
  },
  window = {
    config = { title = '' },
    winblend = 0,
  },
}

vim.notify = notify.make_notify()

-- ====================================================================
-- Theme
-- ====================================================================

vim.pack.add {
  gh 'projekt0n/github-nvim-theme',
}

---Neovim detects the terminal background via OSC 11, so this follows the
---macOS appearance.
local function apply_theme()
  local theme = vim.o.background == 'light' and 'github_light_default' or 'github_dark_default'
  if vim.g.colors_name ~= theme then vim.cmd.colorscheme(theme) end
end

---The OSC 11 reply can land late, and OptionSet is suppressed during startup.
---Defer until the background change finishes, or it immediately clears the
---color scheme just applied.
local function schedule_theme() vim.schedule(apply_theme) end

apply_theme()

vim.api.nvim_create_autocmd('VimEnter', { once = true, callback = schedule_theme })
vim.api.nvim_create_autocmd('OptionSet', { pattern = 'background', callback = schedule_theme })

-- ====================================================================
-- Status line
-- ====================================================================

vim.pack.add {
  gh 'nvim-lualine/lualine.nvim',
}

vim.o.cmdheight = 0
vim.o.laststatus = 3
vim.o.showmode = false

---@diagnostic disable-next-line: undefined-field
require('lualine').setup {
  options = {
    section_separators = '',
    component_separators = '',
  },
  sections = {
    lualine_x = { 'encoding', 'filetype' },
  },
}

-- ====================================================================
-- Telescope
-- ====================================================================

vim.pack.add {
  gh 'nvim-telescope/telescope.nvim',
  gh 'nvim-telescope/telescope-fzf-native.nvim',
}

-- fzf-native is a C port of the fzf algorithm, so no fzf executable is needed.
-- Telescope cannot load the extension without the library, hence the blocking
-- build.
ensure_built('telescope-fzf-native.nvim', function(path)
  if vim.uv.fs_stat(vim.fs.joinpath(path, 'build/libfzf.so')) then return end

  local result = vim.system({ 'make' }, { cwd = path }):wait()
  if result.code ~= 0 then
    error('failed to build telescope-fzf-native.nvim: ' .. result.stderr)
  end
end)

local telescope = require('telescope')
local actions = require('telescope.actions')

telescope.setup {
  defaults = {
    mappings = {
      i = {
        ['<Esc>'] = actions.close,
      },
    },
  },
}

telescope.load_extension('fzf')

local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>/', builtin.current_buffer_fuzzy_find, { desc = 'Fuzzy find in current buffer' })
vim.keymap.set('n', '<leader>ft', '<Cmd>Telescope<CR>', { desc = 'Open Telescope' })
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help tags' })

-- Open Telescope when Neovim starts with a directory argument instead of netrw.
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    local dir = vim.api.nvim_buf_get_name(0)
    if dir == '' or vim.fn.isdirectory(dir) ~= 1 then return end

    -- Make the directory passed on the command line Neovim's global cwd.
    vim.fn.chdir(dir)

    local buf = vim.api.nvim_get_current_buf()
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
      builtin.find_files { cwd = dir }
    end)
  end,
})

-- ====================================================================
-- Which-key
-- ====================================================================

vim.pack.add {
  gh 'folke/which-key.nvim',
}

require('which-key').setup {
  icons = { mappings = false },
}

-- ====================================================================
-- tree-sitter
-- ====================================================================

vim.pack.add {
  gh 'nvim-treesitter/nvim-treesitter',
}

local ts = require('nvim-treesitter')
local available_parsers = ts.get_available()

---Starts Tree-sitter highlighting.
---@param buf integer Buffer handle.
---@param lang string Tree-sitter language name.
local function start_ts(buf, lang)
  if vim.api.nvim_buf_is_valid(buf) and vim.treesitter.language.add(lang) then
    vim.treesitter.start(buf, lang)
  end
end

vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if not lang then return end

    local installed = vim.list_contains(ts.get_installed('parsers'), lang)
    if not installed and vim.list_contains(available_parsers, lang) then
      ts.install(lang):await(function() start_ts(args.buf, lang) end)
      return
    end

    start_ts(args.buf, lang)
  end,
})

-- ====================================================================
-- Blink
-- ====================================================================

vim.pack.add {
  gh 'Saghen/blink.lib',
  gh 'Saghen/blink.cmp',
}

local cmp = require('blink.cmp')

-- The Rust fuzzy matcher is optional, so build it in the background and let
-- blink.cmp use its Lua implementation until the library is ready.
ensure_built('blink.cmp', function()
  if not cmp.library_available() then cmp.build() end
end)

cmp.setup {
  keymap = { preset = 'super-tab' },
  completion = {
    menu = { scrolloff = 0 },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 300,
    },
  },
  signature = { enabled = true },
}

-- ====================================================================
-- LSP
-- ====================================================================

vim.pack.add {
  gh 'neovim/nvim-lspconfig',
  gh 'mason-org/mason.nvim',
  gh 'mason-org/mason-lspconfig.nvim',
}

require('mason').setup()
require('mason-lspconfig').setup {
  ensure_installed = {
    'tsc',
    'vtsls',
    'astro',
    'basedpyright',
    'ruff',
    'lua_ls',
    'rust_analyzer',
  },
}

---Whether the project uses TypeScript 7 or newer.
---
---TypeScript 7 ships a native language server (`tsc --lsp`); earlier versions
---need `vtsls`.
---@param root string
---@return boolean
local function is_ts7(root)
  local ok, version = pcall(function()
    local path = vim.fs.joinpath(root, 'node_modules/typescript/package.json')
    local pkg = vim.json.decode(table.concat(vim.fn.readfile(path), '\n'))
    return assert(vim.version.parse(pkg.version))
  end)
  return not ok or version.major >= 7
end

local tsc_root_dir = assert(vim.lsp.config.tsc.root_dir)
vim.lsp.config('tsc', {
  root_dir = function(bufnr, on_dir)
    tsc_root_dir(bufnr, function(root)
      if is_ts7(root) then on_dir(root) end
    end)
  end,
})

local vtsls_root_dir = assert(vim.lsp.config.vtsls.root_dir)
vim.lsp.config('vtsls', {
  root_dir = function(bufnr, on_dir)
    vtsls_root_dir(bufnr, function(root)
      if not is_ts7(root) then on_dir(root) end
    end)
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local function map(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = args.buf, desc = desc })
    end

    map('K', vim.lsp.buf.hover, 'Show hover documentation')
    map('gd', builtin.lsp_definitions, 'Go to definition')
    map('grr', builtin.lsp_references, 'Find references')
  end,
})

-- ====================================================================
-- Git
-- ====================================================================

vim.pack.add {
  gh 'lewis6991/gitsigns.nvim',
}

require('gitsigns').setup()

-- ====================================================================
-- Pairs and tags
-- ====================================================================

vim.pack.add {
  gh 'windwp/nvim-autopairs',
  gh 'windwp/nvim-ts-autotag',
}

require('nvim-autopairs').setup()
require('nvim-ts-autotag').setup()
