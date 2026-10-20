-- version: 1.0.0
-- Never draw the black focus underline under items in the Mosaic and list file browser views.
-- KOReader forces focus onto the folder you just came back out of, which underlines it even on
-- touch devices. This keeps the focus logic as is and just never paints the line.

local userpatch = require("userpatch")

local function patchCoverBrowser(plugin)
    local views = {
        { module = "mosaicmenu", item = "MosaicMenuItem" },
        { module = "listmenu", item = "ListMenuItem" },
    }
    for _, view in ipairs(views) do
        local ok, Menu = pcall(require, view.module)
        local Item = ok and Menu._updateItemsBuildUI and userpatch.getUpValue(Menu._updateItemsBuildUI, view.item)
        if Item then
            -- the underline stays its default white; focus just doesn't turn it black anymore
            Item.onFocus = function() return true end
        end
    end
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowser)
