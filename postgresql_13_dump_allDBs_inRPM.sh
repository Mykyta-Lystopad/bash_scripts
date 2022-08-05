#!/bin/bash


DATE=$(date +"%d-%m-%Y_%I-%M-%S")

if [[ /var/lib/pgsql/db.out ]]
then
cd /var/lib/pgsql/
zip dbout-$DATE db.out
rm -f db.out
else
echo "file db.out does not exist"
fi

su - postgres -c "pg_dumpall > db.out"
cd /var/lib/pgsql/
zip dbout-$DATE db.out
cp dbout-$DATE.zip /root
rm -f db.out
rm -rf dbout-$DATE.zip
cd
