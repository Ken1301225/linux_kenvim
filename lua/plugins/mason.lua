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

		local function setup(name, config)
			local success, package = pcall(registry.get_package, name)
			if success and not package:is_installed() then
				package:install()
			end

			local nvim_lsp = require("mason-lspconfig").get_mappings().package_to_lspconfig[name]
			config.capabilities = require("blink.cmp").get_lsp_capabilities()
			config.on_attach = function(client)
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
			end
			vim.lsp.enable(nvim_lsp)
			vim.lsp.config(nvim_lsp, config)
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
				python = {
					analysis = {
						typeCheckingMode = "basic", -- 可选: off, basic, strict
						autoImportCompletions = true,
						useLibraryCodeForTypes = true,
					},
				},
			},
		})
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
