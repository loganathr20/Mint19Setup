
#!/bin/sh
## This script monitors a system named dxi4.
## Date created : May 15 1997
  
rm status.dxi4
echo '' > status.dxi4
echo '         ****************************************************' >> status.d
xi4
echo '         *************** LATEST DXI4 STATUS *****************' >> status.d
xi4
echo '         ****************************************************' >> status.d
xi4
echo '' >> status.dxi4
echo '         ***************        DATE        *****************' >> status.d
xi4
echo '' >> status.dxi4
date >> status.dxi4
echo '' >> status.dxi4
 
banner Netstat >> status.dxi4
echo '' >> status.dxi4
netstat -m >> status.dxi4
echo '' >> status.dxi4
banner Fax >> status.dxi4
echo '' >> status.dxi4
fxstat >> status.dxi4
echo '' >> status.dxi4
echo '         ****************************************************' >> status.d
xi4
banner Disk >> status.dxi4
echo '' >> status.dxi4
df >> status.dxi4
echo '' >> status.dxi4
 
echo '         *******************Virtual Memory ******************' >> status.d
xi4
sar >> status.dxi4
 
banner Paging >> status.dxi4
sar -p >> status.dxi4
echo '         *******************free virtual memory *************' >> status.d
xi4
sar -r >> status.dxi4
echo '         ****************************************************' >> status.d
xi4
echo '         ******************* Processes  *********************' >> status.d
xi4
echo '         *************   All rtm processes   ****************' >> status.d
xi4
echo '' >> status.dxi4
ps -ef | grep 'rtm' >> status.dxi4
 
echo '' >> status.dxi4
echo '         *************  All dbsid processes  ****************' >> status.d
xi4
echo '         **Check that synchronization is only one per site **' >> status.d
xi4
echo '' >> status.dxi4
ps -ef | grep 'dbsid' >> status.dxi4
echo '' >> status.dxi4
echo '         *************   All pws processes   ****************' >> status.d
xi4
echo '' >> status.dxi4
ps -ef | grep 'pws' >> status.dxi4
echo '' >> status.dxi4
echo '         *************   All sql processes   ****************' >> status.d
xi4
echo '' >> status.dxi4
ps -ef | grep 'sql' >> status.dxi4
echo '' >> status.dxi4
echo '         ****************************************************' >> status.d
xi4
echo '' >> status.dxi4
echo '         ****************** System Error Report *************' >> status.d
xi4
echo '' >> status.dxi4
tail -500 /usr/adm/messages >> status.dxi4
echo '' >> status.dxi4
 
echo '       ********************* Top Will now run **************************'
>> status.dxi4
more status.dxi4
 
top



