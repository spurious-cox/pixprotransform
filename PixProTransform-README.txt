=============================================================================
 PixProTransform — Perspective Transform in one step
=============================================================================

PixProTransform opens Pixelmator Pro's Perspective Transform effect, saving
the trip through Format > Effects > Other > Perspective Transform.

Pixelmator Pro's AppleScript dictionary does not expose that effect, so the
only way in is to click the menu item. Everything below follows from that.

App:     /Applications/PixProTransform.app
Source:  ~/My_Applications/PixProTransform/PixProTransform.applescript
Rebuild: ~/My_Applications/PixProTransform/build.sh


-----------------------------------------------------------------------------
 HOW TO USE IT
-----------------------------------------------------------------------------

    1. In Pixelmator Pro, open the image and select the layer to
       transform.

    2. Run PixProTransform (/Applications/PixProTransform.app).

    3. Perspective Transform opens on that layer with its handles live on
       the canvas. Drag the corners — the app's part is over once the
       effect is open.

The first run asks for Accessibility and Automation permission; both have to
be granted or the menu click cannot happen. If nothing opens, the usual
reason is that no image is open in Pixelmator Pro, which grays the effect
out.


-----------------------------------------------------------------------------
 ACCESSIBILITY ACCESS IS REQUIRED
-----------------------------------------------------------------------------

Clicking another app's menus is an Accessibility operation. Without the
permission the click fails and the app reports that it could not open the
effect.

    System Settings > Privacy & Security > Accessibility
    add or switch on PixProTransform

The first run may also ask for permission to control Pixelmator Pro; that is
the separate Automation prompt, and it needs a yes as well.


-----------------------------------------------------------------------------
 WHICH PIXELMATOR IT DRIVES
-----------------------------------------------------------------------------

Two builds are installed on this Mac, and they are separate apps:

    com.apple.pixelmator             Pixelmator Pro Creator Studio (4.x)
    com.pixelmatorteam.pixelmator.x  Pixelmator Pro (3.x)

PixProTransform looks for the FRONTMOST one first and falls back to whichever
is running, addressing it by bundle identifier.

That matters. Since the Creator Studio rebrand, `tell application "Pixelmator
Pro"` can resolve to whichever build macOS decides — not necessarily the one
you are looking at. The original one-line version of this script used the
name and was subject to exactly that. Any other PixPro applet still written
that way has the same weakness.


-----------------------------------------------------------------------------
 WHEN IT DOES NOTHING
-----------------------------------------------------------------------------

The effect is greyed out unless an image is open, and a greyed menu item
cannot be clicked. If nothing happens, check in this order:

    1. Is an image open in Pixelmator Pro?
    2. Is PixProTransform enabled under Accessibility?
    3. Did the Automation prompt get declined at some point?
       System Settings > Privacy & Security > Automation

The app reports the underlying error rather than failing silently.


-----------------------------------------------------------------------------
 THE OLDER ROUTE, STILL INSTALLED
-----------------------------------------------------------------------------

The same action already exists as a Quick Action, and this app does not
replace or disturb it:

    /Applications/PixProTransformer.scpt
        an Automator Quick Action bundle, despite the .scpt name
    ~/Library/Services/PixProTransform.workflow
        an alias pointing at it

The original compiled script it was built from is at
/Applications/PixProTransform.applescript — also despite its name, that file
is compiled, not text, which is why opening it in an editor shows gibberish.
Use `osadecompile` to read it. It is superseded by the source in this folder.


-----------------------------------------------------------------------------
 REBUILDING
-----------------------------------------------------------------------------

    cd ~/My_Applications/PixProTransform
    ./build.sh

That compiles the source, restores the bundle identity and version, signs
with the Apple Development certificate, and installs to /Applications.

Signing uses the certificate's SHA-1 hash rather than its name: the expired
2023 certificate is still in the keychain under an identical name, and
signing by name can pick the dead one. --timestamp keeps the signature valid
after the certificate expires on 2027-08-05.

The icon comes from your own artwork at
~/Pictures/Pixelmator/PixProStuff/PixProTransform.pxd. That document is only
200x200, but its content is vector shapes, so it was resized to 1024x1024 in
Pixelmator (on a copy) and exported before the .icns was built — no upscaling
blur. icon/build_icon.py rebuilds the .icns from any source image.

One trap worth knowing: osacompile writes an Assets.car holding the stock
applet icon and sets CFBundleIconName to point at it. The asset catalog WINS
over CFBundleIconFile, so a custom .icns can sit in the bundle and never be
used. build.sh deletes both the Assets.car and the CFBundleIconName key.


-----------------------------------------------------------------------------
 VERSION HISTORY
-----------------------------------------------------------------------------

v1.0.0  (2026-08-05)
    First proper app. Built from the compiled one-liner that had been sitting
    loose in /Applications. Adds bundle identity, version and copyright,
    targets Pixelmator by bundle identifier instead of by name, reports why
    it failed instead of doing nothing, and is signed and timestamped.

v1.1.0  (2026-08-05)
    Added the PixProTransform icon, built from the vector artwork in
    ~/Pictures/Pixelmator/PixProStuff/ resized to 1024. Removing the
    CFBundleIconName key and Assets.car was what actually made it appear.


v1.2.0  (2026-08-15)
    Resolves Pixelmator by PROCESS rather than by bundle identifier. Several
    COPIES of one build can be installed and they share an id, which v1.1.0
    could not distinguish: it talked to whichever copy macOS preferred,
    LAUNCHED that copy if it was not running, and then failed on the empty one
    with "Can't get document 1 ... Invalid index (-1719)". `ps` gives the real
    bundle path and pid of every running process, and the System Events menu
    click is keyed to that pid, so the menu clicked always belongs to the
    process being driven.


v1.2.1  (2026-09-13)  — current
    Documentation release; no change to the effect. Adds a HOW TO USE IT
    section — numbered steps from selecting the layer, through every dialog
    field and its units, to what the result group contains — and fills in a
    version history that had stopped one release short of the shipping build.
    The copy inside the bundle was refreshed with it, so the Read Me button
    shows the same text.

    This app keeps no copy of the README inside the bundle, so the text lives
    only in the project folder. build.sh, which restores the bundle identity
    on every rebuild, still wrote version 1.1.0 over a 1.2.0 build; it now
    carries the real version.


-----------------------------------------------------------------------------
 Copyright (c) 2026 Timothy McCoy. All rights reserved.

 Developed with the support of Claude (Anthropic).
=============================================================================
