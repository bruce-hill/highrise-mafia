--!Type(Server)

-- This file handles general gameplay logic and advancing the game through the
-- different phases.

local TargetManager = require "TargetManager"
local News = require "News"
local Teleporter = require "Teleporter"

local LOBBY_DURATION: number = 10
local NIGHT_DURATION: number = 15
local DAY_DURATION: number = 25
local GAMEOVER_DURATION: number = 5

type Team = "mafia" | "citizens" | "neutral"
type Role = {role: "mafioso", team: "mafia"} | {role: "detective", team: "citizens"} | {role: "townsperson", team: "citizens"} | {role: "corpse", team: "neutral"} | {role: "observer", team: "neutral"}
type State = {state: "waiting", elapsed: number} | {state: "night", elapsed: number} | {state: "day", elapsed: number} | {state: "gameover", winner: Team, elapsed: number}
type SceneName = "LobbyScene" | "DayScene" | "NightScene"

local playersChannel: ChannelInfo
local playerTargets: {[Player]: Player?} = {}

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

local function setPlayerRole(player: Player, role: Role)
    if role.team == "citizens" then
        Chat:AddPlayerToChannel(playersChannel, player)
    elseif role.team == "mafia" then
        Chat:AddPlayerToChannel(playersChannel, player)
    elseif role.team == "neutral" then
        Chat:RemovePlayerFromChannel(playersChannel, player)
    end

    News.UpdateClientRole(player, role.role, role.team)

    roles[player] = role

    if role.team == "neutral" then
        Teleporter.SendPlayerToObservationDeck(player)
    else
        Teleporter.SendPlayerToGameArea(player)
    end

    if role.role == "corpse" then
        Storage.UpdatePlayerValue(player, "Losses", function(losses: number)
            return (losses or 0) + 1
        end)
    
        -- When you die, you learn what role everyone has:
        for p,r in pairs(roles) do
            if p ~= player then
                News.SendNewsToClient(player, {type="role_revealed", player=p, role=r.role})
            end
        end
    end

    if role.team == "neutral" then
        News.SendNewsToAllClients({type="role_revealed", player=player, role=role.role})
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

local function getScene(state: State): SceneName
    if state.state == "day" then
        return "DayScene"
    elseif state.state == "night" then
        return "NightScene"
    else
        return "LobbyScene"
    end
end

local function timeRemaining(state: State): number
    if state.state == "gameover" then
        return GAMEOVER_DURATION - state.elapsed
    elseif state.state == "day" then
        return DAY_DURATION - state.elapsed
    elseif state.state == "night" then
        return NIGHT_DURATION - state.elapsed
    elseif state.state == "waiting" then
        return LOBBY_DURATION - state.elapsed
    else
        error("Invalid state")
    end
end

local function setState(newState: State)
    currentState = newState
    playerTargets = {}
    TargetManager.TellAllClientsToForgetTargets()

    News.SendNewsToAllClients({type="state_changed", state=newState.state})

    if newState.state == "waiting" then
        for p in pairs(roles) do
            setPlayerRole(p, {role="observer", team="neutral"})
        end
    end

    if newState.state == "gameover" then
        local winningPlayers = {}
        for p,role in pairs(roles) do
            if role.team == newState.winner then
                table.insert(winningPlayers, p)
            end
        end
        News.SendNewsToAllClients({type="game_over", winningTeam=newState.winner, winningPlayers=winningPlayers})

        for player,role in pairs(roles) do
            News.SendNewsToAllClients({type="role_revealed", player=player, role=role.role})
            if role.team == newState.winner then
                Storage.UpdatePlayerValue(player, "Wins", function(wins: number)
                    return (wins or 0) + 1
                end)
            elseif role.team ~= newState.winner and role.team ~= "neutral" then
                -- If a player was already killed, they lost when they died, so we only
                -- need to update losses for surviving players.
                Storage.UpdatePlayerValue(player, "Losses", function(losses: number)
                    return (losses or 0) + 1
                end)
            end
        end
    end
    
    News.SendNewsToAllClients({type="start_countdown", duration=timeRemaining(newState)})
end

function shuffle(t) -- in-place shuffle a table
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local function randomizeRoles()
    local playerList: {Player} = {}
    for p in pairs(roles) do
        table.insert(playerList, p)
    end
    local mafiosos = #playerList >= 6 and math.round(#playerList/3) or 1
    local detectives = #playerList > 2 and 1 or 0
    local townspeople = #playerList - mafiosos - detectives
    local toAssign: {Role} = {}
    for _=1,mafiosos do table.insert(toAssign, {role="mafioso", team="mafia"}) end
    for _=1,detectives do table.insert(toAssign, {role="detective", team="citizens"}) end
    for _=1,townspeople do table.insert(toAssign, {role="townsperson", team="citizens"}) end
    assert(#playerList == #toAssign)
    shuffle(playerList)
    for i=1,#playerList do
        setPlayerRole(playerList[i], toAssign[i])
    end
end

local function startNewGame()
    randomizeRoles()
    setState(DayState())
    News.SendNewsToAllClients({type="new_game"})

    -- Let the mafia know their teammates
    for p1,role1 in pairs(roles) do
        if role1.team ~= "mafia" then continue end
        for p2,role2 in pairs(roles) do
            if p2 == p1 or role2.team ~= "mafia" then continue end
            News.SendNewsToClient(p1, {type="role_revealed", player=p2, role=roles[p2].role})
        end
    end
end

local function killPlayer(player: Player)
    setPlayerRole(player, {role="corpse", team="neutral"})
    News.SendNewsToAllClients({type="player_killed", player=player})
end

local function chooseMobJusticeVictims(): {Player}
    local targetCounts: {[Player]: number} = {}
    local mostTargeted: Player? = nil
    for player,target in pairs(playerTargets) do
        if roles[player].team == "citizens" or roles[player].team == "mafia" then
            targetCounts[target] = (targetCounts[target] or 0) + 1
            if mostTargeted == nil or targetCounts[target] > targetCounts[mostTargeted] then
                mostTargeted = target
            end
        end
    end

    local victims = {}
    if mostTargeted and targetCounts[mostTargeted] > 1 then
        for player,count in pairs(targetCounts) do
            if count == targetCounts[mostTargeted] then
                table.insert(victims, player)
            end
        end
    end
    return victims
end

local function finishDay()
    local victims: {Player} = chooseMobJusticeVictims()
    for _,victim in ipairs(victims) do
        killPlayer(victim)
    end

    setState(NightState())
end

local function chooseMafiaVictim():Player?
    local victim: Player? = nil
    for player,target in pairs(playerTargets) do
        if roles[player].team == "mafia" then
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
    for player,target in pairs(playerTargets) do
        table.insert(targets, player.name.." targeted "..target.name)
        if roles[player].role == "detective" then
            News.SendNewsToClient(player, {type="role_revealed", player=target, role=roles[target].role})
        end
    end

    local victim: Player? = chooseMafiaVictim()
    if victim then
        killPlayer(victim)
    end

    setState(DayState())
end

local function getWinner():Team?
    if countPlayers("mafia") >= countPlayers("citizens") then
        return "mafia"
    elseif countPlayers("mafia") == 0 then
        return "citizens"
    else
        return nil
    end
end

function self:Awake()
    playersChannel = Chat:CreateChannel("Players", true, true)

    game.PlayerConnected:Connect(function(player: Player)
        setPlayerRole(player, {role="observer", team="neutral"})
        Timer.After(0.7, function()
            News.SendNewsToClient(player, {type="state_changed", state=currentState.state})
            News.UpdateClientRole(player, roles[player].role, roles[player].team)
            News.SendNewsToClient(player, {type="start_countdown", duration=timeRemaining(currentState)})

            if currentState.state == "day" or currentState.state == "night" then
                News.SendNewsToClient(player, {type="new_game"})
            end

            for p, role in pairs(roles) do
                if p ~= player then
                    if role.team == "neutral" then
                        Teleporter.TeleportRequest:FireClient(player, p, "observationDeck", Vector3.new(math.random(-6, 6), 0, math.random(-1, 1)))
                    else
                        Teleporter.TeleportRequest:FireClient(player, p, "gameArea", Vector3.new(math.random(-6, 6), 0, math.random(-2, 2)))
                    end
                end
            end
        end)
    end)

    game.PlayerDisconnected:Connect(function(player: Player)
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

        if currentState.state == "night" and roles[player].team == "mafia" then
            -- Mafia get to know who their teammates vote for at night
            for other,otherRole in pairs(roles) do
                if other ~= player and otherRole.team == "mafia" then
                    News.SendNewsToClient(other, {type="teammate_chose_target", teammate=player, target=target})
                end
            end
        end
    end)

    setState(WaitingState())
end

function self:Update()
    currentState.elapsed += Time.deltaTime

    if currentState.state == "waiting" then
        if countPlayers() >= 4 and currentState.elapsed >= LOBBY_DURATION then
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
        if currentState.elapsed >= GAMEOVER_DURATION then
            setState(WaitingState())
        end
    end
end