-- SETOR SEGURANCA - MOBILE
-- Baseado na versao mobile validada e nas funcoes da versao PC.

local samp = require 'samp.events'
local requests = require 'requests'
local inicfg = require 'inicfg'

local VERSION = '2.0'
local CONFIG_FILE = 'SetorSeguranca.ini'
local CACHE_FILE = 'hz_rg_cache_mobile.txt'
local MONITOR_FILE = 'hz_monitorados_mobile.txt'
local UPDATE_VERSION_URL = 'https://raw.githubusercontent.com/YagoBMF/setor-seguranca-mobile/main/SETOR/MOBILE/versao.txt'
local UPDATE_SCRIPT_URL = 'https://raw.githubusercontent.com/YagoBMF/setor-seguranca-mobile/main/SETOR/MOBILE/SETOR_SEGURANCA_MOBILE_COMPLETO.lua'

local WEBHOOKS = {
    LOG = 'https://discord.com/api/webhooks/1472343208477593822/AsrnjXuzTjPhPZM_W9QDmGylJ6uPL5mJZJyheDwFB1FzAYO82jrrV1VBor4Xkh1d0KO0',
    BAN = 'https://discord.com/api/webhooks/1472343861719339212/BbCTngmkr9YZH5W7PiCVx_IjhC6eboyI072MlddFaGUzQ39i1g9FXI0AcgIJavP3dzdo',
    CADEIA = 'https://discord.com/api/webhooks/1472343962797998090/0zYDFcEW_q7pfrtMYmwk2_hijr33Bb_tS-GyXktfwg3Uvj1ZzAlMtgXk-VX5S5uBlGVU',
    MUTE = 'https://discord.com/api/webhooks/1472344170520907939/BTLBSNDhp054jKOLU7_3Q-eXunG4SM3g2K7uhRKv_3wIaKgp997daaLxwvLh2sYbJfUV',
    TAPA = 'https://discord.com/api/webhooks/1519098721806192697/bah3dfhfZD29fJQeOf21awLF9WkcN8pkf1wITxFXDMjl2KXB2fjGg3fs7DoOyZjd2VU5',
    TRAZER = 'https://discord.com/api/webhooks/1519098792794656979/5xs6w4tv_CYyw0UN4BgjH1HBie9VgNuHUZMc_cfJFkXzJl5a-Fjfr3vaEzZMMBGG4AY1',
    IR = 'https://discord.com/api/webhooks/1519098786343817501/mmohOhvvFt8HtM8oFCDC7v4PzvEAh9yQCQ8sdVeOVsrrrGZyPTTJzVtHB6Wrdj_DknHT',
    CONGELAR = 'https://discord.com/api/webhooks/1519123580041035849/-HJzL4KKnS6sYqL3wssbAvsU54kCcSbaHrAfdZIJSJ2WfzoUz325I4bLdi-N1RQCX8sP',
    DESCONGELAR = 'https://discord.com/api/webhooks/1519123575108272268/Wj1tYTA4RQmpt_jIx8HtlNzuzed3DgQyAEVaYY94otiCTR9IfhWnMHqO_K9laLwAFYIe',
    PRENDERARMAS = 'https://discord.com/api/webhooks/1519149792872108062/Nfnx7YOtGbBcDYvAbV3K9Uns6yiwZEWmgWWfLqXt0u68ejT4FOYG8HvjLxgIYFu_n6xB',
    SETVIDA = 'https://discord.com/api/webhooks/1519338573218840728/eiMlWVsK_0FqTHL-AwDNDFj0tICtgbkmqOlSN1dyaFCh-VOfQlvWfKCfDP49Kh-_iGjN',
    SETCOLETE = 'https://discord.com/api/webhooks/1519341309121269921/Jeb-TRF1I2zj3rrfwqx3pGSTGEdKYiHWHhFKW-dBf2hwiXZRtFmQZjusZjwFu2LsOFfJ',
    REVIVER = 'https://discord.com/api/webhooks/1519353929492860968/FjWWaoy1g2F3Jf05XzRFCe84L4ZZOczEsvD9FAAtR_ZhTclMxp14agsXIhgZG3dudTGH'
}

local cfg = inicfg.load({
    dados = { nome = 'Vazio', cargo = 'Vazio' },
    modulos = { logs = true, monitoramento = true, navegacao = true, atalhos = true }
}, CONFIG_FILE)

local cache, monitorados = {}, {}
local rgAtual, nickAtual = nil, nil
local pendente = nil
local navNovato, navTodos = 0, 0

-- Dialogos locais (faixa alta para evitar conflito com dialogos comuns do servidor)
local D_MAIN = 28000
local D_TV = 28001
local D_ACOES = 28002
local D_RG = 28003
local D_MONITOR = 28004
local D_MODULOS = 28005
local D_INPUT_ACAO = 28010
local D_INPUT_RG_BUSCA = 28011
local D_INPUT_RG_DEL = 28012
local D_INPUT_MONITOR = 28013
local D_INPUT_DESMONITOR = 28014
local D_PUNICOES = 28015
local D_INPUT_PUNICAO = 28016
local dialogAction = nil

local function chat(cor, texto)
    sampAddChatMessage(cor .. '[SETOR]: {FFFFFF}' .. tostring(texto), -1)
end

local function trim(s)
    return tostring(s or ''):match('^%s*(.-)%s*$')
end

local function clean(s)
    return tostring(s or ''):gsub('{%x%x%x%x%x%x}', ''):gsub('~.-~', '')
end

local function jsonEscape(s)
    return tostring(s or ''):gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\r', '\\r'):gsub('\n', '\\n')
end

local function perfilOk()
    if cfg.dados.nome ~= 'Vazio' then return true end
    chat('{FF5555}', 'Perfil nao configurado. Use /configadm Nome 1 ou /configadm Nome 2.')
    return false
end

local function responseBody(res)
    if type(res) ~= 'table' then return nil end
    return res.text or res.body or res.data
end

local function versaoMaior(remota, localAtual)
    local r, l = {}, {}
    for n in tostring(remota or ''):gmatch('%d+') do r[#r + 1] = tonumber(n) or 0 end
    for n in tostring(localAtual or ''):gmatch('%d+') do l[#l + 1] = tonumber(n) or 0 end
    for i = 1, math.max(#r, #l) do
        local rv, lv = r[i] or 0, l[i] or 0
        if rv > lv then return true end
        if rv < lv then return false end
    end
    return false
end

local function obterVersaoRemota()
    local ok, res = pcall(requests.get, UPDATE_VERSION_URL)
    if not ok then return nil end
    local body = responseBody(res)
    return body and trim(body):match('([%d%.]+)') or nil
end

local function caminhoDoScript()
    if type(thisScript) == 'function' then
        local ok, script = pcall(thisScript)
        if ok and script and script.path then return script.path end
    end
    return nil
end

local function verificarAtualizacao(silencioso)
    lua_thread.create(function()
        local remota = obterVersaoRemota()
        if not remota then
            if not silencioso then chat('{FF5555}', 'Nao foi possivel consultar o GitHub.') end
            return
        end
        if versaoMaior(remota, VERSION) then
            chat('{FFFF00}', 'Nova versao disponivel: ' .. remota .. '. Use /setoratualizar.')
        elseif not silencioso then
            chat('{3EDC81}', 'Voce ja esta na versao mais recente (' .. VERSION .. ').')
        end
    end)
end


local function instalarAtualizacao()
    lua_thread.create(function()
        chat('{48C6FF}', 'Baixando atualizacao do GitHub...')
        local remota = obterVersaoRemota()
        if not remota then return chat('{FF5555}', 'Falha ao consultar a versao remota.') end
        if not versaoMaior(remota, VERSION) then return chat('{3EDC81}', 'Nenhuma atualizacao disponivel.') end

        local ok, res = pcall(requests.get, UPDATE_SCRIPT_URL)
        local novo = ok and responseBody(res) or nil
        if not novo or #novo < 5000 or not novo:find('SETOR SEGURANCA %- MOBILE') then
            return chat('{FF5555}', 'Arquivo remoto invalido. Atualizacao cancelada.')
        end

        local path = caminhoDoScript()
        if not path then return chat('{FF5555}', 'O MoonLoader nao informou o caminho deste script.') end
        local atual = io.open(path, 'r')
        if not atual then return chat('{FF5555}', 'Nao foi possivel abrir o script atual.') end
        local conteudoAtual = atual:read('*a')
        atual:close()

        local backup = io.open(path .. '.bak', 'w')
        if not backup then return chat('{FF5555}', 'Nao foi possivel criar o backup. Atualizacao cancelada.') end
        backup:write(conteudoAtual)
        backup:close()

        local destino = io.open(path, 'w')
        if not destino then return chat('{FF5555}', 'Nao foi possivel substituir o script.') end
        destino:write(novo)
        destino:close()
        chat('{3EDC81}', 'Atualizado para ' .. remota .. '. Reinicie o jogo. Backup salvo em .bak.')
    end)
end

local function salvarTabela(path, dados)
    local f = io.open(path, 'w')
    if not f then return false end
    for chave, info in pairs(dados) do
        local nick, motivo = '', ''
        if type(info) == 'table' then nick, motivo = info.nick or '', info.motivo or '' else nick = tostring(info) end
        f:write(tostring(chave), '\t', nick:gsub('[\r\n\t]', ' '), '\t', motivo:gsub('[\r\n\t]', ' '), '\n')
    end
    f:close()
    return true
end

local function carregarTabela(path)
    local dados, f = {}, io.open(path, 'r')
    if not f then return dados end
    for line in f:lines() do
        local chave, nick, motivo = line:match('^([^\t]+)\t([^\t]*)\t?(.*)$')
        if chave then dados[chave] = { nick = nick or '', motivo = motivo or '' } end
    end
    f:close()
    return dados
end

local function salvarRG(rg, nick)
    rg, nick = tostring(rg or ''):match('(%d+)'), trim(nick)
    if not rg or nick == '' then return end
    cache[rg] = { nick = nick }
    salvarTabela(CACHE_FILE, cache)
end

local function acharRG(valor)
    valor = trim(valor)
    if valor:match('^%d+$') and cache[valor] then return valor, cache[valor].nick end
    local busca = valor:lower()
    local achados = {}
    for rg, info in pairs(cache) do
        if tostring(info.nick):lower():find(busca, 1, true) then achados[#achados + 1] = {rg, info.nick} end
    end
    if #achados == 1 then return achados[1][1], achados[1][2] end
    return nil, nil, #achados
end

local function post(url, mensagem, retorno)
    if not cfg.modulos.logs or not perfilOk() then return end
    lua_thread.create(function()
        local ok, res = pcall(requests.post, url, {
            data = '{"content":"' .. jsonEscape(mensagem) .. '"}',
            headers = {['Content-Type'] = 'application/json'}
        })
        if retorno then
            if ok and res then chat('{3EDC81}', retorno) else chat('{FF5555}', 'Falha ao enviar o registro ao Discord.') end
        end
    end)
end

local function logPunicao(nick, rg, tempo, motivo, acao, url, tipo)
    local data = os.date('%d/%m/%Y - %H:%M:%S')
    local geral = string.format('[%s] HZ-ADMIN: %s %s %s o(a) jogador(a) %s %s por %s (Motivo: %s)',
        data, cfg.dados.cargo, cfg.dados.nome, acao, nick, rg, tempo, motivo)
    local form = string.format('```\nADM: %s\nNICK: %s\nRG: %s\nTEMPO: %s\nMOTIVO: %s\nPROVAS: \n```',
        cfg.dados.nome, nick, rg, tempo, motivo)
    post(WEBHOOKS.LOG, geral)
    lua_thread.create(function()
        wait(1100)
        post(url, '[' .. data .. ']')
        wait(1100)
        post(url, form, 'Registro de ' .. tipo .. ' enviado.')
    end)
end

local function logAcao(tipo, rg, extra)
    local url = WEBHOOKS[tipo]
    if not url then return end
    local nick = cache[tostring(rg)] and cache[tostring(rg)].nick or ('RG ' .. tostring(rg))
    local msg = string.format('[%s] %s %s executou %s em %s [RG %s]%s', os.date('%d/%m/%Y - %H:%M:%S'),
        cfg.dados.cargo, cfg.dados.nome, tipo, nick, rg, extra and (' (' .. extra .. ')') or '')
    post(url, msg)
end

local function listaJogadores(somenteNovatos)
    local lista = {}
    for id = 0, sampGetMaxPlayerId(false) do
        if sampIsPlayerConnected(id) then
            local level = sampGetPlayerScore(id) or 0
            if not somenteNovatos or level == 0 then
                lista[#lista + 1] = { id = id, nick = sampGetPlayerNickname(id), level = level }
            end
        end
    end
    table.sort(lista, function(a, b) return a.id < b.id end)
    return lista
end

local function navegar(novatos, direcao)
    if not cfg.modulos.navegacao then return chat('{FF5555}', 'Modulo de navegacao desativado.') end
    local lista = listaJogadores(novatos)
    if #lista == 0 then return chat('{FFFF00}', 'Nenhum jogador disponivel nessa lista.') end
    if novatos then
        navNovato = ((navNovato - 1 + direcao) % #lista) + 1
        sampSendChat('/tv ' .. lista[navNovato].id)
        chat('{48C6FF}', 'TV novatos: ' .. lista[navNovato].nick .. ' [ID ' .. lista[navNovato].id .. ']')
    else
        navTodos = ((navTodos - 1 + direcao) % #lista) + 1
        sampSendChat('/tv ' .. lista[navTodos].id)
        chat('{48C6FF}', 'TV todos: ' .. lista[navTodos].nick .. ' [ID ' .. lista[navTodos].id .. ']')
    end
end

local function mostrarAjuda()
    chat('{48C6FF}', 'Mobile ' .. VERSION .. ' | Perfil: /configadm Nome 1|2')
    chat('{48C6FF}', '/rgnome nome | /rgatual | /rgcache | /rgdel RG')
    chat('{48C6FF}', '/monitor RG motivo | /desmonitor RG | /monitorados')
    chat('{48C6FF}', '/tvn /tvnvoltar (novatos) | /tva /tavoltar (todos) | /tvoff')
    chat('{48C6FF}', '/setorir RG | /setortrazer RG | /setorvida RG valor | /setorcolete RG valor')
    chat('{48C6FF}', '/setorreviver RG | /setorcongelar RG | /setordescongelar RG | /setorarmas RG')
    chat('{48C6FF}', '/mods | /modulo logs|monitoramento|navegacao|atalhos on|off')
end

local function dialogo(id, titulo, texto, botao1, botao2, estilo)
    sampShowDialog(id, titulo, texto, botao1 or 'Selecionar', botao2 or 'Voltar', estilo or 2)
end

local function abrirPrincipal()
    dialogo(D_MAIN, 'SETOR SEGURANCA - MOBILE',
        'TV / Telagem\nPunicoes\nAcoes administrativas\nCache de RG\nMonitoramento\nModulos\nAjuda no chat',
        'Abrir', 'Fechar', 2)
end

local function abrirTV()
    dialogo(D_TV, 'SETOR - TV / TELAGEM',
        'Proximo novato\nNovato anterior\nProximo jogador\nJogador anterior\nDesligar TV\nMostrar RG atual',
        'Executar', 'Voltar', 2)
end

local function abrirPunicoes()
    dialogo(D_PUNICOES, 'SETOR - PUNICOES',
        'Ban permanente\nBan temporario\nCadeia / Punicao\nMute (somente registro)',
        'Continuar', 'Voltar', 2)
end

local function abrirAcoes()
    dialogo(D_ACOES, 'SETOR - ACOES',
        'Ir ate jogador\nTrazer jogador\nReviver jogador\nCongelar jogador\nDescongelar jogador\nPrender armas\nDefinir vida\nDefinir colete',
        'Continuar', 'Voltar', 2)
end

local function abrirRG()
    dialogo(D_RG, 'SETOR - CACHE DE RG',
        'Buscar por nome ou RG\nMostrar RG atual\nQuantidade no cache\nRemover RG',
        'Abrir', 'Voltar', 2)
end

local function abrirMonitor()
    dialogo(D_MONITOR, 'SETOR - MONITORAMENTO',
        'Adicionar monitorado\nRemover monitorado\nListar monitorados',
        'Abrir', 'Voltar', 2)
end

local function abrirModulos()
    dialogo(D_MODULOS, 'SETOR - MODULOS (toque para alternar)',
        'Logs: ' .. (cfg.modulos.logs and 'ON' or 'OFF') ..
        '\nMonitoramento: ' .. (cfg.modulos.monitoramento and 'ON' or 'OFF') ..
        '\nNavegacao TV: ' .. (cfg.modulos.navegacao and 'ON' or 'OFF') ..
        '\nAtalhos: ' .. (cfg.modulos.atalhos and 'ON' or 'OFF'),
        'Alternar', 'Voltar', 2)
end

local function pedirAcao(acao, instrucao)
    dialogAction = acao
    dialogo(D_INPUT_ACAO, 'SETOR - INFORME O ALVO', instrucao or 'Digite o RG ou nome salvo no cache:', 'Executar', 'Cancelar', 1)
end

local function executarAcaoDialogo(valor)
    local acao = dialogAction
    dialogAction = nil
    if not acao then return end
    if acao == 'vida' or acao == 'colete' then
        local alvo, quantidade = trim(valor):match('^(%S+)%s+(%d+)$')
        local rg = alvo and (acharRG(alvo) or alvo)
        if not rg or not rg:match('^%d+$') then return chat('{FFFF00}', 'Formato invalido. Informe: RG-ou-nome valor') end
        local comando = acao == 'vida' and 'setvida' or 'setcolete'
        sampSendChat('/' .. comando .. ' ' .. rg .. ' ' .. quantidade)
        logAcao(comando:upper(), rg, quantidade)
        return
    end
    local mapa = {
        ir={'ir','IR'}, trazer={'trazer','TRAZER'}, reviver={'reviver','REVIVER'},
        congelar={'congelar','CONGELAR'}, descongelar={'descongelar','DESCONGELAR'},
        armas={'prenderarmas','PRENDERARMAS'}
    }
    local dados = mapa[acao]
    local rg = acharRG(valor) or trim(valor)
    if not dados or not rg:match('^%d+$') then return chat('{FFFF00}', 'Informe um RG ou nome salvo no cache.') end
    sampSendChat('/' .. dados[1] .. ' ' .. rg)
    logAcao(dados[2], rg)
end

local function pedirPunicao(tipo)
    dialogAction = tipo
    local instrucoes = {
        ban='Formato: RG motivo',
        bantemp='Formato: RG dias motivo',
        cadeia='Formato: RG minutos motivo',
        mute='Formato: Nick RG dias motivo'
    }
    dialogo(D_INPUT_PUNICAO, 'SETOR - PUNICAO', instrucoes[tipo], 'Enviar', 'Cancelar', 1)
end

local function executarPunicaoDialogo(valor)
    local tipo = dialogAction
    dialogAction = nil
    valor = trim(valor)
    if tipo == 'ban' then
        local rg, motivo = valor:match('^(%d+)%s+(.+)$')
        if not rg then return chat('{FFFF00}', 'Formato: RG motivo') end
        sampSendChat('/ban ' .. rg .. ' ' .. motivo)
    elseif tipo == 'bantemp' then
        local rg, dias, motivo = valor:match('^(%d+)%s+(%d+)%s+(.+)$')
        if not rg then return chat('{FFFF00}', 'Formato: RG dias motivo') end
        sampSendChat('/bantemp ' .. rg .. ' ' .. dias .. ' ' .. motivo)
    elseif tipo == 'cadeia' then
        local rg, minutos, motivo = valor:match('^(%d+)%s+(%d+)%s+(.+)$')
        if not rg then return chat('{FFFF00}', 'Formato: RG minutos motivo') end
        sampSendChat('/punicao ' .. rg .. ' ' .. minutos .. ' ' .. motivo)
    elseif tipo == 'mute' then
        local nick, rg, dias, motivo = valor:match('^(%S+)%s+(%d+)%s+(%d+)%s+(.+)$')
        if not nick then return chat('{FFFF00}', 'Formato: Nick RG dias motivo') end
        logPunicao(nick, rg, dias .. ' dias', motivo, 'mutou', WEBHOOKS.MUTE, 'MUTE')
    end
end

local function registrarComandos()
    sampRegisterChatCommand('setor', abrirPrincipal)
    sampRegisterChatCommand('setorversao', function()
        chat('{48C6FF}', 'Versao instalada: ' .. VERSION)
        verificarAtualizacao(false)
    end)
    sampRegisterChatCommand('setoratualizar', instalarAtualizacao)
    sampRegisterChatCommand('configadm', function(arg)
        local nome, id = trim(arg):match('^(%S+)%s+([12])$')
        if not nome then return chat('{FF5555}', 'Use /configadm Nome 1 (Moderador) ou 2 (Administrador).') end
        cfg.dados.nome = nome
        cfg.dados.cargo = id == '1' and 'Moderador(a)' or 'Administrador(a)'
        inicfg.save(cfg, CONFIG_FILE)
        chat('{3EDC81}', 'Perfil definido: ' .. cfg.dados.cargo .. ' ' .. nome)
    end)
    sampRegisterChatCommand('mods', abrirModulos)
    sampRegisterChatCommand('modulo', function(arg)
        local nome, estado = trim(arg):match('^(%S+)%s+(on|off)$')
        if not nome or cfg.modulos[nome] == nil then return chat('{FFFF00}', 'Use /modulo logs|monitoramento|navegacao|atalhos on|off') end
        cfg.modulos[nome] = estado == 'on'
        inicfg.save(cfg, CONFIG_FILE)
        chat('{3EDC81}', nome .. ' = ' .. estado)
    end)
    sampRegisterChatCommand('rgnome', function(arg)
        local rg, nick, total = acharRG(arg)
        if rg then chat('{3EDC81}', nick .. ' - RG ' .. rg) elseif total and total > 1 then chat('{FFFF00}', 'Mais de um resultado; refine o nome.') else chat('{FF5555}', 'Nao encontrado no cache.') end
    end)
    sampRegisterChatCommand('rgatual', function()
        if rgAtual then chat('{3EDC81}', (nickAtual or '?') .. ' - RG ' .. rgAtual) else chat('{FFFF00}', 'Nenhum jogador telado foi identificado.') end
    end)
    sampRegisterChatCommand('rgcache', function()
        local n = 0 for _ in pairs(cache) do n = n + 1 end
        chat('{3EDC81}', n .. ' RG(s) no cache mobile.')
    end)
    sampRegisterChatCommand('rgdel', function(arg)
        local rg = trim(arg)
        if cache[rg] then cache[rg] = nil salvarTabela(CACHE_FILE, cache) chat('{3EDC81}', 'RG ' .. rg .. ' removido.') else chat('{FF5555}', 'RG inexistente.') end
    end)
    sampRegisterChatCommand('monitor', function(arg)
        if not cfg.modulos.monitoramento then return chat('{FF5555}', 'Monitoramento desativado.') end
        local alvo, motivo = trim(arg):match('^(%S+)%s+(.+)$')
        if not alvo then return chat('{FFFF00}', 'Use /monitor RG-ou-nome motivo') end
        local rg, nick = acharRG(alvo)
        if not rg and alvo:match('^%d+$') then rg, nick = alvo, 'Desconhecido' end
        if not rg then return chat('{FF5555}', 'Jogador nao localizado no cache.') end
        monitorados[rg] = { nick = nick, motivo = motivo }
        salvarTabela(MONITOR_FILE, monitorados)
        chat('{3EDC81}', nick .. ' [RG ' .. rg .. '] monitorado: ' .. motivo)
    end)
    sampRegisterChatCommand('desmonitor', function(arg)
        local rg = acharRG(arg) or trim(arg)
        if monitorados[rg] then monitorados[rg] = nil salvarTabela(MONITOR_FILE, monitorados) chat('{3EDC81}', 'RG ' .. rg .. ' removido dos monitorados.') else chat('{FFFF00}', 'RG nao monitorado.') end
    end)
    sampRegisterChatCommand('monitorados', function()
        local n = 0
        for rg, info in pairs(monitorados) do n = n + 1 chat('{48C6FF}', info.nick .. ' [RG ' .. rg .. '] - ' .. info.motivo) end
        if n == 0 then chat('{FFFF00}', 'Lista de monitorados vazia.') end
    end)
    sampRegisterChatCommand('tvn', function() navegar(true, 1) end)
    sampRegisterChatCommand('tvnvoltar', function() navegar(true, -1) end)
    sampRegisterChatCommand('tva', function() navegar(false, 1) end)
    sampRegisterChatCommand('tavoltar', function() navegar(false, -1) end)

    local atalhos = {
        setorir = {'ir', 'IR'}, setortrazer = {'trazer', 'TRAZER'}, setorreviver = {'reviver', 'REVIVER'},
        setorcongelar = {'congelar', 'CONGELAR'}, setordescongelar = {'descongelar', 'DESCONGELAR'},
        setorarmas = {'prenderarmas', 'PRENDERARMAS'}
    }
    for nome, dados in pairs(atalhos) do
        sampRegisterChatCommand(nome, function(arg)
            if not cfg.modulos.atalhos or not perfilOk() then return end
            local rg = acharRG(arg) or trim(arg)
            if not rg:match('^%d+$') then return chat('{FFFF00}', 'Informe um RG ou nome salvo no cache.') end
            sampSendChat('/' .. dados[1] .. ' ' .. rg)
            logAcao(dados[2], rg)
        end)
    end
    sampRegisterChatCommand('setorvida', function(arg)
        local alvo, valor = trim(arg):match('^(%S+)%s+(%d+)$'); local rg = alvo and (acharRG(alvo) or alvo)
        if not rg or not rg:match('^%d+$') then return chat('{FFFF00}', 'Use /setorvida RG-ou-nome valor') end
        sampSendChat('/setvida ' .. rg .. ' ' .. valor); logAcao('SETVIDA', rg, valor)
    end)
    sampRegisterChatCommand('setorcolete', function(arg)
        local alvo, valor = trim(arg):match('^(%S+)%s+(%d+)$'); local rg = alvo and (acharRG(alvo) or alvo)
        if not rg or not rg:match('^%d+$') then return chat('{FFFF00}', 'Use /setorcolete RG-ou-nome valor') end
        sampSendChat('/setcolete ' .. rg .. ' ' .. valor); logAcao('SETCOLETE', rg, valor)
    end)
    sampRegisterChatCommand('mu', function(arg)
        if not perfilOk() then return end
        local nick, rg, dias, motivo = trim(arg):match('^(%S+)%s+(%d+)%s+(%d+)%s+(.+)$')
        if not nick then return chat('{FFFF00}', 'Use /mu Nick RG dias motivo') end
        logPunicao(nick, rg, dias .. ' dias', motivo, 'mutou', WEBHOOKS.MUTE, 'MUTE')
    end)
end

function samp.onSendDialogResponse(dialogId, button, listboxId, input)
    -- Retorna false para impedir que respostas dos nossos dialogos locais sejam enviadas ao servidor.
    if dialogId < D_MAIN or dialogId > D_INPUT_PUNICAO then return end

    if button == 0 then
        if dialogId == D_MAIN then return false end
        if dialogId == D_INPUT_ACAO or dialogId == D_INPUT_PUNICAO or
           dialogId == D_INPUT_RG_BUSCA or dialogId == D_INPUT_RG_DEL or
           dialogId == D_INPUT_MONITOR or dialogId == D_INPUT_DESMONITOR then
            abrirPrincipal()
        elseif dialogId == D_TV or dialogId == D_PUNICOES or dialogId == D_ACOES or
               dialogId == D_RG or dialogId == D_MONITOR or dialogId == D_MODULOS then
            abrirPrincipal()
        end
        return false
    end

    if dialogId == D_MAIN then
        if listboxId == 0 then abrirTV()
        elseif listboxId == 1 then abrirPunicoes()
        elseif listboxId == 2 then abrirAcoes()
        elseif listboxId == 3 then abrirRG()
        elseif listboxId == 4 then abrirMonitor()
        elseif listboxId == 5 then abrirModulos()
        elseif listboxId == 6 then mostrarAjuda() abrirPrincipal() end
    elseif dialogId == D_TV then
        if listboxId == 0 then navegar(true, 1)
        elseif listboxId == 1 then navegar(true, -1)
        elseif listboxId == 2 then navegar(false, 1)
        elseif listboxId == 3 then navegar(false, -1)
        elseif listboxId == 4 then sampSendChat('/tvoff')
        elseif listboxId == 5 then
            if rgAtual then chat('{3EDC81}', (nickAtual or '?') .. ' - RG ' .. rgAtual) else chat('{FFFF00}', 'Nenhum RG atual identificado.') end
        end
        lua_thread.create(function() wait(150) abrirTV() end)
    elseif dialogId == D_PUNICOES then
        local tipos = {'ban', 'bantemp', 'cadeia', 'mute'}
        if tipos[listboxId + 1] then pedirPunicao(tipos[listboxId + 1]) end
    elseif dialogId == D_ACOES then
        local acoes = {'ir', 'trazer', 'reviver', 'congelar', 'descongelar', 'armas', 'vida', 'colete'}
        local acao = acoes[listboxId + 1]
        if acao == 'vida' or acao == 'colete' then
            pedirAcao(acao, 'Digite: RG-ou-nome valor\nExemplo: 12345 100')
        elseif acao then pedirAcao(acao) end
    elseif dialogId == D_INPUT_ACAO then
        executarAcaoDialogo(input)
    elseif dialogId == D_INPUT_PUNICAO then
        executarPunicaoDialogo(input)
    elseif dialogId == D_RG then
        if listboxId == 0 then dialogo(D_INPUT_RG_BUSCA, 'BUSCAR RG', 'Digite o nome ou RG:', 'Buscar', 'Cancelar', 1)
        elseif listboxId == 1 then
            if rgAtual then chat('{3EDC81}', (nickAtual or '?') .. ' - RG ' .. rgAtual) else chat('{FFFF00}', 'Nenhum RG atual identificado.') end
            lua_thread.create(function() wait(150) abrirRG() end)
        elseif listboxId == 2 then
            local n = 0 for _ in pairs(cache) do n = n + 1 end
            chat('{3EDC81}', n .. ' RG(s) no cache mobile.')
            lua_thread.create(function() wait(150) abrirRG() end)
        elseif listboxId == 3 then dialogo(D_INPUT_RG_DEL, 'REMOVER RG', 'Digite o RG que deseja remover:', 'Remover', 'Cancelar', 1) end
    elseif dialogId == D_INPUT_RG_BUSCA then
        local rg, nick, total = acharRG(input)
        if rg then chat('{3EDC81}', nick .. ' - RG ' .. rg) elseif total and total > 1 then chat('{FFFF00}', 'Mais de um resultado; refine o nome.') else chat('{FF5555}', 'Nao encontrado no cache.') end
    elseif dialogId == D_INPUT_RG_DEL then
        local rg = trim(input)
        if cache[rg] then cache[rg] = nil salvarTabela(CACHE_FILE, cache) chat('{3EDC81}', 'RG ' .. rg .. ' removido.') else chat('{FF5555}', 'RG inexistente.') end
    elseif dialogId == D_MONITOR then
        if listboxId == 0 then dialogo(D_INPUT_MONITOR, 'ADICIONAR MONITORADO', 'Digite: RG-ou-nome motivo', 'Adicionar', 'Cancelar', 1)
        elseif listboxId == 1 then dialogo(D_INPUT_DESMONITOR, 'REMOVER MONITORADO', 'Digite o RG ou nome:', 'Remover', 'Cancelar', 1)
        elseif listboxId == 2 then
            local n = 0
            for rg, info in pairs(monitorados) do n = n + 1 chat('{48C6FF}', info.nick .. ' [RG ' .. rg .. '] - ' .. info.motivo) end
            if n == 0 then chat('{FFFF00}', 'Lista de monitorados vazia.') end
            lua_thread.create(function() wait(150) abrirMonitor() end)
        end
    elseif dialogId == D_INPUT_MONITOR then
        local alvo, motivo = trim(input):match('^(%S+)%s+(.+)$')
        local rg, nick = alvo and acharRG(alvo)
        if not rg and alvo and alvo:match('^%d+$') then rg, nick = alvo, 'Desconhecido' end
        if not rg then chat('{FF5555}', 'Jogador nao localizado no cache.')
        else monitorados[rg] = {nick=nick, motivo=motivo} salvarTabela(MONITOR_FILE, monitorados) chat('{3EDC81}', nick .. ' [RG ' .. rg .. '] adicionado.') end
    elseif dialogId == D_INPUT_DESMONITOR then
        local rg = acharRG(input) or trim(input)
        if monitorados[rg] then monitorados[rg] = nil salvarTabela(MONITOR_FILE, monitorados) chat('{3EDC81}', 'RG ' .. rg .. ' removido.') else chat('{FFFF00}', 'RG nao monitorado.') end
    elseif dialogId == D_MODULOS then
        local nomes = {'logs', 'monitoramento', 'navegacao', 'atalhos'}
        local nome = nomes[listboxId + 1]
        if nome then cfg.modulos[nome] = not cfg.modulos[nome] inicfg.save(cfg, CONFIG_FILE) end
        lua_thread.create(function() wait(150) abrirModulos() end)
    end
    return false
end

function samp.onSendCommand(command)
    if not perfilOk() then return end
    local rg, motivo = command:match('^/ban%s+(%d+)%s+(.+)')
    if rg then pendente = {rg=rg, tempo='Permanente', motivo=motivo, tipo='BAN'} return end
    local tempo
    rg, tempo, motivo = command:match('^/bantemp%s+(%d+)%s+(%d+)%s+(.+)')
    if rg then pendente = {rg=rg, tempo=tempo .. ' dias', motivo=motivo, tipo='BAN'} return end
    rg, tempo, motivo = command:match('^/cadeia%s+(%d+)%s+(%d+)%s+(.+)')
    if not rg then rg, tempo, motivo = command:match('^/punicao%s+(%d+)%s+(%d+)%s+(.+)') end
    if rg then pendente = {rg=rg, tempo=tempo .. ' minutos', motivo=motivo, tipo='CADEIA'} return end

    local comandos = { ir='IR', trazer='TRAZER', reviver='REVIVER', congelar='CONGELAR', descongelar='DESCONGELAR', prenderarmas='PRENDERARMAS' }
    local cmd, alvo = command:match('^/(%S+)%s+(%d+)%s*$')
    if cmd and comandos[cmd:lower()] then logAcao(comandos[cmd:lower()], alvo) end
    local q
    cmd, alvo, q = command:match('^/(%a+)%s+(%d+)%s+(%d+)')
    if cmd and (cmd:lower() == 'setvida' or cmd:lower() == 'setcolete') then
        logAcao(cmd:upper(), alvo, q)
    end
    alvo, q = command:match('^/tapa%s+(%d+)%s+(%d+)')
    if alvo then logAcao('TAPA', alvo, q) end
end

function samp.onServerMessage(color, text)
    local ct = clean(text)
    local nick, rg = ct:match('[Nn]ome[:%s]+([%w_]+).-RG[:%s]+(%d+)')
    if not nick then nick, rg = ct:match('[Nn]ick[:%s]+([%w_]+).-RG[:%s]+(%d+)') end
    if not nick then rg, nick = ct:match('RG[:%s]+(%d+).-Nome[:%s]+([%w_]+)') end
    if not nick then rg, nick = ct:match('RG[:%s]+(%d+).-Nick[:%s]+([%w_]+)') end
    if nick and rg then salvarRG(rg, nick); rgAtual, nickAtual = rg, nick end
    local tvNick, tvRg = ct:match('[Tt]elando.-([%w_]+).-RG[:%s]+(%d+)')
    if tvNick and tvRg then salvarRG(tvRg, tvNick); rgAtual, nickAtual = tvRg, tvNick end

    if pendente and ct:find('HZ%-ADMIN') then
        local alvoNick = ct:match('[Jj]ogador%(a%)%s+([%w_]+)') or (cache[pendente.rg] and cache[pendente.rg].nick)
        if alvoNick and alvoNick:lower() ~= tostring(cfg.dados.nome):lower() then
            local acao = pendente.tipo == 'BAN' and 'baniu' or 'prendeu'
            local url = pendente.tipo == 'BAN' and WEBHOOKS.BAN or WEBHOOKS.CADEIA
            logPunicao(alvoNick, pendente.rg, pendente.tempo, pendente.motivo, acao, url, pendente.tipo)
            pendente = nil
        end
    end

    for mrg, info in pairs(monitorados) do
        if ct:lower():find(tostring(info.nick):lower(), 1, true) and (ct:lower():find('entrou', 1, true) or ct:lower():find('conect', 1, true)) then
            chat('{FFAA00}', 'MONITORADO ONLINE: ' .. info.nick .. ' [RG ' .. mrg .. '] - ' .. info.motivo)
        end
    end
end

function main()
    while not isSampAvailable() do wait(100) end
    cache = carregarTabela(CACHE_FILE)
    monitorados = carregarTabela(MONITOR_FILE)
    registrarComandos()
    if cfg.dados.nome ~= 'Vazio' then
        chat('{3EDC81}', 'Mobile ' .. VERSION .. ' ativo: ' .. cfg.dados.cargo .. ' ' .. cfg.dados.nome .. '. Use /setor.')
    else
        chat('{FF5555}', 'Perfil nao configurado. Use /configadm Nome 1 ou 2.')
    end
    lua_thread.create(function()
        wait(4000)
        verificarAtualizacao(true)
    end)
    wait(-1)
end
