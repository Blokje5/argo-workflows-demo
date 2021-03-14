.phony: cluster install clean

cluster:
	@kind create cluster --config=01_installation/kind.yaml --wait 200s
	@kubectl cluster-info --context kind-kind

install:
	@01_installation/install.sh

hello:
	@cat 02_hello_world/hello.yaml
	@echo "\n"
	@argo submit 02_hello_world/hello.yaml -p message="goodbye"

install-minio:
	@04_file_io/install.sh

load-csv:
	@04_file_io/csv/load.sh

file-io:
	@cat 04_file_io/file.yaml
	@echo "\n"
	@argo submit 04_file_io/file.yaml

pod-racing:
	@argo submit 03_pod_racing/pod-racing.yaml

pod-racing-steps:
	@argo submit 03_pod_racing/pod-racing-steps.yaml

clean:
	@kind delete cluster