	.align	2
	.globl	main
	.set	nomips16
	.set	nomicromips
	.ent	main
	.type	main, @function
main:
	MOVE $0,$2
	MOVE $0,$3
	MOVE $0,$4
    ADDIU $3,$3,1
    LI $4,8
    ADDU $2,$3,$4
    JR $31
    .end main
    .set	noreorder
    .set	nomacro
