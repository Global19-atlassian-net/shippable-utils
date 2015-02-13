#!/bin/sh
# Author: Michael Goff <Michael.Goff@Quantum.com>
# Licence: MIT
# Copyright (c) 2015, Quantum Corp.

usage()
{
cat <<EOF
Usage:
  $0 -h
  $0 <command>

Description:
  Handle starting, configuring, and stopping the database for shippable

Commands:
  start - start the mysql service and config with a test user with no password
  stop - stop the mysql service
EOF
}

while getopts ":h" opt
do
  case "${opt}" in
    h ) usage; exit 0 ;;
    \?) echo "unrecognized option: $OPTARG" 1>&2
        exit 1
        ;;
  esac
done
shift $((OPTIND-1))

if [ "$#" -ne 1 ]; then
  echo "Invalid Params: Requires a command argument" 1>&2
  usage
  exit 1
fi

COMMAND=$1
shift

case "$COMMAND" in
  start)
    /usr/bin/mysqld_safe > /dev/null 2>&1 &
    sleep 1
    started=false
    for try in {1..10}; do
      mysqladmin --socket=/var/run/mysqld/mysqld.sock status &>/dev/null && started=true && break
      echo "Waiting for mysql to start..."
      sleep 5
    done
    if $started; then
      echo "mysql started successfully"
    else
      echo "mysql failed to start!" 1>&2
      exit 1
    fi

    mysql -u root -e "DROP USER 'test'@'localhost';" || true
    mysql -u root -e "FLUSH PRIVILEGES; CREATE USER 'test'@'localhost'; GRANT ALL PRIVILEGES ON *.* TO 'test'@'localhost' WITH GRANT OPTION;"
    ;;

  stop)
    mysqladmin --socket=/var/run/mysqld/mysqld.sock shutdown
    ;;

  *)
    echo "Unknown command: ${COMMAND}" 1>&2
    usage
    exit 1
    ;;
esac