#!/bin/bash

# ==========================================================================
# FUNÇÕES DE SUPORTE (Necessárias para as chamadas print_message e check_success)
# ==========================================================================
print_message() {
    echo -e "\n\e[1;34m[+]\e[0m $1"
}

check_success() {
    if [ $? -eq 0 ]; then
        echo -e "\e[1;32m✔ $1 concluído com sucesso.\e[0m"
    else
        echo -e "\e[1;31m✘ Erro em: $1. Verifique os logs acima.\e[0m"
    fi
}

# ==========================================================================
# 1. ATUALIZAÇÃO DO SISTEMA
# ==========================================================================
print_message "Atualizando repositórios e sistema..."
sudo apt update && sudo apt upgrade -y
check_success "Atualização do sistema"

# ==========================================================================
# 2. INSTALAÇÃO DE PACOTES APT (.DEB)
# ==========================================================================
print_message "Instalando pacotes APT selecionados..."
PACOTES_APT="ubuntu-restricted-extras amdgpu-top bpytop curl dkms gnome-tweaks nala neofetch ntp openssl syncthing ttf-mscorefonts-installer vim-common xxd fonts-roboto fonts-open-sans"

sudo apt install -y --ignore-missing $PACOTES_APT
check_success "Instalação de pacotes APT"

# ==========================================================================
# 3. CORREÇÃO DE HARDWARE (TECLADO PÓS-SUSPENSÃO)
# ==========================================================================
echo -e "\n\e[1;33m[?] O sistema apresenta problemas com o teclado perdendo a conexão após retornar da suspensão?\e[0m"
echo "Escolha o método de correção (O script continuará automaticamente em 15s se nada for digitado):"
echo "  1) Método AMD PMC (Adiciona 'amd_pmc enable_stb=1' no modprobe - Para CPUs AMD recentes)"
echo "  2) Método GRUB (Adiciona 'i8042.nopnp' nos parâmetros do kernel - Solução PS/2 genérica)"
echo "  3) Pular (Nenhuma alteração)"

read -t 15 -p "Digite a opção (1, 2 ou 3) [padrão: 3]: " choice
choice=${choice:-3}

case "$choice" in
    1)
        print_message "Configurando módulo amd_pmc (enable_stb=1)..."
        echo "options amd_pmc enable_stb=1" | sudo tee /etc/modprobe.d/amd_pmc.conf > /dev/null
        check_success "Criação do arquivo /etc/modprobe.d/amd_pmc.conf"
        
        print_message "Atualizando initramfs para aplicar alterações de módulo..."
        sudo update-initramfs -u
        check_success "Atualização do initramfs"
        ;;
    2)
        print_message "Verificando configurações do GRUB (Correção i8042.nopnp)..."
        sudo cp /etc/default/grub "/etc/default/grub.bak_$(date +%s)"
        
        if grep -q "i8042.nopnp" /etc/default/grub; then
            echo "[-] O parâmetro i8042.nopnp já está presente no GRUB. Nenhuma alteração necessária."
        else
            echo "[+] Aplicando correção i8042.nopnp para teclado/touchpad..."
            sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 i8042.nopnp"/' /etc/default/grub
            sudo update-grub
            check_success "Atualização do GRUB"
        fi
        ;;
    *)
        echo -e "\n[-] Pular selecionado (ou tempo esgotado). Nenhuma correção de hardware aplicada."
        ;;
esac

# ==========================================================================
# 4. CONFIGURAÇÃO DE FIREWALL (KDE CONNECT)
# ==========================================================================
if command -v ufw &> /dev/null; then
    print_message "Configurando firewall para KDE Connect/GSConnect..."
    sudo ufw allow 1714:1764/udp
    sudo ufw allow 1714:1764/tcp
    sudo ufw reload
    check_success "Configuração do firewall"
fi

# ==========================================================================
# 5. INSTALAÇÃO FLATPAK (SYSTEM-WIDE)
# ==========================================================================
print_message "Iniciando instalação de aplicativos Flatpak (System)..."

sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Array unificado contendo os pacotes originais e os oriundos de installed_flatpaks.sh
APPS=(
    app.drey.Warp
    app.go2tv.go2tv
    com.bitwarden.desktop
    com.calibre_ebook.calibre
    com.discordapp.Discord
    com.github.jeromerobert.pdfarranger
    com.github.johnfactotum.Foliate
    com.github.tchx84.Flatseal
    com.mattjakeman.ExtensionManager
    com.moonlight_stream.Moonlight
    com.openspeedtest.server
    com.rtosta.zapzap
    com.usebottles.bottles
    com.visualstudio.code
    io.emeric.toolblex
    io.freetubeapp.FreeTube
    io.github.flattool.Warehouse
    io.github.jonmagon.kdiskmark
    io.github.kolunmi.Bazaar
    io.github.linx_systems.ClamUI
    io.github.mmarco94.tambourine
    io.github.peazip.PeaZip
    io.github.seadve.Mousai
    io.github.thetumultuousunicornofdarkness.cpu-x
    io.github.vikdevelop.SaveDesktop
    io.gitlab.adhami3310.Impression
    io.gitlab.librewolf-community
    io.gitlab.news_flash.NewsFlash
    io.missioncenter.MissionCenter
    md.obsidian.Obsidian
    me.iepure.devtoolbox
    me.timschneeberger.GalaxyBudsClient
    net.kvirc.KVIrc
    no.mifi.losslesscut
    org.gnome.gitlab.somas.Apostrophe
    org.jdownloader.JDownloader
    org.jousse.vincent.Pomodorolm
    org.localsend.localsend_app
    org.mozilla.Thunderbird
    org.onlyoffice.desktopeditors
    org.qbittorrent.qBittorrent
    org.upnproutercontrol.UPnPRouterControl
    org.videolan.VLC
    page.kramo.Sly
    re.fossplant.songrec
)

for app in "${APPS[@]}"; do
    sudo flatpak install --system -y flathub "$app"
done

check_success "Instalação de Flatpaks unificados"

# ==========================================================================
# 6. CONSERVAÇÃO DE BATERIA LENOVO (LIMITE 80%)
# ==========================================================================
print_message "Configurando modo de conservação de bateria (limite 80%)..."
DEVICE_ID="VPC2004:00"
ACPI_PATH="/sys/bus/platform/drivers/ideapad_acpi/$DEVICE_ID"

if [ -d "$ACPI_PATH" ]; then
    echo 1 | sudo tee "$ACPI_PATH/conservation_mode" > /dev/null
    
    sudo bash -c "cat > /etc/systemd/system/battery-conservation.service <<EOF
[Unit]
Description=Enable Lenovo Battery Conservation Mode

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo 1 > $ACPI_PATH/conservation_mode'

[Install]
WantedBy=multi-user.target
EOF"

    sudo systemctl enable --now battery-conservation.service > /dev/null 2>&1
    check_success "Serviço de conservação de bateria ativado"
else
    echo -e "\e[1;33m⚠ Caminho $ACPI_PATH não encontrado. O módulo ideapad_acpi está ativo?\e[0m"
fi

# ==========================================================================
# 7. COMPORTAMENTO DA TAMPA (LID SWITCH)
# ==========================================================================
echo -e "\n\e[1;33m[?] O que o sistema deve fazer ao fechar a tampa do notebook?\e[0m"
echo "  1) Padrão (Suspender / Modo Sleep)"
echo "  2) Hibernar (Atenção: Requer SWAP configurado adequadamente)"
echo "  3) Ignorar (Não fazer nada ao fechar a tampa)"
echo "  4) Pular (Manter configuração atual do sistema)"

read -t 15 -p "Digite a opção (1, 2, 3 ou 4) [padrão: 4]: " lid_choice
lid_choice=${lid_choice:-4}

lid_action=""

case "$lid_choice" in
    1)
        print_message "Configurando para Suspender ao fechar a tampa..."
        lid_action="suspend"
        ;;
    2)
        print_message "Configurando para Hibernar ao fechar a tampa..."
        lid_action="hibernate"
        ;;
    3)
        print_message "Desabilitando qualquer ação ao fechar a tampa (Ignorar)..."
        lid_action="ignore"
        ;;
    *)
        echo -e "\n[-] Pular selecionado (ou tempo esgotado). Nenhuma alteração de energia aplicada."
        ;;
esac

if [ -n "$lid_action" ]; then
    if grep -q "^#*HandleLidSwitch=" /etc/systemd/logind.conf; then
        sudo sed -i "s/^#*HandleLidSwitch=.*/HandleLidSwitch=$lid_action/" /etc/systemd/logind.conf
    else
        echo "HandleLidSwitch=$lid_action" | sudo tee -a /etc/systemd/logind.conf > /dev/null
    fi
    check_success "Configuração do logind.conf ($lid_action)"
fi

# ==========================================================================
# FINALIZAÇÃO
# ==========================================================================
print_message "Script finalizado! Recomenda-se reiniciar o sistema para aplicar as mudanças de hardware, energia e systemd."