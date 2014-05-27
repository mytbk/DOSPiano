RECKEY equ 12h
SAVEKEY equ 13h
        
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
        raisetune db ?
        recording db 0
;;; a big buffer for recording
        datasize dw 0
        buffer db 200h dup(?)

data ends

stack segment stack
mysp db 100h dup (?)
sttop equ $-mysp
stack ends

code segment
        assume cs:code,ds:data
        extrn _raisehalf: near
        extrn _transkey: near
start:  mov ax,data
	mov ds,ax
        mov es,ax
        mov ax, stack
        mov ss, ax
        mov sp, sttop

sss:    mov ah,7
	int 21h              ;从键盘接收字符,不回显

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
        jne TSPACE
        mov recording, 0
        call savetofile
        jmp sss
TSPACE:
        cmp al, ' '
        jne ttt
        cmp recording, 1
        jne sss                 ; ignore it
        mov bx, datasize
        mov buffer[bx], 0
        inc datasize
        jmp sss
ttt:
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
        jnz sss
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
        mov bx, offset time
        xlat
        shr al, 1
        jmp tune
mediumlow:
        cmp ax, 8  ;; ax>=8 => medium tune
        jl lowt
        and al, 00000111b
        mov bx, offset time
        xlat
        jmp tune
lowt:
        and al, 00000111b
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

savetofile proc near
        ret
savetofile endp
        
code   ends
        end  start

