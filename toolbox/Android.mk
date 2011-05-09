LOCAL_PATH:= $(call my-dir)
include $(CLEAR_VARS)

TOOLS := \
	cat \
	ps \
	kill \
	insmod \
	rmmod \
	lsmod \
	ifconfig \
	setconsole \
	rmdir \
	reboot \
	getevent \
	sendevent \
	date \
	wipe \
	sync \
	start \
	stop \
	notify \
	cmp \
	dmesg \
	route \
	hd \
	dd \
	getprop \
	setprop \
	watchprops \
	log \
	sleep \
	renice \
	printenv \
	smd \
	newfs_msdos \
	netstat \
	ioctl \
	schedtop \
	top \
	iftop \
	id \
	uptime \
	vmstat \
	nandread \
	ionice 

ifndef TINY_TOOLBOX
    TOOLS += \
        mkdir \
        ln \
        ls \
        mount \
        rm \
        umount \
        df \
        chmod \
        chown \
        mv \
        lsof	
endif

LOCAL_SRC_FILES:= \
	toolbox.c \
	$(patsubst %,%.c,$(TOOLS))

LOCAL_SHARED_LIBRARIES := libcutils libc

LOCAL_MODULE:= toolbox

ifneq ($(TARGET_RECOVERY_WRITE_MISC_PART),)
        LOCAL_CFLAGS += -DRECOVERY_WRITE_MISC_PART='$(TARGET_RECOVERY_WRITE_MISC_PART)'
endif
ifneq ($(TARGET_RECOVERY_PRE_COMMAND),)
	LOCAL_CFLAGS += -DRECOVERY_PRE_COMMAND='$(TARGET_RECOVERY_PRE_COMMAND)'
endif

# Including this will define $(intermediates).
#
include $(BUILD_EXECUTABLE)

$(LOCAL_PATH)/toolbox.c: $(intermediates)/tools.h

TOOLS_H := $(intermediates)/tools.h
$(TOOLS_H): PRIVATE_TOOLS := $(TOOLS)
$(TOOLS_H): PRIVATE_CUSTOM_TOOL = echo "/* file generated automatically */" > $@ ; for t in $(PRIVATE_TOOLS) ; do echo "TOOL($$t)" >> $@ ; done
$(TOOLS_H): $(LOCAL_PATH)/Android.mk
$(TOOLS_H):
	$(transform-generated-source)

# Make #!/system/bin/toolbox launchers for each tool.
#
SYMLINKS := $(addprefix $(TARGET_OUT)/bin/,$(TOOLS))
$(SYMLINKS): TOOLBOX_BINARY := $(LOCAL_MODULE)
$(SYMLINKS): $(LOCAL_INSTALLED_MODULE) $(LOCAL_PATH)/Android.mk
	@echo "Symlink: $@ -> $(TOOLBOX_BINARY)"
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) ln -sf $(TOOLBOX_BINARY) $@

ALL_DEFAULT_INSTALLED_MODULES += $(SYMLINKS)

# We need this so that the installed files could be picked up based on the
# local module name
ALL_MODULES.$(LOCAL_MODULE).INSTALLED := \
    $(ALL_MODULES.$(LOCAL_MODULE).INSTALLED) $(SYMLINKS)

# Create separate executables for tools that depend on
# additional shared libraries
include $(CLEAR_VARS)

ifneq ($(BOARD_SUPPORTS_GRALLOC_FB_READ),)
	LOCAL_CFLAGS += -DGRALLOC_FB_READ_SUPPORTED
	LOCAL_CFLAGS += -include $(BOARD_SUPPORTS_GRALLOC_FB_READ)
endif

ifneq ($(TARGET_RECOVERY_WRITE_MISC_PART),)
	LOCAL_CFLAGS += -DRECOVERY_WRITE_MISC_PART='$(TARGET_RECOVERY_WRITE_MISC_PART)'
endif

LOCAL_SRC_FILES := fbread.c
LOCAL_SHARED_LIBRARIES := libcutils libc libhardware
LOCAL_MODULE := fbread
LOCAL_MODULE_TAGS := eng

include $(BUILD_EXECUTABLE)
