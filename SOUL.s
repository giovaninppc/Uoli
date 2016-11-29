@ Giovani Nascimento Pereira	168609
@ Renan Adriani Sterle			176526
@ MC404 Project - Uoli
@ Operational System - SOUL

@ System time clock divider constant
.set TIME_SZ,			0x000000C8

@ System constants
.set MAX_ALARMS,		0x00000008
.set MAX_CALLBACKS,		0x00000008
.set STACK_SIZE,		0x00000064
.set SUPERVISOR_MODE,	0x00000013
.set IRQ_MODE,			0x00000012
.set SYSTEM_MODE,		0x0000001F
.set GDIRMask,			0xFFFC003E


@ GPT registers addresses constants
.set GPT_CR,			0x53FA0000
.set GPT_PR,			0x53FA0004
.set GPT_SR,			0x53FA0008
.set GPT_IR,			0x53FA000C
.set GPT_OCR1,			0x53FA0010

@ TZIC registers addresses constants
.set TZIC_BASE,			0x0FFFC000
.set TZIC_INTCTRL,		0x00000000
.set TZIC_INTSEC1,		0x00000084
.set TZIC_ENSET1,		0x00000104
.set TZIC_PRIOMASK,		0x0000000C
.set TZIC_PRIORITY9,	0x00000424

@GPIO registers addresses constants
.set DR,				0x53F84000
.set GDIR,				0x53F84004
.set PSR,				0x53F84008

@iv Section>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

.org 0x0
.section .iv,"a"

_start:

InterruptVector:
	b RESET_HANDLER

@SYSCALL
.org 0x08
	b SYSCALL_HANDLER

.org 0x18
	b IRQ_HANDLER

@CODING SECTION>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

.org 0x100
.text

RESET_HANDLER:
	@ Sets interrupt table base address on coprocessor 15.
	ldr r0, =InterruptVector
	mcr p15, 0, r0, c12, c0, 0
	
	@ Initializes SystemTime counter to 0.
	ldr r2, =SystemTime
	mov r0,#0
	str r0,[r2]

@ Initializing stacks:
	@ Initializes supervisor mode stack
	ldr SP, =SupervisorStack
	
	@ Switches to IRQ mode
	cps #IRQ_MODE
	
	@ Initializes IRQ mode stack
	ldr SP, =IRQStack
	
	@ Switches to system mode
	cps #SYSTEM_MODE
	
	@ Initializes user mode stack
	ldr SP, =UserStack
	
	@ Switches back to supervisor mode
	cps #0xSUPERVISOR_MODE

@ Setting GPT
	@ Enable clock source
	ldr r2, =GPT_CR
	mov r0, #0x41
	str r0, [r2]

	@ Resetting prescaler
	ldr r2, =GPT_PR
	mov r0, #0
	str r0, [r2]

	@ Setting prescaler limit
	ldr r2, =GPT_OCR1
	mov r0, #TIME_SZ
	str r0, [r2]

	@ Enable interruptions
	ldr r2, =GPT_IR
	mov r0, #1
	str r0, [r2]

@ Setting GPIO
	@ Sets GPIO direction register
	ldr r0, =GDIRMask
	ldr r0, [r0]
	ldr r1, =GDIR
	str r0, [r1]
	
@ Setting TZIC
	@ Enable interruption controller
	ldr	r1, =TZIC_BASE

	@ Sets interruption #39 of GPT as non safe.
	mov	r0, #(1 << 7)
	str	r0, [r1, #TZIC_INTSEC1]

	@ Enables GPT interruption #39
	@ reg1 bit 7 (gpt)

	mov	r0, #(1 << 7)
	str	r0, [r1, #TZIC_ENSET1]

	@ Configures interrupt39 priority as 1
	@ reg9, byte 3

	ldr r0, [r1, #TZIC_PRIORITY9]
	bic r0, r0, #0xFF000000
	mov r2, #1
	orr r0, r0, r2, lsl #24
	str r0, [r1, #TZIC_PRIORITY9]

	@ Configure PRIOMASK as 0
	eor r0, r0, r0
	str r0, [r1, #TZIC_PRIOMASK]

	@ Enables interruption controller
	mov	r0, #1
	str	r0, [r1, #TZIC_INTCTRL]

	@ Enables interruptions
	msr  CPSR_c, #0x13	   @ SUPERVISOR mode, IRQ/FIQ enabled

@IR PARA CODIGO DO USUARIO!!!!!
Loop:
    b main
    b Loop

IRQ_HANDLER:
	@Secures context
    push {r0-r1}

	@ Signs that the interruption has been performed
	ldr r0, =GPT_SR
	mov r1, #1
	str r1, [r0]
	
	@ Increments system clock
	ldr r0, =SystemTime
	ldr r1, [r0]
	add r1, r1, #1
	str r1, [r0]
	
	@ Recovers context
	pop {r0-r1}
	sub lr, lr, #4
	movs pc, lr

@SYSCALL_HANDLER
@ r7 contains the syscall number
@ Parameters:
@	passed by the user stack
@16 - read_sonar
@17 - register_proximity_callback
@18 - set_motor_speed
@19 - set_motors_speed
@20 - get_time
@21 - set_time
@22 - set_alarm

SYSCALL_HANDLER:

	cmp r7, #16
	beq read_sonar

	cmp r7, #17
	beq register_proximity_callback
	
	cmp r7, #18
	beq set_motor_speed

	cmp r7, #19
	beq set_motors_speed

	cmp r7, #20
	beq get_time

	cmp r7, #21
	beq set_time

	cmp r7, #22
	beq  set_alarm

	@default treatment
	movs pc, lr


@---------------------------
set_motor_speed:
	push {r1-r3}			@PILHA DO TIO2
	cps #SYSTEM_MODE 		@Switch to System mode (same stack as user)
	pop {r1, r2}			@R1 <= P0; R2 <= P1;
	cps #SUPERVISOR_MODE	@Go back to supervisor mode

	eor r0, r0, r0			@ R0 <= 0
	cmp r2, #0x3F
	movhi r0, #-2			@ If |speed| is higher than 2^6-1, set R0 to -2
	cmp r1, #1
	movhi r0, #-1			@ If |id| is higher than 1, set R0 to -1
	
	cmp r0, #0				@ If R0 != 0, return.
	movsne pc, lr 			@Going back to users mode
	
	cmp r1, #1
	beq Second				@ If id == 1, jump to second motor section
	lsl r2, #18				@ Prepare speed for masking
	ldr r1, =DR				@ Load original DR
	ldr r3, [r1]			@ Mask it in order to update Motor0 range
	and r3, r3, #FE03FFFF
	orr r3, r3, r2
	str [r1], r3			@Update DR
	movs pc, lr 			@Going back to users mode
	
Second:
	lsl r2, #25				@ Prepare speed for masking
	ldr r1, =DR				@ Load original DR
	ldr r3, [r1]			@ Mask it in order to update Motor0 range
	and r3, r3, #1FFFFFF
	orr r3, r3, r2
	str [r1], r3			@Update DR
	
	pop {r1-r3}
	movs pc, lr 			@Going back to users mode

@---------------------------
set_time:
	push {r0-r1}			@Saving the users register state (Supervisor stack!)

	cps #SYSTEM_MODE 		@Switch to System mode (same stack as user)
	pop {r0}				@Pop the parameter value (System stack!)
	cps #SUPERVISOR_MODE	@Go back to supervisor mode

	ldr r1, =SystemTime		@Get the SystemTime address
	str r0, [r1]			@Setting the time

	pop {r0-r1}			@Poping the Users state
	movs pc, lr 			@Going back to users mode

@---------------------------
get_time:
	push {r1}
	
	ldr r1, =SystemTime		@Load the SystemTime address
	ldr r0, [r1]			@Load the SystemTime value on the return register
	
	pop {r1}
	movs pc, lr 			@Go back to User mode and users code

@Data Section>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

.data
	SystemTime:
	.word 0
	UserStack:
	.skip STACK_SIZE * 4
	SupervisorStack:
	.skip STACK_SIZE * 4
	IRQStack:
	.skip STACK_SIZE * 4
