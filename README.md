# Omarchy Sunsetr

An Omarchy bar widget and policy controller for
[`sunsetr`](https://github.com/psi4j/sunsetr), inspired by the parts of f.lux
that give the user direct control over their circadian schedule.

## Features

- Smooth waking, daylight, sunset, evening, wind-down, and sleep phases.
- Explicit wake time, sleep time, wind-down duration, and transition duration.
- Solar timing from manually entered coordinates—no GPS or location service—or
  a completely fixed evening time.
- Separate daylight, evening, bedtime, manual, and neutral temperatures.
- Automatic, manual, and neutral modes plus one-hour and until-wake disables.
- Right-clicking the bar icon quickly disables/resumes the filter for one hour.
- Disable for the active application and maintain the exclusion list in-panel.
- Optional automatic disable whenever the active window is fullscreen.
- Connected-display inventory and honest backend capability reporting.

The widget expects either `sunsetr` or `wl-gammarelay-rs` to be running. With
`sunsetr`, it writes its own static runtime preset, `omarchy-circadian`, and
continuously reconciles that preset with the schedule and active-window rules.
User settings live in `~/.config/omarchy-sunsetr/settings.json`.

The stock sunsetr/hyprsunset backend applies one transform to every output. For
independent display switches, install and run
[`wl-gammarelay-rs`](https://github.com/MaxVerevkin/wl-gammarelay-rs). The
controller detects its D-Bus service automatically. A user-service template is
included at `systemd/wl-gammarelay-rs.service`; stop Sunsetr before enabling it
so two gamma controllers do not compete. Without that backend, display switches
stay read-only and all other controls continue to work.

On Omarchy, the optional per-display backend can be enabled with:

```bash
omarchy pkg aur add wl-gammarelay-rs
install -Dm644 ~/.config/omarchy/plugins/venifko.sunsetr/systemd/wl-gammarelay-rs.service \
  ~/.config/systemd/user/wl-gammarelay-rs.service
systemctl --user disable --now sunsetr.service sunsetr-schedule.timer
systemctl --user daemon-reload
systemctl --user enable --now wl-gammarelay-rs.service
```

## Install

```bash
omarchy plugin add https://github.com/venifko/omarchy-sunsetr --enable
omarchy bar put venifko.sunsetr --section right
```

For a local checkout, copy or symlink the repository to
`~/.config/omarchy/plugins/venifko.sunsetr` and add `venifko.sunsetr` to the bar.

## IPC

```bash
omarchy-shell ipc call venifko.sunsetr toggle
```

## Development

```bash
python -m unittest discover -s test -v
```
