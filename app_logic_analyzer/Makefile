TARGET = XS1-U16A-128-FB217-C10
#TARGET = XS1-U8A-64-FB96-C5
XCC_FLAGS = -O2 -DUSB_CORE=0 -g
APP_NAME = app_logic_analyzer
USED_MODULES = module_usb_device module_usb_shared module_xud
VERBOSE = 0
POSTBUILD_TARGET += dynamic_bin

#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common


# Local actions
dynamic_bin: $(BIN_DIR)/$(APP_NAME).bin
$(BIN_DIR)/$(APP_NAME).bin: $(BIN_DIR)/$(APP_NAME).xe
	mkdir -p $(BIN_DIR)/splitdir
	xobjdump --strip --split --split-dir $(BIN_DIR)/splitdir $<
	for bin in $(BIN_DIR)/splitdir/image_n*c0_2.bin; do \
		node=`echo "$$bin" | sed 's/.*_n\([0-9]\)c0.*/\1/'`; \
		mv "$$bin" $(BIN_DIR)/$(APP_NAME)_n$$node.bin; \
	done
	rm -rf $(BIN_DIR)/splitdir
