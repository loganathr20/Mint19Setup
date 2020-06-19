clear


echo " Below steps will upgrade Linux Mint. Please be careful before continue execution. To aboart press ctrl-Z"

echo "\n Press enter to continue... To aboart press ctrl-Z \n"
read a
clear

echo " Have you taken backup of your system. To cancel mintupdate execution and proceed with backup press ctrl-Z"

echo "\n Press enter to continue... To aboart press ctrl-Z \n"
read a
clear

notify-send "Mintupgrade Checking "

mintupgrade check

echo "\n Press enter to continue... To aboart press ctrl-Z \n"
read a
clear

notify-send "Mintupgrade download starting "

mintupgrade download

echo " Important :: Mint is going to upgrade now. Below step is not reversible. Please press ctrl-Z if you want to abort"

echo "\n Press enter to continue... To aboart press ctrl-Z \n"
read a
clear

sleep 100

notify-send "Important :: Mint is going to upgrade now. Below step is not reversible. Please press ctrl-Z if you want to abort "'

mintupgrade upgrade

notify-send "Mintupgrade processing "'

exit




