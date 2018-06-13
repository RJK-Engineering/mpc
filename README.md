# Media Player Classic Tools

MPC-HC homepage: https://mpc-hc.org

MPC-HC main repository: https://github.com/mpc-hc/mpc-hc

# tweak.pl

View and change Media Player Classic settings.

```
Usage: tweak.pl [options] [setting] [value]
```

# mkmpcpl.pl

# Options

Options | Description
------- | -----------
-r | Recursively add subdirectories.
-s -shuffle | Shuffle.
-a -append | Append to existing playlist.
-l -list [path] | Path to Total Commander file list.
-t -target [path] | Path to target.
-e -extensions [string] | List of extensions to include, regular expressions seperated by "|".
-i -incl-extensions [string] | List of extensions to include, regular expressions seperated by "|". Appended to default list of extensions.
-f -filter [string] | Regular expression for filenames to include.
-g -glob [string] | Glob for filenames to include.
-m -min-size [string] | Minimum file size.
-x -max-size [string] | Maximum file size.
-gbs -group-by-size [string] | Group by size, optional maximum deviation in bytes.
-gbl -group-by-length [string] | Group by length, optional maximum deviation in seconds.
-v -verbose | Be verbose.
-q -quiet | Be quiet.
-debug | Display debug information.
-h -? -help | Help.
