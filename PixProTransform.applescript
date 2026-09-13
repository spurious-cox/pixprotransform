-- PixProTransform — v1.3.0
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

property scriptVersion : "1.3.0"

-- ============================================================
-- UPDATE CHECK (reports only, never downloads)
-- ============================================================
-- Asks GitHub for the newest published tag and adds a line to the prompt when
-- this build is behind. It never downloads or replaces anything: a running
-- bundle cannot safely overwrite its own files, and getting that wrong costs
-- the app.
--
-- Checked once a day at most and capped at three seconds, so a slow or absent
-- network barely shows. The tag and the day it was fetched are kept in the
-- same defaults file as the settings.
--
-- The JSON is picked apart with grep and cut rather than a parser: a stranger's
-- Mac is not guaranteed to have python3, and the tag is the only field wanted.
property kSlug : "pixprotransform"
property kDefaults : "$HOME/.pixprotransform_defaults"

on versionParts(v)
	set out to {}
	set AppleScript's text item delimiters to "."
	set pieces to text items of v
	set AppleScript's text item delimiters to ""
	repeat with piece in pieces
		set digits to ""
		repeat with c in (characters of (piece as text))
			if c is in "0123456789" then set digits to digits & c
		end repeat
		if digits is "" then set digits to "0"
		set end of out to digits as integer
	end repeat
	return out
end versionParts

on isNewer(tag, mine)
	-- Compared as integers, so 3.10.0 comes out above 3.9.0 rather than below.
	set a to my versionParts(tag)
	set b to my versionParts(mine)
	repeat with i from 1 to 3
		set x to 0
		set y to 0
		if i ≤ (count a) then set x to item i of a
		if i ≤ (count b) then set y to item i of b
		if x > y then return true
		if x < y then return false
	end repeat
	return false
end isNewer

on latestTag()
	set today to do shell script "/bin/date +%Y-%m-%d"
	set lastDay to ""
	try
		set lastDay to do shell script "defaults read " & kDefaults & " updateCheckedOn 2>/dev/null"
	end try
	if lastDay is today then
		try
			return do shell script "defaults read " & kDefaults & " updateLatestTag 2>/dev/null"
		end try
		return ""
	end if
	try
		set tag to do shell script "/usr/bin/curl -sL --max-time 3 -H \"Accept: application/vnd.github+json\" https://api.github.com/repos/spurious-cox/" & kSlug & "/releases/latest | /usr/bin/grep -o '\"tag_name\": *\"[^\"]*\"' | /usr/bin/head -1 | /usr/bin/cut -d'\"' -f4"
		do shell script "defaults write " & kDefaults & " updateLatestTag " & quoted form of tag
		do shell script "defaults write " & kDefaults & " updateCheckedOn " & quoted form of today
		return tag
	on error
		return ""
	end try
end latestTag

on updateNotice(mine)
	set tag to my latestTag()
	if tag is "" then return ""
	if not (my isNewer(tag, mine)) then return ""
	set t to tag
	if t starts with "v" then set t to text 2 thru -1 of t
	return return & return & "Update available: " & t & "  —  brew upgrade --cask " & kSlug
end updateNotice



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

	-- This app has no dialog of its own to carry a notice, so a newer release
	-- is reported as a notification — and only when there IS one. Nothing is
	-- shown, and nothing is delayed beyond the three-second cap, otherwise.
	set notice to my updateNotice(scriptVersion)
	if notice is not "" then
		display notification "Update available — brew upgrade --cask " & kSlug ¬
			with title "PixProTransform " & scriptVersion
	end if
end run
