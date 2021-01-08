bits 32
	addsd xmm0, xmm0
	addsd xmm3, xmm0
	addsd xmm7, xmm0

	addsd xmm0, xmm1
	addsd xmm0, xmm3
	addsd xmm0, xmm7

	addsd xmm2, xmm2
	addsd xmm2, xmm3
	addsd xmm3, xmm2
	
	addsd xmm0, [eax]
	addsd xmm7, [eax]
	addsd xmm0, [ecx]
	addsd xmm0, [esi]
	addsd xmm0, [edi]
	addsd xmm0, [esp]
	addsd xmm0, [esp+8]

	addsd xmm0, [0x99887766]
	addsd xmm0, [0x77]
