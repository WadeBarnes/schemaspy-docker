#!/bin/sh

DB_TYPE=${DATABASE_TYPE-pgsql}
DB_HOST=${DATABASE_HOST-${DATABASE_SERVICE_NAME}}
DB_USER=${DATABASE_USER-${POSTGRESQL_USER}}
DB_PASSWORD=${DATABASE_PASSWORD-${POSTGRESQL_PASSWORD}}
DB_NAME=${DATABASE_NAME-${POSTGRESQL_DATABASE}}
DB_DRIVER=${DATABASE_DRIVER}
DB_SCHEMA=${DATABASE_SCHEMA-public}
DB_CATALOG=${DATABASE_CATALOG-}
SERVER_PORT=${SCHEMASPY_PORT-8080}
OUTPUT_PATH=${OUTPUT_PATH-output}
SCHEMASPY_PATH=${SCHEMASPY_PATH-lib/schemaspy.jar}

PG_SQL=pgsql

if [ -z "$DB_TYPE" ]; then
  echo "ERROR: Environment variable DATABASE_TYPE is empty."
  FAIL=1
fi

# if [ -z "$DB_TYPE" ]; then
#   echo "ERROR: Environment variable DATABASE_TYPE is empty."
#   FAIL=1
# elif [ -z "$DB_DRIVER" ]; then
#   case "$DB_TYPE" in
#     *pgsql*)
#       DB_DRIVER="lib/postgresql-jdbc.jar"
#       ;;
#     *mysql*)
#       DB_DRIVER="lib/mysql-connector-java.jar"
#       ;;
#     *sqlite*)
#       DB_DRIVER="lib/sqlite-jdbc.jar"
#       ;;
#     *)
#     echo "ERROR: Environment variable DATABASE_TYPE unrecognized: $DB_TYPE."
#     FAIL=1
#   esac
# fi

if [ "$DB_TYPE" != *"sqlite"* ]; then
  if [ -z "$DB_HOST" ]; then
    echo "ERROR - Environment variable DATABASE_HOST is empty."
    FAIL=1
  fi
  if [ -z "$DB_USER" ]; then
    echo "ERROR - Environment variable DATABASE_USER is empty."
    FAIL=1
  fi
  if [ -z "$DB_PASSWORD" ]; then
    echo "ERROR - Environment variable DATABASE_PASSWORD is empty."
    FAIL=1
  fi
fi

if [ -z "$DB_NAME" ]; then
  echo "ERROR - Environment variable DATABASE_NAME is empty."
  FAIL=1
fi

if [ -n "$FAIL" ]; then
  exit 1
fi

ARGS="-t \"$DB_TYPE\" -db \"$DB_NAME\""

if [ ! -z "$DB_DRIVER" ]; then
  ARGS="$ARGS -dp \"$DB_DRIVER\""
fi

if [ ! -z "$SCHEMASPY_HQ" ]; then
  ARGS="$ARGS -hq"
fi

ARGS="$ARGS -s \"$DB_SCHEMA\" -cat \"$DB_CATALOG\""
ARGS="$ARGS -u \"$DB_USER\" -p \"$DB_PASSWORD\""
if [ -n "$DB_HOST" ]; then
  ARGS="$ARGS -host \"$DB_HOST\""
fi
if [ -n "$CONNPROPS" ]; then
  ARGS="$ARGS -connprops \"$CONNPROPS\""
fi

echo $ARGS

java -jar "$SCHEMASPY_PATH" $ARGS -o "$OUTPUT_PATH"

if [ ! -f "$OUTPUT_PATH/index.html" ]; then
  echo "ERROR - No HTML output generated"
  exit 1
fi

# busybox httpd
echo "Starting webserver on port $SERVER_PORT"
#httpd -f -p $SERVER_PORT -h "$OUTPUT_PATH"
exec caddy -quic --conf /etc/Caddyfile