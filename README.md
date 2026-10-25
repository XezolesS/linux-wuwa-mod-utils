# linux-wuwa-mod-utils

A Bash utility script for managing **Wuthering Waves** mod tools on Linux/Steam
Proton.

It helps you:

- install basic Windows dependencies.
- install and run **XXMI Launcher**
- manage **WWMI** mods
- install and run **ReShade**
- install and run **WWMI DX12** through Proton

## AI USAGE DISCLAIMER

`README.md` is written with AI, and human checked. Though it could contain
wrong information, so keep that in mind.

The scripts are **NOT** AI-assisted.

## Requirements

- **Linux**, **Steam**, **Proton**, and **Wuthering Waves** installed, obviously.
- `unzip`
- `protontricks`

## Usage

```bash
./wuwa-mod-utils.sh COMMAND
```

|Command|Description|
|-------|-----------|
|`install-deps`|Install Windows dependencies.|
|`install-xxmi`|Install XXMI Launcher.|
|`run-xxmi`|Run XXMI Launcher.exe|
|`add-wwmi-mod`|Add WWMI mod.|
|`rm-wwmi-mod`|Remove installed WWMI mod.|
|`ls-wwmi-mod`|List installed WWMI mods.|
|`rename-wwmi-mod`|Rename installed WWMI mod.|
|`toggle-wwmi-mod`|Enable/disable installed WWMI mod.|
|`intsall-reshade`|Install ReShade.|
|`install-wwmi-dx12`|Install WWMI-DX12 (ReShade required).|
|`run-wwmi-dx12`|Run WWMI-DX12 script using Proton."|

### Command in detail

#### `install-deps`

Installs required Windows components into the Wuthering Waves prefix:

- `d3dcompiler_47`
- `powershell`

### `install-xxmi`

```bash
./wuwa-mod-utils.sh install-xxmi PORTABLE_ZIP_PATH
```

Installs XXMI Launcher from a `.zip` archive into the game prefix.

### `run-xxmi`

```bash
./wuwa-mod-utils.sh run-xxmi [--proton PROTON]
```

Runs XXMI Launcher with Proton.

Options:

- `-p, --proton` — Proton version name or Proton path
- `-h, --help` — show help

### `add-wwmi-mod`

Currently a placeholder.

### `rm-wwmi-mod`

```bash
./wuwa-mod-utils.sh rm-wwmi-mod
```

Removes a selected installed WWMI mod.

### `ls-wwmi-mod`

```bash
./wuwa-mod-utils.sh ls-wwmi-mod
```

Lists installed mods and shows whether each one is enabled or disabled.

### `rename-wwmi-mod`

```bash
./wuwa-mod-utils.sh rename-wwmi-mod
```

Renames a selected installed mod.

### `toggle-wwmi-mod`

```bash
./wuwa-mod-utils.sh toggle-wwmi-mod
```

Moves a selected mod between enabled and disabled states.

### `install-reshade`

```bash
./wuwa-mod-utils.sh install-reshade [--proton PROTON] SETUP_EXE_PATH
```

Copies a ReShade installer into the prefix and runs it through Proton.

### `install-wwmi-dx12`

Currently a placeholder.

### `run-wwmi-dx12`

```bash
./wuwa-mod-utils.sh run-wwmi-dx12 [--proton PROTON]
```

Runs the WWMI DX12 launch script through Proton.

## Notes

- The script auto-detects Steam libraries, Proton installations, and the
Wuthering Waves prefix.
- It expects the game app ID to be `3513350`.
- It looks for the game executable in Steam library folders.
- It uses NVIDIA-related environment variables for Proton launch.

## Mod storage layout

The script expects WWMI mods under:

```text
.../Application Data/XXMI-Launcher/WWMI/Mods
```

Disabled mods are stored in:

```text
.../Application Data/XXMI-Launcher/WWMI/Mods/DISABLED
```

It detects `DISABLED` in the name of the mod directory, but not used in disabling
mods.
