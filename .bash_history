
cd /var/www/html
cd /var/www
ls
systemctl start mongod
systemctl status mongod
systemctl enable mongod
echo "mongodb-org hold" | sudo dpkg --set-selections
echo "mongodb-org-database hold" | sudo dpkg --set-selections
echo "mongodb-org-server hold" | sudo dpkg --set-selections
echo "mongodb-mongosh hold" | sudo dpkg --set-selections
echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
echo "mongodb-org-tools hold" | sudo dpkg --set-selections
php -m
# Configure Sessions Directory Permissions
chmod 733 /var/lib/php/sessions
chmod +t /var/lib/php/sessions
# Write Systemd File For Linode
update-alternatives --set php /usr/bin/php8.1
# Install Nginx & PHP-FPM
apt-get install -y --force-yes nginx
systemctl enable nginx.service
# Generate dhparam File
openssl dhparam -out /etc/nginx/dhparams.pem 2048
# Tweak Some PHP-FPM Settings
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/8.1/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/8.1/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/8.1/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/8.1/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/8.1/fpm/php.ini
# Misc. PHP FPM Configuration
sudo sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/8.1/fpm/php.ini
# Configure FPM Pool Settings
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/8.1/fpm/pool.d/www.conf
sed -i "s/;request_terminate_timeout.*/request_terminate_timeout = 600/" /etc/php/8.1/fpm/pool.d/www.conf
sed -i "s/pm = .*/pm = static/" /etc/php/8.1/fpm/pool.d/www.conf
# Optimize FPM Processes
sed -i "s/^pm.max_children.*=.*/pm.max_children = 20/" /etc/php/8.1/fpm/pool.d/www.conf
# Configure Gzip
cat > /etc/nginx/conf.d/gzip.conf << EOF
gzip_comp_level 5;
gzip_min_length 256;
gzip_proxied any;
gzip_vary on;
gzip_http_version 1.1;

gzip_types
application/atom+xml
application/javascript
application/json
application/ld+json
application/manifest+json
application/rss+xml
application/vnd.geo+json
application/vnd.ms-fontobject
application/x-font-ttf
application/x-web-app-manifest+json
application/xhtml+xml
application/xml
font/opentype
image/bmp
image/svg+xml
image/x-icon
text/cache-manifest
text/css
text/plain
text/vcard
text/vnd.rim.location.xloc
text/vtt
text/x-component
text/x-cross-domain-policy;

EOF

cat > /etc/nginx/conf.d/cloudflare.conf << EOF
set_real_ip_from 103.21.244.0/22;
set_real_ip_from 103.22.200.0/22;
set_real_ip_from 103.31.4.0/22;
set_real_ip_from 104.16.0.0/13;
set_real_ip_from 104.24.0.0/14;
set_real_ip_from 108.162.192.0/18;
set_real_ip_from 131.0.72.0/22;
set_real_ip_from 141.101.64.0/18;
set_real_ip_from 162.158.0.0/15;
set_real_ip_from 172.64.0.0/13;
set_real_ip_from 173.245.48.0/20;
set_real_ip_from 188.114.96.0/20;
set_real_ip_from 190.93.240.0/20;
set_real_ip_from 197.234.240.0/22;
set_real_ip_from 198.41.128.0/17;
set_real_ip_from 2400:cb00::/32;
set_real_ip_from 2405:8100::/32;
set_real_ip_from 2405:b500::/32;
set_real_ip_from 2606:4700::/32;
set_real_ip_from 23:f800::/32;
set_real_ip_from 2a06:98c0::/29;
set_real_ip_from 2c0f:f248::/32;

real_ip_header X-Forwarded-For;

EOF

# Restart Nginx & PHP-FPM Services
#service nginx restart
curl --silent --location https://deb.nodesource.com/setup_18.x | bash - 
apt-get update
sudo apt-get install -y --force-yes nodejs
npm install -g pm2
npm install -g gulp
npm install -g yarn
# Install & Configure Redis Server
apt-get install -y redis-server
sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
service redis-server restart
systemctl enable redis-server
yes '' | pecl install -f redis
# Ensure PHPRedis extension is available
echo "extension=redis.so" > /etc/php/8.1/mods-available/redis.ini
# Configure Supervisor Autostart
systemctl enable supervisor.service
service supervisor start
# Disable protected_regular
sudo sed -i "s/fs.protected_regular = .*/fs.protected_regular = 0/" /usr/lib/sysctl.d/protect-links.conf
sysctl --system
# Setup Unattended Security Upgrades
apt-get install -y --force-yes unattended-upgrades
cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "Ubuntu focal-security";
};
Unattended-Upgrade::Package-Blacklist {
    //
};
EOF

cat > /etc/apt/apt.conf.d/10periodic << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

#Install laravel echo server with whisper
npm install -g laravel-echo-server-whisper
#SSL certificate, we're going to follow this https://www.inmotionhosting.com/support/website/ssl/lets-encrypt-ssl-ubuntu-with-certbot/
sudo apt install python3 python3-venv libaugeas0
sudo python3 -m venv /opt/certbot/
sudo /opt/certbot/bin/pip install --upgrade pip
sudo /opt/certbot/bin/pip install certbot certbot-nginx
sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
cd /var/www
ls
rm -rf html
git clone https://github.com/casinoscriptsshop/hitjuwa.git
ls
mc hitjuwa html
mv hitjuwa html
cd html
git remote -v
composer install
cd @web
npm install
npm run build
cd ..
cd @admin
npm install
npm run build
cd ..
touch .env
touch laravel-echo-server.json
> /etc/nginx/sites-enabled/default
nano /etc/nginx/sites-enabled/default
nginx -t
nano .env
php artisan key:generate
nano laravel-echo-servr.json
nano laravel-echo-server.json
sudo chgrp -R www-data storage bootstrap/cache
sudo chmod -R ug+rwx storage bootstrap/cache
sudo chmod -R 777 /var/www/html/public
nohup php artisan queue:work --sleep=0.01 & disown
nohup laravel-echo-server start & disown
sudo certbot --nginx -d hitjuwa.com -d www.hitjuwa.com
systemctl restart nginx
sudo certbot --nginx -d hitjuwa.com -d www.hitjuwa.com
nano /etc/nginx/sites-enabled/default
systemctl restart nginx
systemctl status nginx
sudo certbot --nginx -d hitjuwa.com -d www.hitjuwa.com
htop
sudo certbot --nginx -d hitjuwa.com -d www.hitjuwa.com
nano .env
mongosh
nohup php artisan queue:work crash --queue=crash_tick --timeout=0 --sleep=0.01 & disown
nohup php artisan queue:work crash --queue=crash_finish --tries=3 --sleep=0.01 & disown
php artisan game:chain slide
php artisan game:chain crash
mongosh
php artisan tinker
htop
cd /var/www/html
nano outes/admin.php
nano routes/admin.php
htop
ls
cd /var/www/html
ls
git log
q
ls
ls /etc/nginx/sites-available/
ls /etc/nginx/sites-available/default 
more /etc/nginx/sites-available/default 
git st
git status
git pull
git checkout  public/
git pull
ls
more .env
mongosh
git st
ls
cd /var/www/html
git st
git status
git diff
git stash
git pull
git status
git stash apply
git stash
git pull
git stash apply
vim @web/resources/js/components/modals/BannerModal.vue
cd @web/
npm run build
sudo apt update
sudo apt upgrade -y
ls
mysql
mongo
ls /etc
cat /etc/mongod.conf
mongo
mongod –version
mongod --version
mongod
ls
cd ..
ls
ls var
ls var/www/
ls var/www/html
ls var/www/html -a
cat var/www/html/.env
ls var/www/html/@sport
ls var/www/html/@sport -a
lsof -i | grep mongo
nano /etc/mongod.conf
ufw allow 27017
sudo ufw allow 27017
ufw status
systemctl restart mongod
exit
cd /var/www/html
cd storage/logs
ls
tail -500 laravel-2024-10-12.log
systemctl status mongod
systemctl start mongod
systemctl status mongod
df -h
htop
sudo chown -R mongodb:mongodb /var/lib/mongodb
sudo chown mongodb:mongodb /tmp/mongodb-27017.sock
systemctl start mongod
systemctl status mongod
htop
cd /var/www/html
ls
git pull
cd @web
npm run build
cd ..
mongosh
php artisan tinker
htop
mongosh
htop
cd @web
ls
cd resources
ls
cd js
ls
cd bootstrap.js
nano bootstrap.js
cd components
ls
cd views
ls
nano WebsiteLayout.vue
cd ../../..
cd ../..
git pull
it pull
git pull
htop
cd storagelogs
cd storage/logs
ls
nano laravel-2024-10-27.log
htop
nano laravel-2024-10-27.log
mongosh
htop
mongosh
cd ../..
ls
nano .env
htop
nano .env
ls
cd app
ls
cd Http
ls
cd Middleware
ls
nano SuperAdminAuthenticate.php
cd ../../..
nano .env
cd app/Http/Middleware
nano SuperAdminAuthenticate.php
nano AdminAuthenticate.php
cd ../..
nano .env
cd ..
nano .env
nano app/Http/Middleware
cd app/Http/Middleware
nano AdminAuthenticate.php
nano SuperAdminAuthenticate.php
htop
nano InternalMiddleware.php
nano SuperAdminAuthenticate.php
nano ModeratorAuthenticate.php
nano AdminAuthenticate.php
htop
ls
mongosh
cd ../..
cd models
cd Models
ls
nano Role.php
cd ../..
php artisan tinker
htop
mongosh
htop
cd app/CURRENCY
cd app/Currency
ls
cd Local
ls
cd ..
ls
nano Currency.php
cd ../..
php artisan tinker
htop
nano app/Games/Kernel/ThirdParty/FiversCan/FiversCan.php:
nano app/Games/Kernel/ThirdParty/FiversCan/FiversCan.php
php artisan tinker
htop
mongosh
php artisan tinker
htop
mongosh
htop
php artisan tinker
htop
git stash
git pull
cd @web
npm run build
htop
cd ..
php artisan tinker
htop
git pull
htop
git pull
cd @web
npm run build
cd ..
htop
git pul
git pull
git stash
git pull
cd @web
npm run build
cd /var/www/html
git pull
htop
git pull
htop
git pull
htop
git pull
htop
git pull
htop
git pull
htop
git pull
htop
git pull
htop
mongosh
htop
mongosh
htop
git pull
htop
git pull
htop
cd /var/www/html
mongosh
ls
mongosh
htop
cd sotrage/logs
ls
cd storage/logs
ls
nano laravel-2024-10-29.log
nano laravel-2024-10-28.log
cd /var/www/html
ls
ps aux
ls
nohup php artisan queue:work --sleep=0.01 & disown
nohup laravel-echo-server start & disown
cd mongosh
ls
nano .env
mongosh
htop
php artisan tinker
htop
mongosh
php artisan tinker
htop
mongosh
cd /var/www/html
git pull
ps aux
kill -9 74360
nohup php artisan queue:work --sleep=0.01 & disown
htop
cd /var/www/html
mongosh
htop
mongosh
htop
mongosh
htop
git pull
ps aux
kill -9 73086
nohup php artisan queue:work --sleep=0.01 & disown
htop
git pull
ps au
kill -9 74291
nohup php artisan queue:work --sleep=0.01 & disown
htop
mongosh
htop
git pull
htop
mongosh
cd /
du -shx *
cd /var/
ls -ltr
du -sxh *
cd www/
ls -ltr
cd html/
ls -ltr
cd ..
zip -r html.zip html/
cd ..
du -shx *
cd lib/
ls -ltr
du -shx *
cd mongodb/
ls -ltr
cd 
ls -ltr
mongodb
cd 
ls -ltr
cd /
ls -ltr
cd 
ls -ltr
pwd
cd 
cd /
ls -ltr
exit
cd /var/www/html/
ls -ltr
cd ..
ls -ltr
du -shx *
cd html/
ls -ltr
ls -ltra
cat .env 
ls -ltr
cat .env 
ls -ltr
ls -ltra
cat nohup.out 
ls -ltr
cat laravel-echo-server.lock 
cat laravel-echo-server.json 
ls -ltr
cat sendToken.js 
ls -ltr
cd @admin/
ls -ltr
cat jsconfig.json 
cat vite.config.js 
cd ..
cat .env 
grep DB_USERNAME *
grep -r DB_USERNAME *
grep -r DB_PASSWORD *
mongod -u homestead -p
mongo -u homestead -p secret hitjuwa
mongod -u homestead -p secret hitjuwa
sudo systemctl status redis-server.service 
cd app/
cd Models/
ls -ltr
cat User.php 
cat /etc/mongod.conf 
mongo -u admin
mono
mongod
mongodump 
ls -ltr
cd dump/
ls -ltr
cd hitjuwa/
ls -ltr
cd ..
cd admin/
ls -ltr
cd ..
cd READ__ME_TO_RECOVER_YOUR_DATA/
ls -ltr
cat README.metadata.json 
cat README.
cat README.bson 
exit
cd /var/www/html/
ls -ltr
cat .env 
historey
history
cd /var/www/html/
grep -r DB_USERNAME *
cat vendor/jenssegers/mongodb/README.md
grep -r DB_PASSWORD *
cat vendor/jenssegers/mongodb/README.md
grep -r DB_USERNAME *
grep -r DB_PASSWORD *
cat .env 
grep -r DB_PASSWORD *
cat vendor/mongodb/mongodb/CONTRIBUTING.md

grep -r DB_PASSWORD *
echo $secret
cd /var/www/html/
ls- ltr
ls -ltr
cat .env 
grep REDIS_PASSWORD *
grep -r REDIS_PASSWORD *
grep -r DB_PASSWORD *
echo $password
echo $MONGODB_PASSWORD
echo SERVERLESS_ATLAS_PASSWORD
echo $SERVERLESS_ATLAS_PASSWORD
ls -ltr
cd config/
ls -ltr
cat auth.php 
cat database.php 
cd ..
ls -ltr
cd database/
ls -ltr
cd seeders/
ls -ltr
cat DatabaseSeeder.php 
cd ..
ls -ltr
cd resources/
ls -ltr
cd cvi
cd views/
ls -ltr
cd 
mongod
mongodb
mongo
mongosh
sudo nano /etc/mongod.conf 
mongo
mongo --eval 'db.runCommand({ connectionStatus: 1 })'
mongo --version
mongod --version
mongod --auth
sudo systemctl status mongod.service 
grep -r MONGODB_CONFIG_OVERRIDE_NOFORK
sudo nano /etc/mongod.conf 
ls -ltr
cd hitjuwa.gz/
ls -ltr
cd hitjuwa/
ls -ltr
cd ..
ls -ltr
cd dump/
ls -ltr
cd hitjuwa/
ls -ltr
cd ..
ls -le
ls -ltr
pwd
cd ..
nano /etc/mongod.conf 
systemctl reload mongod.service 
systemctl reload mongod.service
systemctl reload mongod.services
systemctl status mongod.service 
cd dump/
ls -ltr
cd hitjuwa/
ls -ltr
cat settings.metadata.json 
cat settings.bson 
ls -ltr
cd ..
ls -ltr
cd admin/
ls -ltr
cd ..
ls -ltr
cat server-6.0.asc 
mongod
ls -ltr
cd ..
ls -ltr
ls -ltra
cd 
ls -ltr
sudo nano /etc/mongod.conf 
cd Kaudajuwa123.
cd /var/lib/mongodb/
ls -ltr
cd journal/
ls -ltr
cd ..
ls -ltr
mongod -u admin
mongo -u admin
mongod --help
mongod --noauth
mongo --noauth
cd 
cd dump/
ls -ltr
mongodump --noauth hitjuwa >> hitjuwa
cd .
cd ..
mongodump --noauth hitjuwa >> hitjuwa
mongodump --help
mongodump --db hitjuwa --collection hitjuwa
mongodump --db Hitjuwa --collection hitjuwa
mongodump --db Hitjuwa --collection Hitjuwa
mongodump --db hitjuwa --gzip --out hitjuwa.gz
ls -ltr
du -sxh *
gunzip hitjuwa.gz/
cd hitjuwa.gz/
ls -ltr
cd hitjuwa/
ls -ltr
gunzip settings.metadata.json.gz 
ls -ltr
cat settings.metadata.json 
cd ..
cd .
cd 
cd dump/
ls -ltr
zip -r hitjuwa.zip hitjuwa/
la
ls
cd hitjuwa/
ls -l
cd dump/
ls
cd hitjuwa/
ls
cd ../
cd admin/
ls -l
cd /
ls -l
clear
ls -l
cd home/
ls -l
cd ..
cd var/
ls -l
cd www/
ls -l
cd html/
ls -l
cd config/
ls -l
cd ..
ls -l
cd database/
ls -l
cd ..
clear
ls -l
cd config/
ls -l
sudo nano database.php 
cd ..
ls -a
sudo nano .env 
cd config/
clear
ls -l
sudo nano database.php 
cd /
ls -l
mongo -v
mongod -v
mongod
clear
mongosh --version
clear
cd /
ls -l
mongo "mongodb+srv://127.0.0.1" --username  --password 
mongod "mongodb+srv://127.0.0.1" --username  --password 
mongodb "mongodb+srv://127.0.0.1" --username  --password 
mangosh --version
mongosh -v
mongosh --version
clear
mongodump --uri="mongodb://<root>:<root>@<185.208.159.84>:<22>/<hitjuwa>" --out=/path/to/backup/
mongodump --uri="mongodb://<root>:<root>@<185.208.159.84>:22/<hitjuwa>" --out=/path/to/backup/
