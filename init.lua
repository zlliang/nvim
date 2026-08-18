-- ====================================================================
-- Options
-- ====================================================================

vim.loader.enable()

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.o.number = true
vim.o.signcolumn = 'yes'

vim.o.splitbelow = true
vim.o.splitright = true

vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 0
vim.o.confirm = true

vim.o.mouse = ''

-- Sync clipboard between OS and Neovim.
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

-- ====================================================================
-- Helpers
-- ====================================================================

--- Expands `owner/repo` into a clone URL, as most plugins live on GitHub.
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

--- Ensures a plugin's native library is built after install/update and at startup.
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

notify.setup()
vim.notify = require('mini.notify').make_notify()

-- ====================================================================
-- Theme
-- ====================================================================

vim.pack.add {
  gh 'projekt0n/github-nvim-theme',
}

--- Neovim detects the terminal background via OSC 11, so this follows the
--- macOS appearance.
local function apply_theme()
  local theme = vim.o.background == 'light' and 'github_light_default' or 'github_dark_default'
  if vim.g.colors_name ~= theme then vim.cmd.colorscheme(theme) end
end

--- The OSC 11 reply can land late, and OptionSet is suppressed during startup.
--- Defer until the background change finishes, or it immediately clears the
--- color scheme just applied.
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
    scroll_strategy = 'limit',
  },
}

telescope.load_extension('fzf')

local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help tags' })

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

ts.install {
  'javascript',
  'jsx',
  'typescript',
  'tsx',
  'json',
  'python',
  'lua',
  'rust',
}

vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)

    if lang and vim.list_contains(ts.get_installed(), lang) then
      vim.treesitter.start(args.buf, lang)
    end
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

--- Whether the project uses TypeScript 7 or newer.
---
--- TypeScript 7 ships a native language server (`tsc --lsp`); earlier versions
--- need `vtsls`.
---@param root string
---@return boolean
local function is_ts7(root)
  local ok, version = pcall(function()
    local path = vim.fs.joinpath(root, 'node_modules/typescript/package.json')
    local pkg = vim.json.decode(table.concat(vim.fn.readfile(path), '\n'))
    return assert(vim.version.parse(pkg.version))
  end)
  return ok and version.major >= 7
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
