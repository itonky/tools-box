echo ""
echo "Setting timezone..."
echo " "

rm -rf /etc/localtime
ln -sf /usr/share/zoneinfo/Asia/Hong_Kong /etc/localtime
ntpdate -u pool.ntp.org

yum install epel-release wget curl vim firewalld -y
echo ""
echo "add nginx repo..."
echo " "
cat > /etc/yum.repos.d/nginx.repo<<-EOF
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/7/\$basearch/
gpgcheck=0
enabled=1
EOF

echo ""
echo "add mysql and php repo..."
echo " "

rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm

yum update -y

for packages in make cmake gcc gcc-c++ gcc-g77 flex bison file libtool libtool-libs autoconf kernel-devel patch wget crontabs libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel libxml2 libxml2-devel zlib zlib-devel glib2 glib2-devel unzip tar bzip2 bzip2-devel libzip-devel libevent libevent-devel ncurses ncurses-devel curl curl-devel libcurl libcurl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel vim-minimal gettext gettext-devel ncurses-devel gmp-devel pspell-devel unzip libcap diffutils ca-certificates net-tools libc-client-devel psmisc libXpm-devel git-core c-ares-devel libicu-devel libxslt libxslt-devel xz expat-devel libaio-devel rpcgen libtirpc-devel perl;
do yum -y install $packages; done

yum install  libevent libevent-devel mcrypt libmcrypt mhash -y
 
echo ""
echo "installing lnmp..."
echo " "

yum install nginx php55w php55w-devel php55w-fpm php55w-mysql php55w-common php55w-devel php55w-curl php55w-gd libjpeg* php55w-ldap php55w-odbc php55w-pear php55w-mbstring php55w-xml php55w-xmlrpc php55w-mhash php55w-pecl-zip php55w-pdo php55w-json mysql-community-server php55w-cli  php55w-mcrypt php55w-opcache php55w-pecl-apcu php55w-pecl-xdebug php55w-bcmath -y

sed -i 's/;listen.owner = nobody/listen.owner = nobody/g' /etc/php-fpm.d/www.conf
sed -i 's/;listen.group = nobody/listen.group = nobody/g' /etc/php-fpm.d/www.conf

sed -i 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf

sed -i 's/#gzip  on;/gzip  on;/g' /etc/nginx/nginx.conf

mkdir -p /home/wwwroot
chown -R nginx:nginx /home/wwwroot

cat > /etc/nginx/conf.d/www.conf<<-EOF
server {
    listen       80;
    server_name  localhost;
    root   /home/wwwroot;
    index  index.php index.html;

    location ~ \.php$ {
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  /home/wwwroot\$fastcgi_script_name;
        include        fastcgi_params;
    }
}
EOF

cat > /home/wwwroot/index.php<<-EOF
<?php
	phpinfo();
?>
EOF

mv -f /etc/nginx/conf.d/www.conf /etc/nginx/conf.d/default.conf

firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
firewall-cmd --zone=public --add-port=3306/tcp --permanent
firewall-cmd --zone=public --add-port=9000/tcp --permanent

firewall-cmd --reload

systemctl enable nginx

systemctl start nginx

systemctl enable php-fpm

systemctl start php-fpm

ifconfig

cat >>/etc/security/limits.conf<<eof
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
eof

echo "fs.file-max=65535" >> /etc/sysctl.conf
