# ZorinOS 18 Post-Install Automation

Este script automatiza a configuração de uma instalação limpa do **ZorinOS 18 Core**, focando em produtividade, correções de hardware e segurança. 

## 🛠️ O que este script faz?

1.  **Atualização:** Sincroniza os repositórios e atualiza todos os pacotes do sistema.
2.  **Hardware (Teclado):** Oferece opções interativas para corrigir travamentos no teclado pós-suspensão (Método AMD PMC ou via GRUB com `i8042.nopnp`).
3.  **Segurança:** Configura o Firewall (UFW) para permitir o uso do KDE Connect/GSConnect.
4.  **Aplicações:** Instala uma extensa lista unificada de aplicativos via Flatpak (System-wide) e pacotes utilitários via APT (como `nala`, `neofetch` e `bpytop`).
5.  **Bateria (Lenovo):** Ativa automaticamente o modo de conservação de bateria (limita o carregamento a 80%) para dispositivos compatíveis.
6.  **Energia (Tampa):** Permite configurar de forma interativa o comportamento do notebook ao fechar a tampa (Suspender, Hibernar ou Ignorar).

## 🚀 Como Executar

Baixe o arquivo `post-install.sh`, abra o terminal na mesma pasta e execute:

```bash
chmod +x post-install.sh
sudo ./post-install.sh