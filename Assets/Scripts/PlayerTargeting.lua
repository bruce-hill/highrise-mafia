--!Type(Client)

-- local TargetManager = require "TargetManager"

-- local target: Player? = nil

-- TargetManager.OnServerGaveTarget(function(newTarget:Player?)
--     local oldTarget: Player? = target
--     if oldTarget then
--         oldTarget.character.gameObject.transform:Find("Crosshairs"):GetComponent(Renderer).enabled = false
--     end

--     target = newTarget

--     if target then
--         target.character.gameObject.transform:Find("Crosshairs"):GetComponent(Renderer).enabled = true
--     end
-- end)

-- function self:Awake()
--     scene.PlayerJoined:Connect(function(scene: Scene, somePlayer: Player)
--         somePlayer.CharacterChanged:Connect(function(somePlayer: Player, character: Character)
--             if not character then return end
--             local tapHandler: TapHandler = character.gameObject:GetComponent(TapHandler)
--             if somePlayer == client.localPlayer then
--                 tapHandler.enabled = false
--             else
--                 tapHandler.Tapped:Connect(function()
--                     -- Toggle targeting on tap
--                     if target == somePlayer then
--                         TargetManager.TellServerToTargetPlayer(nil)
--                     else
--                         TargetManager.TellServerToTargetPlayer(somePlayer)
--                     end
--                 end)
--             end
--         end)
--     end)
-- end