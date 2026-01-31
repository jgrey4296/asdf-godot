#!/usr/bin/env bash

# asdf env vars:
# ASDF_INSTALL_TYPE : version or ref
# ASDF_INSTALL_VERSION : full version number or git ref
# ASDF_INSTALL_PATH : where the tool should be
# ASDF_CONCURRENCY : number of cores
# ASDF_DOWNLOAD_PATH : where bin/download downloads to
# ASDF_PLUGIN_PATH : where the plugin is installed
# ASDF_PLUGIN_SOURCE_URL : url of the plugin
# ASDF_PLUGIN_PREV_REF : previous git-ref of plugin
# ASDF_PLUGIN_POST_REF : updated git-ref of plugin
# ASDF_CMD_FILE : full path of file being sourced

set -euo pipefail

GH_REPO="https://github.com/godotengine/godot"
TOOL_NAME="Godot"
TOOL_TEST="Godot --help"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

function sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

function list_github_tags() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/.*' | cut -d/ -f3- |
		sed -n "s/-stable//; p; s/$/_mono/; p"
}

function list_all_versions() {
	list_github_tags
}


# # -----

function gd-version-id () {
	echo "${ASDF_INSTALL_VERSION/_mono/}"
}

function gd-zip-file () {
	case "$ASDF_INSTALL_VERSION" in
		*_mono)
			echo "$(gd-extract-path).zip"
			;;
		*)
			echo "$(gd-bin-name).zip"
			;;
	esac
}

function gd-bin-name () {
	# returns eg: Godot_v4.5.1-stable_linux.x86_64
	sys_name="$(uname -s | sed 's/./\L&/')"
	is_mono=""
	case "$ASDF_INSTALL_VERSION" in
		*_mono)
			is_mono="_mono"
			;;
		*)
			;;
	esac
	echo "${TOOL_NAME}_v$(gd-version-id)-stable${is_mono}_${sys_name}.$(uname -m)"
}

function gd-extract-path () {
	# returns eg: Godot_v4.5.1-stable_linux_x86_64
	# note the underscore before x86..
	sys_name=$(uname -s | sed 's/./\L&/')
	case "${ASDF_INSTALL_VERSION}" in
		*_mono)
			echo -e "${TOOL_NAME}_v$(gd-version-id)--stable_mono_${sys_name}_$(uname -m)"
			;;
		*)
			exit
			;;
	esac
}
