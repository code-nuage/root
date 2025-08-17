
-- Root, a simple OOP based Luvit router
--           @code-nuage

local http = require("coro-http")
local json = require("json")

--+ UTILS +--
local colors = {
    reset =   "\27[0m",
    black =   "\27[31;1m",
    red =     "\27[31;1m",
    green =   "\27[32;1m",
    yellow =  "\27[33;1m",
    blue =    "\27[34;1m",
    magenta = "\27[35;1m",
    cyan =    "\27[36;1m",
    gray =    "\27[37;1m"
}

local function get_color_from_status_code(status)
    local hundreds_colors = {
        [1] = colors.blue,
        [2] = colors.green,
        [3] = colors.yellow,
        [4] = colors.red,
        [5] = colors.red,
    }

    local hundreds = math.floor(status / 100)

    return hundreds_colors[hundreds] or colors.red
end

local function get_color_from_method(method)
    local method_colors = {
        ["GET"] = colors.green,
        ["POST"] = colors.yellow,
        ["PUT"] = colors.blue,
        ["PATCH"] = colors.cyan,
        ["DELETE"] = colors.red,
        ["HEAD"] = colors.green,
        ["OPTIONS"] = colors.magenta,
    }

    return method_colors[method] or colors.gray
end

--+     ROOT     +--
local root = {}
root.__index = root

function root.new()
    local i = setmetatable({}, root)

    i.routes = {}
    i.host = nil
    i.port = nil

    return i
end

function root:bind(host, port)
    assert(type(host) == "string", "Argument <host> must be a string.")
    assert(type(port) == "number", "Argument <port> must be a number.")
    self.host, self.port = host, port
    return self
end

function root:set_route(route, method, controller)
    local keys = {}

    local pattern = route:gsub("(:%w+)", function(key)
        table.insert(keys, key:sub(2))
        return "([^/:]+)"
    end)

    pattern = "^" .. pattern .. "$"

    table.insert(self.routes, {
        ["Pattern"] = pattern,
        ["Method"] = method,
        ["Keys"] = keys,
        ["Controller"] = controller
    })

    return self
end

function root:set_not_found(controller)
    self.not_found_controller = controller
    return self
end

function root:not_found(req, res)
    if type(self.not_found_controller) == "function" then
        self.not_found_controller(req, res)
    else
        res["Status-Code"], res["Headers"]["Content-Type"], res["Body"] = 404, "text/plain", "No ressource found at " .. req["Path"]
    end
end

function root:handle_request(req, res)
    table.sort(self.routes, function(a, b)
        return #a["Keys"] < #b["Keys"]
    end)

    for _, route in ipairs(self.routes) do
        if route["Method"] == req["Method"] then
            local match = req:get_path():match(route["Pattern"])
            if match then
                local captures = {req:get_path():match(route["Pattern"])}
                for i, key in ipairs(route["Keys"]) do
                    req:set_param(key, captures[i])
                end
                return route["Controller"](req, res)
            end
        end
    end

    self:not_found(req, res)
end

function root:display_request(req, res)
    print("--+     " .. colors.blue .. req["Path"] .. colors.reset .. "     +--" .. colors.reset ..
    "\nClient: " .. colors.blue .. req["Headers"]["user-agent"] .. colors.reset ..
    "\nMethod: " .. get_color_from_method(req["Method"]) .. req["Method"] .. colors.reset ..
    "\nPath: " .. colors.blue .. req["Path"] .. colors.reset ..
    "\nStatus-Code: " .. get_color_from_status_code(res["Status-Code"]) .. res["Status-Code"] .. colors.reset ..
    "\n--+" .. string.rep(" ", #req["Path"] + 10) .. "+--\n")
end

--+ REQUEST +--
local request = {}
request.__index = request

function request.new(head, body)
    local i = setmetatable({}, request)

    i["HTTP-Version"] = head.version
    
    i["Path"] = head.path:gsub("%?.*$", "")
    i["Path"] = i["Path"] :gsub("/+$", "")
    if i["Path"] == "" then i["Path"]  = "/" end

    i["Method"] = head.method
    i["Headers"] = {}
    i["Body"] = nil
    i["Params"] = {}

    for _, header in ipairs(head) do
        local name, value = header[1], header[2]
        i["Headers"][name] = value
    end

    if body and body ~= "" then
        i["Body"] = body
    end

    return i
end

-- SETTERS
function request:set_param(name, value)
    self["Params"][name] = value
end

-- GETTERS
function request:get_http_ver()
    return self["HTTP-Version"]
end

function request:get_path()
    return self["Path"]
end

function request:get_method()
    return self["Method"]
end

function request:get_header(header)
    return self["Headers"][header]
end

function request:get_headers()
    return self["Headers"]
end

function request:get_body_raw()
    return true, self["Body"]
end

function request:get_body_json()
    local data = json.decode(self["Body"])
    if data then
        return true, data
    end
    return false, json.encode({error = "Unable to decode data"})
end

function request:get_params()
    return self["Params"]
end

function request:get_param(param)
    return self["Params"][param]
end

--+ RESPONSE +--
local response = {}
response.__index = response

function response.new()
    local i = setmetatable({}, response)

    i["HTTP-Version"] = nil
    i["Status-Code"] = nil
    i["Headers"] = {}
    i["Body"] = nil

    return i
end

-- SETTERS
function response:set_http_ver(http_ver)
    self["HTTP-Version"] = http_ver
    return self
end

function response:set_status(status_code)
    self["Status-Code"] = status_code
    return self
end

function response:set_header(name, value)
    self["Headers"][name] = value
    return self
end

function response:set_body(body)
    self["Body"] = body
    return self
end

-- GETTERS
function response:get_http_ver()
    return self["HTTP-Version"]
end

function response:get_status()
    return self["Status-Code"]
end

function response:get_header(name)
    return self["Headers"][name]
end

function response:get_headers()
    return self["Headers"]
end

function response:get_body()
    return self["Body"]
end

--+ START +--
function root:start()
    http.createServer(self.host, self.port, function(head, body)
        local req = request.new(head, body)

        local res = response.new()

        self:handle_request(req, res)
        self:display_request(req, res)

        local headers = {}
        for name, value in pairs(res:get_headers()) do
            table.insert(headers, {name, value})
        end

        return {
            code = res:get_status() or 500,
            reason = "OK",
            {"Content-Length", #res:get_body() or ""},
            table.unpack(headers),
            keepAlive = true
        }, res:get_body() or ""
    end)
end

return root
