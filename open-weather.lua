local awful = require("awful")
local wibox = require("wibox")
local json = require("json")
local http = require("socket.http")

local apikey = 'e66e2f85e64d284b53877705a7f59d56'
local city_id = '2962153'

-- weather indicator (openweathermap.org)

local indicator = { mt = {}, wmt = {} }
indicator.wmt.__index = indicator

local function trim(s)
  if s == nil then return nil end
  -- from PiL2 20.4
  return (s:gsub("^%s*(.-)%s*$", "%1"))
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
    
    sw.info = nil
    sw.description = nil
    sw.icon = nil
    sw.temp = nil
    sw.feels_like = nil
    sw.pressure = nil
    sw.humidity = nil
    sw.wind = nil

    sw.widget = wibox.widget.textbox()
    sw.widget.set_align("right")
    sw.tooltip = awful.tooltip({objects={sw.widget}})

    sw.timer = timer({ timeout = args.timeout or 900 }) -- refresh every 15 mins
    sw.timer:connect_signal("timeout", function() sw:update() end)
    sw.timer:start()

    sw:update()

    return sw
end

function indicator:update()
    -- update widget text
    local response = http.request("https://api.openweathermap.org/data/2.5/weather?id=" .. city_id .. "&APIKEY=" .. apikey)
    local parsed_response = json.decode(response)

    self.info = parsed_response['weather'][1]['main']
    self.description = parsed_response['weather'][1]['description']
    self.icon = parsed_response['weather'][1]['icon']

    self.temp = parsed_response['main']['temp']
    self.feels_like = tonumber(parsed_response['main']['feels_like']) - 273.15
    self.pressure = parsed_response['main']['pressure']
    self.humidity = parsed_response['main']['humidity']
    self.wind = parsed_response['wind']['speed']
    self.dt = os.date("%x %X", tonumber(parsed_response['dt']))

    local text = "  " .. self.info .. " " .. (tonumber(self.temp) - 273.15) .. "℃  " .. self.wind .. " m/s  "
    local text_dropdown = self.description .. "\n\nFeels like: " .. self.feels_like .. "℃ \nPressure: " .. self.pressure .. "\nHumidity: " .. self.humidity .. "%\n\n" .. self.dt
    self.widget:set_text(text)
    self.tooltip:set_text(text_dropdown)
end

function indicator.mt:__call(...)
    return indicator.new(...)
end

return setmetatable(indicator, indicator.mt)
