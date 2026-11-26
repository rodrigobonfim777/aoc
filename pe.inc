; Estrutura do executavel Windows PE32 e tabela de bibliotecas.
; Esta parte substitui o linker. A logica do jogo fica em jogo.asm.
bits 32
org 0x400000
%define RVA(x) (x - $$)
%macro pcall 1-*
 %define %%api %1
 %rep %0-1
 %rotate -1
 push dword %1
 %endrep
 call [%%api]
%endmacro
dw 'MZ'
times 0x3c-($-$$) db 0
dd RVA(pe)
pe: db 'PE',0,0
dw 0x14c,1
dd 0,0,0
dw section_header-opt,0x103
opt: dw 0x10b
db 0,0
dd file_end-game_section,0,0,RVA(start),0x1000,0x1000
dd 0x400000,0x1000,0x200,5
dw 0,0,4,0
dd 0
dd ((RVA(file_end)+reserve_size+4095) & ~4095),0x1000,0
dw 2,0x100
dd 0x100000,0x1000,0x100000,0x1000,0,16
dd 0,0,RVA(imports),imports_end-imports
times 14 dq 0
section_header: db '.game',0,0,0
dd file_end-game_section+reserve_size,0x1000,file_end-game_section,0x1000,0,0
dw 0,0
dd 0xe0000060
times 4096-($-$$) db 0
game_section:
%macro library 2
dd RVA(%1_list),0,0,RVA(%1_name),RVA(%1_list)
%endmacro
imports:
library kernel,0
library user,0
library gdi,0
times 5 dd 0
imports_end:
kernel_name: db 'KERNEL32.dll',0
user_name: db 'USER32.dll',0
gdi_name: db 'GDI32.dll',0
align 4
kernel_list:
GetModuleHandleA: dd RVA(hint_GetModuleHandleA)
ExitProcess: dd RVA(hint_ExitProcess)
dd 0
align 2
hint_GetModuleHandleA: dw 0
db 'GetModuleHandleA',0
align 2
hint_ExitProcess: dw 0
db 'ExitProcess',0
align 4
user_list:
RegisterClassA: dd RVA(hint_RegisterClassA)
CreateWindowExA: dd RVA(hint_CreateWindowExA)
ShowWindow: dd RVA(hint_ShowWindow)
GetMessageA: dd RVA(hint_GetMessageA)
TranslateMessage: dd RVA(hint_TranslateMessage)
DispatchMessageA: dd RVA(hint_DispatchMessageA)
DefWindowProcA: dd RVA(hint_DefWindowProcA)
PostQuitMessage: dd RVA(hint_PostQuitMessage)
BeginPaint: dd RVA(hint_BeginPaint)
EndPaint: dd RVA(hint_EndPaint)
InvalidateRect: dd RVA(hint_InvalidateRect)
AdjustWindowRect: dd RVA(hint_AdjustWindowRect)
LoadCursorA: dd RVA(hint_LoadCursorA)
SetTimer: dd RVA(hint_SetTimer)
KillTimer: dd RVA(hint_KillTimer)
dd 0
align 2
hint_RegisterClassA: dw 0
db 'RegisterClassA',0
align 2
hint_CreateWindowExA: dw 0
db 'CreateWindowExA',0
align 2
hint_ShowWindow: dw 0
db 'ShowWindow',0
align 2
hint_GetMessageA: dw 0
db 'GetMessageA',0
align 2
hint_TranslateMessage: dw 0
db 'TranslateMessage',0
align 2
hint_DispatchMessageA: dw 0
db 'DispatchMessageA',0
align 2
hint_DefWindowProcA: dw 0
db 'DefWindowProcA',0
align 2
hint_PostQuitMessage: dw 0
db 'PostQuitMessage',0
align 2
hint_BeginPaint: dw 0
db 'BeginPaint',0
align 2
hint_EndPaint: dw 0
db 'EndPaint',0
align 2
hint_InvalidateRect: dw 0
db 'InvalidateRect',0
align 2
hint_AdjustWindowRect: dw 0
db 'AdjustWindowRect',0
align 2
hint_LoadCursorA: dw 0
db 'LoadCursorA',0
align 2
hint_SetTimer: dw 0
db 'SetTimer',0
align 2
hint_KillTimer: dw 0
db 'KillTimer',0
align 4
gdi_list:
SetDIBitsToDevice: dd RVA(hint_SetDIBitsToDevice)
TextOutA: dd RVA(hint_TextOutA)
SetBkMode: dd RVA(hint_SetBkMode)
SetTextColor: dd RVA(hint_SetTextColor)
GetStockObject: dd RVA(hint_GetStockObject)
SelectObject: dd RVA(hint_SelectObject)
dd 0
align 2
hint_SetDIBitsToDevice: dw 0
db 'SetDIBitsToDevice',0
align 2
hint_TextOutA: dw 0
db 'TextOutA',0
align 2
hint_SetBkMode: dw 0
db 'SetBkMode',0
align 2
hint_SetTextColor: dw 0
db 'SetTextColor',0
align 2
hint_GetStockObject: dw 0
db 'GetStockObject',0
align 2
hint_SelectObject: dw 0
db 'SelectObject',0
