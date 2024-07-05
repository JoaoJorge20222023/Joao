#!/bin/bash

function download_files() {
    wget https://github.com/Muamalaljanahi/SpamKiller/releases/download/1.1.2/SpamKiller_Ubuntu_x86_64.zip || { echo "Falha ao baixar SpamKiller!" ; exit 1; }
    wget https://www.python.org/ftp/python/3.10.13/Python-3.10.13.tgz || { echo "Falha ao baixar Python!" ; exit 1; }
    wget https://bearware.dk/teamtalk/v5.16/teamtalk-v5.16-ubuntu22-x86_64.tgz || { echo "Falha ao baixar TeamTalk!" ; exit 1; }
    wget https://bearware.dk/teamtalk/v5.16/teamtalkpro-v5.16-ubuntu22-x86_64.tgz || { echo "Falha ao baixar TeamTalk Pro!" ; exit 1; }
}

function install_dependencies_and_license() {
    read -p "Digite o nome do ambiente virtual: " venv_name
    python3 -m venv $venv_name
    source $venv_name/bin/activate
    systemctl --user enable pulseaudio && systemctl --user start pulseaudio
    git clone https://github.com/gumerov-amir/TTMediaBot.git && cd TTMediaBot && pip3 install -r requirements.txt || { echo "Falha ao clonar repositório ou instalar dependências!" ; exit 1; }
    cd tools && python3 ttsdk_downloader.py && python3 compile_locales.py || { echo "Falha ao executar scripts na pasta tools!" ; exit 1; }
    cd ..
}

function configure_bot_server() {
    mv config_default.json config.json

    # Edite o arquivo config.json
    read -p "Digite o endereço do servidor: " server_address
    read -p "Digite a porta: " port
    read -p "Digite o nick do bot: " bot_nick
    read -p "Digite o usuário do servidor: " server_user
    read -p "Digite a senha do servidor: " server_password
    read -p "Digite o canal: " channel
    read -p "Digite a senha do canal: " channel_password

    sed -i "s/\"hostname\": \"localhost\"/\"hostname\": \"$server_address\"/" config.json
    sed -i "/\"tcp_port\":/d" config.json
    sed -i "/\"udp_port\":/d" config.json
    sed -i "s/\"nickname\": \"\"/\"nickname\": \"$bot_nick\"/" config.json
    sed -i "s/\"username\": \"bot\"/\"username\": \"$server_user\"/" config.json
    sed -i "s/\"password\": \"bot\"/\"password\": \"$server_password\"/" config.json
    sed -i "s/\"channel\": \"/\"channel\": \"$channel\"/" config.json
    sed -i "s/\"channel_password\": \"\"/\"channel_password\": \"$channel_password\"/" config.json
}

function start_bot() {
    screen -dmS TTMediaBot ./TTMediaBot.sh || { echo "Falha ao iniciar TTMediaBot!" ; exit 1; }
}

function stop_bot() {
    pid=$(pidof python)
    if [ -n "$pid" ]; then
        kill $pid
        echo "Bot encerrado."
    else
        echo "Bot não está em execução."
    fi
}

function additional_commands() {
    sudo adduser --gecos "" --disabled-password bot
    echo "bot:bot" | sudo chpasswd || { echo "Falha ao definir senha para o usuário bot!" ; exit 1; }
    sudo apt-get update && sudo apt install -y libmpv-dev pulseaudio p7zip-full python3-pip git python3-venv || { echo "Falha ao instalar dependências!" ; exit 1; }
    7z x SpamKiller_Ubuntu_x86_64.zip || { echo "Falha ao extrair SpamKiller!" ; exit 1; }
    chmod 777 SpamKiller || { echo "Falha ao alterar permissões do SpamKiller!" ; exit 1; }
    tar -xzf teamtalk-v5.16-ubuntu22-x86_64.tgz || { echo "Falha ao extrair TeamTalk!" ; exit 1; }
    cd teamtalk-v5.16-ubuntu22-x86_64 || { echo "Diretório TeamTalk não encontrado!" ; exit 1; }
    tar -xzf teamtalkpro-v5.16-ubuntu22-x86_64.tgz || { echo "Falha ao extrair TeamTalk Pro!" ; exit 1; }
    cd teamtalkpro-v5.16-ubuntu22-x86_64 || { echo "Diretório TeamTalk Pro não encontrado!" ; exit 1; }
    7z x SpamKiller_Ubuntu_x86_64.zip || { echo "Falha ao extrair SpamKiller novamente!" ; exit 1; }
    cd SpamKiller || { echo "Diretório SpamKiller não encontrado!" ; exit 1; }
    ./SpamKiller || { echo "Falha ao executar o SpamKiller!" ; exit 1; }
    cd ..
}

function change_root_password() {
    echo "root:root" | sudo chpasswd || { echo "Falha ao alterar a senha do root!" ; exit 1; }
    echo "Senha do root alterada para 'root'."
}

function spamkiller_menu() {
    while true; do
        echo "Menu SpamKiller:"
        echo "1) Baixar SpamKiller"
        echo "2) Executar SpamKiller"
        echo "0) Voltar ao menu principal"

        read -p "Digite o número da opção: " option

        case $option in
            1)
                wget https://github.com/Muamalaljanahi/SpamKiller/releases/download/1.1.2/SpamKiller_Ubuntu_x86_64.zip || { echo "Falha ao baixar SpamKiller!" ; exit 1; }
                ;;
            2)
                cd SpamKiller || { echo "Diretório SpamKiller não encontrado!" ; exit 1; }
                ./SpamKiller || { echo "Falha ao executar o SpamKiller!" ; exit 1; }
                cd ..
                ;;
            0)
                break
                ;;
            *)
                echo "Opção inválida!"
                ;;
        esac

        echo "Pressione qualquer tecla para voltar ao menu SpamKiller..."
        read -n 1
        clear
    done
}

while true; do
    echo "Selecione uma opção:"
    echo "1) Baixar arquivos necessários"
    echo "2) Instalar dependências e licença do TTMediaBot"
    echo "3) Configurar o servidor do TTMediaBot"
    echo "4) Iniciar o TTMediaBot"
    echo "5) Encerrar o TTMediaBot"
    echo "6) Executar comandos adicionais"
    echo "7) Alterar senha do root"
    echo "8) Menu SpamKiller"
    echo "0) Sair"

    read -p "Digite o número da opção: " option

    case $option in
        1)
            download_files
            ;;
        2)
            install_dependencies_and_license
            ;;
        3)
            configure_bot_server
            ;;
        4)
            start_bot
            ;;
        5)
            stop_bot
            ;;
        6)
            additional_commands
            ;;
        7)
            change_root_password
            ;;
        8)
            spamkiller_menu
            ;;
        0)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida!"
            ;;
    esac

    echo "Pressione qualquer tecla para voltar ao menu inicial..."
    read -n 1
    clear
function additional_commands() {
    sudo adduser --gecos "" --disabled-password bot
    echo "bot:bot" | sudo chpasswd || { echo "Falha ao definir senha para o usuário bot!" ; exit 1; }
    sudo apt-get update && sudo apt install -y libmpv-dev pulseaudio p7zip-full python3-pip git python3-venv || { echo "Falha ao instalar dependências!" ; exit 1; }
    7z x SpamKiller_Ubuntu_x86_64.zip || { echo "Falha ao extrair SpamKiller!" ; exit 1; }
    chmod 777 SpamKiller || { echo "Falha ao alterar permissões do SpamKiller!" ; exit 1; }
    tar -xzf teamtalk-v5.16-ubuntu22-x86_64.tgz || { echo "Falha ao extrair TeamTalk!" ; exit 1; }
    cd teamtalk-v5.16-ubuntu22-x86_64 || { echo "Diretório TeamTalk não encontrado!" ; exit 1; }
    tar -xzf teamtalkpro-v5.16-ubuntu22-x86_64.tgz || { echo "Falha ao extrair TeamTalk Pro!" ; exit 1; }
    cd teamtalkpro-v5.16-ubuntu22-x86_64 || { echo "Diretório TeamTalk Pro não encontrado!" ; exit 1; }
    7z x SpamKiller_Ubuntu_x86_64.zip || { echo "Falha ao extrair SpamKiller novamente!" ; exit 1; }
    cd SpamKiller || { echo "Diretório SpamKiller não encontrado!" ; exit 1; }
    ./SpamKiller || { echo "Falha ao executar o SpamKiller!" ; exit 1; }
    cd ..
}

function change_root_password() {
    echo "root:root" | sudo chpasswd || { echo "Falha ao alterar a senha do root!" ; exit 1; }
    echo "Senha do root alterada para 'root'."
}

function spamkiller_menu() {
    while true; do
        echo "Menu SpamKiller:"
        echo "1) Baixar SpamKiller"
        echo "2) Executar SpamKiller"
        echo "0) Voltar ao menu principal"

        read -p "Digite o número da opção: " option

        case $option in
            1)
                wget https://github.com/Muamalaljanahi/SpamKiller/releases/download/1.1.2/SpamKiller_Ubuntu_x86_64.zip || { echo "Falha ao baixar SpamKiller!" ; exit 1; }
                ;;
            2)
                cd SpamKiller || { echo "Diretório SpamKiller não encontrado!" ; exit 1; }
                ./SpamKiller || { echo "Falha ao executar o SpamKiller!" ; exit 1; }
                cd ..
                ;;
            0)
                break
                ;;
            *)
                echo "Opção inválida!"
                ;;
        esac

        echo "Pressione qualquer tecla para voltar ao menu SpamKiller..."
        read -n 1
        clear
    done
}

while true; do
    echo "Selecione uma opção:"
    echo "1) Baixar arquivos necessários"
    echo "2) Instalar dependências e licença do TTMediaBot"
    echo "3) Configurar o servidor do TTMediaBot"
    echo "4) Iniciar o TTMediaBot"
    echo "5) Encerrar o TTMediaBot"
    echo "6) Executar comandos adicionais"
    echo "7) Alterar senha do root"
    echo "8) Menu SpamKiller"
    echo "0) Sair"

    read -p "Digite o número da opção: " option

    case $option in
        1)
            download_files
            ;;
        2)
            install_dependencies_and_license
            ;;
        3)
            configure_bot_server
            ;;
        4)
            start_bot
            ;;
        5)
            stop_bot
            ;;
        6)
            additional_commands
            ;;
        7)
            change_root_password
            ;;
        8)
            spamkiller_menu
            ;;
        0)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida!"
            ;;
    esac

    echo "Pressione qualquer tecla para voltar ao menu inicial..."
    read -n 1
    clear
done
