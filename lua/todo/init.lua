local config = require("todo.config")
local store = require("todo.store")
local hl = require("todo.ui.hl")
local util = require("todo.util")

local M = {}

M.cfg = nil
M.state = nil
M._buf = nil
M._win = nil

M.actions = {}

function M.setup(opts)
  M.cfg = config.merge(opts)
  store.setup(M.cfg.file)
  hl.setup(M.cfg.categories)
  vim.api.nvim_create_user_command("Todo", function() M.toggle() end, {})
  vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
      if M._win and vim.api.nvim_win_is_valid(M._win) then
        M.close()
        M.open()
      end
    end,
  })
end

local function ensure_buf()
  if M._buf and vim.api.nvim_buf_is_valid(M._buf) then return end
  M._buf = vim.api.nvim_create_buf(false, true)
  vim.bo[M._buf].bufhidden = "hide"
  vim.bo[M._buf].filetype = "todocal"
end

function M.open()
  if M._win and vim.api.nvim_win_is_valid(M._win) then return end
  store.load()
  if not M.state then
    local today = util.today()
    M.state = {
      view = "month",
      month_cursor = today,
      week_base = today,
      week_sel = { col = util.weekday(today), row = 1 },
    }
  end
  ensure_buf()
  local w = math.floor(vim.o.columns * M.cfg.win.width)
  local h = math.floor(vim.o.lines * M.cfg.win.height)
  M._win = vim.api.nvim_open_win(M._buf, true, {
    relative = "editor",
    width = w,
    height = h,
    row = math.floor((vim.o.lines - h) / 2),
    col = math.floor((vim.o.columns - w) / 2),
    style = "minimal",
    border = "rounded",
    title = " TODO ",
    title_pos = "center",
    zindex = 40,
  })
  vim.wo[M._win].wrap = false
  M.refresh()
end

function M.close()
  if M._win and vim.api.nvim_win_is_valid(M._win) then
    vim.api.nvim_win_close(M._win, true)
  end
  M._win = nil
end

function M.toggle()
  if M._win and vim.api.nvim_win_is_valid(M._win) then
    M.close()
  else
    M.open()
  end
end

function M.refresh()
  if not (M._win and vim.api.nvim_win_is_valid(M._win)) then return end
  local view = require("todo.ui." .. M.state.view)
  view.attach({
    buf = M._buf,
    win = M._win,
    cfg = M.cfg,
    state = M.state,
    refresh = M.refresh,
    actions = M.actions,
  })
end

-- 保存结果统一处理（含外部修改冲突）
local function persist(ok, err)
  if ok then
    M.refresh()
    return
  end
  if err == "conflict" then
    vim.ui.select({ "覆盖", "放弃并重载" }, { prompt = "todo 文件已被外部修改：" }, function(choice)
      if choice == "覆盖" then
        store.save(true)
      else
        store.load()
      end
      M.refresh()
    end)
  else
    vim.notify("todo 保存失败: " .. tostring(err), vim.log.levels.ERROR)
  end
end

-- 某天有多个任务时让用户选择
local function pick_task(date, cb)
  local tasks = store.by_date(date)
  if #tasks == 0 then
    vim.notify("该日期没有任务", vim.log.levels.INFO)
    return
  end
  if #tasks == 1 then
    cb(tasks[1])
    return
  end
  vim.ui.select(tasks, {
    prompt = "选择任务：",
    format_item = function(t) return t.title end,
  }, function(t)
    if t then cb(t) end
  end)
end

local function new_task(date)
  return {
    title = "",
    date = date,
    category = M.cfg.default_category,
    priority = "medium",
    done = false,
    notes = "",
  }
end

function M.actions.add(date)
  require("todo.ui.form").open(new_task(date), M.cfg, function(t)
    persist(store.add(t))
  end)
end

function M.actions.edit_task(t)
  require("todo.ui.form").open(vim.deepcopy(t), M.cfg, function(nt)
    persist(store.update(t.id, nt))
  end)
end

function M.actions.edit(date)
  pick_task(date, function(t) M.actions.edit_task(t) end)
end

function M.actions.toggle_task(t)
  persist(store.toggle(t.id))
end

function M.actions.toggle(date)
  pick_task(date, function(t) M.actions.toggle_task(t) end)
end

function M.actions.remove_task(t)
  vim.ui.select({ "否", "是" }, { prompt = "删除任务「" .. t.title .. "」？" }, function(c)
    if c == "是" then persist(store.remove(t.id)) end
  end)
end

function M.actions.remove(date)
  pick_task(date, function(t) M.actions.remove_task(t) end)
end

function M.actions.move_task(t)
  vim.ui.input({ prompt = "移动到日期（YYYY-MM-DD）：", default = t.date }, function(input)
    if not input then return end
    input = vim.trim(input)
    if not util.is_valid_date(input) then
      vim.notify("非法日期: " .. input, vim.log.levels.ERROR)
      return
    end
    persist(store.move(t.id, input))
  end)
end

function M.actions.move(date)
  pick_task(date, function(t) M.actions.move_task(t) end)
end

function M.actions.shift_month(n)
  local y, m, d = util.split_date(M.state.month_cursor)
  y, m = util.add_months(y, m, n)
  d = math.min(d, util.days_in_month(y, m))
  M.state.month_cursor = util.make_date(y, m, d)
  M.refresh()
end

function M.actions.shift_week(n)
  M.state.week_base = util.add_days(M.state.week_base, 7 * n)
  M.refresh()
end

function M.actions.show_week(date)
  M.state.view = "week"
  M.state.week_base = date
  M.state.week_sel = { col = util.weekday(date), row = 1 }
  M.refresh()
end

function M.actions.show_month(date)
  M.state.view = "month"
  M.state.month_cursor = date
  M.refresh()
end

function M.actions.close()
  M.close()
end

return M
