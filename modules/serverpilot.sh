#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT=$(dirname -- "$DIR")

echo $MODE
echo $MODULE
source $PARENT/includes/functions.sh
source $PARENT/local/backup.ini
#Also add include/exclude strings
#excludes="--exclude=$dir1 --exclude=$dir2"
#EXCLUDES="--exclude=public/wp-content/cache"
#SERVERPILOT=/srv/users
SERVERPILOT=$PARENT/srv/users

#Setup Variables
CONFIG=backup.json

for pilot in $SERVERPILOT/{.,}*; do
    
    temp=`basename $pilot`
    if [ "$temp" == "." ] || [ "$temp" == ".." ]; then continue; fi
    echo && echo "Backing up $pilot/apps" && echo
    
    for app in $pilot/apps/{.,}*; do
        
        temp=`basename $app`
        if [ "$temp" == "." ] || [ "$temp" == ".." ]; then continue; fi
        
        database=
        user=
        password=

        if [ -f "$app/$CONFIG" ]; then
            database=`readJson $app/$CONFIG database`
            user=`readJson $app/$CONFIG user`
            password=`readJson $app/$CONFIG pass`

            if [ ! -n "$database" ] || [ ! -n "$user" ] || [ ! -n "$password" ]; then
                echo "Backing up $temp without a database" && echo
                $PARENT/backup/$MODE.sh $app --exclude=$app/public/wp-content/cache
            else
                echo "Backing up $temp with database $database" && echo
                $PARENT/backup/$MODE.sh $app --exclude=$app/public/wp-content/cache $database $user $password
            fi
        else
            echo "Backing up $temp without a database" && echo
            $PARENT/backup/$MODE.sh $app --exclude=$app/public/wp-content/cache
        fi    
    done
done