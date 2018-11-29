#!/bin/bash

#######Begin########
echo "It will install acme."
sleep 1
##check last command is OK or not.
check_ok() {
if [ $? != 0 ]
then
    echo "Error, Check the error log."
    exit 1
fi
}
##if the packge installed ,then igore.
myum() {
if ! rpm -qa|grep -q "^$1"
then
    yum install -y $1
    check_ok
else
    echo $1 already installed.
fi
}

## install some packges.
for p in gcc wget curl git cron socat
do
    myum $p
done

echo $DP_Id
check_ok || export DP_Id="" #api id
echo $DP_Key
check_ok || export DP_Key="" #api key
cd ~
[[ -d ~/acme.sh ]] || git clone https://github.com/Neilpang/acme.sh.git
check_ok
cd ./acme.sh
./acme.sh --install
check_ok
alias | grep 'acme.sh' || alias acme.sh=~/.acme.sh/acme.sh
#注册证书
[[ -d ~/.acme.sh/abcgogo.com_ecc ]] || acme.sh --issue -d abcgogo.com -d *.abcgogo.com --dns dns_dp --keylength ec-256

#比较证书的创建日期是否大于50天，大于50天就强制更新
renew_50d() {
f=fullchain.cer
f_path=~/.acme.sh/abcgogo.com_ecc/
f_name=${f_path}${f}
a=`stat -c %Y ${f_name}`
b=`date +%s`
s=$((b-a))
t=$((50*24*3600))
if [[ $S -gt %t ]];then
	echo "Time is more than 50 days,cert will be update"
	acme.sh --renew -d abcgogo.com --force --ecc
	acme.sh --installcert  -d abcgogo.com --key-file /mnt/software/ssl/abcgogo.com.key --fullchain-file /mnt/software/ssl/fullchain.cer
else
	echo "Time is less then 50 days,don't need update cert"
fi
}
renew_50d
#acme.sh --issue -d abcgogo.com --dns dns_dp 
#Apache 服务器安装letsencrypt SSL证书如下：:
#acme.sh --install-cert -d wzfou.com \
#--key-file       /path/to/keyfile/in/apache/key.pem  \
#--fullchain-file /path/to/fullchain/certfile/apache/fullchain.pem \
#--reloadcmd     "service apache2 force-reload"
#或者--reloadcmd     "/etc/init.d/httpd force-reload"
#Nginx 服务器安装letsencrypt SSL证书e:
#acme.sh --install-cert -d wzfou.com \
#--key-file       /path/to/keyfile/in/nginx/key.pem  \
#--fullchain-file /path/to/fullchain/nginx/cert.pem \
#--reloadcmd     "service nginx force-reload"

#这里用的是 service nginx force-reload, 不是 service nginx reload, 据测试, reload 并不会重新加载证书, 所以用的 force-reload,Nginx 的配置 ssl_certificate 使用 /etc/nginx/ssl/fullchain.cer ，而非 /etc/nginx/ssl/<domain>.cer ，否则 SSL Labs 的测试会报 Chain issues Incomplete 错误。
#如果你发现letsencrypt SSL证书不能定时更新，你也可以自己手动强制更新:

#acme.sh --renew -d abcgogo.com --force
#如果是ECC cert，使用以下命令:

#acme.sh --renew -d abcgogo.com --force --ecc
#添加自动任务,每周3执行任务。
if [ ! -e /var/spool/cron/ ];then
mkdir -p /var/spool/cron/
fi
if [[ `grep -v '^\s*#' /var/spool/cron/root | grep -c 'rewcrt_50.sh'` -eq 0 ]];then
echo "* 3 * * * /bin/bash ~/rewcrt_50.sh >> /var/log/le-dnspod.log 2>&1 " >> /var/spool/cron/`whoami`
fi
rewcrt() {
seconds=$((50*24*3600))
for i in {1..10}
do
	/bin/bash ~/rewcrt_50.sh  > /dev/null 2>&1
	sleep ${seconds}
done 
}
#rewcrt
