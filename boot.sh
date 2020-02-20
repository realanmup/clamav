#!/bin/bash
set -m

# Apply env
for OUTPUT in $(env | awk -F "=" '{print $1}' | grep "^CLAMD_CONF_")
do
	TRIMMED=$(echo $OUTPUT | sed 's/CLAMD_CONF_//g')
	grep -q "^$TRIMMED " /etc/clamav/clamd.conf && sed "s/^$TRIMMED .*/$TRIMMED ${!OUTPUT}/" -i /etc/clamav/clamd.conf ||
	    sed "$ a\\$TRIMMED ${!OUTPUT}" -i /etc/clamav/clamd.conf
done

for OUTPUT in $(env | awk -F "=" '{print $1}' | grep "^FRESHCLAM_CONF_")
do
	TRIMMED=$(echo $OUTPUT | sed 's/FRESHCLAM_CONF_//g')
	grep -q "^$TRIMMED " /etc/clamav/freshclam.conf && sed "s/^$TRIMMED .*/$TRIMMED ${!OUTPUT}/" -i /etc/clamav/freshclam.conf ||
	    sed "$ a\\$TRIMMED ${!OUTPUT}" -i /etc/clamav/freshclam.conf
done

# Start services on background
freshclam -d &
clamd &

pids=`jobs -p`

# default exitcode
exitcode=0

# keeping the container running
# Ctrl+c will not work if you run docker without -d 
function terminate() {
    trap "" CHLD

    for pid in $pids; do
        if ! kill -0 $pid 2>/dev/null; then
            wait $pid
            exitcode=$?
        fi
    done

    kill $pids 2>/dev/null
}

trap terminate CHLD
wait

exit $exitcode