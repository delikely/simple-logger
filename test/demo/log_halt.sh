#!/bin/bash
#
#关机前执行此脚本 清空who.old service.old
#
LOG4SH_CONFIGURATION='none' . /root/log/test/log4sh
log4sh_resetConfiguration
logger_setLevel INFO
logger_addAppender R
appender_setType R RollingFileAppender
appender_file_setFile R '/root/log/test/demo/logout.log'
appender_file_setMaxFileSize R 10KB
appender_file_setMaxBackupIndex R 1
appender_activateOptions R
thread=`ps aux|grep demo|wc -l`
if [  $thread -eq 1  ];then
	`cat /dev/null > /root/log/test/demo/who.old`
	`cat /dev/null > /root/log/test/demo/service.old`
	`cat /dev/null > /root/log/test/demo/use_ratio.old`
	date=`date -u`
	logger_info  $date' | '' who.old service.old is  cleaned'
fi

#usage
#cp log_halt.sh /etc/init.d/log-halt
#update-rc.d log-halt stop 20 0 6
