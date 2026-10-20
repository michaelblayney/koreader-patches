-- version: 1.3.1
-- File browser: drop the "KOReader" title and move the folder path (☆ Home) up into its place,
-- between the home and + icons. The bar loses a row, so the covers get more room.

local FileManager = require("apps/filemanager/filemanager")
local Font = require("ui/font")
local Blitbuffer = require("ffi/blitbuffer")
local Screen = require("device").screen
local Size = require("ui/size")
local TitleBar = require("ui/widget/titlebar")

local Title = {
    hide_on_home = true, -- no text in the home folder, just the home and + icons; path everywhere else
    font = "NotoSans-Italic.ttf", -- italic (becomes Noto Serif Italic with 2-serif-ui)
    font_size = 24, -- same size as the bold title font
    underline = false,
    underline_gap = Screen:scaleBySize(2), -- space between the text baseline and the line
    underline_thickness = Size.line.medium,
}

-- The file browser builds its title bar inside setupLayout, and sizes the file list from the
-- bar's height right after, so the bar has to be built without the extra row in the first place.
local orig_setupLayout = FileManager.setupLayout
function FileManager:setupLayout(...)
    local had_own_new = rawget(TitleBar, "new")
    local orig_new = TitleBar.new
    TitleBar.new = function(class, o)
        if o and o.title == self.title then
            o.title = ""
            o.subtitle = nil -- no second row
            -- looked up here, not at load, so patches that load after this one (2-serif-ui) apply
            o.title_face = Font:getFace(Title.font, Title.font_size)
            local bar = orig_new(class, o)
            if Title.underline then
                -- the title TextWidget is kept and just gets new text on folder changes,
                -- so drawing the line in its paintTo follows the text's width
                local text = bar.title_widget
                local orig_paintTo = text.paintTo
                text.paintTo = function(this, bb, x, y)
                    orig_paintTo(this, bb, x, y)
                    local w = this:getWidth()
                    if w > 0 then
                        bb:paintRect(x, y + this:getBaseline() + Title.underline_gap, w,
                            Title.underline_thickness, this.fgcolor or Blitbuffer.COLOR_BLACK)
                    end
                end
            end
            return bar
        end
        return orig_new(class, o)
    end
    local ok, err = pcall(orig_setupLayout, self, ...)
    TitleBar.new = had_own_new
    if not ok then error(err, 0) end
end

-- The path normally goes in the subtitle; put it in the title instead
function FileManager:updateTitleBarPath(path)
    local BD = require("ui/bidi")
    local filemanagerutil = require("apps/filemanager/filemanagerutil")
    path = path or self.file_chooser.path
    local text = self.folder_shortcuts:getShortcutFullName(path) or BD.directory(filemanagerutil.abbreviate(path))
    local home = filemanagerutil.getHomeFolder()
    local at_home = home and path:gsub("/+$", "") == home:gsub("/+$", "")
    self.title_bar:setTitle((Title.hide_on_home and at_home) and "" or text)
end
FileManager.onPathChanged = FileManager.updateTitleBarPath
