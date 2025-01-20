--!Type(UI)

--!Bind
local _news : UILabel = nil
--!Bind
local _button : UIButton = nil
print("Registering Press callback...")

-- Register a callback for when the button is pressed
local counter = 0
_button:RegisterPressCallback(function()
    counter = counter + 1 -- Increment the counter
    print("Updating counter: "..tostring(counter))
    _news:SetPrelocalizedText("Count: "..tostring(counter)) -- Update the label text
end)

print("Registered Press callback")