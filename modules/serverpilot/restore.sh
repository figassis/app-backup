#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT=$(dirname -- "$(dirname -- "$DIR")")
source $PARENT/local/backup.ini

if [ $# -ne 2 ]; then echo Usage: $0 DATE APP; exit 1; fi

rm -rf $PARENT/restore && mkdir -p $PARENT/restore
    
DATE="--restore-time $1"
APPNAME=$2
BACKUP_NAME="${APPNAME}_$1.tar.gz"

if [ "$1" == "last" ]; then
    DATE=
fi

if [ "$MODE" == "incremental" ]; then

    DEST="s3://s3.amazonaws.com/$AWS_BUCKET/$APPNAME"
    duplicity $DATE ${DEST} $PARENT/restore
    echo "$APPNAME restored to $PARENT/restore"

elif [ "$MODE" == "archive" ]; then

    DEST="s3://$AWS_BUCKET/$APPNAME/$BACKUP_NAME"
    aws s3 cp $DEST $PARENT/restore
    [ -f "$PARENT/restore/$BACKUP_NAME" ] && cd $PARENT/restore && tar -xf $BACKUP_NAME && rm -f $BACKUP_NAME
    PUBLIC=`find $PARENT/restore -name "public" -type d -print -quit`
    echo $PUBLIC
    PUBLIC=$(dirname -- "$PUBLIC")
    echo $PUBLIC
    mv $PUBLIC $PARENT/restore && rm -rf $PARENT/restore/srv && cd $PARENT


    echo "$APPNAME restored to $PARENT/restore"

else
    echo "Usage: $0 DATE APP archive|incremental";
fi