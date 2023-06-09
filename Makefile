# ============================================================================================
# Validator-manager Quick Deploy Makefile for Development and Testing
# ============================================================================================

# KUBERNETES_CONTEXT = gke_test-installations-222013_europe-central2-a_david-mythical-cluster-tmp
KUBERNETES_CONTEXT = gke_test-installations-222013_europe-west3-a_tellor-denis
# rococo or wococo (don't put space at the end of the variable it will be used as is)
CHAIN_NAMESPACE = rococo


# ============================================================================================

all: check build install

# ============================================================================================

kube: kube_${KUBERNETES_CONTEXT}

kube_minikube:
	@minikube start \
		--addons ingress --addons metrics-server --addons registry --driver docker \
		--kubernetes-version=1.23.3 --memory=8g --cpus=4

kube_minikube-podman:
	@minikube start \
		--addons ingress --addons metrics-server --addons registry --driver podman \
		--container-runtime=containerd --memory=8g --cpus=4

# ============================================================================================

check:
	@kubectl config use-context ${KUBERNETES_CONTEXT}
	@kubectl --context ${KUBERNETES_CONTEXT} get nodes

setup:
	@kubectl --context ${KUBERNETES_CONTEXT} apply -f ./kube-setup -f ./kube-setup

build: check build_${KUBERNETES_CONTEXT}

build_minikube:
	cd ../. && minikube image build . -t local/testnet-manager

# ============================================================================================

ports-open:
	# port-forwarding to local ports
	@nohup kubectl --context ${KUBERNETES_CONTEXT} port-forward -n ${CHAIN_NAMESPACE} svc/testnet-manager 8080:80 >/dev/null 2>&1 &
	@nohup kubectl --context ${KUBERNETES_CONTEXT} port-forward -n ${CHAIN_NAMESPACE} svc/local${CHAIN_NAMESPACE}-bootnode-0 9944:9944 >/dev/null 2>&1 &
	@nohup kubectl --context ${KUBERNETES_CONTEXT} port-forward -n ${CHAIN_NAMESPACE} svc/${CHAIN_NAMESPACE}-mythical-collator-alice-node-0 9945:9944 >/dev/null 2>&1 &

rpc:
	@xdg-open 'https://polkadot.js.org/apps/?rpc=ws%3A%2F%2F127.0.0.1%3A9944#/explorer'
	@kubectl --context ${KUBERNETES_CONTEXT} port-forward service/local${CHAIN_NAMESPACE}-bootnode 9944:9944 -n ${CHAIN_NAMESPACE}

para-moon:
	@xdg-open 'https://polkadot.js.org/apps/?rpc=ws%3A%2F%2F127.0.0.1%3A9949#/explorer'
	@kubectl --context ${KUBERNETES_CONTEXT} port-forward service/local${CHAIN_NAMESPACE}-moonbase-alice-node 9949:9944 -n ${CHAIN_NAMESPACE}

para-mint:
	@xdg-open 'https://polkadot.js.org/apps/?rpc=ws%3A%2F%2F127.0.0.1%3A9950#/explorer'
	@kubectl --context ${KUBERNETES_CONTEXT} port-forward service/local${CHAIN_NAMESPACE}-statemint-alice-node 9950:9944 -n ${CHAIN_NAMESPACE}

web:
	@xdg-open 'http://localhost:8080/'
	@kubectl --context ${KUBERNETES_CONTEXT} port-forward service/testnet-manager 8080:80 -n ${CHAIN_NAMESPACE}

web-tasks:
	@xdg-open 'http://localhost:8081/tasks'
	@kubectl --context ${KUBERNETES_CONTEXT} port-forward service/testnet-manager-task-scheduler 8081:80 -n ${CHAIN_NAMESPACE}

# ============================================================================================

apply: check
	@helmfile --file ./charts/helmfile-${CHAIN_NAMESPACE}.yaml apply
	@kubectl --context ${KUBERNETES_CONTEXT} delete pod  -l app.kubernetes.io/name=testnet-manager -n ${CHAIN_NAMESPACE}
	@kubectl --context ${KUBERNETES_CONTEXT} delete pod  -l app.kubernetes.io/name=testnet-manager-task-scheduler -n ${CHAIN_NAMESPACE} # force recreate testnet-manager pod

install: build setup apply

# ============================================================================================

reload: build
	@kubectl --context ${KUBERNETES_CONTEXT} delete pod  -l app.kubernetes.io/name=testnet-manager -n ${CHAIN_NAMESPACE}
	@kubectl --context ${KUBERNETES_CONTEXT} delete pod  -l app.kubernetes.io/name=testnet-manager-task-scheduler -n ${CHAIN_NAMESPACE}
	@make web

log:
	@kubectl --context ${KUBERNETES_CONTEXT}  logs --tail 50 -f -l app.kubernetes.io/name=testnet-manager -n ${CHAIN_NAMESPACE}

# ============================================================================================

ports-close:
	@pkill -f -e "port-forward -n ${CHAIN_NAMESPACE}"

uninstall: check
	@helmfile --file ./charts/helmfile-${CHAIN_NAMESPACE}.yaml destroy
	@kubectl --context ${KUBERNETES_CONTEXT} delete pvc -n ${CHAIN_NAMESPACE} --all

cleanup: check
	@kubectl --context ${KUBERNETES_CONTEXT} delete namespace ${CHAIN_NAMESPACE}

postinstall: check
	./postinstall.sh

deploy-contracts: check
	./deploy-contracts.sh
