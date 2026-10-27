# linux-wuwa-mod-utils

A Bash utility script for managing **Wuthering Waves** mod tools on Linux/Steam
Proton.

It helps you:

- install basic Windows dependencies.
- install and run **XXMI Launcher**
- manage **WWMI** mods
- install and run **ReShade**
- install and run **WWMI-DX12** through Proton

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
git clone https://github.com/XezolesS/linux-wuwa-mod-utils.git
cd linux-wuwa-mod-utils
./wuwa-mod-utils.sh COMMAND
```

|Command|Description|
|-------|-----------|
|`install-deps`|Install Windows dependencies.|
|`install-xxmi`|Install XXMI Launcher.|
|`run-xxmi`|Run XXMI Launcher.exe|
|`manage-wwmi-mod`|Manage WWMI mods via interactive mode.|
|`add-wwmi-mod`|Add WWMI mod.|
|`rm-wwmi-mod`|Remove installed WWMI mod.|
|`ls-wwmi-mod`|List installed WWMI mods.|
|`rename-wwmi-mod`|Rename installed WWMI mod.|
|`toggle-wwmi-mod`|Enable/disable installed WWMI mod.|
|`intsall-reshade`|Install ReShade.|
|`install-wwmi-dx12`|Install WWMI-DX12 (ReShade required).|
|`run-wwmi-dx12`|Run WWMI-DX12 script using Proton.|

### Command in detail

#### `install-deps`

Installs required Windows components into the Wuthering Waves prefix:

- `vcrun2022`, dependencies of **WWMI Launcher**
- `d3dcompiler_47` to fix [SpectrumQT/XXMI-Launcher#325](https://github.com/SpectrumQT/XXMI-Launcher/issues/325)
- `powershell` to run WWMI-DX12

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

### `manage-wwmi-mod`

```bash
./wuwa-mod-utils.sh manage-wwmi-mod
```

Open a wuwa-mod-manager to manage WWMI mods.
Can perform:

- `add-wwmi-mod`
- `rm-wwmi-mod`
- `ls-wwmi-mod`
- `rename-wwmi-mod`
- `toggle-wwmi-mod`

### `add-wwmi-mod`

```bash
./wuwa-mod-utils.sh add-wwmi-mod ZIP_PATH [MOD_NAME]
```

Add a mod from zip file.

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

```bash
./wuwa-mod-utils.sh install-wwmi-dx12 [ZIP_PATH]
```

Installs WWMI-DX12. It extract from `.zip` archive to `.../Wuthering Waves/Client/Binaries/Win64/`

The script will search for `wwmi-dx12*.zip` from `~/Downloads/` and currently
working directory(`$PWD`).

If no `.zip` archive is found, it will present a [Download URL](https://github.com/lekarsenten/wwmi-dx12/releases/latest)

You can pass a `ZIP_PATH` to install directly from given `.zip` archive.

### `run-wwmi-dx12`

```bash
./wuwa-mod-utils.sh run-wwmi-dx12 [--proton PROTON]
```

Runs the WWMI-DX12 launch script through Proton.

## Notes

- The script auto-detects Steam libraries, Proton installations, and the
Wuthering Waves prefix.
- It expects the game app ID to be `3513350`.
- It looks for the game executable in Steam library folders.
- It uses NVIDIA-related environment variables for Proton launch.

## Mod storage layout

The script installs XXMI Launcher at:

```text
.../drive_c/users/steamuser/Application Data/XXMI-Launcher
C:\users\steamuser\Application Data\XXMI-Launcher
```

The script expects WWMI mods under:

```text
.../drive_c/users/steamuser/Application Data/XXMI-Launcher/WWMI/Mods
C:\users\steamuser\Application Data\XXMI-Launcher\WWMI\Mods
```

Disabled mods are stored in:

```text
.../drive_c/users/steamuser/Application Data/XXMI-Launcher/WWMI/Mods/DISABLED
C:\users\steamuser\Application Data\XXMI-Launcher\WWMI\Mods\DISABLED
```

It detects `DISABLED` in the name of the mod directory, but not used in disabling
mods.

## References

- [SpectrumQT/XXMI Launcher](https://github.com/SpectrumQT/XXMI-Launcher)
- [ReShade](https://reshade.me/)
- [lekarsenten/WWMI-DX12](https://github.com/lekarsenten/wwmi-dx12)
