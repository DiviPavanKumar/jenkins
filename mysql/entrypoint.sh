#!/bin/bash
set -e

if [ -f /tmp/mysql_root_password.txt ]; then
    export MYSQL_ROOT_PASSWORD=$(cat /tmp/mysql_root_password.txt)
    echo "✅ Root password loaded from /tmp/mysql_root_password.txt"
    rm -f /tmp/mysql_root_password.txt
else
    echo "❌ Password file not found!"
    exit 1
fi

exec docker-entrypoint.sh mysqld
