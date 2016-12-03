@ Giovani Nascimento Pereira	R.A.: 168609
@ Renan Adriani Sterle			R.A.: 176526
@ MC404 Project - Uoli
@ Operational System - SOUL

@ System time clock divider constant.
.set TIME_SZ,			0x00000064

@ System constants
.set MAX_ALARMS,		0x00000008
.set MAX_CALLBACKS,		0x00000008
.set STACK_SIZE,		0x00000064
.set SUPERVISOR_MODE,	0x00000013
.set SUPERVISOR_MODE_NI,0x000000D3
.set IRQ_MODE,			0x00000012
.set IRQ_MODE_NI,		0x000000D2
.set SYSTEM_MODE,		0x0000001F
.set SYSTEM_MODE_NI, 	0x000000DF
.set USER_MODE,			0x00000010
.set USER_MODE_NI,		0x000000D0
.set GDIRMask,			0xFFFC003E
.set ENTRY_POINT, 		0x77802000
.set TRIGGER_TIME,		0x00000001
.set DIST_INTERVAL,		TRIGGER_TIME * MAX_CALLBACKS << 1

@ GPT registers addresses constants.
.set GPT_CR,			0x53FA0000
.set GPT_PR,			0x53FA0004
.set GPT_SR,			0x53FA0008
.set GPT_IR,			0x53FA000C
.set GPT_OCR1,			0x53FA0010

@ TZIC registers addresses constants.
.set TZIC_BASE,			0x0FFFC000
.set TZIC_INTCTRL,		0x00000000
.set TZIC_INTSEC1,		0x00000084
.set TZIC_ENSET1,		0x00000104
.set TZIC_PRIOMASK,		0x0000000C
.set TZIC_PRIORITY9,	0x00000424

@ GPIO registers addresses constants.
.set DR,				0x53F84000
.set GDIR,				0x53F84004
.set PSR,				0x53F84008

@-VERIFICATION: OK--------------------------------------------------------------
.org 0x0
.section .iv, "a"

_start:
InterruptVector:
	b RESET_HANDLER

.org 0x08
	b SYSCALL_HANDLER

.org 0x18
	b IRQ_HANDLER
@-------------------------------------------------------------------------------






.org 0x100
.text

RESET_HANDLER:
	msr CPSR_c, #SUPERVISOR_MODE_NI	   @SUPERVISOR mode, IRQ/FIQ disabled

	@ Sets interrupt table base address on coprocessor 15.
	ldr r0, =InterruptVector
	mcr p15, 0, r0, c12, c0, 0

@ Initializing stacks:
	ldr SP, =SupervisorStack	@ Initializes supervisor mode stack
	
	msr CPSR_c, #IRQ_MODE_NI
	ldr SP, =IRQStack			@ Initializes IRQ mode stack
	
	msr CPSR_c, #SYSTEM_MODE_NI
	ldr SP, =UserStack			@ Initializes user mode stack
	
	msr CPSR_c, #SUPERVISOR_MODE_NI
@ Setting GPT
								@ Enable clock source
	ldr r2, =GPT_CR 			@ Loading GPT_CR address
	mov r0, #0x41 				@ adding  aflag mask on r0
	str r0, [r2]				@ Writing the flags on GPT_CR

								@ Resetting prescaler
	ldr r2, =GPT_PR				@ Loading GPT_PR address
	eor r0, r0, r0				@ r0 <= 0
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
	msr CPSR_c, #USER_MODE	   @USER mode, IRQ/FIQ enabled
	
	@VAI PRO MODO DE USUARIO

    ldr r0, =ENTRY_POINT
    bx r0







IRQ_HANDLER:
    push {r0-r12}			@ Secures context

	ldr r0, =GPT_SR			@ Signs that the interruption has been performed
	mov r1, #1
	str r1, [r0]
	
	ldr r0, =SystemTime		@ Increments system clock
	ldr r1, [r0]			@ Load SystemTime value on r1
	add r1, r1, #1			@ Time + 1
	str r1, [r0]			@ Store on SystemTime

@Checks enabled alarms
	ldr r0, =Alarms			@ Loads Alarms base address into R0
	eor r3, r3, r3			@ Initializes R3 as index

check_alarms:
	ldr r4, [r0, r3]		@ Loads alarm time into R4
	
	cmp r4, #-1				@ Checks if it is not enabled
	beq next_alarm
	cmp r4, r1				@ Checks if it is not equal to system time
	bhi next_alarm
	
	mov r4, #-1
	str r4, [r0, r3]		@ Disables alarm
	add r2, r3, #4
	ldr r2, [r0, r2]		@ Load function address on r2

	push {r0-r4}
	msr CPSR_c, #SYSTEM_MODE_NI
	mov r4, lr
	msr CPSR_c, #IRQ_MODE_NI
	push {r4}
	msr CPSR_c, #USER_MODE_NI
	
	blx r2

	mov r7, #15360
	svc 0x0
alarm_return_point:
	pop {r0}
	msr CPSR_c, #SYSTEM_MODE_NI
	mov lr, r0
	msr CPSR_c, #IRQ_MODE_NI
	pop {r0-r4}
next_alarm:
	add r3, r3, #8			@ Increments index.
	cmp r3, #MAX_ALARMS << 3
	blo check_alarms		@ Keep chekcing

	@TESTE@@@@@@@@@@@@@@@@@
	push {r0-r12}
	msr CPSR_c, #IRQ_MODE

	ldr r0, =SystemTime
	ldr r1, [r0]

	cmp r1, #1
loopInfinito:
	beq loopInfinito

	pop {r0-r12}
	msr CPSR_c, #IRQ_MODE_NI
	@@@@@@@@@@@@@@@@@@@@@@@@

	pop {r0-r12}
	sub lr, lr, #4			@ Correct the link register
	movs pc, lr 			@ Go back to the last mode














@-VERIFICATION: OK--------------------------------------------------------------
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

	cmp r7, #15360
	beq alarm_invocation_recover

	movs pc, lr						@ Default treatment.
@-------------------------------------------------------------------------------

@-VERIFICATION: OK--------------------------------------------------------------
set_motor_speed_svc:
	push {r1-r3}					@ Saves previous context.

	msr CPSR_c, #SYSTEM_MODE		@ Changes mode to SYSTEM.
	pop {r1, r2}					@ Gets desired parameters from user stack.
									@ R1 <= id; R2 <= speed.
	msr CPSR_c, #SUPERVISOR_MODE	@ Changes mode back to SVC.

	eor r0, r0, r0					@ R0 <= 0.
	cmp r2, #0x3F					@ If |speed| is higher than 2^6-1:
	movhi r0, #-2					@ Sets R0 to -2.
	cmp r1, #1
	movhi r0, #-1					@ If |id| is higher than 1, sets R0 to -1.

	cmp r0, #0						@ If R0 != 0, returnn.
	beq FirstMotor					@ Continue
	
	pop {r1-r3}						@ Recovers previous context.
	movs pc, lr 					@ Returns from syscall.

FirstMotor:
	cmp r1, #1
	beq SecondMotor					@ If id == 1, jumps to second motor section.
	lsl r2, r2, #19					@ Prepares speed for masking.
	ldr r1, =DR						@ Loads original DR.
	ldr r3, [r1]					@ Mask it in order to update Motor0 range.
	bic r3, r3, #0x1FC0000
	orr r3, r3, r2
	str r3, [r1]					@ Updates DR.
	
	pop {r1-r3}						@ Recovers previous context.
	movs pc, lr 					@ Returns from syscall.
	
SecondMotor:
	lsl r2, r2, #26					@ Prepares speed for masking.
	ldr r1, =DR						@ Loads original DR.
	ldr r3, [r1]					@ Mask it in order to update Motor1 range.
	bic r3, r3, #0xFE000000
	orr r3, r3, r2
	str r3, [r1]					@ Update DR.
	
	pop {r1-r3}						@ Recovers previous context.
	movs pc, lr 					@ Returns from syscall.
@-------------------------------------------------------------------------------

@-VERIFICATION: OK--------------------------------------------------------------
set_motors_speed_svc:
	push {r1-r3}					@ Saves previous context.
	
	msr CPSR_c, #SYSTEM_MODE		@ Changes mode to SYSTEM.
	pop {r1, r2}					@ Gets desired parameters from user stack.
									@R1 <= speed0; R2 <= speed1.
	msr CPSR_c, #SUPERVISOR_MODE	@ Changes mode back to SVC.
	
	eor r0, r0, r0					@ R0 <= 0.
	cmp r2, #0x3F					@ If |speed1| is higher than 2^6-1:
	movhi r0, #-2					@ Sets R0 to -2.

	cmp r1, #0x3F					@ If |speed0| is higher than 2^6-1:
	movhi r0, #-1					@ Sets R0 to -1.
									
	cmp r0, #0						@ If R0 != 0, returns.
	beq continue_set_motors			@ Continue .

	pop {r1-r3}						@ Recovers previous context.
	movs pc, lr 					@ Returns from syscall.
	
continue_set_motors:
	lsl r1, r1, #19					@ Prepares speed0 for masking.
	lsl r2, r2, #26					@ Prepares speed1 for masking.
	orr r2, r1, r2					@ Concatenates speeds into r2.
	
	ldr r1, =DR						@ Loads original DR.
	ldr r3, [r1]					@ Mask it in order to update motors range.
	bic r3, r3, #0x1FC0000
	orr r3, r3, r2
	str r3, [r1]					@ Updates DR.
	
	pop {r1-r3}						@ Recovers previous context.
	movs pc, lr 					@ Returns from syscall.
@-------------------------------------------------------------------------------

@-VERIFICATION: OK--------------------------------------------------------------
set_time_svc:
	push {r1-r2}					@ Saves previous context.

	msr CPSR_c, #SYSTEM_MODE		@ Changes mode to SYSTEM.
	pop {r2}						@ Gets desired system time from user stack.
	msr CPSR_c, #SUPERVISOR_MODE	@ Changes mode back to SVC.
	
	ldr r1, =SystemTime				@ Gets SystemTime address.
	str r2, [r1]					@ Updates SystemTime.

	pop {r1-r2}						@ Recovers previous context.
	movs pc, lr 					@ Returns from syscall.
@-------------------------------------------------------------------------------

@-VERIFICATION: OK--------------------------------------------------------------
get_time_svc:
	ldr r0, =SystemTime				@ Loads SystemTime address.
	ldr r0, [r0]					@ Loads SystemTime.
	movs pc, lr 					@ Returns from syscall.
@-------------------------------------------------------------------------------

@-VERIFICATION: OK--------------------------------------------------------------
set_alarm_svc:
	push {r1-r4}					@ Saves previous context.
	
	msr CPSR_c, #SYSTEM_MODE		@ Changes mode to SYSTEM.
	pop {r1, r2}					@ R1 <= Callback function pointer.
									@ R2 <= Target system time.
	msr CPSR_c, #SUPERVISOR_MODE	@ Goes back to SVC mode.

	ldr r0, =SystemTime				@ Loads SystemTime address.
	ldr r0, [r0]					@ Loads SystemTime.

	cmp r2, r0						@ Compares target time to system time.
	movle r0, #-2					@ If not greater, returns -2.
	bls set_alarm_end

	ldr r0, =Alarms					@ Loads Alarms base address into R0.
	eor r3, r3, r3					@ Initializes R3 as iteration index.

find_free_alarm:
	ldr r4, [r0, r3]				@ Loads alarm time into R4.
	cmp r4, #-1						@ Checks if it is disabled (-1).
	beq free_alarm_found
	add r3, r3, #8					@ Increments index.
	cmp r3, #MAX_ALARMS << 3		@ Compares to limit.
	blo find_free_alarm				@ If it is still lower, keeps searching.

	movhs r0, #-1					@ Search failed. There's no free slot.
	bhs set_alarm_end				@ Returns -1.

free_alarm_found:					@ Free alarm slot found at r0 + r3.
	str r2, [r0, r3]				@ Adds new alarm target time.
	add r3, r3, #4
	str r1, [r0, r3]				@ Adds new alarm target callback address.
	
	eor r0, r0, r0					@ Alarm successfully added. Returns 0.
set_alarm_end:
	pop {r1-r4}						@ Recovers previous context.
	movs pc, lr 					@ Returns from syscall.
@-------------------------------------------------------------------------------

@-VERIFICATION: OK--------------------------------------------------------------
alarm_invocation_recover:
	msr cpsr_c, #IRQ_MODE_NI		@ Changes mode back to IRQ.
	b alarm_return_point			@ And returns to alarms invocation specific
									@ location.
@-------------------------------------------------------------------------------

@-VERIFICATION: OK--------------------------------------------------------------
read_sonar_svc:
	push {r1 - r4}					@ Saves previous context.

	msr CPSR_c, #SYSTEM_MODE		@ Changes mode to SYSTEM.
	pop {r0}						@ GetS parameters from user stack. R0 <= ID.
	msr CPSR_c, #SUPERVISOR_MODE	@ Goes back to SVC mode.

	cmp   r0, #15					@ Compares |ID| with 15, testing limits.
	movhi r0, #-1					@ Wrong ID, R0 <= -1.
	bhi read_sonar_svc_end			@ Wrong ID, exits.

	lsl r0, #2 						@ Prepares ID to place it on DR.
	ldr r1, =DR						@ Loads DR address.
	ldr r3, [r1]					@ Loads DR current value.
	bic r3, r3, #0x03C				@ Masks it in order to update sensor ID.
	orr r3, r3, r0
	str r3, [r1]					@ Updates DR.

	bic r3, r3, #0x2				@ Sets trigger bit to low.
	str r3, [r1]					@ Updates DR.

	ldr r2, =SystemTime				@ Loads SystemTime address.
	ldr r0, [r2]					@ Loads SystemTime current.
	add r0, r0, #TRIGGER_TIME		@ Set time limit.

read_sonar_delay1:
	ldr r4, [r2]					@ Loads SystemTime value.
	cmp r4, r0 						@ Compares current time with time limit.
	blo read_sonar_delay1 			@ Repeats while TRIGGER_TIME has not elapsed

	orr r3, r3, #2 					@ Sets trigger bit to high.
	str r3, [r1]					@ Updates DR.

	add r0, r0, #TRIGGER_TIME		@ Sets time limit.

read_sonar_delay2:
	ldr r4, [r2]					@ Loads SystemTime value.
	cmp r4, r0						@ Compares current time with time limit.
	blo read_sonar_delay2			@ Repeats while TRIGGER_TIME has not elapsed

	bic r3, r3, #0x02				@ Sets trigger bit to low.
	str r3, [r1]					@ Updates DR.

read_sonar_flag_1:					@ Waits for flag to go high.
	ldr r3, [r1]					@ Checks DR value...
	and r3, #1 						@ ...getting flag bit.
	cmp r3, #1 						@ Compares it to 1.
	bne read_sonar_flag_1			@ Repeats while not 1.

	ldr r3, [r1]					@ Loads DR value again.
	ldr r2, =0x3FFC0
	and r0, r3, r2 					@ Gets only the Sonar_Data bits on r0.
	lsr r0, #6 						@ Place them correctly.

read_sonar_svc_end:
	pop {r1 - r4}					@ Recovers previous context.
	movs pc, lr 					@ Returns from syscall.
@-------------------------------------------------------------------------------

@-VERIFICATION: OK--------------------------------------------------------------
register_proximity_callback_svc:
	push {r1-r5}					@ Saves previous context.

	msr CPSR_c, #SYSTEM_MODE		@ Changes mode to SYSTEM.
	pop {r1-r3}						@ R1 <= Sonar ID.
									@ R2 <= Threshold distance.
									@ R3 <= Callback function pointer.
	msr CPSR_c, #SUPERVISOR_MODE	@ Goes back to SVC mode.

	cmp r1, #15						@ Compares |ID| with 15, testing limits.
	movhi r0, #-2					@ Wrong ID, returns -2.
	bhs set_callback_end

	ldr r4, =ActiveCallbacks		@ Loads ActiveCallbacks address.
	ldr r4, [r4]					@ Loads ActiveCallbacks.

	cmp r4, #MAX_CALLBACKS			@ Comperes ActiveCallbacks to MAX_CALLBACKS.
	movhs r0, #-1					@ If max. has been reached, returns -1.
	bhs set_callback_end

	ldr r0, =Callbacks				@ Loads Alarms base address into R0.

	add r5, r4, #0					@ Calculates index.
	add r5, r4, r5
	add r5, r4, r5
	lsl r5, #2
	str r1, [r0, r5]				@ Adds new callback sonar ID.
	add r5, r5, #4
	str r2, [r0, r5]				@ Adds new callback threshold distance.
	add r5, r5, #4
	str r3, [r0, r5]				@ Adds new callback function pointer.

	
	add r4, r4, #1					@ Increments ActiveCallbacks.
	ldr r1, =ActiveCallbacks		@ Loads ActiveCallbacks address.
	str r4, [r1]					@ Updates ActiveCallbacks.
	
	eor r0, r0, r0					@ Callback successfully added. Returns 0.
set_callback_end:
	pop {r1-r5}						@ Recovers previous context.
	movs pc, lr 					@ Returns from syscall.
@-------------------------------------------------------------------------------












@Data Section>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

.data
SystemTime:
	.fill 1, 4, 0
Alarms:
	.fill 2*MAX_ALARMS, 4, -1
Callbacks:
	.fill 3*MAX_CALLBACKS, 4, -1
ActiveCallbacks:
	.fill 1, 4, 0

	.fill STACK_SIZE, 4, 0
UserStack:
	.fill STACK_SIZE, 4, 0
SupervisorStack:
	.fill STACK_SIZE, 4, 0
IRQStack:
@ Made with <3 by Giovani & Sterle

@TODO: Inicializar variaveis no reset
@register callbacks
@verify callbacks and sonar
@verify callbacks frequency
@calibrate system time
@salvar registradores do usuário e lr no callback
