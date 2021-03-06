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
	@03_file_io/install.sh

load-csv:
	@03_file_io/csv/load.sh

file-io:
	@cat 03_file_io/file.yaml
	@echo "\n"
	@argo submit 03_file_io/file.yaml

clean:
	@kind delete cluster