# renew_cert
## 判断Let's Encrypt证书日期是否大于50天，若大于50天自动更新。
```
acme.sh --issue -d abcgogo.com --dns dns_dp 
```
Apache 服务器安装letsencrypt SSL证书如下：:
```
acme.sh --install-cert -d wzfou.com \
--key-file       /path/to/keyfile/in/apache/key.pem  \
--fullchain-file /path/to/fullchain/certfile/apache/fullchain.pem \
--reloadcmd     "service apache2 force-reload"
或者--reloadcmd     "/etc/init.d/httpd force-reload"
```
Nginx 服务器安装letsencrypt SSL证书:
```
acme.sh --install-cert -d wzfou.com \
--key-file       /path/to/keyfile/in/nginx/key.pem  \
--fullchain-file /path/to/fullchain/nginx/cert.pem \
--reloadcmd     "service nginx force-reload"
```
这里用的是 service nginx force-reload, 不是 service nginx reload, 据测试, reload 并不会重新加载证书, 所以用的 force-reload,Nginx 的配置 ssl_certificate 使用 /etc/nginx/ssl/fullchain.cer ，而非 /etc/nginx/ssl/<domain>.cer ，否则 SSL Labs 的测试会报 Chain issues Incomplete 错误。
如果你发现letsencrypt SSL证书不能定时更新，你也可以自己手动强制更新:
```
acme.sh --renew -d abcgogo.com --force
```
如果是ECC cert，使用以下命令:
```
acme.sh --renew -d abcgogo.com --force --ecc
```
另外的定时方式
```
rewcrt() {
seconds=$((50*24*3600))
for i in {1..10}
do
	/bin/bash ~/rewcrt_50.sh  > /dev/null 2>&1
	sleep ${seconds}
done 
}
rewcrt
```
