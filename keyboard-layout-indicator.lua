local awful = require("awful")
local wibox = require("wibox")

-- Keyboard Layout Switcher
-- Keyboard map indicator and changer

-- indicator.mt: module (class) metatable
-- indicator.wmt: widget (instance) metatable
local indicator = { mt = {}, wmt = {} }
indicator.wmt.__index = indicator


local function trim(s)
  if s == nil then return nil end
  -- from PiL2 20.4
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function findindex(array, match)
    for k,v in pairs(array) do
        if match(v) then
            return k
        end
    end
    return nil
end

local function readall(file)
    local text = file:read('*all')
    file:close()
    return text
end

local function readcommand(command)
    return readall(io.popen(command))
end


function indicator.new(args)
    local sw = setmetatable({}, indicator.wmt)

    sw.cmd = "setxkbmap"
    sw.layouts = args.layouts

    sw.index = 1     -- 1-based index!
    sw.current = nil

    sw.widget = wibox.widget.textbox()
    sw.widget.set_align("right")

    sw.widget:buttons(awful.util.table.join(
        awful.button({ }, 1, function() sw:next() end),
        awful.button({ }, 3, function() sw:prev() end),
        awful.button({ }, 4, function() sw:prev() end),
        awful.button({ }, 5, function() sw:next() end)
    ))

    sw.timer = timer({ timeout = args.timeout or 1 })
    sw.timer:connect_signal("timeout", function() sw:update() end)
    sw.timer:start()
    sw:get()
    return sw
end

function indicator:set(i)
    -- set current index
    self.index = ((i-1)+#(self.layouts)) % #(self.layouts) + 1
    self.current = self.layouts[self.index]
    self:update()
    -- execute command
    local cmd
    if self.current.command then
        cmd = self.current.command
    else
        cmd = self.cmd .. " " .. self.current.layout
        if self.current.variant then
            cmd = cmd .. " " .. self.current.variant
        end
    end
    cmd = cmd .. " -option alt:leftaltismeta -option caps:escape"
    os.execute( cmd )
end

function indicator:setcustom(str)
    os.execute(str)
    self:get()
end

function indicator:update()
    -- update widget text
    self.widget:set_text(self.current.name)
end

function indicator:get(i)
    -- parse current layout from setxkbmap
    local status = readcommand(self.cmd .. " -query")
    local layout = trim(string.match(status, "layout:%s+(%a+)"))
    local variant = trim(string.match(status, "variant:([^\n]*)"))

    -- find layout in self.layouts
    local index = findindex(self.layouts,
        function (v)
            return v.layout == layout and v.variant == variant 
        end)
    if index == nil then
        self.current = {color="yellow"}
        if variant then
            self.current.name = layout.."/"..variant
        else
            self.current.name = layout
        end
    else
        self.index = tonumber(index)
        self.current = self.layouts[index]
    end
    -- update widget
    self:update()
end

function indicator:next()
    self:set(self.index + 1)
end

function indicator:prev()
    self:set(self.index - 1)
end

function indicator.mt:__call(...)
    return indicator.new(...)
end

return setmetatable(indicator, indicator.mt)

