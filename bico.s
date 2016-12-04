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
	ldrb r0, [r1]			@Copiando ID do motor para r0 (unsigned char)
	ldrb r1, [r1, #1]		@Copiando velocidade do motor em r1 (unsigned char)

	cmp r0, #1				@Compara com 1 (ver qual motor deve alterar a velocidade)
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
		push {r7, lr}
	ldrb r2, [r0]			@Carregando em r2 a ID de r0
	cmp r2, #0				@Compara com 0, verifica se eh a ID do primeiro motor
	beq get_speeds			@Salta se a ID for zero (=> r0 = m0 e r1 = m1)

	mov r2, r1				@Trocando os apontadores de structs
	mov r1, r0 				@para o caso que
	mov r0, r2				@se a ID nao for zero, os motores estao trocados

get_speeds:
	ldrb r0, [r0, #1]		@Carrega em r0 a velocidade do motor 0
	ldrb r1, [r1, #1]		@Carrega em r1 a velocidade do motor 1

	push {r0, r1}			@empilha parametros
	mov r7, #19 			@svc motors
	svc 0x0					@faz a syscall

		pop {r7, pc}		@Restaura r7 e retorna da funcao

@--------------------
@ read_sonar
@
@ Parametros:
@	r0 = sonar_id
@ Retorno:
@	unsigned short = distancia lida do sonar 
@ Le a distancia do sonar especificado

read_sonar:
		push {r7, lr}		@Salva o registrador r7 q será usado para as Syscalls (callee-save)
	mov r7, #16				@coloca o identificador da syscall em r7
	push {r0}				@Parametros syscall: P0 = ID do sonar
	svc 0x0					@Faz a syscall
		pop {r7, pc}		@Restaura o valor de r7 e retorna



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
	bhs read_sonars_end		@Salta para o fim (ge ou hs???)
	mov r3, r0				@Copia o indice do sensor para r3

	push {r0}				@Parametros: P0 = ID do sensor
	svc 0x0					@Faz a syscall, le o sensor de indice P0
	lsl r3, #2 				@Multiplica por 4
	str r0, [r2, r3] 		@Salva no apontador do vetor + (deslocamento)r3*4
	lsr r3, #2 				@Divide por 4
	mov r0, r3				@Copia r3 em r0
	b read_sonars_loop		@Salta para o loop

read_sonars_end:
		pop {r7, pc}		@Restaura o valor de r7 e retorna



@--------------------
@ register_proximity_callback
@ Parametros:
@	r0 = id do sensor de proximidade (unsigned char)
@	r1 = "distancia de ativacao" (unsigned short)
@	r2 = ponteiro para funcao de callback
@
@ Registra uma funcao de callback a ser cahamda quando o sensor em r0
@ estiver a uma distancia menor que r1

register_proximity_callback:
		push {r7, lr} 		@ Salva registradores callee-save
	mov r7, #17 			@ Coloca identificador da syscall em r7
	push {r0-r2} 			@ Empilha os parametros da syscall
	svc 0x0 				@ Faz a syscall
		pop {r7, pc} 		@ Retorna da funcao


@--------------------
@ add_alarm
@ Parametros:
@	r0 = endereco da funcao f de callback
@	r1 = tempo para invocar a funcao
@ Retorno:
@	void
@ "Seta" um alarme que dispara uma funcao f 

add_alarm:
		push {r7, lr}		@ Salva registradores callee-save
	mov r7, #22				@ Coloca o numero da syscall em r7
	push {r0, r1}
	svc 0x0
		pop {r7, pc}


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
	str r0, [r1]			@ Salva o tempo no endereco passado
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
