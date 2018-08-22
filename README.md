# Media Player Classic Tools

MPC-HC homepage: https://mpc-hc.org

MPC-HC main repository: https://github.com/mpc-hc/mpc-hc

## MPC Settings - mpcset.pl

View and change Media Player Classic settings.

```
Usage: mpcset.pl [options] [setting] [value]
```

## Make MPC Playlist - mkmpcpl.pl

### Options

Options | Description
------- | -----------
-r | Recursively add subdirectories.
-s -shuffle | Shuffle.
-l -list [path] | Path to file list text file.

Options | Description
------- | -----------
-a -append | Append to existing playlist.
-t -target [path] | Path to target.
-f -filter [string] | List of extensions to include, regular expressions seperated by "\|".
-e -extend-filter [string] | List of extensions to include, regular expressions seperated by "\|". Appended to default list of extensions.
-E -reduce-filter [string] |
-g -regex-filter [string] | Regular expression for filenames to include.

Options | Description
------- | -----------
-m -min-size [string] | Minimum file size.
-x -max-size [string] | Maximum file size.
-gbs -group-by-size [string] | Group by size, optional maximum deviation in bytes.
-gbl -group-by-length [string] | Group by length, optional maximum deviation in seconds.
-v -verbose | Be verbose.
-q -quiet | Be quiet.
-debug | Display debug information.
-h -? -help | Help.

## MPC Monitor - mpcmon.pl

Snapshots
---------
Filename format: `<filename>_snapshot_<position>_[<date>].<extension>`

- `<filename>` = Name of the file the snapshot was taken from
- `<position>` = Position at which the snapshot was taken, format: `mm.ss` or `hh.mm.ss`
- `<date>` = Date the snapshot was taken, format: `yyyy.mm.dd_hh.mm.ss`
- `<extension>` = Image file extension

I want to group snapshots by `<filename>`

I want to create a segment list from a list of snapshot files

Segments
--------
- Snapshot files sorted from old to new
- Default: first snapshot is segment start
  - Option: start @ 0:00, first snapshot is segment stop
- If last snapshot is not a segment stop
  - Default: ignore last snapshot
  - Option: segment stop is end of file

Directories
-----------
- Look for snapshots and `<filename>` in current working directory
  - Option: look for snapshots in a specific directory
  - Option: look for `<filename>` in a specific directory

To Do
-----
- display clock time and bookmark time
- get open file special case: opened more then once
- remove emtpy dir after moves fail
- k: add title to bookmark snapshot filename

Keys
----

mpc-hc/src/mpc-hc/mpcresources/PO/mpc-hc.en_GB.menus.po

```
-k
   Display keys.
-k [name]
-k [nr]
   Display key combination.
-k [name]=[combination]
-k [nr]=[combination]
   Set key combination.


-k [name]=[combination] or -k [nr]=[combination]
   Display all keys if no arguments are defined, display key combination if no [combination] is defined, set key combination otherwise. Set default key combination if [combination] is equal to C<default>.
```

Menu
----

keys 12345 - menu struct

* Monitor (can be enabled/disabled)
  * Snaphots in dir (option: snapshot dir)
    * New snapshot
  * Web interface (option: webif url)
    * New file playing
    * Status change
    * Position change
  * Default.mpcpl, create history: cp when changed (option: mpc dir)
    * File change
* Actions
  * List
    * List files
    * List bookmarks
    * List segments
    * List files in bin
  * Show status
    * Show monitor status (monitors en/dis, cwd, category list, en/dis actions)
    * Show unprocessed snapshots in snapshot dir
    * Show mpc status using webif
    * Show running mpc instances
  * Change cwd
  * Process unprocessed snapshots
  * Take a snapshot using web interface
  * Empty bin
  * Display help
  * Exit
* New snapshot event actions (can be enabled/disabled)
  * Bookmark mode
    1. Get info from snapshot: filename, position, date
    1. Get info from default.mpcpl: path
    1. Get info from instances: path
    1. Get info from web interface (only one instance)
    1. Categorize - cycle through cats, store cat index number + cat (option: category list)
    1. Copy to clipboard - string with bookmark properties (see: [Properties](#properties)) (option: string)
    1. Move snapshot to bin (option: bin dir)
    1. Store info - assign sequence number (option: file path)
    1. Clear media file selection, set last bookmarked
  * Snapshot mode - store snapshot alongside media file
  * Open mode - open media file based on filename (see Filecheck)
* Select media file(s)
  * Last bookmarked
  * By list number
  * By path using regex
  * By category
  * All
  * None (clear selection)
* Media file actions
  * Move to category subdir - Default selection: all except category "delete"
    * Move, remove from list, execute command (option: command string)
  * Delete - Default selection: category "delete"
    * Delete, remove from list, execute command (option: command string)
  * List - Default selection: last file
    * List bookmarks
    * List segments
    * Remove from list, move snapshots to bin (*undo*)
    * Set category - input
    * Set category - cycle through cats, store cat index number + cat (option: cat list)
    * Add/remove tags - input
  * System - Default selection: last file
    * Execute command (option: command string)
    * Open file based on filename (see Filecheck)
    * Cut (option: output dir)
    * Join (cut required first, option: output dir)

### Properties

```
file.[file props]
file.audio.[audio props]
file.video.[video props]
file.bookmarks[]
bookmark.file = file
bookmark.position
bookmark.date
bookmark.snapshot.[file props]
bookmark.snapshot.[image props]

file: name, dir, path, parent, size, created, modified, accessed
audio: codec, bitrate, duration, ...
video: codec, bitrate, duration, ...
image: width, height, ...
```

### Lists

```
files
# file
1 file1.avi
2 file2.avi
3 file3.avi

bookmarks
# file      position
1 file1.avi 1:00
2 file1.avi 2:00
3 file2.avi 1:00
4 file2.avi 3:00
5 file3.avi 1:00

segments
# file      start duration
1 file1.avi 1:00  1:00
2 file2.avi 1:00  2:00
3 file3.avi 1:00

```

## Settings

```
[Settings\PnSPresets]
Preset0=Scale to 16:9 TV,0.500,0.500,1.000,1.333
Preset1=Zoom To Widescreen,0.500,0.500,1.333,1.333
Preset2=Zoom To Ultra-Widescreen,0.500,0.500,1.763,1.763
Preset3=Fullscreen Seek Bar + Status,0.500,0.486,0.942,0.942
Preset4=1080 top left,0.625,0.625,1.400,1.400
Preset5=1080 top center,0.5,0.625,1.400,1.400
Preset6=1080 top right,0.375,0.625,1.400,1.400
Preset7=1080 bottom left,0.625,0.375,1.400,1.400
Preset8=1080 bottom center,0.5,0.375,1.400,1.400
Preset9=1080 bottom right,0.375,0.375,1.400,1.400
```
