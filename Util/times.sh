
#!/bin/bash
times=0

while true;do
used=`free -m |awk 'NR==3 {print $3}'`
total=`free -m |awk 'NR==2 {print $2}'`
result=`echo "$used / $total" |bc -l`
result2=`echo "$result > 0.8" |bc`
# result2=1
# times=6


if [ $result2 -eq 1 ];then
        let times+=1
        if [ $times -gt 5 ];then
              echo "more than 80% of ram used"
              times=0
              echo "You are login as: `whoami`" 
              echo "`sudo sh /home/lraja/Util/cpu_info.sh`"
              echo "`sudo sh /home/lraja/Util/clear_swap.sh`" 
        fi
else
        times=0
fi

sleep 5
done

