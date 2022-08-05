#!/bin/bash

# variables for postgresql
PWDSRV_IP1=172.16.60.1    #ip 1 - Сервисы Авторизации, ДБО.
PWDSRV_IP2=172.16.60.2    #ip 2 - Сервисы Авторизации, ДБО.

MASK1=32                  #mask for ip 1 - Сервисы Авторизации, ДБО. (8, 16, 24, 32)
MASK2=32                  #mask for ip 2 - Сервисы Авторизации, ДБО. (8, 16, 24, 32)

CHECK1=md5                # проверка для ip 1 (ident, peer, md5, scram-sha-256, trust)
CHECK2=md5                # проверка для ip 2 (ident, peer, md5, scram-sha-256, trust)
 
# опционально если кубер или нужен третий адрес ( вставляем в скобки )
PWDSRV_IP3=""              #ip 3 - Сервисы Авторизации, ДБО.
MASK3=32                  #mask for ip 3 - Сервисы Авторизации, ДБО. (8, 16, 24, 32)
CHECK3=md5                # проверка для ip 3 (ident, peer, md5, scram-sha-256, trust)

LISTEN_ADDRESSES=*         #необходимо разрешить подключения со всех узлов (или список IP адресов через запятую

# Идем на сайт https://pgtune.leopard.in.ua/  <Mixed tipe of aplication>
# Выбираем необходимые параметры вм
# Вставляем вместо шаблона
# Функция вставит в файл /var/lib/pgsql/13/data/postgresql.conf

function partOFconfFN {

cat <<EOF >> /var/lib/pgsql/13/data/postgresql.conf

# DB Version: 13
# OS Type: linux
# DB Type: mixed
# Total Memory (RAM): 2 GB
# CPUs num: 1
# Connections num: 500
# Data Storage: ssd

max_connections = 500
shared_buffers = 512MB
effective_cache_size = 1536MB
maintenance_work_mem = 128MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 262kB
min_wal_size = 1GB
max_wal_size = 4GB

EOF

}





# -------------------------------------- Body of Postgresql ---------------------------------

if cd utils
then
cd utils
yum install -y *.rpm
cd ..
else
yum install -y epel-release
yum install -y jq
yum install -y mc nmap chrony wget nano psmisc zip unzip  yum-utils net-tools nfs-utils tree htop
fi


function posgresqlFn {

echo "Установка сервера postgresql 13"
sleep 3

if cd postgresql_13
then
cd postgresql_13
yum install -y *.rpm
cd ..
else
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum install -y postgresql13-server postgresql13-contrib
fi

echo "Открываем порт 5432"
sleep 2
firewall-cmd --permanent --zone=public --add-port=5432/tcp
systemctl restart firewalld

echo "Производим инициализацию"
sleep 2
/usr/pgsql-13/bin/postgresql-13-setup initdb

echo "Автозапуск - включен"
sleep 2
systemctl enable postgresql-13


echo "Контроль доступа"
cat <<EOF > /var/lib/pgsql/13/data/pg_hba.conf
# PostgreSQL Client Authentication Configuration File
# ===================================================
#
# Refer to the "Client Authentication" section in the PostgreSQL
# documentation for a complete description of this file.  A short
# synopsis follows.
#
# This file controls: which hosts are allowed to connect, how clients
# are authenticated, which PostgreSQL user names they can use, which
# databases they can access.  Records take one of these forms:
#
# local         DATABASE  USER  METHOD  [OPTIONS]
# host          DATABASE  USER  ADDRESS  METHOD  [OPTIONS]
# hostssl       DATABASE  USER  ADDRESS  METHOD  [OPTIONS]
# hostnossl     DATABASE  USER  ADDRESS  METHOD  [OPTIONS]
# hostgssenc    DATABASE  USER  ADDRESS  METHOD  [OPTIONS]
# hostnogssenc  DATABASE  USER  ADDRESS  METHOD  [OPTIONS]
#
# (The uppercase items must be replaced by actual values.)
#
# The first field is the connection type: "local" is a Unix-domain
# socket, "host" is either a plain or SSL-encrypted TCP/IP socket,
# "hostssl" is an SSL-encrypted TCP/IP socket, and "hostnossl" is a
# non-SSL TCP/IP socket.  Similarly, "hostgssenc" uses a
# GSSAPI-encrypted TCP/IP socket, while "hostnogssenc" uses a
# non-GSSAPI socket.
#
# DATABASE can be "all", "sameuser", "samerole", "replication", a
# database name, or a comma-separated list thereof. The "all"
# keyword does not match "replication". Access to replication
# must be enabled in a separate record (see example below).
#
# USER can be "all", a user name, a group name prefixed with "+", or a
# comma-separated list thereof.  In both the DATABASE and USER fields
# you can also write a file name prefixed with "@" to include names
# from a separate file.
#
# ADDRESS specifies the set of hosts the record matches.  It can be a
# host name, or it is made up of an IP address and a CIDR mask that is
# an integer (between 0 and 32 (IPv4) or 128 (IPv6) inclusive) that
# specifies the number of significant bits in the mask.  A host name
# that starts with a dot (.) matches a suffix of the actual host name.
# Alternatively, you can write an IP address and netmask in separate
# columns to specify the set of hosts.  Instead of a CIDR-address, you
# can write "samehost" to match any of the server's own IP addresses,
# or "samenet" to match any address in any subnet that the server is
# directly connected to.
#
# METHOD can be "trust", "reject", "md5", "password", "scram-sha-256",
# "gss", "sspi", "ident", "peer", "pam", "ldap", "radius" or "cert".
# Note that "password" sends passwords in clear text; "md5" or
# "scram-sha-256" are preferred since they send encrypted passwords.
#
# OPTIONS are a set of options for the authentication in the format
# NAME=VALUE.  The available options depend on the different
# authentication methods -- refer to the "Client Authentication"
# section in the documentation for a list of which options are
# available for which authentication methods.
#
# Database and user names containing spaces, commas, quotes and other
# special characters must be quoted.  Quoting one of the keywords
# "all", "sameuser", "samerole" or "replication" makes the name lose
# its special character, and just match a database or username with
# that name.
#
# This file is read on server startup and when the server receives a
# SIGHUP signal.  If you edit the file on a running system, you have to
# SIGHUP the server for the changes to take effect, run "pg_ctl reload",
# or execute "SELECT pg_reload_conf()".
#
# Put your actual configuration here
# ----------------------------------
#
# If you want to allow non-local connections, you need to add more
# "host" records.  In that case you will also need to make PostgreSQL
# listen on a non-local interface via the listen_addresses
# configuration parameter, or via the -i or -h command line switches.



# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             $PWDSRV_IP1/$MASK1      $CHECK1
host    all             all             $PWDSRV_IP2/$MASK2      $CHECK2

# IPv6 local connections:
host    all             all             ::1/128                 scram-sha-256
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
EOF

if [[ $PWDSRV_IP3 = "" ]]
then
echo "ip-3 пустой" 
else
sed -i "89i  host    all             all             $PWDSRV_IP3/$MASK3      $CHECK3" /var/lib/pgsql/13/data/pg_hba.conf
fi

tail -n 17 /var/lib/pgsql/13/data/pg_hba.conf
sleep 3

echo "-------------------------------------------------------------"
echo "Оптимизация"
sleep 2

cp /var/lib/pgsql/13/data/postgresql.conf /var/lib/pgsql/13/data/postgresql.conf_buckUP

sed -i "/listen_addresses =/d" /var/lib/pgsql/13/data/postgresql.conf
sed -i "60i listen_addresses = '${LISTEN_ADDRESSES}'      # what IP address(es) to listen on;" /var/lib/pgsql/13/data/postgresql.conf
sed -i "/max_connections =/d" /var/lib/pgsql/13/data/postgresql.conf
sed -i "64i #max_connections = 100			# (change requires restart)" /var/lib/pgsql/13/data/postgresql.conf
sed -i "/shared_buffers =/d" /var/lib/pgsql/13/data/postgresql.conf
sed -i "121i #shared_buffers = 128MB			# min 128kB" /var/lib/pgsql/13/data/postgresql.conf

sed -i "/max_wal_size/d" /var/lib/pgsql/13/data/postgresql.conf
sed -i "229i #max_wal_size = 1GB" /var/lib/pgsql/13/data/postgresql.conf
sed -i "/min_wal_size =/d" /var/lib/pgsql/13/data/postgresql.conf
sed -i "230i #min_wal_size = 80MB" /var/lib/pgsql/13/data/postgresql.conf

sed -i "780,814d" /var/lib/pgsql/13/data/postgresql.conf

partOFconfFN

tail -n 35 /var/lib/pgsql/13/data/postgresql.conf
sleep 3

echo "-------------------------------------------------------------"
echo "Для активации данных настроек необходимо перезапустить PostgreSQL"
systemctl restart postgresql-13
systemctl status postgresql-13

echo "-------------------------------------------------------------"
}



function postgresql_database {

#============================= Создать пользователя rbr =================================================================================
echo "-------------------------------------------------------------"
echo "Создать пользователя rbr с паролем colvir (или иным)"
sudo -u postgres psql -c "CREATE ROLE rbruser;"
sudo -u postgres psql -c "ALTER ROLE rbruser WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION PASSWORD 'colvir';"

echo "Создать пустую БД с алиасом rbr из шаблона template0 с владельцем rbruser"
sudo -u postgres psql -c  "CREATE DATABASE rbr WITH TEMPLATE = template0 OWNER = rbruser;"
  
echo "Предоставить доступ к созданной БД"
sudo -u postgres psql -c "REVOKE ALL ON DATABASE rbr FROM PUBLIC;"
sudo -u postgres psql -c "GRANT ALL ON DATABASE rbr TO rbruser;"
sudo -u postgres psql -c "GRANT CONNECT,TEMPORARY ON DATABASE rbr TO PUBLIC;"
  
echo "Настроить работу с бинарными типами данных в БД"
sudo -u postgres psql -c "ALTER DATABASE rbr SET bytea_output TO 'escape';"
sleep 2
#============================ Создать пользователя pwdsrv ======================================================================
echo "-------------------------------------------------------------"
echo "Создать пользователя pwdsrv с паролем colvir (или иным)"
sudo -u postgres psql -c "CREATE ROLE pwdsrvuser;"
sudo -u postgres psql -c "ALTER ROLE pwdsrvuser WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION PASSWORD 'colvir';"

echo "Создать пустую БД с алиасом pwdsrv из шаблона template0 с владельцем rbruser"
sudo -u postgres psql -c  "CREATE DATABASE pwdsrv WITH TEMPLATE = template0 OWNER = pwdsrvuser;"
  
echo "Предоставить доступ к созданной БД"
sudo -u postgres psql -c "REVOKE ALL ON DATABASE pwdsrv FROM PUBLIC;"
sudo -u postgres psql -c "GRANT ALL ON DATABASE pwdsrv TO rbruser;"
sudo -u postgres psql -c "GRANT CONNECT,TEMPORARY ON DATABASE pwdsrv TO PUBLIC;"
  
echo "Настроить работу с бинарными типами данных в БД"
sudo -u postgres psql -c "ALTER DATABASE pwdsrv SET bytea_output TO 'escape';"
sleep 2

echo "-------------------------------------------------------------"
echo "Если видим сообщение Permission denied - игнорируем"
echo "Проверяем созданы ли базы"
sudo -u postgres psql -c "CREATE ROLE rbruser;"
sudo -u postgres psql -c  "CREATE DATABASE rbr WITH TEMPLATE = template0 OWNER = rbruser;"
sudo -u postgres psql -c "CREATE ROLE pwdsrvuser;"
sudo -u postgres psql -c  "CREATE DATABASE pwdsrv WITH TEMPLATE = template0 OWNER = pwdsrvuser;"
echo "-------------------------------------------------------------"
echo "Базы успешно созданы"

echo "Для активации данных настроек необходимо перезапустить PostgreSQL"
systemctl restart postgresql-13
systemctl status postgresql-13
echo "-------------------------------------------------------------"
echo "!!!!!!!!!!! ЕСЛИ НУЖНА ЧИСТАЯ БАЗА ДАННЫХ, НА ЭТОМ ВСЕ !!!!!!!!!!!!!!!!!!!!!!!!!!!"
}


function pgAdmin_fn {

echo "Опция. Установка pgadmin"
echo "Разворачивание проведем с помощью docker-compose на отдельной ВМ."

echo "Пример установки docker-compose на Centos 7"

yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce docker-ce-cli containerd.io
systemctl enable docker --now
curl -SL https://github.com/docker/compose/releases/download/v2.6.1/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose -v

echo "Создаем docker-compose.yml"

touch docker-compose.yml

cat <<EOF >  /root/docker-compose.yml
version: "3.7"
services:
    pgadmin:
        image: dpage/pgadmin4
        container_name: pgadmin
        environment:
            PGADMIN_DEFAULT_EMAIL: sys@colvir.ru
            PGADMIN_DEFAULT_PASSWORD: sys
            PGADMIN_LISTEN_PORT: 8080
        restart: always
        ports:
            - "8080:8080"
        volumes:
            - pgadmin:/var/lib/pgadmin
volumes:
   pgdata:
   pgadmin:
EOF


echo "Запускаем:"

docker-compose up -d

}





echo "Нужно ли производить установку базы данных Postgresql. Если да, введите - 1, нет - 0"
read VAR_POSTGRESQL

if [[ $VAR_POSTGRESQL -eq 1 ]]
then
posgresqlFn
else
echo "Установка базы данных Postgresql не производилась"
fi


echo "Хотите создать пользователей rbr & pwdsrv с пустыми базами данных? Если да, введите - 1, нет -0"
read VAR_DB

if [[ $VAR_DB -eq 1 ]]
then 
postgresql_database
else
echo "Пользователей rbr & pwdsrv с пустыми базами данных не созданы"
fi


echo "Хотите установить pgAdmin? Если да, введите - 1, нет -0"
read VAR_PA

if [[ $VAR_PA -eq 1 ]]
then 
pgAdmin_fn
else
echo "pgAdmin не устанавливается"
fi
