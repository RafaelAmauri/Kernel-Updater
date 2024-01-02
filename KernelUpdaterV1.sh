echo "Digite a versao da kernel com pontos. Ex: A kernel linux-5.5.13 seráapenas \"5.5.13\""
read version


# A major_version eh necessaria para parte da URL do kernel.org
echo ${version} > ./tmp_file
major_version=$(cut -f 1 -d . ./tmp_file)
rm ./tmp_file


# Se o diretorio nao existe, esse comando cria ele. Assim nao fica uma bagunca do tar.gz na /home na hora de extrair
if [ ! -d $HOME/build-dir-linux-${version} ]
then
	mkdir ${HOME}/build-dir-linux-${version}
fi


# Aqui eh feita a requisicao para o kernel.org com a versao da kernel desejada. O arquivo eh salvo no diretorio que foi criado antes
if [ ! -f /home/rafael/Downloads/linux-${version}.tar.xz ]
then	
	wget -v -O $HOME/build-dir-linux-${version}/linux-${version}.tar.xz -c https://cdn.kernel.org/pub/linux/kernel/v${major_version}.x/linux-${version}.tar.xz
	echo "Arquivo baixado!"
fi


# Extraindo conteudos do tarball
cd $HOME/build-dir-linux-${version}
tar -xvJf ./linux-${version}.tar.xz
cd ./linux-${version}


zcat /proc/config.gz > .config


# O make suporta paralelismo, e essa parte eh feita pra pegar quantos cores vao ser usados na compilacao
core_count=$(grep -c ^processor /proc/cpuinfo)
echo "Deseja usar os ${core_count} cores da sua CPU? [y/n]"
read answer

if [ ${answer} = "n" ]
then
	echo "Digite um numero para usar [ 1 - ${core_count} ]"
	read answer
	
	while [ ${answer} -gt ${core_count} ] || [ ${answer} -lt 1 ]
	do
		echo "Sua CPU tem apenas ${core_count} cores. Coloca um numero entre 1 e ${core_count}"
		read answer
	done

	core_count=${answer}
fi


make -j${core_count}
sudo make -j${core_count} modules_install

echo "Deseja dar um nome customizado para sua kernel? [y/n]"
read answer

if [ ${answer} = "n" ]
then
	kernel_name=${version}
else
	echo "Qual o nome customizado da kernel?"
	read kernel_name
fi

sudo cp -v arch/x86_64/boot/bzImage /boot/vmlinuz-linux-${kernel_name}


# Gerando imagem cpio para a kernel
sudo mkinitcpio -k ${version} -g "/boot/initramfs-linux-${kernel_name}.img"

# Atualizando grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "Kernel compilada e instalada com sucesso. Se quiser remover o arquivo de build, ele esta localizado em $HOME/build-dir-linux-${version}. Obrigado por usar =)"
