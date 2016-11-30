/* Giovani Nascimento Pereira - 168609
 * MC404 - Projeto 2 - Uoli / 2016/2S
 * LoCo - Segue Parede
 * Controla o Uoli de forma a encontrar uma parede e segui-la
 */

#include "api_robot2.h"
#define STOP_DISTANCE 1200

void moveForward(motor_cfg_t *m0, motor_cfg_t *m1);
void stop(motor_cfg_t *m0, motor_cfg_t *m1);
void turnRight(motor_cfg_t *m0, motor_cfg_t *m1);
void turnLeft(motor_cfg_t *m0, motor_cfg_t *m1);

void main(void){


	int a = 0;

	while(1){
		get_time(&a);
	}

/*
	motor_cfg_t m0, m1;
	unsigned int distances[16];

	//Inicializando Valores para controle do Uoli
	m0.id = 0;
	m1.id = 1;

	read_sonars(3, 4, distances);

	//Busca-Parede
	while(distances[3] > STOP_DISTANCE){
		moveForward(&m0, &m1);
		distances[3] = read_sonar(3);
	}

	//Segue-Parede
	distances[0] = read_sonar(0);
	while(distances[0] > STOP_DISTANCE){
		turnRight(&m0, &m1);
		distances[0] = read_sonar(0);
	}

	while(1){ //Repete infinitamente quando entra nessa rotina

		//Mantem o Uoli alinhado com a parede
		while(distances[0] > STOP_DISTANCE){
			turnLeft(&m0, &m1);
			distances[0] = read_sonar(0);
		}

		//Se está alinhado com a parede, move em frente
		moveForward(&m0, &m1);
		distances[0] = read_sonar(0);

	}
*/
}

/*Faz o Uoli se movimentar para a frente
 *Parametros:
 *	2 apontadores para structs do tipo motor com as ids dos motores
 *Retorno:
 *	void */
void moveForward(motor_cfg_t *m0, motor_cfg_t *m1){

	m0->speed = 35;
	m1->speed = 35;
	set_motors_speed(m0, m1);
}

/*Seta as velocidades dos motores para 0 - para o Uoli
 *Parametros:
 *	2 apontadores para structs do tipo motor com as ids dos motores
 *Retorno:
 *	void */
void stop(motor_cfg_t *m0, motor_cfg_t *m1){
	
	m0->speed = 0;
	m1->speed = 0;
	set_motors_speed(m0, m1);	
}

/*Faz o Uoli girar para a direita
 *Parametros:
 *	2 apontadores para structs do tipo motor com as ids dos motores
 *Retorno:
 *	void */
void turnRight(motor_cfg_t *m0, motor_cfg_t *m1){

	m0->speed = 10;
	m1->speed = 0;
	set_motors_speed(m0, m1);
}

/*Faz o Uoli girar para a esquerda
 *Parametros:
 *	2 apontadores para structs do tipo motor com as ids dos motores
 *Retorno:
 *	void */
void turnLeft(motor_cfg_t *m0, motor_cfg_t *m1){

	m0->speed = 0;
	m1->speed = 10;
	set_motors_speed(m0, m1);
}