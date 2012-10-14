#!/bin/bash
# 
# Ejemplo: 
# InstalaW5.sh
#
# DESCRIPCION: Instala el software W-FIVE
#
# Exit Codes
# 0 - Se ha instalado correctamente
# 1 - No se ha realizado la instalacion
# 2 - 

USER=`whoami`		#devuelve usuario actual del sistema
COMMAND=`ps -p $PPID -o comm=`	#obtengo nombre del comando que lo invoco
GROUP="../deploy"

INSTALAW5_CONFDIR="$GROUP/confdir"
INSTALAW5_sETUPFILE="$INSTALAW5_CONFDIR/InstalaW5.temp"
INSTALAW5_TEMPFILE="$INSTALAW5_CONFDIR/InstalaW5.conf"
INSTALAW5_LOGFILE="$INSTALAW5_CONFDIR/InstalaW5.log"		#archivo de log

INSTALAW5_STATE_COMPLETE="DONE"
INSTALAW5_STATE_INCOMPLETE="PARTIAL"
INSTALAW5_STATE_FRESHINSTALL="FRESH"


#---------- Funciones de bajo nivel ----------

## Funcion de log - CONSOLIDAR CON LoguearW5
function logOnly  {
	DATE=`date '+%x %X '` 		#devuelve la fecha del sistema dd/MM/yy hh:mm:ss
	echo "$DATE-$USER-$COMMAND-$1" >> "$INSTALAW5_LOGFILE"
}
function log {
	logOnly "$1"
	echo "$1"
}



## Funcion que verifica si existe y directorio, y sino, lo crea
function createDirIfNotExist {
	mkdir -p "$1"
}

## Muestra el mensaje de bienvenida
function hello {
	log "Comando InstalaW5 Inicio de Ejecución"
	log "TP SO7508 Segundo Cuatrimestre 2012. Tema W Copyright © Grupo 04"
}

## Obtiene los componentes que se han instalado
function getInstalledComponentsFromFile {
	log "getInstalledComponents"
}

## Espera a que el usuario ingrese S o N. Guarda el resultado en una variable llamada replyYesOrNo
function waitForYesOrNo {
	log "waitForYesOrNo"
}

#---------- Funciones de alto nivel ----------

## Comprueba que perl este instalado, y que la version sea igual o mayor a la requerida
function isPerlIstalled {
	log "Comprobando version de Perl..";
	declare required_version=5
	declare perl_version=`perl -v | sed -n 's/.*v\([0-9]*\)\.[0-9]*\.[0-9]*.*/\1/p'`
	declare errorMsg
	if [ "$perl_version" -lt "$required_version" ]
	then
		if [ -z "$perl_version" ]
		then
			log "Para instalar W-FIVE es necesario contar con Perl $required_version o superior instalado. Efectúe su instalación e inténtelo nuevamente.";
			log "Proceso de Instalación Cancelado.";
		fi
		exit 1;
	else
		errorMsg="Perl Version: $perl_version";
		log "$errorMsg";
	fi
}



## Funcion que obtiene el estado de la ultima instalacion
function getLastInstallationState {
	# Verificamos si existe el archivo de configuracion. $INSTALAW5_sETUPFILE
	# 	Si existe, obtenemos la cantidad de componentes que quedan por instalar.
	# 		Si la cantidad de componentes que quedan por installar es mayor a cero, entonces la instalacion esta incompleta.
	#		Si la cantidad de componentes que quedan por instalar es igual a cero, la instalación finalizo correctamente
	#	Si no existe el archivo, verificamos si existe el archivo de instalacion temporal $INSTALAW5_TEMPFILE
	#		Si existe y la cantidad de componentes instalados es mayor a cero, la instalacion esta incompleta
	#		Si existe y la cantidad de componentes instalados es igual a cero, la instalacion aun no empezo
	
	if [ -e "$INSTALAW5_sETUPFILE" ];
	then
		
		getInstalledComponentsFromFile "$INSTALAW5_SETUPFILE"
		
		if [[ "$notInstCount" -eq "0" ]];
		then
			lastInstallationState=$INSTALAW5_STATE_COMPLETE
		else
			lastInstallationState=$INSTALAW5_STATE_INCOMPLETE
		fi
	else
		if [ -e "$INSTALAW5_TEMPFILE" ];
		then
			getInstalledComponentsFromFile "$INSTALAW5_TEMPFILE"
			
			if [[ "$instCount" -eq "0" ]];
			then
				lastInstallationState=$INSTALAW5_STATE_FRESHINSTALL
			else
				lastInstallationState=$INSTALAW5_STATE_INCOMPLETE
			fi
		else
			# restauramos los valores por default
			#for i in ${!vars_default[*]}
			#do
			#	vars_user["$i"]="${vars_default[$i]}"
			#done

			lastInstallationState=$INSTALAW5_STATE_FRESHINSTALL
		fi
	fi	

}


## STEP 4 - Muestra la informacion de la instalacion
function showInstallInformation {
	
	GROUPFullPath=$(readlink -f "$GROUP")
	CONFDIRFullPath=$(readlink -f "$INSTALAW5_CONFDIR")

	log "Directorio de Trabajo para la instalacion: $GROUPFullPath"
	GROUPContent=`ls -c $GROUP`
	log "Contenido del directorio de trabajo: $GROUPContent"

	log "Librería del Sistema: $CONFDIRFullPath"
	CONFDIRContent=`ls -c $INSTALAW5_CONFDIR`
	log "Contenido del directorio: $CONFDIRContent"	


	log "Estado de la instalacion: PENDIENTE

	Para completar la instalación Ud. Deberá:
	
	1) Definir el directorio de instalación de los ejecutables
	2) Definir el directorio de instalación de los archivos maestros
	3) Definir el directorio de arribo de archivos externos
	4) Definir el espacio mínimo libre para el arribo de archivos externos
	5) Definir el directorio de grabación de los archivos externos rechazados
	6) Definir el directorio de grabación de los logs de auditoria
	7) Definir la extensión y tamaño máximo para los archivos de log
	8) Definir el directorio de grabación de los reportes de salida"
}

## STEP 5 - definir directorio de instalacion de ejecutables
function defineBINDir {
	# Espera por que el usuario ingrese un directorio valido

	validInput="0"
	while [ "$validInput" != "1" ] ; do

		log "Defina el directorio ($GROUP/bin):"; read userbindir
		
		if [ "$directorio" != "" ]; then
			validInput=`validarString $userbindir`
			if [ "$validInput" = "1" ]; then
				logOnly "El usuario ingreso '$GROUP$userbindir' como directorio de trabajo para 'bin'"
				BINDIR=$GROUP$userbindir;
    			else
	      			echo $validInput
				logOnly	 "$validInput"		
	   		fi
  		else
    			validInput="1"
			logOnly "El usuario quiere mantener $BINDIR como directorio para 'bin'"
  		fi
	done
}

## Setea los valores por defecto para las variables
function setDefaultValues {
	BINDIR="$GROUP/bin"
}

## Funcion principal
function startInstallWFIVE {	
	# Crea el directirio donde estaran los archivos de instalacion (configuracion y temporal), si este no existe
	createDirIfNotExist $INSTALAW5_CONFDIR

	# Inicia la instalacion
	hello

	# Verificar si es una sola instancia	

	# obtiene el estado de la ultima instalacion
	
	declare lastInstallationState
	declare installedComponents

	getLastInstallationState

	case "$lastInstallationState" in

		"$INSTALAW5_STATE_FRESHINSTALL")
			#PRE 
			setDefaultValues

			#STEP 3 Chequear que PERL este instalado
			isPerlIstalled  #Si no esta instalado, esta funcion sale con error 1
			
			#STEP 4 Brinda la informacion de la instalacion
			showInstallInformation
			
			#STEP 5 Definir BINDIR
			defineBINDir
		;;

		"$INSTALAW5_STATE_INCOMPLETE")
			# Log de archivos existentes

			# Mostrar estado de la instalacion
			log "Estado de la instalacion: INCOMPLETA"
			
			# Mostrar mensaje para continuar con la instalacion
			log "Desea completar la instalacion? (Si-No)"
			
			# Esperar la respuesta del usuario
			declare replyYesOrNo
			waitForYesOrNo

			if ( "$replyYesOrNo" == "YES")
				then
				echo "A"
			else 
				echo "B"
			fi
			
			

		;;


		"$INSTALAW5_STATE_COMPLETE")

		;;

	esac

}

#---------- Inicia el proceso de instalacion ----------

## Iniciar Instalacion
startInstallWFIVE

## por default suponemos que la instalacion termina correctamente
exit 0
