.phony: cluster install clean

cluster:
	@kind create cluster --config=01_installation/kind.yaml --wait 200s
	@kubectl cluster-info --context kind-kind

install:
	@01_installation/install.sh

clean:
	@kind delete cluster