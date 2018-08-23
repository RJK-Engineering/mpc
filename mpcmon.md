# MPC Monitor - mpcmon.pl

## Snapshots

Filename format: `<filename>_snapshot_<position>_[<date>].<extension>`

- `<filename>` = Name of the file the snapshot was taken from
- `<position>` = Position at which the snapshot was taken, format: `mm.ss` or `hh.mm.ss`
- `<date>` = Date the snapshot was taken, format: `yyyy.mm.dd_hh.mm.ss`
- `<extension>` = Image file extension

## Segments

- Snapshot files sorted from old to new
- Default: first snapshot is segment start
  - Option: start @ 0:00, first snapshot is segment stop
- If last snapshot is not a segment stop
  - Default: ignore last snapshot
  - Option: segment stop is end of file

## Directories

- Look for snapshots and `<filename>` in current working directory
  - Option: look for snapshots in a specific directory
  - Option: look for `<filename>` in a specific directory

## To Do

- display clock time and bookmark time
- get open file special case: opened more then once
- remove emtpy dir after moves fail
- k: add title to bookmark snapshot filename

## Actions

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

## Keys

Maybe: keys 12345 - menu struct

Key     | Action | Reply
------- | ------ | -----
h ?     | Help
s       | Status
l       | List
r       | Reset
p       | Pause monitoring
q Esc   | Quit
**Mode**
a       | AutoCompleteMode
b       | BookmarkMode
O       | OpenMode
**Current snapshot**
c       | SetCategory
o       | Open
t       | Tag
u       | Undo
**Per category**
C       | CompleteCategory
**All**
d       | Delete
m       | Move

## Properties

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

## Lists

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
