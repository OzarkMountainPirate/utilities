# audio-linux-linein-sbx3

Route Nintendo Switch audio through a Creative Sound Blaster X3 USB DAC using PipeWire, with PC audio running simultaneously through the same device.

This is a device-specific implementation for the **Creative Sound Blaster X3** (USB serial `FACA0D7DF9F2D4AF`). For a generic version that works with any USB audio device, see [audio-linux-linein-generic](../audio-linux-linein-generic/).

---

## Hardware Setup

```
PC ─────────────── USB ──────────────────┐
                                         X3 ──── Headphones / Speakers
Nintendo Switch ── HDMI ── Monitor ── 3.5mm ─── X3 Line-In
```

The monitor's 3.5mm headphone jack carries the Switch's HDMI audio out to the X3's line-in input. A PipeWire loopback routes that line-in signal to the X3's output, mixing it with PC audio transparently.

---

## Prerequisites

- PipeWire with WirePlumber as the session manager
- `pulseaudio-utils` for `pactl`

```bash
sudo apt install pulseaudio-utils
```

---

## Installation

### 1. PipeWire loopback

```bash
mkdir -p ~/.config/pipewire/pipewire.conf.d
cp pipewire/10-switch-loopback.conf ~/.config/pipewire/pipewire.conf.d/
```

### 2. WirePlumber profile lock

Prevents the X3 from reverting to a digital (IEC958) input profile on replug, which would break the loopback.

```bash
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
cp wireplumber/50-x3-profile.conf ~/.config/wireplumber/wireplumber.conf.d/
```

### 3. Apply

```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

---

## Verification

```bash
wpctl status
```

In the **Streams** section you should see:

```
output.loopback-...
     output_FL  >  Sound Blaster X3:playback_FL  [active]
     output_FR  >  Sound Blaster X3:playback_FR  [active]
input.loopback-...
     input_FL   <  Sound Blaster X3:capture_FL   [active]
     input_FR   <  Sound Blaster X3:capture_FR   [active]
```

Both loopback streams must reference the Sound Blaster X3. If `input.loopback` shows a different device (e.g. a webcam), see Troubleshooting.

---

## Troubleshooting

### No Switch audio after replug

The X3 likely reverted to a digital input profile. Check:

```bash
pactl list cards | grep -A 5 "Active Profile"
```

If it shows `iec958`, fix it manually:

```bash
pactl set-card-profile alsa_card.usb-Creative_Technology_Ltd_Sound_Blaster_X3_FACA0D7DF9F2D4AF-03 output:analog-stereo+input:analog-stereo
```

Then confirm the WirePlumber rule is installed (Step 2) so this is handled automatically going forward.

### Loopback capturing from wrong device

Run `wpctl status` and check the `input.loopback` stream. If it shows anything other than `Sound Blaster X3:capture`, the analog input wasn't available when PipeWire started — fix the profile (above) then:

```bash
systemctl --user restart pipewire pipewire-pulse
```

### Switch audio is too quiet

Boost the X3 line-in source volume (values above 1.0 amplify):

```bash
wpctl set-volume $(wpctl status | awk '/Sound Blaster X3 Analog Stereo/ && /Sources/{found=1} found && /Sound Blaster X3/{print $1; exit}') 1.5
```

Or find the source ID manually with `wpctl status` and run:

```bash
wpctl set-volume SOURCE_ID 1.5
```

### Default output switched to wrong device after restart

```bash
wpctl set-default $(wpctl status | grep -m1 "Sound Blaster X3 Analog Stereo" | awk '{print $1}' | tr -d '.')
```

Or set it manually by ID from `wpctl status`.
