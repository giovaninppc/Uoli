# UoliController.MC404
Robot Uóli controller simulator.

This is part of the discipline MC404 on the second semestre of 2016 ministrated by Edson Borin at Unicamp (University of Campinas - Campinas, Brazil).

## Objetivo

Criar um código de controle, desde a parte inferior do sistema, a código de usuário para uma unidade de robo através de um simulador.
O código é dividido em três subcamadas: (a) Sistema Operacional UóLi (SOUL), (b) Biblioteca de Controle (BiCo) e (c) Lógica de Controle (LoCo).

## SOUL

Sistema Operacional do robo.
Controlaos acessos à memória, define interrupções de sistema e o acesso a periféricos.

## BiCo

Biblioteca que implementa em linguagem de montagem (ARM) as chamadas de sistema para
ser cahamdo pelo código de usuário.
Permite realizar a leitura dos sensores e a escrita de velocidades nos motores do robo.

## LoCo

Unidade em C, define as rotinas do usuário.