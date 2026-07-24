-- Portable Neovim config (0.11.3+) for Linux, macOS, WSL, and Windows.
local function fail_startup(message)
	vim.api.nvim_echo({ { message, "ErrorMsg" } }, true, {})
	os.exit(1)
end

if vim.fn.has("nvim-0.11.3") == 0 then
	local v = vim.version()
	fail_startup(("This config needs Neovim 0.11.3 or newer; you have %d.%d.%d."):format(v.major, v.minor, v.patch))
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
opt.winborder = "rounded"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
local read_ok, lock_lines = pcall(vim.fn.readfile, lockfile)
local decode_ok, lock = pcall(vim.json.decode, read_ok and table.concat(lock_lines, "\n") or "")
local lazy_entry = decode_ok and type(lock) == "table" and lock["lazy.nvim"]
local lazy_commit = type(lazy_entry) == "table" and lazy_entry.commit
if type(lazy_commit) ~= "string" or #lazy_commit ~= 40 or not lazy_commit:match("^%x+$") then
	fail_startup("lazy-lock.json does not contain a valid lazy.nvim commit.")
end

local function git_or_fail(arguments, message)
	table.insert(arguments, 1, "git")
	local ok, output = pcall(vim.fn.system, arguments)
	if not ok or vim.v.shell_error ~= 0 then
		fail_startup(message .. "\n" .. output)
	end
	return vim.trim(output)
end

local cloned = false
if not vim.uv.fs_stat(lazypath) then
	git_or_fail({
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	}, "Failed to clone lazy.nvim.")
	cloned = true
end

local lazy_head = git_or_fail({ "-C", lazypath, "rev-parse", "HEAD" }, "Failed to inspect lazy.nvim.")
if lazy_head ~= lazy_commit then
	git_or_fail({
		"-C",
		lazypath,
		"fetch",
		"--depth=1",
		"--filter=blob:none",
		"origin",
		lazy_commit,
	}, "Failed to fetch the locked lazy.nvim commit.")
end
if cloned or lazy_head ~= lazy_commit then
	git_or_fail({
		"-C",
		lazypath,
		"checkout",
		"--detach",
		lazy_commit,
	}, "Failed to check out the locked lazy.nvim commit.")
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

require("lazy").setup({
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

	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				-- Windows runners provide CMake rather than make.
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

	{
		"echasnovski/mini.nvim",
		config = function()
			require("mini.ai").setup()
			require("mini.surround").setup()
			require("mini.pairs").setup()
		end,
	},

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
				-- nil has no prebuilt binary: Mason builds it from source, and its
				-- build script shells out to `nix` to extract the Nix builtins.
				local installable = vim.tbl_filter(function(name)
					return name ~= "nil_ls" or vim.fn.executable("nix") == 1
				end, servers)
				require("mason-lspconfig").setup({ ensure_installed = installable })
				require("mason-tool-installer").setup({
					ensure_installed = { "stylua", "shfmt", "black", "isort", "prettierd" },
				})
			end

			-- Remove longer defaults so `gr` does not wait for another key.
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
