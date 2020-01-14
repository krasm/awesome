require 'socket'
local ssl = require 'ssl'

local verbose = false -- turn to true to see all traffic

local IMAP = {}
local IMAP_META = {}

local function log(...)
	if verbose then return print(...) end
end

function IMAP.connect(host, port, usessl)
	local conn = socket.tcp()
	conn:connect(host, port)
	conn:setoption('tcp-nodelay', true)
	log('Connected to', conn:getpeername())
	if usessl then
		local params = {
		  mode = "client",
		  protocol = "tlsv1",
		  cafile = "cacert.pem",
		  verify = "peer",
		  options = "all",
		}
		conn = assert(ssl.wrap(conn, params))
		conn:dohandshake()
	end
	local OK = conn:receive()
	log('<', OK)

	return setmetatable({conn = conn, id = 1}, IMAP_META)
end

function IMAP_META:__gc()
	self.conn:close()
end

local function formatCommand(id, cmd, ...)
	local args = { n = select('#', ...) + 2, id, cmd:upper(), ... }
	local str = table.concat(args, ' ', 1, args.n)
	return str
end

function IMAP_META:command(cmd, ...)
	local id = string.format('a%04d', self.id)
	self.id = self.id + 1
	
	local str = formatCommand(id, cmd, ...)
	self.conn:send(str .. '\r\n')
	log('>', str)
	
	local res = {}
	repeat
		local line = self.conn:receive()
		log('<', line)
		res[#res + 1] = line
	until not line or type(line) == "string" and line:match('^'..id)
	return res
end

function IMAP_META.__index(t, k)
	if rawget(IMAP_META, k) then
		return IMAP_META[k]
	else
		return function(self, ...)
			return self:command(k, ...) 
		end
	end
end

return IMAP
