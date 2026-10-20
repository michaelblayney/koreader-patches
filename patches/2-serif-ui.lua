-- version: 1.1.0
-- Use Noto Serif instead of Noto Sans for KOReader's interface: menus, file browser, titles,
-- dialogs, footer. Book text is a separate setting (font menu in the reader) and isn't touched.
-- Monospace fonts stay as they are. All the Noto Serif files ship with KOReader.

local Font = require("ui/font")

local serif = {
    ["NotoSans-Regular.ttf"] = "NotoSerif-Regular.ttf",
    ["NotoSans-Bold.ttf"] = "NotoSerif-Bold.ttf",
    ["NotoSans-Italic.ttf"] = "NotoSerif-Italic.ttf",
    ["NotoSans-BoldItalic.ttf"] = "NotoSerif-BoldItalic.ttf",
}

-- named UI fonts (cfont, tfont, ffont...)
for name, file in pairs(Font.fontmap) do
    if serif[file] then Font.fontmap[name] = serif[file] end
end

-- code that asks for a Noto Sans file by name instead of through the map
local orig_getFace = Font.getFace
function Font:getFace(font, size, faceindex)
    if font and serif[font] then font = serif[font] end
    return orig_getFace(self, font, size, faceindex)
end

-- Some widgets (title bar, dialogs, buttons...) pick their fonts once, when their module is
-- first loaded, which can happen before patches run. Swap any Noto Sans face they already
-- hold in their class defaults; modules loaded from here on get serif by themselves.
for _, module in pairs(package.loaded) do
    if type(module) == "table" and module ~= Font then
        for key, value in pairs(module) do
            if type(value) == "table" and value.orig_font and value.orig_size and serif[value.realname] then
                module[key] = Font:getFace(value.orig_font, value.orig_size)
            end
        end
    end
end
