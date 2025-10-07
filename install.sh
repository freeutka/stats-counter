#!/bin/bash

if (( $EUID != 0 )); then
    printf "\033[0;33m<stats-counter> \033[0;31m[✕]\033[0m Please run this program as root \n"
    exit
fi

watermark="\033[0;33m<stats-counter> \033[0;32m[✓]\033[0m"
target_dir=""

chooseDirectory() {
    echo -e "<stats-counter> [1] /var/www/jexactyl   (choose this if you installed the panel using the official Jexactyl documentation)"
    echo -e "<stats-counter> [2] /var/www/pterodactyl (choose this if you migrated from Pterodactyl to Jexactyl)"

    while true; do
        read -p "<stats-counter> [?] Choose jexactyl directory [1/2]: " choice
        case "$choice" in
            1)
                target_dir="/var/www/jexactyl"
                break
                ;;
            2)
                target_dir="/var/www/pterodactyl"
                break
                ;;
            *)
                echo -e "\033[0;33m<stats-counter> \033[0;31m[✕]\033[0m Invalid choice. Please enter 1 or 2."
                ;;
        esac
    done
}

startPterodactyl(){
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | sudo -E bash -
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    nvm install 18 || {
        printf "${watermark} nvm command not found, trying to source nvm script directly... \n"
        . ~/.nvm/nvm.sh
        nvm install 18
    }
    
    nvm use 18
    apt update
    npm install -g pnpm@9.0.6
    corepack enable 2>/dev/null || true
    pnpm install
    
    pnpm run build || {
        printf "${watermark} Build failed, trying with legacy OpenSSL provider... \n"
        export NODE_OPTIONS=--openssl-legacy-provider
        pnpm run build
    }
    
    sudo php artisan optimize:clear
}

installModule(){
    chooseDirectory
    printf "${watermark} Installing module... \n"
    cd "$target_dir"
    rm -rvf stats-counter
    printf "${watermark} Previous module successfully removed \n"
    git clone https://github.com/freeutka/stats-counter.git
    printf "${watermark} Cloning git repository \n"
    rm -f app/Http/Controllers/Base/StatsController.php
    rm -f routes/base.php
    rm -f resources/scripts/components/elements/InformationContainer.tsx
    printf "${watermark} Previous files successfully removed \n"
    cd stats-counter
    mv resources/StatsController.php "$target_dir/app/Http/Controllers/Base/"
    mv resources/base.php "$target_dir/routes/"
    mv resources/InformationContainer.tsx "$target_dir/resources/scripts/components/elements/"
    printf "${watermark} New files successfully installed \n"
    rm -rvf "$target_dir/stats-counter"
    printf "${watermark} Git repository deleted \n"
    cd "$target_dir"

    printf "${watermark} Module fully and successfully installed in your jexactyl repository \n"

    while true; do
        read -p '<stats-counter> [?] Do you want rebuild panel assets [y/N]? ' yn
        case $yn in
            [Yy]* ) startPterodactyl; break;;
            [Nn]* ) exit;;
            * ) exit;;
        esac
    done
}

while true; do
    read -p '<stats-counter> [✓] Are you sure that you want to install "stats-counters" module [y/N]? ' yn
    case $yn in
        [Yy]* ) installModule; break;;
        [Nn]* ) printf "${watermark} Canceled \n"; exit;;
        * ) exit;;
    esac
done