--!Type(Client)

-- This file switches the floor between yellow (day) and blue (night)

local News = require "News"

--!SerializeField
local floor: GameObject = nil
--!SerializeField
local dayMaterial: Material = nil
--!SerializeField
local nightMaterial: Material = nil

function self:ClientAwake()
    local floorRenderer: MeshRenderer = floor:GetComponent(MeshRenderer)
    News.NewsEvent:Connect(function(event)
        if event.type == "state_changed" and event.state == "day" then
            floorRenderer:SetMaterials({dayMaterial})
        elseif event.type == "state_changed" and event.state == "night" then
            floorRenderer:SetMaterials({nightMaterial})
        end
    end)
end