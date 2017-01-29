#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT=$(dirname -- "$DIR")
source $PARENT/local/backup.ini

if [ $# -ne 1 ] && [ $# -ne 2 ] && [ $# -ne 5 ]; then
    echo Usage: $0 app_dir [excludes] [db db_user db_pass]
    exit 1
fi
    
APPDIR=$1
EXCLUDES=
DATABASE=
USER=
PASS=

if [ $# -eq 2 ]; then
    EXCLUDES=$2
fi

if [ $# -eq 5 ]; then
    DATABASE=$3
    USER=$4
    PASS=$5
fi

# Export some ENV variables so you don't have to type anything
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export PASSPHRASE=`cat local/password.txt`

DATE=`date +%d-%m-%Y`
HOST=`hostname`
APPNAME=`basename $APPDIR`
BACKUP_NAME="${APPNAME}_$DATE.tar.gz"
DBNAME="${APPNAME}_$DATE.sql"

# The S3 destination followed by bucket name
DEST="s3://s3.amazonaws.com/$AWS_BUCKET/$APPNAME"

if [ -n "$DATABASE" ] && [ -n "$USER" ] && [ -n "$PASS" ]; then
    mysqldump --lock-tables -u $USER -p$PASS $DATABASE > $APPDIR/$DBNAME
    gzip $APPDIR/$DBNAME
fi

is_running=$(ps -ef | grep duplicity  | grep python | wc -l)

mkdir -p log

touch $PARENT/$FULLBACKLOGFILE

if [ $is_running -eq 0 ]; then
    # Clear the old daily log file
    cat /dev/null > $PARENT/${DAILYLOGFILE}

    # Trace function for logging, don't change this
    trace () {
            stamp=`date +%Y-%m-%d_%H:%M:%S`
            echo "$stamp: $*" >> $PARENT/${DAILYLOGFILE}
    }

    # The source of your backup
    SOURCE=$APPDIR

    trace "Backup for $APPNAME started"

    trace "... removing old backups"

    duplicity $REMOVE $DEST >> $PARENT/$DAILYLOGFILE 2>&1
    
    trace "... backing up $app"

    duplicity $FULL $EXCLUDES --allow-source-mismatch --s3-use-rrs $SOURCE $DEST >> $PARENT/$DAILYLOGFILE 2>&1
    
    trace "Backup for $APPNAME complete"
    trace "------------------------------------"

    # Send the daily log file by email
    cat "$DAILYLOGFILE" | mail -s "Duplicity Backup Log for $HOST - $DATE" $MAILADDR
    BACKUPSTATUS=`cat "$PARENT/$DAILYLOGFILE" | grep Errors | awk '{ print $2 }'`
    if [ "$BACKUPSTATUS" != "0" ]; then
	   cat "$PARENT/$DAILYLOGFILE" | mail -s "Duplicity Backup Log for $HOST - $DATE" $EMAIL
    elif [ "$FULL" = "full" ]; then
        echo "$(date +%d%m%Y_%T) Full Backup Done" >> $PARENT/$FULLBACKLOGFILE
    fi

    # Append the daily log file to the main log file
    cat "$PARENT/$DAILYLOGFILE" >> $PARENT/$LOGFILE

    # Reset the ENV variables. Don't need them sitting around
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset PASSPHRASE
    [ -f $APPDIR/$DBNAME.gz ] && rm -f $APPDIR/$DBNAME.gz
fi