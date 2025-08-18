# LinuxMint Setup


This repo Mint19Setup  -- Updated Utilities for Linux Mint 22.1 cinnamon

Config files(bashrc, zshrc, git etc) and utilities, conky setup files etc.. etc

Welcome to GitHub Pages.

Target Audience: People who want to setup Linux Mint 22.1  with Cinnamon desktop configurations quickly

URL Contains Config files(bashrc, zshrc, git etc) and utilities, .deb archives, conky files etc

Github URL: https://github.com/loganathr20/Mint19Setup

Goto Home folder ( All config files need to be present in $HOME folder idealy).

$ cd $HOME

$ git clone https://github.com/loganathr20/Mint19Setup .

(or)

To clone in minthub folder and later you can move files to $HOME

$ git clone https://github.com/loganathr20/Mint19Setup


Other Utilities for Linux Mint 22.1 :
__________________________________________

DEB Packages:
Chrome
VS Code
Mailspring
Skype
Slack
Insomnia
WPS Office
TeamViewer
my-ubuntu-setup.sh
cd
sudo apt update
sudo apt upgrade -y
sudo apt dist-upgrade

##################
# Basic packages #
##################

sudo apt install zsh git build-essential htop screenfetch cowsay sl fortunes-br lolcat zip unzip rar unrar lm-sensors sysinfo vim youtube-dl apt-transport-https zlib1g-dev libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev ruby2.5 ruby2.5-dev -y

############
# GUI Apps #
############

sudo apt install tilix gimp plank inkscape audacity vlc gparted xsensors conky bleachbit ttf-mscorefonts-installer typecatcher qbittorrent cheese

##############################
# PPAs (for latest releases) #
##############################

## Spotify ##
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 931FF8E79F0876134EDDBDCCA87FF9DF48BF1C90
echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list

## Sublime Text 3 ##
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list

## NodeJS ##
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -

## Yarn ##
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

## OBS Studio ##
sudo add-apt-repository ppa:obsproject/obs-studio -y

## Adapta Theme ##
sudo add-apt-repository ppa:tista/adapta -y

sudo apt update
sudo apt install spotify-client sublime-text nodejs yarn obs-studio adapta-gtk-theme -y

#########
# Fonts #
#########

## Powerline Fonts ##
git clone git@github.com:powerline/fonts.git
cd fonts && ./install.sh
cd .. && rm -rf fonts

## Top Programming Fonts ##
curl -L https://github.com/hbin/top-programming-fonts/raw/master/install.sh | bash

## Fira Code ##
wget https://github.com/tonsky/FiraCode/releases/download/4/Fira_Code_v4.zip
unzip FiraCode_v4.zip 'ttf/*' -d ~/.fonts
mv ~/.fonts/ttf/* ~/.fonts
rm -rf ~/.fonts/ttf

wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.0.0/FiraCode.zip
unzip FiraCode.zip '*.ttf' -d ~/.fonts

rm FiraCode_1.205.zip FiraCode.zip
fc-cache
cd

########
# Misc #
########

## Git configs ##
git config --global user.name "loganathr20"
git config --global user.email "loganathr20@gmail.com"
git config --global color.ui true
git config --global core.editor "vim"

git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.df diff
git config --global alias.cmt commit
git config --global alias.pl pull
git config --global alias.ps push

## Vim configs ##
wget https://raw.githubusercontent.com/mathcale/dotfiles/master/.vimrc
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

## Tilix themes ##
mkdir -p ~/.config/tilix/schemes
cd ~/.config/tilix/schemes
git clone git@github.com:storm119/Tilix-Themes.git
mv Tilix-Themes/Themes/* .
mv Tilix-Themes/Themes-2/* .
rm -rf Tilix-Themes
cd

## Oh My ZSH ##
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
git clone https://github.com/denysdovhan/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt"
ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

## Disable RDoc ##
touch ~/.gemrc && echo "gem: --no-ri --no-rdoc" >> ~/.gemrc

## Ruby packages ##
sudo gem install bundler
sudo gem install jekyll

## NPM Packages ##
sudo npm i -g sass express-generator create-react-app@next @vue/cli @vue/cli-init @vue/cli-service-global nodemon pm2 expo-cli




Authors and Contributors
loganathr20@gmail.com

Support or Contact
loganathr20@gmail.com

LinuxMint19hub -- Utilities for Linux Mint 22.1  cinnamon maintained by loganathr20

Published with GitHub Pages



