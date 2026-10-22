---
name: build-tv-remote
description: Customise, troubleshoot, and extend a native macOS menu-bar remote for an Android TV or Google TV with authorised network ADB. Use for ongoing remote maintenance, app shortcuts, connection recovery, or configuring additional TVs.
---

# Maintain a TV remote

Use this optional workflow for repeated work on a Mac TV remote. Initial setup needs only the [repository README](https://github.com/tayors/mac-tv-remote#readme), its copy-and-paste prompt, and the working app source; installing a skill is not a prerequisite.

## Locate the project

Start with the user's existing remote project when available. The reference implementation is [tayors/mac-tv-remote](https://github.com/tayors/mac-tv-remote). If no checkout exists, obtain one in a new working directory without replacing the user's files.

The repository's canonical source is in `app/`; it is not bundled inside this skill. Installed skill folders can live anywhere, so do not infer a source path relative to the installed skill. To make a separate customised project, run from a repository checkout:

```sh
python3 scripts/create_remote.py <new-project-directory>
```

The generator refuses existing destinations. It copies the source into the generated project's root. In that project, test with `PYTHONPATH=. python3 -B -m unittest discover -s tests -v` and build with `./build.sh`. In the original repository, use `./scripts/test.sh` and `./scripts/build.sh`.

## Check connection assumptions

The reference transport is network ADB for Android/Google TV, originally tested on a TCL Smart TV Pro. Other models are unverified. Samsung Tizen, LG webOS, Roku, and other non-Android platforms need separate transports. A brand name or an open Cast port does not establish ADB support.

Reuse an authorised connection from `adb devices -l`, or get the actual host and port from the TV's debugging settings. Keep discovery to the intended local network or supplied address. Do not assume port 5555. For pairing-code TVs, `adb pair` uses the pairing endpoint; `adb connect` uses the distinct connection endpoint. The user enables debugging and accepts authorisation on the TV.

Verify `adb -s HOST:PORT get-state`, then `python3 remote_bridge.py --device HOST:PORT --discover status` from the source directory. This reads power, foreground app, device model, and recognised enabled apps without waking the TV. A Mac app's child processes may be subject to its Local Network permission; explain the intended permission instead of bypassing it.

## Make the requested change

For another app shortcut, verify its package ID and TV-launcher activity, update `APPS` in `tv.py`, and add its label/symbol in `Remote.swift`. Do not assume a streaming app is installed. Preserve accessible labels, keyboard input, system light/dark appearance, and visible connection feedback when adjusting the UI.

Keep TV addresses and optional Wake MAC/broadcast values in local preferences. Do not invent network-wake details or report a successful wake merely because a packet was sent. Package disabling, uninstallation, picture calibration, and background brightness automation are outside remote maintenance unless separately requested.

Preserve these transport behaviours:

- Bound subprocesses and the control queue; keep status work off the navigation queue and ignore stale completions.
- Check ADB failure text as well as exit status: `adb connect` can print a failure and exit zero.
- Refresh only reads. Explicit Reconnect resets this TV's transport; the supplied daemon repair requires a reachable TV port and no other listed ADB devices. Stop that repair if another device is present.
- Validate resolved app components before forwarding them to Android's shell.
- Keep Python/ADB lookup for both Homebrew locations and `/usr/bin/python3`; GUI PATH can differ from a shell. Use Python's `-B` option so bytecode does not modify the signed bundle.

## Verify and report

Run the project's relevant offline tests and build after code changes. The build requires macOS 13+, Swift command-line tools, Python 3.9+, and Android Platform Tools. It produces a locally ad-hoc-signed app, not a notarised binary, and accepts an alternate output path. Use another output name and bundle identifier when installing independent remotes side by side.

Check the changed behaviour in the built app when practical. Use read-only status first; do not interrupt playback just to prove a button works. Restore any reversible test changes. Distinguish real-TV checks from fixtures and identify compatibility limits.

Keep actual endpoints, MACs, pairing material, ADB private keys, local paths, preferences, and captured diagnostics out of public commits. Preserve the starter's MIT licence when redistributing it.

For device-specific uncertainty, consult [Android's ADB documentation](https://developer.android.com/tools/adb) or [Apple TN3179](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy).
