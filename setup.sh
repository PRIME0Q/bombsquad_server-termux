#!/bin/bash

termux_home="/data/data/com.termux/files/home/"
termux_bashrc="/data/data/com.termux/files/usr/etc/bash.bashrc"
root_fs="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu"
echo "beginning">$log_file

#colors
clear="\033[0m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
blue="\033[34m"
purple="\033[35m"
cyan="\033[36m"

load_animation=( '•....' '.•...' '..•..' '...•.' '....•' '...•.' '..•..' '.•...' '•....' )
load_animation2=( ' ↑↓' ' ↓↑' )
load_animation3=( ' ↑' ' ↓')
load_animation4=(  ' >' ' >>' ' >>>' ' >>>>' ' >>>>>' ' >>>>' ' >>>' ' >>' ' >' ' ' '     <' '    <<' '   <<<' '  <<<<' ' <<<<<' '  <<<<' '   <<<' '    <<' '     <' )

trap interrupt_handler SIGINT
interrupt_handler(){
	kill -KILL $$
}

animate(){
    printf "${purple}"
    while true
    do
        for i in "${load_animation4[@]}"
        do
            echo -ne "$i\033[K\r"
            sleep 0.2
        done
	done
    printf "${clear}"
}

with_animation(){
    animate &
    pid=$!
    eval "$1" &>>$log_file
    kill $pid &>>$log_file
}

run_in_proot(){
    proot-distro login ubuntu -- bash -c "$1"
}

update_ssl_certificate(){
    run_in_proot 'export DEBIAN_FRONTEND=noninteractive && apt-get install -y ca-certificates'
    run_in_proot 'export DEBIAN_FRONTEND=noninteractive && update-ca-certificates'
}


update_termux(){
    apt update &>>$log_file
    apt upgrade -o Dpkg::Options::="--force-confnew" -y &>>$log_file
    apt update &>>$log_file
}


update_ubuntu(){
    run_in_proot 'export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get upgrade -y'
}


#updating termux
printf "${red}+-+-Updating Termux packages${clear}\n">>$log_file
printf "${green}Updating Termux packages${clear}\n"
with_animation "update_termux"

#installing proot-distro
printf "${red}+-+-Installing proot-distro${clear}\n">>$log_file
printf "${green}Installing proot-distro${clear}\n"
with_animation "\$(apt-get install proot-distro -y)"

#installing proot-distro ubuntu
printf "${red}+-+-Installing proot-distro Ubuntu${clear}\n">>$log_file
printf "${green}Installing proot-distro Ubuntu${clear}\n"
with_animation "\$(proot-distro install ubuntu)"

#updating ubuntu
printf "${red}+-+-Updating ubuntu packages${clear}\n">>$log_file
printf "${green}Updating ubuntu packages${clear}\n"
with_animation "update_ubuntu"

#updating CA certificates
printf "${red}+-+-Updating ubuntu CA certificates${clear}\n">>$log_file
printf "${green}Updating ubuntu CA certificates${clear}\n"
with_animation "update_ssl_certificate" #this is a function,not a command

#writing a valid value to /etc/machine-id
printf "${red}+-+-Making /etc/machine-id in ubuntu${clear}\n">>$log_file
printf "${green}Making /etc/machine-id in ubuntu${clear}\n"
test -f $root_fs/etc/machine-id || proot-distro login ubuntu -- uuidgen>$root_fs/etc/machine-id

#adding ubuntu login cmd to bash.bashrc
printf "${red}+-+-Adding login commands to termux bashrc at ~/../usr/etc/bash.bashrc${clear}\n">>$log_file
printf "${green}Adding login command to termux bashrc\n"
login_cmd="proot-distro login ubuntu"
if grep -Fxq "$login_cmd" $termux_bashrc
then
    true
else
    printf "clear\n$login_cmd">>$termux_bashrc
fi

printf "${cyan}Finished!${clear}\n"
printf "${cyan}Finished!${clear}\n">>$log_file
proot-distro login ubuntu


