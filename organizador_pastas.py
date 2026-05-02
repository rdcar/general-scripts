"""
Organizador de Pastas
Programa para criar pastas e subpastas personalizadas para organização de arquivos
"""

import os
import sys
from pathlib import Path


def limpar_tela():
    """Limpa a tela do terminal"""
    os.system('cls' if os.name == 'nt' else 'clear')


def exibir_cabecalho():
    """Exibe o cabeçalho do programa"""
    print("=" * 60)
    print(" ORGANIZADOR DE PASTAS ".center(60, "="))
    print("=" * 56 + "v1.0")
    print()


def obter_numero_valido(mensagem, min_val=1):
    """Obtém um número válido do usuário"""
    while True:
        try:
            valor = int(input(mensagem))
            if valor < min_val:
                print(f"⚠️  Por favor, digite um número maior ou igual a {min_val}.")
            else:
                return valor
        except ValueError:
            print("⚠️  Por favor, digite um número válido.")


def validar_nome_pasta(nome):
    """Valida o nome da pasta"""
    caracteres_invalidos = ['/', '\\', ':', '*', '?', '"', '<', '>', '|']
    
    if not nome or nome.strip() == "":
        return False, "Nome não pode estar vazio"
    
    for char in caracteres_invalidos:
        if char in nome:
            return False, f"Nome contém caractere inválido: '{char}'"
    
    return True, ""


def criar_estrutura_pastas():
    """Função principal para criar a estrutura de pastas"""
    limpar_tela()
    exibir_cabecalho()
    
    # Obtém o diretório onde o script está localizado
    diretorio_atual = Path.cwd()
    print(f"📁 Diretório de trabalho: {diretorio_atual}\n")
    
    # Pergunta quantas pastas principais criar
    num_pastas = obter_numero_valido("Quantas pastas principais você deseja criar? ")
    print()
    
    pastas_criadas = []
    
    for i in range(1, num_pastas + 1):
        print(f"\n--- PASTA {i} de {num_pastas} ---")
        
        # Nome da pasta principal
        while True:
            nome_pasta = input(f"Digite o nome da pasta {i}: ").strip()
            valido, mensagem = validar_nome_pasta(nome_pasta)
            
            if valido:
                break
            else:
                print(f"⚠️  {mensagem}. Tente novamente.")
        
        # Pergunta se deseja criar subpastas
        criar_sub = input("Deseja criar subpastas dentro desta pasta? (s/n): ").strip().lower()
        
        subpastas = []
        if criar_sub == 's':
            num_subpastas = obter_numero_valido("Quantas subpastas? ", 1)
            
            for j in range(1, num_subpastas + 1):
                while True:
                    nome_subpasta = input(f"  └─ Nome da subpasta {j}: ").strip()
                    valido, mensagem = validar_nome_pasta(nome_subpasta)
                    
                    if valido:
                        subpastas.append(nome_subpasta)
                        break
                    else:
                        print(f"  ⚠️  {mensagem}. Tente novamente.")
        
        pastas_criadas.append({
            'nome': nome_pasta,
            'subpastas': subpastas
        })
    
    # Confirma antes de criar
    print("\n" + "=" * 60)
    print(" RESUMO DA ESTRUTURA A SER CRIADA ".center(60, "="))
    print("=" * 60)
    
    for pasta in pastas_criadas:
        print(f"\n📁 {pasta['nome']}/")
        for subpasta in pasta['subpastas']:
            print(f"   └─ 📁 {subpasta}/")
    
    print("\n" + "=" * 60)
    confirmar = input("\nDeseja criar esta estrutura? (s/n): ").strip().lower()
    
    if confirmar == 's':
        print("\n🔄 Criando estrutura de pastas...\n")
        
        sucesso = True
        for pasta in pastas_criadas:
            caminho_pasta = diretorio_atual / pasta['nome']
            
            try:
                # Cria a pasta principal
                caminho_pasta.mkdir(exist_ok=True)
                print(f"✅ Pasta criada: {pasta['nome']}")
                
                # Cria as subpastas
                for subpasta in pasta['subpastas']:
                    caminho_subpasta = caminho_pasta / subpasta
                    caminho_subpasta.mkdir(exist_ok=True)
                    print(f"   ✅ Subpasta criada: {pasta['nome']}/{subpasta}")
                    
            except PermissionError:
                print(f"❌ Erro: Sem permissão para criar '{pasta['nome']}'")
                sucesso = False
            except Exception as e:
                print(f"❌ Erro ao criar '{pasta['nome']}': {str(e)}")
                sucesso = False
        
        if sucesso:
            print("\n✨ Estrutura de pastas criada com sucesso!")
        else:
            print("\n⚠️  Algumas pastas não puderam ser criadas.")
    else:
        print("\n❌ Operação cancelada.")
    
    return pastas_criadas


def menu_principal():
    """Menu principal do programa"""
    while True:
        limpar_tela()
        exibir_cabecalho()
        
        print("OPÇÕES:")
        print("1. Criar nova estrutura de pastas")
        print("2. Listar pastas do diretório atual")
        print("3. Sair")
        print()
        
        opcao = input("Escolha uma opção (1-3): ").strip()
        
        if opcao == '1':
            criar_estrutura_pastas()
            input("\nPressione ENTER para continuar...")
            
        elif opcao == '2':
            limpar_tela()
            exibir_cabecalho()
            print("📁 PASTAS NO DIRETÓRIO ATUAL:\n")
            
            diretorio_atual = Path.cwd()
            pastas = [p for p in diretorio_atual.iterdir() if p.is_dir()]
            
            if pastas:
                for pasta in sorted(pastas):
                    print(f"  📁 {pasta.name}")
                    # Lista subpastas (apenas 1 nível)
                    subpastas = [s for s in pasta.iterdir() if s.is_dir()]
                    for subpasta in sorted(subpastas):
                        print(f"     └─ 📁 {subpasta.name}")
            else:
                print("  Nenhuma pasta encontrada.")
            
            input("\nPressione ENTER para continuar...")
            
        elif opcao == '3':
            print("\n👋 Obrigado por usar o Organizador de Pastas!")
            sys.exit(0)
            
        else:
            print("⚠️  Opção inválida. Tente novamente.")
            input("Pressione ENTER para continuar...")


if __name__ == "__main__":
    try:
        menu_principal()
    except KeyboardInterrupt:
        print("\n\n❌ Programa interrompido pelo usuário.")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Erro inesperado: {str(e)}")
        sys.exit(1)
