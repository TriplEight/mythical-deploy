#!/bin/bash
set -x
export TESTNET_MGR_URL="localhost:8080"
export RELAYCHAIN_WS="localhost"

# Register more validators
echo 'Registering validators'
curl -X 'POST' "http://${TESTNET_MGR_URL}/api/validators/register?statefulset=localrococo-validator-a-node" -H 'accept: application/json' -d ''

echo 'Sleeping while validators are onboarded'
sleep 30

# Onboard Parachains
echo 'Registering parachains'
curl -X 'POST' "http://${TESTNET_MGR_URL}/api/parachains/onboard?para_id=1000" -H 'accept: application/json' -d ''
sleep 10
curl -X 'POST' "http://${TESTNET_MGR_URL}/api/parachains/onboard?para_id=2058" -H 'accept: application/json' -d ''
sleep 10


# Wait for parachain onboarding
echo 'Sleep for parachain onboarding and initial block'
sleep 180 

# Setup hrmp channels
shopt -s expand_aliases
alias polkadot-js-api="docker run --network=host jacogr/polkadot-js-tools api"

polkadot-js-api --ws ws://$RELAYCHAIN_WS:9944 tx.parasSudoWrapper.sudoEstablishHrmpChannel 1000 2058 8 512   --seed "//Alice" --sudo
polkadot-js-api --ws ws://$RELAYCHAIN_WS:9944 tx.parasSudoWrapper.sudoEstablishHrmpChannel 2058 1000 8 512   --seed "//Alice" --sudo
