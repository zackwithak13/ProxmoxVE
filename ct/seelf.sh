#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/YuukanOO/seelf

APP="seelf"
var_tags="${var_tags:-server;docker}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/seelf ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if fetch_and_deploy_gh_release "seelf" "YuukanOO/seelf"; then
    msg_ok "$APP already at the latest version. No update required."
  else
    msg_info "Stopping $APP"
    systemctl stop seelf
    msg_ok "Stopped $APP"

    msg_info "Updating $APP"
    cd /opt/seelf
    $STD make build
    msg_ok "Updated $APP"

    msg_info "Starting $APP"
    systemctl start seelf
    msg_ok "Started $APP"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
