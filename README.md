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
- monitor default.mpcpl, create history: cp when changed
- remove emtpy dir after moves fail
- k: add title to bookmark snapshot filename

get opened file special case: opened more then once
bookmark from msm using webif
- no image available
- take snapshot from msm?

display clock time and bookmark time

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

1. monitor
   1. switch - bookmark upon snapshot/pause monitoring
   1. list files
   1. list bookmarks
   1. list segments
   1. exit
1. bin
   1. list bin
   1. empty bin
1. bookmark upon snapshot actions:
   1. get info from snapshot: filename, position, date (option: snapshot dir)
   1. get info from instances: path
   1. get info from webif (only one instance): ... (option: webif url)
   1. save - store snapshot alongside file
   1. keep a copy (move to bin) when snapshot save disabled (option: bin dir)
   1. categorize - cycle through cats, store cat index number + cat (option: category list)
   1. copy to clipboard - string with properties (see [Properties](#properties)) (option: string)
   1. store info - assign sequence number (option: file path)
1. file selection
   1. by list number
   1. by category
   1. all
1. actions
   1. move to category subdir, remove from list
      default: all except category "delete"
   1. delete files in category, remove from list
      default: category "delete"
   1. remove a file
      default: last file
   1. process new snapshots since last monitoring

### Properties

file.[file props]
file.bookmarks[]
bookmark.file = media.file
bookmark.position
bookmark.date
bookmark.snapshot.[file props]
bookmark.image.[image props]

file: name, dir, path, parent, size, created, modified, accessed
image: width, height, ...

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
