@ Giovani Nascimento Pereira - 168609
@ Modulo de implementacao .s 
@ Que implementa em ARM as rotinas do api_robot2.h


@ Syscalls usadas:
@	125 : read_sonar
@		Parametro: 
@			r0: identificador do read_sonar
@		Retorno: 
@			r0 distância
@
@	124 : write_motors
@		Parametros:
@			r0: velocidade motor 0
@			r1: velocidade motor 1
@
@	126 : write_motor0
@		Parametros:
@			r0: velocidade do motor
@
@	127 : write_motor1
@		Parametro:
@			r0: velocidade do motor

@ Definindo Rotinas Globais

	.global set_motor_speed
	.global set_motors_speed
	.global read_sonar
	.global read_sonars
	.global register_proximity_callback
	.global add_alarm
	.global get_time
	.global set_time



@--------------------
@ set_motor_speed
@
@ Parametros:
@	r0 = apontador para struct motor
@ Retorno:
@	void 
@ seta a velocidade do motor especificado

set_motor_speed:
		push {r7, lr}		@Salvando registradores callee-save
	ldr r1, [r0]			@Copiando ID do motor para r1
	ldr r0, [r0, #4]		@Copiando velocidade do motor em r0

	cmp r1, #1				@Compara com 0 (ver qual motor deve alterar a velocidade)
	beq set_motor1_speed	@Salta ou nao para o set do motor especificado

set_motor0_speed:
	mov r7, #126			@Identificador da Syscall write_motor0
	svc 0x0					@Faz a syscall (r0 = velocidade do motor / r7 = 126)
	b set_motor_speed_end	@Salta para o final da funcao

set_motor1_speed:
	mov r7, #127			@Identificador da Syscall write_motor1
	svc 0x0					@Faz a Syscall (r0 = velocidade do motor / r7 = 127s)

set_motor_speed_end:
		pop {r7, pc}		@Retorna da funcao



@--------------------
@ set_motors_speed
@
@ Parametros:
@	r0 = apontador para struct motor
@	r1 = apontador para struct motor
@ Retorno:
@	void 
@ seta a velocidade dos motores do Uoli

set_motors_speed:
		push {lr}			@Salvando registradores callee-save
		push {r1}			@Salvando o r1 antes de chamar a funcao (caller-save)
	bl set_motor_speed 		@Salta para a funcao para setar a velocidade de um dos motores
		pop {r0}			@Pega o valor salvo, mas agora em r0
	bl set_motor_speed 		@Salta para a funcao para setar a velocidade do outro motor
		pop {pc}			@Retorna da funcao



@--------------------
@ read_sonar
@
@ Parametros:
@	r0 = sonar_id
@ Retorno:
@	unsigned short = distancia lida do sonar 
@ Le a distancia do sonar especificado

read_sonar:
		push {r7}			@Salva o registrador r7 q será usado para as Syscalls (callee-save)
	mov r7, #125			@coloca o identificador da syscall em r7
	svc 0x0					@Faz a syscall
		pop {r7}			@Restaura o valor de r7 e retorna



@--------------------
@ read_sonars
@
@ Parametros:
@	r0 = start
@	r1 = end
@	r2 = apontador para vetor de distancias (unsigned int)
@ Retorno:
@	void 
@ atualiza o vetor com as distancias dos sensores em: [start, end]

read_sonars:


@--------------------
@ register_proximity_callback
@ ??????????????? nao sei o q isso faz

register_proximity_callback:


@--------------------
@ add_alarm

add_alarm:


@--------------------
@ get_time

get_time:


@--------------------
@ set_time

set_time:




@ Made with <3