# Optional maintenance skill

If you regularly customise the remote, troubleshoot connections, or configure additional TVs, [`build-tv-remote`](../skills/build-tv-remote/SKILL.md) packages that workflow for an agent. It is optional; the app and the setup instructions above do not depend on it.

In Codex, ask the built-in installer:

```text
$skill-installer install https://github.com/tayors/mac-tv-remote/tree/main/skills/build-tv-remote
```

Then use it for a specific task:

```text
Use $build-tv-remote to diagnose why my existing remote cannot connect to my TV.
```

The skill points to this repository's source instead of bundling another copy. It can work with an existing checkout or help obtain one. See the [official Codex skill documentation](https://learn.chatgpt.com/docs/build-skills) for local installation options. Other agents can read the same instructions, though their skill discovery behaviour is untested here.
