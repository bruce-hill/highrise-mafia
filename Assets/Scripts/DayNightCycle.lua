--!Type(Client)

local News = require "News"

--!SerializeField
local floor: GameObject = nil
--!SerializeField
local dayMaterial: Material = nil
--!SerializeField
local nightMaterial: Material = nil

function self:ClientAwake()
    local floorRenderer: MeshRenderer = floor:GetComponent(MeshRenderer)
    News.SetGamePhaseEvent:Connect(function(gamePhase: string)
        if gamePhase == "day" then
            floorRenderer:SetMaterials({dayMaterial})
        elseif gamePhase == "night" then
            floorRenderer:SetMaterials({nightMaterial})
        end
    end)
end