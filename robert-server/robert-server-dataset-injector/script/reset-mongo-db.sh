#!/bin/sh
#Reset the collections idTable and CONTACTS_TO_PROCESS of the database given in parameter.
dbname=$1
if [ -z "${dbname}" ]
then
    echo Please give the database name in parameter. Example : protectedRobertDB.
    exit 1
fi
echo Reset the collections idTable and CONTACTS_TO_PROCESS of the database ${dbname}.
mongo -d ${dbname} --eval "db.runCommand( { drop: 'idTable' } )"
mongo -d ${dbname} --eval "db.runCommand( { drop: 'CONTACTS_TO_PROCESS' } )"
