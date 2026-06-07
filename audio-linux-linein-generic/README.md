# audio-linux-linein

Route a USB audio device's line-in input (e.g. a console or secondary audio source connected via 3.5mm) to its own output using PipeWire, persistently across reboots and device replug events.

Tested on Linux Ubuntu 24.04 with Cinnamon and PipeWire 1.0.5. Should work on any modern PipeWire-based distribution.

---

## Use Case

This setup was developed to route Nintendo Switch audio (via a monitor's 3.5mm headphone jack) through a USB DAC/amp (Creative Sound Blaster X3), while the same device also handles PC audio over USB. The result is both audio sources mixed and available simultaneously through the DAC's output.

The same approach works for any scenario where you want to monitor a line-in source through the same USB audio device.

---

## Prerequisites

- PipeWire (with WirePlumber as the session manager)
- `pulseaudio-utils` for `pactl`

```bash
sudo apt install pulseaudio-utils
```

---

## Step 1: Find Your Device Names

List your audio sources and sinks:

```bash
pactl list sources short
pactl list sinks short
```

Look for your USB audio device in the output. You need two names:

- **Input (source):** the `alsa_input.usb-...analog-stereo` entry
- **Output (sink):** the `alsa_output.usb-...analog-stereo` entry

Also find the card name for the WirePlumber profile rule:

```bash
pactl list cards short
```

Look for the `alsa_card.usb-...` entry matching your device.

Example output (your serial ID will differ):

```
alsa_input.usb-Creative_Technology_Ltd_Sound_Blaster_X3_FACA0D7DF9F2D4AF-03.analog-stereo
alsa_output.usb-Creative_Technology_Ltd_Sound_Blaster_X3_FACA0D7DF9F2D4AF-03.analog-stereo
alsa_card.usb-Creative_Technology_Ltd_Sound_Blaster_X3_FACA0D7DF9F2D4AF-03
```

---

## Step 2: Configure the PipeWire Loopback

Create the drop-in config directory and file:

```bash
mkdir -p ~/.config/pipewire/pipewire.conf.d
cp pipewire/10-switch-loopback.conf ~/.config/pipewire/pipewire.conf.d/
```

Edit the file and replace the placeholder values with your actual device names from Step 1:

```bash
nano ~/.config/pipewire/pipewire.conf.d/10-switch-loopback.conf
```

Replace:
- `YOUR_DEVICE_ALSA_INPUT_NAME` → your `alsa_input.usb-...` source name
- `YOUR_DEVICE_ALSA_OUTPUT_NAME` → your `alsa_output.usb-...` sink name

---

## Step 3: Lock the Device Profile with WirePlumber

Without this step, the device may revert to a digital (IEC958) input profile on replug, causing the loopback to lose its target and fall back to a different audio source.

```bash
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
cp wireplumber/50-x3-profile.conf ~/.config/wireplumber/wireplumber.conf.d/
```

Edit the file and replace the placeholder:

```bash
nano ~/.config/wireplumber/wireplumber.conf.d/50-x3-profile.conf
```

Replace:
- `YOUR_DEVICE_CARD_NAME` → your `alsa_card.usb-...` card name from Step 1

---

## Step 4: Apply

```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

---

## Step 5: Verify

```bash
wpctl status
```

In the **Streams** section you should see two loopback entries:

```
output.loopback-...
     output_FL  >  YourDevice:playback_FL  [active]
     output_FR  >  YourDevice:playback_FR  [active]
input.loopback-...
     input_FL   <  YourDevice:capture_FL   [active]
     input_FR   <  YourDevice:capture_FR   [active]
```

Both streams should reference your USB audio device, not any other source (e.g. a webcam). If you see a different device in the `input.loopback` capture lines, see Troubleshooting below.

---

## Troubleshooting

### No line-in audio after replug

The device likely landed on the wrong profile. Verify:

```bash
pactl list cards | grep -A 5 "Active Profile"
```

If it shows `iec958` instead of `analog-stereo`, set it manually:

```bash
pactl set-card-profile YOUR_DEVICE_CARD_NAME output:analog-stereo+input:analog-stereo
```

Then confirm your WirePlumber profile rule is in place (Step 3) so this is handled automatically on future replug events.

### Loopback is capturing from the wrong device

Run `wpctl status` and check the `input.loopback` stream. If it shows a device other than your USB audio device's capture port, the analog input source wasn't available when PipeWire started — usually a profile issue (see above).

After fixing the profile, restart PipeWire:

```bash
systemctl --user restart pipewire pipewire-pulse
```

### Line-in volume too low

Boost the source volume (values above 1.0 amplify):

```bash
wpctl set-volume SOURCE_ID 1.5
```

Replace `SOURCE_ID` with the ID shown next to your device's source in `wpctl status`.

### Default audio output switched to wrong device after restart

Set it back explicitly:

```bash
wpctl set-default SINK_ID
```

Replace `SINK_ID` with the ID of your USB audio device's sink from `wpctl status`.

---

## How It Works

- **PipeWire loopback** (`libpipewire-module-loopback`) creates a persistent internal connection from the device's line-in (analog source) to its analog output. This runs transparently alongside normal PC audio from the same device.
- **WirePlumber profile rule** ensures the USB audio device always initialises with `output:analog-stereo+input:analog-stereo` — the profile that exposes both the analog output and analog line-in simultaneously. Without this, the device may default to a digital input profile on replug, which hides the line-in source and breaks the loopback target.
