#
# Environment Variables
#

REPOSITORY    ?= takumi/samba-ad-dc
ALPINE_BRANCH ?= latest

#
# Docker Build Variables
#

BUILD_ARGS ?= --build-arg ALPINE_BRANCH=$(ALPINE_BRANCH)

ifneq (x${no_proxy}x,xx)
BUILD_ARGS += --build-arg no_proxy=${no_proxy}
endif
ifneq (x${NO_PROXY}x,xx)
BUILD_ARGS += --build-arg NO_PROXY=${NO_PROXY}
endif

ifneq (x${ftp_proxy}x,xx)
BUILD_ARGS += --build-arg ftp_proxy=${ftp_proxy}
endif
ifneq (x${FTP_PROXY}x,xx)
BUILD_ARGS += --build-arg FTP_PROXY=${FTP_PROXY}
endif

ifneq (x${http_proxy}x,xx)
BUILD_ARGS += --build-arg http_proxy=${http_proxy}
endif
ifneq (x${HTTP_PROXY}x,xx)
BUILD_ARGS += --build-arg HTTP_PROXY=${HTTP_PROXY}
endif

ifneq (x${https_proxy}x,xx)
BUILD_ARGS += --build-arg https_proxy=${https_proxy}
endif
ifneq (x${HTTPS_PROXY}x,xx)
BUILD_ARGS += --build-arg HTTPS_PROXY=${HTTPS_PROXY}
endif

#
# Docker Run Variables
#

RUN_ARGS ?= env REPOSITORY=$(REPOSITORY) ALPINE_BRANCH=$(ALPINE_BRANCH)

#
# Default Rules
#

.PHONY: all
all: build up

#
# Build Rules
#

.PHONY: build
build:
	@$(RUN_ARGS) docker-compose build --parallel $(BUILD_ARGS)

#
# Test Rules
#

.PHONY: up
up: down
	@$(RUN_ARGS) docker-compose up -d

.PHONY: down
down:
ifneq (x$(shell docker-compose --log-level ERROR ps -q),x)
	@docker-compose down
endif

#
# Clean Rules
#

.PHONY: clean
clean: down
	@docker system prune -f
	@docker volume prune -f
