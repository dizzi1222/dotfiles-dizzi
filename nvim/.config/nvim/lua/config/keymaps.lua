-- PARA Configurar IAS, revisa:
-- config/lazy.lua
-- plugins/disabled
-- OBVIAMENTE REVISA LOS KEYMAPS: config/keymaps.lua
--
-- KEYMAPS DE CHAT por IA FUNCIONAN AL SELECCIONAR TEXTO [v]
--
vim.g.mapleader = " "

local keymap = vim.keymap

keymap.set("i", "jj", "<ESC>")
keymap.set("n", "<ESC>", ":noh<CR>")
vim.keymap.set("v", "<A-S-f>", vim.lsp.buf.format)
--💫 PARA OBTENER INFORMACION DE UN BUFFER Y SUS MAPEOS: UTILIZA:[2 puntos] :lua print(vim.inspect(vim.api.nvim_buf_get_keymap(0, "i")))
--
-- 🗣️ ATAJOS DE IA y OIL/snack_picker_list tree EXPLORER QUE DEBES SABER:
-- 🐐 1- ATAJO IMPORTANTE: - {minus -} [oil ~ requiere oil]-
-- te lleva al directorio en el que te encuentras [GOZZZZ]
-- 🐐 1.5 - ATAJO IMPORTANTE: Space E [mayus] \ o usa: Space + Shift + E [Abre oil flotante] ) \ AL SELECCIONAR TEXTO [v]-
-- 🐐 2- ATAJO IMPORTANTE: Space+e [minus] [snack ~ requiere: fd fd-find]
-- 🐐 3- ATAJO IMPORTANTE: Space+N  [notifaciones - como :mes pero mejor para depurar codigo!! ]
-- 🐐 4- ATAJO IMPORTANTE: Space+M ejecutar el markdown render ej Space + M+R
-- 🐐 5- accept Copilot/Tabnine etc = "<Tab>", -- acepta sugerencia
--       dismisss Copilot/Tabnine = "<C-c> o con ESC", -- cancela sugerencia
-- 🐐 6- abrir menu IA panel {claude api} = Space + A -- tambien puedesc crear un new file
-- keymap = {
--   accept = "<C-Tab>", -- acepta sugerencia
--   next = "<C-]>",
--   prev = "<C-[>",
--   dismiss = "<C-",

-- 🗣️ ATAJOS OIL tree EXLORER:
-- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
-- keymaps =
--   {
--     ["g?"] = "actions.show_help",
--     ["<CR>"] = "actions.select",
--     ["<C-s>"] = { "actions.select", opts = { vertical = true }, desc = "Open in vertical split" },
--     ["<C-v>"] = { "actions.select", opts = { horizontal = true }, desc = "Open in horizontal split" },
-- ESTE NO LO RECOMIENDO, lo quite.     -- ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open in new tab" },
--     ["<C-p>"] = "actions.preview",
--     ["<C-c>"] = "actions.close",
--     ["<C-r>"] = "actions.refresh",
--     ["-"] = "actions.parent",
--     ["_"] = "actions.open_cwd",
--     ["`"] = "actions.cd",
--     ["~"] = { "actions.cd", opts = { scope = "tab" }, desc = ":tcd to the current oil directory" },
--     ["gs"] = "actions.change_sort",
--     ["gx"] = "actions.open_external",
--     ["g."] = "actions.toggle_hidden",
--     ["g\\"] = "actions.toggle_trash",
--     -- Quick quit
--     ["q"] = "actions.close",
--   },
-- similar al EXPLORER snack_picker_list

-- Mapear Ctrl+T y Space+A+N para {add new file} abrir una nueva pestaña - lo mismo que space + m + n

-- Crear nuevo archivo desde treesitter - arbol de archivo - lo mismo que Control + Ts
vim.keymap.set("n", "<leader>an", function()
  local dir = vim.fn.expand("%:p:h") -- ruta del buffer actual
  if dir == "" then
    dir = vim.loop.cwd() -- fallback si no hay archivo
  end
  local name = vim.fn.input("Nombre del archivo: ")
  if name ~= "" then
    vim.cmd("tabnew " .. dir .. "/" .. name)
  end
end, { noremap = true, silent = true, desc = "Nuevo archivo [add new file]" })

-- keymap.set("n", "<C-t>", ":tabnew<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-t>", function()
  local dir = vim.fn.expand("%:p:h") -- ruta del buffer actual
  if dir == "" then
    dir = vim.loop.cwd() -- fallback si no hay archivo
  end
  local name = vim.fn.input("Nombre del archivo: ")
  if name ~= "" then
    -- abre un buffer normal en la carpeta actual con el nombre indicado
    vim.cmd("tabnew " .. dir .. "/" .. name)
  end
end, { noremap = true, silent = true })

-- Cambiar a pestaña anterior con [b
keymap.set("n", "<C-[>", ":bprev<CR>", { noremap = true, silent = true })

-- Cambiar a pestaña siguiente con ]b
keymap.set("n", "<C-]>", ":bnext<CR>", { noremap = true, silent = true })

-- Activar backspace+Control - MODO INSERCION COMO EN VSCODE!!! = Ctrl W
vim.api.nvim_set_keymap("i", "<C-BS>", "<C-W>", { noremap = true, silent = true })

-- 🚨📌🗿🔥Mapeo para Ctrl + backspace a Ctrl + W en el modo de línea de comandos (la : )🚨📌🗿🔥
-- Mapeo que usa una función para asegurar que funciona en la línea de comandos
vim.keymap.set("c", "<C-BS>", function()
  -- Cierra cualquier ventana de completado y luego ejecuta el comando Ctrl-W
  -- El comando \b borra una palabra hacia atrás
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-W>", true, true, true), "n", true)
end, { noremap = true, silent = true })

-- ---------------------------------------------------|-
--👹📌🗿🔥Mismo mapeo pero para el modo de inserción en buffers normales👹📌🗿🔥
-- Función mejorada para borrar palabras en buffers de snacks
local function delete_previous_word()
  -- Obtener posición actual
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1], pos[2]
  local line = vim.api.nvim_get_current_line()

  -- Encontrar el inicio de la palabra anterior
  local word_start = col
  while word_start > 0 and line:sub(word_start, word_start):match("%s") do
    word_start = word_start - 1
  end

  while word_start > 0 and not line:sub(word_start, word_start):match("%s") do
    word_start = word_start - 1
  end

  -- Ajustar índices (Lua es 1-indexed, Neovim API es 0-indexed)
  word_start = word_start + 1

  -- Borrar la palabra
  if word_start <= col then
    vim.api.nvim_buf_set_text(0, row - 1, word_start - 1, row - 1, col, { "" })
    vim.api.nvim_win_set_cursor(0, { row, word_start - 1 })
  end
end

-- Aplicar a TODOS los tipos de buffers de snacks
local snack_filetypes = {
  "snacks_picker_input",
  "snacks_picker_list",
  "snacks_picker_recent",
  "snacks_picker_files",
  "snacks_picker_smart",
}

for _, ft in ipairs(snack_filetypes) do
  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    callback = function()
      -- Habilitar modifiable temporalmente
      vim.bo.modifiable = true

      -- Mapear Ctrl+Backspace y Ctrl+H
      vim.keymap.set("i", "<C-BS>", delete_previous_word, {
        buffer = true,
        noremap = true,
        silent = true,
        desc = "Borrar palabra anterior",
      })

      vim.keymap.set("i", "<C-H>", delete_previous_word, {
        buffer = true,
        noremap = true,
        silent = true,
        desc = "Borrar palabra anterior",
      })
    end,
  })
end

--🛑 🗿 Cerrar pestaña

keymap.set("n", "<C-q>", function()
  -- Cierra el buffer actual sin preguntar, forzando el cierre
  -- para cerrar ventanas molestas usa: :q! o :q
  vim.cmd("bdelete!")
end, { noremap = true, silent = true })

-- # MUCHOS DE ESTOS COMANDOS EQUIVALEN A:
--  [ + b > cambiar pestaña prev {osea tabear}
--  ] + b > cambiar pestaña next {osea tabear}
--  space + b + b = la unica forma de ctrl tab
--
--    |
-- 	  ╰─❯ CTrl + [] > cabra a buffer prev!!
--        [lomejor] Ctrl + ] > cambiar a buffer sigueinte [ctrl tab!! en buffer]

-- # y otros que NO MODIFIQUE COMO:
-- Ctrl + V > Grabar Tecla - Util para averiguar la tecla [Record key] {Similar a cat -v}
-- Ctrl + Shif + C > Copiar en Modo Insercion
-- Ctrl + Shif + V > Pegar en Modo Insercion
-- ╰❯ [Ctrl + W > Guia de Window]
-- 	╰─❯ {recomiendo}
-- 	  ╰─❯ Ctrl + W + W > cambiar ventana {osea tabear}
-- 	  ╰─❯  Ctrl + W + J > Cambiar ventana {abajo}
-- 	  ╰─❯  Ctrl + W + H > Cambiar ventana {izquierda,
-- 	  ╰─❯  Ctrl + Space [lo mejor] > Cambiar entre TODAS las ventana [shift tab!!! en ventana],
--
--    |
-- 	  ╰─❯  Ctrl + H [lo mejor] > Cambiar entre ventana [ctrl tab!!! en ventana],

--     Ctrl + W + O > cierra tod@s las ventanas divididas/o Explorer
--   	Ctrl + W + > S > split dividir {mas lento que space}

-- Mapea la tecla 'p' en modo visual para pegar sin copiar lo que reemplazas!!!
vim.keymap.set("v", "p", '"_dP', { noremap = true, silent = true })

-- Cambiar de tema con Telescope colorscheme = Space + C + T                  # ubicado en: ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/colorscheme.lua
-- Cambiar a Pywal color de fondo = Space + P                  # ubicado en: ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/pywal-nvim.lua
-- Cambiar a Pywal color de fondo = Space + P+W                  # ubicado en: ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/pywal-nvim.lua
-- Cambiar a Pywal color de fondo = Soace + C + T escribe Pywal, gruv o el tema que gustes.                  # ubicado en: ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/colorscheme.lua
-- Usar minty para generar colorschemes? idk activa Huefy = Space + M + H                   # ubicado: en ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/minty.luau
-- Usar minty para generar colorschemes? idk activa Shades = Space + M + S                  # ubicado: en ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/minty.luau
-- Usar minty para generar colorschemes? idk = Space + M + H                  # ubicado: en ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/minty.luau

-- CAMBIAR color con Teclado = C+P                  # ubicado en: ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins.lua
-- CAMBIAR color con Mouse + C+V                  # ubicado en: ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/color-picker.lua

-- =============================
-- -- Solo en Arhcivos.MD | MARKDown (Gentleman config) - {no funciona bien}
-- =============================
-- KEYMAPS CORRECTOS:
keymap.set("n", "<leader>mr", function()
  require("render-markdown").toggle()
end, { desc = "Toggle Markdown Render" })

keymap.set("n", "<leader>me", function()
  require("render-markdown").enable()
end, { desc = "Enable Markdown Render" })

keymap.set("n", "<leader>md", function()
  require("render-markdown").disable()
end, { desc = "Disable Markdown Render" })

-- =============================
-- INSERT MODE (Gentleman config)
-- =============================
keymap.set("i", "<C-b>", "<C-o>de") -- Ctrl+b: borrar hasta fin de palabra
keymap.set("i", "<C-c>", [[<C-\><C-n>]]) -- Ctrl+c escape
vim.api.nvim_set_keymap("i", "<A-j>", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<A-k>", "<Nop>", { noremap = true, silent = true })

-- =============================
-- NORMAL MODE (Gentleman config)
-- =============================
keymap.set("n", "<C-s>", ":lua SaveFile()<CR>") -- guardar con función

-- =============================
-- VISUAL MODE (Gentleman config)
-- =============================
keymap.set("v", "<C-c>", [[<C-\><C-n>]]) -- escape
vim.api.nvim_set_keymap("x", "<A-j>", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("x", "<A-k>", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("x", "J", "<Nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("x", "K", "<Nop>", { noremap = true, silent = true })

-- =============================
-- LEADER KEYS (Gentleman config)
-- =============================
keymap.set("n", "<leader>uk", "<cmd>Screenkey<CR>")
keymap.set("n", "<leader>bq", '<Esc>:%bdelete|edit #|normal`"<CR>', { desc = "Delete other buffers" })
keymap.set("n", "<leader>md", function()
  vim.cmd("delmarks!")
  vim.cmd("delmarks A-Z0-9")
  vim.notify("All marks deleted")
end, { desc = "Delete all marks" })

-- =============================
-- TMUX NAVIGATION (Gentleman config)
-- =============================
local nvim_tmux_nav = require("nvim-tmux-navigation")
keymap.set("n", "<C-h>", nvim_tmux_nav.NvimTmuxNavigateLeft)
keymap.set("n", "<C-j>", nvim_tmux_nav.NvimTmuxNavigateDown)
keymap.set("n", "<C-k>", nvim_tmux_nav.NvimTmuxNavigateUp)
keymap.set("n", "<C-l>", nvim_tmux_nav.NvimTmuxNavigateRight)
keymap.set("n", "<C-\\>", nvim_tmux_nav.NvimTmuxNavigateLastActive)
keymap.set("n", "<C-Space>", nvim_tmux_nav.NvimTmuxNavigateNext)

-- =============================
-- OBSIDIAN (Gentleman config)
-- =============================
keymap.set("n", "<leader>oc", "<cmd>ObsidianCheck<CR>")
keymap.set("n", "<leader>ot", "<cmd>ObsidianTemplate<CR>")
keymap.set("n", "<leader>oo", "<cmd>Obsidian Open<CR>")
keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<CR>")
keymap.set("n", "<leader>ol", "<cmd>ObsidianLinks<CR>")
keymap.set("n", "<leader>on", "<cmd>ObsidianNew<CR>")
keymap.set("n", "<leader>os", "<cmd>ObsidianSearch<CR>")
keymap.set("n", "<leader>oq", "<cmd>ObsidianQuickSwitch<CR>")

-- =============================
-- OIL (Gentleman config)
-- =============================
keymap.set("n", "-", "<CMD>Oil<CR>")

-- =============================
-- FUNCIONES (Gentleman config)
-- =============================
function SaveFile()
  if vim.fn.empty(vim.fn.expand("%:t")) == 1 then
    vim.notify("No file to save", vim.log.levels.WARN)
    return
  end
  local filename = vim.fn.expand("%:t")
  local ok, err = pcall(function()
    vim.cmd("silent! write")
  end)
  if ok then
    vim.notify(filename .. " Saved!")
  else
    vim.notify("Error: " .. err, vim.log.levels.ERROR)
  end
end

-- =============================
-- KEYMAPS GENTLEMAN / CLAUDE (SEPARADO) \ AL SELECCIONAR TEXTO [v]
-- =============================
local has_claude, claude = pcall(require, "claude-code")
if has_claude then
  -- Visual: completar selección con Claude
  vim.keymap.set("v", "<leader>ac", function()
    claude.complete_selection()
  end, { desc = "Claude: completar selección" })

  -- Normal: abrir panel de Claude
  vim.keymap.set("n", "<leader>aa", function()
    claude.open_panel()
  end, { desc = "Claude: abrir panel" })

  -- Optional: enviar línea actual a Claude y obtener respuesta
  vim.keymap.set("n", "<leader>al", function()
    claude.complete_line()
  end, { desc = "Claude: completar línea actual" })

  -- Optional: cerrar panel de Claude
  vim.keymap.set("n", "<leader>ax", function()
    claude.close_panel()
  end, { desc = "Claude: cerrar panel" })
end
