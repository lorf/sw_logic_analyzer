APP_NAME = app_logic_analyzer
USED_MODULES = module_usb_device module_usb_shared module_xud
VERBOSE = 0
DEBUG_BUILD ?= 1

COMMON_XCC_FLAGS += -Wall -O2 -g

ifeq ($(DEBUG_BUILD),1)
COMMON_XCC_FLAGS += -DDEBUG
USED_MODULES += module_locks module_uart_print
endif

#XCC_FLAGS_xtag2 = $(COMMON_XCC_FLAGS) -DTARGET_BOARD_XTAG2 -DXUD_SERIES_SUPPORT=XUD_L_SERIES

ifeq ($(CONFIG), xtag2) 
	TARGET = XTAG2.xn
	# Use XUD library for L-series controllers
	MODULE_LIBRARIES = xud_l
	POSTBUILD_TARGET += dynamic_bin
	DYNAMIC_BIN_XE_SECTION = n0c0
endif

XCC_FLAGS_startkit = $(COMMON_XCC_FLAGS) -DTARGET_BOARD_STARTKIT -DXUD_SERIES_SUPPORT=XUD_U_SERIES

ifeq ($(CONFIG), startkit) 
	TARGET = XS1-U8A-64-FB96-C5
	#TARGET = XS1-U16A-128-FB217-C10
	# Use XUD library for U-series controllers
	MODULE_LIBRARIES = xud_u
	POSTBUILD_TARGET += dynamic_bin
	DYNAMIC_BIN_XE_SECTION = n1c0_2
endif


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
	mv $(BIN_DIR)/splitdir/image_$(DYNAMIC_BIN_XE_SECTION).bin $@
	rm -rf $(BIN_DIR)/splitdir

ifeq ($(CONFIG),All)

%.install: CONFIG0=$*
%.install: BIN_DIR0=$(BASE_DIR)/bin/$(if $(filter Default,$*),,$*)

%.install:
	@$(MAKE) BIN_DIR=$(BIN_DIR0) CONFIG=$(CONFIG0) install

install: $(foreach config,$(ALL_CONFIGS),$(config).install)

else

install: $(BIN_DIR)/$(APP_NAME).bin
	install -d -m 0755 $(DESTDIR)/$(PREFIX)/share/sigrok-firmware
	install -m 0644 $< $(DESTDIR)/$(PREFIX)/share/sigrok-firmware/xs1la-$(CONFIG).fw

endif
