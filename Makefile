-include env_make

KUBEADM_VER ?= 1.11
TAG ?= $(KUBEADM_VER)

REPO = wodbycloud/kubeadm-dind
NAME = wodbycloud-kubeadm-dind

ifneq ($(STABILITY_TAG),)
    ifneq ($(TAG),latest)
        override TAG := $(TAG)-$(STABILITY_TAG)
    endif
endif

.PHONY: build test push shell run start stop logs clean release

default: build

build:
	docker build -t $(REPO):$(TAG) --build-arg KUBEADM_VER=$(KUBEADM_VER) ./
	# pre-pull images and commit.
	$(eval cid = $(shell make start))
	docker exec $(cid) docker pull busybox:1.26.2 mirantis/kubeadm-dind-cluster:v1.11
	docker exec $(cid) sh -c 'echo "" > ~/.ash_history'
	docker exec $(cid) rm -rf /docker/runtimes
	docker commit $(cid) $(REPO):$(TAG)
	make clean

test:
	echo "no tests :("

push:
	docker push $(REPO):$(TAG)

shell:
	docker run --rm --name $(NAME) -i -t $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) /bin/bash

run:
	docker run --rm --privileged --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) $(CMD)

# !important keep @ at the beginning.
start:
	@docker run -d  --privileged --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG)

stop:
	docker stop $(NAME)

logs:
	docker logs $(NAME)

clean:
	-docker rm -f $(NAME)

release: build push
