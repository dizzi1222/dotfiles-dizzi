#!/bin/bash
# fix-zsh-unified.sh - Reparar e instalar Zsh con dotfiles

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔧 Reparando Zsh con dotfiles...${NC}"

# 1. Instalar Oh My Zsh si no existe
if [[ ! -d ~/.oh-my-zsh ]]; then
  echo -e "${GREEN}Instalando Oh My Zsh...${NC}"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 2. Limpiar plugins existentes del sistema
echo -e "${YELLOW}Limpiando plugins antiguos del sistema...${NC}"
rm -rf ~/.oh-my-zsh/custom/plugins/zsh-*
rm -rf ~/.zsh/zsh-autocomplete
rm -rf ~/.zsh/fzf-tab

# 2.5 Instalar Powerlevel10k theme
if [[ ! -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]]; then
  echo -e "${GREEN}Instalando Powerlevel10k...${NC}"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    ~/.oh-my-zsh/custom/themes/powerlevel10k
fi

# 3. Ir a dotfiles y clonar plugins DENTRO del repo
cd ~/dotfiles-dizzi

echo -e "${GREEN}Clonando plugins dentro de dotfiles...${NC}"

# Plugins Oh My Zsh Custom
mkdir -p zsh/.oh-my-zsh/custom/plugins

[[ ! -d zsh/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]] &&
  git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
    zsh/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

[[ ! -d zsh/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]] &&
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git \
    zsh/.oh-my-zsh/custom/plugins/zsh-autosuggestions

[[ ! -d zsh/.oh-my-zsh/custom/plugins/zsh-completions ]] &&
  git clone --depth 1 https://github.com/zsh-users/zsh-completions.git \
    zsh/.oh-my-zsh/custom/plugins/zsh-completions

[[ ! -d zsh/.oh-my-zsh/custom/plugins/zsh-history-substring-search ]] &&
  git clone --depth 1 https://github.com/zsh-users/zsh-history-substring-search.git \
    zsh/.oh-my-zsh/custom/plugins/zsh-history-substring-search

# Plugins externos
mkdir -p zsh/.zsh

[[ ! -d zsh/.zsh/zsh-autocomplete ]] &&
  git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git \
    zsh/.zsh/zsh-autocomplete

[[ ! -d zsh/.zsh/fzf-tab ]] &&
  git clone --depth 1 https://github.com/Aloxaf/fzf-tab.git \
    zsh/.zsh/fzf-tab

# 4. Limpiar .git internos y agregar a tu repo
echo -e "${GREEN}Agregando plugins al repo...${NC}"
find zsh/.oh-my-zsh/custom/plugins -name ".git" -exec rm -rf {} + 2>/dev/null || true
find zsh/.zsh -name ".git" -exec rm -rf {} + 2>/dev/null || true

git add zsh/ 2>/dev/null || true
git commit -m "feat(zsh): add plugins as regular files" 2>/dev/null || true

# 5. Backup y aplicar dotfiles con stow
echo -e "${GREEN}Aplicando dotfiles con stow...${NC}"
[[ -f ~/.zshrc ]] && [[ ! -L ~/.zshrc ]] && mv ~/.zshrc ~/.zshrc.bak

stow -R zsh

# 6. Restaurar .zshrc original del repo si fue modificado
git checkout HEAD zsh/.zshrc 2>/dev/null || true

# 7. Cambiar shell
echo -e "${GREEN}Configurando Zsh como shell por defecto...${NC}"
sudo chsh -s $(which zsh) $USER

echo -e "${GREEN}✅ Zsh reparado exitosamente${NC}"
echo -e "${YELLOW}Cierra sesión y vuelve a entrar, o ejecuta: exec zsh${NC}"
