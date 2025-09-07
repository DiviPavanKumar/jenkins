#!/bin/bash
set -e  # ✅ Exit immediately on error (best practice for safety)

# ✅ Check if the password file exists
if [ -f /tmp/mysql_root_password.txt ]; then
    PASSWORD=$(cat /tmp/mysql_root_password.txt)
    echo "✅ Root password loaded from /tmp/mysql_root_password.txt"
else
    echo "❌ Password file not found at /tmp/mysql_root_password.txt"
    exit 1
fi

# ✅ Export password so MySQL image can use it
export MYSQL_ROOT_PASSWORD="$PASSWORD"

# ✅ Remove the password file to avoid leaking secrets inside the container
rm -f /tmp/mysql_root_password.txt

# ✅ Chain to the original MySQL entrypoint with the correct arguments
exec /entrypoint.sh mysqld