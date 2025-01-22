--!Type(Module)

--!SerializeField
local gameArea : GameObject = nil
--!SerializeField
local observationDeck : GameObject = nil

TeleportRequest = Event.new("TeleportRequest")

function SendPlayerToGameArea(player: Player)
    TeleportRequest:FireAllClients(player, "gameArea")
end

function SendPlayerToObservationDeck(player: Player)
    TeleportRequest:FireAllClients(player, "observationDeck")
end

function self:ClientAwake()
    TeleportRequest:Connect(function(player: Player, dest: "gameArea" | "observationDeck")
        if dest == "gameArea" then
            player.character:Teleport(gameArea.transform.position)
        elseif dest == "observationDeck" then
            player.character:Teleport(observationDeck.transform.position)
        end
    end)
end
