local map = vim.keymap.set

-- Clear search highlight with <esc>
map("n", "<esc>", "<cmd>nohlsearch<cr>", { silent = true })

-- Move by display line (wrapped) instead of actual line
map({ "n", "x" }, "j", "gj")
map({ "n", "x" }, "k", "gk")
map({ "n", "x" }, "gj", "j")
map({ "n", "x" }, "gk", "k")

-- Save file
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })

-- Toggle word wrap
map("n", "<A-W>", "<cmd>set wrap!<cr>", { desc = "Toggle word wrap" })

-- Session (persistence.nvim)
map("n", "<leader>ls", function()
  require("persistence").save()
end, { desc = "Save session" })
map("n", "<leader>ll", function()
  require("persistence").load({ last = true })
end, { desc = "Load last session" })

-- Clipboard
map("n", "<leader>c", '"*yy', { desc = "Yank line to selection clipboard" })
map("n", "<leader>v", '"+p', { desc = "Paste from system clipboard" })

-- Pane
map("n", "<leader>=", "<c-w>5>")
map("n", "<leader>-", "<c-w>5<")
map("n", "<leader>+", "<c-w>5+")
map("n", "<leader>_", "<c-w>5-")
map("n", "<tab>", "<c-w>w")
map("n", "<s-tab>", "<c-w>W")

-- Tabs
for i = 1, 9 do
  map("n", "<leader>" .. i, i .. "gt")
end
map("n", "<leader>0", "<cmd>tabonly<cr>", { desc = "Close other tabs" })
map("n", "<leader>t", "gt")
map("n", "<leader>T", "gT")

-- Terminal
map("t", "jk", [[<c-\><c-n>]])
map("t", "<esc>", [[<c-\><c-n>]])
map("n", "<leader>`", "<cmd>sp | term<cr>")
map("t", "<leader>``", [[<c-\><c-n>:vs | term<cr>]])

-- File explorer (nvim-tree)
map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>")

-- Fuzzy finder (telescope)
local function project_files()
  local in_git = vim.fn.systemlist("git rev-parse --is-inside-work-tree")[1] == "true"
  if in_git then
    require("telescope.builtin").git_files({ show_untracked = true })
  else
    require("telescope.builtin").find_files()
  end
end
map("n", "<leader>p", project_files)
map("n", "<leader>P", function()
  require("telescope.builtin").find_files()
end)
map("n", "<leader>fs", function()
  require("telescope.builtin").live_grep()
end)

-- Insert Mode Navigation
map("i", "<c-h>", "<left>")
map("i", "<c-j>", "<down>")
map("i", "<c-k>", "<up>")
map("i", "<c-l>", "<right>")

-- Exit insert mode with jk
map("i", "jk", "<esc>")

-- Move lines
map("n", "<a-j>", ":m .+1<cr>==")
map("n", "<a-k>", ":m .-2<cr>==")
map("i", "<a-j>", "<esc>:m .+1<cr>==gi")
map("i", "<a-k>", "<esc>:m .-2<cr>==gi")
map("v", "<a-j>", ":m '>+1<cr>gv=gv")
map("v", "<a-k>", ":m '<-2<cr>gv=gv")
-- -- MacOs - <opt-j>/<opt-k>
map("n", "\226\136\134", ":m .+1<cr>==")
map("n", "\203\154", ":m .-2<cr>==")
map("i", "\226\136\134", "<esc>:m .+1<cr>==gi")
map("i", "\203\154", "<esc>:m .-2<cr>==gi")
map("v", "\226\136\134", ":m '>+1<cr>gv=gv")
map("v", "\203\154", ":m '<-2<cr>gv=gv")

-- Add blank lines
map("n", "<leader>o", "o<cr><up>")
map("n", "<leader>O", "O<cr><up>")

-- Add comma to the end of current line and add blank line
map("n", ",,", "A,<esc>o")
map("i", ",,", "<esc>A,<esc>o", { nowait = true })

-- Comment line/selection (Comment.nvim)
local comment_api = require("Comment.api")
map("n", "<c-_>", comment_api.toggle.linewise.current)
map("i", "<c-_>", function()
  comment_api.toggle.linewise.current()
end)
map("v", "<c-_>", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "nx", false)
  comment_api.toggle.linewise(vim.fn.visualmode())
end)
