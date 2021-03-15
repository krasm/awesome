local wibox        = require("wibox")

local temp = { mt = {}, wmt = {} }

function temp.new(args)
    local t = setmetatable({}, temp.wmt)

    local args     = args or {}
    local tempfile = args.tempfile or "/sys/class/thermal/thermal_zone0/temp"

    t.widget = wibox.widget.textbox()

    function temp.update()
        local f = io.open(tempfile)
        if f then
            coretemp_now = tonumber(f:read("*line")) / 1000
            f:close()
        else
            coretemp_now = "N/A"
        end
		
		if coretemp_now > 95 then
			coretemp_now = "<span color=\"red\">" .. coretemp_now .. "</span>"
		end

        widget = t.widget
		widget:set_markup( " 🌡" .. coretemp_now .. "℃ ")
    end

	t.timer = timer({ timeout = args.timeout or 1 })
	t.timer:connect_signal("timeout", temp.update)
    t.timer:start()

	temp.update()

    return t
end

function temp.mt:__call(...) 
    return temp.new(...)
end

return setmetatable(temp, temp.mt)


