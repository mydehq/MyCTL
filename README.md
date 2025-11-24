# MyCTL

**MyCTL** - A powerful CLI to control your Linux Desktop

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Version](https://img.shields.io/badge/version-1.0.4-green.svg)](https://github.com/mydehq/MyCTL/releases)

MyCTL is a standalone command-line interface tool that provides a unified way to control common Linux desktop operations. It offers audio control, theme management, distro-agnostic package management, screenshot utilities, interactive menus, and more. While it integrates seamlessly with the MyDE desktop environment, MyCTL works independently on any Linux system.

## Features

### 🎵 Audio Management
- Control speaker and microphone volume
- Mute/unmute audio devices
- Visual feedback with WOB (Wayland Overlay Bar) integration

### 🎨 Theme Management
- Get and set GTK themes
- Rofi theme configuration
- Cursor theme and size management

### 📦 Package Management
- Distro-agnostic package management wrapper
- Install, remove, search, and update packages
- Automatic distro detection and base distro identification

### 📸 Screenshot Utilities
- Capture screenshots of selected areas
- Full screen captures
- Active window screenshots
- Integration with screenshotting tools

### 🚀 System Control
- Configuration reload (Hyprland compositor support)
- Default terminal emulator setup
- Desktop file management and queries
- Application launcher integration

### 🎯 Interactive Menus
- Power menu with shutdown/reboot/logout options
- Keybinds reference menu
- WiFi management menu
- TUI application launcher

## Installation

### Arch Linux (AUR)

The package is available on the AUR as `myctl`:

```bash
# Using an AUR helper (e.g., yay, paru)
yay -S myctl
# or
paru -S myctl
```

### From Source

1. Clone the repository:
```bash
git clone https://github.com/mydehq/MyCTL.git
cd MyCTL
```

2. Install manually:
```bash
# Install binaries
sudo install -Dm755 app/bin/* /usr/bin/

# Install libraries
sudo mkdir -p /usr/lib/myctl
sudo install -Dm644 app/lib/* /usr/lib/myctl/

# Install assets
sudo mkdir -p /usr/share/myctl
sudo cp -r app/src/* /usr/share/myctl/
```

### Dependencies

Required dependencies:
- `bash` - Shell interpreter
- `gawk` - Text processing
- `sed` - Stream editor
- `grep` - Pattern matching
- `rofi` - Application launcher and menu system
- `wob` - Wayland overlay bar for visual feedback

Optional dependencies vary based on your desktop environment and the features you use.

## Usage

### Basic Command Structure

```bash
myctl <command> <subcommand> [options]
```

### Get Information

Retrieve system configuration and status:

```bash
# Get current volume
myctl get volume

# Get microphone volume
myctl get mic

# Get current GTK theme
myctl get theme gtk

# Get current Rofi theme
myctl get theme rofi

# Get cursor theme and size
myctl get cursor theme
myctl get cursor size

# Get distro information
myctl get distro
myctl get distro base

# Get desktop file of an application
myctl get desktop-file <app_name>
```

### Set Configuration

Modify system settings:

```bash
# Set volume (increase by 5)
myctl set volume +5

# Set volume (decrease by 5)
myctl set volume -5

# Mute/unmute volume
myctl set volume mute
myctl set volume unmute
myctl set volume toggle

# Set microphone volume
myctl set mic +5
myctl set mic mute

# Set GTK theme
myctl set theme gtk <theme_name>

# Set Rofi theme
myctl set theme rofi <theme_name>

# Set default terminal
myctl set terminal
```

### Screenshots

Capture screenshots easily:

```bash
# Screenshot of selected area (default)
myctl get snip
myctl get snip area

# Screenshot of active window
myctl get snip active

# Screenshot of entire screen
myctl get snip screen
```

### Package Management

Use the distro-agnostic package manager wrapper:

```bash
# Install packages
myctl pkg add <package_name>
mypm add <package_name>

# Remove packages
myctl pkg rm <package_name>
mypm rm <package_name>

# Search for packages
myctl pkg search <query>

# Update packages
myctl pkg update

# Sync package database
myctl pkg sync
```

Note: `mypm` is a convenience wrapper for `myctl pkg` commands.

### Interactive Menus

Show various interactive menus:

```bash
# Display power menu (shutdown, reboot, logout, etc.)
myctl show power-menu

# Display keybinds reference
myctl show keybinds

# Display WiFi menu
myctl show wifi-menu

# Launch TUI application
myctl show tui [-t <terminal>] [-c <class>] [-e <exec>]
```

### System Management

```bash
# Reload configuration (Hyprland compositor)
myctl reload

# Setup WOB daemon for visual feedback
myctl setup wob-daemon

# Show WOB bar with specific level
myctl show wobar <level>
```

### Help

Get help for any command:

```bash
# General help
myctl help

# Help for specific commands
myctl get help
myctl set help
myctl pkg help
myctl show help

# Help for subcommands
myctl get theme help
myctl set volume help
```

## Configuration

MyCTL uses configuration files located at:
- User config: `~/.config/myde/myde.conf`
- System config: `/etc/myde/myde.conf`

Library and source directories:
- User installation: `~/.local/lib/myctl/`, `~/.local/src/myctl/`
- System installation: `/usr/lib/myctl/`, `/usr/share/myctl/`

## Project Structure

```
MyCTL/
├── app/
│   ├── bin/          # Main executables (myctl, mypm)
│   ├── lib/          # Library modules
│   │   ├── audio-utils.sh
│   │   ├── gtk-utils.sh
│   │   ├── pkg-utils.sh
│   │   ├── power-menu.sh
│   │   ├── rofi-utils.sh
│   │   └── ... (other utility libraries)
│   └── src/          # Assets and resources
│       ├── rofi/     # Rofi themes and configs
│       └── *.awk     # AWK scripts for parsing
├── PKGBUILD          # Arch Linux package build file
└── LICENSE           # GPL-3.0 License
```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please follow the conventional commits format for commit messages.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Author

**Soymadip** - <soumadip@zohomail.in>

## Repository

- GitHub: [mydehq/MyCTL](https://github.com/mydehq/MyCTL)
- Issues: [Report a bug or request a feature](https://github.com/mydehq/MyCTL/issues)

## Acknowledgments

- Integrates seamlessly with [MyDE](https://github.com/mydehq) (My Desktop Environment) but works standalone
- Built with love for the Linux community
