#!/bin/bash

if [ "`id -u`" != 0 ];then
	echo 'SB：请使用root用户执行脚本'
	exit
fi
if [ ! -f "/etc/redhat-release" ];then
    apt install git curl -y
else 
    yum install git curl -y
	systemctl stop firewalld
	systemctl disable firewalld
	setenforce 0
	echo 'SELINUX=disabled'>/etc/selinux/config
fi
if [ "$?" != '0' ];then
	echo 'SB：git curl安装失败，请手动安装成功后再次执行'
	exit
fi
cd /root
#如果已经对接过soga，存在/root/soga，则跳过git步骤
if [ ! -d "/root/soga" ];then
	git clone -b soga https://github.com/GouGoGoal/v2ray
	mv v2ray soga
	cd soga
	chmod +x soga
	mv soga.service /etc/systemd/system/
	mv soga@.service /etc/systemd/system/
else 
	cd soga
fi
if [ ! "`echo $*|grep node_id|grep webapi_url|grep webapi_mukey`" ];then
	echo 'SB：必须参数不全，请修正后重新执行'
	exit
fi
#先循环一次，将带有-的参数进行配置
for i in $*
do
	if [ "${i:0:1}" == '-' ];then 
		i=${i:1}
		A=`echo $i|awk -F '=' '{print $1}'`
		case $A in 
		conf)
			B=`echo $i|awk -F '=' '{print $2}'`
			rm -f $B.conf
			cp example.conf $B.conf
			conf=$B.conf
		;;
		shield)
			if [ ! -f "/etc/rc.local" ];then 
				echo '#!/bin/bash' >/etc/rc.local
			fi
			if [ ! "`cat /etc/rc.local|grep soga.sprov.xyz`" ];then 
				iptables -A OUTPUT -m string --string 'soga.sprov.xyz' --algo bm --to 65535 -j DROP
				echo "iptables -A OUTPUT -m string --string 'soga.sprov.xyz' --algo bm --to 65535 -j DROP" >>/etc/rc.local
				chmod +x /etc/rc.local
			fi
			;;
		tls)
			if [ ! "`grep /root/soga /etc/crontab`" ];then
				echo "#定时从github上更新tls证书
50 5 * * 1 root wget -N --no-check-certificate -P /root/soga https://raw.githubusercontent.com/GouGoGoal/v2ray/soga/full_chain.pem 
50 5 * * 1 root wget -N --no-check-certificate -P /root/soga https://raw.githubusercontent.com/GouGoGoal/v2ray/soga/private.key">>/etc/crontab
			fi
		;;
		esac
	fi
done

#如果没有指定-conf，则默认为systemctl status soga
if [ ! "$conf" ];then 
	rm -f soga.conf
	cp example.conf soga.conf
	conf=soga.conf
fi
#再循环一次，将不带-的参数的配置进行替换
for i in $*
do
	if [ "${i:0:1}" == "-" ];then continue;fi
	A=`echo $i|awk -F '=' '{print $1}'`
	#防傻逼
	if [ "$A" == 'node_id' -o "$A" == 'webapi_url' -o "$A" == 'webapi_mukey' ];then 
		if [ ! "`echo $i|awk -F '=' '{print $2}'`" ];then 
			echo "SB：必须参数$A未填写，请修正后重新执行"
			rm -f $conf
			exit
		fi
	fi
	sed -i "s|^$A.*|$i|g" $conf
done

if [ "$conf" == 'soga.conf' ];then 
	systemctl daemon-reload
	systemctl enable soga
	systemctl restart soga
	echo '部署完毕，等待5秒将显示服务状态'
	sleep 5
	systemctl status soga
else 
	conf=`echo $conf|awk -F '.' '{print $1}'`
	systemctl daemon-reload
	systemctl enable soga@$conf
	systemctl restart soga@$conf
	echo '部署完毕，等待5秒将显示服务状态'
	sleep 5
	systemctl status soga@$conf
fi





