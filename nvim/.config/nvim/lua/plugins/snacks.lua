-- LSP Progress Autocmd
-- Este autocmd muestra el progreso del LSP en las notificaciones.
-- Ha sido adaptado para funcionar correctamente con Snacks.nvim.
vim.api.nvim_create_autocmd("LspProgress", {
  ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
  callback = function(ev)
    local title = "LSP Progress"
    local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

    local is_end = ev.data.params.value.kind == "end"
    local icon = is_end and " " or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]

    local msg = ev.data.params.value.title
    if ev.data.params.value.message then
      msg = msg .. ": " .. ev.data.params.value.message
    end

    if is_end then
      vim.notify(msg, "info", { title = title, icon = icon, timeout = 3000 })
    else
      vim.notify(msg, "info", {
        id = "lsp_progress",
        title = title,
        icon = icon,
        timeout = 0, -- Set to 0 to keep the notification visible until a new one replaces it
      })
    end
  end,
})

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  keys = {
    -- Top Pickers & Explorer
    {
      "<leader><space>",
      function()
        require("snacks").picker.smart()
      end,
      desc = "Smart Find Files",
    },
    {
      "<leader>.",
      function()
        require("snacks").picker.smart()
      end,
      desc = "Smart Find Files",
    },
    {
      "<leader>,",
      function()
        require("snacks").picker.buffers()
      end,
      desc = "Buffers",
    },
    {
      "<leader>/",
      function()
        require("snacks").picker.grep()
      end,
      desc = "Grep",
    },
    {
      "<leader>:",
      function()
        require("snacks").picker.command_history()
      end,
      desc = "Command History",
    },
    {
      "<leader>n",
      function()
        require("snacks").picker.notifications()
      end,
      desc = "Notification History",
    },
    {
      "<leader>e",
      function()
        require("snacks").explorer()
      end,
      desc = "File Explorer",
    },
    -- buffers
    {
      "<leader>bK",
      function(opts)
        require("snacks").bufdelete.all(opts)
      end,
      desc = "Kill all buffers",
    },
    {
      "<leader>bO",
      function(opts)
        require("snacks").bufdelete.other(opts)
      end,
      desc = "Kill other buffers",
    },
    {
      "<leader>bd",
      function()
        require("snacks").bufdelete()
      end,
      desc = "Kill buffer",
    },
    {
      "<leader>bk",
      function()
        require("snacks").bufdelete()
      end,
      desc = "Kill buffer",
    },
    -- find
    {
      "<leader>fb",
      function()
        require("snacks").picker.buffers()
      end,
      desc = "Buffers",
    },
    {
      "<leader>fc",
      function()
        require("snacks").picker.files({ cwd = vim.fn.stdpath("config") })
      end,
      desc = "Find Config File",
    },
    {
      "<leader>ff",
      function()
        require("snacks").picker.files()
      end,
      desc = "Find Files",
    },
    {
      "<leader>fg",
      function()
        require("snacks").picker.git_files()
      end,
      desc = "Find Git Files",
    },
    {
      "<leader>fp",
      function()
        require("snacks").picker.projects()
      end,
      desc = "Projects",
    },
    {
      "<leader>fr",
      function()
        require("snacks").picker.recent()
      end,
      desc = "Recent",
    },
    -- git
    {
      "<leader>gb",
      function()
        require("snacks").picker.git_branches()
      end,
      desc = "Git Branches",
    },
    {
      "<leader>gl",
      function()
        require("snacks").picker.git_log()
      end,
      desc = "Git Log",
    },
    {
      "<leader>gL",
      function()
        require("snacks").picker.git_log_line()
      end,
      desc = "Git Log Line",
    },
    {
      "<leader>gs",
      function()
        require("snacks").picker.git_status()
      end,
      desc = "Git Status",
    },
    {
      "<leader>gS",
      function()
        require("snacks").picker.git_stash()
      end,
      desc = "Git Stash",
    },
    {
      "<leader>gd",
      function()
        require("snacks").picker.git_diff()
      end,
      desc = "Git Diff (Hunks)",
    },
    {
      "<leader>gf",
      function()
        require("snacks").picker.git_log_file()
      end,
      desc = "Git Log File",
    },
    -- Grep
    {
      "<leader>sb",
      function()
        require("snacks").picker.lines()
      end,
      desc = "Buffer Lines",
    },
    {
      "<leader>sB",
      function()
        require("snacks").picker.grep_buffers()
      end,
      desc = "Grep Open Buffers",
    },
    {
      "<leader>sg",
      function()
        require("snacks").picker.grep()
      end,
      desc = "Grep",
    },
    {
      "<leader>sw",
      function()
        require("snacks").picker.grep_word()
      end,
      mode = { "n", "x" },
      desc = "Visual selection or word",
    },
    -- search
    {
      '<leader>s"',
      function()
        require("snacks").picker.registers()
      end,
      desc = "Registers",
    },
    {
      "<leader>s/",
      function()
        require("snacks").picker.search_history()
      end,
      desc = "Search History",
    },
    {
      "<leader>sa",
      function()
        require("snacks").picker.autocmds()
      end,
      desc = "Autocmds",
    },
    {
      "<leader>sb",
      function()
        require("snacks").picker.lines()
      end,
      desc = "Buffer Lines",
    },
    {
      "<leader>sc",
      function()
        require("snacks").picker.command_history()
      end,
      desc = "Command History",
    },
    {
      "<leader>sC",
      function()
        require("snacks").picker.commands()
      end,
      desc = "Commands",
    },
    {
      "<leader>sd",
      function()
        require("snacks").picker.diagnostics()
      end,
      desc = "Diagnostics",
    },
    {
      "<leader>sD",
      function()
        require("snacks").picker.diagnostics_buffer()
      end,
      desc = "Buffer Diagnostics",
    },
    {
      "<leader>sh",
      function()
        require("snacks").picker.help()
      end,
      desc = "Help Pages",
    },
    {
      "<leader>sH",
      function()
        require("snacks").picker.highlights()
      end,
      desc = "Highlights",
    },
    {
      "<leader>si",
      function()
        require("snacks").picker.icons()
      end,
      desc = "Icons",
    },
    {
      "<leader>sj",
      function()
        require("snacks").picker.jumps()
      end,
      desc = "Jumps",
    },
    {
      "<leader>sk",
      function()
        require("snacks").picker.keymaps()
      end,
      desc = "Keymaps",
    },
    {
      "<leader>sl",
      function()
        require("snacks").picker.loclist()
      end,
      desc = "Location List",
    },
    {
      "<leader>sm",
      function()
        require("snacks").picker.marks()
      end,
      desc = "Marks",
    },
    {
      "<leader>sM",
      function()
        require("snacks").picker.man()
      end,
      desc = "Man Pages",
    },
    {
      "<leader>sp",
      function()
        require("snacks").picker.lazy()
      end,
      desc = "Search for Plugin Spec",
    },
    {
      "<leader>sq",
      function()
        require("snacks").picker.qflist()
      end,
      desc = "Quickfix List",
    },
    {
      "<leader>sR",
      function()
        require("snacks").picker.resume()
      end,
      desc = "Resume",
    },
    {
      "<leader>su",
      function()
        require("snacks").picker.undo()
      end,
      desc = "Undo History",
    },
    {
      "<leader>uC",
      function()
        require("snacks").picker.colorschemes()
      end,
      desc = "Colorschemes",
    },
    -- LSP
    {
      "gd",
      function()
        require("snacks").picker.lsp_definitions()
      end,
      desc = "Goto Definition",
    },
    {
      "gD",
      function()
        require("snacks").picker.lsp_declarations()
      end,
      desc = "Goto Declaration",
    },
    {
      "gr",
      function()
        require("snacks").picker.lsp_references()
      end,
      nowait = true,
      desc = "References",
    },
    {
      "gi",
      function()
        require("snacks").picker.lsp_implementations()
      end,
      desc = "Goto Implementation",
    },
    {
      "gf",
      function()
        require("snacks").picker.lsp_implementations()
      end,
      desc = "Goto Implementation",
    },
    {
      "gy",
      function()
        require("snacks").picker.lsp_type_definitions()
      end,
      desc = "Goto T[y]pe Definition",
    },
    {
      "<leader>ss",
      function()
        require("snacks").picker.lsp_symbols()
      end,
      desc = "LSP Symbols",
    },
    {
      "<leader>sS",
      function()
        require("snacks").picker.lsp_workspace_symbols()
      end,
      desc = "LSP Workspace Symbols",
    },
    { "K", "<cmd>Lspsaga hover_doc<CR>", desc = "Hover Documentation" },
    { "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", desc = "Code Action" },
    { "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", desc = "Rename" },
    { "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", desc = "Previous Diagnostic" },
    { "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", desc = "Next Diagnostic" },
    { "<leader>d", "<cmd>Lspsaga show_cursor_diagnostics<CR>", desc = "Show Line Diagnostics" },
    { "<leader>o", "<cmd>Lspsaga outline<CR>" },
  },
  opts = {
    bigfile = { enabled = true },
    dashboard = {
      enabled = true,
      sections = {
        { section = "header" },
        { section = "startup" },
        { section = "keys", gap = 1, padding = 1 },
        {
          pane = 2,
          section = "terminal",
          cmd = "pokemon-colorscripts -rn 'vaporeon,rayquaza,darkrai,lucario,gardevoir,lopunny,garchomp,blaziken,charmander,totodile,metagross' --no-title; sleep 0.3",
          height = 19,
          padding = 1,
        },
        {
          pane = 2,
          icon = " ",
          desc = "Browse Repo",
          padding = 1,
          key = "b",
          action = function()
            require("snacks").gitbrowse()
          end,
        },
        function()
          local in_git = require("snacks").git.get_root() ~= nil
          local cmds = {
            {
              title = "Notifications",
              cmd = "gh notify -s -a -n5",
              action = function()
                vim.ui.open("https://github.com/notifications")
              end,
              key = "n",
              icon = " ",
              height = 2,
              enabled = true,
            },
            {
              title = "Open Issues",
              cmd = "gh issue list -L 3",
              key = "i",
              action = function()
                vim.fn.jobstart("gh issue list --web", { detach = true })
              end,
              icon = " ",
              height = 2,
            },
            {
              icon = " ",
              title = "Open PRs",
              cmd = "gh pr list -L 3",
              key = "P",
              action = function()
                vim.fn.jobstart("gh pr list --web", { detach = true })
              end,
              height = 2,
            },
            {
              icon = " ",
              title = "Git Status",
              cmd = "git --no-pager diff --stat -B -M -C",
              height = 1,
            },
          }
          return vim.tbl_map(function(cmd)
            return vim.tbl_extend("force", {
              pane = 2,
              section = "terminal",
              enabled = in_git,
              padding = 1,
              ttl = 5 * 60,
              indent = 3,
            }, cmd)
          end, cmds)
        end,
      },
    },
    explorer = { replace_netrw = true },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = true },
    picker = {},
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = {},
    statuscolumn = { enabled = true },
    toggle = {
      map = vim.keymap.set,
      which_key = true,
      notify = true,
      icon = { enabled = " ", disabled = " " },
      color = { enabled = "green", disabled = "yellow" },
      wk_desc = { enabled = "Disable ", disabled = "Enable " },
    },
    words = { enabled = false },
  },
}
