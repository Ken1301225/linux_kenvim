return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	opts = {},
	config = function(_, opts)
		local npairs = require("nvim-autopairs")
		local Rule = require("nvim-autopairs.rule")
		local latex_filetypes = { "tex", "plaintex", "latex" }

		npairs.setup(opts)

		npairs.add_rule(Rule("{", "}", { "tex", "plaintex", "latex" }):with_pair(function(pair_opts)
			return pair_opts.next_char:match("%w") ~= nil or pair_opts.next_char == "\\"
		end))
		npairs.add_rule(Rule("_", "{}", latex_filetypes):set_end_pair_length(1))
		npairs.add_rule(Rule("^", "{}", latex_filetypes):set_end_pair_length(1))
	end,
}
