TERMUX_PKG_HOMEPAGE=https://en.wikipedia.org/wiki/Util-linux
TERMUX_PKG_DESCRIPTION="Miscellaneous system utilities"
TERMUX_PKG_LICENSE="GPL-3.0-or-later, GPL-2.0-or-later, LGPL-2.1-or-later, BSD 3-Clause, BSD, ISC"
TERMUX_PKG_LICENSE_FILE="
	Documentation/licenses/COPYING.GPL-3.0-or-later
	Documentation/licenses/COPYING.GPL-2.0-or-later
	Documentation/licenses/COPYING.LGPL-2.1-or-later
	Documentation/licenses/COPYING.BSD-3-Clause
	Documentation/licenses/COPYING.BSD-4-Clause-UC
	Documentation/licenses/COPYING.ISC
"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2.42.1"
TERMUX_PKG_REVISION=4
TERMUX_PKG_SRCURL="https://www.kernel.org/pub/linux/utils/util-linux/v${TERMUX_PKG_VERSION:0:4}/util-linux-${TERMUX_PKG_VERSION}.tar.xz"
TERMUX_PKG_SHA256=82e9158eb12a9b0b569d84e1687fed9dd18fe89ccd8ef5ac3427218a7c0d7f7f
# <dependency>: <binaries linking to that dependency>
# libandroid-glob: lsclocks
# libandroid-posix-semaphore: lsipc, lsns and the lib{blkid,smartcols,uuid} subpackages
# libcap-ng: setpriv
# libsmartcols: cal, column, fincore, irqtop, losetup, lsclocks, lscpu, lsfd, lsipc, lsirq, lsns, prlimit, wdctl, zramctl
# ncurses: cal, dmesg, hexdump, irqtop, setterm, ul
# zlib: fsck.cramfs
#
# libcrypt would be required for newgrp and sulogin, which we are not building
TERMUX_PKG_DEPENDS="libandroid-glob, libandroid-posix-semaphore, libcap-ng, libsmartcols, ncurses, zlib"
TERMUX_PKG_ESSENTIAL=true
TERMUX_PKG_BREAKS="util-linux-dev"
TERMUX_PKG_REPLACES="util-linux-dev"
# ac_cv_type_struct_nsfs_file_handle=no：
# configure.ac 里是
#   AC_CHECK_TYPES([struct nsfs_file_handle], [], [], [[#include <linux/nsfs.h>]])
# 该检查只验证 <linux/nsfs.h>（NDK r30 起有），不验证 glibc 的
# struct file_handle / name_to_handle_at / open_by_handle_at（bionic 要 API >= 26）。
# 于是探测结果为 yes，nsenter.c 第 60 行
#   #if defined(HAVE_STRUCT_NSFS_FILE_HANDLE) && defined(HAVE_PIDFD_OPEN)
# 里的那段代码被编进来，而 UL_CHECK_SYSCALL([pidfd_open]) 只查 syscall 号
# （aarch64 恒有），所以 HAVE_PIDFD_OPEN 也是 yes，必然编译失败：
#   nsenter.c:189:27: error: variable has incomplete type 'struct file_handle'
#   nsenter.c:225:6: error: call to undeclared function 'name_to_handle_at'
# 强制置 no 与该文件既有的 ac_cv_* 覆盖风格一致，效果等同于把该特性编译掉，
# 也正是官方已发布 bootstrap 的实际形态（其中 bin/nsenter 不含
# name_to_handle_at / open_by_handle_at / nsfs 任何引用）。
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
ac_cv_func_setns=yes
ac_cv_func_statx=no
ac_cv_func_unshare=yes
ac_cv_func_uselocale=no
ac_cv_type_struct_statx=no
ac_cv_type_struct_fanotify_event_info_header=no
ac_cv_type_struct_nsfs_file_handle=no
--enable-setpriv
--disable-agetty
--disable-chmem
--disable-copyfilerange
--disable-eject
--disable-fdformat
--disable-hwclock-cmos
--disable-ipcmk
--disable-ipcrm
--disable-ipcs
--disable-kill
--disable-last
--disable-liblastlog2
--disable-logger
--disable-lsmem
--disable-makeinstall-chown
--disable-mesg
--disable-mountpoint
--disable-nologin
--disable-pivot_root
--disable-poman
--disable-raw
--disable-rfkill
--disable-switch_root
--disable-wall
"

termux_step_pre_configure() {
	case "$TERMUX_ARCH_BITS" in
		#prlimit() is only available in 64-bit bionic.
		64) TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" ac_cv_func_prlimit=yes";;
		32) TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" --disable-year2038";;
	esac

	LDFLAGS+=" -landroid-posix-semaphore"
	autoreconf -fi
}
