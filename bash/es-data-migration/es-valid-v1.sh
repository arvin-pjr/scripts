#!/bin/bash
source_uri=<source-uri>
target_uri=<target-uri>
index=<index>

START_TIME=`date +%s`
for (( i=1; i<=$1; i++ )); do
    # Generate random key in index.
    S_KEY=`curl -s -XGET --header 'Content-Type: application/json' -k ${source_uri}/${index}/_search | jq '.hits.hits[]._source | keys[]' | shuf | tail -n1 | sed "s/\"//g"`
    QM_KEY=`curl -s -XGET --header 'Content-Type: application/json' -k ${source_uri}/${index}/_search | jq '.hits.hits[]._source | keys[]' | shuf | tail -n1 | sed "s/\"//g"`
    # Get Value for above Key:
    QM_VALUE=`curl -s -XGET --header 'Content-Type: application/json' -k ${source_uri}/${index}/_search | jq '.hits.hits[]._source | .["'"$QM_KEY"'"]' | shuf | tail -n1| sed "s/\"//g"`

    sed "s/S_KEY/$S_KEY/g;s/QM_KEY/$QM_KEY/g;s/QM_VALUE/$QM_VALUE/g" query.tpl > query-$i.json

    echo "test-query-$i"
    cat query-$i.json

    echo "source report"
    curl -s -XGET --header 'Content-Type: application/json' -k ${source_uri}/${index}/_search -d @query-$i.json | jq '.hits.hits[]._source' | sort &> source.json

    echo "target report"
    curl -s -XGET --header 'Content-Type: application/json' -k ${target_uri}/${index}/_search -d @query-$i.json | jq '.hits.hits[]._source' | sort &> target.json

    echo -e "\nvalidating report"
    if ( $(cmp source.json target.json) ); then
        echo "query-$i is success."
    else
        echo "query-$i is failed:"
        cat query-$i.json
        echo -e "[Validate]: Data Validation is failed."
        exit 0
    fi
done
echo -e "[Validate]: Data Validation is successfull."
END_TIME=`date +%s`
SECONDS=$((end-start))
echo -e "[VALIDATION]: Duration: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"