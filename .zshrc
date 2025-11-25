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

# alias us='_CURRENTDIR=`pwd` && cd ~/Documents/SVN/GoldenBird/CV && svn update && cd ~/Documents/SVN/GoldenBird && svn update && cd ~/Documents/LCloud/Assembla && svn update &&cd _CURRENTDIR' 
alias us='_CURRENTDIR=`pwd` && cd ~/Documents/SVN/GoldenBird/CV && pwd && svn status && svn update && cd ~/Documents/SVN/GoldenBird  && pwd && svn status && svn update  && svn status && cd _CURRENTDIR  && pwd' 
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
alias kteams='killall teams-for-linux'

alias kz='killall zoom'
alias cairo='killall cairo-dock'
alias c='clear'
alias top='htop'
alias f='finger'
alias ut='uptime'
alias u='cd $HOME/Github/Mint19Setup/Util'
alias mi='cd $HOME/Github/Mint19Setup'
alias ub='cd /usr/bin'

alias ga='cd /home/lraja/Desktop/Garage'
alias s='sudo su'
alias x='exit'
alias xx='exit \n exit'
alias k='killall ' 
alias h='history 0'
alias cr='cinnamon --replace &'
alias kt='killall gnome-do gnome-calculator tomboy skype  pidgin  spotify gnome-terminal '
alias e='gedit ' 
alias v='gedit ' 
alias kii='killall  chrome  gnome-system-monitor gnome-terminal-server teams-for-linux evolution nemo gnome-do gnome-calculator pidgin skype tomboy whatsapp-desktop-linux whatsapp-deskto spotify zoom '
alias sf='screenfetch'
alias sm='banner santhya is a monkey'
alias gd='google-drive-ocamlfuse ~/gdrive'
alias gdrive='google-drive-ocamlfuse ~/gdrive'
alias synccloud='sh $HOME/Github/Mint19Setup/Util/synccloud.sh &'
alias syn='sh $HOME/Github/Mint19Setup/Util/synccloud.sh &'
# alias cl='sh freemem.sh && sh clear_swap.sh && sh clean_mailbox.sh && sh killusage.sh'
alias fm='sh freemem.sh'
alias cs='sh clear_swap.sh'
alias cm='sh clean_mailbox.sh'
alias ki='sh killusage.sh'
alias tm='sudo hddtemp /dev/sda'

alias dx='sh dxcmode.sh'

alias ke='killall evolution'
alias ku='sh killu.sh'
alias con='sh conky-startup.sh &'
alias av='sh anti_virus.sh &'
alias a='alias'
alias remove='rm -rf ' 
alias ldeb='cd $HOME/Documents/Net_Downloads'
alias deb='cd /var/cache/apt/archives/'
alias sb='cd $HOME/Documents/SystemBack'
alias sv='cd $HOME/Documents/SVN/GoldenBird'
alias as='cd $HOME/Documents/Cloud/Assembla'
# alias dsts='v $HOME/Documents/SVN/GoldenBird/Documents/Lokesh/dsts.txt'
# alias kdsts='v $HOME/Documents/SVN/GoldenBird/Documents/Kotak/dsts.txt'

alias dsts='v /media/lraja/DDrive_SSD_SATA/SVN/GoldenBird/Documents/Lokesh/dsts.txt'
alias kdsts='v /media/lraja/DDrive_SSD_SATA/SVN/GoldenBird/Documents/Kotak/dsts.txt'


alias dxts='v $HOME/Documents/SVN/GoldenBird/Documents/DXCTech/dxts.txt'
alias nissd='v $HOME/Documents/SVN/GoldenBird/Documents/DXCTech/Nissan/NewOnedrive/ANissan/Personal/nissd.txt'
alias dbsdoc='cd $HOME/Documents/DXCTech/Nissan/VDI_codesetup/Regarding_DBS_setup_'
alias usts='v $HOME/Documents/SVN/Win10Repo/Personal/ust.txt'
alias ust=' nemo $HOME/Documents/SVN/GoldenBird/Documents/USTGlobal'
alias pcj=' v $HOME/Documents/SVN/GoldenBird/Documents/Kotak/PCJ_DIGIGOLD/pcj.txt'


alias dstsa='v $HOME/Documents/SVN/GoldenBird/Documents/DXCTech/OneDriveDXC/OneDriveDxc/Personal/dstsa.txt'
alias dstsd='v $HOME/Documents/SVN/GoldenBird/Documents/DXCTech/OneDriveDXC/OneDriveDxc/Personal/dstsd.txt'
alias gh='v $HOME/Documents/SVN/GoldenBird/Documents/GitHelp/githelp.txt'
alias notes='v $HOME/Documents/SVN/GoldenBird/Documents/GitHelp/Notes.txt'
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'
alias speed='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'
alias sp='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'

alias whichs='echo $0'
alias doc='cd $HOME/Documents'
alias down='cd $HOME/Downloads'
alias kot='cd $HOME/Documents/SVN/GoldenBird/Documents/Kotak'
alias lok='cd $HOME/Documents/SVN/GoldenBird/Documents/Lokesh'
alias dxc='nemo $HOME/Documents/SVN/GoldenBird/Documents/DXCTech'
alias htc='cd $HOME/Documents/SVN/GoldenBird/Documents/HTCGlobal'
alias jio='v $HOME/Documents/SVN/GoldenBird/Documents/Jio/Jio.txt'
alias cvf='v $HOME/Documents/SVN/GoldenBird/CV/Current/CV_upto_HTC/cvform.txt'
alias cv='nemo $HOME/Documents/SVN/GoldenBird/CV/Current/CV_upto_HTC'
alias cn=' nemo $HOME/Documents/SVN/GoldenBird/Documents/Kotak/ContractNotes'
alias aws='nemo $HOME/Documents/CommonRepo/AWS'
alias n='cd $HOME/Documents/Net_Downloads'
alias svnss='clear && sh $HOME/csvn/bin/csvn start'
alias svnt='clear && sh $HOME/csvn/bin/csvn stop && sudo fuser -k 18080/tcp'
alias svns='sh $HOME/Github/Mint19Setup/Util/svns.sh &'
alias svnst='sh $HOME/Github/Mint19Setup/Util/svnstatus.sh &'
alias cst='sh $HOME/Github/Mint19Setup/Util/cst.sh &'
alias mp4tomp3='sh $HOME/Github/Mint19Setup/Util/mp4tomp3.sh &'
alias dos2unix='perl -pi -e 's/\r\n/\n/g' $1'
# alias dos2unix='sed -e "s/^M//" $1 $2'
alias convertmedia='ffmpeg -i $1 $2'

alias insur='v $HOME/Documents/SVN/GoldenBird/Documents/Kwid/RTO_and_Insurance/insurance_companytxt'
alias kwid='nemo $HOME/Documents/SVN/GoldenBird/Documents/Kwid'
alias aprilia='nemo $HOME/Documents/SVN/GoldenBird/Documents/Aprilia'

alias tslist='sudo timeshift --list'
alias ts='sudo timeshift --list'
alias t='sudo timeshift --list'
alias tscheck='sudo timeshift --check'
alias tch='sudo timeshift --check'
alias tscreate='sudo timeshift --create'

alias tsdelete='sudo timeshift --delete'
alias tsdeleteall='sudo timeshift --delete-all'


alias timerstatus='systemctl list-timers --all | grep timeshift'
alias 8hstatus='sudo systemctl status new_timeshift-8h.service' 
alias bootstatus='sudo systemctl status new_timeshift-boot.service'
alias cleanupstatus='sudo systemctl status timeshift-cleanup.service'
alias notes='v $HOME/Github/Mint19Setup/TimeShift_Automate/notes.txt'


alias 8hstart='sudo systemctl start new_timeshift-8h.service'  
alias bootstart='sudo systemctl start new_timeshift-boot.service' 
alias cleanupstart='sudo systemctl start timeshift-cleanup.service' 

alias sc='svn cleanup'
alias upp='svn update'
alias st='svn status'
alias upt='sh $HOME/Github/Mint19Setup/Util/upt.sh'
alias kp='sudo fuser -k 18080/tcp'
alias m='more '
alias tree='sh $HOME/Github/Mint19Setup/Util/tree.sh '
alias gk='$HOME/Documents/GitGUI/gitkraken/gitkraken'


## Helpful Ubuntu Aliases
alias install1='sudo apt-get install'
alias update1='sudo apt-get update'
alias upgrade1='sudo apt-get upgrade'
alias remove1='sudo apt-get remove'
alias autoremove1='sudo apt-get autoremove'
alias autoclean1='sudo apt-get autoclean'
alias autopurge1='sudo apt-get purge autoclean'
alias ar1='sudo apt-get autoremove'
alias ac='sudo apt-get autoclean'
alias ap='sudo apt-get purge autoclean'


alias install='sudo nala install'
alias update='sudo nala update'
alias upgrade='sudo nala upgrade'

alias uu='sudo nala update && sudo nala upgrade && sudo nala full-upgrade && sudo apt-get autoremove && sudo apt-get autoclean  && sudo nala autoremove  && sudo nala list --upgradable && sudo nala history'

alias uu1='echo "\n\n **********************************************************\n\n Network Settings \n **********************************************************\n" && sudo iwconfig wlx98038eb487bc txpower 10 && sudo iwconfig wlx98038eb487bc && sudo systemctl restart NetworkManager'

alias ns='sudo iwconfig wlx98038eb487bc'

alias ns1='sudo iwconfig wlxf0a73129dcba'



alias nn='echo "\n *********************************************************\n\n Network Settings txpower 10 - Default Temp \n **********************************************************\n" && sudo iwconfig wlx98038eb487bc txpower 10  && sudo iwconfig wlx98038eb487bc && sudo systemctl restart NetworkManager'

alias nn1='echo "\n *********************************************************\n\n Network Settings txpower 10 - Default Temp \n **********************************************************\n" && sudo iwconfig wlxf0a73129dcba txpower 10  && sudo iwconfig wlxf0a73129dcba && sudo systemctl restart NetworkManager'


alias nnc='echo "\n *********************************************************\n\n Network Settings txpower 5 -- Cooler Temp \n **********************************************************\n" && sudo iwconfig wlx98038eb487bc txpower 5  && sudo iwconfig wlx98038eb487bc && sudo systemctl restart NetworkManager'

alias nns='echo "\n *********************************************************\n\n Network Settings txpower 15 - Optimum Temp \n **********************************************************\n" && sudo iwconfig wlx98038eb487bc txpower 15  && sudo iwconfig wlx98038eb487bc && sudo systemctl restart NetworkManager'


alias full-upgrade='sudo nala full-upgrade'
alias autoremove='sudo nala autoremove'
alias remove='sudo nala remove'
alias autoclean1='sudo nala autoclean'
alias autopurge1='sudo nala purge autoclean'
alias ar='sudo nala autoremove'
alias ac1='sudo nala autoclean'
alias ap1='sudo nala purge autoclean'
alias upgradable='sudo nala list --upgradable'
alias fetch='sudo nala fetch'
alias show='sudo nala show'
alias list='sudo nala list'
alias nhistory='sudo nala history'


# alias dist-upgrade='sudo apt-get dist-upgrade'
alias dist-upgrade='sudo apt-get update && time sudo apt-get dist-upgrade'
alias apt-source='apt-get source'
alias apt-search='apt-cache search'
alias mountg='google-drive-ocamlfuse ~/gdrive'
alias MountIphone='ifuse ~/IPhone'

alias in='inxi -F'
alias j='crontab -l'
alias cmod='chmod +x'
alias updategrub='sudo update-grub'
alias yt='youtube-dl '
alias mi='cd $HOME/Github/Mint19Setup'
alias shift='cd $HOME/Documents/Deploy.Kubernetes.web-project'
alias gs='git status'
alias gp='git pull'
alias gm='git merge'
alias gco='git commit -a'
alias gc='git checkout '
alias gb='git branch '
alias gba='git branch -a'
alias up='sh /home/lraja/Documents/update_git.sh'


alias googleurl='sh $HOME/Github/Mint19Setup/Util/urlopener.sh "https://google.com"'
alias bb='cd $HOME/BitBucket'
alias je='cd $JENKINS_HOME'
alias ws='cd $JENKINS_HOME/workspace'
alias i='sh $HOME/Github/Mint19Setup/Util/ids.sh'
alias ovpn='sudo sh $HOME/Github/Mint19Setup/Util/ovpn.sh'
alias reboot='sudo systemctl reboot -i'
alias locateupdate='sudo apt install locate && sudo updatedb'

# alias memfree =  free -m | grep -i mem | tr -d [A-z],\:,\+,\=,\-,\/, | awk '{print"Mem used: "100-(($3)/($1)*100)"%"}'


alias netstat='netstat -tulpn'
# alias gf='sh $HOME/Github/Mint19Setup/Util/gitflow/git-flow'
alias gf='sh $HOME/DriessensModel/gitflow/git-flow'
alias glog='git log --graph --abbrev-commit --decorate --date=relative --all'
alias hibernate='systemctl hibernate -i'
alias g='glances'
alias se='sensors'
alias shut='shutdown -r now'
alias neo='neofetch'
alias suspend='systemctl suspend -i'

alias tomreload='sudo systemctl daemon-reload'
alias tom='cd /opt/tomcat/'
alias tomstart='sudo systemctl start tomcat'
alias tomstatus='sudo systemctl status tomcat'
alias tomrestart='sudo systemctl restart tomcat'
alias tomstop='sudo systemctl stop tomcat'
alias tomdeploy='sudo sh $HOME/Github/Mint19Setup/Util/tomdeploy.sh '
alias tomconfig='sudo nano /etc/systemd/system/tomcat.service'
alias tomurl='sh $HOME/Github/Mint19Setup/Util/urlopener.sh "http://LinuxMint-Thinkcentre:8080" & '


alias kuberstart='microk8s start'
alias kuberstop='microk8s stop'
alias kuberstatus='microk8s status'
alias kuberdash='microk8s dashboard-proxy'
alias mkctl='microk8s kubectl'

alias jenkinsreload='sudo systemctl daemon-reload'
alias jenkinsstart='sudo systemctl start jenkins'
alias jenkinsstatus='sudo systemctl status jenkins'
alias jenkinsrestart='sudo systemctl restart jenkins'
alias jenkinsstop='sudo systemctl stop jenkins'

alias jiradir='cd /opt/atlassian/jira/bin'
alias jirastart='sudo ./start-jira.sh'


alias kc='killall -HUP cinnamon'
alias gtalk='google-chat-electron &'

alias MountIphone='ifuse ~/IPhone'

# MYSQL Alias
alias mysqlrestart='sudo service mysql restart'
alias journalctl='sudo journalctl -u mysql'
alias mysqldump='mysqldump -u root [database name] > dump.sql'
alias mysqlrestore='mysql -u root [database name] < dump.sql'
alias mysqlworkbench='mysql-workbench-community'


# Compare SVN REPOs
alias comparealla='
  foldercompare.sh /media/lraja/DDrive_SSD_SATA/csvn/data/repositories/GoldenBird /media/lraja/Elephant/SVN/Repositories/Archive/GoldenBird &&
  foldercompare.sh /media/lraja/DDrive_SSD_SATA/csvn/data/repositories/Win10Repo /media/lraja/Elephant/SVN/Repositories/Archive/Win10Repo &&
  foldercompare.sh /media/lraja/DDrive_SSD_SATA/csvn/data/repositories/GoldenBird /media/lraja/Elephant/SVN/Repositories/Backup/GoldenBird &&
  foldercompare.sh /media/lraja/DDrive_SSD_SATA/csvn/data/repositories/Win10Repo /media/lraja/Elephant/SVN/Repositories/Backup/Win10Repo &&
  foldercompare.sh /media/lraja/DDrive_SSD_SATA/csvn/data "/media/lraja/My Passport/SVN/data" &&
  foldercompare.sh /media/lraja/DDrive_SSD_SATA/csvn/data/repositories/GoldenBird "/media/lraja/My Passport/SVN/data/repositories/GoldenBird" &&
  foldercompare.sh /media/lraja/DDrive_SSD_SATA/csvn/data/repositories/Win10Repo "/media/lraja/My Passport/SVN/data/repositories/Win10Repo"
'

alias compareall='
  echo "Comparing GoldenBird → Archive"; foldercompare.sh /media/lraja/DDrive_SSD_SATA/csvn/data/repositories/GoldenBird /media/lraja/Elephant/SVN/Repositories/Archive/GoldenBird; echo "Press Enter to continue..."; read _; clear ;
  echo "Comparing Win10Repo → Archive"; foldercompare.sh /media/lraja/DDrive_SSD_SATA/csvn/data/repositories/Win10Repo /media/lraja/Elephant/SVN/Repositories/Archive/Win10Repo; echo "Press Enter to continue..."; read _; clear ; 
  echo "Comparing GoldenBird → Backup"; foldercompare.sh /media/lraja/DDrive_SSD_SATA/csvn/data/repositories/GoldenBird /media/lraja/Elephant/SVN/Repositories/Backup/GoldenBird; echo "Press Enter to continue..."; read _; clear ;
  echo "Comparing Win10Repo → Backup"; foldercompare.sh /media/lraja/DDrive_SSD_SATA/csvn/data/repositories/Win10Repo /media/lraja/Elephant/SVN/Repositories/Backup/Win10Repo; echo "Press Enter to continue..."; read _; clear ; 
  echo "Comparing /data → My Passport"; foldercompare.sh /media/lraja/DDrive_SSD_SATA/csvn/data "/media/lraja/My Passport/SVN/data"; echo "Press Enter to continue..."; read _;  clear ;
  echo "Comparing GoldenBird → My Passport"; foldercompare.sh /media/lraja/DDrive_SSD_SATA/csvn/data/repositories/GoldenBird "/media/lraja/My Passport/SVN/data/repositories/GoldenBird"; echo "Press Enter to continue..."; read _; clear ; 
  echo "Comparing Win10Repo → My Passport"; foldercompare.sh /media/lraja/DDrive_SSD_SATA/csvn/data/repositories/Win10Repo "/media/lraja/My Passport/SVN/data/repositories/Win10Repo"; read _; clear ; 
'




# Package Managment
alias nalai='nala list --installed'

# sudo /etc/init.d/jenkins restart
# Usage: /etc/init.d/jenkins {start|stop|status|restart|force-reload}

# Environment variables
export CLIEDITOR=nano
export GUIEDITOR=gedit


git config --global core.editor "vim"
export GIT_EDITOR=vim

export VISUAL=gedit
export EDITOR="$VISUAL"



# JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

JAVA_HOME="/usr/lib/jvm/jdk-21-oracle-x64"

# M2_HOME='/opt/apache-maven-3.9.6'
# PATH="$M2_HOME/bin:$PATH"
# export PATH

M2_HOME=/usr/share/maven
PATH="$M2_HOME/bin:$PATH"
export PATH

export JAVA_HOME
export JRE_HOME=$JAVA_HOME/jre

ANT_HOME=/usr/share/ant
PATH="$ANT_HOME:$ANT_HOME/bin:$PATH"
export PATH


# For Backing up .deb files for easy installation  
# cp -r /var/cache/apt/archives/*.* $HOME/Documents/Net_Downloads

DEB_HOME=$HOME/Documents/Net_Downloads

export PYTHONPATH="$PYTHONPATH:$HOME/Development/python3"
# gitkraken="$HOME/gitkraken"
# gitflow="$HOME/Github/Mint19Setup/Util/gitflow"
# gitflow="$HOME/DriessensModel/gitflow"

# export PATH=$PATH:$HOME/bin:$JAVA_HOME/bin:$JRE_HOME/bin:$ANT_HOME:$JAVA_HOME:$DEB_HOME:$ANT_HOME/bin:$HOME/Github/Mint19Setup/Util:$HOME/csvn
# export PATH=$PATH:/usr/bin:/usr/sbin:$HOME/Github/Mint19Setup/Util:$PYTHONPATH:$PATH:$gitkraken:$gitflow:$M2_HOME:$M2

export PATH=$PATH:$PATH:/usr/bin:/usr/sbin:$JAVA_HOME:$JAVA_HOME/bin:$JAVA_HOME/lib:$JRE_HOME/bin:$JRE_HOME/lib:$ANT_HOME:$ANT_HOME/bin:$HOME/Github/Mint19Setup/Util:$PYTHONPATH:$PATH:$gitkraken:$gitflow


# Jenkins environment ( Change it when job changes)
#JENKINS_HOME=$HOME/JenkinsJobs

JENKINS_HOME=/var/lib/jenkins
# ITEM_FULLNAME=${JENKINS_HOME}/atoadapp
# ITEM_ROOTDIR=${JENKINS_HOME}/workspace/${ITEM_FULLNAME}

export JENKINS_HOME
export ITEM_FULLNAME
export ITEM_ROOTDIR


# screenfetch
neofetch

##Commands to run at start
# clear 
echo " Press i and enter for more Information \n "
echo " $HOST Welcomes You. \n "


echo " Current working directory is `pwd` \n "
echo " To list currently running cronjobs press j \n"
echo " To increase disk space run $HOME/Github/Mint19Setup/Util/movebackup.sh as super user "

crontab -l
inxi -F

# stty intr ^v^c

echo " \n \n \n Current system uptime statistics: \n  `uptime` \n "

# espeak " Welcome $USER"
# sleep 1
# espeak " I am Spark X. You are in super user mode. "

# cowsay `fortune` 
echo "\n "

# sh $HOME/Github/Mint19Setup/Util/highcpu_usage.sh &

# git config --global credential.helper 'cache --timeout=3600'


webmTOmp4 () {
      ffmpeg -i "$1".webm -qscale 0 "$1".mp4
}    

mp4TOmp3 () {
      ffmpeg -i "$1".mp4 "$1".mp3
}


export MAIL=/var/mail/username


echo "************************************************************************\n"
echo "\n"

echo " Home Directory is $HOME"
echo "\n"

echo " JAVA_HOME Directory is $JAVA_HOME"
echo "\n"

echo " JRE_HOME Directory is $JRE_HOME"
echo "\n"

echo " M2_Home Directory is $M2_HOME"
echo "\n"

echo " ANT_Home Directory is $ANT_HOME"
echo "\n"

echo " JENKINS_HOME Directory is $JENKINS_HOME"
echo "\n"

echo " Current Shell  is $0 "
echo "\n"

echo " Path is \n"
echo $PATH

echo "\n"
echo " Mounting Iphone "
echo "\n"
ifuse ~/IPhone


echo "\n"
echo "************************************************************************\n"


# echo " Jenkins server status \n"
# jenkinsstatus

hostnamectl

echo "\n"

w

echo "\n"

# echo "timerstatus \n"
# systemctl list-timers --all | grep timeshift


echo " alias timerstatus='systemctl list-timers --all | grep timeshift'  \n"
echo " alias 8hstatus='sudo systemctl status new_timeshift-8h.service'  \n"
echo " alias bootstatus='sudo systemctl status new_timeshift-boot.service' \n"
echo " alias cleanupstatus='sudo systemctl status timeshift-cleanup.service' \n"

echo " alias 8hstart='sudo systemctl start new_timeshift-8h.service' \n"  
echo " alias bootstart='sudo systemctl start new_timeshift-boot.service' \n" 
echo " alias cleanupstart='sudo systemctl start timeshift-cleanup.service' \n"

# google-chat-electron 



