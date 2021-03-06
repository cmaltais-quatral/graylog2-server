#!/bin/sh
### BEGIN INIT INFO
# Provides:          graylog2-server
# Required-Start:    $network $local_fs $syslog $remote_fs
# Required-Stop:     $network $local_fs $syslog $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Should-Stop:       $local_fs
# Short-Description: Starts Graylog2-server
# Description:       Graylog2 is an open source syslog implementation that
#                    stores your logs in ElasticSearch. It consists of a
#                    server written in Java that accepts your syslog messages
#                    via TCP or UDP and stores it in the database. The second
#                    part is a Ruby on Rails web interface that allows you to
#                    view the log messages.
### END INIT INFO

# Author: Claudio Filho <claudio.filho@locaweb.com.br>

PATH=/bin:/sbin:/usr/bin:/usr/sbin
USER=graylog2
GROUP=graylog2
NAME=graylog2-server
DESC="Graylog2 Server"
DEFAULT=/etc/default/$NAME

DIR=/usr/share/java
PID_FILE=/var/tmp/graylog2.pid
JAVA_OPTS="-Xms512m -Xmx512m -Xss1024k -XX:MaxPermSize=1g"
GRAYLOG2_OPTS="-f /etc/graylog2/graylog2.conf -p $PID_FILE"

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

set -e

# The first existing directory is used for JAVA_HOME (if JAVA_HOME is not defined in $DEFAULT)
JDK_DIRS="/usr/lib/jvm/java-7-oracle /usr/lib/jvm/java-7-openjdk /usr/lib/jvm/java-7-openjdk-amd64/ /usr/lib/jvm/java-6-openjdk /usr/lib/jvm/java-6-openjdk-amd64/"

# Look for the right JVM to use
for jdir in $JDK_DIRS; do
    if [ -r "$jdir/bin/java" -a -z "${JAVA_HOME}" ]; then
        JAVA_HOME="$jdir"
    fi
done
export JAVA_HOME

# overwrite settings from default file
if [ -f "$DEFAULT" ]; then
    . "$DEFAULT"
fi

case "$1" in
  start)
    if [ -z "$JAVA_HOME" ]; then
        log_failure_msg "no JDK found - please set JAVA_HOME"
        exit 1
    fi

    log_daemon_msg "Starting $DESC"
    if [ -f "$PID_FILE" ] && [ $(ps -o pid --no-headers -p `cat $PID_FILE`) ]; then
        exit 1
    fi

    if start-stop-daemon -S -q -b -o --user $USER -c $USER --exec $JAVA_HOME/bin/java -- $JAVA_OPTS -jar $DIR/${NAME}.jar $GRAYLOG2_OPTS; then
        log_end_msg 0
    else
        log_end_msg 1
    fi
    ;;		
  stop)
    log_daemon_msg "Stopping $DESC"
    if start-stop-daemon -K -q -o --user $USER -c $USER --pidfile "$PID_FILE"; then
        log_end_msg 0
    else
        log_end_msg 1
    fi
    ;;
  restart)
    ${0} stop
    sleep 1
    ${0} start
    ;;
  *)
    log_success_msg "Usage: $0 {start|stop|restart}"
    exit 1
    ;;
esac

exit 0
