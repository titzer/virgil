	addsd xmm1, xmm2
	subsd xmm1, xmm2
	mulsd xmm1, xmm2	
	divsd xmm1, xmm2
	sqrtsd xmm1, xmm2
 	cmpeqsd xmm1, xmm2

	addss xmm1, xmm2
	subss xmm1, xmm2
	mulss xmm1, xmm2	
	divss xmm1, xmm2
	sqrtss xmm1, xmm2
 	cmpeqss xmm1, xmm2

	ucomiss xmm1, xmm2
	ucomisd xmm1, xmm3
	
	cvtss2si eax, xmm1
	cvtsi2ss xmm1, eax
	cvtsd2si eax, xmm1
	cvtsi2sd xmm1, eax

	
