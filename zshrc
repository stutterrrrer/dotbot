# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 0 >>> homebrew plugins
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/opt/powerlevel10k/powerlevel10k.zsh-theme



# 1 >>> key bindings
	# 1. mapping jj etc to escape in zsh ( this is now done with zsh vi mode homebrew version)


# 2 >>> aliases
	# always use ls with -G color flag. -F show slashes for directory and @ for symlinks
alias ls='ls -GF' 
alias v='mvim'
	# to easier attach to sessions, especially in intelliJ's emulated terminal

# 3 >>> environment variables
export ICLOUD=/Users/ian/Library/Mobile\ Documents/com~apple~CloudDocs
export EDITOR=vim
	# ClashX - Copy shell command; so that terminal can be routed through ClashX VPN as well.
export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890

	# rbenv - manage ruby version - just for vim golf
eval "$(rbenv init -)"

# z >>> functions:
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

vman ()
{
	if [[ $# -eq 1 ]]
	then
		man $1 | mvim +MANPAGER -
	else
		$@ | mvim +MANPAGER -
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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
