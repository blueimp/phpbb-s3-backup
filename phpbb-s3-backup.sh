#!/bin/sh

#
# Uploads backups of the phpBB database and user file uploads to Amazon S3.
#
# Requires awscli and mysqldump.
#
# Usage: ./phpbb-s3-backup.sh
#

# Tests if the given variables have been defined, exits otherwise:
test_required_variables() {
  local var
  for var in "$@"; do
    if eval 'test -z "$'$var'"'; then
      echo "Error: $var is not defined." >&2
      exit 1
    fi
  done
}

test_required_variables \
  S3_BUCKET \
  AWS_ACCESS_KEY_ID \
  AWS_SECRET_ACCESS_KEY \
  DBHOST \
  DBUSER \
  DBNAME

# Uploads a dump of the phpBB database:
database_backup() {
  local date_prefix="$(date -u +"${DATE_FORMAT:-"%Y-%m-%dT%H-%M-%SZ_"}")"
  local s3_url="s3://$S3_BUCKET/db/$date_prefix$DBNAME.sql.gz"
  mysqldump \
    --host="$DBHOST" \
    --port="${DBPORT:-3306}" \
    --user="$DBUSER" \
    --password="$DBPASSWD" \
    $MYSQLDUMP_OPTS \
    "$DBNAME" |
    gzip -9 |
    aws s3 cp - "$s3_url" $DB_CP_OPTS \
      && echo "Saved database $DBNAME to $s3_url."
}

# Uploads the given relative phpBB directory:
directory_backup() {
  local path="${PHPBB_ROOT_PATH:-"/var/www/html"}/$1"
  local s3_url="s3://$S3_BUCKET/$1"
  aws s3 sync "$path" "$s3_url" $DIR_SYNC_OPTS \
    && echo "Synced directory $1 to $s3_url."
}

# Waits for the background processes to complete.
# Returns exit code 0 if all succeeded, else exit code 1:
wait_and_exit() {
  local exit_code=0
  local pid
  for pid in $PIDS; do
    wait $pid
    if [ ! $? -eq 0 ]; then
      exit_code=1
    fi
  done
  exit $exit_code
}

# Runs the given command line as background job:
run() {
  "$@" & PIDS="$PIDS $!"
}

# Variable holding the PIDs of the background jobs:
PIDS=

# Run the backup functions in parallel:
run database_backup
run directory_backup files
run directory_backup images/avatars/upload

wait_and_exit
