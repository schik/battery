include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME=Battery

Battery_APPLICATION_ICON=battery-charged.tiff

ifeq ($(trayicon), no)
Battery_OBJCFLAGS += -DNOTRAYICON
endif

#
# Additional libraries
#
Battery_GUI_LIBS = -lDBusKit

ifneq ($(trayicon), no)
Battery_GUI_LIBS += -lTrayIconKit
endif

Battery_OBJC_FILES = \
	main.m \
	ApplicationDelegate.m \
	Battery.m \
	BatteryIconController.m \
	UpowerHandler.m

Battery_RESOURCE_FILES = \
	Images/16 \
	Images/48 \
	Images/48/battery-charged.tiff

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble

