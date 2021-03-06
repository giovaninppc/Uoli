/* Giovani Nascimento Pereira - 168609
 * MC404 - Projeto 2 - Uoli / 2016/2S
 * LoCo - Segue Parede
 * Controla o Uoli de forma a rondar o espaco em torno do robo
 * fazendo uma espiral quadrada (aproximadamente)
 * e desviando de paredes
 */

#include 	"api_robot2.h"
#define 	STOP_DISTANCE 1000
#define 	TURN_TIME 4

/*Funcoes de Movimentacao*/
void moveForward();
void stop();
void turnRight();

/*Funcoes para a logica da ronda*/
void fazCurva();
void avanca();
void desviar();

//Definindo motores para uso
motor_cfg_t m0, m1;
int t = 0;

void _start(){

	//Inicializando Valores para controle do Uoli
	m0.id = 0;
	m1.id = 1;

	//Logica da ronda - um callback para desviar de obstaculos
	//Um alarma que "seta" alarmes sequencialmente
	//  Alarme 1 (g)- Anda em linha reta por x + t tempo (incrementa t)
	//  Alarme 2 (f)- Faz uma curva para a direita
	register_proximity_callback(3, STOP_DISTANCE, desviar);
	add_alarm(avanca, 1);

	while(1);

}

/* FUNCAO PARA ALARME
 * Faz o Uoli fazer uma curva para a direita
 * "Seta" um alarme para faze-lo ir para frente*/
void fazCurva(){

	turnRight();
	int a;
	get_time(&a);
	add_alarm(avanca, a + TURN_TIME);
}

/* FUNCAO PARA ALARME
 * Faz o Uoli andar para frente
 * "Seta" um alarme para faze-lo virar*/
void avanca(){
	moveForward();
	int a;
	get_time(&a);
	t += 1;
	add_alarm(fazCurva, a + t);
	
	if(t == 50)
		t = 0;	//Reinicia Ronda em 50!
}

/* FUNCAO DE PROXIMITY CALLBACK
 * Faz o Uoli desviar de uma parede
 * Depois faz ele andar em frente
 * Invocada por proximity_callback*/
void desviar(){
	turnRight();
	while(read_sonar(3) < STOP_DISTANCE);
	moveForward();
}


/*Faz o Uoli se movimentar para a frente
 *Parametros:
 *	2 apontadores para structs do tipo motor com as ids dos motores
 *Retorno:
 *	void */
void moveForward(){

	m0.speed = 40;
	m1.speed = 40;
	set_motors_speed(&m0, &m1);
}

/*Seta as velocidades dos motores para 0 - para o Uoli
 *Parametros:
 *	2 apontadores para structs do tipo motor com as ids dos motores
 *Retorno:
 *	void */
void stop(){
	
	m0.speed = 0;
	m1.speed = 0;
	set_motors_speed(&m0, &m1);	
}

/*Faz o Uoli girar para a Direita
 *Parametros:
 *	2 apontadores para structs do tipo motor com as ids dos motores
 *Retorno:
 *	void */
void turnRight(){

	m0.speed = 0;
	m1.speed = 13;
	set_motors_speed(&m0, &m1);
}
