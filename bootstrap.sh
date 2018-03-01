#!/bin/sh

# Change the ip by your own IP adress 
USER="pi"
HOST="monip.org"
PORT=3000

# Update 
apt update -y && apt upgrade -y

# Install soft
apt install rtorrent git sshfs apache2 php unzip unrar-free mediainfo ffmpeg sox curl -y

# Configure apache
a2dissite 000-default.conf
a2enssite default-ssl.conf
service apache2 reload

# PASTE YOUR OWN PRIVATE KEY HERE !! FOLLOW THE SAME LOGIC !!
echo "-----BEGIN RSA PRIVATE KEY-----" > /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" >> /home/admin/.ssh/id_rsa
echo "-----END RSA PRIVATE KEY-----" >> /home/admin/.ssh/id_rsa
# END PASTE OF YOUR PRIVATE KEY 

chown admin:admin /home/admin/.ssh/id_rsa
chmod o-r /home/admin/.ssh/id_rsa
chmod g-r /home/admin/.ssh/id_rsa

# Create the folder of rTorrent
mkdir -p /srv/rtorrent/downloading
mkdir /srv/rtorrent/finish
chown -R admin. /srv/rtorrent

# mount the SSH folder by allowing the other guys and specify his UID/GID
sshfs $USER@$HOST:/srv/datas /srv/rtorrent/finish -o IdentityFile=/home/admin/.ssh/id_rsa,Port=$PORT,allow_other,StrictHostKeyChecking=no
mkdir /srv/rtorrent/finish/.sessions
rm /srv/rtorrent/finish/.sessions/rtorrent.lock

# Configure settings of rTorrent
echo "download_rate = 0" >> /home/admin/.rtorrent.rc
echo "upload_rate = 10000" >> /home/admin/.rtorrent.rc
echo "" >> /home/admin/.rtorrent.rc
echo "max_downloads_global = 2" >> /home/admin/.rtorrent.rc
echo "" >> /home/admin/.rtorrent.rc
echo "max_peers = 0" >> /home/admin/.rtorrent.rc
echo "max_uploads = 0" >> /home/admin/.rtorrent.rc
echo "" >> /home/admin/.rtorrent.rc
echo "directory = /srv/rtorrent/downloading" >> /home/admin/.rtorrent.rc
echo "session = /srv/rtorrent/finish/.sessions" >> /home/admin/.rtorrent.rc
echo "" >> /home/admin/.rtorrent.rc
echo "port_range = 51413-51413" >> /home/admin/.rtorrent.rc
echo "port_random = no" >> /home/admin/.rtorrent.rc
echo "" >> /home/admin/.rtorrent.rc
echo "check_hash = no" >> /home/admin/.rtorrent.rc
echo "" >> /home/admin/.rtorrent.rc
echo "dht = auto" >> /home/admin/.rtorrent.rc
echo "dht_port = 6881" >> /home/admin/.rtorrent.rc
echo "peer_exchange = yes" >> /home/admin/.rtorrent.rc
echo "" >> /home/admin/.rtorrent.rc
echo "encryption = allow_incoming,try_outgoing,enable_retry" >> /home/admin/.rtorrent.rc
echo "" >> /home/admin/.rtorrent.rc
echo "use_udp_trackers = yes" >> /home/admin/.rtorrent.rc
echo "" >> /home/admin/.rtorrent.rc
echo "scgi_port = 127.0.0.1:5000" >> /home/admin/.rtorrent.rc
echo "" >> /home/admin/.rtorrent.rc
echo "ratio.min.set = 100" >> /home/admin/.rtorrent.rc
echo "ratio.max.set = 100" >> /home/admin/.rtorrent.rc
echo "system.method.set = group.seeding.ratio.command, d.close=" >> /home/admin/.rtorrent.rc
chown admin. /home/admin/.rtorrent.rc

# Configure rTorrent Service
echo "[Unit]" > /etc/systemd/system/rTorrent.service
echo "Description=rTorrent" >> /etc/systemd/system/rTorrent.service
echo "After=network.target" >> /etc/systemd/system/rTorrent.service
echo "" >> /etc/systemd/system/rTorrent.service
echo "[Service]" >> /etc/systemd/system/rTorrent.service
echo "User=admin" >> /etc/systemd/system/rTorrent.service
echo "Type=forking" >> /etc/systemd/system/rTorrent.service
echo "KillMode=none" >> /etc/systemd/system/rTorrent.service
echo "ExecStart=/usr/bin/screen -d -m -fa -S admin /usr/bin/rtorrent" >> /etc/systemd/system/rTorrent.service
echo "ExecStop=/usr/bin/killall -w -s 2 /usr/bin/rtorrent" >> /etc/systemd/system/rTorrent.service
echo "WorkingDirectory=/home/admin" >> /etc/systemd/system/rTorrent.service
echo "User=admin" >> /etc/systemd/system/rTorrent.service
echo "Group=admin" >> /etc/systemd/system/rTorrent.service
echo "" >> /etc/systemd/system/rTorrent.service
echo "[Install]" >> /etc/systemd/system/rTorrent.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/rTorrent.service

# Reload Service
systemctl daemon-reload
systemctl enable rTorrent.service
systemctl start rTorrent.service

# Install/Configure ruTorrent
cd /var/www/
git clone https://github.com/Novik/ruTorrent.git
mv ruTorrent/* /var/www/html
mv ruTorrent/.* /var/www/html
chown -R www-data. /var/www

# Configure AutoTools
sed -i '/$enable_label = /c\        public $enable_label = 1;' /var/www/html/plugins/autotools/autotools.php
sed -i '/$label_template = /c\        public $label_template = "{DIR}";' /var/www/html/plugins/autotools/autotools.php
sed -i '/$enable_move = /c\        public $enable_move = 1;' /var/www/html/plugins/autotools/autotools.php
sed -i '/$path_to_finished = /c\        public $path_to_finished = "/srv/rtorrent/finish";' /var/www/html/plugins/autotools/autotools.php
sed -i '/$addLabel = /c\        public $addLabel = 1;' /var/www/html/plugins/autotools/autotools.php        
