# MarkItDown Local OCR & LLM Formatter

Este projeto automatiza a extração de texto de diversos formatos de arquivos (PDF, DOCX, PPTX, XLSX, Imagens) e utiliza um modelo de Inteligência Artificial local para corrigir falhas de OCR, reestruturar o conteúdo e formatá-lo em um Markdown de alta precisão.

Todo o processamento é projetado para rodar localmente (via servidores compatíveis com a API da OpenAI, como **LM Studio** ou **Ollama**), garantindo 100% de privacidade para seus documentos.

## 📋 Pré-requisitos

1. **Conda:** É necessário ter o [Anaconda](https://www.anaconda.com/) ou [Miniconda](https://docs.conda.io/en/latest/miniconda.html) instalado no seu sistema.
2. **Servidor LLM Local:** Um servidor rodando localmente que exponha uma API compatível com a OpenAI. Por padrão, o script aponta para `http://localhost:1234/v1` (porta padrão do LM Studio).
3. **Arquivos:** O documento que você deseja processar deve estar no mesmo diretório dos scripts. Extensões suportadas: `.pdf, .docx, .pptx, .xlsx, .png, .jpg, .jpeg`.

## 🚀 Como Usar

O projeto inclui um script de configuração automatizado que cria o ambiente, instala as dependências e executa o programa principal.

1. Inicie o seu servidor LLM local (ex: carregue um modelo no LM Studio e inicie o "Local Server").
2. Dê permissão de execução ao script de instalação e rode-o:

```bash
chmod +x setup.sh
./setup.sh