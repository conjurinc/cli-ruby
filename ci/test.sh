#!/bin/bash

conjur_cid="$1"

docker exec $conjur_cid bash -c "cd /src/cli; unset CONJUR_AUTHN_LOGIN; bundle exec rake jenkins || true"
