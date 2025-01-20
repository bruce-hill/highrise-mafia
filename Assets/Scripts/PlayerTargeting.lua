--!Type(Module)

local _playerTargets: {[Player]: Player?} = {}

Targets = _playerTargets

local playerChoseTarget: Event = Event.new("PlayerChoseTarget")
local clearTargets: Event = Event.new("ClearTargets")

local isServer = false

function ClearTargets()
    if isServer then
        clearTargets:FireAllClients()
    end
end

function self:ServerAwake()
    isServer = true
    playerChoseTarget:Connect(function(player: Player, target: Player?)
        if target then
            print(player.name.." targeted "..target.name)
        else
            print(player.name.." deselected their target")
        end
        _playerTargets[player] = target
    end)
end

function self:ClientAwake()
    local function setTarget(target: Player?)
        local oldTarget: Player? = _playerTargets[client.localPlayer]
        if oldTarget then
            oldTarget.character.gameObject.transform:Find("Crosshairs"):GetComponent(Renderer).enabled = false
        end

        _playerTargets[client.localPlayer] = target

        if target then
            target.character.gameObject.transform:Find("Crosshairs"):GetComponent(Renderer).enabled = true
        end
        playerChoseTarget:FireServer(target)
    end

    clearTargets:Connect(function()
        local oldTarget: Player? = _playerTargets[client.localPlayer]
        if oldTarget then
            oldTarget.character.gameObject.transform:Find("Crosshairs"):GetComponent(Renderer).enabled = false
            _playerTargets[client.localPlayer] = nil
        end
    end)

    -- playerChoseTarget:Connect(function(player: Player, target: Player)
    --     _playerTargets[player] = target
    -- end)

    scene.PlayerJoined:Connect(function(scene, player)
        player.CharacterChanged:Connect(function(player: Player, character: Character)
            if character then
                local tapHandler: TapHandler = character.gameObject:GetComponent(TapHandler)
                if player == client.localPlayer then
                    tapHandler.enabled = false
                else
                    tapHandler.Tapped:Connect(function()
                        -- Toggle targeting on tap
                        if _playerTargets[client.localPlayer] == player then
                            setTarget(nil)
                        else
                            setTarget(player)
                        end
                    end)
                end
            end
        end)
    end)
end