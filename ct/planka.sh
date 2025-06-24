#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/refs/heads/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/plankanban/planka

APP="PLANKA"
var_tags="${var_tags:-Todo,kanban}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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

  if [[ ! -f /etc/systemd/system/planka.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -s https://api.github.com/repos/plankanban/planka/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ "${RELEASE}" != "$(cat ~/.planka 2>/dev/null)" ]] || [[ ! -f ~/.planka ]]; then
    msg_info "Stopping $APP"
    systemctl stop planka
    msg_ok "Stopped $APP"

    msg_info "Updating $APP to ${RELEASE}"
    mkdir -p /opt/planka-backup
    mkdir -p /opt/planka-backup/favicons
    mkdir -p /opt/planka-backup/user-avatars
    mkdir -p /opt/planka-backup/background-images
    mkdir -p /opt/planka-backup/attachments
    mv /opt/planka/planka/.env /opt/planka-backup
    [ -n "$(ls -A /opt/planka/planka/public/favicons 2>/dev/null)" ] && mv /opt/planka/planka/public/favicons/* /opt/planka-backup/favicons/
    [ -n "$(ls -A /opt/planka/planka/public/user-avatars 2>/dev/null)" ] && mv /opt/planka/planka/public/user-avatars/* /opt/planka-backup/user-avatars/
    [ -n "$(ls -A /opt/planka/planka/public/background-images 2>/dev/null)" ] && mv /opt/planka/planka/public/background-images/* /opt/planka-backup/background-images/
    [ -n "$(ls -A /opt/planka/planka/private/attachments 2>/dev/null)" ] && mv /opt/planka/planka/private/attachments/* /opt/planka-backup/attachments/
    rm -rf /opt/planka
    fetch_and_deploy_gh_release "planka" "plankanban/planka" "prebuild" "latest" "/opt/planka" "planka-prebuild.zip"
    cd /opt/planka/planka
    $STD npm install
    mv /opt/planka-backup/.env /opt/planka/planka/
    [ -n "$(ls -A /opt/planka-backup/favicons 2>/dev/null)" ] && mv /opt/planka-backup/favicons/* /opt/planka/planka/public/favicons/
    [ -n "$(ls -A /opt/planka-backup/user-avatars 2>/dev/null)" ] && mv /opt/planka-backup/user-avatars/* /opt/planka/planka/public/user-avatars/
    [ -n "$(ls -A /opt/planka-backup/background-images 2>/dev/null)" ] && mv /opt/planka-backup/background-images/* /opt/planka/planka/public/background-images/
    [ -n "$(ls -A /opt/planka-backup/attachments 2>/dev/null)" ] && mv /opt/planka-backup/attachments/* /opt/planka/planka/private/attachments/
    msg_ok "Updated $APP to ${RELEASE}"

    msg_info "Starting $APP"
    systemctl start planka
    msg_ok "Started $APP"

    msg_ok "Update Successful"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:1337${CL}"
