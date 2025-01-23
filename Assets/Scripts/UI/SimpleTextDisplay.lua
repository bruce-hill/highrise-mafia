--!Type(UI)

--!SerializeField
local text : string = ""
--!Bind
local label : Label = nil

function self:ClientAwake()
    label.text = text
end
