--!Type(UI)

-- This script shows a player's username and role (if known) above their head

--!Bind
local nameLabel: Label = nil
--!Bind
local roleLabel: Label = nil
--!Bind
local roleIcon: VisualElement = nil

local News = require "News"

local function ShowRole(role: string?)
    roleLabel.text = role and role:gsub("^%l", string.upper) or ""
    for _,r in ipairs({"mafioso", "townsperson", "detective", "corpse", "observer"}) do
        roleLabel:EnableInClassList(r, r == role)
        roleIcon:EnableInClassList(r, r == role)
    end
end

function self:ClientAwake()
    local character: Character = self.gameObject:GetComponentInParent(Character, true)
    defer(function()
        nameLabel.text = character.player.name
    end)
    News.NewsEvent:Connect(function(news)
        if news.type == "role_revealed" and news.role and news.player == character.player then
            ShowRole(news.role)
        elseif news.type == "new_game" then
            ShowRole(nil)
        end
    end)

    News.SetRoleEvent:Connect(function(role:string, team:string)
        if character.player == client.localPlayer then
            ShowRole(role)
        end
    end)
end

function self:LateUpdate()
    self.transform.eulerAngles = Camera.main.transform.eulerAngles
end