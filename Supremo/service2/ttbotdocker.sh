#!/bin/bash

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to display an error message and exit
exit_with_error() {
    echo "Error: $1"
    exit 1
}

# Display a welcoming message
echo "Welcome to the TTMediaBot Configuration Script!"
echo "This script helps you set up and manage configurations for TTMediaBot."
echo "for more information, please grab link to Rexya_mr"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    exit_with_error "Please run this script with sudo."
fi

# Check if Docker, Docker Compose, and jq are installed
if ! command_exists docker || ! command_exists docker-compose || ! command_exists jq; then
    echo "Docker, Docker Compose, or jq is not installed. Updating system and installing necessary packages..."
    apt-get update && apt-get upgrade -y

    # Install only if not already installed
    command_exists docker || apt-get install -y docker.io
    command_exists docker-compose || apt-get install -y docker-compose
    command_exists jq || apt-get install -y jq
fi


# Determine current user and home directory
CURRENT_USER=$(who am i | awk '{print $1}')
HOME_DIR=$(eval echo ~"$CURRENT_USER")

# Set TTMediaBot directory
TTMEDIABOT_DIR="$HOME_DIR/TTMediaBot"

# Check if TTMediaBot directory exists
if [ ! -d "$TTMEDIABOT_DIR" ]; then
    # Clone TTMediaBot repository
    git clone https://github.com/gumerov-amir/TTMediaBot.git "$TTMEDIABOT_DIR" || exit_with_error "Failed to clone TTMediaBot repository."
fi

# Change permissions of TTMediaBot directory
sudo chown -R "$CURRENT_USER":"$CURRENT_USER" "$TTMEDIABOT_DIR" || exit_with_error "Failed to change permissions for TTMediaBot directory."

# Check and modify Python version and libmpv version in Dockerfile
DOCKERFILE="$TTMEDIABOT_DIR/Dockerfile"

PYTHON_VERSION="3.11.8"
LIBMPV_VERSION="libmpv-dev"

# Function to modify Dockerfile content
modify_dockerfile() {
    local pattern="$1"
    local replacement="$2"
    if grep -q "$pattern" "$DOCKERFILE"; then
        sed -i "s|$pattern|$replacement|" "$DOCKERFILE" || exit_with_error "Failed to modify Dockerfile."
    fi
}

# Check and modify Python version
modify_dockerfile "FROM python:3.11-slim-bullseye" "FROM python:${PYTHON_VERSION}-slim-bookworm"

# Check and modify libmpv version
modify_dockerfile "libmpv1 \\\\" "libmpv-dev \\\\"

# Check and add chmod +x ./TTMediaBot.sh in Dockerfile
if ! grep -q "RUN chmod +x ./TTMediaBot.sh" "$DOCKERFILE"; then
    sed -i '/python tools\/compile_locales.py/a RUN chmod +x ./TTMediaBot.sh' "$DOCKERFILE" || exit_with_error "Failed to add chmod +x to Dockerfile."
fi


# Determine cache file path
CACHE_FILE="$HOME_DIR/bot_cache.txt"

# Create or load cache file
touch "$CACHE_FILE" || exit_with_error "Failed to create or load cache file."

# Function to display available configurations
display_configs() {
    local count=0
    while IFS= read -r line; do
        count=$((count + 1))
        echo "$count. $line"
    done < "$CACHE_FILE"

    echo "$count"  # Output the count for use in the main script
}

# Function to delete a configuration
delete_config() {
    local config_name="$1"
    docker-compose -f "$TTMEDIABOT_DIR/docker-compose.yml" -p "$config_name" down
    rm -rf "$config_name"
    sed -i "/$config_name/d" "$CACHE_FILE"
}

# Function to restart a bot
restart_bot() {
    local config_name="$1"
    docker-compose -f "$TTMEDIABOT_DIR/docker-compose.yml" -p "$config_name" down
    docker-compose -f "$TTMEDIABOT_DIR/docker-compose.yml" -p "$config_name" up -d
    echo "Bot configuration '$config_name' restarted successfully."
}

while true; do
    echo "Please select a menu below:"
    echo "1. Create Bot."
    echo "2. Delete Bot."
    echo "3. Restart Bot."
    echo "4. Exit."

    read -p "Your choice: " choice

    case $choice in
        1)
            while true; do
                # Ask user for configuration input
                read -p "Enter directory name (e.g., config1): " CONFIG_DIR
                read -p "Enter hostname (If you run this bot on the same server, please type localhost): " hostname
                read -p "Enter TCP port: " tcp_port
                read -p "Enter UDP port: " udp_port
                while true; do
                    read -p "Enable encryption? (true/false): " encrypted
                    if [ "$encrypted" = "true" ] || [ "$encrypted" = "false" ]; then
                        break
                else
                        echo "Please enter true or false."
                    fi
                done
                read -p "Enter username: " username
                read -p "Enter password: " password
                read -p "Enter nickname (press Enter to leave blank): " nickname
                read -p "Enter channel ID: " channel_id
                read -p "Enter channel password: " channel_password
                read -p "Enter input device (e.g., 0): " input_device
                read -p "Enter output device (e.g., 1): " output_device
                if ! [[ "$input_device" =~ ^[0-9]+$ ]] || ! [[ "$output_device" =~ ^[0-9]+$ ]]; then
                    exit_with_error "Input and output devices must be numeric. Please try again."
                fi
                read -p "Enter license name (press Enter to leave blank): " license_name
                read -p "Enter license key (press Enter to leave blank): " license_key

                # Validate mandatory inputs
                if [ -z "$CONFIG_DIR" ] || [ -z "$hostname" ] || [ -z "$tcp_port" ] || [ -z "$udp_port" ] || [ -z "$username" ] || [ -z "$password" ]; then
                    exit_with_error "Mandatory inputs cannot be empty. Please try again."
                else
                    break
                fi
            done

            # Create directory and copy config_default.json
            mkdir -p "$CONFIG_DIR" || exit_with_error "Failed to create directory $CONFIG_DIR."
            cp "$TTMEDIABOT_DIR/config_default.json" "$CONFIG_DIR/config.json" || exit_with_error "Failed to copy config_default.json."

            # Update config.json with user input using jq
            jq --arg hostname "$hostname" '.teamtalk.hostname = $hostname' "$CONFIG_DIR/config.json" > tmpfile && mv tmpfile "$CONFIG_DIR/config.json"
            jq --arg tcp_port "$tcp_port" '.teamtalk.tcp_port = ($tcp_port | tonumber)' "$CONFIG_DIR/config.json" > tmpfile && mv tmpfile "$CONFIG_DIR/config.json"
            jq --arg udp_port "$udp_port" '.teamtalk.udp_port = ($udp_port | tonumber)' "$CONFIG_DIR/config.json" > tmpfile && mv tmpfile "$CONFIG_DIR/config.json"
            jq --arg username "$username" '.teamtalk.username = $username' "$CONFIG_DIR/config.json" > tmpfile && mv tmpfile "$CONFIG_DIR/config.json"
            jq --arg nickname "$nickname" '.teamtalk.nickname = $nickname' "$CONFIG_DIR/config.json" > tmpfile && mv tmpfile "$CONFIG_DIR/config.json"
            jq --arg password "$password" '.teamtalk.password = $password' "$CONFIG_DIR/config.json" > tmpfile && mv tmpfile "$CONFIG_DIR/config.json"
            jq --arg encrypted "$encrypted" '.teamtalk.encrypted = ($encrypted | test("true"; "i"))' "$CONFIG_DIR/config.json" > tmpfile && mv tmpfile "$CONFIG_DIR/config.json"
            jq --arg channel_id "$channel_id" '.teamtalk.channel = ($channel_id | tonumber)' "$CONFIG_DIR/config.json" > tmpfile && mv tmpfile "$CONFIG_DIR/config.json"
            jq --arg channel_password "$channel_password" '.teamtalk.channel_password = $channel_password' "$CONFIG_DIR/config.json" > tmpfile && mv tmpfile "$CONFIG_DIR/config.json"
            jq --arg license_name "$license_name" '.teamtalk.license_name = $license_name' "$CONFIG_DIR/config.json" > tmpfile && mv tmpfile "$CONFIG_DIR/config.json"
            jq --arg license_key "$license_key" '.teamtalk.license_key = $license_key' "$CONFIG_DIR/config.json" > tmpfile && mv tmpfile "$CONFIG_DIR/config.json"
            jq --arg input_device "$input_device" '.sound_devices.input_device = ($input_device | tonumber)' "$CONFIG_DIR/config.json" > tmpfile && mv tmpfile "$CONFIG_DIR/config.json"
            jq --arg output_device "$output_device" '.sound_devices.output_device = ($output_device | tonumber)' "$CONFIG_DIR/config.json" > tmpfile && mv tmpfile "$CONFIG_DIR/config.json"


            # Change permissions of config directory and config.json
            sudo chown -R "$CURRENT_USER":"$CURRENT_USER" "$CONFIG_DIR" || exit_with_error "Failed to change permissions for $CONFIG_DIR."

            # Check if the image ttmediabot already exists
            if ! docker image inspect ttmediabot > /dev/null 2>&1; then
                # If the image doesn't exist, build it
                docker build -t ttmediabot "$TTMEDIABOT_DIR" || exit_with_error "Failed to build Docker image."
            fi

            # Create docker-compose.yml if it doesn't exist
            if [ ! -f "$TTMEDIABOT_DIR/docker-compose.yml" ]; then
                echo "version: '3'" > "$TTMEDIABOT_DIR/docker-compose.yml"
                echo "services:" >> "$TTMEDIABOT_DIR/docker-compose.yml"
            fi

            # Check if the service configuration already exists
            if ! grep -q "ttmediabot_${CONFIG_DIR}:" "$TTMEDIABOT_DIR/docker-compose.yml"; then
                # Add the configuration to docker-compose.yml
                echo "  ttmediabot_${CONFIG_DIR}:" >> "$TTMEDIABOT_DIR/docker-compose.yml"
                echo "    image: ttmediabot" >> "$TTMEDIABOT_DIR/docker-compose.yml"
                echo "    volumes:" >> "$TTMEDIABOT_DIR/docker-compose.yml"
                echo "      - $HOME_DIR/$CONFIG_DIR:/home/ttbot/data" >> "$TTMEDIABOT_DIR/docker-compose.yml"
                echo "    command: [\"sh\", \"-c\", \"pulseaudio --start && ./TTMediaBot.sh -c data/config.json --cache data/TTMediaBotCache.dat --log data/TTMediaBot.log\"]" >> "$TTMEDIABOT_DIR/docker-compose.yml"
                if [ "$hostname" = "localhost" ]; then
                    echo "    network_mode: host" >> "$TTMEDIABOT_DIR/docker-compose.yml"
                fi
            else
                echo "Service 'ttmediabot_${CONFIG_DIR}' already defined in docker-compose.yml. Skipping..."
            fi


            # Start the container
            docker-compose -f "$TTMEDIABOT_DIR/docker-compose.yml" -p "$CONFIG_DIR" up -d || exit_with_error "Failed to start the container."

            # Update cache file
            echo "$CONFIG_DIR" >> "$CACHE_FILE" || exit_with_error "Failed to update cache file."
            echo "Bot configuration created successfully."
            ;;
        2)
            echo "Available configurations:"
            display_configs

            if [ -s "$CACHE_FILE" ]; then
                count=$(wc -l < "$CACHE_FILE") # Menghitung jumlah konfigurasi yang tersedia
                read -p "Enter the number of the configuration to delete: " delete_choice

                if [ -n "$delete_choice" ] && [ "$delete_choice" -ge 1 ] && [ "$delete_choice" -le "$count" ]; then
                    config_name=$(sed -n "${delete_choice}p" "$CACHE_FILE")
                    delete_config "$config_name"
                    echo "Bot configuration '$config_name' deleted successfully."

                    # Remove the deleted config from cache
                    sed -i "/$config_name/d" "$CACHE_FILE"
                else
                    echo "Invalid choice. Please enter a valid number."
                fi
            else
                echo "No configurations available for deletion."
            fi
            ;;
        3)
            echo "Available configurations:"
            display_configs

            if [ -s "$CACHE_FILE" ]; then
                count=$(wc -l < "$CACHE_FILE") # Menghitung jumlah konfigurasi yang tersedia
                read -p "Enter the number of the configuration to restart: " restart_choice

                if [ -n "$restart_choice" ] && [ "$restart_choice" -ge 1 ] && [ "$restart_choice" -le "$count" ]; then
                    config_name=$(sed -n "${restart_choice}p" "$CACHE_FILE")
                    restart_bot "$config_name"
                else
                    echo "Invalid choice. Please enter a valid number."
                fi
            else
                echo "No configurations available for restart."
            fi
            ;;
        4)
            echo "Exiting script."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter a valid number."
            ;;
    esac
done
