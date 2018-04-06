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
# Convert hexadecimal to binary
hex-bin () {
    echo "ibase=16;obase=2; $1" | bc
}

pad () {
    STR=$1
    LENGTH=$2
    while [[ ${#STR} -lt $LENGTH ]]; do
        STR="0$STR"
    done
    echo $STR
}
split () {
    STR=$1
    CHAR=$2
    OUTPUT=("")
    CURR=0

    # Reference: https://stackoverflow.com/a/10552175/8706910
    for (( i=0; i < ${#STR}; i++ )); do
        C=${STR:i:${#CHAR}}
        if [[ $C == $CHAR ]]; then
            OUTPUT+=("")
            CURR=$((CURR + 1))
            i=$((i + ${#CHAR} - 1))
        else
            OUTPUT[$CURR]+=${STR:i:1}
        fi
    done
    echo ${OUTPUT[@]}
}

ip-type () {
    IP=$1
    if [[ $IP =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        PARTS=$(split $IP ".")
        for PART in $PARTS; do
            if [[ $PART -gt 255 ]]; then
                echo "None"
                exit 0
            fi
        done
        echo "IPv4"
    elif [[ $IP =~ ^([0-9|a-f|A-F]{0,4}\:){2,7}[0-9|a-f|A-F]{0,4}$ ]]; then
        echo "IPv6"
    else
        echo "None"
    fi
}

pad-ipv6-shortened () {
    IP=$1
    LEFT=$(echo $IP | awk '{split($0,x,"::"); print x[1]}')
    RIGHT=$(echo $IP | awk '{split($0,x,"::"); print x[2]}')
    LEFT=($(split "$LEFT" ":"))
    RIGHT=($(split "$RIGHT" ":"))
    ZERO_COUNT=$((8 - ${#LEFT[@]} - ${#RIGHT[@]})) # Need to insert this many blocks of zeros
    while [[ $ZERO_COUNT -gt 0 ]]; do
        LEFT+=("0")
        ZERO_COUNT=$(($ZERO_COUNT - 1))
    done
    LEFT+=(${RIGHT[@]})
    echo ${LEFT[@]^^}
}

ipv6-to-binary () {
    IP=$1
    IP_PARTS=$(pad-ipv6-shortened $IP)
    IP_BINARY=""
    for PART in $IP_PARTS; do
        PART_BINARY=$(hex-bin $PART)
        PADDED=$(pad $PART_BINARY 16)
        IP_BINARY="$IP_BINARY$PADDED" 
    done
    echo $IP_BINARY
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

    echo ${STR:$INDEX:$LENGTH}
}

validate-ip () {
    IP=$1
    RANGE=$2

    RANGE_PIECES=($(split $RANGE "/"))
    RANGE_IP=${RANGE_PIECES[0]}
    MASK=${RANGE_PIECES[1]}
    if [[ $MASK == "" ]]; then
        MASK=128
    fi

    IP_TYPE=$(ip-type $IP)
    RANGE_IP_TYPE=$(ip-type $RANGE_IP)
    if [[ $IP_TYPE != $RANGE_IP_TYPE ]]; then
        return 1 # IPs can't match if they are not the same type
    fi

    if [[ $IP_TYPE == "IPv4" ]]; then
        IP_BINARY=$(ip-to-binary $IP)
        RANGE_IP_BINARY=$(ip-to-binary $RANGE_IP)
    elif [[ $IP_TYPE == "IPv6" ]]; then
        IP_BINARY=$(ipv6-to-binary $IP)
        RANGE_IP_BINARY=$(ipv6-to-binary $RANGE_IP)
    else
        return 1
    fi

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

    email "$PAM_USER from $REMOTE_HOSTNAME" "Successful login to `hostname` as user $PAM_USER at $(date) from $REMOTE_HOSTNAME ($PAM_RHOST)" 
fi
