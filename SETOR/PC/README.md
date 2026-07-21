# Setor Advanced - PC

## Arquivos obrigatorios

- `SETOR_SEG.lua`: mod principal.
- `SETOR_UPDATER.lua`: atualizador e recuperador independente.
- `versao.txt`: versao publica mais recente.

Na primeira instalacao, coloque `SETOR_SEG.lua` e `SETOR_UPDATER.lua` dentro da pasta `moonloader`. Depois disso, o atualizador independente cuida das novas versoes do mod principal.

## Publicar uma atualizacao

1. Teste o `SETOR_SEG.lua` localmente.
2. Atualize o campo `versao` dentro de `SETOR_SEG.lua`.
3. Envie primeiro o novo `SETOR_SEG.lua` ao GitHub.
4. Confirme no link raw que o codigo publicado contem a nova versao.
5. Somente depois altere `versao.txt` para o mesmo numero.

Essa ordem impede que os jogadores recebam uma versao anunciada antes de o arquivo correto estar disponivel.

## Protecoes

O `SETOR_UPDATER.lua`:

- ignora cache antigo do GitHub;
- tenta o download ate tres vezes;
- verifica se `versao.txt` e `SETOR_SEG.lua` correspondem;
- compila o Lua antes da instalacao;
- valida um arquivo temporario antes de substituir;
- mantem `SETOR_SEG.lua.bak` para recuperacao.

## Comandos

- `/setorversao`: mostra a versao e consulta atualizacoes.
- `/setoratualizar`: baixa novamente a versao publicada.
- `/setorrollback`: restaura o ultimo backup valido.

Depois de instalar uma atualizacao ou restaurar um backup, reinicie completamente o GTA.
