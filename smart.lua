local awful = require("awful")
local wibox = require("wibox")

local vcontrol = { mt = {}, wmt = {} }
vcontrol.wmt.__index = vcontrol

local function readcommand(cmd) 
    local file = io.popen(cmd)
    local text = file:read('*all')
    file:close()
    return text
end

local function getstate(hdd)
    local cmd = "sudo /usr/sbin/smartctl " .. hdd .. " -H"
    local raw = readcommand(cmd)

    local state = string.match(raw, "SMART.+result:%s*(%a+)")
    return state
end

local function check(args) 
    local ret = {}
    for _, v in ipairs(args) do 
        print('v: ', v[1])
        ret[#ret+1] = {v, getstate(v)}
    end 
    return ret
end

local function fg(color, text)
    if color == nil then
        return text
    else
        return '<span color="' .. color .. '">' .. text .. '</span>'
    end
end

function vcontrol.new(...)
    local sw = setmetatable({}, vcontrol.wmt)

    sw.hddids  = {...}

    sw.widget = wibox.widget.textbox()
    sw.widget.set_align("right")
    sw.tooltip = awful.tooltip({objects={sw.widget}})

    sw.timer = timer({ timeout = 600 })
    sw.timer:connect_signal("timeout", function() sw:get() end)
    sw.timer:start()
    sw:get()

    return sw
end

function vcontrol:get()
    self:update(check(self.hddids))
end

function vcontrol:update(results)
    local status = true
    local details = ''
    local text = '🖫' --'🖴'
    for _,v in ipairs(results) do
        details = details .. v[1] .. ' ' .. v[2] .. '\n'
        if v[2] ~= 'PASSED' then
            status = false
        end
    end
    if status then
        text = fg('yellow', text)
    else
        text = fg('red', text)
    end 

    self.widget:set_markup(' ' .. text .. ' ')
    self.tooltip:set_text(details)
end


function vcontrol.mt:__call(...)
    return vcontrol.new(...)
end

return setmetatable(vcontrol, vcontrol.mt)
