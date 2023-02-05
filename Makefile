#===-- Toolchain setup -----------------------------------------------------===
#
# Everything meant to be included in the cryptex obviously needs to be built
# with the iOS SDK. The setup below should be satisfactory for compiling most
# applications that can be built using the public iOS SDK.
#
# For building applications that require headers not included in the standard
# iOS SDK, a "SDK graft" can be performed; an example of this exists in the
# private SRD repo.

export TOOLCHAIN	?= iOS14.0
export ARCH		:= arm64e
export SDK_PATH		:= $(shell xcrun --show-sdk-path --sdk iphoneos)

export CC		:= $(shell xcrun -f --toolchain $(TOOLCHAIN) clang)
export CXX		:= $(shell xcrun -f --toolchain $(TOOLCHAIN) clang++)

export CFLAGS		:= -isysroot $(SDK_PATH) -arch $(ARCH) -I$(SDK_PATH)/usr/include -DTARGET_OS_IPHONE=1 -DTARGET_OS_BRIDGE=0
export LDFLAGS		:= -isysroot $(SDK_PATH) -arch $(ARCH)
export CXXFLAGS		:= $(CFLAGS)
export CCFLAGS		:= $(CFLAGS)
export CPPFLAGS		:= -DUSE_GETCWD -isysroot $(SDK_PATH) -arch arm64

export LD_LIBRARY_PATH	:= $(SDK_PATH)/usr/lib

#===-- Cryptex properties --------------------------------------------------===

CRYPTEX_ID	?= com.example.barebones
CRYPTEX_VERSION	?= 1.0.1

#===-- Build variables -----------------------------------------------------===

BUILD_DIR	?= ./build

CRYPTEX		?= $(BUILD_DIR)/$(CRYPTEX_ID).cxbd
CRYPTEX_ROOT	?= $(BUILD_DIR)/$(CRYPTEX_ID).root
CRYPTEX_IMAGE	?= $(BUILD_DIR)/$(CRYPTEX_ID).dmg

# Effectively used as a flag to prevent building the cryptex disk image (slow)
# when the contents of the cryptex root have not changed.
ROOT_FLAG	:= $(BUILD_DIR)/.root_flag
ROOT_DAEMON_DIR	:= $(CRYPTEX_ROOT)/Library/LaunchDaemons
ROOT_BIN_DIR	:= $(CRYPTEX_ROOT)/usr/bin

# Used to silence needlessly-noisy commands.
HUSH		:= >/dev/null 2>&1

#===-- Standard targets ----------------------------------------------------===

.PHONY: all
all: $(CRYPTEX)

$(BUILD_DIR)/server: server.c entitlements.plist
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	codesign -s - --entitlements entitlements.plist $@

$(CRYPTEX_ROOT):
	@mkdir -p $(ROOT_DAEMON_DIR)
	@mkdir -p $(ROOT_BIN_DIR)

$(ROOT_FLAG): $(CRYPTEX_ROOT) $(BUILD_DIR)/server launchd.plist
	install $(BUILD_DIR)/server $(ROOT_BIN_DIR)
	install launchd.plist $(ROOT_DAEMON_DIR)/server.plist
	@touch $@

$(CRYPTEX_IMAGE): $(ROOT_FLAG)
	@rm -fr $@
	hdiutil create -fs hfs+ -srcfolder $(CRYPTEX_ROOT) $@ $(HUSH)

$(CRYPTEX): $(CRYPTEX_IMAGE)
	cryptexctl create --research --replace -o $(BUILD_DIR) --identifier=$(CRYPTEX_ID) --version=$(CRYPTEX_VERSION) --variant=research $(CRYPTEX_IMAGE) 

#===-- Auxiliary targets ---------------------------------------------------===

# Helper target to personalize and install the cryptex to a device; will not
# work if `CRYPTEXCTL_UDID` is not set.
.PHONY: install
install: $(CRYPTEX)
	cryptexctl uninstall $(CRYPTEX_ID) $(HUSH) || true
	cryptexctl personalize --replace -o $(BUILD_DIR) --variant=research $(CRYPTEX) || exit 1
	cryptexctl install --variant=research $(CRYPTEX).signed

.PHONY: clean
clean:
	@rm -fr $(BUILD_DIR)
