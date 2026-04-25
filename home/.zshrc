# Show system info on new terminal
fastfetch

# Add ~/bin to PATH
export PATH="$HOME/bin:$PATH"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/yutonglv/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/yutonglv/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/yutonglv/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/yutonglv/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
# Function to get the current Git branch
parse_git_branch() {
    git branch 2>/dev/null | grep '*' | sed 's/* //'
}

# Function to show SSH status
ssh_indicator() {
    if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
        echo "%F{red}(SSH)%f"
    fi
}

# Enable colors
autoload -U colors && colors

alias ls='ls -G'

# App shortcuts
alias chrome='open -a "Google Chrome"'
alias safari='open -a Safari'
alias iterm='open -a iTerm'
alias kitty='open -a kitty'
alias forget='cat ~/forget.txt'
alias forgete='nvim ~/forget.txt'
alias lastss='ls -t ~/Desktop/Screenshot* 2>/dev/null | head -1'
alias cpss='echo $(ls -t ~/Desktop/Screenshot* 2>/dev/null | head -1) | pbcopy && echo "path copied!"'
alias code='open -a "Visual Studio Code"'
alias cursor='open -a Cursor'
alias pycharm='open -a PyCharm'
alias clion='open -a CLion'
alias idea='open -a "IntelliJ IDEA"'
alias webstorm='open -a WebStorm'
alias xcode='open -a Xcode'
alias lmstudio='open -a "LM Studio"'
alias rstudio='open -a RStudio'
alias r='open -a R'
alias notion='open -a Notion'
alias obsidian='open -a Obsidian'
alias notability='open -a Notability'
alias xmind='open -a Xmind'
alias word='open -a "Microsoft Word"'
alias excel='open -a "Microsoft Excel"'
alias ppt='open -a "Microsoft PowerPoint"'
alias wps='open -a wpsoffice'
alias pages='open -a Pages'
alias numbers='open -a Numbers'
alias keynote='open -a Keynote'
alias zotero='open -a Zotero'
alias calibre='open -a calibre'
alias cclaude='open -a Claude'
alias chatgpt='open -a "ChatGPT Atlas"'
alias wechat='open -a WeChat'
alias discord='open -a Discord'
alias spotify='open -a Spotify'
alias music='open -a NeteaseMusic'
alias imovie='open -a iMovie'
alias garageband='open -a GarageBand'
alias photoshop='open -a "Adobe Photoshop 2026"'
alias lightroom='open -a "Adobe Lightroom Classic"'
alias acrobat='open -a "Adobe Acrobat DC"'
alias onedrive='open -a OneDrive'
alias clash='open -a ClashX'
alias quickfox='open -a QuickFox'
alias zoom='open -a zoom.us'
alias magnet='open -a Magnet'
alias skim='open -a Skim'
alias gantt='open -a GanttProject'
alias qqlive='open -a QQLive'
alias sorted='open -a Sorted³'
alias essayist='open -a Essayist'
alias hiclock='open -a "Hi Clock"'
alias antigravity='open -a Antigravity'
alias motionpro='open -a MotionPro'
alias anaconda='open -a Anaconda-Navigator'

# Mac Mini shortcuts
alias jobtracker='ssh macmini -L 3000:localhost:3000 && echo "Tunnel closed"'

# Apple apps
alias maps='open -a Maps'
alias weather='open -a Weather'
alias messages='open -a Messages'
alias facetime='open -a FaceTime'
alias notes='open -a Notes'
alias reminders='open -a Reminders'
alias calendar='open -a Calendar'
alias photos='open -a Photos'
alias mail='open -a Mail'
alias contacts='open -a Contacts'
alias books='open -a Books'
alias podcasts='open -a Podcasts'
alias news='open -a News'
alias stocks='open -a Stocks'
alias home='open -a Home'
alias findmy='open -a "Find My"'
alias preview='open -a Preview'
alias textedit='open -a TextEdit'
alias calc='open -a Calculator'
alias appstore='open -a "App Store"'
alias settings='open -a "System Settings"'
alias terminal='open -a Terminal'
alias finder='open -a Finder'
alias freeform='open -a Freeform'
alias shortcuts='open -a Shortcuts'
alias voice='open -a "Voice Memos"'
alias stickies='open -a Stickies'

# Minimal prompt (like the screenshot)
PROMPT=$'\n%F{cyan}~%f\n%F{green}❯%f '


# >>> COPT Solver Configuration >>>
export COPT_HOME=/Applications/copt72
export COPT_LICENSE_DIR=/Applications/copt72
export PATH=$COPT_HOME/bin:$PATH
export DYLD_LIBRARY_PATH=$COPT_HOME/lib:$DYLD_LIBRARY_PATH
# <<< COPT Solver Configuration <<<

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
# module load eecs484  # Only works on CAEN
# module load mongodb   # Only works on CAEN

export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
export PATH="$HOME/.pyenv/shims:$PATH"

# Added by Antigravity
export PATH="/Users/yutonglv/.antigravity/antigravity/bin:$PATH"
