# Make MPC Playlist - mkmpcpl.pl

## Options

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
