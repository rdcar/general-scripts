#!/bin/bash
# organizar-downloads.sh — Organiza arquivos por tipo de extensão com esteroides
# Uso: ./organizar-downloads.sh [pasta] [--dry-run] [-y]

set -uo pipefail # Removido -e para lidar com erros de 'mv' individualmente

# Cores e Estilos
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
DIM='\033[0;90m'
BOLD='\033[1m'
RESET='\033[0m'

# Variáveis de Controle
TARGET="."
DRY_RUN=false
ASSUME_YES=false
MOVED=0
ERRORS=0

# Parsing de Argumentos
for arg in "$@"; do
    case $arg in
        --dry-run|-d) DRY_RUN=true; shift ;;
        -y) ASSUME_YES=true; shift ;;
        *) TARGET="$arg" ;;
    esac
done

TARGET="${TARGET%/}"

# Validação Inicial
if [ ! -d "$TARGET" ]; then
    echo -e "${RED}Erro:${RESET} '$TARGET' não é um diretório válido." >&2
    exit 1
fi

get_category() {
    local ext="${1,,}" # Bash 4+ tolower
    case "$ext" in
        jpg|jpeg|png|gif|bmp|svg|webp|ico|tiff|heic|heif|raw|avif) echo "Imagens" ;;
        pdf|doc|docx|xls|xlsx|ppt|pptx|odt|ods|odp|rtf|tex|epub)   echo "Documentos" ;;
        mp4|mov|avi|mkv|wmv|flv|webm|m4v|mpg|mpeg|ts)             echo "Videos" ;;
        mp3|wav|flac|aac|ogg|wma|m4a|opus|alac)                   echo "Audio" ;;
        dmg|pkg|exe|msi|deb|rpm|appimage|snap)                    echo "Instaladores" ;;
        zip|rar|7z|tar|gz|bz2|xz|tgz|zst)                         echo "Compactados" ;;
        py|js|html|css|sh|json|xml|yaml|md|csv|sql|go|rs|java|c)   echo "Codigo" ;;
        *)                                                        echo "Outros" ;;
    esac
}

# Confirmação
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}${BOLD} MODO SIMULAÇÃO (Nenhum arquivo será movido)${RESET}\n"
elif [ "$ASSUME_YES" = false ]; then
    read -p "Organizar arquivos em '$TARGET'? (y/N): " confirm
    [[ "$confirm" =~ ^[yY]$ ]] || { echo "Abortado."; exit 0; }
fi

COUNTS_FILE=$(mktemp)
trap 'rm -f "$COUNTS_FILE"' EXIT

echo -e "Escaneando ${BOLD}$TARGET${RESET}...\n"

# Loop principal
for file in "$TARGET"/*; do
    # Pular se não for arquivo, se for o próprio script ou se for oculto
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    [[ "$filename" == "."* ]] && continue
    [[ "$filename" == "$(basename "$0")" ]] && continue

    ext="${filename##*.}"
    # Se o arquivo não tem extensão, ext será igual ao filename
    [ "$filename" = "$ext" ] && category="Outros" || category=$(get_category "$ext")

    dest_dir="$TARGET/$category"
    dest_file="$dest_dir/$filename"

    # Lógica de conflito (com suporte a dry-run)
    if [ -e "$dest_file" ]; then
        base="${filename%.*}"
        suffix="${filename##*.}"
        n=1
        while [ -e "$dest_dir/$base ($n).$suffix" ]; do n=$((n + 1)); done
        dest_file="$dest_dir/$base ($n).$suffix"
    fi

    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${DIM}[SIMULADO]${RESET} $filename ${DIM}→${RESET} ${CYAN}$category/${RESET}"
        echo "$category" >> "$COUNTS_FILE"
        ((MOVED++))
    else
        mkdir -p "$dest_dir"
        if mv "$file" "$dest_file"; then
            echo -e "  ${GREEN}✔${RESET} $filename ${DIM}→${RESET} ${CYAN}$category/${RESET}"
            echo "$category" >> "$COUNTS_FILE"
            ((MOVED++))
        else
            echo -e "  ${RED}✘ Falha ao mover $filename${RESET}"
            ((ERRORS++))
        fi
    fi
done

# Sumário Final
echo -e "\n------------------------------------------"
if [ $MOVED -eq 0 ]; then
    echo -e "${YELLOW}Nenhum arquivo encontrado para organizar.${RESET}"
else
    status_msg="organizados"
    [ "$DRY_RUN" = true ] && status_msg="seriam movidos"
    
    echo -e "${GREEN}${BOLD}✓ $MOVED arquivos $status_msg!${RESET}"
    [ $ERRORS -gt 0 ] && echo -e "${RED}⚠ $ERRORS erros encontrados.${RESET}"
    echo ""
    sort "$COUNTS_FILE" | uniq -c | sort -rn | while read -r count cat; do
        printf "  %-15s %d\n" "$cat:" "$count"
    done
fi
echo -e "------------------------------------------\n"
