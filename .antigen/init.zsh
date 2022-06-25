#-- START ZCACHE GENERATED FILE
#-- GENERATED: sáb 25 jun 2022 01:20:13 AST
#-- ANTIGEN v2.2.2
_antigen () {
	local -a _1st_arguments
	_1st_arguments=('apply:Load all bundle completions' 'bundle:Install and load the given plugin' 'bundles:Bulk define bundles' 'cleanup:Clean up the clones of repos which are not used by any bundles currently loaded' 'cache-gen:Generate cache' 'init:Load Antigen configuration from file' 'list:List out the currently loaded bundles' 'purge:Remove a cloned bundle from filesystem' 'reset:Clears cache' 'restore:Restore the bundles state as specified in the snapshot' 'revert:Revert the state of all bundles to how they were before the last antigen update' 'selfupdate:Update antigen itself' 'snapshot:Create a snapshot of all the active clones' 'theme:Switch the prompt theme' 'update:Update all bundles' 'use:Load any (supported) zsh pre-packaged framework') 
	_1st_arguments+=('help:Show this message' 'version:Display Antigen version') 
	__bundle () {
		_arguments '--loc[Path to the location <path-to/location>]' '--url[Path to the repository <github-account/repository>]' '--branch[Git branch name]' '--no-local-clone[Do not create a clone]'
	}
	__list () {
		_arguments '--simple[Show only bundle name]' '--short[Show only bundle name and branch]' '--long[Show bundle records]'
	}
	__cleanup () {
		_arguments '--force[Do not ask for confirmation]'
	}
	_arguments '*:: :->command'
	if (( CURRENT == 1 ))
	then
		_describe -t commands "antigen command" _1st_arguments
		return
	fi
	local -a _command_args
	case "$words[1]" in
		(bundle) __bundle ;;
		(use) compadd "$@" "oh-my-zsh" "prezto" ;;
		(cleanup) __cleanup ;;
		(update|purge) compadd $(type -f \-antigen-get-bundles &> /dev/null || antigen &> /dev/null; -antigen-get-bundles --simple 2> /dev/null) ;;
		(theme) compadd $(type -f \-antigen-get-themes &> /dev/null || antigen &> /dev/null; -antigen-get-themes 2> /dev/null) ;;
		(list) __list ;;
	esac
}
antigen () {
  local MATCH MBEGIN MEND
  [[ "$ZSH_EVAL_CONTEXT" =~ "toplevel:*" || "$ZSH_EVAL_CONTEXT" =~ "cmdarg:*" ]] && source "/home/rudolf/antigen.zsh" && eval antigen $@;
  return 0;
}
typeset -gaU fpath path
fpath+=(/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/git /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/fzf /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/pip /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/colorize /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/command-not-found /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/gitfast /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/ufw /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/zsh-interactive-cd /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/copypath /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/cp /home/rudolf/.antigen/bundles/zsh-users/zsh-syntax-highlighting /home/rudolf/.antigen/bundles/zsh-users/zsh-completions /home/rudolf/.antigen/bundles/zsh-users/zsh-autosuggestions /home/rudolf/.antigen/bundles/laggardkernel/zsh-thefuck /home/rudolf/.antigen/bundles/chrissicool/zsh-256color /home/rudolf/.antigen/bundles/ael-code/zsh-colored-man-pages /home/rudolf/.antigen/bundles/spaceship-prompt/spaceship-prompt) path+=(/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/git /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/fzf /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/pip /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/colorize /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/command-not-found /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/gitfast /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/ufw /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/zsh-interactive-cd /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/copypath /home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/cp /home/rudolf/.antigen/bundles/zsh-users/zsh-syntax-highlighting /home/rudolf/.antigen/bundles/zsh-users/zsh-completions /home/rudolf/.antigen/bundles/zsh-users/zsh-autosuggestions /home/rudolf/.antigen/bundles/laggardkernel/zsh-thefuck /home/rudolf/.antigen/bundles/chrissicool/zsh-256color /home/rudolf/.antigen/bundles/ael-code/zsh-colored-man-pages /home/rudolf/.antigen/bundles/spaceship-prompt/spaceship-prompt)
_antigen_compinit () {
  autoload -Uz compinit; compinit -d "/home/rudolf/.antigen/.zcompdump"; compdef _antigen antigen
  add-zsh-hook -D precmd _antigen_compinit
}
autoload -Uz add-zsh-hook; add-zsh-hook precmd _antigen_compinit
compdef () {}

if [[ -n "/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh" ]]; then
  ZSH="/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh"; ZSH_CACHE_DIR="/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/cache/"
fi
#--- BUNDLES BEGIN
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/bzr.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/clipboard.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/cli.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/compfix.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/completion.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/correction.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/diagnostics.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/directories.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/functions.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/git.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/grep.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/history.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/key-bindings.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/misc.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/nvm.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/prompt_info_functions.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/spectrum.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/termsupport.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/theme-and-appearance.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/vcs_info.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/git/git.plugin.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/fzf/fzf.plugin.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/pip/pip.plugin.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/colorize/colorize.plugin.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/command-not-found/command-not-found.plugin.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/gitfast/gitfast.plugin.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/zsh-interactive-cd/zsh-interactive-cd.plugin.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/copypath/copypath.plugin.zsh';
source '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/cp/cp.plugin.zsh';
source '/home/rudolf/.antigen/bundles/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh';
source '/home/rudolf/.antigen/bundles/zsh-users/zsh-completions/zsh-completions.plugin.zsh';
source '/home/rudolf/.antigen/bundles/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh';
source '/home/rudolf/.antigen/bundles/laggardkernel/zsh-thefuck/zsh-thefuck.plugin.zsh';
source '/home/rudolf/.antigen/bundles/laggardkernel/zsh-thefuck/init.zsh';
source '/home/rudolf/.antigen/bundles/chrissicool/zsh-256color/zsh-256color.plugin.zsh';
source '/home/rudolf/.antigen/bundles/ael-code/zsh-colored-man-pages/colored-man-pages.plugin.zsh';
source '/home/rudolf/.antigen/bundles/spaceship-prompt/spaceship-prompt/spaceship.zsh';

#--- BUNDLES END
typeset -gaU _ANTIGEN_BUNDLE_RECORD; _ANTIGEN_BUNDLE_RECORD=('https://github.com/robbyrussell/oh-my-zsh.git lib plugin true' 'https://github.com/robbyrussell/oh-my-zsh.git plugins/git plugin true' 'https://github.com/robbyrussell/oh-my-zsh.git plugins/fzf plugin true' 'https://github.com/robbyrussell/oh-my-zsh.git plugins/pip plugin true' 'https://github.com/robbyrussell/oh-my-zsh.git plugins/colorize plugin true' 'https://github.com/robbyrussell/oh-my-zsh.git plugins/command-not-found plugin true' 'https://github.com/robbyrussell/oh-my-zsh.git plugins/gitfast plugin true' 'https://github.com/robbyrussell/oh-my-zsh.git plugins/ufw plugin true' 'https://github.com/robbyrussell/oh-my-zsh.git plugins/zsh-interactive-cd plugin true' 'https://github.com/robbyrussell/oh-my-zsh.git plugins/copypath plugin true' 'https://github.com/robbyrussell/oh-my-zsh.git plugins/cp plugin true' 'https://github.com/zsh-users/zsh-syntax-highlighting.git / plugin true' 'https://github.com/zsh-users/zsh-completions.git / plugin true' 'https://github.com/zsh-users/zsh-autosuggestions.git / plugin true' 'https://github.com/laggardkernel/zsh-thefuck.git / plugin true' 'https://github.com/chrissicool/zsh-256color.git / plugin true' 'https://github.com/ael-code/zsh-colored-man-pages.git / plugin true' 'https://github.com/spaceship-prompt/spaceship-prompt.git / theme true')
typeset -g _ANTIGEN_CACHE_LOADED; _ANTIGEN_CACHE_LOADED=true
typeset -ga _ZCACHE_BUNDLE_SOURCE; _ZCACHE_BUNDLE_SOURCE=('/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/bzr.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/clipboard.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/cli.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/compfix.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/completion.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/correction.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/diagnostics.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/directories.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/functions.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/git.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/grep.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/history.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/key-bindings.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/misc.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/nvm.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/prompt_info_functions.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/spectrum.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/termsupport.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/theme-and-appearance.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/lib/vcs_info.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/git' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/git/git.plugin.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/fzf' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/fzf/fzf.plugin.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/pip' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/pip/pip.plugin.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/colorize' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/colorize/colorize.plugin.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/command-not-found' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/command-not-found/command-not-found.plugin.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/gitfast' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/gitfast/gitfast.plugin.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/ufw' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/zsh-interactive-cd' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/zsh-interactive-cd/zsh-interactive-cd.plugin.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/copypath' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/copypath/copypath.plugin.zsh' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/cp' '/home/rudolf/.antigen/bundles/robbyrussell/oh-my-zsh/plugins/cp/cp.plugin.zsh' '/home/rudolf/.antigen/bundles/zsh-users/zsh-syntax-highlighting//' '/home/rudolf/.antigen/bundles/zsh-users/zsh-syntax-highlighting///zsh-syntax-highlighting.plugin.zsh' '/home/rudolf/.antigen/bundles/zsh-users/zsh-completions//' '/home/rudolf/.antigen/bundles/zsh-users/zsh-completions///zsh-completions.plugin.zsh' '/home/rudolf/.antigen/bundles/zsh-users/zsh-autosuggestions//' '/home/rudolf/.antigen/bundles/zsh-users/zsh-autosuggestions///zsh-autosuggestions.plugin.zsh' '/home/rudolf/.antigen/bundles/laggardkernel/zsh-thefuck//' '/home/rudolf/.antigen/bundles/laggardkernel/zsh-thefuck///zsh-thefuck.plugin.zsh' '/home/rudolf/.antigen/bundles/laggardkernel/zsh-thefuck///init.zsh' '/home/rudolf/.antigen/bundles/chrissicool/zsh-256color//' '/home/rudolf/.antigen/bundles/chrissicool/zsh-256color///zsh-256color.plugin.zsh' '/home/rudolf/.antigen/bundles/ael-code/zsh-colored-man-pages//' '/home/rudolf/.antigen/bundles/ael-code/zsh-colored-man-pages///colored-man-pages.plugin.zsh' '/home/rudolf/.antigen/bundles/spaceship-prompt/spaceship-prompt//' '/home/rudolf/.antigen/bundles/spaceship-prompt/spaceship-prompt///spaceship.zsh-theme')
typeset -g _ANTIGEN_CACHE_VERSION; _ANTIGEN_CACHE_VERSION='v2.2.2'

#-- END ZCACHE GENERATED FILE
