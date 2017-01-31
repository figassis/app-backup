#!/bin/bash
#Incremental date format: last, 1D, 1W, 1M, 1Y, MM-DD-YYYY
#Archive date format = MM-DD-YYYY

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT=$DIR
source $PARENT/local/backup.ini

if [ $# -ne 2 ]; then echo Usage: $0 DATE APP; exit 1; fi

# Export some ENV variables so you don't have to type anything
export AWS_ACCESS_KEY_ID=$AWS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_ACCESS_KEY
export PASSPHRASE=`cat local/password.txt`

./modules/$MODULE/restore.sh $1 $2

# Reset the ENV variables. Don't need them sitting around
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset PASSPHRASE