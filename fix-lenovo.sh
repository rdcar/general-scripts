#!/bin/bash

# Nome do arquivo: fix_lenovo_keyboard.sh
# Descrição: Automatiza a ativação do Smart Trace Buffer para corrigir o teclado após suspensão.
# ALERTA: Este script foi desenvolvido especificamente para o Lenovo IdeaPad Slim 3 
# (Modelos 15ARP10 / Ryzen 7 7735HS) e hardware AMD Ryzen similar.

# Cores para saída de texto
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' 

echo -e "${YELLOW}=============================================================${NC}"
echo -e "${YELLOW}   CORRETOR DE TECLADO: LENOVO IDEAPAD SLIM 3 (RYZEN 7000)   ${NC}"
echo -e "${YELLOW}=============================================================${NC}"
echo -e "${RED}AVISO: Este script altera parâmetros do módulo de energia AMD.${NC}"
echo -e "${RED}Use apenas em modelos Lenovo IdeaPad Slim 3 ou similares com Ryzen.${NC}\n"

# 1. Verificação de privilégios root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Erro: Este script precisa ser executado como root (sudo).${NC}"
    exit 1
fi

# 2. Criação do arquivo de configuração do módulo
CONF_FILE="/etc/modprobe.d/amd_pmc.conf"
PARAM="options amd_pmc enable_stb=1"

echo -e "Configurando o parâmetro 'enable_stb=1' em: $CONF_FILE"

# Garante que o diretório existe e escreve o parâmetro
if echo "$PARAM" > "$CONF_FILE"; then
    echo -e "${GREEN}[OK] Arquivo de configuração criado.${NC}"
else
    echo -e "${RED}[ERRO] Falha ao criar o arquivo.${NC}"
    exit 1
fi

# 3. Atualização do initramfs
echo -e "\n${YELLOW}Atualizando o initramfs...${NC}"
echo "Isso garante que o kernel carregue a configuração durante o boot."

if command -v update-initramfs >/dev/null 2>&1; then
    if update-initramfs -u; then
        echo -e "${GREEN}[OK] initramfs atualizado com sucesso.${NC}"
    else
        echo -e "${RED}[ERRO] Falha ao atualizar initramfs.${NC}"
    fi
else
    echo -e "${YELLOW}[AVISO] 'update-initramfs' não encontrado. Se você usa Arch ou Fedora,${NC}"
    echo -e "${YELLOW}ignore este aviso ou use o comando equivalente da sua distro (ex: dracut/mkinitcpio).${NC}"
fi

# 4. Instruções finais
echo -e "\n${YELLOW}-------------------------------------------------------------${NC}"
echo -e "A configuração foi aplicada, mas ${RED}REQUER REINICIALIZAÇÃO${NC}."
echo -e "Após reiniciar, valide com o comando:"
echo -e "cat /sys/module/amd_pmc/parameters/enable_stb"
echo -e "O resultado esperado deve ser: ${GREEN}1${NC} ou ${GREEN}Y${NC}"
echo -e "${YELLOW}-------------------------------------------------------------${NC}"

read -p "Deseja reiniciar o sistema agora? (s/n): " choice
case "$choice" in 
  s|S ) echo "Reiniciando..."; reboot;;
  * ) echo "Reinicialização cancelada. Lembre-se de reiniciar manualmente.";;
esac