return {
	"lervag/vimtex",
	lazy = false,
	-- tag = "v2.15",
	init = function()
		-- Viewer: zathura
		vim.g.vimtex_view_method = "zathura"

		-- WSL: inverse search from PDF back to nvim
		if vim.fn.executable("wsl") == 1 then
			vim.g.vimtex_callback_progpath = "wsl nvim"
		end

		-- Compiler: latexmk + xelatex
		vim.g.vimtex_compiler_method = "latexmk"
		vim.g.vimtex_compiler_silent = 1
		vim.g.vimtex_compiler_latexmk = {
			build_dir = "",
			callback = 1,
			executable = "latexmk",
			options = {
				"-xelatex",
				"-file-line-error",
				"-interaction=nonstopmode",
				"-synctex=1",
				"-shell-escape",
			},
		}
	end,
	config = function()
		-- Suppress auto-opening quickfix on compile
		vim.api.nvim_create_autocmd("User", {
			group = vim.api.nvim_create_augroup("VimTeX_NoAutoQF", { clear = true }),
			pattern = { "VimtexEventCompileSuccess", "VimtexEventCompileFailed" },
			callback = function()
				vim.defer_fn(function() pcall(vim.cmd, "cclose") end, 50)
			end,
		})

		-- Dynamically set zathura window size to 3/8 screen width x full height
		local function update_zathura_geometry()
			local zathurarc = vim.fn.expand("~/.config/zathura/zathurarc")
			local w, h = 1440, 900 -- fallback
			if vim.fn.executable("powershell.exe") == 1 then
				local pw = vim.fn.system("powershell.exe -Command \"Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width\"")
				local ph = vim.fn.system("powershell.exe -Command \"Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height\"")
				w = tonumber(pw) or w
				h = tonumber(ph) or h
			end
			local win_w = math.floor(w * 3 / 8)
			local fp = io.open(zathurarc, "r")
			if not fp then return end
			local content = fp:read("*a")
			fp:close()
			content = content:gsub("set window%-width %d+", "set window-width " .. win_w)
			content = content:gsub("set window%-height %d+", "set window-height " .. h)
			local wp = io.open(zathurarc, "w")
			if wp then
				wp:write(content)
				wp:close()
			end
		end

		-- Run on compile success (before first view) and on VimtexView
		vim.api.nvim_create_autocmd("User", {
			group = vim.api.nvim_create_augroup("VimTeX_Geometry", { clear = true }),
			pattern = "VimtexEventCompileSuccess",
			callback = update_zathura_geometry,
		})
		vim.api.nvim_create_autocmd("User", {
			group = "VimTeX_Geometry",
			pattern = "VimtexEventView",
			callback = update_zathura_geometry,
		})

		-- Lint shortcut: ,ln → chktex → location list
		vim.keymap.set("n", "<localleader>ln", function()
			if vim.fn.executable("chktex") == 0 then
				vim.notify("chktex not found", vim.log.levels.WARN)
				return
			end
			pcall(vim.cmd, "compiler chktex")
			vim.cmd("silent! lmake!")
			local count = #vim.fn.getloclist(0)
			if count > 0 then
				vim.cmd("lwindow")
				vim.notify("chktex: " .. count .. " issue(s)", vim.log.levels.WARN)
			else
				vim.notify("chktex: no issues", vim.log.levels.INFO)
			end
		end, { buffer = true, desc = "VimTeX chktex lint" })
	end,
}
