import os
import sys
from markitdown import MarkItDown
from openai import OpenAI

def selecionar_modelo_e_url():
    # 1. Pergunta a URL do servidor
    default_url = "http://localhost:1234/v1"
    print(f"\n--- Configuração do Servidor Local ---")
    url = input(f"Digite a Base URL do servidor [Padrão: {default_url}]: ").strip()
    if not url:
        url = default_url

    client = OpenAI(base_url=url, api_key="not-needed")

    # 2. Busca os modelos disponíveis no endpoint
    try:
        print(f"Conectando a {url}...")
        models = client.models.list()
        model_list = [m.id for m in models.data]
        
        if not model_list:
            print("Nenhum modelo encontrado no servidor.")
            sys.exit(1)
        
        print("\nModelos disponíveis:\n")
        for i, model_name in enumerate(model_list):
            print(f"[{i}] {model_name}")

        # 3. Usuário escolhe o modelo
        choice = int(input(f"\nEscolha o número do modelo (0-{len(model_list)-1}): "))
        selected_model = model_list[choice]
        
        return client, selected_model

    except Exception as e:
        print(f"Erro ao conectar ou listar modelos: {e}")
        sys.exit(1)

# 1. Configuração da LLM
client, modelo_escolhido = selecionar_modelo_e_url()

# 2. Listar arquivos no diretório atual
# Filtramos por extensões comuns que o MarkItDown processa bem
extensoes_suportadas = ('.pdf', '.docx', '.pptx', '.xlsx', '.png', '.jpg', '.jpeg')
arquivos_locais = [f for f in os.listdir('.') if f.lower().endswith(extensoes_suportadas)]

if not arquivos_locais:
    print(f"\nErro: Nenhum arquivo compatível {extensoes_suportadas} encontrado no diretório.")
    sys.exit(1)

print("\nArquivos encontrados no diretório:")
for i, arquivo in enumerate(arquivos_locais):
    print(f"[{i}] {arquivo}")

try:
    escolha_arq = int(input(f"\nEscolha o número do arquivo para processar (0-{len(arquivos_locais)-1}): "))
    pdf_file = arquivos_locais[escolha_arq]
except (ValueError, IndexError):
    print("Escolha inválida. Encerrando.")
    sys.exit(1)

# Inicializa MarkItDown
md = MarkItDown(enable_plugins=True, llm_client=client, llm_model=modelo_escolhido)

print(f"\n[1/3] Extraindo conteúdo bruto de '{pdf_file}'...")
result = md.convert(pdf_file)
texto_bruto = result.text_content

print(f"[2/3] Refinando Markdown usando o modelo: {modelo_escolhido}...")
try:
    response = client.chat.completions.create(
        model=modelo_escolhido,
        messages=[
            {
                "role": "system", 
                "content": (
    "You are an expert in document structuring and high-precision Markdown. "
    "Your task is to clean the text extracted by OCR, following these strict rules:\n\n"
    "1. STRUCTURE: Identify titles and subtitles and apply the correct hierarchy (#, ##, ###).\n"
    "2. CLEANING: Correct broken words (end-of-line hyphenation), remove random characters "
    "typical of OCR errors, and merge paragraphs that were improperly split.\n"
    "3. TABLES AND LISTS: Reconstruct tables using standard Markdown format and recover "
    "bullet points with correct hierarchy (structuring), ensuring the indentation makes logical sense.\n"
    "4. FIDELITY: Do not summarize or add interpretations. Maintain the original text, "
    "only improving readability and formatting.\n"
    "5. FORMATTING: Use bold to emphasize key terms if the original context suggests it.\n"
    "6. OUTPUT: Respond ONLY with the formatted text, without any introductions or explanations."
)
            },
            {"role": "user", "content": texto_bruto}
        ]
    )

    texto_final = response.choices[0].message.content

    # 5. Salvar resultado
    output_name = "formatted_output_document.md"
    with open(output_name, "w", encoding="utf-8") as f:
        f.write(texto_final)

    print(f"[3/3] Sucesso! Resultado salvo em: {output_name}")

except Exception as e:
    print(f"Erro durante o refinamento da LLM: {e}")
