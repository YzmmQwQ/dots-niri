# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

#####################################################################################
# MISC (For dots/.config/* but not quickshell, not fish, not Hyprland, not Niri, not fontconfig)
case "${SKIP_MISCCONF}" in
  true) sleep 0;;
  *)
    for i in $(find dots/.config/ -mindepth 1 -maxdepth 1 ! -name 'quickshell' ! -name 'fish' ! -name 'hypr' ! -name 'niri' ! -name 'fontconfig' -exec basename {} \;); do
#      i="dots/.config/$i"
      echo "[$0]: Found target: dots/.config/$i"
      if [ -d "dots/.config/$i" ];then install_dir__sync "dots/.config/$i" "$XDG_CONFIG_HOME/$i"
      elif [ -f "dots/.config/$i" ];then install_file "dots/.config/$i" "$XDG_CONFIG_HOME/$i"
      fi
    done
    install_dir "dots/.local/share/konsole" "${XDG_DATA_HOME}"/konsole
    ;;
esac

case "${SKIP_QUICKSHELL}" in
  true) sleep 0;;
  *)
     # Should overwriting the whole directory not only ~/.config/quickshell/ii/ cuz https://github.com/end-4/dots-hyprland/issues/2294#issuecomment-3448671064
    install_dir__sync dots/.config/quickshell "$XDG_CONFIG_HOME"/quickshell
    ;;
esac

case "${SKIP_FISH}" in
  true) sleep 0;;
  *)
    install_dir__sync_exclude dots/.config/fish "$XDG_CONFIG_HOME"/fish "conf.d"
    ;;
esac

case "${SKIP_FONTCONFIG}" in
  true) sleep 0;;
  *)
    case "$FONTSET_DIR_NAME" in
      "") install_dir__sync dots/.config/fontconfig "$XDG_CONFIG_HOME"/fontconfig ;;
      *) install_dir__sync dots-extra/fontsets/$FONTSET_DIR_NAME "$XDG_CONFIG_HOME"/fontconfig ;;
    esac;;
esac

# For Hyprland
case "${SKIP_HYPRLAND}" in
  true) sleep 0;;
  *)
    install_dir__sync dots/.config/hypr/hyprland "$XDG_CONFIG_HOME"/hypr/hyprland
    for i in hyprlock.conf {monitors,workspaces}.conf ; do
      install_file__auto_backup "dots/.config/hypr/$i" "${XDG_CONFIG_HOME}/hypr/$i"
    done
    for i in hyprland.conf ; do
      case "${SKIP_HYPRLAND_ENTRY}" in
        true) sleep 0;;
        *) install_file "dots/.config/hypr/$i" "${XDG_CONFIG_HOME}/hypr/$i" ;;
      esac
    done
    for i in hypridle.conf ; do
      if [[ "${INSTALL_VIA_NIX}" == true ]]; then
        install_file__auto_backup "dots-extra/via-nix/$i" "${XDG_CONFIG_HOME}/hypr/$i"
      else
        install_file__auto_backup "dots/.config/hypr/$i" "${XDG_CONFIG_HOME}/hypr/$i"
      fi
    done
    if [ "$OS_GROUP_ID" = "fedora" ];then
      v bash -c "printf \"# For fedora to setup polkit\nexec-once = /usr/libexec/kf6/polkit-kde-authentication-agent-1\n\" >> ${XDG_CONFIG_HOME}/hypr/hyprland/execs.conf"
    fi

    install_dir__ignore_existing "dots/.config/hypr/custom" "${XDG_CONFIG_HOME}/hypr/custom"
    ;;
esac

install_file "dots/.local/share/icons/illogical-impulse.svg" "${XDG_DATA_HOME}"/icons/illogical-impulse.svg

# For Niri
case "${SKIP_NIRI}" in
  true) sleep 0;;
  *)
    if [[ "${WITH_NIRI}" == true ]]; then
      echo "[$0]: Installing Niri configuration..."
      install_dir__sync dots/.config/niri "$XDG_CONFIG_HOME"/niri

      # Install Niri-specific Quickshell files (overwrite Hyprland versions)
      echo "[$0]: Installing Niri-specific Quickshell files..."

      # Backup and replace shell.qml
      if [ -f "$XDG_CONFIG_HOME/quickshell/ii/shell.qml" ]; then
        install_file__auto_backup "dots/.config/quickshell/ii/shell-niri.qml" "$XDG_CONFIG_HOME/quickshell/ii/shell.qml"
      else
        install_file "dots/.config/quickshell/ii/shell-niri.qml" "$XDG_CONFIG_HOME/quickshell/ii/shell.qml"
      fi

      # Backup and replace GlobalStates.qml
      if [ -f "$XDG_CONFIG_HOME/quickshell/ii/GlobalStates.qml" ]; then
        install_file__auto_backup "dots/.config/quickshell/ii/GlobalStates-niri.qml" "$XDG_CONFIG_HOME/quickshell/ii/GlobalStates.qml"
      else
        install_file "dots/.config/quickshell/ii/GlobalStates-niri.qml" "$XDG_CONFIG_HOME/quickshell/ii/GlobalStates.qml"
      fi

      # Install Niri service files
      for svc in NiriData.qml NiriConfig.qml NiriXkb.qml NiriKeybinds.qml NightLight.qml NiriFocusGrab.qml; do
        if [ -f "dots/.config/quickshell/ii/services/$svc" ]; then
          install_file "dots/.config/quickshell/ii/services/$svc" "$XDG_CONFIG_HOME/quickshell/ii/services/$svc"
        fi
      done

      # Install Niri UI components
      install_file "dots/.config/quickshell/ii/modules/ii/bar/Workspaces-niri.qml" "$XDG_CONFIG_HOME/quickshell/ii/modules/ii/bar/Workspaces.qml"
      install_file "dots/.config/quickshell/ii/modules/ii/cheatsheet/CheatsheetKeybinds-niri.qml" "$XDG_CONFIG_HOME/quickshell/ii/modules/ii/cheatsheet/CheatsheetKeybinds.qml"
      install_file "dots/.config/quickshell/ii/modules/ii/overview/Overview-niri.qml" "$XDG_CONFIG_HOME/quickshell/ii/modules/ii/overview/Overview.qml"

      echo "[$0]: Niri configuration installed successfully."
    fi
    ;;
esac
