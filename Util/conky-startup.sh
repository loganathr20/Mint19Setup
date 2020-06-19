killall conky
sleep 10s

cd "/home/lraja/.conky/CPUPanel"
conky -c "/home/lraja/.conky/CPUPanel/CPUPanel - 4 Core CPU" &
cd "/home/lraja/.conky/Conky Seamod"
conky -c "/home/lraja/.conky/Conky Seamod/conky_seamod" &
cd "/home/lraja/.conky/Gotham"
conky -c "/home/lraja/.conky/Gotham/Gotham" &



