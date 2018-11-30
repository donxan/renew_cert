#!/bin/bash
BASE_ROOT=$HOME
# date time
DATE_TIME=`date +%Y%m%d%H%M%S`
# base crt path
CRT_BASE_PATH="/usr/syno/etc/certificate"
#CRT_BASE_PATH="/Users/carl/Downloads/certificate"
ACME_BIN_PATH=${BASE_ROOT}/.acme.sh
TEMP_PATH=${BASE_ROOT}/temp
#CRT_PATH_NAME=`cat ${CRT_BASE_PATH}/_archive/DEFAULT`
#CRT_PATH=${CRT_BASE_PATH}/_archive/${CRT_PATH_NAME}

installAcme() {
  echo 'begin installAcme'
  cd ~
  acme_f=${BASE_ROOT}/.acme.sh/acme.sh
  if [ -e $acme_f ]
  then
      echo "$acme_f is exist."
  else
        echo "$acme_f is not exist"
        git clone https://github.com/Neilpang/acme.sh.git
        cd ./acme.sh
       ./acme.sh --install
  fi
  echo 'done installAcme'
  return 0
}

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
  ${ACME_BIN_PATH}/acme.sh --renew -d abcgogo.com --force --ecc
  echo "begin install cert for nas"
  for nas_cert_path in `find /usr/syno/etc/certificate/ -name "fullchain.pem" | xargs -i ls -d {} | awk -F 'fullchain.pem' '{print $1}'`
    do
	     ${ACME_BIN_PATH}/acme.sh --installcert -d ${DOMAIN} -d *.${DOMAIN} \
		      --certpath ${nas_cert_path}/cert.pem \
			  --key-file ${nas_cert_path}/privkey.pem \
			  --fullchain-file ${nas_cert_path}/fullchain.pem --ecc
  done
  reloadWebService
  ${ACME_BIN_PATH}/acme.sh --installcert -d ${DOMAIN} -d *.${DOMAIN} \
    --certpath ${gitlab_CRT_PATH}/cert.pem \
    --key-file ${gitlab_CRT_PATH}/privkey.key \
    --fullchain-file ${gitlab_CRT_PATH}/fullchain.pem --ecc
else
  echo "Time is less then 50 days,don't need update cert"
fi
}

generateCrt () {
  echo 'begin generateCrt'
  cd ${BASE_ROOT}
  source /volume1/test/syno-acme/config
  echo 'begin updating default cert by acme.sh tool'
  installAcme
  source ${ACME_BIN_PATH}/acme.sh.env
  [[ -d ~/.acme.sh/abcgogo.com_ecc ]] || ${ACME_BIN_PATH}/acme.sh --issue --dns ${DNS} --dnssleep ${DNS_SLEEP} -d "${DOMAIN}" -d "*.${DOMAIN}" --keylength ec-256
  renew_50d
  cd -
  echo 'done generateCrt'
  return 0
}

updateService () {
  echo 'begin updateService'
  echo 'cp cert path to des'
  /bin/python2 ${BASE_ROOT}/crt_cp.py ${CRT_PATH_NAME}
  echo 'done updateService'
}

reloadWebService () {
  echo 'begin reloadWebService'
  echo 'reloading new cert...'
  /usr/syno/etc/rc.sysv/nginx.sh reload
  echo 'done reloadWebService'  
}
backupCrt () {
  echo 'begin backupCrt'
  BACKUP_PATH=${BASE_ROOT}/backup/${DATE_TIME}
  mkdir -p ${BACKUP_PATH}
  cp -r ${CRT_BASE_PATH} ${BACKUP_PATH}
  echo ${BACKUP_PATH} > ${BASE_ROOT}/backup/latest
  echo 'done backupCrt'
  return 0
}
updateCrt () {
  echo '------ begin updateCrt ------'
  backupCrt
  generateCrt
  echo '------ end updateCrt ------'
}

case "$1" in
  generateCrt)
    echo "begin generate cert"
    generateCrt
    ;;
  update)
    echo "begin update cert"
    updateCrt
    ;;

  revert)
    echo "begin revert"
      revertCrt $2
      ;;

    *)
        echo "Usage: $0 {generateCrt|update|revert}"
        exit 1
esac
