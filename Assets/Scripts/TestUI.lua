--!Type(UI)

local News = require "News"

--!Bind
local roleLabel : Label = nil
--!Bind
local instructionsLabel : Label = nil
--!Bind
local gamePhaseLabel : Label = nil
--!Bind
local phaseIcon : VisualElement = nil
--!Bind
local roleIcon : VisualElement = nil
--!Bind
local newsFeed : UIScrollView = nil
--!Bind
local statusInfo : VisualElement = nil

local currentRole : string

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
        client.localPlayer.character:PlayEmote("emote-death2")
    end

    roleIcon:EnableInClassList("role-icon-mafioso", role == "mafioso")
    roleIcon:EnableInClassList("role-icon-detective", role == "detective")
    roleIcon:EnableInClassList("role-icon-townsperson", role == "townsperson")
    roleIcon:EnableInClassList("role-icon-observer", role == "observer")
    roleIcon:EnableInClassList("role-icon-ghost", role == "corpse")

    statusInfo:EnableInClassList("team-mafia", team == "mafia")
    statusInfo:EnableInClassList("team-citizens", team == "citizens")
    statusInfo:EnableInClassList("team-neutral", team == "neutral")
end)

News.NewsEvent:Connect(function(news: string)
    print("UI detected news: "..news)
    -- roleLabel.text = news
    local newsItem: Label = Label.new()
    newsItem:AddToClassList("news-item")
    newsItem.text = news
    newsFeed:Add(newsItem)
    newsFeed:ScrollToEnd()
end)

News.SetGamePhaseEvent:Connect(function(gamePhase: "waiting" | "day" | "night" | "gameover")
    gamePhaseLabel.text = "Phase: "..gamePhase:gsub("^%l", string.upper)

    if currentRole == "corpse" then
        instructionsLabel.text = "Wait for the game to finish"
    elseif currentRole == "observer" or not currentRole then
        instructionsLabel.text = "Wait for the game to start"
    elseif gamePhase == "waiting" then
        instructionsLabel.text = "Wait for the game to start"
    elseif gamePhase == "gameover" then
        instructionsLabel.text = "Wait for the next game to start"
    elseif gamePhase == "day" then
        instructionsLabel.text = "Vote on a player to eliminate"
    elseif gamePhase == "night" then
        if currentRole == "mafioso" then
            instructionsLabel.text = "Choose a player to eliminate"
        elseif currentRole == "detective" then
            instructionsLabel.text = "Choose a player to investigate"
        elseif currentRole == "townsperson" then
            instructionsLabel.text = "Wait for morning"
        end
    end
end)