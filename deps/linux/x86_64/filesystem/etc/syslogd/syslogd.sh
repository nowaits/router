#!/bin/sh
set -e

USAGE="Usage: `basename $0` start|stop|restart [config]"

#------------------------------------ -o- 
# Globals.
#
BINFILE=/usr/sbin/syslogd
PIDFILE=/var/run/syslog.pid

SYSLOGCONF=/var/tmp/shells/syslogd.conf
RUNCONF=/var/tmp/shells/syslogd.run.conf
USERCONF=/usr/admin/etc/syslogd.conf
STARTCONF=/usr/admin/etc/syslogd.start.conf
LOGSOCKET=/var/tmp/log
if [ "$2" != "" ]; then
  CLICONF=$2
else
  CLICONF=$RUNCONF
fi

#------------------------------------ -o- 
# Function definitions.
#
make_conf() {
  if [ "$CLICONF" = "$STARTCONF" -a ! -f "$STARTCONF" ]; then
    if [ -f "$USERCONF" ]; then
      cat "$USERCONF" > "$SYSLOGCONF"
    else
      echo > "$SYSLOGCONF"
    fi
  else
    if [ ! -f "$CLICONF" ]; then
      echo syslogd: configuration file \"$CLICONF\" not found ! 1>&2
      exit 1
    fi
    if [ -f "$USERCONF" ]; then
      cat "$CLICONF" "$USERCONF" > "$SYSLOGCONF"
    else
      cat "$CLICONF" > "$SYSLOGCONF"
    fi
  fi
  chmod 666 "$SYSLOGCONF"
}  # make_conf()


start() {
  pid=`ps -wax | grep "$BINFILE" | grep -v grep | awk '{ print $1 }'`;
  if [ -n "$pid" ]; then
    echo syslogd: \"$pid\" deamon already started ! 1>&2
    exit 1
  fi
  "$BINFILE" -p "$LOGSOCKET" -f "$SYSLOGCONF" || (echo syslogd: can not execute \"$BINFILE\" ! 1>&2; exit 1)
}  # end start()


stop() {
  # Kill process.
  #pid=`cat $PIDFILE 2>/dev/null` 
  pid=`ps -wax | grep "$BINFILE" | grep -v grep | awk '{ print $1 }'`;
  if [ -n "$pid" ]; then
    # Kill with -TERM then -KILL by default.
    kill -TERM $pid 2> /dev/null
    if [ "`ps -p $pid |  grep -c $pid`" != "0" ]; then
      kill -KILL $pid 2> /dev/null
    fi
  fi
  rm -f $PIDFILE
}  # end stop()

#------------------------------------ -o- 
# Action.
#
case "$1" in
  start)
    make_conf
    start
    ;;

  stop)
    stop
    ;;

  restart)
    make_conf
    # Make kill HUP.
    #pid=`cat $PIDFILE 2>/dev/null` 
    pid=`ps -wax | grep "$BINFILE" | grep -v grep | awk '{ print $1 }'`;
    if [ -n "$pid" ]; then
      kill -HUP $pid 2> /dev/null || start
    else
      start
    fi
    ;;

  *)
    echo $USAGE	1>&2
    exit 1
esac

exit 0

