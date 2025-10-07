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
    nvm install node || {
        printf "${watermark} nvm command not found, trying to source nvm script directly... \n"
        . ~/.nvm/nvm.sh
        nvm install node
    }
    apt update

    npm i -g yarn
    yarn
    export NODE_OPTIONS=--openssl-legacy-provider
    yarn build:production || {
        printf "${watermark} node: --openssl-legacy-provider is not allowed in NODE_OPTIONS \n"
        export NODE_OPTIONS=
        yarn build:production
    }
    sudo php artisan optimize:clear
}

deleteModule(){
    chooseDirectory
    printf "${watermark} Deleting module... \n"
    cd "$target_dir"
    rm -rvf stats-counter
    printf "${watermark} Previous module successfully removed \n"
    git clone https://github.com/freeutka/stats-counter.git
    printf "${watermark} Cloning git repository \n"
    rm -f app/Http/Controllers/Base/StatsController.php
    rm -f routes/base.php
    rm -f resources/scripts/components/elements/InformationContainer.tsx
    printf "${watermark} Module files successfully removed \n"
    cd stats-counter
    mv original-resources/StatsController.php "$target_dir/app/Http/Controllers/Base/"
    mv original-resources/base.php "$target_dir/routes/"
    mv original-resources/InformationContainer.tsx "$target_dir/resources/scripts/components/elements/"
    printf "${watermark} Original files successfully restored \n"
    rm -rvf "$target_dir/stats-counter"
    cd "$target_dir"
    printf "${watermark} Git repository deleted \n"

    printf "${watermark} Module successfully deleted from your jexactyl repository. Thanks for using this module in your projects. Have a nice day \n"

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
    read -p '<stats-counter> [?] Are you sure that you want to delete "stats-counters" module [y/N]? ' yn
    case $yn in
        [Yy]* ) deleteModule; break;;
        [Nn]* ) printf "${watermark} Canceled \n"; exit;;
        * ) exit;;
    esac
done