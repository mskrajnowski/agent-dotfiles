---
name: desktop
description: >-
  Start, use, share, and stop a long-running headless Wayland desktop session
  (sway) inside the sandbox, so GUI applications can run there. Use when the
  user asks to start a desktop, run or show a GUI application in the sandbox,
  share the desktop with the host, take a screenshot of the desktop, or stop
  the desktop session.
---

# Headless Wayland desktop

A long-running sway (Wayland) session runs inside this sandbox without a GPU or
display. GUI applications — Wayland-native and, through Xwayland, X11 apps —
run in the session. The agent sees what happens via screenshots (`grim`); the
user sees and interacts via VNC/noVNC.

## Quickstart

```sh
scripts/start.sh                      # start (idempotent; reuse if already up)
scripts/run.sh foot                   # run a GUI app in the session
scripts/run.sh grim /tmp/desktop.png  # screenshot for the agent to inspect
scripts/stop.sh                       # stop when no longer needed
```

`screenshots` are plain PNG files — inspect them with the `vision` subagent.
Install GUI apps on demand (`apt install ...`); none are preinstalled.

## Scripts

- `scripts/start.sh` — start the session: headless sway, `wayvnc` bound to
  127.0.0.1:5900 (never published — it only serves websockify inside the
  sandbox), and `websockify`/noVNC on port 6080 (when noVNC is installed).
  Idempotent — run it again to get the current status. It also installs the
  desktop packages via apt if they are missing (they normally ship in the
  agent-kit image).
- `scripts/run.sh <command> [args...]` — run a command inside the session with
  the right `XDG_RUNTIME_DIR`, `WAYLAND_DISPLAY`, `SWAYSOCK`, and `DISPLAY` set.
  Do not set
  these variables yourself: the sandbox's default `WAYLAND_DISPLAY` points at
  the clipboard bridge, which is not a compositor.
- `scripts/stop.sh` — shut the session down gracefully.

## Sharing the desktop with the user

The user opens the desktop with the host-side helper (`sbx` and `agent-desktop`
run on the host, not in the sandbox — tell the user to run it, don't try to run
it yourself):

```sh
agent-desktop <sandbox-name>
```

It reuses the sandbox's existing noVNC host port publication or creates one,
and opens the desktop
(`http://localhost:<port>/vnc.html?autoconnect=true&reconnect=true&resize=scale`) in the
user's default browser. Published
ports bind to the host's loopback by default, so the desktop is only visible on
the user's machine.

## Behavior expectations

- One shared session per sandbox. Start it on demand, reuse it across turns,
  and stop it only when the user says the desktop is no longer needed (or the
  task that required it is clearly finished).
- The session lives inside the sandbox: it does not survive a sandbox restart.
  After a restart, simply run `scripts/start.sh` again.
- Stopping or restarting the session kills every app running inside it, and
  nothing is restored automatically — after a restart, relaunch the apps the
  user was using.
- Rendering is software-based (wlroots pixman renderer) — no GPU/GL
  acceleration. Complex 3D apps will be slow but should still work.
- Resolution is 1400x900, set in `sway.conf`. Adjust there if a different
  resolution is needed. wayvnc runs with `-R`, so VNC clients cannot change the
  resolution — they scale or scroll instead — which keeps the agent's
  screenshots and the user's view consistent regardless of viewer window size.
- Logs for a running session: `$SESSION_DIR/sway.log`, `wayvnc.log`,
  `websockify.log` (where `SESSION_DIR=/run/user/$(id -u)/desktop-session`).
