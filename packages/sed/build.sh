TERMUX_PKG_HOMEPAGE=https://www.gnu.org/software/sed/
TERMUX_PKG_DESCRIPTION="GNU stream editor for filtering/transforming text"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION=4.10
TERMUX_PKG_SRCURL="https://mirrors.kernel.org/gnu/sed/sed-${TERMUX_PKG_VERSION}.tar.xz"
TERMUX_PKG_SHA256=b8e72182b2ec96a3574e2998c47b7aaa64cc20ce000d8e9ac313cc07cecf28c7
TERMUX_PKG_ESSENTIAL=true
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_GROUPS="base-devel"

# --without-selinux 是必需的，别删。
#
# gnulib 的 selinux-selinux-h.m4 把 with_selinux 默认设成 maybe（自动探测），于是
# 只要构建环境里能找到 libselinux 头/库，sed 就会被编入 SELinux 支持，之后每次
# 「sed -i」都去调 setfscreatecon()，而 Android 上普通应用无权设置创建上下文，
# 于是打印：
#   sed: warning: failed to set default file creation context to
#        u:object_r:app_data_file:s0:...: Permission denied
#
# 官方 CI 每个包在**独立容器**里构建，sed 看不到 libandroid-selinux，所以不会发生。
# 而 fork 的 scripts/build-bootstraps.sh 是**单容器按依赖顺序从源码全编**：
# coreutils 先把 libandroid-selinux 装进 $TERMUX_PREFIX，sed 的 configure 就探到了。
#
# 判据：本包元数据**没有** TERMUX_PKG_DEPENDS，也没有 -landroid-selinux，说明链接它
# 本来就非本意（coreutils 则相反：显式声明依赖并主动链接，那是设计如此，故不动它）。
# 实测证据：生成的 bin/sed 里同时含 "libandroid-selinux.so" 与那句警告字符串。
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--without-selinux
ac_cv_func_nl_langinfo=no
ac_cv_header_langinfo_h=no
am_cv_langinfo_codeset=no
gl_cv_func_setlocale_works=yes
"

termux_step_pre_configure() {
	CFLAGS+=" -D__USE_FORTIFY_LEVEL=2"
}

termux_step_post_configure() {
	touch -d "next hour" "$TERMUX_PKG_SRCDIR/doc/sed.1"
}
