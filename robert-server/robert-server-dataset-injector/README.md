This module allows to inject contacts and registrations on a __local computer__ for performance tests.

# Pre-requisites 
- running instance of crypto-server (which depends on PostgreSQL DB and softHSMv2)
- MongoDB database instance

# Usage
```console
java -jar robert-server-dataset-injector <contact | registration> <number of record to generate>
```

# Examples
```console
java -jar robert-server-dataset-injector.jar contact 100000
java -jar robert-server-dataset-injector registration 20000
```

# Reset MongoDB database
The script script/reset-mongo-db allows to reset the MongoDB database.
Concretely, this script actually deletes all entries of the associated collections of contacts and registrations.
This script takes the database name in parameter. Example : ./reset-mongo-db.sh protectedRobertDB
