#!/bin/bash
source local/backup.ini

if [ $# -ne 1 ] && [ $# -ne 4 ]; then
    echo Usage: $0 app_dir [db db_user db_pass]
    exit 1
fi
    
APPDIR=$1
DATABASE=
USER=
PASS=

if [ $# -eq 4 ]; then
    DATABASE=$3
    USER=$4
    PASS=$5
fi

# Export some ENV variables so you don't have to type anything
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION
export AWS_DEFAULT_OUTPUT

DATE=`date +%Y-%m-%d`
TODAY=$(date +%d%m%Y)
HOST=`hostname`
APPNAME=`${app##*/}`
BACKUP_NAME=$APPNAME_$DATE.tar.gz
DBNAME=$APPNAME_$DATE.sql

# The S3 destination followed by bucket name
DEST="s3://$AWS_BUCKET/$MODE/$APPNAME"

Create temp folder
rm -rf $DIR/temp && mkdir $DIR/temp
TEMP=~/temp

if [ ! -z "$DATABASE" ] && [ ! -z "$USER" ] && [ -z "$PASS" ]; then
    #mysqldump --lock-tables -u $USER -p$PASS $DATABASE > $APPDIR/$DBNAME
    echo "akjbhjabdjlnak.jdlikebde,bdjkweqhbdujhbdlbqw" > $APPDIR/$DBNAME
    gzip $app/$DBNAME
fi


tar -cf $TEMP/$BACKUP_NAME $APPDIR
rm $APPDIR/$DBNAME.gz

#ls ~/mysql_backup
#exit

touch $FULLBACKLOGFILE
cat /dev/null > ${DAILYLOGFILE}

# Trace function for logging, don't change this
    trace () {
            stamp=`date +%Y-%m-%d_%H:%M:%S`
            echo "$stamp: $*" >> ${DAILYLOGFILE}
    }

    trace "Backup for $APPNAME started"

    aws s3 cp $TEMP/$BACKUP_NAME $DEST/$BACKUP_NAME >> $DAILYLOGFILE 2>&1

    trace "Backup for $APPNAME complete"
    trace "------------------------------------"

    BACKUPSTATUS=`cat "$DAILYLOGFILE" | grep Errors | awk '{ print $2 }'`
    if [ "$BACKUPSTATUS" != "0" ]; then
       cat "$DAILYLOGFILE" | mail -s "Archive Log for $HOST - $DATE" $EMAIL
    fi
    
    echo "$(date +%d%m%Y_%T) Full Backup Done" >> $FULLBACKLOGFILE

    # Append the daily log file to the main log file
    cat "$DAILYLOGFILE" >> $LOGFILE

    # Reset the ENV variables. Don't need them sitting around
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset PASSPHRASE