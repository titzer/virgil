bits 32
	movss xmm0, [eax]
	movss xmm1, [eax]
	movss xmm2, [eax]
	movss xmm7, [eax]
	
	movss xmm0, [ebx]
	movss xmm0, [ecx]
	movss xmm0, [edx]
	movss xmm0, [esi]
	
	movss [eax], xmm0
	movss [eax], xmm1
	movss [eax], xmm2
	movss [eax], xmm7
	
	movss [ebx], xmm0
	movss [ecx], xmm0
	movss [edx], xmm0
	movss [esi], xmm0
	
	movsd xmm0, [eax]
	movsd xmm1, [eax]
	movsd xmm2, [eax]
	movsd xmm7, [eax]
	
	movsd xmm0, [ebx]
	movsd xmm0, [ecx]
	movsd xmm0, [edx]
	movsd xmm0, [esi]
	
	movsd [eax], xmm0
	movsd [eax], xmm1
	movsd [eax], xmm2
	movsd [eax], xmm7
	
	movsd [ebx], xmm0
	movsd [ecx], xmm0
	movsd [edx], xmm0
	movsd [esi], xmm0
