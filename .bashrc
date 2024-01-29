
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

# alias upsvn='_CURRENTDIR=`pwd` && cd ~/Documents/CV  && svn update && cd _CURRENTDIR' 
alias us='_CURRENTDIR=`pwd` && cd ~/Documents/CV && svn update && cd ~/Documents/LSVN/MountainView && svn update && cd ~/Documents/LCloud/Assembla && svn update &&cd _CURRENTDIR' 
alias gsvn='cd ~/Documents/CV' 

alias df='domain_finder.sh'
alias p='pwd'
alias l='ls -ltr'
alias ll='ls -altr'
alias ch='history -c && history -w'
alias attrib='chmod'
alias chdir='cd'
alias copy='cp'
alias cp='cp -i'
alias d='dir'
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
alias kill='kill -9'
alias c='clear'
alias top='htop'
alias f='finger'
alias ut='uptime'
alias u='cd $HOME/Util'
alias s='sudo su'
alias x='exit'
alias xx='exit \n exit'
alias k='killall ' 
alias h='history'
alias cr='cinnamon --replace &'
alias ks='killall skype  pidgin  evolution'
alias e='leafpad ' 
alias v='leafpad ' 
alias kt='killall gnome-terminal '
alias sf='screenfetch'
alias nf='neofetch'
alias sm='banner santhosh is a monkey'
alias gd='google-drive-ocamlfuse ~/gdrive'
alias gdrive='google-drive-ocamlfuse ~/gdrive'
alias synccloud='sh /home/lraja/Util/synccloud.sh &'
alias sc='sh /home/lraja/Util/synccloud.sh &'
alias yt='youtube-dl -f 18 '


## Helpful Ubuntu Aliases
alias install='sudo apt-get install'
alias update='sudo apt-get update'
alias upgrade='sudo apt-get upgrade'
# alias dist-upgrade='sudo apt-get dist-upgrade'
alias dist-upgrade='sudo apt-get update && time sudo apt-get dist-upgrade'
alias remove='sudo apt-get remove'
alias autoremove='sudo apt-get autoremove'
alias apt-source='apt-get source'
alias apt-search='apt-cache search'
alias mountg='google-drive-ocamlfuse ~/gdrive'

alias g='glances'
alias se='sensors'
alias shut='shutdown -r now'
alias neo='neofetch'


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


## Environment variables
export CLIEDITOR=nano
export GUIEDITOR=gedit


# JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
ANT_HOME=/usr/share/ant

# For Backing up .deb files for easy installation  
# cp -r /var/cache/apt/archives/*.* /media/lraja/LinuxStorage1/Net_Downloads

DEB_HOME=/media/lraja/LinuxStorage1/Net_Downloads

PATH="$JAVA_HOME:$DEB_HOME:$ANT_HOME/bin:$HOME/Util:$PATH"

export JAVA_HOME
PATH=$JAVA_HOME/bin:/usr/bin:/usr/sbin:$PATH
export PATH

##Commands to run at start

screenfetch
cowsay `fortune`
 sh $HOME/Util/highcpu_usage.sh &
pwd




export PATH=$PATH:/usr/bin:/usr/sbin


screenfetch


function prompt {
  local BLUE="\[\033[0;34m\]"
  local DARK_BLUE="\[\033[1;34m\]"
  local RED="\[\033[0;31m\]"
  local DARK_RED="\[\033[1;31m\]"
  local GREEN="\[\033[0;32m\]"
  local DARK_GREEN="\[\033[1;32m\]"
  local PURPLE="\[\033[0;35m\]"
  local DARK_PURPLE="\[\033[01;35m\]"
  local CYAN="\[\033[0;36m\]"
  local DARK_CYAN="\[\033[01;36m\]"
  local NO_COLOR="\[\033[0m\]"


txtblk='\e[0;30m' # Black - Regular
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
txtylw='\e[0;33m' # Yellow
txtblu='\e[0;34m' # Blue
txtpur='\e[0;35m' # Purple
txtcyn='\e[0;36m' # Cyan
txtwht='\e[0;37m' # White
bldblk='\e[1;30m' # Black - Bold
bldred='\e[1;31m' # Red
bldgrn='\e[1;32m' # Green
bldylw='\e[1;33m' # Yellow
bldblu='\e[1;34m' # Blue
bldpur='\e[1;35m' # Purple
bldcyn='\e[1;36m' # Cyan
bldwht='\e[1;37m' # White
unkblk='\e[4;30m' # Black - Underline
undred='\e[4;31m' # Red
undgrn='\e[4;32m' # Green
undylw='\e[4;33m' # Yellow
undblu='\e[4;34m' # Blue
undpur='\e[4;35m' # Purple
undcyn='\e[4;36m' # Cyan
undwht='\e[4;37m' # White
bakblk='\e[40m'   # Black - Background
bakred='\e[41m'   # Red
bakgrn='\e[42m'   # Green
bakylw='\e[43m'   # Yellow
bakblu='\e[44m'   # Blue
bakpur='\e[45m'   # Purple
bakcyn='\e[46m'   # Cyan
bakwht='\e[47m'   # White
txtrst='\e[0m'    # Text Reset
  
  case $TERM in
    xterm*|rxvt*)
      TITLEBAR='\[\033]0;\u@\h:\w\007\]'
      ;;
    *)
      TITLEBAR=""
      ;;
  esac
  PS1="\u@\h [\t]'$PWD'> "
  PS1="${TITLEBAR}\
$DARK_CYAN\u@\h $GREEN[\t]$DARK_PURPLE\w>$NO_COLOR "
  PS2='continue-> '
  PS4='$0.$LINENO+ '
}


# PS1='$USERNAME #$PWD $ ' 
PWD=`pwd`


# JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
ANT_HOME=/usr/share/ant

PATH="$JAVA_HOME:$ANT_HOME/bin:$HOME/Util:$PATH"

export JAVA_HOME
PATH=$JAVA_HOME/bin:$PATH
export PATH


##Commands to run at start
# screenfetch
# cowsay `fortune`
sh $HOME/Util/highcpu_usage.sh &
pwd


stty sane
prompt


 

