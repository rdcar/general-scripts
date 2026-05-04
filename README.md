# General Scripts

Um repositório de utilitários em shell script e Python focados em automação de tarefas cotidianas, diagnóstico de redes e correções de hardware. O objetivo desta coleção é otimizar fluxos de trabalho e fornecer diagnósticos rápidos através do terminal.

---

| Script | Linguagem | Função Principal |
| :--- | :--- | :--- |
| `file-organizer.sh` | Bash | Categoriza e move arquivos em massa por extensão. |
| `fix-lenovo.sh` | Bash | Corrige travamentos de teclado após suspensão (Ryzen). |
| `organizador_pastas.py` | Python | Cria estruturas customizadas de diretórios interativamente. |
| `wifi-scanner.sh` | Bash | Escaneia redes Wi-Fi e sugere o canal com menor interferência. |

---

## Detalhamento e Uso

### 1. Organizar Downloads (`file-organizer.sh`)
Classifica arquivos de um diretório alvo e os move para subpastas baseadas em suas extensões (ex: Imagens, Documentos, Vídeos, Código). Possui proteção contra sobrescrita de arquivos com o mesmo nome e suporte a simulação.

* **Pré-requisitos:** Ambiente Linux ou macOS (Bash 4.0+).
* **Uso Básico:**
    ```bash
    ./file-organizer.sh /caminho/para/pasta
    ```
* **Parâmetros:**
    * `--dry-run` ou `-d`: Executa uma simulação, mostrando o que seria movido sem alterar nada no disco.
    * `-y`: Ignora a confirmação inicial (Assume Yes).

### 2. Corretor de Teclado Lenovo (`fix-lenovo.sh`)
**⚠️ ATENÇÃO: Uso restrito a hardwares específicos.**
Script desenvolvido para corrigir o problema onde o teclado para de funcionar após o retorno da suspensão em notebooks Lenovo IdeaPad Slim 3 (Modelos 15ARP10 / Ryzen 7 7735HS). Ele altera módulos de energia da AMD diretamente no kernel.

* **Pré-requisitos:** Acesso root (`sudo`), sistema Linux baseado em Debian/Ubuntu (para o `update-initramfs`).
* **Como usar:**
    ```bash
    sudo ./fix-lenovo.sh
    ```
* **Nota:** Será necessário reiniciar o sistema após a execução para que as alterações no *initramfs* tenham efeito.

### 3. Organizador de Pastas (`organizador_pastas.py`)
Utilitário interativo que permite a criação rápida de uma hierarquia complexa de pastas e subpastas. Valida nomes para evitar caracteres ilegais no sistema de arquivos e fornece um resumo visual antes da criação.

* **Pré-requisitos:** Python 3.6 ou superior (não requer bibliotecas externas).
* **Como usar:**
    ```bash
    python organizador_pastas.py
    ```
    Siga as instruções na tela para definir o número de diretórios, seus nomes e a profundidade de subpastas desejada.

### 4. Scanner de Redes Wi-Fi (`wifi-scanner.sh`)
Varre o ambiente em busca de redes Wi-Fi nas faixas de 2.4 GHz e 5 GHz, agrupando os dados para exibir um gráfico de barras no terminal. Ao final, analisa o congestionamento do seu canal atual e recomenda o canal mais livre disponível para melhorar a estabilidade da sua rede.

* **Pré-requisitos:**
    * **Linux:** `nmcli`, `awk`, `grep`.
    * **macOS:** `system_profiler`, `ipconfig`, `scutil` (nativos do sistema).
* **Como usar:**
    ```bash
    ./wifi-scanner.sh
    ```
* **Dica:** No macOS, execuções sem privilégios podem ocultar nomes de redes próximas devido a políticas de privacidade. Para um mapeamento completo, utilize `sudo ./wifi-scanner.sh`.
