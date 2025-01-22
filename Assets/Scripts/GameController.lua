--!Type(Server)

local TargetManager = require "TargetManager"
local News = require "News"
local Teleporter = require "Teleporter"

local NIGHT_DURATION: number = 15
local DAY_DURATION: number = 15

type Team = "mafia" | "citizens" | "neutral"
type Role = {role: "mafioso", team: "mafia"} | {role: "detective", team: "citizens"} | {role: "townsperson", team: "citizens"} | {role: "corpse", team: "neutral"} | {role: "observer", team: "neutral"}
type State = {state: "waiting", elapsed: number} | {state: "night", elapsed: number} | {state: "day", elapsed: number} | {state: "gameover", winner: Team, elapsed: number}
type SceneName = "LobbyScene" | "DayScene" | "NightScene"

local chatChannels: {[string]: ChannelInfo} = {}
-- local loadedScenes : {[string]: Scene?} = {Day=nil, Night=nil, Lobby=nil}
local playerTargets: {[Player]: Player?} = {}
-- local currentScene: Scene? = nil

local function WaitingState():State
    return {state="waiting", elapsed=0}
end
local function DayState():State
    return {state="day", elapsed=0}
end
local function NightState():State
    return {state="night", elapsed=0}
end
local function GameOverState(winner:Team):State
    return {state="gameover", winner=winner, elapsed=0}
end

local currentState: State = WaitingState()
local roles: {[Player]: Role} = {}

local function setRole(player: Player, role: Role)
    -- print("Player "..player.id.." assigned to role: "..role.role)
    if role.team == "citizens" then
        Chat:AddPlayerToChannel(chatChannels.Players, player)
        Chat:RemovePlayerFromChannel(chatChannels.Mafia, player)
        Chat:RemovePlayerFromChannel(chatChannels.Observers, player)
    elseif role.team == "mafia" then
        Chat:AddPlayerToChannel(chatChannels.Players, player)
        Chat:AddPlayerToChannel(chatChannels.Mafia, player)
        Chat:RemovePlayerFromChannel(chatChannels.Observers, player)
    elseif role.team == "neutral" then
        Chat:RemovePlayerFromChannel(chatChannels.Players, player)
        Chat:RemovePlayerFromChannel(chatChannels.Mafia, player)
        Chat:AddPlayerToChannel(chatChannels.Observers, player)
    end

    if role.role == "detective" then
        Chat:AddPlayerToChannel(chatChannels.Detectives, player)
    else
        Chat:RemovePlayerFromChannel(chatChannels.Detectives, player)
    end

    News.UpdateClientRole(player, role.role, role.team)

    roles[player] = role

    if role.team == "neutral" then
        Teleporter.SendPlayerToObservationDeck(player)
    else
        Teleporter.SendPlayerToGameArea(player)
    end
end

local function countPlayers(team:Team?): number
    local n = 0
    for player,role in pairs(roles) do
        if team == nil or role.team == team then
            n += 1
        end
    end
    return n
end

-- local function sendEveryoneToScene(sceneName: SceneName)
--     -- local scene: Scene? = loadedScenes[sceneName]
--     currentScene = server.LoadScene(sceneName, true)
--     if currentScene then
--         print("Sending to scene: "..sceneName)
--         for player in pairs(roles) do
--             server.MovePlayerToScene(player, currentScene)
--         end
--     else
--         print("No such loaded scene: "..sceneName)
--     end
-- end


local function getScene(state: State): SceneName
    if state.state == "day" then
        return "DayScene"
    elseif state.state == "night" then
        return "NightScene"
    else
        return "LobbyScene"
    end
end

local function setState(newState: State)
    currentState = newState
    -- print("Game state is now: "..newState.state)
    playerTargets = {}
    TargetManager.TellAllClientsToForgetTargets()
    News.UpdateGamePhase(newState.state)

    if newState.state == "gameover" then
        News.SendNewsToAllClients("Game over! "..newState.winner:gsub("^%l", string.upper).." win!")
    end
    -- sendEveryoneToScene(getScene(currentState))
end

function shuffle(t) -- in-place shuffle a table
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local function randomizeRoles()
    local n = countPlayers()
    local mafiosos = n/3
    local detectives = n > 2 and 1 or 0
    local townspeople = n - mafiosos - detectives
    local toAssign: {Role} = {}
    for _=1,mafiosos do table.insert(toAssign, {role="mafioso", team="mafia"}) end
    for _=1,detectives do table.insert(toAssign, {role="detective", team="citizens"}) end
    for _=1,townspeople do table.insert(toAssign, {role="townsperson", team="citizens"}) end
    local playerList: {Player} = {}
    for p in pairs(roles) do
        table.insert(playerList, p)
    end
    assert(#playerList == #toAssign)
    shuffle(playerList)
    for i=1,#playerList do
        setRole(playerList[i], toAssign[i])
    end
end

local function startNewGame()
    randomizeRoles()
    setState(NightState())
end

local function killPlayer(player: Player)
    -- Chat:DisplayTextMessage(playersChannel, player, "💀 "..player.name.." was killed!")
    setRole(player, {role="corpse", team="neutral"})
    -- Chat:DisplayTextMessage(observersChannel, player, "💀 "..player.name.." was killed!")
    -- print(player.name.." was killed!")
    News.SendNewsToAllClients(player.name.." was killed!")
end

local function chooseMobJusticeVictim()
    local targetCounts: {[Player]: number} = {}
    local mostTargeted: Player? = nil
    for p,target in pairs(playerTargets) do
        if roles[p].team == "citizens" or roles[p].team == "mafia" then
            targetCounts[target] = (targetCounts[target] or 0) + 1
            if mostTargeted == nil or targetCounts[target] > targetCounts[mostTargeted] then
                mostTargeted = target
            end
        end
    end

    if mostTargeted then
        for p,count in pairs(targetCounts) do
            if p ~= mostTargeted and count == targetCounts[mostTargeted] then
                return nil -- It's a tie
            end
        end
    end
    return mostTargeted
end

local function finishDay()
    local mobVictim: Player? = chooseMobJusticeVictim()
    if mobVictim then
        killPlayer(mobVictim)
    end

    setState(NightState())
end

local function chooseMafiaVictim():Player?
    local victim: Player? = nil
    for p,target in pairs(playerTargets) do
        if roles[p].team == "mafia" then
            if victim ~= nil and target ~= victim then
                return nil -- No consensus
            end
            victim = target
        end
    end
    return victim
end

local function finishNight()
    local targets = {}
    for p,target in pairs(playerTargets) do
        table.insert(targets, p.name.." targeted "..target.name)
        if roles[p].role == "detective" then
            -- Chat:DisplayTextMessage(detectiveChannel, p, "🕵️ "..target.name.." is a "..roles[target].role)
            -- print(p.name.." learned that "..target.name.." is a "..roles[target].role)
            News.SendNewsToClient(p, target.name.." is a "..roles[target].role:gsub("^%l", string.upper).."!")
        end
    end

    local victim: Player? = chooseMafiaVictim()
    if victim then
        killPlayer(victim)
    end

    setState(DayState())
end

local function getWinner():Team?
    if countPlayers("citizens") == 0 then
        return "mafia"
    elseif countPlayers("mafia") == 0 then
        return "citizens"
    else
        return nil
    end
end

function self:Awake()
    chatChannels.Players = Chat:CreateChannel("Players", true, true)
    chatChannels.Detectives = Chat:CreateChannel("Detectives", true, false)
    chatChannels.Mafia = Chat:CreateChannel("Mafia", true, false)
    chatChannels.Observers = Chat:CreateChannel("Observers", true, true)

    -- currentScene = server.LoadScene("LobbyScene", false)

    game.PlayerConnected:Connect(function(player: Player)
        print("Player joined: "..player.name)
        setRole(player, {role="observer", team="neutral"})
        defer(function()
            News.UpdateGamePhaseForClient(player, currentState.state)
            News.UpdateClientRole(player, roles[player].role, roles[player].team)
        end)
        -- server.MovePlayerToScene(player, assert(currentScene))
    end)

    -- loadedScenes.Lobby = server.LoadScene("LobbyScene", false)
    -- print("Loaded Lobby scene")
    -- loadedScenes.Day = server.LoadScene("DayScene", false)
    -- print("Loaded Day scene")
    -- loadedScenes.Night = server.LoadScene("NightScene", false)
    -- print("Loaded Night scene")

    game.PlayerDisconnected:Connect(function(player: Player)
        -- print("Player left: "..player.name)
        roles[player] = nil
    end)

    TargetManager.OnClientChoseTarget(function(player: Player, target: Player?)
        local playerRole = roles[player].role
        if currentState.state == "day" and roles[player].team ~= "neutral" then
            playerTargets[player] = target
            TargetManager.TellClientToTargetPlayer(player, target)
        elseif currentState.state == "night" and (roles[player].role == "mafioso" or roles[player].role == "detective") then
            playerTargets[player] = target
            TargetManager.TellClientToTargetPlayer(player, target)
        end
    end)

    setState(WaitingState())
end

function self:Update()
    currentState.elapsed += Time.deltaTime

    if currentState.state == "waiting" then
        -- print("Waiting: "..tostring(countPlayers()))
        if countPlayers() >= 3 and currentState.elapsed >= 3 then
            startNewGame()
        end
    elseif currentState.state == "night" then
        local winner = getWinner()
        if winner then
            setState(GameOverState(winner))
        elseif currentState.elapsed >= NIGHT_DURATION then
            finishNight()
        end
    elseif currentState.state == "day" then
        local winner = getWinner()
        if winner then
            setState(GameOverState(winner))
        elseif currentState.elapsed >= DAY_DURATION then
            finishDay()
        end
    elseif currentState.state == "gameover" then
        if currentState.elapsed >= 10 then
            setState(WaitingState())
        end
    end
end