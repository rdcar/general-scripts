#!/bin/bash
# scanner-wifi.sh — Escaneia redes Wi-Fi e sugere o melhor canal
# Uso: ./scanner-wifi.sh [opções]

set -eo pipefail

# ── Configuração de Cores (Apenas se for TTY) ──
if [ -t 1 ]; then
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    RED='\033[1;31m'
    BOLD='\033[1m'
    DIM='\033[0;90m'
    RESET='\033[0m'
else
    GREEN=''
    YELLOW=''
    RED=''
    BOLD=''
    DIM=''
    RESET=''
fi

TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

PARSED_FILE="$TMPDIR_WORK/parsed.txt"

# ── Funções de Apoio ──

show_help() {
    echo -e "${BOLD}Uso:${RESET} $0 [opções]"
    echo ""
    echo -e "Escaneia redes Wi-Fi locais, analisa o nível de congestionamento dos canais"
    echo -e "e sugere os melhores canais (menos populosos) para as bandas de 2.4 GHz e 5 GHz."
    echo ""
    echo -e "${BOLD}Opções:${RESET}"
    echo "  -h, --help    Exibe esta mensagem de ajuda e sai."
    echo ""
    echo -e "${BOLD}Dependências (Linux):${RESET} nmcli, awk, grep"
    echo -e "${BOLD}Dependências (macOS):${RESET} system_profiler, ipconfig, scutil, awk, grep"
    exit 0
}

check_dependencies() {
    local missing=0
    local deps=("awk" "grep" "wc" "paste" "sed")
    
    if [[ "$OSTYPE" == darwin* ]]; then
        deps+=("system_profiler" "ipconfig" "scutil")
    else
        deps+=("nmcli")
    fi

    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${RED}Erro: A dependência obrigatória '$cmd' não está instalada ou não está no PATH.${RESET}" >&2
            missing=1
        fi
    done

    if [ $missing -eq 1 ]; then
        echo -e "${YELLOW}Por favor, instale as ferramentas ausentes e tente novamente.${RESET}" >&2
        exit 1
    fi
}

get_current_ssid() {
    if [[ "$OSTYPE" == darwin* ]]; then
        ipconfig getsummary en0 2>/dev/null | awk -F' : ' '/^ *SSID/{print $2}' || true
    else
        nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '/^yes/{print $2}' || true
    fi
}

get_current_channel() {
    if [[ "$OSTYPE" == darwin* ]]; then
        scutil <<< "show State:/Network/Interface/en0/AirPort" 2>/dev/null | awk '/CHANNEL/{print $3; exit}' || true
    else
        # Tenta iw primeiro (mais moderno), depois cai para o iwconfig
        if command -v iw &>/dev/null; then
            iw dev 2>/dev/null | awk '/channel/{print $2; exit}' || true
        elif command -v iwconfig &>/dev/null; then
            iwconfig 2>/dev/null | awk '/Channel/{gsub(/[^0-9]/,"",$2); print $2}' || true
        fi
    fi
}

scan_networks() {
    if [[ "$OSTYPE" == darwin* ]]; then
        echo -e "  ${DIM}(Isso pode levar alguns segundos dependendo do hardware...)${RESET}"
        local profiler_out
        
        if ! profiler_out=$(system_profiler SPAirPortDataType 2>/dev/null); then
            echo -e "${RED}Erro: Falha ao executar system_profiler.${RESET}" >&2
            exit 1
        fi

        echo "$profiler_out" | awk '
            /Current Network Information:|Other Local Wi-Fi Networks:/ { capture=1; next }
            capture && /^[^ ]/ { capture=0 }
            capture && /^            [^ ].*:$/ {
                ssid=$0
                gsub(/^ +/, "", ssid)
                gsub(/ *:$/, "", ssid)
            }
            capture && /Channel:/ {
                ch=$0
                gsub(/.*Channel: */, "", ch)
                gsub(/ .*/, "", ch)
                if (ssid != "" && ch != "") {
                    print ch "|" ssid
                    ssid=""
                }
            }
        ' >> "$PARSED_FILE"
    else
        # Força rescan se tiver permissão (evita dados cacheados antigos)
        nmcli dev wifi rescan 2>/dev/null || true
        nmcli -t -f SSID,CHAN dev wifi list 2>/dev/null | while IFS=: read -r ssid chan; do
            [ -n "$chan" ] && [ "$ssid" != "--" ] && echo "${chan}|${ssid}" >> "$PARSED_FILE"
        done
    fi
}

signal_bar() {
    local count=$1
    local bar=""
    for ((i=0; i<8; i++)); do
        if [ "$i" -lt "$count" ]; then
            bar="${bar}█"
        else
            bar="${bar}░"
        fi
    done
    echo "$bar"
}

# ── Execução Principal ──

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
fi

check_dependencies

echo ""
echo -e "  ${BOLD}Escaneando redes Wi-Fi do ambiente...${RESET}"
echo ""

current_ssid=$(get_current_ssid)
current_channel=$(get_current_channel)

> "$PARSED_FILE"
scan_networks

if [[ "$OSTYPE" == darwin* ]] && grep -q "<redacted>" "$PARSED_FILE" 2>/dev/null; then
    echo -e "  ${YELLOW}Aviso: Nomes de rede ocultos pela privacidade do macOS.${RESET}"
    echo -e "  ${DIM}Para visualizar todos os SSIDs, execute o script com 'sudo'.${RESET}"
    echo ""
fi

if [ ! -s "$PARSED_FILE" ]; then
    echo -e "  ${RED}Nenhuma rede Wi-Fi encontrada.${RESET}"
    echo -e "  ${DIM}Verifique se a interface sem fio está habilitada e possui alcance.${RESET}"
    exit 1
fi

# ── Análise 2.4 GHz (1-14) ──

echo -e "  ${BOLD}Redes encontradas (Banda 2.4 GHz):${RESET}"
echo ""
printf "  %-6s %-6s %-10s %s\n" "Canal" "Redes" "Nível" "Nomes (SSID)"
printf "  %-6s %-6s %-10s %s\n" "─────" "─────" "────────" "──────────────────────────────"

best_24_ch=""
best_24_count=999

for ch in {1..14}; do
    count=$(awk -F'|' -v c="$ch" '$1 == c' "$PARSED_FILE" | wc -l | tr -d ' ')
    names=$(awk -F'|' -v c="$ch" '$1 == c {print $2}' "$PARSED_FILE" | paste -sd', ' -)

    case $ch in
        1|6|11)
            if [ "$count" -lt "$best_24_count" ]; then
                best_24_count=$count
                best_24_ch=$ch
            fi
            ;;
    esac

    if [ "$count" -eq 0 ]; then
        case $ch in
            1|6|11) ;;
            *) continue ;;
        esac
    fi

    bar=$(signal_bar "$count")

    if [ -n "$current_ssid" ] && echo "$names" | grep -Fq "$current_ssid"; then
        names=$(echo "$names" | sed "s/$(echo "$current_ssid" | sed 's/[.[\*^$]/\\&/g')/$(printf "${GREEN}%s${RESET}" "$current_ssid")/")
    fi

    if [ "$count" -ge 5 ]; then
        printf "  ${RED}%-6d %-6d %-10s${RESET} %b\n" "$ch" "$count" "$bar" "$names"
    elif [ "$count" -ge 3 ]; then
        printf "  ${YELLOW}%-6d %-6d %-10s${RESET} %b\n" "$ch" "$count" "$bar" "$names"
    elif [ "$count" -eq 0 ]; then
        printf "  %-6d %-6d %-10s ${DIM}(vazio)${RESET}\n" "$ch" "$count" "$bar"
    else
        printf "  %-6d %-6d %-10s %b\n" "$ch" "$count" "$bar" "$names"
    fi
done
echo ""

# ── Análise 5 GHz ──

has_5ghz=false
best_5_ch=""
best_5_count=999
canais_5g=(36 40 44 48 52 56 60 64 149 153 157 161 165)

for ch in "${canais_5g[@]}"; do
    if awk -F'|' -v c="$ch" '$1 == c' "$PARSED_FILE" | grep -q .; then
        has_5ghz=true
        break
    fi
done

if $has_5ghz; then
    echo -e "  ${BOLD}Redes encontradas (Banda 5 GHz):${RESET}"
    echo ""
    printf "  %-6s %-6s %-10s %s\n" "Canal" "Redes" "Nível" "Nomes (SSID)"
    printf "  %-6s %-6s %-10s %s\n" "─────" "─────" "────────" "──────────────────────────────"

    for ch in "${canais_5g[@]}"; do
        count=$(awk -F'|' -v c="$ch" '$1 == c' "$PARSED_FILE" | wc -l | tr -d ' ')
        names=$(awk -F'|' -v c="$ch" '$1 == c {print $2}' "$PARSED_FILE" | paste -sd', ' -)

        if [ "$count" -eq 0 ]; then
            if [ -z "$best_5_ch" ]; then
                best_5_ch=$ch
                best_5_count=0
            fi
            continue
        fi

        if [ "$count" -lt "$best_5_count" ]; then
            best_5_count=$count
            best_5_ch=$ch
        fi

        bar=$(signal_bar "$count")

        if [ -n "$current_ssid" ] && echo "$names" | grep -Fq "$current_ssid"; then
            names=$(echo "$names" | sed "s/$(echo "$current_ssid" | sed 's/[.[\*^$]/\\&/g')/$(printf "${GREEN}%s${RESET}" "$current_ssid")/")
        fi

        printf "  %-6d %-6d %-10s %b\n" "$ch" "$count" "$bar" "$names"
    done
    echo ""
fi

# ── Diagnóstico Final ──

echo "  ─────────────────────────────────"
echo -e "  ${BOLD}Diagnóstico:${RESET}"
echo ""

if [ -n "$current_ssid" ]; then
    echo -e "  Sua rede ativa:    ${GREEN}$current_ssid${RESET}"
else
    echo -e "  Sua rede ativa:    ${DIM}(não detectada/desconectado)${RESET}"
fi

if [ -n "$current_channel" ]; then
    current_count=$(awk -F'|' -v c="$current_channel" '$1 == c' "$PARSED_FILE" | wc -l | tr -d ' ')
    if [ "$current_count" -ge 5 ]; then
        echo -e "  Canal atual:       ${RED}$current_channel — CONGESTIONADO ($current_count redes dividindo o espaço)${RESET}"
    elif [ "$current_count" -ge 3 ]; then
        echo -e "  Canal atual:       ${YELLOW}$current_channel — MODERADO ($current_count redes dividindo o espaço)${RESET}"
    else
        echo -e "  Canal atual:       ${GREEN}$current_channel — BOM ($current_count redes dividindo o espaço)${RESET}"
    fi
fi

echo ""
echo -e "  ${BOLD}Recomendação (Menor Interferência):${RESET}"

if [ -n "$best_24_ch" ]; then
    if [ "$best_24_count" -eq 0 ]; then
        echo -e "  Canal ideal 2.4:   ${GREEN}$best_24_ch — TOTALMENTE LIVRE${RESET}"
    else
        echo -e "  Canal ideal 2.4:   ${GREEN}$best_24_ch ($best_24_count redes — opção menos congestionada)${RESET}"
    fi
fi

if [ -n "$best_5_ch" ]; then
    if [ "$best_5_count" -eq 0 ]; then
        echo -e "  Canal ideal 5 GHz: ${GREEN}$best_5_ch — TOTALMENTE LIVRE${RESET}"
    else
        echo -e "  Canal ideal 5 GHz: ${GREEN}$best_5_ch ($best_5_count redes — opção menos congestionada)${RESET}"
    fi
fi

echo "  ─────────────────────────────────"
echo ""
echo -e "  ${DIM}Para aplicar a melhoria, acesse o painel de administração do seu roteador${RESET}"
echo -e "  ${DIM}(geralmente via navegador no IP 192.168.1.1, 192.168.0.1 ou similar)${RESET}"
echo -e "  ${DIM}e altere o canal na seção de configurações da rede Wireless (Wi-Fi).${RESET}"
echo ""