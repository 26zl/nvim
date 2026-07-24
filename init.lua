-- Portable Neovim config (0.11.3+) for Linux, macOS, WSL, and Windows.
local function fail_startup(message)
	vim.api.nvim_echo({ { message, "ErrorMsg" } }, true, {})
	os.exit(1)
end

if vim.fn.has("nvim-0.11.3") == 0 then
	local v = vim.version()
	fail_startup(("This config needs Neovim 0.11.3 or newer; you have %d.%d.%d."):format(v.major, v.minor, v.patch))
end

vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- Set to false in a terminal without a Nerd Font; icons fall back to plain text.
vim.g.have_nerd_font = true

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
opt.showmode = false -- lualine already shows the mode
opt.inccommand = "split" -- live preview while typing a :substitute
opt.confirm = true -- prompt about unsaved changes instead of failing
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
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
	{
		"nvim-lualine/lualine.nvim",
		opts = {
			options = { theme = "nordic", globalstatus = true, icons_enabled = vim.g.have_nerd_font },
		},
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			delay = 0,
			icons = { mappings = vim.g.have_nerd_font },
			spec = {
				{ "<leader>f", group = "Find" },
				{ "<leader>g", group = "Git" },
				{ "<leader>l", group = "LSP" },
				{ "<leader>c", group = "Code" },
				{ "<leader>r", group = "Rename" },
				{ "<leader>x", group = "Diagnostics" },
				{ "<leader>i", group = "Toggle" },
			},
		},
	},

	-- Follows the indentation a file already uses instead of forcing 2 spaces.
	{ "NMAC427/guess-indent.nvim", opts = {} },

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
			highlight = {
				enable = true,
				disable = function(_, buf)
					return vim.b[buf].big_file == true
				end,
			},
			indent = { enable = true },
		},
	},

	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			-- Routes vim.ui.select (code actions, …) through Telescope.
			"nvim-telescope/telescope-ui-select.nvim",
			{
				-- On Windows, build with the MinGW toolchain (gcc + make) that
				-- Treesitter also needs, rather than CMake + MSVC. See README.
				"nvim-telescope/telescope-fzf-native.nvim",
				build = is_windows
						and function(plugin)
							-- Drop any half-built output so make's mkdir step can't error on a rebuild.
							vim.fn.delete(plugin.dir .. "/build", "rf")
							local make = (vim.fn.executable("mingw32-make") == 1 and "mingw32-make")
								or (vim.fn.executable("make") == 1 and "make")
							if not make then
								error(
									"telescope-fzf-native needs a MinGW toolchain (gcc + mingw32-make); see README Requirements"
								)
							end
							local res = vim.system({ make }, { cwd = plugin.dir, text = true }):wait()
							if res.code ~= 0 then
								error(
									"telescope-fzf-native build failed:\n" .. (res.stdout or "") .. (res.stderr or "")
								)
							end
						end
					or "make",
			},
		},
		config = function()
			local telescope = require("telescope")
			telescope.setup({
				extensions = { ["ui-select"] = { require("telescope.themes").get_dropdown() } },
			})
			pcall(telescope.load_extension, "fzf")
			pcall(telescope.load_extension, "ui-select")
			local b = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", b.find_files, { desc = "Find files" })
			vim.keymap.set("n", "<leader>fg", b.live_grep, { desc = "Grep in project" })
			vim.keymap.set("n", "<leader>fb", b.buffers, { desc = "Buffers" })
			vim.keymap.set("n", "<leader>fh", b.help_tags, { desc = "Help" })
			vim.keymap.set("n", "<leader>fd", b.diagnostics, { desc = "Diagnostics" })
			vim.keymap.set("n", "<leader>fo", b.oldfiles, { desc = "Recent files" })
			vim.keymap.set("n", "<leader>fr", b.resume, { desc = "Resume last picker" })
			vim.keymap.set("n", "<leader>fk", b.keymaps, { desc = "Keymaps" })
			vim.keymap.set({ "n", "x" }, "<leader>fw", b.grep_string, { desc = "Grep word under cursor" })
			vim.keymap.set("n", "<leader>/", b.current_buffer_fuzzy_find, { desc = "Fuzzy find in buffer" })
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

	-- Undo is persistent (opt.undofile); this makes the history navigable.
	{
		"mbbill/undotree",
		cmd = { "UndotreeToggle", "UndotreeFocus" },
		keys = { { "<leader>u", "<cmd>UndotreeToggle<cr><cmd>UndotreeFocus<cr>", desc = "Undo tree" } },
	},
	-- :SudaWrite saves a root-owned file without reopening Neovim under sudo.
	{ "lambdalisue/vim-suda", cmd = { "SudaRead", "SudaWrite" } },

	{
		"echasnovski/mini.nvim",
		lazy = false,
		-- Loads before lualine/telescope so the icon swap below is in place first.
		priority = 900,
		config = function()
			require("mini.ai").setup()
			require("mini.surround").setup()
			require("mini.pairs").setup()

			-- Without a Nerd Font, stand in for nvim-web-devicons with ASCII icons
			-- so every plugin that asks for an icon gets a readable one.
			if not vim.g.have_nerd_font then
				local icons = require("mini.icons")
				icons.setup({ style = "ascii" })
				icons.mock_nvim_web_devicons()
			end

			require("mini.starter").setup({
				header = [[
  /|  |\            /|  |\
  /|  |\            /|  |\
 / |  | \          / |  | \
 | |  | |          | |  | |
 \  \/  /  __  __  \  \/  /
  \    /  / /  \ \  \    /
   \  /   \ \__/ /   \  /
   \  /   /      \   \  /
  _ \ \__/ O    O \__/ / _
  \\ \___          ___/ //
_  \\___/  ______  \___//  _
\\  ----(          )----  //
 \\_____( ________ )_____//
  ~-----(          )-----~ _
   _____( ________ )_____  \\
  /,----(          )----  _//
 //     (  ______  )     /  \
 ~       \        /      \  /
          \  __  /       / /
           \    /       / /
            \   \      / /
             \   ~----~ /
              \________/]],
				items = {
					{ section = "Menu", name = "Find file", action = "Telescope find_files" },
					{ section = "Menu", name = "Recent files", action = "Telescope oldfiles" },
					{ section = "Menu", name = "Live grep", action = "Telescope live_grep" },
					{ section = "Menu", name = "Quit", action = "qa" },
				},
				footer = function()
					local v = vim.version()
					return ("Neovim v%d.%d.%d"):format(v.major, v.minor, v.patch)
				end,
			})
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

	-- Linting alongside conform's formatting. A linter whose binary is missing is
	-- skipped rather than reported as an error on every save.
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPost", "BufWritePost" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				sh = { "shellcheck" },
				bash = { "shellcheck" },
				markdown = { "markdownlint-cli2" },
			}

			local function binary(name)
				local ok, linter = pcall(function()
					return lint.linters[name]
				end)
				return (ok and type(linter) == "table" and linter.cmd) or name
			end

			vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
				group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
				callback = function()
					if not vim.bo.modifiable then
						return
					end
					local runnable = vim.tbl_filter(function(name)
						return vim.fn.executable(binary(name)) == 1
					end, lint.linters_by_ft[vim.bo.filetype] or {})
					if #runnable > 0 then
						lint.try_lint(runnable)
					end
				end,
			})
		end,
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

			-- Teach lua_ls about the Neovim runtime so editing this config does not
			-- report `vim` as undefined. stylua owns formatting.
			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						workspace = {
							checkThirdParty = false,
							library = { vim.env.VIMRUNTIME, "${3rd}/luv/library" },
						},
						diagnostics = { globals = { "vim" } },
						completion = { callSnippet = "Replace" },
						format = { enable = false },
						telemetry = { enable = false },
					},
				},
			})

			if is_nixos then
				vim.lsp.enable(servers)
			else
				-- Mason ships prebuilt binaries for most servers, but a few are built
				-- from source and fail loudly when their toolchain is absent.
				-- nil's build script also shells out to `nix` for the Nix builtins.
				local needs = { nil_ls = "nix", gopls = "go" }
				local installable = vim.tbl_filter(function(name)
					local tool = needs[name]
					return not tool or vim.fn.executable(tool) == 1
				end, servers)
				require("mason-lspconfig").setup({ ensure_installed = installable })
				require("mason-tool-installer").setup({
					ensure_installed = {
						"stylua",
						"shfmt",
						"black",
						"isort",
						"prettierd",
						"shellcheck",
						"markdownlint-cli2",
					},
				})
			end

			-- Remove longer defaults so `gr` does not wait for another key.
			for _, k in ipairs({ "grr", "gra", "grn", "gri", "grt", "grx" }) do
				pcall(vim.keymap.del, "n", k)
			end

			local highlight_group = vim.api.nvim_create_augroup("lsp-document-highlight", { clear = false })

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(ev)
					local client = vim.lsp.get_client_by_id(ev.data.client_id)

					-- Large files are opened without syntax or analysis; keep it that way.
					if vim.b[ev.buf].big_file then
						vim.lsp.buf_detach_client(ev.buf, ev.data.client_id)
						return
					end

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

					-- Underline the other uses of whatever the cursor is resting on.
					if client and client:supports_method("textDocument/documentHighlight") then
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = ev.buf,
							group = highlight_group,
							callback = vim.lsp.buf.document_highlight,
						})
						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = ev.buf,
							group = highlight_group,
							callback = vim.lsp.buf.clear_references,
						})
					end
				end,
			})

			vim.api.nvim_create_autocmd("LspDetach", {
				group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
				callback = function(ev)
					vim.lsp.buf.clear_references()
					vim.api.nvim_clear_autocmds({ group = highlight_group, buffer = ev.buf })
				end,
			})
		end,
	},
}, { ui = { border = "rounded" }, checker = { enabled = false } })

vim.diagnostic.config({
	severity_sort = true,
	update_in_insert = false,
	underline = { severity = { min = vim.diagnostic.severity.WARN } },
	float = { source = "if_many" },
	virtual_text = { source = "if_many" },
})

local augroup = function(name)
	return vim.api.nvim_create_augroup(name, { clear = true })
end

-- Briefly highlight whatever was just yanked.
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("highlight-yank"),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- Files past this size open as plain text: no syntax, Treesitter, LSP, swap or
-- undo history, so a stray log or dump stays usable instead of hanging Neovim.
local big_file_bytes = 1536 * 1024
vim.api.nvim_create_autocmd("BufReadPre", {
	group = augroup("big-file"),
	callback = function(ev)
		local stats = vim.uv.fs_stat(vim.api.nvim_buf_get_name(ev.buf))
		if not stats or stats.size <= big_file_bytes then
			return
		end
		vim.b[ev.buf].big_file = true
		vim.bo[ev.buf].swapfile = false
		vim.bo[ev.buf].undofile = false
		vim.opt_local.list = false
		vim.opt_local.foldmethod = "manual"
		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(ev.buf) then
				vim.bo[ev.buf].syntax = ""
			end
		end)
	end,
})

-- Terminal buffers have no use for numbers, signs or whitespace markers.
vim.api.nvim_create_autocmd("TermOpen", {
	group = augroup("terminal-ui"),
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
		vim.opt_local.list = false
	end,
})

vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Window left" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Window down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Window up" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Window right" })
vim.keymap.set("n", "<C-Up>", "<cmd>resize -2<cr>", { desc = "Shrink window" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize +2<cr>", { desc = "Grow window" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Narrow window" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Widen window" })

vim.keymap.set("x", "<", "<gv", { desc = "Dedent and keep the selection" })
vim.keymap.set("x", ">", ">gv", { desc = "Indent and keep the selection" })
vim.keymap.set("x", "p", '"_dP', { desc = "Paste over without clobbering the register" })

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Leave terminal mode" })
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

-- The README lists the programs this config expects; `:CheckDeps` reports which
-- of them are actually on PATH, so a gap shows up here rather than as a build
-- failure in `:Mason` or a Treesitter parser that never compiles.
local external_tools = {
	{ names = { "git" }, required = true, purpose = "lazy.nvim clones and pins plugins" },
	{ names = { "cc", "gcc", "clang" }, required = true, purpose = "Treesitter parsers, fzf-native" },
	{ names = { "make", "mingw32-make" }, required = true, purpose = "Treesitter parsers, fzf-native" },
	{ names = { "rg" }, required = true, purpose = "Telescope live-grep" },
	{ names = { "fd", "fdfind" }, purpose = "faster Telescope file search" },
	{ names = { "node" }, purpose = "Mason: python/ts/bash/yaml/docker/ansible, prettier" },
	{ names = { "python3", "python" }, purpose = "Mason: black, isort" },
	{ names = { "go" }, purpose = "Mason: gopls" },
	{ names = { "cargo" }, purpose = "Mason: nil" },
	{ names = { "nix" }, purpose = "Mason: nil build script" },
	{ names = { "unzip" }, purpose = "Mason unpacks some releases" },
	{ names = { "lazygit" }, purpose = "<leader>gg" },
	{ names = { "shellcheck" }, purpose = "shell linting" },
	{ names = { "markdownlint-cli2" }, purpose = "markdown linting" },
}

vim.api.nvim_create_user_command("CheckDeps", function()
	local chunks = { { "External dependencies\n\n", "Title" } }
	local missing = 0

	for _, tool in ipairs(external_tools) do
		local found
		for _, name in ipairs(tool.names) do
			if vim.fn.executable(name) == 1 then
				found = name
				break
			end
		end
		local status, highlight = "warn", "DiagnosticWarn"
		if found then
			status, highlight = "ok", "DiagnosticOk"
		elseif tool.required then
			status, highlight = "MISSING", "DiagnosticError"
			missing = missing + 1
		end
		table.insert(chunks, { ("%-9s"):format(status), highlight })
		table.insert(chunks, { ("%-20s %s\n"):format(found or table.concat(tool.names, " / "), tool.purpose) })
	end

	local clipboard = vim.fn.has("clipboard_working") == 1
	local clipboard_status = clipboard and "ok" or "warn"
	local clipboard_highlight = clipboard and "DiagnosticOk" or "DiagnosticWarn"
	table.insert(chunks, { ("%-9s"):format(clipboard_status), clipboard_highlight })
	table.insert(chunks, { ("%-20s %s\n"):format("clipboard", "system clipboard provider (opt.clipboard)") })

	local summary = missing == 0 and "\nEverything required is present; warnings are optional tooling.\n"
		or ("\n%d required program(s) missing — see the Requirements section of the README.\n"):format(missing)
	table.insert(chunks, { summary, missing == 0 and "DiagnosticOk" or "DiagnosticError" })
	vim.api.nvim_echo(chunks, true, {})
end, { desc = "Report the external programs this config expects" })
