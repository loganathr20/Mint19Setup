
# This just means that there is an application using apt.

# First try to find out which application it is by using this command in the terminal

ps aux | grep apt | grep -v 'grep'

rm -rf /var/cache/apt/archives/lock
