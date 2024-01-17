# What's in here

This directory contains the files to bundle
a cross-platform single file binary using [redbean](https://redbean.dev).

## Files and directory explanation

- **bin/redbean.com**: This file is the redbean binary that is
  downloaded from https://redbean.dev.

- **redbean-args**: This file contains the CLI args for redbean
  it will be placed inside the zip as .args

- **redbean-init.lua**: This file is the .init.lua for redbean.

- **types.lua**: This file contains some lua type annotations
  for the redbean API (mainly used vscode LSP).

- **include**: Add files in this directory to include
  in the redbean binary.

- **make.sh**: The bash script that does all the bundling.

## Building/bundling

1. First, make sure you can redbean.com

```
$ bin/redbean.com -h
```

If you should see the redbean help documentation (press q to exit), proceed to step 2.

On linux or WSL environments, you may see an error like

> Cannot open assembly './redbean.com': File does not contain a valid CIL image.

One possible fix is to run

```
$ sudo sh -c 'echo -1 > /proc/sys/fs/binfmt_misc/status'
```

For other workarounds, see the redbean installation notes at https://redbean.dev/#install

2. Run the following to bundle the executable

```bash
$ ./make.sh
```
