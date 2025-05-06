
-- Root, a simple OOP based Luvit router
--           @code-nuage

local url = require("url")

local moreutils = require("./more-utils")

local root = {}
root.__index = root

function root.new_router()
    local i = setmetatable({}, root)

    i.routes = {}

    return i
end

function root:add_route(route, controller)
    local keys = {}

    local pattern = route:gsub("(:%w+)", function(key)
        table.insert(keys, key:sub(2))
        return "([^/]+)"
    end)

    pattern = "^" .. pattern .. "$"

    table.insert(self.routes, {
        pattern = pattern,
        keys = keys,
        controller = controller
    })

    return self
end

function root:set_not_found(controller)
    self.not_found_controller = controller
    return self
end

function root:handle_request(req, res)
    local parsed = url.parse(req.url)
    local path = parsed.pathname

    for _, route in ipairs(self.routes) do
        local matches = {path:match(route.pattern)}
        if #matches > 0 then
            req.params = {}
            for i, key in ipairs(route.keys) do
                req.params[key] = matches[i]
            end
            return route.controller(req, res)
        end
    end

    if self.not_found_controller and type(self.not_found_controller) == "function" then
        self:route_not_found(req, res)
    else
        res:writeHead(404, {["Content-Type"] = "text/plain"})
        res:finish("Error 404 - Route not found")
    end
end

function root:route_not_found(req, res)
    self.not_found_controller(req, res)
end

return root
