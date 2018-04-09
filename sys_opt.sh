#!/bin/sh
#by lufeng @20180403
#实现centos6.*操作系统的优化


##set env###########
export PATH=$PATH:/bin:/sbin:/usr/bin
####################

##require root to run this script
if [ "$UID" -ne "0" ]; then
	echo "please run this script by root!"
	exit 1
fi

##difine cmd var
SERVICE=`which service`
CHKCONFIG=`which chkconfig`

##配置yum源
function mod_yum(){
	#modify yum path
	if [ -e /etc/yum.repos.d/Centos-Base.repo ]; then
		mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak&&\
		wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
	fi
}

##关闭selinux
function close_selinx(){
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/chkconfig
	setenforce 0 &>/dev/null
	getenforce
}

##关闭防火墙
function close_iptables(){
	/etc/init.d/iptables stop
	/etc/init.d/iptables stop
	chkconfig iptables off
}

##仅开启五个最基本的服务
function least_service(){
	for service_name in `chkconfig --list|grep 3:on |awk '{print $1}'`; do
		chkconfig --level 3 $service_name off
	done
	for service_to_on in crond network rsyslog sshd sysstat;do
		chkconfig --level 3 $service_to_on on
	done
}

##添加用户
function adduser(){
	#add lufeng and sudo
	if [ `grep -w lufeng /etc/passwd|wc -l` -lt 1 ]
	then
		useradd lufeng
		echo 199429|passwd ---stdin lufeng
		cp /etc/sudoers /etc/sudoers.ori
		echo "lufeng ALL=(ALL) NOPASSWD: ALL " >>/etc/sudoers
		tail -1 /etc/sudoers
		visudo -c &>/dev/null
	fi
}


##字符集设置
function char_set(){
	cp /etc/sysconfig/i18n /etc/sysconfig/i18n.ori
	echo 'LANG="zh_CN.UTF-8"' >/etc/sysconfig/i18n
	source $LANG
}


##设置时间同步
function time_sync(){
	cron=/var/spool/cron/root
	if [ `grep -W "ntpdate" $cron|wc -l` -lt 1 ];then
		echo '#time sync by lufeng @2018' >>$cron
		echo '*/5 * * * * /usr/sbin/ntpdate time.nist.gov &>/dev/null' >>$cron
		crontab -l
	fi
}

##设置ulimit
function open_file_set(){
	if [ `grep 65535 /etc/security/limits.conf|wc -l` -lt 1 ]; then
		#statements
		echo '*       -    nofile      65535' >>/etc/security/limits.conf
		tail -1 /etc/security/limits.conf
	fi
}

#设置内核参数
function set_kernel(){
	#kernel set
	if [ `grep kernel_flag /etc/sysctl.conf|wc -l` -lt 1 ]
	then 
		cat >>/etc/sysctl.conf<<EOF
		#kernel_flag
		net.ipv4.tcp_syn_retries = 1
		net.ipv4.tcp_synack_retries = 1
		net.ipv4.tcp_keepalive_time = 600
		net.ipv4.tcp_keepalive_probes = 3
		net.ipv4.tcp_keepalive_intvl =15
		net.ipv4.tcp_retries2 = 5
		net.ipv4.tcp_fin_timeout = 2
		net.ipv4.tcp_max_tw_buckets = 36000
		net.ipv4.tcp_tw_recycle = 1
		net.ipv4.tcp_tw_reuse = 1
		net.ipv4.tcp_max_orphans = 32768
		net.ipv4.tcp_syncookies = 1
		net.ipv4.tcp_max_syn_backlog = 16384
		net.ipv4.tcp_wmem = 8192 131072 16777216
		net.ipv4.tcp_rmem = 32768 131072 16777216
		net.ipv4.tcp_mem = 786432 1048576 1572864
		net.ipv4.ip_local_port_range = 1024 65000
		net.ipv4.ip_conntrack_max = 65536
		net.ipv4.netfilter.ip_conntrack_max=65536
		net.ipv4.netfilter.ip_conntrack_tcp_timeout_established=180
		net.core.somaxconn = 16384
		net.core.netdev_max_backlog = 16384
EOF
		sysctl -p
	fi
}

function update_linux(){
	if [ `rpm -qa lrzsz nmap tree dos2unix nc |wc -l ` -le 5 ]
		then
		yum install -y  lrzsz nmap tree dos2unix nc
	fi
}


main(){
	mod_yum
	close_iptables
	close_selinx
	least_service
	adduser
	char_set
	time_sync
	open_file_set
	set_kernel
	update_linux

}

main

