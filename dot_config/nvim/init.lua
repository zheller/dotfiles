vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("config.runtime").setup()
require("config.options").setup()
require("config.commands").setup()
require("config.keymaps").setup()
require("config.lsp").setup()
require("plugins").setup()
require("config.colors").setup()
require("config.autocmds").setup()
require("config.statusline").setup()
require("config.treesitter").setup()
