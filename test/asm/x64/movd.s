bits 64
mov dword eax, [eax + eax * 1] 
mov dword eax, [eax + eax * 2] 
mov dword eax, [eax + eax * 4] 
mov dword eax, [eax + eax * 8] 

mov dword ebx, [eax + ecx * 1] 
mov dword ebx, [eax + ecx * 2] 
mov dword ebx, [eax + ecx * 4] 
mov dword ebx, [eax + ecx * 8] 

mov dword edx, [edx + ecx * 1] 
mov dword edx, [edx + ecx * 2] 
mov dword edx, [edx + ecx * 4] 
mov dword edx, [edx + ecx * 8] 

mov dword edi, [ebp + esi * 1] 
mov dword edi, [ebp + esi * 2] 
mov dword edi, [ebp + esi * 4] 
mov dword edi, [ebp + esi * 8] 

mov dword esi, [esp + edx * 1] 
mov dword esi, [esp + edx * 2] 
mov dword esi, [esp + edx * 4] 
mov dword esi, [esp + edx * 8] 

mov dword edx, [edx + ecx * 1 + 0x42] 
mov dword edx, [edx + ecx * 2 + 0x43] 
mov dword edx, [edx + ecx * 4 + 0x44] 
mov dword edx, [edx + ecx * 8 + 0x45] 

mov dword edx, [edx + ecx * 1 + 0x99887742] 
mov dword edx, [edx + ecx * 2 + 0x98877643] 
mov dword edx, [edx + ecx * 4 + 0x97867544] 
mov dword edx, [edx + ecx * 8 + 0x96857445] 

mov dword edi, [ebp + esi * 1 + 0x11223344] 
mov dword edi, [ebp + esi * 2 + 0x11223344] 
mov dword edi, [ebp + esi * 4 + 0x11223344] 
mov dword edi, [ebp + esi * 8 + 0x11223344] 



;;;  REX prefix
mov dword r8d, [eax + eax * 1] 
mov dword r9d, [eax + eax * 2] 
mov dword r10d, [eax + eax * 4] 
mov dword r11d, [eax + eax * 8] 

mov dword eax, [r8 + rax * 1] 
mov dword eax, [r9 + rax * 2] 
mov dword eax, [r10 + rax * 4] 
mov dword eax, [r11 + rax * 8] 

mov dword eax, [r8d + eax * 1] 
mov dword eax, [r9d + eax * 2] 
mov dword eax, [r10d + eax * 4] 
mov dword eax, [r11d + eax * 8] 

mov dword eax, [eax + r8d * 1] 
mov dword eax, [eax + r9d * 2] 
mov dword eax, [eax + r10d * 4] 
mov dword eax, [eax + r11d * 8] 

