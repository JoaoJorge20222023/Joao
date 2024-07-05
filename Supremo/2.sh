#!/bin/bash

# Adiciona o usuário 'bot'
sudo adduser --gecos "" bot <<EOF
bot
bot
EOF

# Atualiza o sistema e instala os pacotes necessários
sudo apt-get update && sudo apt-get install -y libmpv-dev pulseaudio p7zip-full python3-pip git python3.11-venv screen

# Troca para o usuário 'bot'
sudo su - bot <<'EOSU'

# Verifica se estamos na pasta /home/bot, se não, vá para lá
if [ "$PWD" != "/home/bot" ]; then
  cd /home/bot
fi

# Habilita e inicia o pulseaudio
systemctl --user enable pulseaudio && systemctl --user start pulseaudio

# Clona o repositório e instala as dependências
git clone https://github.com/gumerov-amir/TTMediaBot.git && cd TTMediaBot
pip install --break-system-packages babel beautifulsoup4 patool portalocker pydantic pyshorteners requests vk-api yandex_music youtube-search-python yt-dlp

# Executa os scripts na pasta tools
cd tools && python3 ttsdk_downloader.py && python3 compile_locales.py

# Renomeia o arquivo de configuração
cd .. && mv config_default.json config.json

EOSU

# Abre o config.json para edição
echo "Por favor, edite o arquivo /home/bot/TTMediaBot/config.json com as seguintes informações:"
echo "1. Endereço do servidor (hostname)"
echo "2. Portas TCP/UDP (tcp_port, udp_port)"
echo "3. Encriptado (encrypted)"
echo "4. Nome do bot (nickname)"
echo "5. Nome de usuário do TT (username)"
echo "6. Senha do TT (password)"
echo "7. Nome da licença (license_name)"
echo "8. Chave da licença (license_key)"

sudo nano /home/bot/TTMediaBot/config.json

# Inicia o bot com screen
sudo su - bot <<'EOSU'
cd /home/bot/TTMediaBot
screen -dmS TTMediaBot ./TTMediaBot.sh
EOSU

echo "Setup completo. O bot está rodando em uma sessão screen."
