@ Giovani Nascimento Pereira - 168609
@ Renan Adriani Sterle  	 - 176526
@ Projeto MC404 - Uoli
@ Sistema Operacional - SOUL
@

@ Secao iv---------------------------------------------

@ System time clock divider constant
.set TIME_SZ,			0x64

@ GPT registers addresses constants
.set GPT_CR,			0x53FA0000
.set GPT_PR,			0x53FA0004
.set GPT_SR,			0x53FA0008
.set GPT_IR,			0x53FA000C
.set GPT_OCR1,			0x53FA0010

@ TZIC registers addresses constants
.set TZIC_BASE,			0x0FFFC000
.set TZIC_INTCTRL,		0x0
.set TZIC_INTSEC1,		0x84 
.set TZIC_ENSET1,		0x104
.set TZIC_PRIOMASK,		0xC
.set TZIC_PRIORITY9,	0x424

.org 0x0
.section .iv,"a"

_start:

InterruptVector:
	b RESET_HANDLER

.org 0x18
	b IRQ_HANDLER

RESET_HANDLER:

	@Set interrupt table base address on coprocessor 15.
	ldr r0, =InterruptVector
	mcr p15, 0, r0, c12, c0, 0
	
	ldr r2, =SystemTime
	mov r0,#0
	str r0,[r2]

@Configurando o GPT
SET_GPT:
	
	
	@Habilitar o clock source
	ldr r2, =GPT_CR
	mov r0, #0x41
	str r0, [r2]

	@Zerando o prescaler
	ldr r2, =GPT_PR
	mov r0, #0
	str r0, [r2]

	@Colocando o valor que eu quero contar
	ldr r2, =GPT_OCR1
	mov r0, TIME_SZ
	str r0, [r2]

	@Habilitando interrupcoes
	ldr r2, =GPT_IR
	mov r0, #1
	str r0, [r2]

SET_TZIC:
	@ Liga o controlador de interrupcoes
	@ R1 <= TZIC_BASE

	ldr	r1, =TZIC_BASE

	@ Configura interrupcao 39 do GPT como nao segura
	mov	r0, #(1 << 7)
	str	r0, [r1, #TZIC_INTSEC1]

	@ Habilita interrupcao 39 (GPT)
	@ reg1 bit 7 (gpt)

	mov	r0, #(1 << 7)
	str	r0, [r1, #TZIC_ENSET1]

	@ Configure interrupt39 priority as 1
	@ reg9, byte 3

	ldr r0, [r1, #TZIC_PRIORITY9]
	bic r0, r0, #0xFF000000
	mov r2, #1
	orr r0, r0, r2, lsl #24
	str r0, [r1, #TZIC_PRIORITY9]

	@ Configure PRIOMASK as 0
	eor r0, r0, r0
	str r0, [r1, #TZIC_PRIOMASK]

	@ Habilita o controlador de interrupcoes
	mov	r0, #1
	str	r0, [r1, #TZIC_INTCTRL]

	@instrucao msr - habilita interrupcoes
	msr  CPSR_c, #0x13	   @ SUPERVISOR mode, IRQ/FIQ enabled


