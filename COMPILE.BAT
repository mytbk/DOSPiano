masm mydzq.asm;
tcc -c pianoui.c
tlink mydzq.obj pianoui.obj,mydzq,nul,c:\turboc2\lib\cs
