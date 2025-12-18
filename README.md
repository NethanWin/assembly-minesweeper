# to run
1. sudo apt install dosbox
2. enter dosbox and run
```
mount c /path/to/MINE2.EXE
MINE2.EXE
```

if there are problems with the mouse enter ~/.dosbox/dosbox-0.74-3.conf
and add/change:
`autolock=false`


# compile yourself:
1. git clone 'https://github.com/slyg3nius/CS-TASM-x86.git'
2. edit ~/.dosbox/dosbox-0.74-3.conf
```
@ECHO OFF
MOUNT C ~/CS-TASM-x86/
c:
UTILS\init.BAT
```
3. then run the folowing lines:
```
tasm /zi mine2.asm
tlink /v MINE2.OBJ
```
4. just run `MINE2.EXE` to start :)


