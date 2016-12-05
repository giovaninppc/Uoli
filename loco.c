/* Giovani Nascimento Pereira - 168609
 * MC404 - Projeto 2 - Uoli / 2016/2S
 * LoCo - Segue Parede
 * Controla o Uoli de forma a encontrar uma parede e segui-la
 */

#include "api_robot2.h"
#define STOP_DISTANCE 800

void moveForward();
void stop();
void turnRight();
void turnLeft();
void f();
void g();
void desviar();


motor_cfg_t m0, m1;
int t = 0;

void main(void){

	//Inicializando Valores para controle do Uoli
	m0.id = 0;
	m1.id = 1;

	//register_proximity_callback(3, STOP_DISTANCE, desviar);
	add_alarm(g, 10);

	while(1);

}

void f(){
	turnRight();
	int a;
	get_time(&a);
	add_alarm(g, a + 50);
}

void g(){
	moveForward();
	int a;
	get_time(&a);
	t += 10;
	add_alarm(f, a + 50 + t);
}

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

	m0.speed = 63;
	m1.speed = 63;
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
