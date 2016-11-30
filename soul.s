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
.set USER_MODE,			0x00000010
.set GDIRMask,			0xFFFC003E
.set ENTRY_POINT, 		0x77802000

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

InterruptVector:
	b RESET_HANDLER

.org 0x08
	b SYSCALL_HANDLER

.org 0x18
	b IRQ_HANDLER

@CODING SECTION>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

.org 0x100
.text

RESET_HANDLER:
	msr CPSR_c, #0xD3			@ SUPERVISOR mode, IRQ/FIQ disabled
	
	@ Sets interrupt table base address on coprocessor 15.
	ldr r0, =InterruptVector
	mcr p15, 0, r0, c12, c0, 0
	
	@ Initializes SystemTime counter to 0.
	ldr r2, =SystemTime
	mov r0,#0
	str r0,[r2]

@ Initializing stacks:
	mrs r0, CPSR
	bic r0, r0, #0x1F
	orr r0, r0, #SUPERVISOR_MODE
	msr SPSR, r0

	ldr SP, =SupervisorStack	@ Initializes supervisor mode stack
	
	mrs r0, CPSR
	bic r0, r0, #0x1F
	orr r0, r0, #IRQ_MODE
	msr SPSR, r0
	
	ldr SP, =IRQStack			@ Initializes IRQ mode stack
	
	mrs r0, CPSR
	bic r0, r0, #0x1F
	orr r0, r0, #SYSTEM_MODE
	msr SPSR, r0
	
	ldr SP, =UserStack			@ Initializes user mode stack
	
	mrs r0, CPSR
	bic r0, r0, #0x1F
	orr r0, r0, #SUPERVISOR_MODE
	msr SPSR, r0

@ Setting GPT
								@ Enable clock source
	ldr r2, =GPT_CR 			@ Loading GPT_CR address
	mov r0, #0x41 				@ adding  aflag mask on r0
	str r0, [r2]				@ Writing the flags on GPT_CR

								@ Resetting prescaler
	ldr r2, =GPT_PR				@ Loading GPT_PR address
	mov r0, #0					@ r0 <= 0
	str r0, [r2]				@ Setting prescaler t0 zero

								@ Setting prescaler limit
	ldr r2, =GPT_OCR1 			@ Loading GPT_OCR1 address
	mov r0, #TIME_SZ			@ Add time limit constant to ro 
	str r0, [r2]				@ Setting the limit as TIME_SZ

								@ Enable interruptions
	ldr r2, =GPT_IR				@ Loading GPT_IR address
	mov r0, #1 					@ r0 <= 1
	str r0, [r2]				@ Setting interruptions to 1, true

@ Setting GPIO
								@ Sets GPIO direction register
	ldr r0, =GDIRMask 			@ Loads GDIRMask value address
	ldr r1, =GDIR 				@ Load GDIR address
	str r0, [r1]				@ Store mask on the address
	
@ Setting TZIC

	ldr	r1, =TZIC_BASE			@ Enable interruption controller

	mov	r0, #(1 << 7)			@ Sets interruption #39 of GPT as non safe.
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
	msr CPSR_c, #0x13	   @SUPERVISOR mode, IRQ/FIQ enabled
	
	mrs r0, CPSR
	bic r0, r0, #0x1F
	orr r0, r0, #USER_MODE
	msr SPSR, r0
	
	@VAI PRO MODO DE USUARIO

    ldr r0, =ENTRY_POINT
    push {r0}
    bx r0

IRQ_HANDLER:
    push {r0-r1}			@ Secures context

	ldr r0, =GPT_SR			@ Signs that the interruption has been performed
	mov r1, #1
	str r1, [r0]
	
	ldr r0, =SystemTime		@ Increments system clock
	ldr r1, [r0]			@ Load SystemTime value on r1
	add r1, r1, #1			@ Time + 1
	str r1, [r0]			@ Store on SystemTime

	//Não esquecer de verificar alarmes!!!

	pop {r0-r1}				@ Recovers context
	sub lr, lr, #4			@ Correct the link register
	movs pc, lr 			@ Go back to the last mode

@ SYSCALL_HANDLER-------------------
@
@ r7 contains the syscall number
@ Parameters:
@	passed by the user stack
@
@number/function
@ 16 - read_sonar
@ 17 - register_proximity_callback
@ 18 - set_motor_speed
@ 19 - set_motors_speed
@ 20 - get_time
@ 21 - set_time
@ 22 - set_alarm

SYSCALL_HANDLER:

	cmp r7, #16
	beq read_sonar_svc

	cmp r7, #17
	beq register_proximity_callback_svc
	
	cmp r7, #18
	beq set_motor_speed_svc

	cmp r7, #19
	beq set_motors_speed_svc

	cmp r7, #20
	beq get_time_svc

	cmp r7, #21
	beq set_time_svc

	cmp r7, #22
	beq set_alarm_svc

	@default treatment
	movs pc, lr


@---------------------------
set_motor_speed_svc:
	push {r1-r3}			@ Save context on supervisor stack
	
	mrs r0, CPSR
	bic r0, r0, #0x1F
	orr r0, r0, #SYSTEM_MODE
	msr SPSR, r0
	
	pop {r1, r2}			@ R1 <= P0; R2 <= P1;
	
	mrs r0, CPSR
	bic r0, r0, #0x1F
	orr r0, r0, #SUPERVISOR_MODE
	msr SPSR, r0
	
	eor r0, r0, r0			@ R0 <= 0
	cmp r2, #0x3F
	movhi r0, #-2			@ If |speed| is higher than 2^6-1, set R0 to -2
	cmp r1, #1
	movhi r0, #-1			@ If |id| is higher than 1, set R0 to -1
	
	cmp r0, #0				@ If R0 != 0, return.
	beq First				@ Continue
	pop {r1-r3}				@ Get context back (if necessary)
	movs pc, lr 			@ Going back to user mode

First:
	cmp r1, #1
	beq Second				@ If id == 1, jump to second motor section
	lsl r2, r2, #18			@ Prepare speed for masking
	ldr r1, =DR				@ Load original DR
	ldr r3, [r1]			@ Mask it in order to update Motor0 range
	bic r3, r3, #0x1FC0000
	orr r3, r3, r2
	str r3, [r1]			@ Update DR
	
	pop {r1-r3}				@ Restore context
	movs pc, lr 			@ Going back to users mode
	
Second:
	lsl r2, r2, #25			@ Prepare speed for masking
	ldr r1, =DR				@ Load original DR
	ldr r3, [r1]			@ Mask it in order to update Motor0 range
	bic r3, r3, #0xFE000000
	orr r3, r3, r2
	str r3, [r1]			@Update DR
	
	pop {r1-r3}
	movs pc, lr 			@Going back to users mode

@---------------------------
set_motors_speed_svc:
	push {r1-r3}			@PILHA DO TIO3
	
	mrs r0, CPSR
	bic r0, r0, #0x1F
	orr r0, r0, #SYSTEM_MODE
	msr SPSR, r0
	
	pop {r1, r2}			@R1 <= P0; R2 <= P1;
	
	mrs r0, CPSR
	bic r0, r0, #0x1F
	orr r0, r0, #SUPERVISOR_MODE
	msr SPSR, r0
	
	eor r0, r0, r0			@ R0 <= 0
	cmp r2, #0x3F
	movhi r0, #-2			@ If |speed1| is higher than 2^6-1, set R0 to -2
	cmp r1, #0x3F
	movhi r0, #-1			@ If |speed0| is higher than 2^6-1, set R0 to -1
	
	cmp r0, #0				@ If R0 != 0, return.
	beq continue_set_motors	@ Continue 
	pop {r1-r3}
	movs pc, lr 			@Going back to users mode
	
continue_set_motors:
	lsl r1, r1, #18			@ Prepare speed0 for masking
	lsl r2, r2, #25			@ Prepare speed1 for masking
	orr r2, r1, r2
	
	ldr r1, =DR				@ Load original DR
	ldr r3, [r1]			@ Mask it in order to update Motor0 range
	bic r3, r3, #0x1FC0000
	orr r3, r3, r2
	str r3, [r1]
	
	pop {r1-r3}				@Update DR
	movs pc, lr 			@Going back to users mode

@---------------------------
set_time_svc:
	push {r0-r2}			@Saving the users register state (Supervisor stack!)

	mrs r0, CPSR
	bic r0, r0, #0x1F
	orr r0, r0, #SYSTEM_MODE
	msr SPSR, r0

	pop {r2}				@Pop the parameter value (System stack!)
	
	mrs r0, CPSR
	bic r0, r0, #0x1F
	orr r0, r0, #SUPERVISOR_MODE
	msr SPSR, r0
	
	ldr r1, =SystemTime		@Get the SystemTime address
	str r2, [r1]			@Setting the time

	pop {r0-r2}				@Poping the Users state
	movs pc, lr 			@Going back to users mode

@---------------------------
get_time_svc:
	push {r1}			@Saving state, context
	
	ldr r1, =SystemTime		@Load the SystemTime address
	ldr r0, [r1]			@Load the SystemTime value on the return register
	
	pop {r1}			@Pop the user state
	movs pc, lr 			@Go back to User mode and users code


@---------------------------
set_alarm_svc:
	push {r1-r3}			@ Save context on supervisor stack

	mrs r0, CPSR
	bic r0, r0, #0x1F
	orr r0, r0, #SYSTEM_MODE
	msr SPSR, r0

	pop {r1, r2}			@ R1 <= Callback function pointer
							@ R2 <= Target system time

	mrs r0, CPSR
	bic r0, r0, #0x1F
	orr r0, r0, #SUPERVISOR_MODE
	msr SPSR, r0

	ldr r0, =SystemTime		@ Loads SystemTime address
	ldr r0, [r0]			@ Loads SystemTime

	cmp r2, r0				@ If target system time is less than or equal to current
	movls r0, #-2			@system time, returns -2.
	bls set_alarm_end

	mov r0, =Alarms			@ Loads Alarms base address into R0
	mov r3, #0				@ Initializes R3 as index

find_free_alarm:
	ldr r4, [r0, r3]		@ Loads alarm time into R4
	cmp r4, #-1				@ Checks if it is free (-1)
	beq free_alarm_found
	add r3, r3, #8			@ Increments index.
	cmp r3, #MAX_ALARMS
	blo find_free_alarm		@ Keep searching

	cmp r3, #MAX_ALARMS		@ Checks if search failed
	movhs r0, #-1			@ If failed, return -1
	bhs set_alarm_end

free_alarm_found:			@ Free alarm found at r0 + r3.
	str r2, [r0, r3]		@ Adds new alarm target time
	add r3, r3, #4
	str r1, [r0, r3]		@ Adds new alarm target callback

set_alarm_end:
	pop {r1-r3}
	movs pc, lr 			@Going back to users mode

@---------------------------
read_sonar_svc:


@---------------------------
register_proximity_callback_svc:


@Data Section>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

.data
	SystemTime:				@Defining SystemTime 
	.fill 1, 4, 0
	Alarms:					@Alarms vector
	.fill MAX_ALARMS, 8, -1
							@Creating spaces to modes stacks
	.fill STACK_SIZE, 4, 0
	UserStack:
	.fill STACK_SIZE, 4, 0	@supervisor stack
	SupervisorStack:
	.fill STACK_SIZE, 4, 0	@IQR stack
	IRQStack:
