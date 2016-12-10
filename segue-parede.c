/* Giovani Nascimento Pereira - 168609
 * MC404 - Projeto 2 - Uoli / 2016/2S
 * LoCo - Segue Parede
 * Controla o Uoli de forma a encontrar uma parede e segui-la
 */

#include 	"api_robot2.h"
#define 	STOP_DISTANCE 500
#define 	FOLLOW_DISTANCE 350
#define 	CLOSE_DISTANCE 300

/*Funcoes de Movimentacao*/
void moveForward();
void turnRight();
void turnLeft();
void desviar();

//Definindo motores para uso
motor_cfg_t m0, m1;

void _start(){

	//Inicializando ID dos motores
	m0.id = 0;
	m1.id = 1;

	//logica 1: Encontra parede
	//	segue em frente ate achar uma parede
	moveForward();
	while(read_sonar(3) > STOP_DISTANCE);

	//Alinha com a parede
	//	vira ate alinhar com a parede
	turnRight();
	while(read_sonar(0) > STOP_DISTANCE);

	//logica 2: Segue Parede
	//	vira para a esquerda se a frente esta longe
	//	vira ora a direita se a parte de tras esta longe
	while(1){
		while(read_sonar(1) > FOLLOW_DISTANCE){
			turnLeft();
		}
		while(read_sonar(1) < CLOSE_DISTANCE){
			turnRight();
		}
	}

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

/*Faz o Uoli girar para a direita
 *Parametros:
 *	2 apontadores para structs do tipo motor com as ids dos motores
 *Retorno:
 *	void */
void turnLeft(){

	m0.speed = 9;
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
	m1.speed = 9;
	set_motors_speed(&m0, &m1);
}

/* FUNCAO DE PROXIMITY CALLBACK
 * Faz o Uoli desviar de uma parede
 * Depois faz ele para até a proxima execucao
 * (isso impede que gire mais que o necessario)
 * Invocada por proximity_callback*/
void desviar(){
	turnRight();
	while(read_sonar(3) < STOP_DISTANCE);
}