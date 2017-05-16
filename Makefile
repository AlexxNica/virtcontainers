PREFIX := /usr
BIN_DIR := $(PREFIX)/bin
VC_BIN_DIR := $(BIN_DIR)/virtcontainers/bin
TEST_BIN_DIR := $(VC_BIN_DIR)/test
VIRTC_DIR := hack/virtc
VIRTC_BIN := virtc
PAUSE_DIR := pause
PAUSE_BIN := pause
HOOK_DIR := hook/mock
HOOK_BIN := hook
SHIM_DIR := shim/mock
SHIM_BIN := shim

#
# Pretty printing
#

V	      = @
Q	      = $(V:1=)
QUIET_GOBUILD = $(Q:@=@echo    '     GOBUILD  '$@;)

#
# Build
#

all: build binaries

build:
	$(QUIET_GOBUILD)go build $(go list ./... | grep -v /vendor/)

virtc:
	$(QUIET_GOBUILD)go build -o $(VIRTC_DIR)/$@ $(VIRTC_DIR)/*.go

pause:
	make -C $@

hook:
	$(QUIET_GOBUILD)go build -o $(HOOK_DIR)/$@ $(HOOK_DIR)/*.go

shim:
	$(QUIET_GOBUILD)go build -o $(SHIM_DIR)/$@ $(SHIM_DIR)/*.go

binaries: virtc pause hook shim

#
# Tests
#

check: check-go-static check-go-test

check-go-static:
	.ci/go-lint.sh

check-go-test:
	.ci/go-test.sh \
		$(TEST_BIN_DIR)/$(SHIM_BIN) \
		$(TEST_BIN_DIR)/$(HOOK_BIN)

#
# Install
#

define INSTALL_EXEC
	install -D $1 $(VC_BIN_DIR)/ || exit 1;
endef

define INSTALL_TEST_EXEC
	install -D $1 $(TEST_BIN_DIR)/ || exit 1;
endef

install:
	@mkdir -p $(VC_BIN_DIR)
	$(call INSTALL_EXEC,$(VIRTC_DIR)/$(VIRTC_BIN))
	$(call INSTALL_EXEC,$(PAUSE_DIR)/$(PAUSE_BIN))
	@mkdir -p $(TEST_BIN_DIR)
	$(call INSTALL_TEST_EXEC,$(HOOK_DIR)/$(HOOK_BIN))
	$(call INSTALL_TEST_EXEC,$(SHIM_DIR)/$(SHIM_BIN))

#
# Uninstall
#

define UNINSTALL_EXEC
	rm -f $(VC_BIN_DIR)/$1 || exit 1;
endef

define UNINSTALL_TEST_EXEC
	rm -f $(TEST_BIN_DIR)/$1 || exit 1;
endef

uninstall:
	$(call UNINSTALL_EXEC,$(VIRTC_BIN))
	$(call UNINSTALL_EXEC,$(PAUSE_BIN))
	$(call UNINSTALL_TEST_EXEC,$(HOOK_BIN))
	$(call UNINSTALL_TEST_EXEC,$(SHIM_BIN))

#
# Clean
#

clean:
	rm -f $(VIRTC_DIR)/$(VIRTC_BIN)
	make -C $(PAUSE_BIN) clean
	rm -f $(HOOK_DIR)/$(HOOK_BIN)
	rm -f $(SHIM_DIR)/$(SHIM_BIN)

.PHONY: \
	all \
	build \
	virtc \
	pause \
	hook \
	shim \
	binaries \
	check \
	check-go-static \
	check-go-test \
	install \
	uninstall \
	clean
