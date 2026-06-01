return {
	"MeanderingProgrammer/render-markdown.nvim",
	opts = {
		file_types = { "markdown", "copilot-chat" },
		latex = { enabled = false },
		yaml = { enabled = false },
		heading = {
			foregrounds = {
				"SunsetBoulevardH1",
				"SunsetBoulevardH2",
				"SunsetBoulevardH3",
				"SunsetBoulevardH4",
				"SunsetBoulevardH5",
				"SunsetBoulevardH6",
			},
			backgrounds = {
				"SunsetBoulevardH1Bg",
				"SunsetBoulevardH2Bg",
				"SunsetBoulevardH3Bg",
				"SunsetBoulevardH4Bg",
				"SunsetBoulevardH5Bg",
				"SunsetBoulevardH6Bg",
			},
		},
		code = {
			highlight = "SunsetBoulevardCode",
			highlight_inline = "SunsetBoulevardCodeInline",
			highlight_border = "SunsetBoulevardCodeBorder",
			highlight_info = "SunsetBoulevardCodeInfo",
			highlight_fallback = "SunsetBoulevardCodeFallback",
		},
		quote = { highlight = "SunsetBoulevardQuote" },
		dash = { highlight = "SunsetBoulevardDash" },
		bullet = { highlight = "SunsetBoulevardBullet" },
		checkbox = {
			unchecked = { highlight = "SunsetBoulevardUnchecked" },
			checked = { highlight = "SunsetBoulevardChecked" },
		},
		link = { highlight = "SunsetBoulevardLink" },
	},
	config = function(_, opts)
		-- Sunset Boulevard: #e76f51 → #f4a261 → #e9c46a → #264653
		local pal = {
			bo = "#e76f51",
			co = "#f4a261",
			ws = "#e9c46a",
			dp = "#264653",
		}
		local set = function(name, attrs)
			vim.api.nvim_set_hl(0, name, attrs)
		end

		set("SunsetBoulevardH1", { fg = pal.ws, bold = true })
		set("SunsetBoulevardH2", { fg = "#edb458", bold = true })
		set("SunsetBoulevardH3", { fg = pal.co, bold = true })
		set("SunsetBoulevardH4", { fg = "#ed8656" })
		set("SunsetBoulevardH5", { fg = pal.bo })
		set("SunsetBoulevardH6", { fg = "#cc6449" })

		set("SunsetBoulevardH1Bg", { bg = "#1a303b" })
		set("SunsetBoulevardH2Bg", { bg = "#1f3743" })
		set("SunsetBoulevardH3Bg", { bg = "#233e4c" })
		set("SunsetBoulevardH4Bg", { bg = pal.dp })
		set("SunsetBoulevardH5Bg", { bg = "#2b4d5a" })
		set("SunsetBoulevardH6Bg", { bg = "#2f5462" })

		set("SunsetBoulevardCode", { bg = "#1f2f38" })
		set("SunsetBoulevardCodeInline", { bg = "#2a3e48", fg = pal.co })
		set("SunsetBoulevardCodeBorder", { fg = pal.bo })
		set("SunsetBoulevardCodeInfo", { fg = pal.ws })
		set("SunsetBoulevardCodeFallback", { fg = pal.co })

		set("SunsetBoulevardQuote", { fg = pal.ws, bg = "#233540" })

		set("SunsetBoulevardDash", { fg = pal.bo })

		set("SunsetBoulevardBullet", { fg = pal.co })

		set("SunsetBoulevardLink", { fg = pal.ws })

		set("SunsetBoulevardChecked", { fg = "#d4a44a" })
		set("SunsetBoulevardUnchecked", { fg = "#4a6b7a" })

		require("render-markdown").setup(opts)
	end,
}
