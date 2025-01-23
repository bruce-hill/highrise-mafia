--!Type(Module)

-- This file handles broadcasting or narrowcasting news events and general status
-- updates to players.

SetRoleEvent = Event.new("SetRole")
NewsEvent = Event.new("News")

type NewsEvent = {type:"new_game"} | {type:"game_over", winningTeam: "mafia" | "citizens", winningPlayers: {Player}} | {type: "player_killed", player: Player}
    | {type: "role_revealed", player: Player, role: string} | {type: "state_changed", state: "waiting" | "night" | "day" | "gameover"} | {type: "role_assigned", player: Player, role: string}
    | {type: "start_countdown", duration: number} | {type: "teammate_chose_target", teammate: Player, target: Player?}

function SendNewsToClient(player: Player, event: NewsEvent)
    NewsEvent:FireClient(player, event)
end

function SendNewsToAllClients(event: NewsEvent)
    NewsEvent:FireAllClients(event)
end

function UpdateClientRole(player: Player, role: string, team: string)
    SetRoleEvent:FireClient(player, role, team)
end