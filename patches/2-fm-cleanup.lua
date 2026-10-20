-- version: 1.2.1
-- File browser cleanup: strip things out of the file browser that aren't needed.

local FileChooser = require("ui/widget/filechooser")
local FileManager = require("apps/filemanager/filemanager")
local Screen = require("device").screen

local Cleanup = {
    hide_page_arrows = true, -- the « ‹ › » buttons around "Page x of y"; swiping still turns pages
    home_icon_offset_x = Screen:scaleBySize(9), -- move the home icon right (negative: left)
    home_icon_offset_y = Screen:scaleBySize(5), -- move the home icon down (negative: up)
    plus_icon_offset_x = -Screen:scaleBySize(3), -- move the + icon right (negative: left)
    plus_icon_offset_y = nil, -- move the + icon down; nil = same as the home icon, so they line up
}
if Cleanup.plus_icon_offset_y == nil then Cleanup.plus_icon_offset_y = Cleanup.home_icon_offset_y end

local orig_updatePageInfo = FileChooser.updatePageInfo
function FileChooser:updatePageInfo(...)
    orig_updatePageInfo(self, ...)
    if self.name ~= "filemanager" then return end -- leave folder pickers and other file lists alone

    if Cleanup.hide_page_arrows then
        -- hidden buttons still take taps, so disable them too; they keep their space,
        -- which keeps "Page x of y" centred
        for _, chev in ipairs { self.page_info_first_chev, self.page_info_left_chev,
                                self.page_info_right_chev, self.page_info_last_chev } do
            chev:hide()
            chev:disable()
        end
    end
end

-- Nudge the home and + icons. The title bar lays its buttons out in an overlap group, which paints a
-- child at an explicit offset when it has one; the tap zone follows the painted position.
local orig_setupLayout = FileManager.setupLayout
function FileManager:setupLayout(...)
    orig_setupLayout(self, ...)
    local button = self.title_bar and self.title_bar.left_button
    if button and (Cleanup.home_icon_offset_x ~= 0 or Cleanup.home_icon_offset_y ~= 0) then
        button.overlap_offset = { Cleanup.home_icon_offset_x, Cleanup.home_icon_offset_y }
    end
    -- The + button is right-aligned, and right alignment wins over an offset in the overlap
    -- group, so shift it while it paints instead (its tap zone is set there too)
    local plus = self.title_bar and self.title_bar.right_button
    if plus and (Cleanup.plus_icon_offset_x ~= 0 or Cleanup.plus_icon_offset_y ~= 0) then
        local orig_paintTo = plus.paintTo
        plus.paintTo = function(this, bb, x, y)
            return orig_paintTo(this, bb, x + Cleanup.plus_icon_offset_x, y + Cleanup.plus_icon_offset_y)
        end
    end
end
