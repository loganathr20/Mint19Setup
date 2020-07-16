######################################################################
#                                                                    #
#           LRaja .zshrc v1.0, based on:                             #
#           smartboyathome's .zshrc v0.3, based on:                  #
#           jdong's zshrc file v0.2.1 , based on:                    #
#	    mako's zshrc file, v0.1                                  #
#                                                                    #
######################################################################

# next lets set some enviromental/shell pref stuff up
 setopt NOHUP
#setopt NOTIFY
#setopt NO_FLOW_CONTROL
setopt INC_APPEND_HISTORY SHARE_HISTORY
setopt APPEND_HISTORY
# setopt AUTO_LIST		# these two should be turned off
# setopt AUTO_REMOVE_SLASH
# setopt AUTO_RESUME		# tries to resume command of same name
unsetopt BG_NICE		# do NOT nice bg commands
setopt CORRECT			# command CORRECTION
setopt EXTENDED_HISTORY		# puts timestamps in the history
 setopt HASH_CMDS		# turns on hashing
#
setopt MENUCOMPLETE
setopt ALL_EXPORT

# Set/unset  shell options
setopt   notify globdots correct pushdtohome cdablevars autolist
setopt   correctall autocd recexact longlistjobs
setopt   autoresume histignoredups pushdsilent
setopt   autopushd pushdminus extendedglob rcquotes mailwarning
unsetopt bgnice autoparamslash

# Autoload zsh modules when they are referenced
zmodload -a zsh/stat stat
zmodload -a zsh/zpty zpty
zmodload -a zsh/zprof zprof
# zmodload -ap zsh/mapfile mapfile
autoload -Uz copy-earlier-word
zle -N copy-earlier-word
bindkey "^[m" copy-earlier-word

# TZ="America/Los_Angeles"
HISTFILE=$HOME/.zhistory
HISTSIZE=1000000
SAVEHIST=1000000
HOSTNAME="`hostname`"
PAGER='less'
EDITOR='gedit'
BROWSER='firefox'
    autoload colors zsh/terminfo
    if [[ "$terminfo[colors]" -ge 8 ]]; then
   colors
    fi
    for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
   eval PR_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
   eval PR_LIGHT_$color='%{$fg[${(L)color}]%}'
   (( count = $count + 1 ))
    done
    PR_NO_COLOR="%{$terminfo[sgr0]%}"
PS1="[$PR_RED$PR_GREEN%U%n@%m%u:$PR_NO_COLOR]#$PR_BLUE%2c$PR_RED%(!.#.$) $PR_NO_COLOR"
#LANGUAGE=
LC_ALL='en_US.UTF-8'
LANG='en_US.UTF-8'
LC_CTYPE=C

unsetopt ALL_EXPORT

#if [[ $HOSTNAME == "kamna" ]] {
#	alias emacs='emacs -l ~/.emacs.kamna'
#}	

# alias	=clear

#chpwd() {
#     [[ -t 1 ]] || return
#     case $TERM in
#     sun-cmd) print -Pn "\e]l%~\e\\"
#     ;;
#    *xterm*|screen|rxvt|(dt|k|E)term) print -Pn "\e]2;%~\a"
#    ;;
#    esac
#}
#chpwd

autoload -U compinit
compinit
bindkey "^?" backward-delete-char
bindkey '^[OH' beginning-of-line
bindkey '^[OF' end-of-line
bindkey '^[[5~' up-line-or-history
bindkey '^[[6~' down-line-or-history
bindkey "^r" history-incremental-search-backward
bindkey ' ' magic-space    # also do history expansion on space
bindkey '^I' complete-word # complete on tab, leave expansion to _expand
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path ~/.zsh/cache/$HOST

zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more, or the character to insert%s'
zstyle ':completion:*' menu select=1 _complete _ignored _approximate
zstyle -e ':completion:*:approximate:*' max-errors \
    'reply=( $(( ($#PREFIX+$#SUFFIX)/2 )) numeric )'
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

# Completion Styles

# list of completers to use
zstyle ':completion:*::::' completer _expand _complete _ignored _approximate

# allow one error for every three characters typed in approximate completer
zstyle -e ':completion:*:approximate:*' max-errors \
    'reply=( $(( ($#PREFIX+$#SUFFIX)/2 )) numeric )'

# insert all expansions for expand completer
zstyle ':completion:*:expand:*' tag-order all-expansions

# formatting and messages
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
zstyle ':completion:*' group-name ''

# match uppercase from lowercase
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}'

# offer indexes before parameters in subscripts
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# command for process lists, the local web server details and host completion
# on processes completion complete all user processes
# zstyle ':completion:*:processes' command 'ps -au$USER'

## add colors to processes for kill completion
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

#zstyle ':completion:*:processes' command 'ps ax -o pid,s,nice,stime,args | sed "/ps/d"'
zstyle ':completion:*:*:kill:*:processes' command 'ps --forest -A -o pid,user,cmd'
zstyle ':completion:*:processes-names' command 'ps axho command'
#zstyle ':completion:*:urls' local 'www' '/var/www/htdocs' 'public_html'
#
#NEW completion:
# 1. All /etc/hosts hostnames are in autocomplete
# 2. If you have a comment in /etc/hosts like #%foobar.domain,
#    then foobar.domain will show up in autocomplete!
zstyle ':completion:*' hosts $(awk '/^[^#]/ {print $2 $3" "$4" "$5}' /etc/hosts | grep -v ip6- && grep "^#%" /etc/hosts | awk -F% '{print $2}') # Filename suffixes to ignore during completion (except after rm command)
zstyle ':completion:*:*:(^rm):*:*files' ignored-patterns '*?.o' '*?.c~' \
    '*?.old' '*?.pro'
# the same for old style completion
#fignore=(.o .c~ .old .pro)

# ignore completion functions (until the _ignored completer)
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:*:*:users' ignored-patterns \
        adm apache bin daemon games gdm halt ident junkbust lp mail mailnull \
        named news nfsnobody nobody nscd ntp operator pcap postgres radvd \
        rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs avahi-autoipd\
        avahi backup messagebus beagleindex debian-tor dhcp dnsmasq fetchmail\
        firebird gnats haldaemon hplip irc klog list man cupsys postfix\
        proxy syslog www-data mldonkey sys snort
# SSH Completion$HOME/Documents/SystemBack
zstyle ':completion:*:scp:*' tag-order \
   files users 'hosts:-host hosts:-domain:domain hosts:-ipaddr"IP\ Address *'
zstyle ':completion:*:scp:*' group-order \
   files all-files users hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' tag-order \
   users 'hosts:-host hosts:-domain:domain hosts:-ipaddr"IP\ Address *'
zstyle ':completion:*:ssh:*' group-order \
   hosts-domain hosts-host users hosts-ipaddr
zstyle '*' single-ignored show

##Additions to zshrc
if [ -f ~/.zshrc-additions ]; then
    . ~/.zshrc-additions
fi

##THIS MAKES YAOURT WORK, DON'T TAKE IT OUT!
export color=
LS_COLORS='no=00;37:fi=00:di=00;33:ln=04;36:pi=40;33:so=01;35:bd=40;33;01:'
export LS_COLORS
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}


##Other aliases
alias untarbz2='tar -xvjf'
alias untargz='tar -xvzf'
alias listbz2='tar -tjf'
alias listgz='tar -tzf'
alias edit-cli='$CLIEDITOR'
alias suedit-cli='sudo $CLIEDITOR'
alias edit='$GUIEDITOR'
alias suedit='gksu $GUIEDITOR'
alias start-timidity='timidity -iA -B2,8 -Oj -s 44100'
alias su='sudo -i'
alias yt='clear screen && bash && youtube-dl -f 18'
alias cl='xsel -bc'

# alias upsvn='_CURRENTDIR=`pwd` && cd ~/Documents/CV  && svn update && cd _CURRENTDIR' 

# alias us='_CURRENTDIR=`pwd` && cd ~/Documents/SVN/Lodgey/CV && svn update && cd ~/Documents/SVN/Lodgey && svn update && cd ~/Documents/LCloud/Assembla && svn update &&cd _CURRENTDIR' 
alias us='_CURRENTDIR=`pwd` && cd ~/Documents/SVN/Lodgey/CV && pwd && svn status && svn update && cd ~/Documents/SVN/Lodgey  && pwd && svn status && svn update  && svn status && cd _CURRENTDIR  && pwd' 
alias gsvn='cd ~/Documents/CV' 

alias hc='_CURRENTDIR=`pwd` && cd ~ && mv .zhistory .zhistory_old && touch .zhistory && cd _CURRENTDIR'

alias dif='domain_finder.sh'
alias p='pwd'
alias l='ls -ltr'
alias ll='ls -altr'
alias ch='history -c && history -w'
alias attrib='chmod'
alias chdir='cd'
alias copy='cp'
alias cp='cp -i'
alias d='dir'
alias ca='gnome-calculator'
alias del='rm'
alias deltree='rm -r'
alias dir='/bin/ls $LS_OPTIONS --format=vertical'
alias edit='pico'
alias ff='whereis'
alias ls='/bin/ls $LS_OPTIONS'
alias mem='top'
alias move='mv'
alias mv='mv -i'
alias pico='pico -w -z'
alias rm='rm -i'
alias search='grep'
# alias v='vdir'
alias vdir='/bin/ls $LS_OPTIONS --format=long'
alias which='type -path'
alias wtf='watch -n 1 w -hs'
alias wth='ps -uxa | more'
alias ps='ps -aux'
alias kill='kill -9'
alias ke='killall evolution'
alias c='clear'
alias top='htop'
alias f='finger'
alias ut='uptime'
alias u='cd $HOME/Mint19Setup/Util'
alias s='sudo su'
alias x='exit'
alias xx='exit \n exit'
alias k='killall ' 
alias h='history 0'
alias cr='cinnamon --replace &'
alias ks='killall gnome-do gnome-calculator tomboy skype  pidgin  evolution nemo'
alias e='leafpad ' 
alias v='leafpad ' 
alias kt='killall gnome-terminal chrome  gnome-system-monitor gnome-terminal-server'
alias sf='screenfetch'
alias sm='banner santhosh is a monkey'
alias gd='google-drive-ocamlfuse ~/gdrive'
alias gdrive='google-drive-ocamlfuse ~/gdrive'
alias synccloud='sh $HOME/Mint19Setup/Util/synccloud.sh &'
alias syn='sh $HOME/Mint19Setup/Util/synccloud.sh &'
# alias cl='sh freemem.sh && sh clear_swap.sh && sh clean_mailbox.sh && sh killusage.sh'
alias fm='sh freemem.sh'
alias cs='sh clear_swap.sh'
alias cm='sh clean_mailbox.sh'
alias ki='sh killusage.sh'
alias ke='killall evolution'
alias ku='sh killu.sh'
alias con='sh conky-startup.sh &'
alias av='sh anti_virus.sh &'
alias a='alias'
alias remove='rm -rf ' 
alias ldeb='cd $HOME/Documents/Net_Downloads'
alias deb='cd /var/cache/apt/archives/'
alias sb='cd $HOME/Documents/SystemBack'
alias sv='cd $HOME/Documents/SVN/Lodgey'
alias as='cd $HOME/Documents/Cloud/Assembla'
alias dsts='v $HOME/Documents/SVN/Lodgey/Documents/Lokesh/dsts.txt'
alias kdsts='v $HOME/Documents/SVN/Lodgey/Documents/Kotak/dsts.txt'
alias dxts='v $HOME/Documents/SVN/Lodgey/Documents/DXCTech/dxts.txt'
alias dstsa='v $HOME/Documents/SVN/Lodgey/Documents/DXCTech/OneDriveDXC/OneDriveDxc/Personal/dstsa.txt'
alias dstsd='v $HOME/Documents/SVN/Lodgey/Documents/DXCTech/OneDriveDXC/OneDriveDxc/Personal/dstsd.txt'
alias gh='v $HOME/Documents/SVN/Lodgey/Documents/GitHelp/githelp.txt'
alias notes='v $HOME/Documents/SVN/Lodgey/Documents/GitHelp/Notes.txt'
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -'
alias speed='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -'
alias sp='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -'



alias kot='cd $HOME/Documents/SVN/Lodgey/Documents/Kotak'
alias lok='cd $HOME/Documents/SVN/Lodgey/Documents/Lokesh'
alias dxc='nemo $HOME/Documents/SVN/Lodgey/Documents/DXCTech'
alias htc='cd $HOME/Documents/SVN/Lodgey/Documents/HTCGlobal'
alias jio='v $HOME/Documents/SVN/Lodgey/Documents/Jio/Jio.txt'
alias cvf='v $HOME/Documents/SVN/Lodgey/CV/Current/CV_upto_HTC/cvform.txt'
alias cv='nemo $HOME/Documents/SVN/Lodgey/CV/Current/CV_upto_HTC'
alias cn=' nemo $HOME/Documents/SVN/Lodgey/Documents/Kotak/ContractNotes'
alias aws='nemo $HOME/Documents/CommonRepo/AWS'
alias n='cd $HOME/Documents/Net_Downloads/Kernel/latest4.1.1'
alias svnss='clear && sh $HOME/csvn/bin/csvn start'
alias svnt='clear && sh $HOME/csvn/bin/csvn stop && sudo fuser -k 18080/tcp'
alias svns='sh $HOME/Mint19Setup/Util/svns.sh &'
alias svnst='sh $HOME/Mint19Setup/Util/svnstatus.sh &'
alias cst='sh $HOME/Mint19Setup/Util/cst.sh &'
alias mp4tomp3='sh $HOME/Mint19Setup/Util/mp4tomp3.sh &'


alias insur='v $HOME/Documents/SVN/Lodgey/Documents/Kwid/RTO_and_Insurance/insurance_companytxt'
alias kwid='nemo $HOME/Documents/SVN/Lodgey/Documents/Kwid'
alias aprilia='nemo $HOME/Documents/SVN/Lodgey/Documents/Aprilia'


alias sc='svn cleanup'
alias up='svn update'
alias st='svn status'
alias upt='sh $HOME/Mint19Setup/Util/upt.sh'
alias kp='sudo fuser -k 18080/tcp'
alias m='more '
alias tree='sh $HOME/Mint19Setup/Util/tree.sh '
alias gk='$HOME/gitkraken/gitkraken'

## Helpful Ubuntu Aliases
alias install='sudo apt-get install'
alias update='sudo apt-get update'
alias upgrade='sudo apt-get upgrade'
# alias dist-upgrade='sudo apt-get dist-upgrade'
alias dist-upgrade='sudo apt-get update && time sudo apt-get dist-upgrade'
alias remove='sudo apt-get remove'
alias autoremove='sudo apt-get autoremove'
alias autoclean='sudo apt-get autoclean'
alias autopurge='sudo apt-get purge autoclean'
alias apt-source='apt-get source'
alias apt-search='apt-cache search'
alias mountg='google-drive-ocamlfuse ~/gdrive'
alias in='inxi -F'
alias j='crontab -l'
alias cmod='chmod +x'
alias updategrub='sudo update-grub'
alias yt='youtube-dl '
alias mi='cd $HOME/Mint19Setup'
alias gs='git status'
alias gp='git push'
alias gco='git commit -a'
alias gc='git checkout '
alias gb='git branch '
alias gba='git branch -a'

alias tomreload='sudo systemctl daemon-reload'
alias tomstart='sudo systemctl start tomcat'
alias tomstatus='sudo systemctl status tomcat'
alias tomrestart='sudo systemctl restart tomcat'
alias tomstop='sudo systemctl stop tomcat'
alias tomdeploy='sudo sh $HOME/Mint19Setup/Util/tomdeploy.sh '
alias tomconfig='sudo nano /etc/systemd/system/tomcat.service'
alias tomurl='sh $HOME/Mint19Setup/Util/urlopener.sh "http://lraja-Aspire-X3990:8080" & '
alias googleurl='sh $HOME/Mint19Setup/Util/urlopener.sh "https://google.com"'
alias bb='cd $HOME/BitBucket'
alias i='sh $HOME/Mint19Setup/Util/ids.sh'
# alias memfree =  free -m | grep -i mem | tr -d [A-z],\:,\+,\=,\-,\/, | awk '{print"Mem used: "100-(($3)/($1)*100)"%"}'




alias jenkinsreload='sudo systemctl daemon-reload'
alias jenkinsstart='sudo systemctl start jenkins'
alias jenkinsstatus='sudo systemctl status jenkins'
alias jenkinsrestart='sudo systemctl restart jenkins'
alias jenkinsstop='sudo systemctl stop jenkins'
alias netstat='netstat -tulpn'
# alias gf='sh $HOME/Mint19Setup/Util/gitflow/git-flow'
alias gf='sh $HOME/DriessensModel/gitflow/git-flow'
alias glog='git log --graph --abbrev-commit --decorate --date=relative --all'


# sudo /etc/init.d/jenkins restart
# Usage: /etc/init.d/jenkins {start|stop|status|restart|force-reload}

## Environment variables
export CLIEDITOR=nano
export GUIEDITOR=gedit


# JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
# JAVA_HOME=/usr/lib/jvm/jdk1.7.0_80
# JAVA_HOME="/usr/lib/jvm/java-8-oracle"
# JAVA_HOME="/usr/lib/jvm/java-9-oracle"
# JAVA_HOME=/usr/lib/jvm/jdk-11.0.1
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
# JAVA_HOME="/usr/lib/jvm/jdk1.6.0_45"

M2_HOME=/usr/share/maven
M2=$M2_HOME/bin

# export CATALINA_HOME
# export TOMCAT_JAVA_HOME

export JAVA_HOME

export JRE_HOME=$JAVA_HOME/jre


ANT_HOME=/usr/share/ant

# For Backing up .deb files for easy installation  
# cp -r /var/cache/apt/archives/*.* $HOME/Documents/Net_Downloads

DEB_HOME=$HOME/Documents/Net_Downloads

export PYTHONPATH="$PYTHONPATH:$HOME/Development/python"
gitkraken="$HOME/gitkraken"
# gitflow="$HOME/Mint19Setup/Util/gitflow"
gitflow="$HOME/DriessensModel/gitflow"

export PATH=$PATH:$HOME/bin:$JAVA_HOME/bin:$JRE_HOME/bin:$ANT_HOME:$JAVA_HOME:$DEB_HOME:$ANT_HOME/bin:$HOME/Mint19Setup/Util:$HOME/csvn
export PATH=/usr/bin:/usr/sbin:$HOME/Mint19Setup/Util:$PYTHONPATH:$PATH:$gitkraken:$gitflow:$M2_HOME:$M2






# Jenkins environment ( Change it when job changes)
JENKINS_HOME=$HOME/JenkinsJobs
ITEM_FULLNAME=${JENKINS_HOME}/atoadapp
ITEM_ROOTDIR=${JENKINS_HOME}/workspace/${ITEM_FULLNAME}

export JENKINS_HOME
export ITEM_FULLNAME
export ITEM_ROOTDIR


# export M3_HOME=/opt/apache-maven-3.1.0
export M3_HOME=/usr/share/maven
export M3=$M3_HOME/bin
export PATH=$M3:$PATH


screenfetch

##Commands to run at start
clear 
echo " Press i and enter for more Information \n "
echo " $HOST Welcomes You. \n "


echo " Current working directory is `pwd` \n "
echo " To list currently running cronjobs press j \n"
echo " To increase disk space run $HOME/Mint19Setup/Util/movebackup.sh as super user "

 crontab -l
 inxi -F

# stty intr ^v^c

echo " \n \n \n Current system uptime statistics: \n  `uptime` \n "

# espeak " Welcome $USER"
# sleep 1
# espeak " I am Spark X. You are in super user mode. "

# cowsay `fortune` 
echo "\n "

# sh $HOME/Mint19Setup/Util/highcpu_usage.sh &

# git config --global credential.helper 'cache --timeout=3600'


webmTOmp4 () {
      ffmpeg -i "$1".webm -qscale 0 "$1".mp4
}    

mp4TOmp3 () {
      ffmpeg -i "$1".mp4 "$1".mp3
}




export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


