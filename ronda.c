/* Giovani Nascimento Pereira - 168609
 * MC404 - Projeto 2 - Uoli / 2016/2S
 * LoCo - Segue Parede
 * Controla o Uoli de forma a rondar o espaco em torno do robo
 * fazendo uma espiral quadrada (aproximadamente)
 * e desviando de paredes
 */

#include 	"api_robot2.h"
#define 	STOP_DISTANCE 500
#define 	TURN_TIME 250
#define 	TIME_DELAY 100

/*Funcoes de Movimentacao*/
void moveForward();
void stop();
void turnRight();
void turnLeft();

void f();
void g();
void desviar();

//Definindo motores para uso
motor_cfg_t m0, m1;
int t = 0;

void main(void){

	//Inicializando Valores para controle do Uoli
	m0.id = 0;
	m1.id = 1;

	//Logica da ronda - um callback para desviar de obstaculos
	//Um alarma que "seta" alarmes sequencialmente
	//  Alarme 1 (g)- Anda em linha reta por x + t tempo (incrementa t)
	//  Alarme 2 (f)- Faz uma curva para a direita
	register_proximity_callback(3, STOP_DISTANCE, desviar);
	add_alarm(g, 10);

	while(1);

}

/* FUNCAO PARA ALARME
 * Faz o Uoli fazer uma curva para a direita
 * "Seta" um alarme para faze-lo ir para frente*/
void f(){
	turnRight();
	int a;
	get_time(&a);
	add_alarm(g, a + TURN_TIME);
}

/* FUNCAO PARA ALARME
 * Faz o Uoli andar para frente
 * "Seta" um alarme para faze-lo virar*/
void g(){
	moveForward();
	int a;
	get_time(&a);
	t += 1;
	add_alarm(f, a + TIME_DELAY*t);
	
	if(t == 50)
		t = 0;	//Reinicia Ronda em 50!
}

/* FUNCAO DE PROXIMITY CALLBACK
 * Faz o Uoli desviar de uma parede
 * Depois faz ele para até a proxima execucao
 * (isso impede que gire mais que o necessario)
 * Invocada por proximity_callback*/
void desviar(){
	turnRight();
	while(read_sonar(3) < STOP_DISTANCE);
	stop();
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

/*Faz o Uoli girar para a direita
 *Parametros:
 *	2 apontadores para structs do tipo motor com as ids dos motores
 *Retorno:
 *	void */
void turnLeft(){

	m0.speed = 13;
	m1.speed = 0;
	set_motors_speed(&m0, &m1);
}

/*Faz o Uoli girar para a esquerda
 *Parametros:
 *	2 apontadores para structs do tipo motor com as ids dos motores
 *Retorno:
 *	void */
void turnRight(){

	m0.speed = 0;
	m1.speed = 13;
	set_motors_speed(&m0, &m1);
}
