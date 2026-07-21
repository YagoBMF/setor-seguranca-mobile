# Setor Segurança — Mobile

Versão atual: **2.1**  
Status: **teste interno — não distribuir antes da validação em Android**.

## Arquivos obrigatórios

- `SETOR_SEGURANCA_MOBILE_COMPLETO.lua` — mod principal.
- `SETOR_MOBILE_UPDATER.lua` — atualização e recuperação independentes.
- `versao.txt` — versão publicada no GitHub.

Coloque os dois arquivos `.lua` na pasta de scripts do MoonLoader mobile. Não coloque o `versao.txt` no aparelho.

## Recursos da 2.1

- Interface por diálogos nativos do SA-MP, adequada para toque.
- Ajudante, Moderador, Administrador, Coordenador e Diretor.
- Identificação automática após `/la` e bloqueio de `/setor` e `/mods` fora da staff.
- Configuração manual de emergência: `/configadm Nome 1-5`.
- Cache de RG, monitoramento e ações administrativas.
- Navegação de novatos level 0–30 e de todos os jogadores.
- Tabela de cadeia com motivo visual abreviado e motivo completo no comando.
- Regra de novatos: 50 minutos; Dark RP: 150 minutos.
- Aviso `/ac Estou telando o Player Nome` somente ao telar pelo `/reports`.
- Logs com nome e cargo do staff configurado/detectado.
- Atualização independente com backup, validação e restauração.

## Comandos principais

- `/setor` — menu principal.
- `/mods` — módulos.
- `/setorversao` — versão instalada.
- `/setoratualizar` — força o download da versão publicada.
- `/setorrollback` — restaura o último backup.
- `/configadm Nome 1-5` — configuração manual do perfil.

## Ordem de publicação

1. Envie `SETOR_SEGURANCA_MOBILE_COMPLETO.lua`.
2. Envie `SETOR_MOBILE_UPDATER.lua`.
3. Por último, altere `versao.txt` para a mesma versão interna do mod.

Essa ordem impede que aparelhos baixem uma versão antes de todos os arquivos estarem disponíveis.

## Segurança

Os webhooks atuais estão escritos dentro do script. Antes de tornar o repositório público ou distribuir amplamente, revogue os endereços expostos e crie novos webhooks.
