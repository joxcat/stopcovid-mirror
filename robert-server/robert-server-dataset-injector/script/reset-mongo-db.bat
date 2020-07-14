@echo OFF
REM Reset the collections idTable and CONTACTS_TO_PROCESS of the database given in parameter.
set dbname=%1
if [%dbname%] ==[] (
echo Please give the database name in parameter. Example : protectedRobertDB.
exit 1
)
echo Reset the collections idTable and CONTACTS_TO_PROCESS of the database %dbname%.
cd C:\Program Files\MongoDB\Server\4.2\bin
mongo.exe %dbname% --eval "db.runCommand( { drop: 'idTable' } )"
mongo.exe %dbname% --eval "db.runCommand( { drop: 'CONTACTS_TO_PROCESS' } )"
pause
