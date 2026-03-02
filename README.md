# Mriya58 ZMK Firmware

ZMK firmware config for the [Mriya58](https://github.com/HolySwitch) split keyboard (58-key, column-staggered, nice!nano v2).

## Prerequisites

- Docker
- [just](https://github.com/casey/just)

## Usage

```bash
just init           # one-time setup (~5 min)
just build          # build both halves
just flash-left     # double-tap reset on left half, then run this
just flash-right    # double-tap reset on right half, then run this
```

Edit your layout in `config/mriya.keymap`, then `just build`.

## Fixing BT pairing

```bash
just build-reset    # build settings_reset firmware
```

Flash `settings_reset` to both halves, then flash normal firmware again.