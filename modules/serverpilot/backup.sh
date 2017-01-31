#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT=$(dirname -- "$(dirname -- "$DIR")")

echo $MODE
echo $MODULE
source $PARENT/includes/functions.sh
source $PARENT/local/backup.ini
EXCLUDES=
SERVERPILOT=/srv/users

#Setup Variables
CONFIG=backup.json

for pilot in $SERVERPILOT/{.,}*; do
    
    temp=`basename $pilot`
    if [ "$temp" == "." ] || [ "$temp" == ".." ]; then continue; fi
    echo && echo "Backing up $pilot/apps" && echo
    
    for app in $pilot/apps/{.,}*; do
        
        if [ "$MODE" == "incremental" ]; then EXCLUDES="--exclude=$app/public/wp-content/cache"; fi
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
                $PARENT/backup/$MODE.sh $app $EXCLUDES
            else
                echo "Backing up $temp with database $database" && echo
                $PARENT/backup/$MODE.sh $app $EXCLUDES $database $user $password
            fi
        else
            echo "Backing up $temp without a database" && echo
            $PARENT/backup/$MODE.sh $app $EXCLUDES
        fi    
    done
done