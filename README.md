# Just Play MineSweeper
* `git clone https://github.com/NethanWin/assembly-minesweeper.git`
* `sudo apt install dosbox`
* Open dosbox and run:
```
mount c /<path-to-git>/assembly-code/
MINE2.EXE
```

if there are problems with the mouse enter ~/.dosbox/dosbox-0.74-3.conf
and add/change:
`autolock=false`


# Compile Yourself
* `git clone https://github.com/NethanWin/assembly-minesweeper.git`
* `cd assembly-minesweeper`
* `git clone 'https://github.com/slyg3nius/CS-TASM-x86.git'`
* open DosBox once
* `cp assembly-code/* CS-TASK-x86/`
* Add the folowing lines to the file `~/.dosbox/dosbox-0.74-3.conf`:
```bash
echo EOF
@ECHO OFF
MOUNT C $PWD/CS-TASM-x86/
c:
UTILS\init.BAT
EOF >> ~/.dosbox/dosbox-0.74-3.conf
```

* Open DosBox and Compile the assembly code:
```
``
tasm /zi mine2.asm
tlink /v MINE2.OBJ
``
```
* and just run `MINE2.EXE` to start :)
