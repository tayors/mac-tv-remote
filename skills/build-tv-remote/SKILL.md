---
name: build-tv-remote
description: Build, customise, and troubleshoot a native macOS menu-bar remote for an Android TV or Google TV with authorised network ADB access. Use for a personal Mac TV remote, its pairing/setup flow, app shortcuts, and connection recovery.
---

# Build a TV remote

Use the working native starter in [assets/starter](assets/starter) as the base. It contains the AppKit/SwiftUI app, bounded Python ADB transport, build script, and offline tests. Copy it into the user's project with:

```sh
python3 <skill-directory>/scripts/create_remote.py <new-project-directory>
```

The generator refuses existing destinations. Adapt an existing remote in place when that is what the user asked for. Run commands from the generated directory; the skill itself need not be modified.

## Establish the device and connection

Determine the TV platform before choosing a transport. The starter supports Android/Google TV with network ADB; its original implementation was tested with a TCL Smart TV Pro. Samsung Tizen, LG webOS, Roku, and other platforms require a separate implementation. A familiar brand name or an open Cast port does not establish ADB support. Describe untested models as unverified.

Use an existing authorised connection if available (`adb devices -l`). Otherwise get the TV's actual ADB host and port from its debugging settings. Keep discovery to the user's intended local network or a supplied address. Do not assume port 5555 or invent a TV address. The Mac and TV need network connectivity; the user enables debugging and accepts the TV's authorisation prompt. For TVs that offer a pairing-code workflow, use the pairing endpoint with `adb pair`, then the distinct connection endpoint with `adb connect`. Do not collect or publish the Mac's ADB private keys.

Verify with `adb -s HOST:PORT get-state`, then a read-only status request. Enable debugging rather than weakening network or OS protections. On macOS, child processes may be subject to the parent app's Local Network permission. The app includes a purpose description; if macOS denies access, explain how to allow the intended app in System Settings instead of bypassing permission checks.

## Configure and personalise

The first launch has no saved endpoint, MAC, or broadcast address. Settings saves the remote name and endpoint in the app's macOS preferences. Wake MAC and IPv4 broadcast are an optional pair; omit them unless known. Network wake is device-dependent. Never report success solely because a UDP packet was sent.

Run `python3 remote_bridge.py --device HOST:PORT --discover status` to read power, foreground app, device model, and recognised enabled apps. This does not wake the TV. The app shows matching shortcuts from the catalog rather than assuming all streaming services are installed. For another app, verify its package and TV-launcher activity, then add the package mapping in `tv.py` and its label/symbol in `Remote.swift`. Package IDs are not display names.

Adapt the title, controls, visual style, and shortcuts to the user's preference. Preserve accessible button names, keyboard controls, system light/dark appearance, and visible connection feedback. Keep settings and status separate from TV actions: Refresh reads; Sleep, Turn on, navigation, playback, and app shortcuts act. Do not include package disabling, uninstallation, picture calibration, or brightness automation as part of building a remote.

## Preserve transport behaviour

- Keep ADB subprocesses bounded, and check failure text as well as exit status: `adb connect` can print a failure and exit zero.
- Reuse a live transport. Keep status requests off the navigation queue, bound queued controls, and ignore stale status completions.
- Ordinary Refresh must not restart the shared ADB daemon. Explicit Reconnect may reset this TV's transport. The supplied repair only restarts an idle daemon after verifying the TV port is reachable and that ADB lists no other devices. If another device is present, stop the repair and explain the conflict.
- Parse device responses defensively. Do not forward arbitrary user input to Android's shell. Resolve and validate a TV app's component before launching it.
- The GUI's PATH can differ from a shell. Maintain Python/ADB lookup for both Apple Silicon and Intel Homebrew installations, with clear dependency errors. Keep Python bytecode out of the signed app bundle (`python3 -B`).

## Build and verify

From the project directory:

```sh
PYTHONPATH=. python3 -B -m unittest discover -s tests -v
./build.sh
```

The build needs macOS 13+, Swift command-line tools, Python 3.9+, and Android Platform Tools. The script creates `~/Applications/Mac TV Remote.app`, with an explicit macOS 13 deployment target and a local ad-hoc signature. It is not a notarised binary. A different output path can be passed to `build.sh`.

Open the built app and check both the first-run screen and a live connection when a TV is available. Verify Refresh through its progress and updated time. Use a reversible control when testing actions and restore any test changes. Do not interrupt playback merely to prove a button works. Report which checks used a real device and which used fixtures; a passing offline test is not hardware certification.

When preparing a public copy, include only the generated source and synthetic test data. Exclude preferences, actual endpoints and MACs, pairing material, ADB keys, local paths, logs, and captured TV diagnostics. Preserve the MIT licence from this repository in redistributed starter code.

## Authoritative references

Consult these when connection behaviour or a platform assumption needs verification:

- [Android Debug Bridge](https://developer.android.com/tools/adb): debugging, pairing, connecting, and device states.
- [Apple TN3179](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy): macOS Local Network permission and responsible processes.
