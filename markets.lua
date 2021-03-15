local awful = require("awful")
local wibox = require("wibox")
local request = require "http.request"
local json = require "json"

APIKEY='5E1LPPU8V4LFN9CB'
URL='https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=%s&apikey=%s'

function update(symbol, descr) 
    local url = URL:format(symbol, APIKEY)
    local headers, stream = assert(request.new_from_uri(url):go())
    local body = assert(stream:get_body_as_string())
    if headers:get ":status" ~= "200" then
        error(body)
    end
    local data = json.decode(body)

    local sym = data["Global Quote"]["01. symbol"]
    local price = data["Global Quote"]["05. price"]
    local change = data["Global Quote"]["10. change percent"]
    if change then 
        change = change:gsub("%%", "")
    end
    
    return sym, descr, price, tonumber(change)
end

--print(update("DJI", "Dow Jones"))
--print(update("GSPC", "S&P 500"))
--print(update("GC=F", "Gold"))
--
--
function indicator.new(args)
    local sw = setmetatable({}, indicator.wmt)

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
    local text_dropdown = ""

    text_dropdown = self.description .. "\n\nFeels like: " .. string.format("%3.1f", self.feels_like) .. "℃ \nPressure: " .. self.pressure .. "\nHumidity: " .. self.humidity .. "%\n\n" .. self.dt
    self.widget:set_text(text)
    self.tooltip:set_text(text_dropdown)
end

function indicator.mt:__call(...)
    return indicator.new(...)
end

return setmetatable(indicator, indicator.mt)
