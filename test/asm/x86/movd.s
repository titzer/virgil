bits 32
mov dword eax, [eax + eax * 1] ; mov(eax, bs(eax, eax, 1, 0x00))
mov dword eax, [eax + eax * 2] ; mov(eax, bs(eax, eax, 2, 0x00))
mov dword eax, [eax + eax * 4] ; mov(eax, bs(eax, eax, 4, 0x00))
mov dword eax, [eax + eax * 8] ; mov(eax, bs(eax, eax, 8, 0x00))

mov dword ebx, [eax + ecx * 1] ; mov(ebx, bs(eax, ecx, 1, 0x00))
mov dword ebx, [eax + ecx * 2] ; mov(ebx, bs(eax, ecx, 2, 0x00))
mov dword ebx, [eax + ecx * 4] ; mov(ebx, bs(eax, ecx, 4, 0x00))
mov dword ebx, [eax + ecx * 8] ; mov(ebx, bs(eax, ecx, 8, 0x00))

mov dword edx, [edx + ecx * 1] ; mov(edx, bs(edx, ecx, 1, 0x00))
mov dword edx, [edx + ecx * 2] ; mov(edx, bs(edx, ecx, 2, 0x00))
mov dword edx, [edx + ecx * 4] ; mov(edx, bs(edx, ecx, 4, 0x00))
mov dword edx, [edx + ecx * 8] ; mov(edx, bs(edx, ecx, 8, 0x00))

mov dword edi, [ebp + esi * 1] ; mov(edi, bs(ebp, esi, 1, 0x00))
mov dword edi, [ebp + esi * 2] ; mov(edi, bs(ebp, esi, 2, 0x00))
mov dword edi, [ebp + esi * 4] ; mov(edi, bs(ebp, esi, 4, 0x00))
mov dword edi, [ebp + esi * 8] ; mov(edi, bs(ebp, esi, 8, 0x00))

mov dword esi, [esp + edx * 1] ; mov(esi, bs(esp, edx, 1, 0x00))
mov dword esi, [esp + edx * 2] ; mov(esi, bs(esp, edx, 2, 0x00))
mov dword esi, [esp + edx * 4] ; mov(esi, bs(esp, edx, 4, 0x00))
mov dword esi, [esp + edx * 8] ; mov(esi, bs(esp, edx, 8, 0x00))

mov dword edx, [edx + ecx * 1 + 0x42] ; mov(edx, bs(edx, ecx, 1, 0x42))
mov dword edx, [edx + ecx * 2 + 0x43] ; mov(edx, bs(edx, ecx, 2, 0x43))
mov dword edx, [edx + ecx * 4 + 0x44] ; mov(edx, bs(edx, ecx, 4, 0x44))
mov dword edx, [edx + ecx * 8 + 0x45] ; mov(edx, bs(edx, ecx, 8, 0x45))

mov dword edx, [edx + ecx * 1 + 0x99887742] ; mov(edx, bs(edx, ecx, 1, 0x99887742))
mov dword edx, [edx + ecx * 2 + 0x98877643] ; mov(edx, bs(edx, ecx, 2, 0x98877643))
mov dword edx, [edx + ecx * 4 + 0x97867544] ; mov(edx, bs(edx, ecx, 4, 0x97867544))
mov dword edx, [edx + ecx * 8 + 0x96857445] ; mov(edx, bs(edx, ecx, 8, 0x96857445))

mov dword edi, [ebp + esi * 1 + 0x11223344] ; mov(edi, bs(ebp, esi, 1, 0x11223344))
mov dword edi, [ebp + esi * 2 + 0x11223344] ; mov(edi, bs(ebp, esi, 2, 0x11223344))
mov dword edi, [ebp + esi * 4 + 0x11223344] ; mov(edi, bs(ebp, esi, 4, 0x11223344))
mov dword edi, [ebp + esi * 8 + 0x11223344] ; mov(edi, bs(ebp, esi, 8, 0x11223344))



