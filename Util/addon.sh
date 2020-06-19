
Evernote is one software I use a lot and hence, added the Everpad (Linux unofficial client of Evernote) through adding the ppa:
$ sudo add-apt-repository ppa:nvbn-rm/ppa
$ sudo apt-get update
$ sudo apt-get install everpad

To install Pipelight, add the PPA and install Pipelight using the commands below:
$ sudo apt-add-repository ppa:pipelight/stable
$ sudo apt-get update
$ sudo apt-get install pipelight-multi

Then, install the Silverlight plugin using the following command:
$ sudo pipelight-plugin --enable silverlight

To install the Widevine plugin, use the command below:
$ sudo pipelight-plugin --enable widevin

Further, I added a few other preferred applications like:

#Google Drive Ocamlfuse, a tool that lets you mount Google Drive in Linux
$ sudo add-apt-repository ppa:alessandro-strada/ppa
$ sudo apt-get update
$ sudo apt-get install google-drive-ocamlfuse

Once it's installed, you'll firstly need to authorize it with Google, by running the following command:
$ google-drive-ocamlfuse
Now let's mount Google Drive. Create a folder in your home directory, let's call it "gdrive":
mkdir ~/gdrive

And mount Goole Drive using the command below:
$ google-drive-ocamlfuse ~/gdrive

#Dropbox
$ sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E
$ sudo sh -c 'echo "deb http://linux.dropbox.com/ubuntu/ trusty main" >> /etc/apt/sources.list.d/dropbox.list'
$ sudo apt-get update
$ sudo apt-get install dropbox

In case you are missing the dropbox icon in the panel, install the libappindicator
$ sudo apt-get install libappindicator1

#PlayonLinux
$ sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E0F72778C4676186
$ sudo wget http://deb.playonlinux.com/playonlinux_trusty.list -O /etc/apt/sources.list.d/playonlinux.list
$ sudo apt-get update
$ sudo apt-get install playonlinux

#Google-Chrome
$ wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
$ sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
$ sudo apt-get update
$ sudo apt-get install google-chrome-stable

#Google Earth
$ wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
$ sudo sh -c 'echo "deb http://dl.google.com/linux/earth/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
$ sudo apt-get update
$ sudo apt-get install google-earth-stable

#Google Music
$ wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
$ sudo sh -c 'echo "deb http://dl.google.com/linux/musicmanager/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
$ sudo apt-get update
$ sudo apt-get install google-musicmanager-beta

#Google-talk
$ wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
$ sudo sh -c 'echo "deb http://dl.google.com/linux/talkplugin/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
$ sudo apt-get update
$ sudo apt-get install google-talkplugin

#To create and read .rar archived files
$ sudo apt-get install rar urar

#To control CPU frequency and reduce laptop heat
$ sudo apt-get install indicator-cpufreq

# Install ZSH shell on Ubuntu
sudo apt-get update && sudo apt-get install zsh

# Setup oh-my-zsh
wget –no-check-certificate https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O – | sh

# make ZSH default
chsh -s /bin/zsh

# Restart your system.
