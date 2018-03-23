#!/bin/bash
# Nicolas Chan <nicolaschan@berkeley.edu>

SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
CONFIG_FILE="$SCRIPT_DIR/config.sh"
source $CONFIG_FILE

# Binary conversion
binary () {
    # Reference: https://stackoverflow.com/questions/10278513/bash-shell-decimal-to-binary-conversion
    echo "obase=2; $1" | bc
}

pad () {
    STR=$1
    LENGTH=$2
    while [[ ${#STR} -lt $LENGTH ]]; do
        STR="0$STR"
    done
    echo $STR
}

ip-to-binary () {
    IP=$1
    IP_PARTS=$(echo $IP | awk '{split($0,x,"."); print x[1],x[2],x[3],x[4]}')
    IP_BINARY=""

    for PART in $IP_PARTS; do
        PART_BINARY=$(binary $PART)
        PADDED=$(pad $PART_BINARY 8)
        IP_BINARY="$IP_BINARY$PADDED"
    done
    echo $IP_BINARY
} 

substr () {
    STR=$1
    INDEX=$2
    LENGTH=$3

    echo $STR | awk "{print substr(\$0,$INDEX,$LENGTH);}"
}

validate-ip () {
    IP=$1
    RANGE=$2

    RANGE_IP=$(echo $RANGE | awk '{split($0,x,"/"); print x[1]}')
    MASK=$(echo $RANGE | awk '{split($0,x,"/"); print x[2]}')
    if [[ $MASK == "" ]]; then
        MASK=32
    fi

    IP_BINARY=$(ip-to-binary $IP)
    RANGE_IP_BINARY=$(ip-to-binary $RANGE_IP)

    echo "masked ip $IP_BINARY"
    echo "masked range $RANGE_IP_BINARY"
    IP_BINARY=$(substr $IP_BINARY 0 $MASK)
    RANGE_IP_BINARY=$(substr $RANGE_IP_BINARY 0 $MASK)

    echo "masked ip $IP_BINARY"
    echo "masked range $RANGE_IP_BINARY"

    if [[ $IP_BINARY == $RANGE_IP_BINARY ]]; then
       return 0 # Matches
    else
       return 1 # Does not match
    fi    
}

# Whitelisted IPs
WHITELIST="$(< $SCRIPT_DIR/ip-whitelist.txt)"
for WHITELISTED_IP in $WHITELIST; do
    if validate-ip $PAM_RHOST $WHITELISTED_IP; then
        exit 0
    fi
done

# Send email
email () {
    SUBJECT=$1
    CONTENT=$2

    curl -s --user "$API_KEY" \
        "$MAILGUN_URL" \
        -F from="$FROM" \
        -F to="$RECIPIENTS" \
        -F subject="$SUBJECT" \
        -F text="$CONTENT" 
}


if [[ $PAM_TYPE != "close_session" ]]; then
    REMOTE_HOSTNAME=$(dig -x $PAM_RHOST +short)
    if [[ $REMOTE_HOSTNAME == "" ]]; then
        REMOTE_HOSTNAME=$PAM_RHOST
    fi

    env > /etc/ssh/cool-log.txt
    email "$PAM_USER from $REMOTE_HOSTNAME" "Successful login to `hostname` as user $PAM_USER at $(date) from $REMOTE_HOSTNAME ($PAM_RHOST)" 
fi
