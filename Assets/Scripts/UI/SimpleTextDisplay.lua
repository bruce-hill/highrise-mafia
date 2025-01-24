--!Type(UI)

-- A simple UI for showing static text floating in the world.

--!SerializeField
local text : string = ""
--!Bind
local label : Label = nil

function self:ClientAwake()
    label.text = text
end
