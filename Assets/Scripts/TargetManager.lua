--!Type(Module)

PlayerChoseTargetEvent = Event.new("PlayerChoseTarget")
ShowTargetEvent = Event.new("ShowTarget")

function TellServerToTargetPlayer(target: Player?)
    PlayerChoseTargetEvent:FireServer(target)
end

function OnServerGaveTarget(callback: (Player?)->())
    ShowTargetEvent:Connect(callback)
end

function OnClientChoseTarget(callback: (Player, Player?)->())
    PlayerChoseTargetEvent:Connect(callback)
end

function TellClientToTargetPlayer(player: Player, target: Player?)
    ShowTargetEvent:FireClient(player, target)
end

function TellAllClientsToForgetTargets()
    ShowTargetEvent:FireAllClients(nil)
end

function self:ClientAwake()
    local playerCrosshairs: {[Player]: Renderer?} = {}

    local function putCrosshairsOnTarget(target: Player?)
        for player,crosshairs in pairs(playerCrosshairs) do
            if player == client.localPlayer then continue end
            crosshairs.enabled = (target == player)
        end
    end

    OnServerGaveTarget(function(target:Player?)
        putCrosshairsOnTarget(target)
    end)

    client.PlayerConnected:Connect(function(player: Player)
        player.CharacterChanged:Connect(function(player: Player, character: Character)
            playerCrosshairs[player] = character.gameObject.transform:Find("Crosshairs"):GetComponent(Renderer)
            local tapHandler: TapHandler = character.gameObject.gameObject:GetComponent(TapHandler)
            if player == client.localPlayer then
                tapHandler.enabled = false
            else
                tapHandler.Tapped:Connect(function()
                    local crosshairsRenderer: Renderer = character.gameObject.transform:Find("Crosshairs"):GetComponent(Renderer)
                    -- Toggle targeting on tap
                    print("Tapped on: "..player.name)
                    if crosshairsRenderer.enabled then
                        TellServerToTargetPlayer(nil)
                    else
                        TellServerToTargetPlayer(player)
                    end
                end)
            end
        end)
    end)

    client.PlayerDisconnected:Connect(function(player: Player)
        playerCrosshairs[player] = nil
    end)
end