#!/bin/bash

# Carrega as funções do Conda para o shell atual
# O caminho pode variar entre ~/anaconda3 ou ~/miniconda3
if [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
else
    echo "Erro: conda.sh não encontrado. Verifique o caminho da instalação do Conda."
    exit 1
fi

ENV_NAME="markitdown"

# 1. Verifica se o ambiente já existe, se não, cria
if ! conda info --envs | grep -q "$ENV_NAME"; then
    echo "--- Criando ambiente Conda: $ENV_NAME com Python 3.11 ---"
    conda create -n $ENV_NAME python=3.11 -y
else
    echo "--- Ambiente $ENV_NAME já existe ---"
fi

# 2. Ativa o ambiente
conda activate $ENV_NAME

# 3. Verifica se as bibliotecas estão instaladas (evita reinstalação demorada)
# Se o markitdown não estiver presente, instala tudo
if ! python -c "import markitdown" &> /dev/null; then
    echo "--- Instalando dependências (markitdown, markitdown-ocr, openai) ---"
    pip install markitdown[all] markitdown-ocr openai
else
    echo "--- Dependências já instaladas ---"
fi

# 4. Roda o script Python
echo "--- Iniciando processamento ---"
python main.py
