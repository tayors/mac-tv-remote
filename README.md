# Mac TV Remote

Build a native Mac menu-bar remote for your own Android TV or Google TV. Includes a working SwiftUI/AppKit app and the **build-tv-remote** agent skill for setup, customisation, and troubleshooting.

The remote has a circular directional pad, keyboard navigation, playback and volume controls, app shortcuts, and connection recovery. It runs locally, with no account, cloud service, telemetry, or app installed on the TV.

**Compatibility:** the original remote was tested with a TCL Smart TV Pro. Other models are unverified. Your TV must support authorised network ADB. Samsung Tizen, LG webOS, Roku, and other non-Android platforms need different transports; this release does not support them. Wake from standby depends on the TV and its network settings.

## Build yours with an agent

In Codex, ask the built-in skill installer:

```text
$skill-installer install https://github.com/tayors/mac-tv-remote/tree/main/skills/build-tv-remote
```

Then use:

```text
Use $build-tv-remote to build a Mac menu-bar remote for my TV.
Identify what it supports, help me connect, and customise the controls for me.
```

The skill includes the complete starter, so an agent can copy and adapt it without recreating the app. It guides device identification, ADB authorisation, app discovery, native UI customisation, building, and testing. It does not disable TV packages or adjust picture settings.

For manual local installation, clone this repository, then symlink the skill from the repository root:

```sh
mkdir -p "$HOME/.agents/skills"
ln -s "$PWD/skills/build-tv-remote" "$HOME/.agents/skills/build-tv-remote"
```

This leaves an existing installation alone: `ln` fails if that destination exists. Keep the clone in place while using the symlink. Codex supports these user-level skill folders; see the [official skill documentation](https://learn.chatgpt.com/docs/build-skills). Other agents can use the portable `SKILL.md` instructions and assets, but their installation and discovery behaviour is not tested here.

## Build without an agent

Requirements:

- A Mac with macOS 13 or newer and Xcode command-line tools (`swiftc`).
- Python 3.9 or newer. The app looks in Apple Silicon Homebrew, Intel Homebrew, then `/usr/bin`.
- [Android SDK Platform Tools](https://developer.android.com/tools/releases/platform-tools), with `adb` installed.
- An Android/Google TV that allows network ADB, on a network reachable from the Mac.

```sh
git clone https://github.com/tayors/mac-tv-remote.git
cd mac-tv-remote
./scripts/test.sh
./scripts/build.sh
open "$HOME/Applications/Mac TV Remote.app"
```

The build creates a locally ad-hoc-signed app, not a notarised downloadable binary. It targets the Mac's current CPU architecture. The macOS 13 deployment target does not establish testing on every macOS release or on Intel hardware.

On first launch, select **Set up TV** or the settings icon. Enter a name and the TV's actual ADB `host:port`. The app has no default endpoint. Enable debugging and accept the Mac's authorisation prompt on the TV. For a pairing-code TV, complete `adb pair PAIRING_HOST:PAIRING_PORT` first, then enter its separate connection endpoint. Follow [Android's ADB instructions](https://developer.android.com/tools/adb) for your device.

Leave Wake MAC and broadcast blank unless you know both values. Without network-wake details, Turn on tries the explicit Android wake key through ADB. A deeply sleeping TV may need its physical remote. If macOS asks, allow this app to access the local network; see [Apple's Local Network guidance](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy).

## Controls and connections

- Arrow keys navigate; Return selects; Space toggles playback; Escape sends Back while the remote has keyboard focus.
- Refresh reads status and shows a timestamp. It never wakes the TV and runs separately from queued control commands.
- Status updates every 15 seconds while the popover is open. ADB subprocesses have five-second timeouts; the app also bounds whole requests.
- **More options → Reconnect to TV** resets that TV's ADB transport. It can restart an idle ADB service when the TV's port is reachable but the service reports “No route to host.” It stops that repair if ADB lists another device.
- The app discovers enabled packages from a catalog of YouTube, Stremio, Netflix, Prime Video, Disney+, and Apple TV. It only shows matching shortcuts. Package presence does not guarantee a launchable TV activity; the launcher checks that when opening an app.

Device name, address, and optional wake details stay in this Mac user's app preferences. The app writes diagnostic failures to the local macOS log. Do not include those logs or your preferences in a public issue without removing private details.

## Customise the starter

Create a separate project from the bundled source:

```sh
python3 skills/build-tv-remote/scripts/create_remote.py ../my-tv-remote
cd ../my-tv-remote
PYTHONPATH=. python3 -B -m unittest discover -s tests -v
./build.sh
```

The generator refuses existing destinations. The source lives in `skills/build-tv-remote/assets/starter/`:

- `Remote.swift`: native interface, preferences, keyboard input, and request queues.
- `tv.py`: bounded ADB commands, status parsing, app catalog, and activity validation.
- `remote_bridge.py`: command-line bridge, optional Wake-on-LAN, and explicit reconnection.
- `build.sh`: app packaging, deployment target, and ad-hoc signing.
- `tests/`: offline transport and device-response fixtures.

Add a streaming app by verifying its Android package ID and TV-launcher activity, then updating the Python catalog and Swift shortcut label/icon. To install multiple customised remotes side by side, change the app output name and bundle identifier in `build.sh`; otherwise they share the default preferences domain.

## Development and compatibility reports

```sh
./scripts/test.sh
python3 -B -m unittest discover -s tests -v
./scripts/build.sh "/tmp/Mac TV Remote Test.app"
codesign --verify --strict "/tmp/Mac TV Remote Test.app"
```

CI runs offline tests on Linux and macOS and builds the app on macOS. These checks do not certify hardware compatibility. Useful compatibility reports include TV brand/model, OS version, Mac architecture, and which controls worked. Exclude actual IP/MAC addresses, pairing codes, ADB keys, serial numbers, and unredacted diagnostics.

This repository contains the remote and its setup skill. It excludes the original device-specific calibration experiments, background jobs, package inventories, and captured diagnostics.

## Licence

[MIT](LICENSE). Preserve the licence when distributing a customised starter.
