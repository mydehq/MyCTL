<div align="center">
  <h1>MyCTL</h1>
  <p><b>A powerful CLI to control your Linux Desktop</b></p>
</div>

MyCTL is a cli tool that provides a unified way to control common Linux desktop operations. It offers audio control, theme management, distro-agnostic package management, screenshot utilities, interactive menus, and more.
<br>
While it integrates seamlessly with the MyDE desktop environment, MyCTL works independently on any Linux system.

---

## Usage

For Usage & Configuration, visit [Documentation](https://mydehq.github.io/MyWiki/docs/user-guide/myctl)

## Installation

### Arch Linux (AUR)

The package is available on the AUR as `myctl`:

#### 1. Using AUR helper

```bash
# Using an AUR helper (e.g., yay, paru)
yay -S myctl
# or
paru -S myctl
```

#### 2. Manually

```bash
# Clone repo & cd into it
git clone https://aur.archlinux.org/myctl && cd myctl

# Build package
makepkg

# Install the package
sudo pacman -U myctl-*.pkg.tar.zst
```

### Dependencies

Install Required dependencies:

- `bash` - Shell interpreter
- `gawk` - Text processing
- `sed` - Stream editor
- `grep` - Pattern matching
- `rofi` - Application launcher and menu system
- `wob` - Wayland overlay bar for visual feedback

### From Source

```bash
git clone https://github.com/mydehq/MyCTL && cd MyCTL

bash install.sh
```

## 🔗 Related Resources

- **Main Repository**: [mydehq/MyDE](https://github.com/mydehq/MyDE)
- **Wiki Repository**: [mydehq/MyWiki](https://github.com/mydehq/MyWiki)
- **KireiSakura-Kit**: [Dependency Library](https://soymadip.github.io/KireiSakura-Kit)

---

<div align="center">

**Made with ❤️ by the MyDE Team**

</div>
