vim.g.mapleader = " "

local keymap = vim.keymap

keymap.set("i", "jj", "<ESC>")
keymap.set("n", "<ESC>", ":noh<CR>")
vim.keymap.set("v", "<A-S-f>", vim.lsp.buf.format)

local keymap = vim.keymap

-- Mapear Ctrl+T para abrir una nueva pestaña con buffer vacío
keymap.set("n", "<C-t>", ":tabnew<CR>", { noremap = true, silent = true })

-- Cambiar a pestaña anterior con [b
keymap.set("n", "<C-[>", ":tabprevious<CR>", { noremap = true, silent = true })

-- Cambiar a pestaña siguiente con ]b
keymap.set("n", "<C-]>", ":tabnext<CR>", { noremap = true, silent = true })

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

-- # MUCHOS DE ESTOS COMANDOS EQUIVALEN A:
--  [ + b > cambiar pestaña prev {osea tabear}
--  ] + b > cambiar pestaña next {osea tabear}
--  space + b + b = la unica forma de ctrl tab

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
