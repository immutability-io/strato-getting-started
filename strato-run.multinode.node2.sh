#!/usr/bin/env bash

# Optional arguments:
# `--stop` - stop STRATO containers
# `--wipe` - stop STRATO containers and wipe out volumes
# `--stable` - run stable STRATO version (latest is by default)

set -e

registry="registry-aws.blockapps.net:5000"

function wipe {
    echo "Stopping STRATO containers"
    docker-compose -f docker-compose.latest.yml -p strato kill 2> /dev/null || docker-compose -f docker-compose.release.yml -p strato kill
    docker-compose -f docker-compose.latest.yml -p strato down -v 2> /dev/null || docker-compose -f docker-compose.release.yml -p strato down -v
}

function stop {
    echo "Stopping STRATO containers"
    docker-compose -f docker-compose.latest.yml -p strato kill 2> /dev/null || docker-compose -f docker-compose.release.yml -p strato kill
    docker-compose -f docker-compose.latest.yml -p strato down 2> /dev/null || docker-compose -f docker-compose.release.yml -p strato down
}

mode=${STRATO_GS_MODE:="0"}
stable=false

while [ ${#} -gt 0 ]; do
  case "${1}" in
  --stop|-stop)
    echo "Stopping STRATO containers"
    stop
    exit 0
    ;;
  --wipe|-wipe)
    echo "Stopping STRATO containers and wiping out volumes"
    wipe
    exit 0
    ;;
  --stable|-stable)
    echo "Deploying the stable version"
    stable=true
    ;;
  -m)
    echo "Mode is set to $2"
    mode="$2"
    shift
    ;;
  esac

  shift 1
done

echo "
    ____  __           __   ___
   / __ )/ /___  _____/ /__/   |  ____  ____  _____
  / __  / / __ \/ ___/ //_/ /| | / __ \/ __ \/ ___/
 / /_/ / / /_/ / /__/ ,< / ___ |/ /_/ / /_/ (__  )
/_____/_/\____/\___/_/|_/_/  |_/ .___/ .___/____/
                              /_/   /_/
"

if ! docker ps &> /dev/null
then
    echo 'Error: docker is required to be installed and configured for non-root users: https://www.docker.com/'
    exit 1
fi

if ! docker-compose -v &> /dev/null
then
    echo 'Error: docker-compose is required: https://docs.docker.com/compose/install/'
    exit 2
fi

if grep -q "${registry}" ~/.docker/config.json
then



    export NODE_HOST="p2pnode2.eastus.cloudapp.azure.com"
    export BOOT_NODE_HOST="p2pnode3.eastus.cloudapp.azure.com"
    export NODE_NAME=$NODE_HOST
    export BLOC_URL="https://$NODE_HOST/bloc/v2.1"
    export BLOC_DOC_URL="http://$NODE_HOST/docs/?url=/bloc/v2.1/swagger.json"
    export STRATO_URL="https://$NODE_HOST/strato-api/eth/v1.2"
    export STRATO_DOC_URL="https://$NODE_HOST/docs/?url=/strato-api/eth/v1.2/swagger.json"
    export cirrusurl=nginx/cirrus
    export stratoHost=nginx
    export ssl=true

    echo "Using environment:"
    echo "NODE NAME: $NODE_NAME"
    echo "BLOC_URL: $BLOC_URL"
    echo "BLOC_DOC_URL: $BLOC_DOC_URL"
    echo "STRATO_URL: $STRATO_URL"
    echo "STRATO_DOC_URL: $STRATO_DOC_URL"
    echo "cirrusurl: $cirrusurl"
    echo "stratoHost: $stratoHost"
    echo "ssl: $ssl"

    # TODO: (before production release) add switch indicating a preference for `stable` vs `latest` (see `strato-run.sh` for an example)
    # TODO: (before production release) add switch enabling MixPanel tracking (see `strato-run.sh` for an example)
    # TODO: (before production release) re-enable docker-compose fetch from github (see `strato-run.sh` for an example)

    genesisBlock=$(< gb.json) \
      stratoHost="nginx" \
      ssl=$ssl \
      cirrusurl="http://cirrus" \
      miningAlgorithm="SHA" \
      lazyBlocks=false \
      explorerHost="http://explorer" \
      explorerAdvertise="https://$NODE_HOST" \
      bootnode=$BOOT_NODE_HOST \
      syncMode=true \
      docker-compose -f docker-compose.release.yml -p strato up -d
else
    echo "Please login to BlockApps Public Registry first:
1) Register for access to STRATO Developer Edition trial here: http://developers.blockapps.net/trial
2) Follow the instructions from the registration email to login to BlockApps Public Registry;
3) Run this script again"
    exit 3
fi
