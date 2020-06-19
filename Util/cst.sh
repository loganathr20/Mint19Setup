#!/bin/bash

clear  

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
echo " \n"

echo "tomcat status"

sudo systemctl status tomcat

echo " ________________________________________________________ "
echo " \n"


echo " jenkins status "
echo " \n"

"sudo systemctl status jenkins"

echo " ________________________________________________________ "
echo " \n"

