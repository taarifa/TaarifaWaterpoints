#!/bin/sh

# https://github.com/CounterpartyXCP/federatednode_build/blob/master/dist/linux/runit/mongod/run

exec 2>&1

CONF=/etc/mongod.conf
DAEMON=/usr/bin/mongod
DAEMONUSER=${DAEMONUSER:-mongodb}

if [ -f /etc/default/mongod ]; then . /etc/default/mongod; fi

# Handle NUMA access to CPUs (SERVER-3574)
# This verifies the existence of numactl as well as testing that the command works
NUMACTL_ARGS="--interleave=all"
if which numactl >/dev/null 2>/dev/null && numactl $NUMACTL_ARGS ls / >/dev/null 2>/dev/null
then
  NUMACTL="$(which numactl) $NUMACTL_ARGS"
  DAEMON_OPTS=${DAEMON_OPTS:-"--config $CONF"}
else
  NUMACTL=""
  DAEMON_OPTS=" "${DAEMON_OPTS:-"--config $CONF"}
fi

exec chpst -u ${DAEMONUSER} $NUMACTL $DAEMON $DAEMON_OPTS
