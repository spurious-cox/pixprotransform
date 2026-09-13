-- PixProTransform — v1.2.1
--
-- Opens Pixelmator Pro's Perspective Transform in one step, instead of
-- Format > Effects > Other > Perspective Transform.
--
-- Pixelmator Pro has no AppleScript command for this effect, so the only way
-- in is to click the menu item. That means the app needs Accessibility access
-- (System Settings > Privacy & Security > Accessibility) or the click fails.
--
-- WHICH PIXELMATOR?  (v1.2.0, 2026-08-15)
--
-- Resolved at run time by PROCESS, not by bundle identifier. Two builds exist
-- since the Creator Studio rebrand:
--
--     com.apple.pixelmator             Pixelmator Pro Creator Studio (4.x)
--     com.pixelmatorteam.pixelmator.x  Pixelmator Pro (3.x)
--
-- but several COPIES of one build can also be installed, and copies share a
-- bundle id. v1.1.0 addressed the app by id, which cannot distinguish two such
-- processes: it talked to whichever copy macOS preferred, LAUNCHED that copy
-- if it was not already running, and then failed on the empty one with
-- "Can't get document 1 ... Invalid index (-1719)".
--
-- ps knows the real bundle path and pid of every running process, which is the
-- one thing that tells identical copies apart. Everything below is keyed to
-- that pid, including the System Events menu click, so the menu clicked always
-- belongs to the process being driven. Nothing depends on where the app is
-- installed or what it is called, so this works on any Mac.

property kBundleIDs : {"com.apple.pixelmator", "com.pixelmatorteam.pixelmator.x"}

-- Returns {bundle path, pid} of the Pixelmator to drive, or missing value.
on runningPixelmator()
	set rawPaths to {}
	try
		set psOut to do shell script "/bin/ps -Axo pid=,args= | /usr/bin/grep '/Contents/MacOS/Pixelmator' | /usr/bin/grep -v grep"
		-- `do shell script` separates lines with RETURN, not linefeed.
		set AppleScript's text item delimiters to return
		set rawPaths to text items of psOut
		set AppleScript's text item delimiters to ""
	end try
	if rawPaths is {} then return missing value

	set candidates to {}
	repeat with aLine in rawPaths
		set theLine to aLine as text
		if theLine is not "" then
			try
				set thePID to word 1 of theLine
				set appPath to do shell script "/bin/echo " & quoted form of theLine & ¬
					" | /usr/bin/sed 's|^ *[0-9]* *||; s|/Contents/MacOS/.*||'"
				set theID to do shell script "/usr/bin/defaults read " & ¬
					quoted form of (appPath & "/Contents/Info") & " CFBundleIdentifier"
				if theID is in kBundleIDs then set end of candidates to {appPath, thePID}
			end try
		end if
	end repeat
	if candidates is {} then return missing value

	-- Frontmost wins, so the effect opens in the window on screen.
	try
		tell application "System Events"
			set fpid to (unix id of (first application process whose frontmost is true)) as text
		end tell
		repeat with c in candidates
			if item 2 of c is fpid then return c
		end repeat
	end try
	return item 1 of candidates
end runningPixelmator

on run
	set target to runningPixelmator()

	if target is missing value then
		display alert "Pixelmator Pro is not running." message ¬
			"Open Pixelmator Pro and the image you want to transform, then run PixProTransform again." as warning
		return
	end if

	set appPath to item 1 of target
	set appPID to item 2 of target

	tell application appPath to activate
	delay 0.4

	try
		tell application "System Events"
			-- Keyed to the pid, so the menu belongs to the very process
			-- activated above even when two copies are running.
			tell (first application process whose unix id is (appPID as integer))
				click menu item "Perspective Transform" of menu "Other" of ¬
					menu item "Other" of menu "Effects" of menu item "Effects" of ¬
					menu "Format" of menu bar 1
			end tell
		end tell
	on error errorMessage
		-- The usual cause is no open document, which greys the whole Effects
		-- menu out; the second is Accessibility access not being granted.
		display alert "Could not open Perspective Transform." message ¬
			"Check that an image is open in Pixelmator Pro, and that PixProTransform is enabled in System Settings > Privacy & Security > Accessibility." & ¬
			return & return & errorMessage as warning
	end try
end run
