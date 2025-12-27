<div align="center">
  <img src="./app/icons/icon.png" height="75" alt="MyCTL Logo">
  <h1>MyCTL</h1>
  <p><b>A powerful CLI to control your Linux Desktop</b></p>

MyCTL is a cli tool that provides a unified way to control common Linux desktop operations.   
While it integrates with the MyDE desktop environment, MyCTL works independently on any Linux system.

</div>

---

## Installation

### Arch Linux

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

### From Source

Install Required dependencies:

- `bash` - Shell interpreter
- `gawk` - Text processing
- `sed` - Stream editor
- `grep` - Pattern matching
- `rofi` - Application launcher and menu system
- `wob` - Wayland overlay bar for visual feedback
- `wireplumber` - For volume control

```bash
git clone https://github.com/mydehq/myctl && cd myctl

bash app/bin/myctl
```

## Usage

For Usage & Configuration, visit [Documentation](https://mydehq.github.io/mywiki/docs/user-guide/myctl)

## Related Resources

- **Main Repository**: [mydehq/MyDE](https://github.com/mydehq/myde)
- **Wiki Repository**: [mydehq/MyWiki](https://github.com/mydehq/mydehq.github.io)
- **Dependency Library**: [soymadip/KireiSakura Kit](https://soymadip.github.io/KireiSakura-Kit)

---

<div align="center">

**Made with ❤️ by the MyDE Team**

</div>
