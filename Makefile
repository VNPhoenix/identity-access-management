# IAM — Makefile
# Requires: Docker, Maven (mvn in PATH), Git
#
# COMMANDS
#   make docker-build [TAG=x]   Build Docker image  (default tag: pom.xml version)
#   make version-set VERSION=x  Update <version> in pom.xml

# On Windows, Chocolatey installs mvn.cmd; bare "mvn" fails CreateProcess.
# On Linux, mvn is the binary directly.
ifeq ($(OS),Windows_NT)
    MVN := mvn.cmd
else
    MVN := mvn
endif

IMAGE       := vnphoenix/iam
APP_VERSION := $(shell $(MVN) -q help:evaluate -Dexpression=project.version -DforceStdout 2>/dev/null)
BUILD_DATE  := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo unknown)
GIT_SHA     := $(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)
TAG         ?= $(APP_VERSION)

.DEFAULT_GOAL := help
.PHONY: help docker-build version-set

help:
	@echo ""
	@echo "Usage: make <target> [VARIABLE=value]"
	@echo ""
	@echo "Targets:"
	@echo "  docker-build                  Build Docker image (tag defaults to pom.xml version)"
	@echo "  docker-build TAG=foo          Build Docker image with a custom tag"
	@echo "  version-set VERSION=x.y.z     Update version in pom.xml"
	@echo ""
	@echo "Current values:"
	@echo "  IMAGE   = $(IMAGE)"
	@echo "  VERSION = $(APP_VERSION)"
	@echo "  TAG     = $(TAG)"
	@echo "  DATE    = $(BUILD_DATE)"
	@echo "  GIT_SHA = $(GIT_SHA)"
	@echo ""

# -----------------------------------------------------------------------------
# version-set
#   Update the <version> field in pom.xml using Maven Versions Plugin.
#
#   REQUIRED
#     VERSION   New semantic version to set.
#               Must follow SemVer: MAJOR.MINOR.PATCH  (e.g. 1.2.3)
#
#   USAGE
#     make version-set VERSION=1.2.3
# -----------------------------------------------------------------------------
version-set:
ifndef VERSION
	$(error VERSION is required - usage: make version-set VERSION=1.2.3)
endif
	$(MVN) -q versions:set -DnewVersion=$(VERSION) -DgenerateBackupPoms=false
	@echo "pom.xml version updated to $(VERSION)"

# -----------------------------------------------------------------------------
# docker-build
#   Build the Docker image and tag it.
#
#   OPTIONAL
#     TAG       Image tag to apply.
#               default: version read from pom.xml  (e.g. 1.0.0)
#               e.g.  make docker-build TAG=1.2.3
#               e.g.  make docker-build TAG=latest
#               e.g.  make docker-build TAG=dev
#
#   USAGE
#     make docker-build
#     make docker-build TAG=<tag>
# -----------------------------------------------------------------------------
docker-build:
	docker build \
	  --build-arg IMAGE="$(IMAGE)" \
	  --build-arg APP_VERSION="$(APP_VERSION)" \
	  --build-arg BUILD_DATE="$(BUILD_DATE)" \
	  --build-arg GIT_SHA="$(GIT_SHA)" \
	  --tag $(IMAGE):$(TAG) \
	  .
	@echo ""
	@echo "Successfully built: $(IMAGE):$(TAG)"
	@echo ""
