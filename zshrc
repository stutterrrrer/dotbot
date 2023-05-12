# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# {{{
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
#}}}

# homebrew plugins {{{
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/opt/powerlevel10k/powerlevel10k.zsh-theme
# }}}

# other settings: global history; optimized history search etc. {{{

# history {{{
# sync history between all zsh sessions
setopt share_history
# ignroe duplicates
setopt HIST_IGNORE_DUPS
# search through history based on what's alreayd typed - see https://coderwall.com/p/jpj_6q/zsh-better-history-searching-with-arrow-keys
# why you need the zle commands:
# zsh-syntax-highlighting: unhandled ZLE widget 'up-line-or-beginning-search'
# zsh-syntax-highlighting: (This is commonly caused by doing `bindkey <keys> up-line-or-beginning-search` without creating the 'up-line-or-beginning-search' widget with `zle -N` or `zle -C`.)
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
# these 2 only works with actual up and down keys - not zsh-vim-mode normal j and k
bindkey $key[Up] up-line-or-beginning-search # Up
bindkey $key[Down] down-line-or-beginning-search # Down 
# these work with zsh-vim-mode - see https://stackoverflow.com/a/68484008
bindkey -M vicmd "k" up-line-or-beginning-search
bindkey -M vicmd "j" down-line-or-beginning-search
#}}}

#}}}

# aliases {{{
# always use ls with -G color flag. -F show slashes for directory and @ for symlinks
alias ls='ls -GF' 
alias v='mvim'
alias python='python3'
alias h='history'
# }}}

# environment variables {{{
export ICLOUD=/Users/ian/Library/Mobile\ Documents/com~apple~CloudDocs
export EDITOR=vim
	# ClashX - Copy shell command; so that terminal can be routed through ClashX VPN as well.
# export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890
# }}}

# functions: manv(), n(), idea() etc. {{{
javar ()
{
	# compile all .java files in current directory into a temp classes directory, execute, then delete the temp directory.
	tempDir=compiled_classes_temp
	javac *.java -d $tempDir
	java -classpath $tempDir "$@"
	rm -rf $tempDir
}

javar-alg()
{
	# include the algorithm course's provided textbook library to classpath:
	tempDir=compiled_classes_temp
	javac -classpath ~/IdeaProjects/Princeton_Algorithms_Course/0-jar_files_for_cmd_line/* *.java -d $tempDir 
	java -classpath ~/IdeaProjects/Princeton_Algorithms_Course/0-jar_files_for_cmd_line/algs4.jar:$tempDir "$@"
	rm -rf $tempDir
}

manv ()
{
	if [[ $# -eq 1 ]]
	then
		man $1 | mvim +MANPAGER -
	else
		$@ | mvim +MANPAGER -
	fi
}

manvim ()
{
	if [[ $# -eq 1 ]]
	then
		man $1 | vim +MANPAGER -
	else
		$@ | vim +MANPAGER -
	fi
}

ta ()
{
	if [[ $# -eq 0 ]]
	then
		tmux attach
	else
		tmux attach-session -t $@
	fi
}

n ()
{
    # Block nesting of nnn in subshells
    if [ -n $NNNLVL ] && [ "${NNNLVL:-0}" -ge 1 ]; then
        echo "nnn is already running"
        return
    fi

    # The default behaviour is to cd on quit (nnn checks if NNN_TMPFILE is set)
    # To cd on quit only on ^G, remove the "export" as in:
    #     NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

    # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
    # stty start undef
    # stty stop undef
    # stty lwrap undef
    # stty lnext undef

    nnn "$@"

    if [ -f "$NNN_TMPFILE" ]; then
            . "$NNN_TMPFILE"
            rm -f "$NNN_TMPFILE" > /dev/null
    fi
}

	# open a folder / directory with IntelliJ IDEA app.
idea()
{
	open -na "IntelliJ IDEA.app" --args "$@"	
}
# }}}

# other: p10k.zsh {{{
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#}}}
