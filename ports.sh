#!/bin/bash


kubectl port-forward -n rococo svc/testnet-manager 8080:80 &
kubectl port-forward -n rococo svc/localrococo-bootnode-0 9944:9944 &
kubectl port-forward -n rococo svc/rococo-mythical-collator-alice-node-0 9945:9944 &

