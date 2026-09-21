# PixProTransform 1.3.3

Opens Pixelmator Pro's Perspective Transform in one step, instead of the trip
through Format → Effects → Other → Perspective Transform.

### [⬇︎ Download the latest release](https://github.com/spurious-cox/pixprotransform/releases/latest)

Notarized and stapled by Apple — open the DMG and drag PixProTransform to Applications,
or install it with Homebrew:

```
brew install --cask spurious-cox/tap/pixprotransform
```
Requires Pixelmator Pro. Both the 3.x build and the Creator Studio build work;
the app binds to whichever one is in front or has a document open.

## Using it

1. Open the image in Pixelmator Pro and select the layer to transform.
2. Run PixProTransform.
3. Perspective Transform opens on that layer with its handles live on the
   canvas. Drag the corners — the app's part is over once the effect is open.

## Accessibility access is required

Pixelmator's AppleScript dictionary does not expose this effect, so the only
way in is to click the menu item — and clicking another app's menus is an
Accessibility operation. Grant it under **System Settings → Privacy & Security
→ Accessibility**; the first run also asks for Automation permission.

If nothing opens, the usual reason is that no image is open in Pixelmator Pro,
which grays the effect out. The app reports the underlying error rather than
failing silently.

## How it works

The running Pixelmator is resolved by **process**, not by bundle identifier:
several copies of one build can be installed and copies share an id, so
addressing by id could talk to — and launch — the wrong copy. `ps` gives the
real bundle path and pid, and the menu click is keyed to that pid.

## Building

```
./build.sh
```

Signing uses a Developer ID certificate selected by SHA-1 hash and timestamped,
which is what keeps macOS's Automation grant alive across rebuilds.
`~/My_Applications/_signing/pixpro_release.sh all <App>` signs and notarizes;
`pixpro_publish.sh <App>` wraps it in the DMG and updates the cask.

## License

MIT. See [LICENSE](LICENSE).
