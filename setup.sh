#!/bin/bash
if [ $# -ne 5 ]; then
    echo Usage: $0 module mode email aws_key_id aws_key
    exit 1
fi

MODULE=$1
MODE=$2
EMAIL=$3
KEY_ID=$4
KEY=$5
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#Install Python and clone mobodoa installer
sudo apt-add-repository -y ppa:duplicity-team/ppa
sudo add-apt-repository -y ppa:chris-lea/python-boto
sudo apt-get update
sudo apt-get install -y build-essential python-pip python-rrdtool python-mysqldb python-dev libcairo2-dev ibpango1.0-dev librrd-dev libxml2-dev libxslt-dev zlib1g-dev duplicity python-boto mailutils
yes | sudo pip install --upgrade pip
yes | sudo pip install awscli

#Chekc if running on OSX or Linux
case "$OSTYPE" in
  darwin*)  tempfile=".bak" ;; 
  *)        tempfile="" ;;
esac




#Create configurations
rm -rf local && mkdir local && mkdir -p log
cp conf/backup.ini local/backup.ini
cp conf/schedule.txt local/schedule.txt

#Customize settings
sed -i $tempfile 's|home_dir|'$DIR'|g' local/schedule.txt
sed -i $tempfile 's|backup_mode|'$MODE'|g' local/backup.ini
sed -i $tempfile 's|aws_key_id|'$KEY_ID'|g' local/backup.ini
sed -i $tempfile 's|aws_key|'$KEY'|g' local/backup.ini
sed -i $tempfile 's|backup_module|'$MODULE'|g' local/backup.ini
sed -i $tempfile 's|backup_email|'$EMAIL'|g' local/backup.ini
sed -i $tempfile 's|backup_module|'$MODULE'|g' local/schedule.txt
openssl rand -base64 32 | tr -d /=+ | cut -c -30 > local/password.txt

rm -f local/*.bak
sudo cp local/schedule.txt /etc/cron.d/backups