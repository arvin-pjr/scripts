#!/bin/bash

### Elasticdump for elasticsearch data migration.

# colors for output
RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"
BOLD="\033[1m"
UNBOLD="\033[0m"

function main (){
    #echo "main func"
	check ${@:2}
    if [ $# = 5 ];then action $1; else usage; fi
}

function check(){
    #echo "check func"
	local OPTIND opt s
    while getopts ":hs:d:" opt; do
        case $opt in
            h) usage; exit 1 ;;
            s) SOURCE_ES_URI="$OPTARG";;
            d) DEST_ES_URI="$OPTARG";;
            *) usage; exit 1;;
        esac
    done
	shift $((OPTIND-1))
    if ! { [ -n "$SOURCE_ES_URI" ] && [ -n "$DEST_ES_URI" ]; }; then usage; fi
}

function usage () {
    echo -e "usage:\n $0 [ACTION] -s [SOURCE_ES_URI] -d [DEST_ES_URI] \n\naction: \n\tplan\t Shows the indices to be migrated. \n\tmigrate\t Migrate the indices."
    #echo -e "\nEx: \tTo migrate the data. \n\n\t $0 -s http://elastic:Secr3tPasswd@es-sg-xxxxx.elasticsearch.aliyuncs.com:9200 -d https://avnadmin:S3cretPasswd@labs-lfs-elasticsearch-some-proj.aivencloud.com:21509 \n"
    echo -e "\nNote: Make sure to whitelist runner IP/cidr in source & dest elasticsearch."
    exit 1
}

function action () {
    #echo "action func"
    case "$1" in
        plan)
            connectivity; 
            check_indices;;
        migrate)
            connectivity;
            check_indices;
            migration;;
        *) usage;;
    esac
}

# Install latest npm & elasticdump on linux machine.
function installations (){
    npm install elasticdump
    export PATH:$PATH:$(pwd)/node_modules/elasticdump/bin
}

function connectivity () {
    for i in $SOURCE_ES_URI $DEST_ES_URI; do
        HOSTURL=`echo $i | cut -d@ -f2-`
        timeout 2 curl -v -s telnet://$HOSTURL &> null.log
        NETWORK_STATUS=`grep -c "Connected" null.log`
        if [ $NETWORK_STATUS -eq 0 ]; then
            HOST=`echo $HOSTURL | cut -d: -f1`;
            echo -e "${BOLD}${RED}Couldn't able to connect to $HOST${ENDCOLOR}${UNBOLD}\n";
            exit 1;
        fi
    done
}

function check_indices () {
    echo -e "${BOLD}${GREEN}[PLAN]: FOLLOWING INDICES ARE READY FOR MIGRATION.${ENDCOLOR}${UNBOLD}\n"
    echo -e "${BOLD}${GREEN}[PLAN]: No: \tINDEX${ENDCOLOR}${UNBOLD}"
    ALL_INDICES=`curl -XGET -s -k $SOURCE_ES_URI/_cat/indices?v | awk '{print $3}' | tail -n+2`
    APP_INDICES=`for i in $ALL_INDICES; do case $i in .*) sleep 0.00001 ;; *) echo $i; esac; done` 
    NUM=0; for i in $APP_INDICES; do NUM=`expr $NUM + 1`; echo -e "${BOLD}${GREEN}[PLAN]: $NUM. \t$i${ENDCOLOR}${UNBOLD}"; done
}

function migration () {
    for INDEX in $APP_INDICES; do
        # creating Index
        echo -e "${BOLD}${GREEN}[MIGRATE]: CREATING INDEX $INDEX IN DESTINATION CLUSTER.${ENDCOLOR}${UNBOLD}\n"
        curl -XPUT -s -k $DEST_ES_URI/$INDEX

        # migrating index's data & mapping.
        echo -e "${BOLD}${GREEN}[MIGRATE]: $INDEX: INDEX MIGRATION IS STARTED AT $(date +%F::%H:%M:%S).${ENDCOLOR}${UNBOLD}\n"

        elasticdump \
            --input=$SOURCE_ES_URI/$INDEX \
            --output=$DEST_ES_URI/$INDEX \
            --type=mapping || true

        elasticdump \
            --input=$SOURCE_ES_URI/$INDEX \
            --output=$DEST_ES_URI/$INDEX \
            --type=data \
            --limit=10000 || exit 1

        echo -e "${BOLD}${GREEN}[MIGRATE]: $INDEX: INDEX MIGRATION IS COMPLETED AT $(date +%F::%H:%M:%S).${ENDCOLOR}${UNBOLD}\n"
    done
}
main $@