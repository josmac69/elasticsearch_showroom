ifdef_check = $(if $(SCRIPT),,@echo "SCRIPT variable is not set or empty"; exit 1)

.PHONY: create-env \
	create-network \
	build-python \
	start-elasticsearch \
	elasticsearch-cli \
	run-python \
	stop-all

NETWORK_NAME = elastic
PYTHON_IMAGE = python_elasticsearch_showroom

build-python:
	docker build --progress=plain --no-cache -t "$(PYTHON_IMAGE)" -f Dockerfile.python .

create-env:
	mkdir -p ./es_data
	mkdir -p ./secrets
	mkdir -p ./data_inputs
	mkdir -p ./data_outputs

create-network: create-env
	docker network inspect $(NETWORK_NAME) >/dev/null 2>&1 || docker network create $(NETWORK_NAME)

start-elasticsearch: create-network
	docker run -it \
	--network $(NETWORK_NAME) \
	--name elasticsearch \
	-v "${PWD}/es_data":/data \
	-p 9200:9200 \
	-p 9300:9300 \
	-e "discovery.type=single-node" \
	elasticsearch:8.7.0

elasticsearch-cli:
	docker exec -it elasticsearch-stack elasticsearch-cli

run-python: create-network
	$(call ifdef_check)
	docker run -it --rm \
	--net $(NETWORK_NAME) \
	-v "${PWD}/data_inputs/":"/inputs" \
	-v "${PWD}/data_outputs/":"/outputs" \
	-v "${PWD}/secrets":/secrets \
	-v "${PWD}/$(SCRIPT)":/app \
	"$(PYTHON_IMAGE)"

stop-all:
	docker ps -aq | xargs -L1 docker rm -f
