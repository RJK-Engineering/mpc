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

1 monitor:
   1 enabled - execute enabled actions for new snapshots
   1 exit
   1 empty bin
   1 list bin
1 snapshot actions:
   1 get info from snapshot: filename, position, date
      option: snapshot dir
   1 get info from instances: path
   1 get info from webif (only one instance): ...
      option: url
   1 bookmark - store snapshot alongside file
   1 copy - copy snapshot to dirs
      option: dirs
   1 keep a copy (move to bin) when bookmark disabled and no copies were made
      option: bin dir
   1 store info - assign sequence number
      1 categorize - cycle through cats, store cat index number + cat
      option: store file
   1 copy to clipboard - filename/path/other property of media or snapshot file
      option: property (eg: media.name snapshot.path image.height)
selected, new :
   1 undo - remove info, delete snapshot
1 actions:
   1 move to category subdir
      all except named "delete"
      prompt for category name
   1 delete files in category
      named "delete"
      prompt for category name
   1 list bookmarks - sequence number
   1 delete a bookmark


file:media
file:snapshot
media.bookmark
   bookmark.position
   bookmark.date
   image:bookmark.snapshot
