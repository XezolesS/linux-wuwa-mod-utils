#! /usr/bin/env bash

readonly SCRIPT_NAME="wuwa-mod-utils.sh"

readonly APPID=3513350
readonly APPNAME="Wuthering Waves"

readonly XXMILAUNCHER_BASENAME="XXMI-Launcher"
readonly RESHADE_BASENAME="ReShade"

readonly WIN_APPDATA="C:\users\steamuser\Application Data"

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

prepare() {
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

  WUWA_PATH=""

  for sl in "${STEAM_GAME_LIBRARIES[@]}"; do
    for dir in "$sl"/steamapps/common/*; do
      [[ -d "$dir" ]] || continue
      [[ -e "$dir/Wuthering Waves.exe" ]] && WUWA_PATH="$dir" && break
    done
  done

  if [[ -n "$WUWA_PATH" ]]; then
    print_success "Found $APPNAME installed at: $WUWA_PATH"
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
      echo "  $i) $(basename "${STEAM_PROTONS["$i"]}")"
    done
    printf "\n"

    while true; do
      printf "%s" "Select proton version (0-$((${#STEAM_PROTONS[@]} - 1))): "
      read -r p_select

      if ((0 <= p_select)) && ((p_select < "${#STEAM_PROTONS[@]}")); then
        PROTON_BIN="${STEAM_PROTONS["$p_select"]}/proton"
        break
      fi
    done
  fi
}

# commands
install-deps() {
  protontricks "$APPID" d3dcompiler_47 && print_success "'d3dcompiler_47' is installed."
  protontricks "$APPID" powershell && print_success "'powershell' is installed."
}

install-xxmi() {
  # TODO: download from git?
  if [[ -z "${1:-}" ]]; then
    cat <<EOF
Usage: ./$SCRIPT_NAME install-xxmi PORTABLE_ZIP_PATH
EOF
    exit 0
  fi

  prepare

  if [[ -f "$1" ]] && [[ "$1" =~ \.zip ]]; then
    XXMI_ZIP_PATH="$1"

    local _path="$APPDATA_PATH/$XXMILAUNCHER_BASENAME"
    if [[ ! -d "$_path" ]]; then
      mkdir "$_path"
    fi

    if unzip "$XXMI_ZIP_PATH" -d "$_path"; then
      print_success "XXMI Launcher is successfully installed at: $_path"
    else
      print_error "Install failed for unknown reason."
    fi
  else
    print_error "'$1' is not a zip file."
    exit 1
  fi
}

run-xxmi() {
  # check XXMI Launcher is installed
  if [[ ! -d "$APPDATA_PATH/$XXMILAUNCHER_BASENAME" ]]; then
    print_error "XXMI Launcher is not installed. Try run './$SCRIPT_NAME install-xxmi' first."
    exit 1
  fi

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
      cat <<EOF
Usage: ./$SCRIPT_NAME run-xxmi [OPTION]

THEME:
  Run XXMI Launcher using proton.

[OPTIONS]:
  -p, --proton        Proton version, or path.
  -h, --help          Show this help.
EOF
      exit 0
      ;;
    --)
      shift
      break
      ;;
    esac
  done

  prepare
  prepare_proton "$ARG_PROTON"

  echo "$PROTON_BIN"

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

  "$PROTON_BIN" run "$WIN_APPDATA\\$XXMILAUNCHER_BASENAME\Resources\Bin\XXMI Launcher.exe"
}

add-wwmi-mod() {
  true
}

rm-wwmi-mod() {
  local _path="$APPDATA_PATH/$XXMILAUNCHER_BASENAME/WWMI/Mods"
  if [[ ! -d "$_path" ]]; then
    print_error "WWMI is not installed. Install and run XXMI first."
    exit 1
  fi

  local mods=()
  for mod in "$_path"/*; do
    [[ -d "$mod" ]] && mods+=("$mod")
  done

  for i in "${!mods[@]}"; do
    echo "  $i. $(basename "${mods["$i"]}")"
  done
}

ls-wwmi-mod() {
  prepare

  local _path="$APPDATA_PATH/$XXMILAUNCHER_BASENAME/WWMI/Mods"
  if [[ ! -d "$_path" ]]; then
    print_error "WWMI is not installed. Install and run XXMI first."
    exit 1
  fi

  local mods=()
  for mod in "$_path"/*; do
    [[ -d "$mod" ]] && mods+=("$mod")
  done

  echo "${#mods[@]} mod(s) installed."
  for i in "${!mods[@]}"; do
    echo "  $i. $(basename "${mods["$i"]}")"
  done
}

rename-wwmi-mod() {
  true
}

toggle-wwmi-mod() {
  true
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
      cat <<EOF
Usage: .$SCRIPT_NAME install-reshade [OPTION] SETUP_EXE_PATH

THEME:
  Install ReShade using proton.

[OPTIONS]:
  -p, --proton        Proton version, or path.
  -h, --help          Show this help.
EOF
      exit 0
      ;;
    --)
      shift
      break
      ;;
    esac
  done

  if [[ -z "${1:-}" ]]; then
    print_error "Please provide a ReShade setup executable. Check: './$SCRIPT_NAME install-reshade --help'"
    exit 1
  fi

  prepare
  prepare_proton "$ARG_PROTON"

  if [[ -f "$1" ]] && [[ "$1" =~ \.exe ]]; then
    XXMI_ZIP_PATH="$1"

    local _path="$APPDATA_PATH/$RESHADE_BASENAME"
    if [[ ! -d "$_path" ]]; then
      mkdir "$_path"
    fi

    cp "$1" "$_path"
  else
    print_error "'$1' is not a zip file."
    exit 1
  fi

  # run
  export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_ROOT"
  export STEAM_COMPAT_DATA_PATH="$COMPATDATA_PATH"

  export WINEPREFIX="$WINEPREFIX_PATH"

  "$PROTON_BIN" run "$WIN_APPDATA\\$RESHADE_BASENAME\\$(basename "$1")"
}

install-wwmi-dx12() {
  true
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
      cat <<EOF
Usage: ./$SCRIPT_NAME run-xxmi-dx12 [OPTION]

THEME:
  Run WWMI DX12 script using proton.

[OPTIONS]:
  -p, --proton        Proton version, or path.
  -h, --help          Show this help.
EOF
      exit 0
      ;;
    --)
      shift
      break
      ;;
    esac
  done

  prepare
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

  "$PROTON_BIN" run "Z:${WUWA_PATH//\//\\}\Client\Binaries\Win64\wwmi_dx12_launch.bat"
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
add-wwmi-mod)
  shift
  add-wwmi-mod "$@"
  ;;
rm-wwmi-mod)
  shift
  rm-wwmi-mod "$@"
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
  install-wwmi-dx12
  ;;
run-wwmi-dx12)
  shift
  run-wwmi-dx12 "$@"
  ;;
*)
  cat <<EOF
Usage: ./$SCRIPT_NAME COMMAND

COMMAND:
  install-deps        Install Windows dependencies.
  install-xxmi        Install XXMI Launcher from portable zip file.
  run-xxmi            Run XXMI Launcher.exe
  intsall-reshade     Install ReShade.
EOF
  exit 0
  ;;
esac
