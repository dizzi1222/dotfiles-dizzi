#!/bin/bash

# Colores
CYAN='\e[36m'
GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
BLUE='\e[34m'
MAGENTA='\e[35m'
BOLD='\e[1m'
RESET='\e[0m'

# Función para mostrar la ayuda con formato bonito
show_help() {
  cat <<'EOF'
EOF

  echo -e "\n${CYAN}┌──────────────────────────────────────────────────────────────┐${RESET}"
  echo -e "${CYAN}│${BOLD}           GIT ALIASES - GUÍA COMPLETA 🎯${RESET}${CYAN}                  │${RESET}"
  echo -e "${CYAN}└──────────────────────────────────────────────────────────────┘${RESET}\n"

  echo -e "${MAGENTA}${BOLD}🖥️  WORKFLOW PRINCIPAL:${RESET}"
  echo -e "  ${GREEN}gitflow${RESET}            → Menú interactivo ${YELLOW}TODO-EN-UNO${RESET}"
  echo -e "                       (commit, AI, log, editar plantilla)\n"

  echo -e "${MAGENTA}${BOLD}📦 COMMITS (4 formas diferentes):${RESET}"
  echo -e "  ${GREEN}gitcommit${RESET}          → Abre editor con plantilla predefinida"
  echo -e "                       Plantilla: ${CYAN}~/commit-template.txt${RESET}"
  echo -e "                       Te pregunta si pushear al terminar\n"

  echo -e "  ${GREEN}gitquick${RESET} [texto]   → Commit ${YELLOW}rápido${RESET} sin abrir editor"
  echo -e "                       Sin args: usa plantilla por defecto"
  echo -e "                       Con args: agrega contexto extra"
  echo -e "                       Ejemplo: ${CYAN}gitquick \"actualizar configs\"${RESET}\n"

  echo -e "                       Usa opencommit (oco) con Ollama"
  echo -e "                       Genera mensaje automático"
  echo -e "                       Te pregunta si pushear\n"

  echo -e "  ${GREEN}gitc${RESET} \"mensaje\"     → Commit ${YELLOW}directo + push${RESET} inmediato"
  echo -e "                       Ejemplo: ${CYAN}gitc \"fix: corregir bug\"${RESET}\n"

  echo -e "  ${GREEN}gitconv${RESET}            → Commit estilo ${YELLOW}Conventional Commits${RESET}"
  echo -e "                       Te pregunta: tipo, scope, mensaje"
  echo -e "                       Ejemplo final: ${CYAN}feat(hyprland): agregar keybinds${RESET}\n"

  echo -e "${MAGENTA}${BOLD}🔍 VISUALIZACIÓN:${RESET}"
  echo -e "  ${GREEN}gits${RESET}               → Estado del repo en formato ${YELLOW}compacto${RESET}"
  echo -e "                       Muestra: branch, archivos modificados, untracked\n"

  echo -e "  ${GREEN}gitlog${RESET}             → Historial ${YELLOW}gráfico${RESET} de commits (últimos)"
  echo -e "                       Formato: hash corto + mensaje + branch\n"

  echo -e "  ${GREEN}gitlogfull${RESET}         → Historial detallado con ${YELLOW}COLORES${RESET}"
  echo -e "                       Incluye: autor, fecha relativa, branches\n"

  echo -e "  ${GREEN}gitdiff${RESET}            → Ver ${YELLOW}CAMBIOS sin agregar${RESET} (unstaged)"
  echo -e "                       Archivos modificados vs último commit\n"

  echo -e "  ${GREEN}gitdiffs${RESET}           → Ver ${YELLOW}CAMBIOS ya agregados${RESET} (staged)"
  echo -e "                       Lo que se incluirá en el próximo commit\n"

  echo -e "  ${GREEN}gitshowcom${RESET}         → Navegador interactivo ${YELLOW}TIG${RESET}"
  echo -e "                       Navega commits con flechas, Enter para ver diff\n"

  echo -e "${MAGENTA}${BOLD}⏪ DESHACER CAMBIOS:${RESET}"
  echo -e "  ${GREEN}gitundo${RESET}            → Deshace último commit, ${YELLOW}MANTIENE${RESET} archivos"
  echo -e "                       Útil para: reescribir mensaje o agregar más cambios\n"

  echo -e "  ${GREEN}gitundobard${RESET}        → Deshace último commit, ${RED}BORRA TODO${RESET}"
  echo -e "                       ${RED}⚠️  PELIGROSO:${RESET} no se puede recuperar\n"

  echo -e "  ${GREEN}CommitEditar${RESET}       → Edita el mensaje del último commit"
  echo -e "                       Solo cambia texto, no el contenido\n"

  echo -e "  ${GREEN}CommitsHistorial${RESET}   → Editor interactivo de últimos ${YELLOW}5 commits${RESET}"
  echo -e "                       Opciones: reword, squash, fixup, drop"
  echo -e "                       Útil para: limpiar historial antes de push\n"

  echo -e "  ${GREEN}gitreset${RESET}           → Vuelve al último commit, ${RED}BORRA${RESET} cambios"
  echo -e "                       Descarta TODO (staged + unstaged)\n"

  echo -e "${MAGENTA}${BOLD}🌿 BRANCHES (RAMAS):${RESET}"
  echo -e "  ${GREEN}gitb${RESET}               → Lista ${YELLOW}TODAS${RESET} las ramas (locales + remotas)"
  echo -e "                       Muestra * en la rama actual\n"

  echo -e "  ${GREEN}gitnew${RESET} <nombre>    → Crea rama nueva ${YELLOW}Y cambia${RESET} a ella"
  echo -e "                       Ejemplo: ${CYAN}gitnew feature/nueva-funcion${RESET}\n"

  echo -e "  ${GREEN}gitco${RESET} <rama>       → Cambia a otra rama existente"
  echo -e "                       Ejemplo: ${CYAN}gitco main${RESET}\n"

  echo -e "  ${GREEN}gitmerge${RESET} <rama>    → Une otra rama a la actual"
  echo -e "                       Ejemplo: estando en main → ${CYAN}gitmerge dev${RESET}\n"

  echo -e "${MAGENTA}${BOLD}🚀 PUSH/PULL:${RESET}"
  echo -e "  ${GREEN}git push${RESET}           → Sube cambios al remoto (normal)\n"

  echo -e "  ${GREEN}gitpushforce${RESET}       → Push ${RED}FORZADO${RESET} pero seguro"
  echo -e "                       Usa --force-with-lease (evita sobrescribir trabajo ajeno)\n"

  echo -e "  ${GREEN}gitpull${RESET}            → Descarga cambios con ${YELLOW}rebase${RESET}"
  echo -e "                       Mantiene historial lineal (sin merge commits)\n"

  echo -e "  ${GREEN}gitsync${RESET}            → Sincroniza tu ${YELLOW}fork${RESET} con el original"
  echo -e "                       Requiere: ${CYAN}git remote add upstream <url>${RESET}\n"

  echo -e "${MAGENTA}${BOLD}🧹 LIMPIEZA:${RESET}"
  echo -e "  ${GREEN}gitclean${RESET}           → Elimina ramas locales ${YELLOW}YA MERGEADAS${RESET}"
  echo -e "                       No toca ramas sin mergear (seguro)\n"

  echo -e "  ${GREEN}gitcleanfiles${RESET}      → Borra archivos ${YELLOW}NO rastreados${RESET}"
  echo -e "                       Elimina: archivos nuevos sin git add\n"

  echo -e "${MAGENTA}${BOLD}📊 ESTADÍSTICAS:${RESET}"
  echo -e "  ${GREEN}gitstats${RESET}           → Commits por autor (ranking)"
  echo -e "                       Muestra: número de commits + nombre\n"

  echo -e "  ${GREEN}gitsize${RESET}            → Tamaño total del repositorio"
  echo -e "                       Incluye: objetos, packs, garbage\n"

  echo -e "${MAGENTA}${BOLD}🗂️  STASH (GUARDAR TEMPORALMENTE):${RESET}"
  echo -e "  ${GREEN}gitstash${RESET}           → Guarda cambios actuales ${YELLOW}SIN COMMIT${RESET}"
  echo -e "                       Limpia working directory\n"

  echo -e "  ${GREEN}gitstashpop${RESET}        → Recupera último stash guardado"
  echo -e "                       Aplica cambios y elimina del stash\n"

  echo -e "  ${GREEN}gitstashlist${RESET}       → Lista todos los stashes guardados\n"

  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}${BOLD}            󰊢 AICOMMITS + OLLAMA - GUÍA COMPLETA 🤖${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"

  echo -e "${MAGENTA}${BOLD}📦 OPENCOMMIT (oco):${RESET}"
  echo -e "  ${GREEN}aicommit${RESET}              → Alias de 'oco' (genera commit con IA)"
  echo -e "                          Lee git diff y crea mensaje automático\n"

  echo -e "  ${GREEN}aicommitconfig${RESET}        → Menú ${YELLOW}interactivo${RESET} de configuración"
  echo -e "                          Muestra modelos disponibles"
  echo -e "                          Configura: provider, modelo, idioma, tokens\n"

  echo -e "  ${GREEN}aicommit-showmodel${RESET}    → Muestra modelo IA ${YELLOW}actualmente en uso${RESET}\n"

  echo -e "  ${GREEN}aicommitreset${RESET}         → Resetea configuración a valores por defecto\n"

  echo -e "  ${GREEN}modellist${RESET}             → Lista modelos de ${YELLOW}Ollama instalados${RESET}"
  echo -e "                          Muestra: nombre, tamaño, última modificación\n"

  echo -e "${BLUE}${BOLD}📋 CONFIGURACIÓN ACTUAL:${RESET}"
  echo -e "  • Provider: ${YELLOW}ollama${RESET}"
  echo -e "  • URL: ${CYAN}http://localhost:11434${RESET}"
  echo -e "  • Idioma: ${YELLOW}es_ES${RESET} (español)"
  echo -e "  • Max tokens entrada: ${CYAN}12000${RESET}"
  echo -e "  • Max tokens salida: ${CYAN}500${RESET}"
  echo -e "  • Recomendación: Usa modelos ${GREEN}cloud${RESET} para commits"
  echo -e "                   Consume ${GREEN}0 GPU${RESET} y ${CYAN}1.5GB RAM${RESET}\n"

  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}${BOLD}                     OTROS COMANDOS ÚTILES 🔧${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"

  echo -e "${GREEN}EspacioTotal${RESET}       → Analiza tamaño de archivos con ${YELLOW}'dust'${RESET}"
  echo -e "                     Muestra: árbol visual + porcentajes"
  echo -e "                     Comando real: ${CYAN}dust /*${RESET}\n"

  echo -e "${GREEN}notepad${RESET} [archivo]  → Abre ${YELLOW}Gedit${RESET} (estilo Windows Notepad)"
  echo -e "                     Sin args: ventana nueva vacía"
  echo -e "                     Con args: abre el archivo especificado\n"

  echo -e "${GREEN}explorer${RESET} [ruta]    → Abre ${YELLOW}Nautilus${RESET} (estilo Windows Explorer)"
  echo -e "                     Sin args: abre carpeta actual"
  echo -e "                     Con args: abre la ruta especificada\n"

  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}${BOLD}                 COMANDOS GIT NATIVOS 📚${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"

  echo -e "${GREEN}git commit --amend${RESET}         → Modifica el ${YELLOW}ÚLTIMO${RESET} commit"
  echo -e "                             Agrega cambios olvidados o cambia mensaje"
  echo -e "                             Ejemplo:"
  echo -e "                               ${CYAN}git add archivo.txt${RESET}"
  echo -e "                               ${CYAN}git commit --amend${RESET}\n"

  echo -e "${GREEN}git rebase -i HEAD~5${RESET}       → Editor interactivo de últimos 5 commits"
  echo -e "                             Comandos disponibles:"
  echo -e "                               ${YELLOW}pick${RESET}   = usar commit tal cual"
  echo -e "                               ${YELLOW}reword${RESET} = cambiar solo el mensaje"
  echo -e "                               ${YELLOW}edit${RESET}   = pausar para modificar contenido"
  echo -e "                               ${YELLOW}squash${RESET} = fusionar con commit anterior"
  echo -e "                               ${YELLOW}fixup${RESET}  = como squash pero descarta mensaje"
  echo -e "                               ${YELLOW}drop${RESET}   = eliminar commit"
  echo -e "                             ${RED}⚠️  Solo para commits NO pusheados${RESET}\n"

  echo -e "${GREEN}git cherry-pick <hash>${RESET}     → Copia ${YELLOW}UN${RESET} commit específico a rama actual"
  echo -e "                             Útil para: traer fix de otra rama"
  echo -e "                             Ejemplo: ${CYAN}git cherry-pick abc123${RESET}\n"

  echo -e "${GREEN}git reflog${RESET}                 → Historial ${YELLOW}COMPLETO${RESET} de movimientos"
  echo -e "                             Recupera commits \"perdidos\""
  echo -e "                             Último recurso cuando hiciste ${RED}reset --hard${RESET}\n"

  echo -e "${GREEN}git bisect start${RESET}           → Búsqueda ${YELLOW}binaria${RESET} de bugs"
  echo -e "                             Encuentra commit que introdujo un error"
  echo -e "                             Uso:"
  echo -e "                               ${CYAN}git bisect start${RESET}"
  echo -e "                               ${CYAN}git bisect bad${RESET}           # commit actual tiene bug"
  echo -e "                               ${CYAN}git bisect good <hash>${RESET}   # commit antiguo sin bug"
  echo -e "                               (git hace checkout y preguntas si tiene bug)\n"

  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}${BOLD}                 EXA - REEMPLAZO DE 'LS' 🎨${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"

  echo -e "${MAGENTA}${BOLD}📂 ALIASES DISPONIBLES:${RESET}"
  echo -e "  ${GREEN}ls${RESET}                     → Lista con ${YELLOW}iconos${RESET} (básico)"
  echo -e "                           Comando: ${CYAN}exa --icons --color=always${RESET}\n"

  echo -e "  ${GREEN}ll${RESET}                     → Lista ${YELLOW}DETALLADA${RESET} (permisos, tamaño, fecha, git)"
  echo -e "                           Comando: ${CYAN}exa -lha --icons --git${RESET}\n"

  echo -e "  ${GREEN}la${RESET}                     → Muestra archivos ${YELLOW}OCULTOS${RESET} (.bashrc, .config)"
  echo -e "                           Comando: ${CYAN}exa -a --icons${RESET}\n"

  echo -e "  ${GREEN}lt${RESET}                     → Vista de ${YELLOW}ÁRBOL${RESET} (carpetas y subcarpetas)"
  echo -e "                           Comando: ${CYAN}exa -T --icons${RESET}\n"

  echo -e "  ${GREEN}lta${RESET}                    → Árbol + archivos ${YELLOW}OCULTOS${RESET}"
  echo -e "                           Comando: ${CYAN}exa -Ta --icons${RESET}\n"

  echo -e "  ${GREEN}ltl${RESET}                    → Árbol ${YELLOW}DETALLADO${RESET} (con permisos y tamaños)"
  echo -e "                           Comando: ${CYAN}exa -lTa --icons --git${RESET}\n"

  echo -e "  ${GREEN}lsd${RESET}                    → Solo ${YELLOW}DIRECTORIOS${RESET} (sin archivos)"
  echo -e "                           Comando: ${CYAN}exa -D --icons${RESET}\n"

  echo -e "  ${GREEN}lss${RESET}                    → Ordenar por ${YELLOW}TAMAÑO${RESET} (más grande primero)"
  echo -e "                           Comando: ${CYAN}exa -lha --sort=size --reverse --icons${RESET}\n"

  echo -e "  ${GREEN}lst${RESET}                    → Ordenar por ${YELLOW}FECHA${RESET} (más reciente primero)"
  echo -e "                           Comando: ${CYAN}exa -lha --sort=modified --reverse --icons${RESET}\n"

  echo -e "${MAGENTA}${BOLD}🔤 OPCIONES PRINCIPALES:${RESET}"
  echo -e "  ${YELLOW}-a, --all${RESET}              → Incluye archivos OCULTOS (empiezan con .)"
  echo -e "  ${YELLOW}-l, --long${RESET}             → Formato DETALLADO (rwx, tamaño, propietario)"
  echo -e "  ${YELLOW}-T, --tree${RESET}             → Vista de ÁRBOL jerárquico"
  echo -e "  ${YELLOW}--icons${RESET}                → Muestra iconos por tipo (📁 📄 🐍)"
  echo -e "  ${YELLOW}--git${RESET}                  → Estado de Git (M=modificado, A=agregado)\n"

  echo -e "${MAGENTA}${BOLD}🎯 EJEMPLOS DE USO REAL:${RESET}"
  echo -e "  ${CYAN}ls${RESET}                     → Listado simple con iconos"
  echo -e "  ${CYAN}ll${RESET}                     → Detalles completos + estado git"
  echo -e "  ${CYAN}la${RESET}                     → Incluye .git, .config, .bashrc"
  echo -e "  ${CYAN}lt --level=2${RESET}           → Árbol limitado a 2 niveles"
  echo -e "  ${CYAN}exa -D${RESET}                 → Solo carpetas (sin archivos)"
  echo -e "  ${CYAN}exa -l --sort=size${RESET}     → Ordenar por tamaño descendente\n"

  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"

  echo -e "${BLUE}${BOLD}💡 TIPS:${RESET}"
  echo -e "  • Usa ${GREEN}'gitflow'${RESET} como punto de partida para todo"
  echo -e "  • Para cambios pequeños: ${GREEN}gitquick${RESET}"
  echo -e "  • Para commits complejos: ${GREEN}gitconv${RESET} o ${GREEN}gitcommit${RESET}"
  echo -e "  • Para explorar historial: ${GREEN}gitlog${RESET} o ${GREEN}gitshowcom${RESET} (tig)"
  echo -e "  • Antes de push, revisa con: ${GREEN}gitdiffs${RESET}\n"

  echo -e "${BLUE}${BOLD}🔗 DOCUMENTACIÓN:${RESET}"
  echo -e "  Git:  ${CYAN}https://git-scm.com/docs${RESET}"
  echo -e "  Eza:  ${CYAN}https://github.com/eza-community/eza${RESET} (fork activo de exa)"
  echo -e "  Oco:  ${CYAN}https://github.com/di-sukharev/opencommit${RESET}\n"

  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
  echo -e "${YELLOW}Presiona 'q' para salir | Usa flechas para navegar${RESET}\n"
}

# Mostrar con less para navegación
show_help | less -R
