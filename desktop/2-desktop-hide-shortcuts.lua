-- Desktop dev only: hide the Q/W/E... keyboard shortcut labels in menus,
-- so the file browser looks like it does on the Kindle.
local Device = require("device")
if Device:isSDL() then
    require("ui/widget/menu").is_enable_shortcut = false
end
