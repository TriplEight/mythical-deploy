## Deployment runbook:

Two github repos: 
- Deployment Repo - https://gitlab.parity.io/ddorgan/tellor
- Tellor Github Repo  - https://github.com/tellor-io/tellor-parachain-demo

## Checkout Repos:

Checkout both repos. For the tellor github repo it uses submodules so run:
`git clone --recursive https://github.com/tellor-io/tellor-parachain-demo`

## Prepare Tellor Repo:

`./scripts/build.sh`

## Run Deployment from deployment repo:

- make setup
- make apply

### Open ports to remote hosts

Run `./ports.sh` from deployment repo

