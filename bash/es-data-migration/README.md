## Pre-requisite: Elasticdump
#### Installation

Elasticdump requires [Node.js](https://nodejs.org/) v10+ to run.

```sh
npm install elasticdump
export PATH=$PATH:$(pwd)/node_modules/elasticdump/bin
elasticdump --help
```

5. Validate data either with elasticsearch queries or on kibana.
 
##### Usage:
```sh
localhost$ ./es-migration.sh -h
usage:
 ./es-migration.sh [ACTION] -s [SOURCE_ES_URI] -d [DEST_ES_URI] 

action: 
	plan	 Shows the indices to be migrated. 
	migrate	 Migrate the indices.

Note: Make sure to whitelist runner IP/cidr in source & dest elasticsearch.
```

##### Check Migration Plan:

```sh
localhost$ ./es-migration.sh plan -s http://elastic:Secr3tPasswd@source.elasticsearch.com:9200 -d https://elastic:Secr3tPasswd@destination.elasticsearch.com:9200

[PLAN]: FOLLOWING INDICES ARE READY FOR MIGRATION.
[PLAN]: No: 	INDEX
[PLAN]: 1. 	some-log-000000001
[PLAN]: 2. 	some-log-000000002
```

##### Migrate Indices:
```sh
localhost$ ./es-migration.sh migrate -s http://elastic:Secr3tPasswd@source.elasticsearch.com:9200 -d https://elastic:Secr3tPasswd@destination.elasticsearch.com:9200

[MIGRATE]: CREATING INDEX some-log-000000001 IN DESTINATION CLUSTER
{"acknowledged":true,"shards_acknowledged":true,"index":"some-log-000000001"}

[MIGRATE]: some-log-000000001: INDEX MIGRATION IS STARTED AT 2021-04-14::18:16:07.
Wed, 14 Apr 2021 18:16:07 GMT | starting dump
Wed, 14 Apr 2021 18:16:08 GMT | got 10000 objects from source elasticsearch (offset: 0)
Wed, 14 Apr 2021 18:16:29 GMT | sent 10000 objects to destination elasticsearch, wrote 10000
Wed, 14 Apr 2021 18:16:30 GMT | got 10000 objects from source elasticsearch (offset: 10000)
...
...
Wed, 14 Apr 2021 18:20:14 GMT | got 2850 objects from source elasticsearch (offset: 280000)
Wed, 14 Apr 2021 18:20:18 GMT | sent 2850 objects to destination elasticsearch, wrote 2850
Wed, 14 Apr 2021 18:20:18 GMT | got 0 objects from source elasticsearch (offset: 282850)
Wed, 14 Apr 2021 18:20:18 GMT | Total Writes: 282850
Wed, 14 Apr 2021 18:20:18 GMT | dump complete
[MIGRATE]: some-log-000000001: INDEX MIGRATION IS COMPLETED AT 2021-04-14::18:20:19.

[MIGRATE]: CREATING INDEX some-log-000000002 IN DESTINATION CLUSTER
{"acknowledged":true,"shards_acknowledged":true,"index":"some-log-000000002"}

[MIGRATE]: some-log-000000002: INDEX MIGRATION IS STARTED AT 2021-04-14::18:21:07.
Wed, 14 Apr 2021 18:21:07 GMT | starting dump
Wed, 14 Apr 2021 18:21:08 GMT | got 10000 objects from source elasticsearch (offset: 0)
Wed, 14 Apr 2021 18:21:29 GMT | sent 10000 objects to destination elasticsearch, wrote 10000
Wed, 14 Apr 2021 18:21:30 GMT | got 10000 objects from source elasticsearch (offset: 10000)
...
...
Wed, 14 Apr 2021 18:25:14 GMT | got 3500 objects from source elasticsearch (offset: 300000)
Wed, 14 Apr 2021 18:25:18 GMT | sent 3500 objects to destination elasticsearch, wrote 3500
Wed, 14 Apr 2021 18:25:18 GMT | got 0 objects from source elasticsearch (offset: 303500)
Wed, 14 Apr 2021 18:25:18 GMT | Total Writes: 303500
Wed, 14 Apr 2021 18:25:18 GMT | dump complete
[MIGRATE]: some-log-000000002: INDEX MIGRATION IS COMPLETED AT 2021-04-14::18:25:19.
```

### Sample indcies information post migration:
**SOURCE & DEST indix information after migration.**

    health status   cluster     index                         uuid                    pri     rep     docs.count      docs.deleted    store.size      pri.store.size
    green  open     SOURCE-ES      some-log-000000001     vo5eO32nTmWtPONvMTg6EA   2      1         305397           23756           386mb           195.6mb
    green  open     DEST-ES    some-log-000000001     RpUz2cb3SiS_p1yn94kNng   1      1         282488            0              361.5mb         181.3mb
   