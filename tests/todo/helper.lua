local M = { failed = 0, passed = 0 }

local function ser(v)
  if type(v) ~= "table" then return tostring(v) end
  local parts = {}
  for k, val in pairs(v) do
    parts[#parts + 1] = tostring(k) .. "=" .. tostring(val)
  end
  table.sort(parts)
  return "{" .. table.concat(parts, ", ") .. "}"
end

local function deep_eq(a, b)
  if type(a) ~= type(b) then return false end
  if type(a) ~= "table" then return a == b end
  for k, v in pairs(a) do if not deep_eq(v, b[k]) then return false end end
  for k, v in pairs(b) do if not deep_eq(v, a[k]) then return false end end
  return true
end

function M.eq(actual, expected, label)
  if deep_eq(actual, expected) then
    M.passed = M.passed + 1
  else
    M.failed = M.failed + 1
    print("FAIL: " .. (label or ""))
    print("  expected: " .. ser(expected))
    print("  actual:   " .. ser(actual))
  end
end

function M.finish(name)
  print(string.format("%s: %d passed, %d failed", name, M.passed, M.failed))
  os.exit(M.failed > 0 and 1 or 0)
end

return M
