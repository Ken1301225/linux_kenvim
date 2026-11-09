return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	opts = {},
	config = function(_, opts)
		local npairs = require("nvim-autopairs")
		local Rule = require("nvim-autopairs.rule")
		local latex_filetypes = { "tex", "plaintex", "latex" }
		local function in_math(pair_opts)
			local before = pair_opts.line:sub(1, pair_opts.col - 1)
			local escapes = before:match("\\+$") or ""
			if #escapes % 2 == 1 then return false end
			local ok, mathzone = pcall(vim.fn["vimtex#syntax#in_mathzone"])
			if not ok or mathzone ~= 1 then return false end
			for _, group in ipairs(vim.fn["vimtex#syntax#stack"]()) do
				if group:match("^texComment") or group:match("^texFiles?Arg") then
					return false
				end
			end
			local command = vim.fn["vimtex#cmd#get_current"]()
			if vim.tbl_contains({ "\\includegraphics", "\\input", "\\include", "\\url", "\\path" }, command.name) then
				return false
			end
			return true
		end

		npairs.setup(opts)

		npairs.add_rule(Rule("{", "}", { "tex", "plaintex", "latex" }):with_pair(function(pair_opts)
			return pair_opts.next_char:match("%w") ~= nil or pair_opts.next_char == "\\"
		end))
		npairs.add_rule(Rule("_", "{}", latex_filetypes):with_pair(in_math):set_end_pair_length(1))
		npairs.add_rule(Rule("^", "{}", latex_filetypes):with_pair(in_math):set_end_pair_length(1))
	end,
}
