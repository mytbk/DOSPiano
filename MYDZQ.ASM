;;; Record:C-R, Play:C-P, Save:C-S, Load:C-L
        
RECKEY equ 12h
SAVEKEY equ 13h
PLAYKEY equ 10h
LOADKEY equ 0ch

        
data segment
;;; data1: sine wave
        data1 db 80h,96h,0aeh,0c5h,0d8h,0e9h,0f5h,0fdh
              db 0ffh,0fdh,0f5h,0e9h,0d8h,0c5h,0aeh,96h
              db 80h,66h,4eh,38h,25h,15h,09h,04h
	      db 00h,04h,09h,15h,25h,38h,4eh,66h
;;; time: 8253 initial value
        time db 120,106,94,89,79,70,63,59
        
        msg db 'Press 1,2,3,4,5,6,7,8,ESC:',0dh,0ah,'$'
        keys db 'qwertyuasdfghjzxcvbnm'
        initval db ?
        note dw 0
        raisetune dw ?
        recording db 0
;;; a big buffer for recording
        datasize dw 0
        buffer db 200h dup(?)
;;; The Graphical Interface
        pianoui db 'aaabbbbcddddeeefffgggghiiiijkkkklll', 0
                db 'aaabbbbcddddeeefffgggghiiiijkkkklll', 0
                db 'aaabbbbcddddeeefffgggghiiiijkkkklll', 0
                db 'aaabbbbcddddeeefffgggghiiiijkkkklll', 0
                db 'aaabbbbcddddeeefffgggghiiiijkkkklll', 0
                db 'aaabbbbcddddeeefffgggghiiiijkkkklll', 0
                db 'aaaaaccccceeeeefffffhhhhhjjjjjlllll', 0
                db 'aaaaaccccceeeeefffffhhhhhjjjjjlllll', 0
                db 'aaaaaccccceeeeefffffhhhhhjjjjjlllll', 0
                db 'aaaaaccccceeeeefffffhhhhhjjjjjlllll', 0
        db 0ffh
        colors db 01111111b, 00001000b, 01111111b, 00001000b, 01111111b, 01111111b
                db 00001000b, 01111111b, 00001000b, 01111111b, 00001000b, 01111111b
        showcode db 0
        
data ends

stack segment stack
mysp db 100h dup (?)
sttop equ $-mysp
stack ends

code segment
        assume cs:code,ds:data
        extrn _transkey: near
        extrn _get_showcode: near
start:  mov ax,data
	mov ds,ax
        mov es,ax
        mov ax, stack
        mov ss, ax
        mov sp, sttop
        call graphic_init
        mov dx, 0510h
        call showui

sss:    mov ah,0
	int 16h              ; getkey

	cmp al, 1bh
        jne TREC             ; ESC=>exit
        mov ax, 4c00h
        int 21h
        ;; program ends
TREC:
        cmp al, RECKEY
        jne TSAVE
        mov recording, 1
        jmp sss
TSAVE:
        cmp al, SAVEKEY
        jne TPLAY
        mov recording, 0
        call savetofile
        jmp sss
TPLAY:
        cmp al, PLAYKEY
        jne TSPACE
        call playaudio
        jmp sss
TSPACE:
        cmp al, ' '
        jne OTHERKEY
        cmp recording, 1
        jne sss                 ; ignore it
        mov bx, datasize
        mov buffer[bx], 0
        inc datasize
        jmp sss
OTHERKEY:
        mov raisetune, 0
        cmp al, 'A'
        jl sss
        cmp al, 'Z'
        jg lowerletter
        mov raisetune, 1
        or al, 00100000b
                
lowerletter:    
        mov di, offset keys
        mov cx, 21
        repnz scasb
        jnz sss                 ; invalid key
        sub di, offset keys
        dec di               ; index = di-keys-1
        push di
        call _transkey
        add sp, 2
        cmp ax, -1
        jz sss

        cmp ax, 16  ;; ax>=16 => high tune
        jl mediumlow
        and al, 00000111b
        mov note, al
        mov bx, offset time
        xlat
        shr al, 1
        jmp tune
mediumlow:
        cmp ax, 8  ;; ax>=8 => medium tune
        jl lowt
        and al, 00000111b
        mov note, al
        mov bx, offset time
        xlat
        jmp tune
lowt:
        and al, 00000111b
        mov note, al
        mov bx, offset time
        xlat
        shl al, 1
tune:
        cmp raisetune, 1
        jne process
        cbw
        push ax
        call raisehalf

process:
        mov initval, al
        ;; show ui
        push raisetune
        push note
        call _get_showcode
        mov showcode, al
        mov dx, 0510h
        call showui
        ;; record
        cmp recording, 1
        jne norec
        mov al, initval
        mov bx, datasize
        mov buffer[bx], al
        inc datasize
norec:
        
        mov cx,60             ;取60次32个正弦波数据
ddd:	mov si,0
lll:	mov al,data1[si]     ;取正弦波数据
        mov dx,0e490h
	out dx,al            ;放音
	call delay           ;调延时子程序
	inc si
	cmp si,32            ;是否取完32个数据
	jl lll               ;若没有,则继续
	loop ddd             ;总循环次数60是否完,没有,则继续
	jmp sss
        
exit:
        mov ah,4ch
	int 21h
delay proc near              ;延时子程序
ccc:    ;mov bx,offset time
        mov dx,0e483h        ;置8253通道0为方式0工作
	mov al,10h
	out dx,al
        mov dx,0e48bh         ;设8255A口输入
	mov al,90h            ; a in, method 0
	out dx,al
	mov al,initval
        mov dx,0e480h
	out dx,al            ; output the initial value to 8253
kkk:    mov dx,0e488h
	in  al,dx            ;从8255A口读一字节
	test al,01           ;判PA0口是否为1
	jz  kkk              ;若不为1,则转KKK
	ret                  ;子程序返回
delay  endp

raisehalf proc near
;; al: initial value
;; output the new initial value to ax
;; 2^(1/12) = 1.0594631
;; first mul 10000, then div 10595
        push dx
        push cx
        cbw
        mov cx, 10000
        mul cx
        mov cx, 10595
        div cx
        pop cx
        pop dx
        ret
raisehalf endp

graphic_init proc near
        xor ah, ah
        mov al, 3
        int 10h
        mov ah, 6
        xor al, al
        mov bh, 00100000b
        mov ch, 0
        mov cl, 0
        mov dh, 24
        mov dl, 79
        int 10h
        ret
graphic_init endp
        
showui proc near
;;; show code stored in mem
;;; dh, dl: line, column

;;; initialize cursor
        push ax
        push bx
        push cx
        push si

        mov si, offset pianoui
        mov cx, 1
        push dx
show_loop:
        cmp byte ptr [si], 0ffh
        jz show_end
        cmp byte ptr [si], 0
        jnz show_cont
        pop dx
        inc dh
        push dx
        inc si
        jmp show_loop
show_cont:
        ;; set cursor
        xor bx, bx
        mov ah, 2
        int 10h

        mov al, [si]
        cmp byte ptr showcode, al
        jz set_color
        sub al, 'a'
        mov bx, offset colors
        xlat
        mov bl, al
        jmp show_sp
set_color:
        mov bl, 00011000b
show_sp:
        mov ah, 9
        mov al, ' '
        xor bh, bh
        int 10h

        inc dl
        inc si
        jmp show_loop
show_end:
        pop dx
        pop si
        pop cx
        pop bx
        pop ax
        ret
showui endp
        
playaudio proc near
        ret
playaudio endp
        
savetofile proc near
        ret
savetofile endp
        
code   ends
        end  start

