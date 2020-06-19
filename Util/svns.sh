
clear  

sh /home/lraja/csvn/bin/csvn stop  
# sudo fuser -k 18080/tcp

sleep 20 

echo " \n"

sh /home/lraja/csvn/bin/csvn start

echo " ________________________________________________________ "
echo " \n"

echo " Current Running Status of csvn "
echo " \n"

sh /home/lraja/csvn/bin/csvn status

echo " \n"

echo "csvn Console URL \n"
echo "http://localhost:3343/csvn/"
echo " \n"
echo " ________________________________________________________ "



