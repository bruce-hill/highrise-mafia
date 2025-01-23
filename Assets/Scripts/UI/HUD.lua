--!Type(UI)

-- This file handles keeping the HUD up to date.

local News = require "News"

type NewsEvent = {type:"new_game"} | {type:"game_over", winner: "mafia" | "citizens"} | {type: "player_killed", player: Player}
    | {type: "role_revealed", player: Player, role: string} | {type: "state_changed", state: "waiting" | "night" | "day" | "gameover"} | {type: "role_assigned", player: Player, role: string}
    | {type: "start_countdown", duration: number}

--!Bind
local roleLabel : Label = nil
--!Bind
local instructionsLabel : Label = nil
--!Bind
local gamePhaseLabel : Label = nil
--!Bind
local roleIcon : VisualElement = nil
--!Bind
local newsFeed : UIScrollView = nil
--!Bind
local statusInfo : VisualElement = nil
--!Bind
local winnerPopup : VisualElement = nil
--!Bind
local winnerIcon : VisualElement = nil
--!Bind
local timerLabel : Label = nil

local currentRole : string
local timerCountdown : number? = nil

News.SetRoleEvent:Connect(function(role: string, team: string)
    currentRole = role
    print("UI detected new role: "..role.." and team: "..team)
    roleLabel.text = "Role: "..role:gsub("^%l", string.upper)
    if role == "mafioso" then
        instructionsLabel.text = "Eliminate all innocent players"
    elseif role == "detective" then
        instructionsLabel.text = "Investigate a player each night and find the mafia"
    elseif role == "townsperson" then
        instructionsLabel.text = "Eliminate the mafia before they eliminate you"
    elseif role == "observer" then
        instructionsLabel.text = "Wait for the next game to begin"
    elseif role == "corpse" then
        instructionsLabel.text = "Wait for the game to finish"
    end

    roleIcon:EnableInClassList("role-icon-mafioso", role == "mafioso")
    roleIcon:EnableInClassList("role-icon-detective", role == "detective")
    roleIcon:EnableInClassList("role-icon-townsperson", role == "townsperson")
    roleIcon:EnableInClassList("role-icon-observer", role == "observer")
    roleIcon:EnableInClassList("role-icon-corpse", role == "corpse")

    statusInfo:EnableInClassList("team-mafia", team == "mafia")
    statusInfo:EnableInClassList("team-citizens", team == "citizens")
    statusInfo:EnableInClassList("team-neutral", team == "neutral")
end)

local function AddNewsItem(message: string)
    local newsItem: Label = Label.new()
    newsItem:AddToClassList("news-item")
    newsItem:AddToClassList("appeared")
    newsItem.text = message
    newsFeed:Add(newsItem)

    defer(function()
        newsItem:RemoveFromClassList("appeared")
        newsFeed:ScrollToEnd()
    end)
end

News.NewsEvent:Connect(function(event: NewsEvent)
    if event.type == "new_game" then
        newsFeed:Clear()
        AddNewsItem("A new game has started!")
    elseif event.type == "game_over" then
        AddNewsItem("Game over! "..event.winner:gsub("^%l", string.upper).." win!")
        Timer.After(5, function()
            winnerIcon:EnableInClassList("mafia-win", (event.winner == "mafia"))
            winnerIcon:EnableInClassList("citizens-win", (event.winner == "citizens"))
            winnerPopup:EnableInClassList("show", true)
        end)
    elseif event.type == "role_revealed" then
        AddNewsItem(event.player.name.." is a "..event.role.."!")
    elseif event.type == "player_killed" then
        AddNewsItem(event.player.name.." was killed!")
        event.player.character:PlayEmote("emote-death", false)
    elseif event.type == "state_changed" then
        gamePhaseLabel.text = "Phase: "..event.state:gsub("^%l", string.upper)

        if event.state ~= "gameover" then
            winnerPopup:EnableInClassList("show", false)
        end

        if currentRole == "corpse" then
            instructionsLabel.text = "Wait for the game to finish"
        elseif currentRole == "observer" or not currentRole then
            instructionsLabel.text = "Wait for the game to start"
        elseif event.state == "waiting" then
            instructionsLabel.text = "Wait for the game to start"
        elseif event.state == "gameover" then
            instructionsLabel.text = "Wait for the next game to start"
        elseif event.state == "day" then
            instructionsLabel.text = "Vote on a player to eliminate"
        elseif event.state == "night" then
            if currentRole == "mafioso" then
                instructionsLabel.text = "Choose a player to eliminate"
            elseif currentRole == "detective" then
                instructionsLabel.text = "Choose a player to investigate"
            elseif currentRole == "townsperson" then
                instructionsLabel.text = "Wait for morning"
            end
        end
    elseif event.type == "start_countdown" then
        timerCountdown = event.duration
    end
end)

function self:ClientUpdate()
    if timerCountdown then
        timerCountdown -= Time.deltaTime
        if timerCountdown <= 0 then
            timerCountdown = nil
        end

        if timerCountdown then
            timerLabel.text = "("..tostring(math.ceil(timerCountdown))..")"
        else
            timerLabel.text = ""
        end
    end
end