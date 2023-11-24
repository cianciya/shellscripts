#!/bin/bash

#Caminho para o arquivo de log
LOG_FILE="/usr/local/bin/scripts/update/log.txt"

#Função para registrar eventos no log
registrar_log() {
	#echo "$(date): &1" >> "$LOG_FILE"
	local mensagem="$1"
	local tipo="${2:-INFO}" 
	echo "[$(date +"%Y-%m-%d %H:%M:%S")] [$tipo] $mensagem" >> "$LOG_FILE"
}

#Função para verificar a conectvidade com a Internet
verificar_conectividade(){
	if ping -c 1 google.com &>/dev/null; then
		return 0 #Conectado
	else
		return 1 #Não conectado
	fi
}

#Aguardar até que a conexão com a internet seja estabelecida
while ! verificar_conectividade; do
	sleep 10 #Espera por 10 segundos antes de verificar novamente
done

#Verificar permissões de superusuário
if [[ $EUID -ne 0 ]]; then
	registrar_log "Erro: Este Script precisa ser executado como superusuário."
	exit 1
fi

#Verificar conectividade de rede
if ! ping -c 1 google.com &>/dev/null; then
	registrar_log "Erro: Falha na conexão de rede. Verifique sua conexão com a internet"
	exit 1
fi

#Verificar espaco em disco
ESPACO_DISPONIVEL=$(df -h / | awk 'NR==2 {print $4}')

#Verifica se o sistema é baseado em Debian ou Red Hat
if command -v apt-get &> /dev/null; then
	#Sistemas baseado em Debian (Ubunto)
	sudo apt-get update -y 
	sudo apt-get upgrade -y 

elif command -v dnf &> /dev/null; then
	#Sistema baseado em Red Hat (Fedora)
	sudo dnf check-update
	sudo dnf upgrade -y
else
	echo "Sistema não suportado pelo script."
	exit 1
fi

#Limpar pacotes antigos
apt-get autoremove -y &>> "LOG_FILE"

#Obter a quantidade em disco após a atualização
ESPACO_DEPOIS=$(df -h / | awk 'NR==2 {print$4}')

#Calcular espaco liberado
ESPACO_LIBERADO=$(echo "$ESPACO_ANTES - $ESPACO_DEPOIS" | bc)

#Obter número de pacotes atualizados
NUM_ATUALIZADOS=$(apt list --upgradable 2>/dev/null | grep -c upgradable)

#Registrar informações no log
registrar_log "Atualização concluida com sucesso"
registrar_log "Espaço de disco liberado: $ESPACO_LIBERADO"
registrar_log "Número de pacotes atualizado: $NUM_ATUALIZADOS"

exit 0

