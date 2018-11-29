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
#dspod id
check_ok || export DP_Id="70005"
#your key
echo $DP_Key
check_ok || export DP_Key="9355222224a6332112121264a70e201e0a"
cd ~
acme_f=~/acme.sh/acme.sh
if [ -e $acme_f ]
then
   echo "$acme_f is exist."
else
   echo "$acme_f is not exist"
   git clone https://github.com/Neilpang/acme.sh.git
   check_ok
   cd ./acme.sh
   ./acme.sh
fi
#[[ -e ~/acme.sh/acme.sh ]] || git clone https://github.com/Neilpang/acme.sh.git
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
if [[ $S -gt $t ]];then
	echo "Time is more than 50 days,cert will be update"
	acme.sh --renew -d abcgogo.com --force --ecc
	acme.sh --installcert  -d abcgogo.com --key-file /mnt/software/ssl/abcgogo.com.key --fullchain-file /mnt/software/ssl/fullchain.cer
else
	echo "Time is less then 50 days,don't need update cert"
fi
}
renew_50d
#添加自动任务,每周3执行任务。
if [ ! -e /var/spool/cron/ ];then
mkdir -p /var/spool/cron/
fi
if [[ `grep -v '^\s*#' /var/spool/cron/root | grep -c 'rewcrt_50.sh'` -eq 0 ]];then
echo "* 3 * * * /bin/bash ~/rewcrt_50.sh >> /var/log/le-dnspod.log 2>&1 " >> /var/spool/cron/`whoami`
fi
