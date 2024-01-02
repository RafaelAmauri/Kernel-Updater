#!/bin/bash

# Atualizador de Kernel-Linux
# Criado pelo lusantisuper

clear
echo "Kernel Updater"
echo "Inicializando a instalação de uma nova kernel!"
echo ""
sleep 3

echo "Digite a versão da kernel que deseja instalar. Exemplo: \"5.5.13\" para baixar a \"kernel linux-5.5.13\""
read versao

echo ""
echo "Deseja salvar a kernel após a instalação? (s/n)"
echo "Se quiser marcar sim, lembre-se que a pasta que você estiver no momento não pode conter pontuações ou espaços!"
read resposta

while [ ${resposta} != "s" ] && [ ${resposta} != "n" ]
do
	echo "Por favor, escreva apenas \"s\" ou \"n\"!"
	read resposta
done

numCoresMAX=$(grep -c ^processor /proc/cpuinfo)
echo ""
echo "Seu computador tem ${numCoresMAX} cores, você deseja usar quantos durante a compilação? (1 - ${numCoresMAX})"
read numCores

while [ ${numCores} -gt ${numCoresMAX} ] || [ ${numCores} -lt 1 ]
do
		echo "Número de cores inválidos! Insira algo entre 1 - ${numCoresMAX}"
		read numCores
done


echo ""
echo "Você deseja customizar o nome da sua Kernel? (s/n)"
read customizarKernel
nomeKernel=""

while [ ${customizarKernel} != "s" ] && [ ${customizarKernel} != "n" ]
do
	echo "Por favor, escreva apenas \"s\" ou \"n\"!"
	read customizarKernel
done

#Nomeando a Kernel
if [ ${customizarKernel} = "s" ]
then
	echo ""
	echo "Qual o nome que deseja dar a sua Kernel?"
	read nomeKernel
fi

echo ""
echo "Deseja que eu instale a Kernel para você? (s/n)"
echo "Lembre-se, instalação de Kernel é algo perigoso!"
read instalarKernel

while [ ${instalarKernel} != "s" ] && [ ${instalarKernel} != "n" ]
do
	echo "Por favor, escreva apenas \"s\" ou \"n\"!"
	read instalarKernel
done

if [ ${instalarKernel} = "s" ]
then
	echo ""
	echo "Instalação de Kernel exige acesso root!"
	echo "Por favor, dê-me a permissão de sudo!"
	sudo -S echo "Requisitando a senha de root!" > /dev/null
fi

clear
echo "Começando a instalação!"
sleep 3
clear

####################### Começando o KernelUpdater #######################

pastaAtual=$(pwd)

if [ ${resposta} = "s" ]
then
	mkdir -p "${pastaAtual}/KernelUpdater-${versao}/"
	pastaInstalacao="${pastaAtual}/KernelUpdater-${versao}/"
else
	mkdir -p "/tmp/KernelUpdater-${versao}/"
	pastaInstalacao="/tmp/KernelUpdater-${versao}/"
fi

#Entrar na pasta de build
cd "${pastaInstalacao}"


#A major_version é necessária para fazer download da Kernel
grandeVersao=$(echo ${versao} | cut -f 1 -d .)
#Download da kernel
if [ ! -f "${pastaInstalacao}/linux-${versao}.tar.xz" ]
then	
	wget -v -O "${pastaInstalacao}/linux-${versao}.tar.xz" -c https://cdn.kernel.org/pub/linux/kernel/v${grandeVersao}.x/linux-${versao}.tar.xz
	echo "Arquivo baixado!"
fi

#Extraindo kernel
tar -xvJf "linux-${versao}.tar.xz"
cd ./linux-${versao}


zcat /proc/config.gz > .config

####### RECURSO PARA SER ADICIONADO! #######
#Copiando configurações do seu computador
#zcat /proc/config.gz > .configPC
#
#
#Removendo configurações que podem travar a compilação da kernel
#while read linha; do
#  if [ ${linha} = "CONFIG_LOCALVERSION" ]
#done <.configPC

#Compilando a kernel
echo ""
echo "Iniciando compilação!"
make -j${numCores}

#Movendo a Kernel gerada para a pasta inicial de instalação
cp -v arch/x86_64/boot/bzImage ../.
cd ..
mv bzImage "vmlinuz-${nomeKernel}-x86_64"
echo "Kernel renomeada para vmlinuz-${nomeKernel}-x86_64"

#Instalação da Kernel
if [ ${instalarKernel} = "s" ]
then

	#Voltar a pasta da kernel
	cd ./linux-${versao}
	
	#instalando os modulos da kernel no sistema
	sudo -S make -j${numCores} modules_install
	
	#Movendo a kernel compilada para a area de boot do sistema
	sudo -S cp -v arch/x86_64/boot/bzImage /boot/${nomeKernel}

 	#Gerando imagem de inicio e fallback para a kernel
	sudo -S mkinitcpio -k ${versao} -g "/boot/initramfs-${nomeKernel}.img"

 	#Atualizando grub
	sudo -S grub-mkconfig -o /boot/grub/grub.cfg
	
	echo "Sucesso Kernel atualizada com sucesso!"
fi
