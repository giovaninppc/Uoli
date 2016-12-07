/* Giovani Nascimento Pereira - 168609
 * MC404 - Projeto 2 - Uoli / 2016/2S
 * LoCo - Segue Parede
 * Controla o Uoli de forma a encontrar uma parede e segui-la
 */

#include 	"api_robot2.h"
#define 	STOP_DISTANCE 500
#define 	FOLLOW_DISTANCE 400
#define 	CLOSE_DISTANCE 320

/*Funcoes de Movimentacao*/
void moveForward();
void stop();
void turnRight();
void turnLeft();
void moveForwardSlowly();
void desviar();

//Definindo motores para uso
motor_cfg_t m0, m1;

void main(){

	//Inicializando ID dos motores
	m0.id = 0;
	m1.id = 0;
	//register_proximity_callback(3, STOP_DISTANCE, desviar);

	//logica 1: Encontra parede
	moveForward();
	while(read_sonar(3) > STOP_DISTANCE);

	//Alinha com a parede
	turnRight();
	while(read_sonar(0) > STOP_DISTANCE);

	//logica 2: Segue Parede
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

 /*Faz o Uoli se movimentar para a frente MAIS DEVAGAR
 *Parametros:
 *	2 apontadores para structs do tipo motor com as ids dos motores
 *Retorno:
 *	void */
void moveForwardSlowly(){

	m0.speed = 10;
	m1.speed = 10;
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
	//stop();
}