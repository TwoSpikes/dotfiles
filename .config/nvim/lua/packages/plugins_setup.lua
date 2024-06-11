require('packages.vim-notify')
require('packages.lsp.plugins')
require('packages.treesitter')
require('packages.netrw')
require('packages.which-key.init')
--require('packages.bufresize.init')
require('packages.quickui.init')
vim.cmd('exec printf("so %s/lua/packages/mason.vim", g:CONFIG_PATH)')
if vim.g.use_nvim_cmp then
	require('packages.nvim-cmp.init')
else
	require('packages.coc.init')
end
require('packages.vim-illuminate.init')
require('packages.todo-comments.init')
require('packages.indent-blankline.init')
require('packages.dap.init')
require('packages.dapui.init')
require('packages.gitsigns.init')
