

#!/bin/bash
while :
    do
        if ping -c 1 www.google.com &> /dev/null
        then
        echo "Google is online"
        break
        fi
    sleep 10
done
