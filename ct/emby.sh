#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://emby.media/

APP="Emby"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/emby-server ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  LATEST=$(curl -fsSL https://api.github.com/repos/MediaBrowser/Emby.Releases/releases/latest | grep '"tag_name":' | cut -d'"' -f4)
  msg_info "Stopping ${APP}"
  systemctl stop emby-server
  msg_ok "Stopped ${APP}"

  msg_info "Updating ${APP}"
  $STD curl -fsSL "https://github.com/MediaBrowser/Emby.Releases/releases/download/${LATEST}/emby-server-deb_${LATEST}_amd64.deb" -o "emby-server-deb_${LATEST}_amd64.deb"
  $STD dpkg -i "emby-server-deb_${LATEST}_amd64.deb"
  rm "emby-server-deb_${LATEST}_amd64.deb"
  msg_ok "Updated ${APP}"

  msg_info "Starting ${APP}"
  systemctl start emby-server
  msg_ok "Started ${APP}"
  msg_ok "Updated Successfully"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8096${CL}"
