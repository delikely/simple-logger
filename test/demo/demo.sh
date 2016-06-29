#! /bin/sh
#record some information
# configuration
LOG4SH_CONFIGURATION='none' . ../log4sh
log4sh_resetConfiguration

# set the global logging level to INFO
logger_setLevel INFO

# add and configure a FileAppender that outputs to STDERR, and activate the
# configuration
logger_addAppender R
appender_setType R RollingFileAppender
appender_file_setFile R 'file.log'
appender_file_setMaxFileSize R 10KB
appender_file_setMaxBackupIndex R 1
appender_activateOptions R
#记录系统启动记录
log_Boot()
{
	#who -b 命令获取系统boot时间
	boot_time=`who -b`
	logger_info $boot_time
}

#记录用户登录和注销信息
log_InOrOut()
{
	#判断who.old是否为空
	if [ ! -s who.old ];then
		who > who.old
		echo "empty"
	fi
	who > who.new
	#判断是否用用户登录或者注册
    who_diff=`diff who.old who.new`
    if test $? -eq 1;then
    	old_user_num=`echo $who_diff | cut -c 1,1 `
		new_user_num=`echo $who_diff | cut -c 3,3 `
		#echo $old_user_num,$new_user_num
		#用户登录信息 通过diff中的用户数判断
    	if [ $old_user_num -lt $new_user_num ];then
			#${varible##*string} 从左向右截取最后一个string后的字符串 
			who_diff="Log In:"${who_diff##*>} 
   		fi
		#用户登出信息 通过diff中的用户数判断
    	if [ $old_user_num -gt $new_user_num ];then
			#${varible##*string} 从左向右截取最后一个string后的字符串 
			who_diff="Log Out:"${who_diff##*<} 
   		fi
	    #other 短时间内登出的用户等于登录的用户 不能通过用户数判断的情况	
    	if [ $old_user_num -eq $new_user_num ];then
			who_diff="Log Other:"${who_diff}  
   		fi
    	#echo $who_diff
        logger_info `date -u`' | '$who_diff
		#更新who.old
		cat who.new > who.old
    fi  
}

#服务状态切换记录
log_Service()
{
	if [ ! -s service.old ];then
		service --status-all > service.old
	fi
	service --status-all > service.new
	service_diff=`diff service.old  service.new`
	if [ $? -eq 1 ];then
		#获取< >间的字符串
		dif=`echo $service_diff | awk -F"< | >" '{print $2}'`
		#提取服务状态 +（开启） -(关闭) 
		status=`echo $dif |cut -c 3,3`
		if [ "$status"x = "-"x ];then
			message="Service: "`echo $dif |cut -d" " -f4`" active(running)"
			elif [ "$status"x = "+"x ];then
				message="Service: "`echo $dif |cut -d" " -f4`" inactive(dead)"
		fi
		logger_info `date -u`' | '$message
		cat service.new > service.old
	fi
}

#检测资源占用率
detect_Use_Ratio()
{
	#磁盘
	disk1=/dev/sda1
	#获取磁盘占用率
	disk_Used_Rate=$(df -h | grep $disk1 | awk '{print $5}')
	#删除最后一位% 获得占用比数值
    disk_Used_Rate=${disk_Used_Rate%?}
	#添加记录标志
	flag=0;
	#判断是否需要记录
	#判断占用率记录文件是否记录有所有的数据 通过行数判断
	num=`cat use_ratio.old | wc -l`
#	logger_info `date -u`' | '$num'111111111111'
	if [ $num -eq 0 ];then
		`echo $disk_Used_Rate > use_ratio.old`
		disk_Used_Rate_old=`head -n 1 use_ratio.old`
		flag=1;
	else
		disk_Used_Rate_old=`head -n 1 use_ratio.old`
		if [ "$disk_Used_Rate_old"x != "$disk_Used_Rate"x ];then
			flag=1;
		fi
	fi
	#flag=1 添加日志
	if [ $flag -eq 1 ];then
		if [ $disk_Used_Rate -gt 95 ];then
			logger_fatal `date -u`' | ''/dev/sda usage ratio byond 95%,now is '$disk_Used_Rate'%'
		elif [ $disk_Used_Rate -gt 30 ];then
			logger_warn `date -u`' | ''/dev/sda usage ratio byond 30%,now is '$disk_Used_Rate'%'
		fi
	#更新磁盘占用率记录
#	sed -e "1c/$disk_Used_Rate" use_ratio.old >.use_ratio.old.tmp
#	cat .use_ratio.old.tmp > use_ratio.old
	`sed -i "1s/$disk_Used_Rate_old/$disk_Used_Rate/" use_ratio.old`
 	fi

	#内存
 	flag=0;
	num=`cat use_ratio.old | wc -l`;
##	logger_info `date -u`' | '$num'2222222222222222'
	memory=$(cat /proc/meminfo | awk '{print $2}')
	total=$(echo $memory | awk '{print $1}')
	free=$(echo $memory | awk '{print $2}')
	#内存占用率计算
    memory_Used_Rate=`awk 'BEGIN{printf "%.2f\n",'$free'/'$total'*100}'|cut -d'.' -f1`
	if [ $num -eq 1 ];then
		`echo $memory_Used_Rate >> use_ratio.old`
		memory_Used_Rate_old=`head -n 2 use_ratio.old | tail -n 1`
		flag=1;
	else
		memory_Used_Rate_old=`head -n 2 use_ratio.old | tail -n 1`
		if [ "$memory_Used_Rate_old"x != "$memory_Used_Rate"x ];then
			flag=1;
		fi
	fi
	#flag=1 添加日志
	if [ $flag -eq 1 ];then
		if [ $memory_Used_Rate -gt 90 ];then
			logger_fatal `date -u`' | ''Memory usage ratio byond 90%,now is '$memory_Used_Rate'%'
		elif [ $memory_Used_Rate -gt 70 ];then
			logger_warn `date -u`' | ''Memory usage ratio byond 70%,now is '$memory_Used_Rate'%'
		fi
	#更新内存占用率记录
	#sed -e "2c/$memory_Used_Rate" use_ratio.old >.use_ratio.old.tmp
	#cat .use_ratio.old.tmp > use_ratio.old
	`sed -i "2s/$memory_Used_Rate_old/$memory_Used_Rate/" use_ratio.old`
	fi
	
	#CPU
	flag=0;
	num=`cat use_ratio.old | wc -l`
#	logger_info `date -u`' | '$num'33333333333333333333'
	#计算CPU占用率
	cpu_Used_Rate=`awk '$0 ~/cpu[ ]/' /proc/stat| awk '{total=$2+$3+$4+$5+$6+$7+$8;free=$5;print (total-free)/total*100"%"}'|cut -d'.' -f1`
	if [ $num -eq 2 ];then
		`echo $cpu_Used_Rate >> use_ratio.old`
		cpu_Used_Rate_old=`head -n 3 use_ratio.old | tail -n 1`
		flag=1;
	else
		cpu_Used_Rate_old=`head -n 3 use_ratio.old | tail -n 1`
		if [ "$cpu_Used_Rate_old"x != "$cpu_Used_Rate"x ];then
			flag=1;
		fi
	fi
	#flag=1 添加日志
	if [ $flag -eq 1 ];then
		if [ $cpu_Used_Rate -gt 90 ];then
			logger_warn `date -u`' | ''CPU usage ratio byond 90%,now is '$cpu_Used_Rate'%'
		elif [ $cpu_Used_Rate -gt 5 ];then
			logger_warn `date -u`' | ''CPU usage ratio byond 5%,now is '$cpu_Used_Rate'%'
		fi
	#更新CPU占用率记录
	#sed -e "3c/$cpu_Used_Rate" use_ratio.old >.use_ratio.old.tmp
	#cat .use_ratio.old.tmp > use_ratio.old
	`sed -i "3s/$cpu_Used_Rate_old/$cpu_Used_Rate/" use_ratio.old`
	fi
}


#主体
logger_info "----------------------------------------"
log_Boot;

while test 1 -eq 1;
do
	log_InOrOut;
	log_Service;
	detect_Use_Ratio;
done

