<div align="center">
  <img src="./docs/public/icon.png" height="75" alt="MyCTL Logo">
  <h1>MyCTL Next</h1>
  <p><b>Architectural overhaul of MyCTL — A high-performance Linux desktop controller</b></p>
</div>

> [!WARNING]  
> Development shifted to https://github.com/mydehq/myctl-next

MyCTL is a CLI tool built on a **Lean Client / Fat Server** architecture. A tiny Go binary proxies all commands to a persistent Python daemon, enabling zero-latency CLI response times, deep system integration, and a self-bootstrapping plugin ecosystem.

## Architecture

```
myctl <command>  →  client Proxy  →  Unix Socket (IPC)  →  Python Daemon
                     (thin)                              (smart server)
```

- **Go Client** (`cmd/`): Fetches the command schema from the daemon at runtime and builds a Cobra CLI tree dynamically.
- **Python Daemon** (`daemon/`): Handles N-level command routing, plugin discovery, and native system integrations (PulseAudio, DBus).
- **Plugins** (`plugins/`, `~/.local/share/myctl/plugins/`): Self-contained Python packages declared via `pyproject.toml`.

## Installation

### From Source

**Prerequisites**: `mise`, `go`, `python 3.13+`, `uv`

```bash
git clone https://github.com/mydehq/myctl && cd myctl

# Install toolchain
mise install

# Build & install
mise run build
```

The compiled binary is placed at `bin/myctl`. Add it to your `$PATH`.

## Usage

```bash
# Start the daemon (auto-started on first command)
myctl daemon start

# Run any command
myctl <plugin> <command> [args]

# Get help
myctl --help
myctl <plugin> --help
```

## Plugin Development

Plugins are self-contained Python packages. Drop a folder into `~/.local/share/myctl/plugins/`:

```
myplugin/
├── pyproject.toml   # manifest ([project] + [tool.myctl])
└── main.py          # commands via @registry.add_cmd
```

See the [Plugin SDK Guide](docs/md/dev/plugin-sdk.md) for the full reference.

## Developer Documentation

The full technical documentation is available at the [MyCTL Developer Portal](https://mydehq.github.io/myctl):

- [Architecture Overview](docs/md/technical/architecture.md)
- [IPC Protocol Specification](docs/md/technical/ipc-protocol.md)
- [Plugin Discovery Engine](docs/md/technical/plugin-discovery.md)
- [Plugin SDK Guide](docs/md/dev/plugin-sdk.md)
- [Server API Reference](docs/md/dev/server-api.md)

## Related

- **MyDE**: [mydehq/MyDE](https://github.com/mydehq/myde)

---

<div align="center">

**Made with ❤️ by the MyDE Team**

</div>
