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
vim.o.mousescroll = 'ver:0,hor:0'

-- Sync clipboard between OS and Neovim.
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

-- ====================================================================
-- Helpers
-- ====================================================================

--- Because most plugins are hosted on GitHub, we can use the helper
--- function to have less repetition in the following sections.
--- @param repo string
--- @return string
local function gh(repo) return 'https://github.com/' .. repo end

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
  gh 'rcarriga/nvim-notify',
}

vim.notify = require('notify')

-- ====================================================================
-- Theme
-- ====================================================================

vim.pack.add {
  gh 'projekt0n/github-nvim-theme',
}

-- Neovim detects the terminal background via OSC 11, so this follows
-- macOS appearance.
local function apply_theme()
  local theme = vim.o.background == 'light' and 'github_light_default' or 'github_dark_default'
  if vim.g.colors_name ~= theme then vim.cmd.colorscheme(theme) end
end

-- The terminal's OSC 11 reply can land late, and OptionSet is
-- suppressed during startup. Defer until the background change finishes;
-- otherwise, it immediately clears the newly applied color scheme.
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

require('lualine').setup {
  options = {
    section_separators = '',
    component_separators = '',
  },
  sections = {
    lualine_x = {'encoding', 'filetype'},
  },
}

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

ts.install({
  'javascript',
  'jsx',
  'typescript',
  'tsx',
  'json',
  'python',
  'lua',
  'rust',
})

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

cmp.build():pwait()
cmp.setup {
  completion = {
    menu = { scrolloff = 0 },
  },
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
    'vtsls',
    'basedpyright',
    'ruff',
    'lua_ls',
    'rust_analyzer',
  },
}

-- ====================================================================
-- Telescope
-- ====================================================================

vim.pack.add {
  gh 'nvim-telescope/telescope.nvim',
  gh 'nvim-telescope/telescope-fzf-native.nvim',
}

-- fzf-native is a C implementation of the fzf algorithm, so it does not
-- require the fzf executable. Build its shared library after installation
-- and updates instead.
local fzf_native_name = 'telescope-fzf-native.nvim'

local function build_fzf_native(path)
  local result = vim.system({ 'make' }, { cwd = path }):wait()
  if result.code ~= 0 then
    error(('failed to build %s: %s'):format(fzf_native_name, result.stderr))
  end
end

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(args)
    local data = args.data
    local name = data.spec.name
    local kind = data.kind
    if name == fzf_native_name and (kind == 'install' or kind == 'update') then
      build_fzf_native(data.path)
    end
  end,
})

local fzf_native = vim.pack.get({ fzf_native_name })[1]
if vim.fn.filereadable(fzf_native.path .. '/build/libfzf.so') == 0 then
  build_fzf_native(fzf_native.path)
end

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
-- Git
-- ====================================================================

vim.pack.add {
  gh 'lewis6991/gitsigns.nvim',
}

require('gitsigns').setup()
