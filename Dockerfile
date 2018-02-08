# phpBB S3 Backup Dockerfile

FROM alpine:3.4

RUN apk --no-cache add \
    # tini is a tiny but valid `init` for containers:
    tini \
    # mariadb-client includes mysqldump for the phpbb backup:
    mariadb-client \
    # curl and jq are used for the phpbb auto-update functionality:
    curl \
    jq \
    # awscli dependencies:
    py-pip \
    groff \
    less \
  && pip install --upgrade \
    pip \
    awscli \
  # Clean up obsolete files:
  && rm -rf \
    # Remove the backwards compatibility wrapper for tini:
    /usr/bin/tini \
    # Clean up any temporary files:
    /tmp/* \
    # Clean up the pip cache:
    /root/.cache \
    # Remove any compiled python files (compile on demand):
    `find / -regex '.*\.py[co]'`

# Add the envconfig, log, phpbb-s3-backup and phpbb-auto-update scripts:
COPY bin /usr/local/bin

# Copy the envconfig config file:
COPY envconfig.conf /usr/local/etc/

# Add the crontab for the user nobody:
COPY crontab /var/spool/cron/crontabs/nobody

ENV \
  BACKUP_SCHEDULE='0 4 * * *' \
  UPDATE_SCHEDULE='0 5 * * *' \
  BACKUP_BEFORE_UPDATE=true \
  DB_CP_OPTS= \
  DIR_SYNC_OPTS='--size-only --exclude .htaccess --exclude index.htm' \
  DBHOST=mysql \
  DBPORT= \
  DBNAME=phpbb \
  DBUSER=phpbb \
  DBPASSWD=

# Start tini and run envconfig:
ENTRYPOINT ["tini", "--", "envconfig"]

# Run crond in foreground mode with the log level set to 10:
CMD ["crond", "-f", "-l", "10"]
