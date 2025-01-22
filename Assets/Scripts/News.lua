--!Type(Module)

SetRoleEvent = Event.new("SetRole")
NewsEvent = Event.new("News")
SetGamePhaseEvent = Event.new("SetGamePhase")

function SendNewsToClient(player: Player, newsItem: string)
    NewsEvent:FireClient(player, newsItem)
end

function SendNewsToAllClients(newsItem: string)
    NewsEvent:FireAllClients(newsItem)
end

function UpdateClientRole(player: Player, role: string, team: string)
    SetRoleEvent:FireClient(player, role, team)
end

function UpdateGamePhase(gamePhase: "waiting" | "day" | "night" | "gameover")
    print("Sending new game phase: "..gamePhase)
    SetGamePhaseEvent:FireAllClients(gamePhase)
end

function UpdateGamePhaseForClient(player: Player, gamePhase: "waiting" | "day" | "night" | "gameover")
    SetGamePhaseEvent:FireClient(player, gamePhase)
end