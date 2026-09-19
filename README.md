# Omarchy Sunsetr

An Omarchy bar widget for [`sunsetr`](https://github.com/psi4j/sunsetr): current
screen colour temperature, automatic/manual mode, and editable temperature
presets in one panel.

## Features

- Shows the current colour temperature and active preset.
- Switches between the automatic schedule and a persistent neutral override.
- Right-clicking the bar icon toggles the override immediately.
- Adjusts daylight, evening, bedtime, and neutral temperatures in 250 K steps.
- Keeps the paired morning/bedtime preset values consistent.

The widget expects `sunsetr` to be installed and running. Its automatic button
also supports the optional `~/.config/sunsetr/select-schedule` helper used by
the workstation configuration; without it, Automatic returns to sunsetr's
default profile.

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
