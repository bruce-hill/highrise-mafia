--!Type(Module)

--!SerializeField
local lobbyArea: GameObject = nil
--!SerializeField
local dayArea: GameObject = nil
--!SerializeField
local nightArea: GameObject = nil

local goToEvent: Event = Event.new("GoToZone")
local isServer: boolean = false

type ZoneName = "Lobby" | "Day" | "Night"

function SendTo(player: Player, zoneName: ZoneName)
    if isServer then
        goToEvent:FireClient(player, zoneName)
    else
        print("Sending character: "..tostring(player).." to zone: "..zoneName)
        if not player.character then
            print("No player character!")
            return
        end

        if zoneName == "Day" then
            player.character:Teleport(dayArea.transform.position)
        elseif zoneName == "Night" then
            player.character:Teleport(nightArea.transform.position)
        elseif zoneName == "Lobby" then
            player.character:Teleport(lobbyArea.transform.position)
        else
            error("Invalid zone name: "..tostring(zoneName))
        end
    end
end

function self:ServerAwake()
    isServer = true
end

function self:ClientAwake()
    goToEvent:Connect(function(zoneName: ZoneName)
        SendTo(client.localPlayer, zoneName)
    end)
end