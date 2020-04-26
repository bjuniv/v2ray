#!/bin/bash

#安装工具，克隆代码
apt update
apt install git -y
cd /root
git clone -b master https://github.com/GouGoGoal/v2ray
cd v2ray
chmod 755 v2ray v2ctl *.sh
rm -rf  README.md setup.sh 常用配置 .git*
#更改对接nodeid
sed -i "s/id_value/$1/g" config.json

#更改开机自启
if [ ! -f "/etc/rc.local" ]; then
    echo '#!/bin/sh -e
    bash /root/v2ray/ban.sh
    exit 0' >/etc/rc.local
    chmod +x /etc/rc.local
    systemctl restart rc.local
else 
    sed -i '$i\bash /root/v2ray/ban.sh' /etc/rc.local
fi

#开机自启服务
mv -f v2ray.service /etc/systemd/system/
systemctl enable v2ray
systemctl restart v2ray
#安装caddy
bash /root/v2ray/Caddy/caddy.sh

