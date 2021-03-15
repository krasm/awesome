local imap = require "imap"
local function prompt(str) io.write(str); return io.read() end

local gmail = imap.connect("imap.gmail.com", 993, true)
gmail:capability()

local username = prompt "Username: "
local password = prompt "Password: "
gmail:login(username, password)

-- open Inbox
gmail:select "Inbox"

-- load 1st message headers
local headers = gmail:fetch "1 FULL"
print('==== HEADERS ====')
print(table.concat(headers, '\n'))

-- load 1st message body text
local message = gmail:fetch "1 BODY[TEXT]"
print('==== BODY ====')
print(table.concat(message, '\n'))
