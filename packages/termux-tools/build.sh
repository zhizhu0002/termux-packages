TERMUX_PKG_HOMEPAGE=https://termux.dev/
TERMUX_PKG_DESCRIPTION="Basic system tools for Termux"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.46.0+really1.45.0"
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=https://github.com/termux/termux-tools/archive/refs/tags/v1.45.0.tar.gz
TERMUX_PKG_SHA256=1ae29b1b875d95cc626dae323b45a2ace759969862d96094b2fa6d13bffe20d2
TERMUX_PKG_ESSENTIAL=true
#TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"
TERMUX_PKG_BREAKS="termux-keyring (<< 1.9)"
TERMUX_PKG_CONFLICTS="procps (<< 3.3.15-2)"
TERMUX_PKG_SUGGESTS="termux-api"

# Some of these packages are not dependencies and used only to ensure
# that core packages are installed after upgrading (we removed busybox
# from essentials).
TERMUX_PKG_DEPENDS="bzip2, coreutils, curl, dash, diffutils, findutils, gawk, grep, gzip, less, procps, psmisc, sed, tar, termux-am (>= 0.8.0), termux-am-socket (>= 1.5.0), termux-core, termux-exec, util-linux, xz-utils, dialog"

# Optional packages that are distributed as part of bootstrap archives.
TERMUX_PKG_RECOMMENDS="ed, dos2unix, inetutils, net-tools, patch, unzip"

termux_step_pre_configure() {
	# ---- fork 包名修复：configure.ac 只认**环境变量**，这里必须显式 export ----
	#
	# termux-tools 的 configure.ac 用 `${VAR+set}` 判断环境变量，取不到就用硬编码
	# 的 com.termux 兜底：
	#   if test "${TERMUX_APP_PACKAGE+set}" = set; then termux_app_package="$TERMUX_APP_PACKAGE"
	#   else termux_app_package="com.termux"; fi
	#   if test "${TERMUX_PREFIX+set}" = set; then termux_prefix="$TERMUX_PREFIX"
	#   else termux_prefix="$termux_base_dir/usr"; fi
	# 而 scripts/properties.sh 只定义这些 shell 变量、**从不 export**，
	# scripts/build-package.sh 里也没有任何 `export TERMUX_*`（全仓库 grep 为 0），
	# 于是 configure 这个**子进程**看不到它们，一路走 fallback。
	#
	# 官方构建 prefix 恒为 /data/data/com.termux，fallback 恰好等于真值，所以上游
	# 永远不暴露；fork 改了包名之后，fallback 就把旧前缀写进产物：
	#   - 编译期 -DTERMUX_APP_PACKAGE/-DTERMUX_BASE_DIR/-DTERMUX_CACHE_DIR/
	#     -DTERMUX_PREFIX/-DTERMUX_ANDROID_HOME（实测见构建日志）
	#   - Makefile 生成的 preinst：printf "#!%s/bin/bash" "$(termux_prefix)"
	#   - mirrors/ 往 preinst 追加的片段
	#   - etc/motd*、init-termux-properties.sh 等 conffiles 内容
	# 这些都会随 deb 进 bootstrap（var/lib/dpkg/info/termux-tools.preinst 等），
	# 最后被「旧前缀必须为 0」的验收 grep 命中，整轮构建白跑。
	#
	# 故意不传 TERMUX_PACKAGE_FORMAT / TERMUX_PACKAGE_MANAGER：
	#   - TERMUX_PACKAGE_FORMAT 在 properties.sh 里**不存在**，其 fallback "debian"
	#     正是本工程 bootstrap 的格式（build-bootstraps.sh 走 apt 分支）；
	#   - TERMUX_PACKAGE_MANAGER 已由 workflow 通过
	#     TERMUX_DOCKER_EXEC_EXTRA_ARGS="--env TERMUX_PACKAGE_MANAGER=apt" 注入。
	# 这两个 fallback 值恰好正确，不必也不应在此覆盖。
	export TERMUX_APP_PACKAGE="$TERMUX_APP__PACKAGE_NAME"
	export TERMUX_BASE_DIR="$TERMUX__ROOTFS"
	export TERMUX_CACHE_DIR="$TERMUX__CACHE_DIR"
	export TERMUX_PREFIX="$TERMUX__PREFIX"
	export TERMUX_ANDROID_HOME="$TERMUX__HOME"

	autoreconf -vfi
}

termux_step_post_make_install() {
	TERMUX_PKG_CONFFILES="$(cat "$TERMUX_PKG_BUILDDIR/conffiles")"
}

termux_step_create_debscripts() {
	cat <<- EOF > ./preinst
	$(cat "$TERMUX_PKG_BUILDDIR/preinst")
	EOF
}
