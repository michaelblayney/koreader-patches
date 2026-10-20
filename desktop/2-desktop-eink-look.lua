-- version: 1.1.0
-- desktop-only: never send to the e-reader
-- Desktop dev only: make the emulator window look like the Paperwhite's e-ink screen.
-- 16 grey levels with ordered dithering, tinted paper, grey ink, frontlight brightness.
-- Needs the emulator in greyscale mode (EMULATE_BB_TYPE=BB8).
-- EINK_LOOK picks the preset: lit (default), unlit, or plain/0 to turn the look off.

local Common = {
    levels = 16, -- grey levels the panel can show
    dither = true, -- ordered 4x4 dithering, so gradients don't band
}

local Presets = {
    -- frontlight on
    lit = {
        paper = { 243, 231, 200 }, -- white, before brightness (warm: device warmth 14/24)
        ink = { 40, 40, 40 }, -- black, before brightness
        brightness = 0.90, -- 1 = full
    },
    -- frontlight off: the screensaver tool's values, checked side by side against the Kindle
    unlit = {
        paper = { 222, 250, 240 },
        ink = { 40, 40, 40 },
        brightness = 0.53,
    },
}

local Device = require("device")
local mode = os.getenv("EINK_LOOK") or "lit"
if not Device:isSDL() or not os.getenv("EMULATE_BB_TYPE") or mode == "0" or mode == "plain" then return end
local Look = Presets[mode] or Presets.lit
Look.levels, Look.dither = Common.levels, Common.dither

local ffi = require("ffi")
local bit = require("bit")
local SDL = require("ffi/SDL3")
local Screen = Device.screen

-- One 256-entry colour table per cell of the 4x4 dither pattern, so the per-pixel work is a lookup.
local bayer = { 0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5 }
local step = 255 / (Look.levels - 1)
local lut = ffi.new("ColorRGB32[?]", 16 * 256)
for cell = 0, 15 do
    local offset = Look.dither and (bayer[cell + 1] + 0.5) / 16 - 0.5 or 0
    for v = 0, 255 do
        local level = math.floor(v / step + offset + 0.5)
        level = math.max(0, math.min(Look.levels - 1, level))
        local t = level / (Look.levels - 1)
        local c = lut[cell * 256 + v]
        c.r = math.floor(Look.brightness * (Look.ink[1] + t * (Look.paper[1] - Look.ink[1])) + 0.5)
        c.g = math.floor(Look.brightness * (Look.ink[2] + t * (Look.paper[2] - Look.ink[2])) + 0.5)
        c.b = math.floor(Look.brightness * (Look.ink[3] + t * (Look.paper[3] - Look.ink[3])) + 0.5)
        c.alpha = 0xFF
    end
end

local band = bit.band

-- Same as the emulator's own greyscale _render (ffi/framebuffer_SDL3.lua), with the lookup swapped in.
-- The dither pattern follows screen coordinates, so it stays put across partial refreshes.
function Screen:_render(bb, x, y, w, h)
    local px, py, pw, ph = bb:getPhysicalRect(x, y, w, h)
    local bb_rect = bb:viewport(x, y, w, h)
    local sdl_rect = SDL.rect(px, py, pw, ph)

    local vbuf = ffi.new("ColorRGB32[?]", pw * ph)
    local pos = 0
    for vy = 0, ph - 1 do
        local row = band(py + vy, 3) * 4
        for vx = 0, pw - 1 do
            local v = bb_rect:getPixelP(vx, vy)[0]:getColor8().a
            vbuf[pos] = lut[(row + band(px + vx, 3)) * 256 + v]
            pos = pos + 1
        end
    end
    SDL.SDL.SDL_UpdateTexture(SDL.texture, sdl_rect, vbuf, pw * 4)

    SDL.SDL.SDL_RenderClear(SDL.renderer)
    SDL.SDL.SDL_RenderTexture(SDL.renderer, SDL.texture, nil, nil)
    SDL.SDL.SDL_RenderPresent(SDL.renderer)
end

-- repaint now, so the look applies without waiting for the next screen change
local UIManager = require("ui/uimanager")
UIManager:nextTick(function() UIManager:setDirty("all", "full") end)
