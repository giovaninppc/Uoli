@ Giovani Nascimento Pereira - 168609
@ Modulo de implementacao .s 
@ Que implementa em ARM as rotinas do api_robot2.h


@ Syscalls usadas:
@	16 : read_sonar
@		Parametro: 
@			P0: identificador do read_sonar
@		Retorno: 
@			r0 distância
@
@	17 : register_proximity_callback
@		Parametros:
@			P0: identificador do sonar
@			P1: Limiar de distancia
@			P2: ponteiro para a funcao de callback
@
@	18 : set_motor_speed
@		Parametros:
@			P0: identificador do motor [0 ou 1]
@			P1: velocidade
@
@	19 : set_motors_speed
@		Parametro:
@			P0: velocidade do motor 0
@			P1: velocidade do motor 1
@
@	20 : get_time
@		Parametro: - 
@		Retorno: 
@			r0: tempo do sistema
@
@	21 : set_time
@		Parametro:
@			P0: tempo do sistema
@
@	22 : set_alarm
@		Parametro:
@			P0: ponteiro para funcao q vai ser chamada quando tocar alarme
@			P1: tempo do sistema
@		Retorno:
@			r0: -1 se maximo de alarmes ativos > MAX_ALARMS
@			  : -2 se o tempo eh invalido
@			  : 0 caso contrario

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
		push {r7, lr}	 	@Salvando registradores callee-save
	mov r1, r0				@Copia o endereco da struct para r1
	ldr r0, [r1]			@Copiando ID do motor para r0
	ldr r1, [r1, #4]		@Copiando velocidade do motor em r1

	cmp r0, #1				@Compara com 0 (ver qual motor deve alterar a velocidade)
	beq set_motor1_speed	@Salta ou nao para o set do motor especificado

set_motor0_speed:
	mov r7, #18				@Identificador da Syscall set_motor_speed
	push {r0, r1}			@Parametros da syscall: P0 = ID, P1 = Velocidade
	svc 0x0					@Faz a syscall
	b set_motor_speed_end	@Salta para o final da funcao

set_motor1_speed:
	mov r7, #18				@Identificador da Syscall set_motor_speed
	push {r0, r1}			@Parametros da syscall: P0 = ID, P1 = Velocidade
	svc 0x0					@Faz a Syscall

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
		pop {pc}			@Retorna da funcao, desempilha lr em pc



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
	mov r7, #16				@coloca o identificador da syscall em r7
	push {r0}				@Parametros syscall: P0 = ID do sonar
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
		push {r7, lr}		@Empilha registradores callee-save
	mov r7, #16				@Coloca 16 em r7, syscall read_sonar

read_sonars_loop:
	cmp r0, r1 				@Compara o valor atual com o final
	bge read_sonars_end		@Salta para o fim (ge ou hs???)
	mov r3, r0				@Copia o indice do sensor para r3

	push {r0}				@Parametros: P0 = ID do sensor
	svc 0x0					@Faz a syscall, le o sensor de indice P0
	str r0, [r2, r3, lsl #2]@Salva no apontador do vetor + (deslocamento)r3*4
	mov r0, r3				@Copia r3 em r0
	b read_sonars_loop		@Salta para o loop

read_sonars_end:
		pop {r7, pc}		@Restaura o valor de r7 e retorna




@--------------------
@ register_proximity_callback
@ ??????????????? nao sei o q isso faz

register_proximity_callback:


@--------------------
@ add_alarm

add_alarm:


@--------------------
@ get_time
@ Parametros
@	r0 = apontador para variavel q salva o tempo do sistema
@ Retorno
@	void
@ Pega valor do tempo do sistema e salva no endereco de [r0]

get_time:
		push {r7, lr}		@ Salva registradores callee-save
	mov r1, r0				@ Coloca em r1 o endereco da variavel de retorno
	mov r7, #20				@ Syscall 20 - get_time
	svc 0x0					@ Faz a syscall - retorna em r0 o tempo do sistema
	ldr r0, [r1]			@ Salva o tempo no endereco passado
		pop {r7, pc}		@ Retorna da funcao



@--------------------
@ set_time
@ Parametros:
@	r0 = o tempo t do sistema a ser setado
@ Retorno:
@	void
@ Seta o tempo do sistema para t 

set_time:
		push {r7, lr}		@ Salva registradores callee-save
	mov r7, #21				@ Coloca em r7 o numero da syscall, set_time
	push {r0}				@ Empilha t (parametro em P0)
	svc 0x0					@ Faz a syscall
		pop {r7, pc}		@ Retorna da funcao

@ Made with <3
