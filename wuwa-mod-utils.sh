#! /usr/bin/env bash

readonly HELP_MAIN="Usage: ./$SCRIPT_NAME COMMAND

COMMAND:
  install-deps        Install Windows dependencies.
  install-xxmi        Install XXMI Launcher.
  run-xxmi            Run XXMI Launcher.exe
  manage-wwmi-mod     Manage WWMI mods via interactive mode.
  add-wwmi-mod        Add WWMI mod.
  rm-wwmi-mod         Remove installed WWMI mod.
  ls-wwmi-mod         List installed WWMI mods.
  rename-wwmi-mod     Rename installed WWMI mod.
  toggle-wwmi-mod     Enable/disable installed WWMI mod.
  intsall-reshade     Install ReShade.
  install-wwmi-dx12   Install WWMI-DX12 (ReShade required).
  run-wwmi-dx12       Run WWMI-DX12 script using Proton."
readonly HELP_INSTALL_XXMI="Usage: ./$SCRIPT_NAME install-xxmi PORTABLE_ZIP_PATH"
readonly HELP_RUN_XXMI="Usage: ./$SCRIPT_NAME run-xxmi [OPTION]

THEME:
  Run XXMI Launcher using proton.

[OPTIONS]:
  -p, --proton        Proton version, or path.
  -h, --help          Show this help."
readonly HELP_ADD_WWMI_MOD="Usage: ./$SCRIPT_NAME add-wwmi-mod ZIP_PATH [MOD_NAME]"
readonly HELP_INSTALL_RESHADE="Usage: .$SCRIPT_NAME install-reshade [OPTION] SETUP_EXE_PATH

THEME:
  Install ReShade using proton.

[OPTIONS]:
  -p, --proton        Proton version, or path.
  -h, --help          Show this help. "
readonly HELP_RUN_XXMI_DX12="
Usage: ./$SCRIPT_NAME run-xxmi-dx12 [OPTION]

THEME:
  Run WWMI-DX12 script using proton.

[OPTIONS]:
  -p, --proton        Proton version, or path.
  -h, --help          Show this help."

readonly SCRIPT_NAME="wuwa-mod-utils.sh"

readonly APPID=3513350
readonly APPNAME="Wuthering Waves"

readonly XXMI_BASENAME="XXMI-Launcher"
readonly RESHADE_BASENAME="ReShade"

readonly WIN_APPDATA="C:\users\steamuser\Application Data"

readonly XXMI_DL_URL="https://github.com/SpectrumQT/XXMI-Launcher/releases/latest"
readonly RESHADE_DL_URL="https://reshade.me/#download"
readonly WWMI_DX12_DL_URL="https://github.com/lekarsenten/wwmi-dx12/releases/latest"

# utils
print_info() {
  echo -e "\033[0;36m[INFO]\033[0m $1"
}

print_success() {
  echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

print_error() {
  echo -e "\033[0;31m[ERROR]\033[0m $1"
}

win_path() {
  local drive="$1"
  local path="$2"
  printf "%s:%s" "$drive" "${path//\//\\}"
}

expand_path() {
  local path="$1"
  path="${path/#\~/$HOME}"
  path="${path/#\./$PWD}"
  printf "%s" "${path}"
}

prepare() {
  if [[ -n "$__PREPARED__" ]]; then
    return 0
  fi

  # find Steam
  STEAM_ROOT="$HOME/.steam/steam"

  if [[ -d "$STEAM_ROOT" ]]; then
    print_success "Found Steam."
  else
    print_error "Cannot find installed Steam."
    exit 1
  fi

  # find all Steam Libraries
  print_info "Checking Steam Library..."

  STEAM_LIB_VDF="$STEAM_ROOT/config/libraryfolders.vdf"
  steam_lib_list=$(
    awk -v appid="$APPID" '
/^[[:space:]]*"path"[[:space:]]/ {
    sub(/^[[:space:]]*"path"[[:space:]]*"/, "")
    sub(/"[[:space:]]*$/, "")
    print
  }
  ' "$STEAM_LIB_VDF"
  )
  mapfile -t STEAM_GAME_LIBRARIES < <(printf "%s" "$steam_lib_list")

  if [[ "${#STEAM_GAME_LIBRARIES[@]}" -ne 0 ]]; then
    print_success "Found ${#STEAM_GAME_LIBRARIES[@]} Steam Library:"
    for sl in "${STEAM_GAME_LIBRARIES[@]}"; do
      echo "  - $sl"
    done
  else
    print_error "Cannot find Wuthering Waves!"
    exit 1
  fi

  # find protons
  print_info "Checking Protons..."

  STEAM_PROTONS=()

  for sl in "${STEAM_GAME_LIBRARIES[@]}"; do
    for dir in "$sl"/steamapps/common/*; do
      [[ -d "$dir" ]] || continue
      [[ -e "$dir/proton" ]] && STEAM_PROTONS+=("$dir")
    done
  done

  for dir in "$STEAM_ROOT"/compatibilitytools.d/*; do
    [[ -d "$dir" ]] || continue
    [[ -e "$dir/proton" ]] && STEAM_PROTONS+=("$dir")
  done

  if [[ "${#STEAM_PROTONS[@]}" -ne 0 ]]; then
    print_success "Found ${#STEAM_PROTONS[@]} Protons:"
    for p in "${STEAM_PROTONS[@]}"; do
      echo "  - $p"
    done
  else
    print_error "Cannot find any Proton installed!"
    exit 1
  fi

  # find Wuthering Waves installed location
  print_info "Checking Steam Library where Wuthering Waves($APPID) is installed..."

  APP_PATH=""

  for sl in "${STEAM_GAME_LIBRARIES[@]}"; do
    for dir in "$sl"/steamapps/common/*; do
      [[ -d "$dir" ]] || continue
      [[ -e "$dir/Wuthering Waves.exe" ]] && APP_PATH="$dir" && break
    done
  done

  if [[ -n "$APP_PATH" ]]; then
    print_success "Found $APPNAME installed at: $APP_PATH"
  else
    print_error "Cannot find $APPNAME installed!"
    exit 1
  fi

  # find Wuthering Waves wineprefix
  print_info "Checking $APPNAME prefix..."

  COMPATDATA_PATH=""
  WINEPREFIX_PATH=""
  APPDATA_PATH=""

  for sl in "${STEAM_GAME_LIBRARIES[@]}"; do
    for dir in "$sl"/steamapps/compatdata/*; do
      [[ -d "$dir" ]] || continue
      [[ "$(basename "$dir")" == "$APPID" ]] && COMPATDATA_PATH="$dir" && break
    done
  done

  if [[ -n "$COMPATDATA_PATH" ]]; then
    WINEPREFIX_PATH="$COMPATDATA_PATH/pfx"
    APPDATA_PATH="$WINEPREFIX_PATH/drive_c/users/steamuser/Application Data"
    print_success "Found $APPNAME prefix at: $WINEPREFIX_PATH"
  else
    print_error "Cannot find $APPNAME prefix!"
    exit 1
  fi

  __PREPARED__=1
}

prepare_proton() {
  # select proton version
  PROTON_BIN=""
  local ARG_PROTON="$1"

  if [[ -n "$ARG_PROTON" ]]; then
    if [[ -d "$ARG_PROTON" ]]; then
      [[ -e "$ARG_PROTON/proton" ]] && PROTON_BIN="$ARG_PROTON/proton"
    else
      for p in "${STEAM_PROTONS[@]}"; do
        echo "$p"
        if [[ "$ARG_PROTON" == "$(basename "$p")" ]]; then
          PROTON_BIN="$p/proton"
          break
        fi
      done
    fi
  fi

  if [[ -z "$PROTON_BIN" ]]; then
    [[ -n "$ARG_PROTON" ]] && print_error "'$ARG_PROTON' not found."
    printf "\nList of Protons:\n"
    for i in "${!STEAM_PROTONS[@]}"; do
      printf "  %d) \033[0;33m%s\033[0m\n" "$((i + 1))" "$(basename "${STEAM_PROTONS[$i]}")"
    done
    printf "\n"

    while true; do
      read -r -p "Select proton version. [1-${#STEAM_PROTONS[@]}]: " select

      if ((1 <= select)) && ((select <= "${#STEAM_PROTONS[@]}")); then
        PROTON_BIN="${STEAM_PROTONS[$((select - 1))]}/proton"
        break
      fi
    done
  fi
}

# commands
install-deps() {
  if ! which protontricks &>/dev/null; then
    print_error "'protontricks' is not installed! Please install it first."
    exit 1
  fi

  _install() {
    local pkg="$1"
    print_info "Installing \033[0;36m$pkg\033[0m..."
    if protontricks "$APPID" "$pkg" &>/dev/null; then
      print_success "\033[0;36m$pkg\033[0m is installed."
    else
      print_error "\033[0;36m$pkg\033[0m is not installed."
    fi
  }

  _install "vcrun2022"
  _install "d3dcompiler_47"
  _install "powershell"
}

install-xxmi() {
  # TODO: download from git?
  if [[ -z "${1:-}" ]]; then
    echo "$HELP_INSTALL_XXMI"
    exit 0
  fi

  prepare

  if [[ -f "$1" ]] && [[ "$1" =~ \.zip ]]; then
    local zip_path="$1"
    local path="$APPDATA_PATH/$XXMI_BASENAME"
    if unzip "$zip_path" -d "$path"; then
      print_success "XXMI Launcher is successfully installed at: $path"
    else
      print_error "Install failed for unknown reason."
    fi
  else
    print_error "\033[0;36m$1\033[0m is not a zip file."
    exit 1
  fi
}

run-xxmi() {
  OPTS=$(getopt \
    -o p:,h \
    -l proton,help \
    -n "run-xxmi" -- "$@")
  eval set -- "$OPTS"

  local ARG_PROTON=""

  while true; do
    case "$1" in
    -p | --proton)
      ARG_PROTON="$2"
      shift 2
      ;;
    -h | --help)
      echo "$HELP_RUN_XXMI"
      exit 0
      ;;
    --)
      shift
      break
      ;;
    esac
  done

  prepare

  # check XXMI Launcher is installed
  if [[ ! -d "$APPDATA_PATH/$XXMI_BASENAME" ]]; then
    print_error "XXMI Launcher is not installed. Try run './$SCRIPT_NAME install-xxmi' first."
    exit 1
  fi

  prepare_proton "$ARG_PROTON"

  # run
  export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_ROOT"
  export STEAM_COMPAT_DATA_PATH="$COMPATDATA_PATH"

  export __NV_PRIME_RENDER_OFFLOAD=1
  export __GLX_VENDOR_LIBRARY_NAME=nvidia
  export __VK_LAYER_NV_optimus=NVIDIA_only

  export WINEPREFIX="$WINEPREFIX_PATH"
  export WINEDLLOVERRIDES="d3dcompiler_47=native,builtin"

  export MANGOHUD=1
  export PROTON_ENABLE_NVAPI=1
  export PROTON_NVIDIA_LIBS=1

  "$PROTON_BIN" run "$WIN_APPDATA\\$XXMI_BASENAME\Resources\Bin\XXMI Launcher.exe"
}

manage-wwmi-mod() {
  prepare

  local manage_help_msg="  1|a|add)     Add a WWMI mod.
  2|r|rm)      Remove a WWMI mod.
  3|l|ls)      List installed WWMI mod.
  4|n|rename)  Rename a WWMI mod.
  5|t|toggle)  Enable/Disable a WWMI mod.

  h) Print this message.
  q) Quit."

  echo "$manage_help_msg"

  while true; do
    printf " \033[0;31mwwmi-mod-manager >\033[0m "
    read -r m_cmd

    case "$m_cmd" in
    1 | a | add)
      printf " \033[0;31mPath to mod zip:\033[0m"
      read -e -p " " m_modzip

      if [[ -z "$m_modzip" ]]; then
        print_error "Path to the zip file must be given!"
        continue
      fi

      printf " \033[0;31mMod name (default if empty):\033[0m "
      read -r m_modname
      add-wwmi-mod "$m_modzip" "$m_modname"
      ;;
    2 | r | rm)
      rm-wwmi-mod
      ;;
    3 | l | ls)
      ls-wwmi-mod
      ;;
    4 | n | rename)
      rename-wwmi-mod
      ;;
    5 | t | toggle)
      toggle-wwmi-mod
      ;;
    h)
      echo "$manage_help_msg"
      ;;
    q)
      exit 0
      ;;
    *)
      continue
      ;;
    esac
  done
}

add-wwmi-mod() {
  if [[ -z "${1:-}" ]]; then
    echo "$HELP_ADD_WWMI_MOD"
    exit 0
  fi

  prepare

  local arg_path="${1/#\~/$HOME}"

  if [[ -f "$arg_path" ]] && [[ "$arg_path" =~ \.zip ]]; then
    local zip_path="$arg_path"
    local zip_filename
    zip_filename="$(basename "$zip_path")"

    local path="$APPDATA_PATH/$XXMI_BASENAME/WWMI/Mods"
    if [[ ! -d "$path" ]]; then
      print_error "WWMI is not installed. Install and run XXMI first."
      exit 1
    fi

    local mod_name="${2:-"${zip_filename%.zip}"}"
    if [[ -d "$mod_name" ]]; then
      print_error "\033[0;36m$mod_name\033[0m is already added."
      exit 1
    fi

    if unzip "$zip_path" -d "$path/$mod_name"; then
      print_success "Mod \033[0;36m$mod_name\033[0m is added."
    else
      print_error "Install failed for unknown reason."
    fi
  else
    print_error "\033[0;36m$arg_path\033[0m is not a zip file."
    exit 1
  fi
}

rm-wwmi-mod() {
  prepare

  local path="$APPDATA_PATH/$XXMI_BASENAME/WWMI/Mods"
  if [[ ! -d "$path" ]]; then
    print_error "WWMI is not installed. Install and run XXMI first."
    exit 1
  fi

  print_info "\033[1;31mWWMI Mod Manager - Remove\033[0m"
  ls-wwmi-mod
  printf "%s" "Select a mod to remove. [1-${#WWMI_MODS[@]}]: "
  read -r m_select

  if ((1 <= m_select)) && ((m_select <= "${#WWMI_MODS[@]}")); then
    local mod="${WWMI_MODS["$((m_select - 1))"]}"
    local mod_name
    mod_name="$(basename "$mod")"

    printf "Are you sure to remove \033[0;36m%s\033[0m? [y/N]: " "$mod_name"
    read -r m_confirm

    if [[ "${m_confirm,,}" == "y" ]]; then
      rm -rf "$mod"
      print_success "\033[0;36m$mod_name\033[0m has been removed!"
    else
      print_info "Canceled."
    fi
  else
    print_info "Canceled."
  fi
}

ls-wwmi-mod() {
  prepare

  local path="$APPDATA_PATH/$XXMI_BASENAME/WWMI/Mods"
  if [[ ! -d "$path" ]]; then
    print_error "WWMI is not installed. Install and run XXMI first."
    exit 1
  fi

  WWMI_MODS=()
  for mod in "$path"/*; do
    [[ -d "$mod" ]] && [[ "$(basename "$mod")" != "DISABLED" ]] && WWMI_MODS+=("$mod")
  done

  for mod in "$path/DISABLED"/*; do
    [[ -d "$mod" ]] && WWMI_MODS+=("$mod")
  done

  print_info "${#WWMI_MODS[@]} mod(s) installed. ([\033[0;32mv\033[0m]: enabled, [ ]: disabled)"
  local mod_name
  local enable_mark

  for i in "${!WWMI_MODS[@]}"; do
    mod_name=$(basename "${WWMI_MODS[$i]}")
    mod_name=$(echo "${mod_name/DISABLED/}" | xargs)

    enable_mark="v" && [[ "${WWMI_MODS[$i]}" == *"DISABLED"* ]] && enable_mark=" "

    printf "  %d) [\033[0;32m%s\033[0m] \033[0;33m%s\033[0m\n" "$((i + 1))" "$enable_mark" "$mod_name"
  done
}

rename-wwmi-mod() {
  prepare

  local path="$APPDATA_PATH/$XXMI_BASENAME/WWMI/Mods"
  if [[ ! -d "$path" ]]; then
    print_error "WWMI is not installed. Install and run XXMI first."
    exit 1
  fi

  print_info "\033[1;31mWWMI Mod Manager - Rename\033[0m"
  ls-wwmi-mod
  printf "%s" "Select a mod to rename. [1-${#WWMI_MODS[@]}]: "
  read -r m_select

  if ((1 <= m_select)) && ((m_select <= "${#WWMI_MODS[@]}")); then
    local mod="${WWMI_MODS["$((m_select - 1))"]}"
    local old_mod_name
    old_mod_name="$(basename "$mod")"

    printf "Change name(\033[0;36m%s\033[0m) to: " "$old_mod_name"
    read -r new_mod_name

    if [[ -z "$new_mod_name" ]]; then
      print_error "Mod name cannot be empty."
      exit 1
    elif [[ "$new_mod_name" == */* ]]; then
      print_error "Mod name cannot contains character '/'."
      exit 1
    else
      mv "$mod" "$(dirname "$mod")/$new_mod_name"
      print_success "\033[0;31m$old_mod_name\033[0m -> \033[0;36m$new_mod_name\033[0m"
    fi
  else
    print_info "Canceled."
  fi
}

toggle-wwmi-mod() {
  prepare

  local path="$APPDATA_PATH/$XXMI_BASENAME/WWMI/Mods"
  if [[ ! -d "$path" ]]; then
    print_error "WWMI is not installed. Install and run XXMI first."
    exit 1
  fi

  print_info "\033[1;31mWWMI Mod Manager - Toggle\033[0m"
  ls-wwmi-mod
  printf "%s" "Select a mod to toggle. [1-${#WWMI_MODS[@]}]: "
  read -r m_select

  if ((1 <= m_select)) && ((m_select <= "${#WWMI_MODS[@]}")); then
    local mod="${WWMI_MODS["$((m_select - 1))"]}"
    local mod_name
    mod_name="$(basename "$mod")"

    if [[ ! -d "$path/DISABLED" ]]; then
      mkdir "$path/DISABLED"
    fi

    local new_path
    local result_text

    if [[ "${mod}" == *"DISABLED"* ]]; then
      if [[ "${mod_name}" == "DISABLED"* ]]; then
        # DISABLED, by filename
        new_path="$path/$(echo "${mod_name/DISABLED/}" | xargs)"
      else
        # DISABLED, in DISABELD dir
        new_path="$path/$mod_name"
      fi

      result_text="enabled"
    else
      # ENABLED
      new_path="$path/DISABLED/$mod_name"

      result_text="disabled"
    fi

    mv "$mod" "$new_path"
    print_success "Mod \033[0;36m$mod_name\033[0m is $result_text."
  else
    print_info "Canceled."
  fi
}

install-reshade() {
  OPTS=$(getopt \
    -o p:,h \
    -l proton,help \
    -n "install-reshade" -- "$@")
  eval set -- "$OPTS"

  local ARG_PROTON=""

  while true; do
    case "$1" in
    -p | --proton)
      ARG_PROTON="$2"
      shift 2
      ;;
    -h | --help)
      echo "$HELP_INSTALL_RESHADE"
      exit 0
      ;;
    --)
      shift
      break
      ;;
    esac
  done

  if [[ -z "${1:-}" ]]; then
    print_error "Please provide a ReShade setup executable."
    echo "$HELP_INSTALL_RESHADE"
    exit 1
  fi

  prepare
  prepare_proton "$ARG_PROTON"

  if [[ -f "$1" ]] && [[ "$1" =~ \.exe ]]; then
    local path="$APPDATA_PATH/$RESHADE_BASENAME"
    if [[ ! -d "$path" ]]; then
      mkdir "$path"
    fi

    cp "$1" "$path"
  else
    print_error "\033[0;36m$1\033[0m is not a executable."
    exit 1
  fi

  # run
  export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_ROOT"
  export STEAM_COMPAT_DATA_PATH="$COMPATDATA_PATH"

  export WINEPREFIX="$WINEPREFIX_PATH"

  "$PROTON_BIN" run "$(win_path "C" "$path/$(basename "$1")")"
}

install-wwmi-dx12() {
  prepare

  local candidates=()
  if [[ -z "${1:-}" ]]; then
    # check $HOME/Downloads
    for f in "$HOME/Downloads"/*; do
      [[ -f "$f" ]] && [[ "$f" == *"wwmi-dx12"*.zip ]] && candidates+=("$f")
    done

    # check current path
    for f in ./*; do
      [[ -f "$f" ]] && [[ "$f" == *"wwmi-dx12"*.zip ]] && candidates+=("$f")
    done
  else
    candidates=("$1")
  fi

  if (("${#candidates[@]}" == 0)); then
    print_error "WWMI-DX12 .zip archive is not found!"
    print_info "You can download it from: $WWMI_DX12_DL_URL"
    exit 1
  fi

  local path="$APP_PATH/Client/Binaries/Win64"
  if [[ -f "$path/wwmi_dx12_launch.bat" ]]; then
    print_info "WWMI-DX12 is already installed."
    read -r -p "Overwrite installation? [y/N]: " confirm
    if [[ "${confirm,,}" != "y" ]]; then
      print_info "Installation canceled."
      exit 1
    fi
  fi

  local zip_path
  if ((${#candidates[@]} == 1)); then
    zip_path="${candidates[0]}"
  else
    print_info "Multiple WWMI-DX12 is found."
    for i in "${!candidates[@]}"; do
      printf "  %d) \033[0;33m%s\033[0m\n" "$((i + 1))" "$(basename "${candidates[$i]}")"
    done

    read -r -p "Select one to install. [1-${#candidates[@]}]: " select
    zip_path="${candidates[(($select - 1))]}"
  fi

  if unzip "$zip_path" -d "$path"; then
    print_success "WWMI-DX12 is installed."
  else
    print_error "Install failed for unknown reason."
  fi
}

run-wwmi-dx12() {
  OPTS=$(getopt \
    -o p:,h \
    -l proton,help \
    -n "run-xxmi-dx12" -- "$@")
  eval set -- "$OPTS"

  local ARG_PROTON=""

  while true; do
    case "$1" in
    -p | --proton)
      ARG_PROTON="$2"
      shift 2
      ;;
    -h | --help)
      echo "$HELP_RUN_XXMI_DX12"
      exit 0
      ;;
    --)
      shift
      break
      ;;
    esac
  done

  prepare

  local path="$APP_PATH/Client/Binaries/Win64/wwmi_dx12_launch.bat"
  if [[ ! -f "$path" ]]; then
    print_error "WWMI-DX12 is not installed. Try run 'install-wwmi-dx12' first."
    exit 1
  fi

  prepare_proton "$ARG_PROTON"

  # run
  export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_ROOT"
  export STEAM_COMPAT_DATA_PATH="$COMPATDATA_PATH"

  export __NV_PRIME_RENDER_OFFLOAD=1
  export __GLX_VENDOR_LIBRARY_NAME=nvidia
  export __VK_LAYER_NV_optimus=NVIDIA_only

  export WINEPREFIX="$WINEPREFIX_PATH"
  export WINEDLLOVERRIDES="d3dcompiler_47=native,builtin"

  export MANGOHUD=1
  export PROTON_ENABLE_NVAPI=1
  export PROTON_NVIDIA_LIBS=1

  "$PROTON_BIN" run "$(win_path "Z" "$path")"
}

# execute
case "$1" in
install-deps)
  shift
  install-deps
  ;;
install-xxmi)
  shift
  install-xxmi "$@"
  ;;
run-xxmi)
  shift
  run-xxmi "$@"
  ;;
manage-wwmi-mod)
  shift
  manage-wwmi-mod
  ;;
add-wwmi-mod)
  shift
  add-wwmi-mod "$@"
  ;;
rm-wwmi-mod)
  shift
  rm-wwmi-mod
  ;;
ls-wwmi-mod)
  shift
  ls-wwmi-mod
  ;;
rename-wwmi-mod)
  shift
  rename-wwmi-mod
  ;;
toggle-wwmi-mod)
  shift
  toggle-wwmi-mod
  ;;
install-reshade)
  shift
  install-reshade "$@"
  ;;
install-wwmi-dx12)
  shift
  install-wwmi-dx12 "$@"
  ;;
run-wwmi-dx12)
  shift
  run-wwmi-dx12 "$@"
  ;;
*)
  echo "$HELP_MAIN"
  exit 0
  ;;
esac
