--!Type(Client)

--!SerializeField
local offset : Vector3 = Vector3.zero

local News = require "News"

type NewsEvent = {type:"new_game"} | {type:"game_over", winner: "mafia" | "citizens"} | {type: "player_killed", player: Player}
    | {type: "role_revealed", player: Player, role: string} | {type: "state_changed", state: "waiting" | "night" | "day" | "gameover"} | {type: "role_assigned", player: Player, role: string}
    | {type: "start_countdown", duration: number}

function self:ClientAwake()
    News.NewsEvent:Connect(function(event: NewsEvent)
        if event.type == "new_game" then
            HideRole()
        elseif event.type == "role_revealed" then
            if event.player.character == self.gameObject.transform.parent:GetComponent(Character) then
                ShowRole(event.role)
            end
        elseif event.type == "player_killed" then
            if event.player.character == self.gameObject.transform.parent:GetComponent(Character) then
                ShowRole("corpse")
            end
        end
    end)
end

function self:LateUpdate()
    self.transform.eulerAngles = Camera.main.transform.eulerAngles + offset
end

function ShowRole(role: string)
    for i=1,self.gameObject.transform.childCount do
        local image: Transform = self.gameObject.transform:GetChild(i-1)
        image.gameObject:SetActive(image.name == role)
    end
end

function HideRole()
    for i=1,self.gameObject.transform.childCount do
        local image: Transform = self.gameObject.transform:GetChild(i-1)
        image.gameObject:SetActive(false)
    end
end
