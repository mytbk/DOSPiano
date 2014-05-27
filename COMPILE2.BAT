masm mydzq.asm;
tcc -c pianoui.c
tlink mydzq.obj pianoui.obj,mydzq,nul,c:\tc\lib\cs
