	.align	2
	.globl	main
	.set	nomips16
	.set	nomicromips
	.ent	main
	.type	main, @function

main:
	MOVE $2, $0
	LI $3, 0xFFFFFFFF
	MOVE $4, $31
	BLTZAL $3, main + 28
	nop
	ADDU $2,$2,5
	ADDU $2,$2,3
	MOVE $31, $4
	JR $31
	.end main
    .set	noreorder
    .set	nomacro