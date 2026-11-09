return {
	"lervag/vimtex",
	lazy = false,
	-- tag = "v2.15",
	init = function()
		-- Viewer: zathura
		vim.g.vimtex_view_method = "zathura"
		vim.g.vimtex_quickfix_mode = 2
		vim.g.vimtex_quickfix_open_on_warning = 0

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
		-- Dynamically set zathura window size to 3/8 screen width x full height
		local geometry_requested = false
		local function write_zathura_geometry(w, h)
			local zathurarc = vim.fn.expand("~/.config/zathura/zathurarc")
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

		local function update_zathura_geometry()
			if geometry_requested then return end
			geometry_requested = true
			if vim.fn.executable("powershell.exe") == 0 then
				write_zathura_geometry(1440, 900)
				return
			end
			vim.system({
				"powershell.exe", "-NoProfile", "-NonInteractive", "-Command",
				"Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Screen]::PrimaryScreen.Bounds | Select-Object Width,Height | ConvertTo-Json -Compress",
			}, { text = true, timeout = 5000 }, vim.schedule_wrap(function(result)
				local ok, bounds = pcall(vim.json.decode, result.stdout or "")
				if result.code == 0 and ok and type(bounds) == "table"
					and type(bounds.Width) == "number" and type(bounds.Height) == "number"
					and bounds.Width > 0 and bounds.Height > 0 then
					write_zathura_geometry(bounds.Width, bounds.Height)
				else
					write_zathura_geometry(1440, 900)
				end
			end))
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
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("VimTeX_Lint", { clear = true }),
			pattern = { "tex", "plaintex" },
			callback = function(args)
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
				end, { buffer = args.buf, desc = "VimTeX chktex lint" })
			end,
		})
	end,
}
