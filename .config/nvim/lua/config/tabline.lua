-- Custom tabline: show each tab's file relative to the cwd (project
-- directory) when the file lives under it, falling back to the full path
-- otherwise. Vim's default tabline always shows just the tail (filename),
-- with no way to configure that modifier, hence the custom renderer.
local M = {}

-- Collapse every directory component to its first letter, keeping the
-- filename itself intact, e.g. "lua/config/options.lua" -> "l/c/options.lua".
local function abbreviate(path)
  local prefix = ""
  if path:sub(1, 1) == "/" then
    prefix = "/"
    path = path:sub(2)
  end

  local parts = {}
  for part in path:gmatch("[^/]+") do
    parts[#parts + 1] = part
  end
  if #parts <= 1 then
    return prefix .. path
  end

  for i = 1, #parts - 1 do
    parts[i] = parts[i]:sub(1, 1)
  end
  return prefix .. table.concat(parts, "/")
end

function M.render()
  local s = ""
  local current_tab = vim.fn.tabpagenr()

  for i = 1, vim.fn.tabpagenr("$") do
    local winnr = vim.fn.tabpagewinnr(i)
    local bufnr = vim.fn.tabpagebuflist(i)[winnr]
    local bufname = vim.fn.bufname(bufnr)
    -- ':.' yields a cwd-relative path when the file is under the cwd,
    -- and leaves it unmodified (full path) otherwise.
    local label = bufname == "" and "[No Name]" or abbreviate(vim.fn.fnamemodify(bufname, ":."))
    local modified = vim.fn.getbufvar(bufnr, "&modified") == 1 and " [+]" or ""

    s = s .. "%" .. i .. "T"
    s = s .. (i == current_tab and "%#TabLineSel#" or "%#TabLine#")
    s = s .. " " .. label .. modified .. " "
  end

  s = s .. "%#TabLineFill#"
  return s
end

vim.o.tabline = "%!v:lua.require('config.tabline').render()"

return M
