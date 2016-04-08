# phpBB S3 Backup Dockerfile

FROM blueimp/awscli

MAINTAINER Sebastian Tschan <mail@blueimp.net>

# Install mysqldump via mariadb-client:
RUN apk --no-cache add \
      mariadb-client

# Install log - a script to execute a given command and log the output:
ADD https://raw.githubusercontent.com/blueimp/container-tools/2.2.0/bin/log.sh \
  /usr/local/bin/log
RUN chmod 755 /usr/local/bin/log

# Copy the envconfig config file:
COPY envconfig.conf /usr/local/etc/

# Add the crontab for the user nobody:
COPY crontab /var/spool/cron/crontabs/nobody

# Add the phpBB S3 backup script
COPY phpbb-s3-backup.sh /usr/local/bin/phpbb-s3-backup

ENV \
  BACKUP_SCHEDULE='0 4 * * *' \
  DB_CP_OPTS='--quiet' \
  DIR_SYNC_OPTS='--quiet --size-only --exclude .htaccess --exclude index.htm' \
  DBHOST=mysql \
  DBPORT= \
  DBNAME=phpbb \
  DBUSER=phpbb \
  DBPASSWD=

# Reset the entrypoint to the blueimp/alpine base image default:
ENTRYPOINT ["tini", "--", "envconfig", "entrypoint"]

# Run crond in foreground mode with the log level set to 10:
CMD ["crond", "-f", "-l", "10"]
