-- Portable Neovim config — works on any Linux, macOS, WSL and Windows.
-- Beginner-friendly (which-key shows keys) and sysadmin/system-engineering ready.
--
-- LSP servers: on NixOS they come from the system; elsewhere Mason auto-installs
-- them. Everything else (keymaps, plugins, UI) is identical on every OS.
--
-- Install locations:
--   Linux/macOS: ~/.config/nvim/init.lua
--   Windows:     ~/AppData/Local/nvim/init.lua

-- This config uses vim.lsp.config()/vim.lsp.enable(), added in Neovim 0.11.
-- Fail clearly on older builds instead of crashing later with a cryptic nil-value
-- error from the LSP setup.
if vim.fn.has("nvim-0.11") == 0 then
	local v = vim.version()
	vim.notify(
		("This Neovim config needs 0.11+ (you have %d.%d.%d). Install a newer Neovim."):format(
			v.major,
			v.minor,
			v.patch
		),
		vim.log.levels.ERROR
	)
	return
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local is_nixos = vim.fn.filereadable("/etc/NIXOS") == 1
local is_windows = vim.fn.has("win32") == 1

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = 400
opt.scrolloff = 8
opt.splitright = true
opt.splitbelow = true
opt.cursorline = true
opt.breakindent = true
if vim.fn.exists("&winborder") == 1 then
	opt.winborder = "rounded"
end

-- Bootstrap lazy.nvim (portable path handling)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

local servers = {
	"lua_ls",
	"pyright",
	"ts_ls",
	"gopls",
	"rust_analyzer",
	"nil_ls",
	"bashls",
	"yamlls",
	"dockerls",
	"ansiblels",
	"terraformls",
	"clangd",
	"marksman",
}

-- Mason installs every server except nil_ls (Nix), which ships only via the system on NixOS.
local mason_servers = vim.tbl_filter(function(s)
	return s ~= "nil_ls"
end, servers)

require("lazy").setup({
	-- Nordic colorscheme (Nord-based, warmer and darker)
	{
		"AlexvZyl/nordic.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("nordic").load()
		end,
	},

	"nvim-tree/nvim-web-devicons",
	{ "nvim-lualine/lualine.nvim", opts = { options = { theme = "nordic", globalstatus = true } } },
	{ "folke/which-key.nvim", event = "VeryLazy", opts = {} },

	-- Buffer tabs
	{
		"akinsho/bufferline.nvim",
		dependencies = "nvim-tree/nvim-web-devicons",
		event = "VeryLazy",
		opts = {
			options = {
				diagnostics = "nvim_lsp",
				separator_style = "slant",
				offsets = { { filetype = "neo-tree", text = "File Explorer", separator = true } },
			},
		},
		keys = {
			{ "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
			{ "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
		},
	},

	-- Syntax
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		build = ":TSUpdate",
		main = "nvim-treesitter.configs",
		opts = {
			ensure_installed = {
				"bash",
				"lua",
				"nix",
				"python",
				"go",
				"rust",
				"json",
				"yaml",
				"toml",
				"dockerfile",
				"hcl",
				"markdown",
				"markdown_inline",
				"vimdoc",
				"gitcommit",
			},
			auto_install = true,
			highlight = { enable = true },
			indent = { enable = true },
		},
	},

	-- Fuzzy finder
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				-- Native sorter: `make` on Unix, CMake on Windows (no make there).
				"nvim-telescope/telescope-fzf-native.nvim",
				build = is_windows
						and "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build"
					or "make",
			},
		},
		config = function()
			local telescope = require("telescope")
			telescope.setup({})
			pcall(telescope.load_extension, "fzf")
			local b = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", b.find_files, { desc = "Find files" })
			vim.keymap.set("n", "<leader>fg", b.live_grep, { desc = "Grep in project" })
			vim.keymap.set("n", "<leader>fb", b.buffers, { desc = "Buffers" })
			vim.keymap.set("n", "<leader>fh", b.help_tags, { desc = "Help" })
			vim.keymap.set("n", "<leader>fd", b.diagnostics, { desc = "Diagnostics" })
		end,
	},

	-- File explorer
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
		keys = { { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "File tree" } },
		opts = {},
	},

	{ "lewis6991/gitsigns.nvim", opts = {} },
	{
		"kdheepak/lazygit.nvim",
		dependencies = "nvim-lua/plenary.nvim",
		cmd = { "LazyGit", "LazyGitCurrentFile" },
		keys = { { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" } },
	},
	{ "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
	{ "folke/todo-comments.nvim", dependencies = { "nvim-lua/plenary.nvim" }, opts = { signs = false } },
	{
		"folke/trouble.nvim",
		opts = {},
		keys = { { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" } },
	},

	-- Editing helpers: a/i text objects, surround (sa/sd/sr), auto-pairs.
	-- (Commenting is built into Neovim 0.10+: gc / gcc.)
	{
		"echasnovski/mini.nvim",
		config = function()
			require("mini.ai").setup()
			require("mini.surround").setup()
			require("mini.pairs").setup()
		end,
	},

	-- Formatting (falls back to the LSP when a formatter is missing)
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		opts = {
			format_on_save = { timeout_ms = 2000, lsp_format = "fallback" },
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				nix = { "nixfmt" },
				go = { "gofmt" },
				rust = { "rustfmt" },
				javascript = { "prettierd", "prettier", stop_after_first = true },
				typescript = { "prettierd", "prettier", stop_after_first = true },
				json = { "prettierd", "prettier", stop_after_first = true },
				yaml = { "prettierd", "prettier", stop_after_first = true },
				markdown = { "prettierd", "prettier", stop_after_first = true },
			},
		},
	},

	-- Completion
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			cmp.setup({
				snippet = {
					expand = function(a)
						luasnip.lsp_expand(a.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping.select_next_item(),
					["<S-Tab>"] = cmp.mapping.select_prev_item(),
				}),
				sources = {
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "buffer" },
					{ name = "path" },
				},
			})
		end,
	},

	-- LSP. On NixOS the servers are on PATH already; elsewhere Mason installs them.
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			{ "mason-org/mason.nvim", cond = not is_nixos, config = true },
			{ "mason-org/mason-lspconfig.nvim", cond = not is_nixos },
			{ "WhoIsSethDaniel/mason-tool-installer.nvim", cond = not is_nixos },
		},
		config = function()
			vim.lsp.config("*", { capabilities = require("cmp_nvim_lsp").default_capabilities() })

			if is_nixos then
				vim.lsp.enable(servers)
			else
				require("mason-lspconfig").setup({ ensure_installed = mason_servers })
				require("mason-tool-installer").setup({
					ensure_installed = { "stylua", "shfmt", "black", "isort", "prettierd" },
				})
			end

			-- Neovim's default gr-prefixed LSP maps (grr/gra/grn/gri/grt/grx) would make our
			-- `gr` wait out timeoutlen for a longer match; drop them so `gr` fires instantly.
			for _, k in ipairs({ "grr", "gra", "grn", "gri", "grt", "grx" }) do
				pcall(vim.keymap.del, "n", k)
			end

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(ev)
					local map = function(keys, fn, desc)
						vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = desc })
					end
					map("gd", vim.lsp.buf.definition, "Go to definition")
					map("gr", vim.lsp.buf.references, "References")
					map("gI", vim.lsp.buf.implementation, "Go to implementation")
					map("gy", vim.lsp.buf.type_definition, "Type definition")
					map("K", vim.lsp.buf.hover, "Hover docs")
					map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
					map("<leader>ca", vim.lsp.buf.code_action, "Code action")
				end,
			})
		end,
	},
}, { ui = { border = "rounded" }, checker = { enabled = false } })

vim.diagnostic.config({ severity_sort = true })

-- General keymaps
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
vim.keymap.set("n", "<leader>t", function()
	vim.cmd("botright 12split | terminal")
	vim.cmd("startinsert")
end, { desc = "Terminal (bottom split)" })
vim.keymap.set("n", "<leader>lf", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })
vim.keymap.set("n", "<leader>ih", function()
	local buf = vim.api.nvim_get_current_buf()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
end, { desc = "Toggle inlay hints" })
