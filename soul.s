@ Giovani Nascimento Pereira	R.A.: 168609
@ Renan Adriani Sterle			R.A.: 176526
@ MC404 Project - Uoli
@ Operational System - SOUL

@-VERIFICATION: OK--------------------------------------------------------------
@ System time constants.
<<<<<<< HEAD
.set TIME_SZ,			0x0000FF00
.set TIME_DIVIDER,		0X00000003
.set DIST_INTERVAL,		0x0000000A
=======
.set TIME_SZ,			0x00000064
.set TIME_DIVIDER,		0X00000100
.set DIST_INTERVAL,		0x00000100
>>>>>>> 96596bd3f4a3cb66954467c25b614c9fb1137f30
.set DELAY_CYCLES,		0x00000064

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
@-------------------------------------------------------------------------------

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

@-VERIFICATION: OK--------------------------------------------------------------
RESET_HANDLER:
	msr CPSR_c, #SUPERVISOR_MODE_NI	@ Switches to SVC mode.

	ldr r0, =InterruptVector		@ Sets interrupt table base address on 
	mcr p15, 0, r0, c12, c0, 0		@ coprocessor 15.

@ Initializing stacks:
	ldr SP, =SupervisorStack		@ Initializes supervisor mode stack.
	
	msr CPSR_c, #IRQ_MODE_NI		@ Switches to IRQ mode.
	ldr SP, =IRQStack				@ Initializes IRQ mode stack.
	
	msr CPSR_c, #SYSTEM_MODE_NI		@ Switches to SYSTEM mode.
	ldr SP, =UserStack				@ Initializes user mode stack.
	
	msr CPSR_c, #SUPERVISOR_MODE_NI	@ Switches back to SVC mode.

@ Initializing System Variables:
	ldr r0, =NextCallbackTime 		@ Loads NextCallbackTime address.
	mov r1, #DIST_INTERVAL			@ R1 <= DIST_INTERVAL.
	str r1, [r0]					@ Sets NextCallbackTime to DIST_INTERVAL
	
	ldr r0, =NextSystemTimeTick 	@ Loads NextSystemTimeTick address.
	mov r1, #TIME_DIVIDER			@ R1 <= TIME_DIVIDER.
	str r1, [r0]					@ Sets NextSystemTimeTick to TIME_DIVIDER
	
	ldr r0, =SystemTime 			@ Load SystemTime address.
	mov r1, #0 						@ R1 <= 0.
	str r1, [r0]					@ Resets SystemTime.
	
<<<<<<< HEAD
=======
	ldr r0, =IRQCounter 			@ Load IRQCounter address.
	str r1, [r0]					@ Resets IRQCounter.
	
>>>>>>> 96596bd3f4a3cb66954467c25b614c9fb1137f30
	ldr r0, =ActiveCallbacks		@ Loads ActiveCallbacks address.
	str r1, [r0]					@ Resets.
	
	ldr r0, =ReadingSonar			@ Loads ReadingSonar address.
	str r1, [r0]					@ Resets.
	
	ldr r0, =ExecutingCallback		@ Loads ExecutingCallback address.
	str r1, [r0]					@ Resets.
	
	ldr r0, =Alarms 				@ Load Alarms address on R0.
	mov r2, #-1 					@ Moves alarms initial value to R2.
	
reset_vectors:
	str r2, [r0, r1, lsl #2]		@ Stores -1 on the Alarms position.
	add r1, r1, #1 					@ Increments counter.
	cmp r1, #MAX_ALARMS << 1		@ Compares with limit.
	blo reset_vectors				@ Repeats if necessary.

@ Setting GPT:
	ldr r2, =GPT_CR 				@ Loads GPT_CR address.
	mov r0, #0x41 					@ Loads setting.
	str r0, [r2]					@ And applies to GPT_CR, enabling source.

	ldr r2, =GPT_PR					@ Loads GPT_PR address.
	eor r0, r0, r0					@ R0 <= 0.
	str r0, [r2]					@ Sets prescaler to zero.

	ldr r2, =GPT_OCR1 				@ Loads GPT_OCR1 address.
	mov r0, #TIME_SZ				@ Loads TIME_SZ.
	str r0, [r2]					@ Sets prescaler limit to TIME_SZ.

	ldr r2, =GPT_IR					@ Loads GPT_IR address.
	mov r0, #1 						@ R0 <= 1.
	str r0, [r2]					@ Enables GTP interruptions.

@ Setting GPIO:
	ldr r0, =GDIRMask 				@ Loads GDIRMask.
	ldr r1, =GDIR 					@ Load GDIR address.
	str r0, [r1]					@ Sets GPIO direction.
	
@ Setting TZIC:
	ldr	r1, =TZIC_BASE				@ Enables interruption controller.
<<<<<<< HEAD

	mov	r0, #(1 << 7)				@ Sets interruption #39 of GPT as
	str	r0, [r1, #TZIC_INTSEC1]		@ non safe.

=======

	mov	r0, #(1 << 7)				@ Sets interruption #39 of GPT as
	str	r0, [r1, #TZIC_INTSEC1]		@ non safe.

>>>>>>> 96596bd3f4a3cb66954467c25b614c9fb1137f30
	mov	r0, #(1 << 7)				@ Enables GPT interruption #39
	str	r0, [r1, #TZIC_ENSET1]

	ldr r0, [r1, #TZIC_PRIORITY9]	@ Sets interruption 39 priority as 1.
	bic r0, r0, #0xFF000000
	mov r2, #1
	orr r0, r0, r2, lsl #24
	str r0, [r1, #TZIC_PRIORITY9]

	eor r0, r0, r0
	str r0, [r1, #TZIC_PRIOMASK]	@ Clears PRIOMASK.

	mov	r0, #1
	str	r0, [r1, #TZIC_INTCTRL]		@ Enables interruption controller.

	msr CPSR_c, #USER_MODE	  		@ Changes to USER mode, IRQ/FIQ enabled.

	ldr r0, =ENTRY_POINT			@ Goes to user code.
	bx r0
@-------------------------------------------------------------------------------

@-VERIFICATION: OK--------------------------------------------------------------
IRQ_HANDLER:
	push {r0-r12, lr}				@ Saves previous context.
	
	mrs r0, spsr					@ Saves original SPSR.
	push {r0}
	
	ldr r0, =GPT_SR					@ Signs that the interruption has been
	mov r1, #1						@ 	performed.
	str r1, [r0]

<<<<<<< HEAD
	ldr r0, =NextSystemTimeTick		@ Loads NextSystemTimeTick address into R0.
	ldr r1, [r0]					@ Loads NextSystemTimeTick into R1.
=======
	ldr r0, =IRQCounter				@ Loads IRQCounter address into R0.
	ldr r10, [r0]					@ Loads IRQCounter into R10.
	add r10, r10, #1				@ Increments IRQCounter.
	str r10, [r0]					@ Updates it.

	ldr r0, =NextSystemTimeTick		@ Loads NextSystemTimeTick address into R0.
	ldr r1, [r0]					@ Loads NextSystemTimeTick into R10.
>>>>>>> 96596bd3f4a3cb66954467c25b614c9fb1137f30
	sub r1, r1, #1					@ Decrements NextSystemTimeTick.
	cmp r1, #0
	movlt r1, #TIME_DIVIDER
	str r1, [r0]					@ And updates it.
	
	cmp r1, #0
	bne callbacks_check_begin

	ldr r1, =SystemTime				@ Loads SystemTime address into R1.
	ldr r0, [r1]					@ Loads SystemTime into R0.
	add r0, r0, #1					@ Increments SystemTime.
	str r0, [r1]					@ Updates it.

	ldr r1, =ExecutingCallback		@ Checks if alarms and callbacks are enabled
	ldr r1, [r1]
	cmp r1, #1
	beq irq_handler_end

@ Checks enabled alarms.
	ldr r1, =Alarms					@ Loads Alarms base address into R1.
	eor r3, r3, r3					@ Initializes R3 as index.

check_alarms:
	ldr r4, [r1, r3]				@ Loads alarm time into R4.

	cmp r4, #-1						@ Checks if it is not enabled.
	beq next_alarm
	cmp r4, r0						@ Checks if it has not expired yet.
	bhi next_alarm

	ldr r4, =ExecutingCallback		@ Disables new alarms and callbacks.
	mov r2, #1
	str r2, [r4]

	mov r4, #-1						@ Disables alarm.
	str r4, [r1, r3]				@ Assigning -1 as its target time.
	add r3, r3, #4
	ldr r2, [r1, r3]				@ Loads function address on R2.

	push {r0-r4}					@ Saves current context.
	msr CPSR_c, #SYSTEM_MODE_NI		@ Switches to SYSTEM mode.
	mov r4, lr						@ Stores user LR to R4.
	msr CPSR_c, #IRQ_MODE_NI
	push {r4}						@ Saves user LR on IRQ stack.
	msr CPSR_c, #USER_MODE			@ Changes mode to USER.

	blx r2							@ And jumps to user callback function.
<<<<<<< HEAD

	mov r7, #15360					@ Gets back to IRQ mode using syscall #15360
	svc 0x0
alarm_return_point:

	pop {r0}						@ Pops user LR into R0.
	msr CPSR_c, #SYSTEM_MODE_NI		@ And recovers it.
	mov lr, r0
	msr CPSR_c, #IRQ_MODE_NI		@ Gets back to IRQ mode.
	pop {r0-r4}						@ Recovers context.

next_alarm:
	add r3, r3, #8					@ Increments index to check other alarms...
	cmp r3, #MAX_ALARMS << 3		@ Until limit.
	blo check_alarms				@ Keeps chekcing.

callbacks_check_begin:
	ldr r1, =NextCallbackTime		@ Loads NextCallbackTime address into R1.
	ldr r2, [r1]					@ Loads NextCallbackTime into R2.
	sub r2, r2, #1					@ Decrements and updates NextCallbackTime.
	cmp r2, #0
	movlt r2, #DIST_INTERVAL
	str r2, [r1]

	bne irq_handler_usual_end		@ Goes to irq_handler_usual_end if not NULL.

	ldr r0, =ReadingSonar			@ Loads ReadingSonar address.
	ldr r0, [r0]					@ Loads ReadingSonar.
	cmp r0, #0
	bne irq_handler_usual_end		@ If user is reading a sonar, skips verif.

	ldr r1, =ActiveCallbacks		@ Loads number of ActiveCallbacks.
	ldr r2, [r1]
	cmp r2, #0
	bls irq_handler_usual_end		@ If null, skips to irq_handler_usual_end.

	add r1, r2, #0					@ Calculates index limit using number
	lsl r1, #1						@ of active callbacks.
	add r1, r2, r1					@ R1 <= 3*R2.
	
@ Checks enabled callbacks.
	ldr r0, =Callbacks				@ Loads Callbacks base address into R0.
	eor r3, r3, r3					@ Initializes R3 as index.

check_callbacks:
	cmp r3, r1						@ Compares index to limit.
	bhs irq_handler_usual_end		@ Continues if it is still valid.

	ldr r4, [r3, r0]				@ Loads callback sonar ID into R4.
	add r3, r3, #4
	ldr r5, [r3, r0]				@ Loads callback threshold into R5.
	add r3, r3, #4
	ldr r6, [r3, r0]				@ Loads callback function pointer into R6.
	add r3, r3, #4

=======

	mov r7, #15360					@ Gets back to IRQ mode using syscall #15360
	svc 0x0
alarm_return_point:

	pop {r0}						@ Pops user LR into R0.
	msr CPSR_c, #SYSTEM_MODE_NI		@ And recovers it.
	mov lr, r0
	msr CPSR_c, #IRQ_MODE_NI		@ Gets back to IRQ mode.
	pop {r0-r4}						@ Recovers context.

next_alarm:
	add r3, r3, #8					@ Increments index to check other alarms...
	cmp r3, #MAX_ALARMS << 3		@ Until limit.
	blo check_alarms				@ Keeps chekcing.

callbacks_check_begin:
	ldr r1, =NextCallbackTime		@ Loads NextCallbackTime address into R1.
	ldr r2, [r1]					@ Loads NextCallbackTime into R2.
	sub r2, r2, #1					@ Decrements and updates NextCallbackTime.
	cmp r2, #0
	movlt r2, #DIST_INTERVAL
	str r2, [r1]

	bne irq_handler_usual_end		@ Goes to irq_handler_usual_end if not NULL.

	ldr r0, =ReadingSonar			@ Loads ReadingSonar address.
	ldr r0, [r0]					@ Loads ReadingSonar.
	cmp r0, #0
	bne irq_handler_usual_end		@ If user is reading a sonar, skips verif.

	ldr r1, =ActiveCallbacks		@ Loads number of ActiveCallbacks.
	ldr r2, [r1]
	cmp r2, #0
	bls irq_handler_usual_end		@ If null, skips to irq_handler_usual_end.

	add r1, r2, #0					@ Calculates index limit using number
	lsl r1, #1						@ of active callbacks.
	add r1, r2, r1					@ R1 <= 3*R2.
	
@ Checks enabled callbacks.
	ldr r0, =Callbacks				@ Loads Callbacks base address into R0.
	eor r3, r3, r3					@ Initializes R3 as index.

check_callbacks:
	cmp r3, r1						@ Compares index to limit.
	bhs irq_handler_usual_end		@ Continues if it is still valid.

	ldr r4, [r3, r0]				@ Loads callback sonar ID into R4.
	add r3, r3, #4
	ldr r5, [r3, r0]				@ Loads callback threshold into R5.
	add r3, r3, #4
	ldr r6, [r3, r0]				@ Loads callback function pointer into R6.
	add r3, r3, #4

>>>>>>> 96596bd3f4a3cb66954467c25b614c9fb1137f30
	lsl r4, #2 						@ Prepares ID to place it on DR.
	ldr r8, =DR						@ Loads DR address.
	ldr r7, [r8]					@ Loads DR current value.
	bic r7, r7, #0x03C				@ Masks it in order to update sensor ID.
	orr r7, r7, r4
	bic r7, r7, #0x2				@ Sets trigger bit to low.
	str r7, [r8]					@ Updates DR.

	ldr r4, =DELAY_CYCLES			@ Loads DELAY_CYCLES.
read_sonar_delay_irq1:
	sub r4, r4, #1					@ Decrements counter.
	cmp r4, #0
	bhi read_sonar_delay_irq1		@ Waits while it is not zero.
	
	orr r7, r7, #2 					@ Sets trigger bit to high.
	str r7, [r8]					@ Updates DR.

	ldr r4, =DELAY_CYCLES			@ Loads DELAY_CYCLES.
read_sonar_delay_irq2:
	sub r4, r4, #1					@ Decrements counter.
	cmp r4, #0
	bhi read_sonar_delay_irq2		@ Waits while it is not zero.

	bic r7, r7, #0x2				@ Sets trigger bit to low.
	str r7, [r8]					@ Updates DR.

read_sonar_flag_irq:				@ Waits for flag to go high.
	ldr r7, [r8]					@ Checks DR value...
	and r7, #1 						@ ...getting flag bit.
	cmp r7, #1 						@ Compares it to 1.
	bne read_sonar_flag_irq			@ Repeats while not 1.

	ldr r7, [r8]					@ Loads DR value again.
	ldr r9, =0x3FFC0
	and r2, r7, r9					@ Gets only the Sonar_Data bits on r4.
	lsr r2, #6 						@ Place them correctly.

	cmp r2, r5						@ Compares range to threshold.
	bhs check_callbacks				@ Gets back if range is not smaller.
	
	ldr r4, =ExecutingCallback		@ Disables new alarms and callbacks.
	mov r7, #1
	str r7, [r4]

	push {r0-r6}					@ Saves current context.
	msr CPSR_c, #SYSTEM_MODE_NI		@ Switches to SYSTEM mode.
	mov r4, lr						@ Stores user LR to R4.
	msr CPSR_c, #IRQ_MODE_NI
	push {r4}						@ Saves user LR on IRQ stack.
	msr CPSR_c, #USER_MODE			@ Changes mode to USER.

	blx r6							@ And jumps to user callback function.

	mov r7, #15872					@ Gets back to IRQ mode using syscall #15872
	svc 0x0
callback_return_point:
	pop {r0}						@ Pops user LR into R0.
	msr CPSR_c, #SYSTEM_MODE_NI		@ And recovers it.
	mov lr, r0
	msr CPSR_c, #IRQ_MODE_NI		@ Gets back to IRQ mode.
	pop {r0-r6}						@ Recovers context.
	b check_callbacks				@ Keeps checking callbacks.

irq_handler_usual_end:
	ldr r4, =ExecutingCallback		@ Enables new alarms and callbacks.
	mov r7, #0
	str r7, [r4]

irq_handler_end:
	pop {r0}
	msr spsr, r0					@ Recovers original SPSR.
	
	pop {r0-r12, lr}				@ Recovers original context.
	sub lr, lr, #4					@ Corrects IRQ LR.
	movs pc, lr 					@ Goes back to the last mode.
@-------------------------------------------------------------------------------

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
	
	cmp r7, #15872
	beq callback_invocation_recover

	movs pc, lr						@ Default treatment.
@-------------------------------------------------------------------------------

@-VERIFICATION: OK--------------------------------------------------------------
set_motor_speed_svc:
	push {r1-r3}					@ Saves previous context.

	msr CPSR_c, #SYSTEM_MODE		@ Changes mode to SYSTEM.
	ldr r1, [sp]					@ R1 <= id;
	ldr r2, [sp, #4]				@ R2 <= speed;
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
	ldr r1, [sp]					@ R1 <= speed0;
	ldr r2, [sp, #4]				@ R2 <= speed;
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
	bic r3, r3, #0xFE000000
	orr r3, r3, r2
	str r3, [r1]					@ Updates DR.
	
	pop {r1-r3}						@ Recovers previous context.
	movs pc, lr 					@ Returns from syscall.
@-------------------------------------------------------------------------------

@-VERIFICATION: OK--------------------------------------------------------------
set_time_svc:
	push {r1-r2}					@ Saves previous context.

	msr CPSR_c, #SYSTEM_MODE		@ Changes mode to SYSTEM.
	ldr r2, [sp]					@ Gets desired system time from user stack.
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
	ldr r1, [sp]					@ R1 <= Callback function pointer.
	ldr r2, [sp, #4]				@ R2 <= Target system time.
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

free_alarm_found:					@ Free alarm slot found at R0 + R3.
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
	mrs r7, spsr
	bic r7, #0xFF
	orr r7, r7, #IRQ_MODE_NI
	msr spsr, r7

	msr cpsr_c, #IRQ_MODE_NI		@ Changes mode back to IRQ.
	b alarm_return_point			@ And returns to alarms invocation specific
									@ location.
@-------------------------------------------------------------------------------

@-VERIFICATION: OK--------------------------------------------------------------
callback_invocation_recover:
	mrs r7, spsr
	bic r7, #0xFF
	orr r7, r7, #IRQ_MODE_NI
	msr spsr, r7

	msr cpsr_c, #IRQ_MODE_NI		@ Changes mode back to IRQ.
	b callback_return_point			@ And returns to alarms invocation specific
									@ location.
@-------------------------------------------------------------------------------

@-VERIFICATION: OK--------------------------------------------------------------
read_sonar_svc:
	push {r1 - r3}					@ Saves previous context.

	ldr r1, =ReadingSonar			@ Loads ReadingSonar address.
	mov r0, #1						@ Sets it to true, to prevent IRQ from
	str r0, [r1]					@ interfering on sonar read process.

	msr CPSR_c, #SYSTEM_MODE		@ Changes mode to SYSTEM.
	ldr r0, [sp]					@ GetS parameters from user stack. R0 <= ID.
	msr CPSR_c, #SUPERVISOR_MODE	@ Goes back to SVC mode.

	cmp r0, #15						@ Compares |ID| with 15, testing limits.
	movhi r0, #-1					@ Wrong ID, R0 <= -1.
	bhi read_sonar_svc_end			@ Wrong ID, exits.

	lsl r0, #2 						@ Prepares ID to place it on DR.
	ldr r1, =DR						@ Loads DR address.
	ldr r3, [r1]					@ Loads DR current value.
	bic r3, r3, #0x03C				@ Masks it in order to update sensor ID.
	orr r3, r3, r0
	bic r3, r3, #0x2				@ Sets trigger bit to low.
	str r3, [r1]					@ Updates DR.

	ldr r0, =DELAY_CYCLES			@ Loads DELAY_CYCLES.
read_sonar_delay1:
	sub r0, r0, #1					@ Decrements counter.
	cmp r0, #0
	bhi read_sonar_delay1			@ Waits while it is not zero.
	
	orr r3, r3, #2 					@ Sets trigger bit to high.
	str r3, [r1]					@ Updates DR.

	ldr r0, =DELAY_CYCLES			@ Loads DELAY_CYCLES.
read_sonar_delay2:
	sub r0, r0, #1					@ Decrements counter.
	cmp r0, #0
	bhi read_sonar_delay2			@ Waits while it is not zero.

	bic r3, r3, #0x2				@ Sets trigger bit to low.
	str r3, [r1]					@ Updates DR.

read_sonar_flag:					@ Waits for flag to go high.
	ldr r3, [r1]					@ Checks DR value...
	and r3, #1 						@ ...getting flag bit.
	cmp r3, #1 						@ Compares it to 1.
	bne read_sonar_flag				@ Repeats while not 1.

	ldr r3, [r1]					@ Loads DR value again.
	ldr r2, =0x3FFC0
	and r0, r3, r2 					@ Gets only the Sonar_Data bits on r0.
	lsr r0, #6 						@ Place them correctly.

read_sonar_svc_end:

	ldr r3, =ReadingSonar			@ Loads ReadingSonar address.
	mov r1, #0						@ Sets it to false, to let IRQ 
	str r1, [r3]					@ read sonars.

	pop {r1 - r3}					@ Recovers previous context.
	movs pc, lr 					@ Returns from syscall.
@-------------------------------------------------------------------------------

@-VERIFICATION: OK--------------------------------------------------------------
register_proximity_callback_svc:
	push {r1-r5}					@ Saves previous context.

	msr CPSR_c, #SYSTEM_MODE		@ Changes mode to SYSTEM.
	ldr r1, [sp]					@ R1 <= Sonar ID.
	ldr r2, [sp, #4]				@ R2 <= Threshold distance.
	ldr r3, [sp, #8]				@ R3 <= Callback function pointer.
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

@-VERIFICATION: OK--------------------------------------------------------------
.data
SystemTime:							@ Defining System variables.
	.fill 1, 4, 0
<<<<<<< HEAD
=======
IRQCounter:							@ Defining System variables.
	.fill 1, 4, 0
>>>>>>> 96596bd3f4a3cb66954467c25b614c9fb1137f30
NextSystemTimeTick:
	.fill 1, 4, 0
NextCallbackTime:
	.fill 1, 4, 0
Alarms:								@ Defining vector to store the User Alarms.
	.fill 2*MAX_ALARMS, 4, -1
Callbacks:							@ Defining vector to store the callbacks.
	.fill 3*MAX_CALLBACKS, 4, -1
ActiveCallbacks:					@ Variable to store no. of active callbacks.
	.fill 1, 4, 0
ReadingSonar:						@ Means that a sonar is being read by user.
	.fill 1, 4, 0
ExecutingCallback:					@ Means that a callback is being executed.
	.fill 1, 4, 0
									@ Defining space for the system stacks.
	.fill STACK_SIZE, 4, 0
UserStack:							@ User Stack
	.fill STACK_SIZE, 4, 0
SupervisorStack:					@ Supervisor Stack
	.fill STACK_SIZE, 4, 0
IRQStack:							@ IRQ Stack
@-------------------------------------------------------------------------------

@ Made with <3 by Giovani & Sterle
