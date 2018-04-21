#!/bin/bash

exitIfFailed(){
	if [ "$1" != 0 ]; then
		exit "$1"
	fi
}

IMAGE_UTIL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$IMAGE_UTIL_DIR/../../config.env"
MAX_WAIT_TIME_FOR_CONNECTION="${MAX_WAIT_TIME_FOR_CONNECTION:-120}"

NAME="$1"

if [ -n "$2" ]; then
    ID_RSA="$2"
fi

if [ -z "$NAME" ]; then
	echo "name of vm must be specified" >&2
	exit 1
fi

if [ ! -e "$ID_RSA" ]; then
	echo "id rsa file must be specified" >&2
	exit 2
fi

# wait for IP
COUNTER=1
while [ -z "$IP" ]; do
	IP="`"$IMAGE_UTIL_DIR/get-ip.sh" "$NAME"`"
	exitIfFailed $?

	if [ -n "$IP" ]; then
		# test ssh works
		OUTPUT="`ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -i "$ID_RSA" "root@$IP" ":" 2>&1`"
		if grep -q "(ECDSA) to the list of known hosts" <<< "$OUTPUT"; then
			break
		fi
		if grep -q "$IP" <<< "$OUTPUT"; then # something wrong happened  (e.g. Connection refused)
			IP=""
		fi
	fi

	if [ "$COUNTER" == "$MAX_WAIT_TIME_FOR_CONNECTION" ]; then
		echo "Could not connect to $NAME" >&2
		exit 3
	fi
	sleep 1
	COUNTER=$(($COUNTER + 1))
done
