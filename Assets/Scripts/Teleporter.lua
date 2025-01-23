--!Type(Module)

-- This file handles teleporting the players around on every client when the server
-- requires it.

--!SerializeField
local gameArea : GameObject = nil
--!SerializeField
local observationDeck : GameObject = nil

TeleportRequest = Event.new("TeleportRequest")

function SendPlayerToGameArea(player: Player)
    TeleportRequest:FireAllClients(player, "gameArea", Vector3.new(math.random(-6, 6), 0, math.random(-2, 2)))
end

function SendPlayerToObservationDeck(player: Player)
    TeleportRequest:FireAllClients(player, "observationDeck", Vector3.new(math.random(-6, 6), 0, math.random(-1, 1)))
end

function self:ClientAwake()
    TeleportRequest:Connect(function(player: Player, dest: "gameArea" | "observationDeck", jitter: Vector3?)
        if dest == "gameArea" then
            player.character:Teleport(gameArea.transform.position + (jitter or Vector3.zero))
        elseif dest == "observationDeck" then
            player.character:Teleport(observationDeck.transform.position + (jitter or Vector3.zero))
        end
    end)
end
