return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	opts = {},
	config = function(_, opts)
		local npairs = require("nvim-autopairs")
		local Rule = require("nvim-autopairs.rule")
		local latex_filetypes = { "tex", "plaintex", "latex" }

		local function in_mathzone(line, col)
			if vim.fn.exists("*vimtex#syntax#in_mathzone") == 1 and vim.fn["vimtex#syntax#in_mathzone"]() == 1 then
				return true
			end

			local before = line:sub(1, col)
			local dollar_count = 0
			for i = 1, #before do
				if before:sub(i, i) == "$" and before:sub(i - 1, i - 1) ~= "\\" then
					dollar_count = dollar_count + 1
				end
			end

			return dollar_count % 2 == 1
		end

		local function find_matching_open_brace(text)
			local depth = 0
			for i = #text, 1, -1 do
				local char = text:sub(i, i)
				if char == "}" then
					depth = depth + 1
				elseif char == "{" then
					if depth == 0 then
						return i
					end
					depth = depth - 1
				end
			end
		end

		local function numerator_before_cursor(before)
			if before:sub(-1) == "}" then
				local open_col = find_matching_open_brace(before:sub(1, -2))
				if open_col then
					return before:sub(open_col + 1, -2), #before - open_col + 1
				end
			end

			local command = before:match("\\%a+$")
			if command then
				return command, #command
			end

			local word = before:match("[%w%.]+$")
			if word then
				return word, #word
			end
		end

		local function latex_fraction()
			local row, col = unpack(vim.api.nvim_win_get_cursor(0))
			local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""

			if not in_mathzone(line, col) then
				return "/"
			end

			local numerator, delete_chars = numerator_before_cursor(line:sub(1, col))
			if not numerator or numerator == "" then
				return "/"
			end

			return ("<BS>"):rep(delete_chars) .. "\\frac{" .. numerator .. "}{}<Left>"
		end

		local function setup_latex_mappings()
			if not vim.tbl_contains(latex_filetypes, vim.bo.filetype) then
				return
			end

			vim.keymap.set("i", "/", latex_fraction, {
				buffer = true,
				expr = true,
				replace_keycodes = true,
				desc = "LaTeX fraction from numerator",
			})
		end

		npairs.setup(opts)

		npairs.add_rule(Rule("{", "}", { "tex", "plaintex", "latex" }):with_pair(function(pair_opts)
			return pair_opts.next_char:match("%w") ~= nil or pair_opts.next_char == "\\"
		end))
		npairs.add_rule(Rule("_", "{}", latex_filetypes):set_end_pair_length(1))
		npairs.add_rule(Rule("^", "{}", latex_filetypes):set_end_pair_length(1))

		vim.api.nvim_create_autocmd("FileType", {
			pattern = latex_filetypes,
			callback = setup_latex_mappings,
			desc = "Enable LaTeX autopairs helpers",
		})
		setup_latex_mappings()
	end,
}
