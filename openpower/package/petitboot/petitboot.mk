################################################################################
#
# petitboot
#
################################################################################

# 1/29 - pje updated to pull in petitboot from a different branch
# pulled it down into my local space as:
# git clone http://github.com/open-power/petitboot -b version_info_all
#
#PETITBOOT_VERSION = LOCAL_version_info_all_branch_sammj
### was: d171258160f7ed4756531f51e66fb116753bc990
#PETITBOOT_SITE=/esw/user/nfs/fspbld/openPower/version_info/petitboot
#PETITBOOT_SITE_METHOD=local
##PETITBOOT_SITE = git://github.com/open-power/petitboot
# was from petitboot/petitboot.git

# claims to be an invalid git repo, unknown -b option, etc, etc...
# so pointed to version_info_all branch (which was merged at some 
# point and then deleted)
#PETITBOOT_VERSION ?= version_info_all

# 2/17 - pje - petitboot mtd changes are merged into the 
#              gitbhub/open-power/petitboot repo. Update
#              to use the newer commit

PETITBOOT_VERSION ?= d531395a3ff60730238854b127925978f6eab289

PETITBOOT_SITE = git://github.com/open-power/petitboot.git
PETITBOOT_DEPENDENCIES = ncurses udev host-bison host-flex lvm2
PETITBOOT_LICENSE = GPLv2
PETITBOOT_LICENSE_FILES = COPYING

PETITBOOT_AUTORECONF = YES
PETITBOOT_AUTORECONF_OPTS = -i
PETITBOOT_GETTEXTIZE = YES
PETITBOOT_CONF_OPTS += --with-ncurses --without-twin-x11 --without-twin-fbdev \
	      --localstatedir=/var \
	      HOST_PROG_KEXEC=/usr/sbin/kexec \
	      HOST_PROG_SHUTDOWN=/usr/libexec/petitboot/bb-kexec-reboot \
	      $(if $(BR2_PACKAGE_BUSYBOX),--with-tftp=busybox)

ifdef PETITBOOT_DEBUG
PETITBOOT_CONF_OPTS += --enable-debug
endif

# pje - 02/17 - added for petitboot_mtd support:
ifeq ($(BR2_PACKAGE_PETITBOOT_MTD),y)
PETITBOOT_CONF_OPTS += --enable-mtd
PETITBOOT_DEPENDENCIES += skiboot libxml2
PETITBOOT_CPPFLAGS += -I$(STAGING_DIR)
PETITBOOT_LDFLAGS += -L$(STAGING_DIR)
endif

ifeq ($(BR2_PACKAGE_NCURSES_WCHAR),y)
PETITBOOT_CONF_OPTS += --with-ncursesw MENU_LIB=-lmenuw FORM_LIB=-lformw
endif

PETITBOOT_PRE_CONFIGURE_HOOKS += PETITBOOT_PRE_CONFIGURE_BOOTSTRAP

define PETITBOOT_POST_INSTALL
	$(INSTALL) -D -m 0755 $(@D)/utils/bb-kexec-reboot \
		$(TARGET_DIR)/usr/libexec/petitboot
	$(INSTALL) -d -m 0755 $(TARGET_DIR)/etc/petitboot/boot.d
	$(INSTALL) -D -m 0755 $(@D)/utils/hooks/01-create-default-dtb \
		$(TARGET_DIR)/etc/petitboot/boot.d/
	$(INSTALL) -D -m 0755 $(@D)/utils/hooks/20-set-stdout \
		$(TARGET_DIR)/etc/petitboot/boot.d/
	$(INSTALL) -D -m 0755 $(@D)/utils/hooks/90-sort-dtb \
		$(TARGET_DIR)/etc/petitboot/boot.d/

	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL)/package/petitboot/S14silence-console \
		$(TARGET_DIR)/etc/init.d/
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL)/package/petitboot/S15pb-discover \
		$(TARGET_DIR)/etc/init.d/
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL)/package/petitboot/kexec-restart \
		$(TARGET_DIR)/usr/sbin/
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL)/package/petitboot/petitboot-console-ui.rules \
		$(TARGET_DIR)/etc/udev/rules.d/
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL)/package/petitboot/removable-event-poll.rules \
		$(TARGET_DIR)/etc/udev/rules.d/
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL)/package/petitboot/63-md-raid-arrays.rules \
		$(TARGET_DIR)/etc/udev/rules.d/
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL)/package/petitboot/65-md-incremental.rules \
		$(TARGET_DIR)/etc/udev/rules.d/

	ln -sf /usr/sbin/pb-udhcpc \
		$(TARGET_DIR)/usr/share/udhcpc/default.script.d/

	$(MAKE) -C $(@D)/po DESTDIR=$(TARGET_DIR) install
endef

PETITBOOT_POST_INSTALL_TARGET_HOOKS += PETITBOOT_POST_INSTALL

$(eval $(autotools-package))
