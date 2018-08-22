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

1. Monitor (can be enabled/disabled)
   1. Snaphots in dir (option: snapshot dir)
   1. Webif (option: webif url)
   1. Default.mpcpl, create history: cp when changed (option: mpc dir)
1. Actions
   1. Process new snapshots since last monitoring
   1. List files
   1. List bookmarks
   1. List segments
   1. List files in bin
   1. Show mpc status using webif
   1. Show running mpc instances
   1. Show monitor status
   1. Show unprocessed snapshots in snapshot dir
   1. Take a snapshot using webif
   1. Empty bin
   1. Display help
   1. Exit
1. New snapshot event:
   1. Bookmark mode
      1. Get info from snapshot: filename, position, date
      1. Get info from default.mpcpl: path
      1. Get info from instances: path
      1. Get info from webif (only one instance)
      1. Move snapshot to bin (option: bin dir)
      1. Categorize - cycle through cats, store cat index number + cat (option: category list)
      1. Copy to clipboard - string with bookmark properties (see: [Properties](#properties)) (option: string)
      1. Store info - assign sequence number (option: file path)
   1. Snapshot mode - store snapshot alongside file
   1. Open mode - open file based on filename (see Filecheck)
1. File selection
   1. By list number
   1. By path using regex
   1. By category
   1. All
1. File actions
   1. Default selection: all except category "delete"
      1. Move to category subdir, remove from list, execute command (option: command string)
   1. Default selection: category "delete"
      1. Delete files in category, remove from list
   1. Default selection: last file
      1. Remove from list (*undo*)
      1. Set category
      1. Execute command (option: command string)
      1. Open file based on filename (see Filecheck)
      1. Tag
      1. Cut (option: output dir)
      1. Join (cut required first, option: output dir)

### Properties

```
file.[file props]
file.bookmarks[]
bookmark.file = file
bookmark.position
bookmark.date
bookmark.snapshot.[file props]
bookmark.image.[image props]

file: name, dir, path, parent, size, created, modified, accessed
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
