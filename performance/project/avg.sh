sum=0
daemonNumber=`cat delete_project| wc -l`
 
number=`cat  delete_project|awk -F ":" '{printf( "%.4f\n",$2)}'| uniq -c| wc -l`
 
for a in `seq $number`
do 
	b=`cat  delete_project| awk -F ':' '{printf( "%.3f\n",$2)}'|uniq -c| awk NR==$a| awk '{print $1}'`
	c=`cat  delete_project| awk -F ':' '{printf( "%.3f\n",$2)}'|uniq -c| awk NR==$a| awk '{print $2}'`
	echo $b
	echo $c	
	c=`echo $b*$c|bc`
	sum=`echo $sum+$c|bc`
	echo $sum
done
	
Avg=`awk 'BEGIN{printf "ConductNum ""%.10f\n",('$sum'/'$daemonNumber')}'`
echo $Avg
	
