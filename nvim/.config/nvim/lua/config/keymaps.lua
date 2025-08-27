vim.g.mapleader = " "

local keymap = vim.keymap

keymap.set("i", "jj", "<ESC>")
keymap.set("n", "<ESC>", ":noh<CR>")
vim.keymap.set("v", "<A-S-f>", vim.lsp.buf.format)

-- Mapear Ctrl+T para abrir una nueva pestaña - lo mismo que space + m + n
-- keymap.set("n", "<C-t>", ":tabnew<CR>", { noremap = true, silent = true })
local keymap = vim.keymap

keymap.set("n", "<C-t>", function()
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

-- Mapeo para Ctrl + backspace a Ctrl + W en el modo de línea de comandos (la : )
-- Mapeo que usa una función para asegurar que funciona en la línea de comandos
vim.keymap.set("c", "<C-BS>", function()
  -- Cierra cualquier ventana de completado y luego ejecuta el comando Ctrl-W
  -- El comando \b borra una palabra hacia atrás
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-W>", true, true, true), "n", true)
end, { noremap = true, silent = true })

-- Cerrar pestaña

keymap.set("n", "<C-q>", function()
  -- Cierra el buffer actual sin preguntar, forzando el cierre
  vim.cmd("bdelete!")
end, { noremap = true, silent = true })

-- Crear nuevo archivo desde treesitter - arbol de archivo - lo mismo que Control + Ts
vim.keymap.set("n", "<leader>an", function()
  -- obtener la carpeta actual del buffer
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then
    dir = vim.loop.cwd()
  end -- fallback si no hay archivo
  -- pedir el nombre del archivo
  local name = vim.fn.input("Nombre del archivo: ")
  if name ~= "" then
    vim.cmd("e " .. dir .. "/" .. name) -- abrir nuevo archivo en esa carpeta
  end
end, { desc = "Nuevo archivo en ruta actual" })

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
-- CAMBAIR color con Mouse + C+V                  # ubicado en: ~/dotfiles-dizzi/nvim/.config/nvim/lua/plugins/color-picker.lua

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
-- KEYMAPS GENTLEMAN / CLAUDE (SEPARADO)
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
