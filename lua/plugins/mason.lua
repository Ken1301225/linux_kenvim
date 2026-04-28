return {
	"mason-org/mason.nvim",
	dependencies = {
		"neovim/nvim-lspconfig",
		"mason-org/mason-lspconfig.nvim",
	},
	opts = {},
	config = function(_, opts)
		require("mason").setup(opts)
		local registry = require("mason-registry")

		local function apply_code_action(action)
			vim.lsp.buf.code_action({
				apply = true,
				context = {
					only = { action },
					diagnostics = {},
				},
			})
		end

		local function setup(name, config)
			local success, package = pcall(registry.get_package, name)
			if success and not package:is_installed() then
				package:install()
			end

			local nvim_lsp = require("mason-lspconfig").get_mappings().package_to_lspconfig[name]
			config.capabilities = require("blink.cmp").get_lsp_capabilities()
			local server_on_attach = config.on_attach
			config.on_attach = function(client, bufnr)
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false

				if
					client.name == "pyright"
					and vim.lsp.inlay_hint
					and client.supports_method
					and client:supports_method("textDocument/inlayHint")
				then
					vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
				end

				if client.name == "ruff" then
					client.server_capabilities.hoverProvider = false

					vim.api.nvim_buf_create_user_command(bufnr, "LspRuffFixAll", function()
						apply_code_action("source.fixAll.ruff")
					end, {
						desc = "Fix all auto-fixable Ruff violations",
					})
					vim.api.nvim_buf_create_user_command(bufnr, "LspRuffOrganizeImports", function()
						apply_code_action("source.organizeImports.ruff")
					end, {
						desc = "Organize imports with Ruff",
					})
					vim.keymap.set("n", "<leader>lx", "<cmd>LspRuffFixAll<CR>", {
						buffer = bufnr,
						desc = "Ruff fix all",
					})
					vim.keymap.set("n", "<leader>lI", "<cmd>LspRuffOrganizeImports<CR>", {
						buffer = bufnr,
						desc = "Ruff organize imports",
					})
				end

				if server_on_attach then
					server_on_attach(client, bufnr)
				end
			end
			vim.lsp.config(nvim_lsp, config)
			vim.lsp.enable(nvim_lsp)
		end
		setup("lua-language-server", {
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
				},
			},
		})
		setup("pyright", {
			settings = {
				pyright = {
					disableOrganizeImports = true,
					disableTaggedHints = true,
				},
				python = {
					analysis = {
						typeCheckingMode = "standard",
						autoSearchPaths = true,
						diagnosticMode = "openFilesOnly",
						autoImportCompletions = true,
						useLibraryCodeForTypes = true,
						diagnosticSeverityOverrides = {
							reportMissingModuleSource = "none",
							reportMissingParameterType = "none",
							reportMissingTypeArgument = "none",
							reportMissingTypeStubs = "none",
							reportPrivateImportUsage = "none",
							reportUnknownArgumentType = "none",
							reportUnknownLambdaType = "none",
							reportUnknownMemberType = "none",
							reportUnknownParameterType = "none",
							reportUnknownVariableType = "none",
						},
					},
				},
			},
		})
		setup("ruff", {})
		setup("clangd", {
			cmd = {
				"clangd",
				"--query-driver=**",
			},
			filetypes = { "c", "cpp", "objc", "objcpp" },
		})
		vim.diagnostic.config({
			virtual_text = true,
			update_in_insert = true,
		})
	end,
}
