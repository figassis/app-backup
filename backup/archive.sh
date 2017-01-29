#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT=$(dirname -- "$DIR")
source $PARENT/local/backup.ini

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

DATE=`date +%d-%m-%Y`
HOST=`hostname`
APPNAME=`basename $APPDIR`
BACKUP_NAME="${APPNAME}_$DATE.tar.gz"
DBNAME="${APPNAME}_$DATE.sql"

# The S3 destination followed by bucket name
DEST="s3://s3.amazonaws.com/$AWS_BUCKET/$APPNAME"

# Create temp folder
rm -rf $PARENT/temp && mkdir $PARENT/temp
TEMP=$PARENT/temp

if [ ! -z "$DATABASE" ] && [ ! -z "$USER" ] && [ -z "$PASS" ]; then
    mysqldump --lock-tables -u $USER -p$PASS $DATABASE > $APPDIR/$DBNAME
    gzip $APPDIR/$DBNAME
fi


tar -cf $TEMP/$BACKUP_NAME $APPDIR
[ -f $APPDIR/$DBNAME.gz ] && rm $APPDIR/$DBNAME.gz

touch $PARENT/$FULLBACKLOGFILE
cat /dev/null > $PARENT/${DAILYLOGFILE}

# Trace function for logging, don't change this
    trace () {
            stamp=`date +%Y-%m-%d_%H:%M:%S`
            echo "$stamp: $*" >> $PARENT/${DAILYLOGFILE}
    }

    trace "Backup for $APPNAME started"

    aws s3 cp $TEMP/$BACKUP_NAME $DEST/$BACKUP_NAME >> $PARENT/$DAILYLOGFILE 2>&1
    
    trace "Backup for $APPNAME complete"
    trace "------------------------------------"

    BACKUPSTATUS=`cat "$PARENT/$DAILYLOGFILE" | grep Errors | awk '{ print $2 }'`
    if [ "$BACKUPSTATUS" != "0" ]; then
       cat "$PARENT/$DAILYLOGFILE" | mail -s "Archive Log for $HOST - $DATE" $EMAIL
    fi
    
    echo "$(date +%d%m%Y_%T) Full Backup Done" >> $PARENT/$FULLBACKLOGFILE

    # Append the daily log file to the main log file
    cat "$PARENT/$DAILYLOGFILE" >> $PARENT/$LOGFILE

    # Reset the ENV variables. Don't need them sitting around
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset PASSPHRASE