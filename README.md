# Root - A Simple Luvit HTTP Router

Root is a lightweight, object-oriented HTTP router for Luvit applications, offering an elegant way to handle HTTP requests and define routes.

## Installation

To use Root, first make sure you have [Luvit](https://luvit.io/) installed, then copy the `root.lua` file into your project's directory.

## Basic Usage

```lua
local root = require("./root")

-- Create a new router instance
local app = root.new()

-- Configure the server
app:set_name("MyServer")
   :bind("0.0.0.0", 8080)

app:start()
```

## Router Configuration

### Methods

#### `root.new()`

Creates a new router instance.

#### `set_name(name)`

Sets the server name for logging purposes.

- **Parameters:**
    - `name` (string): The name to give to the server

#### `bind(host, port)`

Configures the server's host and port.

- **Parameters:**
    - `host` (string): The host address to bind to
    - `port` (number): The port number to listen on

#### `start()`

Starts the HTTP server with the configured settings.

## Route Handling

### Setting Routes

```lua
-- Define a simple route
app:set_route("/hello", "GET", function(req, res)
    res:set_status(200)
       :set_header("Content-Type", "text/plain")
       :set_body("Hello, World!")
end)

-- Route with parameters
app:set_route("/users/:id", "GET", function(req, res)
    local user_id = req:get_param("id")
    res:set_status(200)
       :set_header("Content-Type", "application/json")
       :set_body(json.encode({id = user_id}))
end)
```

#### `set_route(route, method, controller)`

Registers a new route handler.

- **Parameters:**
    - `route` (string): The URL pattern to match (supports `:param` syntax for parameters)
    - `method` (string): The HTTP method ("GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS")
    - `controller` (function): The handler function that receives `req` and `res` objects

#### `set_not_found(controller)`

Sets a custom 404 handler.

- **Parameters:**
    - `controller` (function): The handler function for 404 responses

## Request Object

The request object provides access to incoming request data.

### Methods

#### Getters

- `get_http_ver()`: Returns the HTTP version
- `get_path()`: Returns the request path
- `get_method()`: Returns the HTTP method
- `get_header(header)`: Returns a specific header value
- `get_headers()`: Returns all headers
- `get_body_raw()`: Returns the raw request body
- `get_body_json()`: Attempts to parse and return the body as JSON
- `get_params()`: Returns all route parameters
- `get_param(param)`: Returns a specific route parameter

## Response Object

The response object allows you to construct the HTTP response.

### Methods

#### Setters

- `set_http_ver(http_ver)`: Sets the HTTP version
- `set_status(status_code)`: Sets the response status code
- `set_header(name, value)`: Sets a response header
- `set_body(body)`: Sets the response body

#### Getters

- `get_http_ver()`: Gets the HTTP version
- `get_status()`: Gets the status code
- `get_header(name)`: Gets a specific header value
- `get_headers()`: Gets all headers
- `get_body()`: Gets the response body

## Example Application

Here's a complete example showing various features:

```lua
local root = require("./root")
local json = require("json")

local app = root.new()

-- Configure the server
app:set_name("APIServer")
   :bind("0.0.0.0", 3000)

-- Add some routes
app:set_route("/", "GET", function(req, res)
    res:set_status(200)
       :set_header("Content-Type", "text/plain")
       :set_body("Welcome to the API!")
end)

app:set_route("/api/users/:id", "GET", function(req, res)
    local user_id = req:get_param("id")
    res:set_status(200)
       :set_header("Content-Type", "application/json")
       :set_body(json.encode({id = user_id, name = "John Doe"}))
end)

-- Custom 404 handler
app:set_not_found(function(req, res)
    res:set_status(404)
       :set_header("Content-Type", "application/json")
       :set_body(json.encode({error = "Resource not found", path = req:get_path()}))
end)

app:start()
```

## Features

- Route parameters with `:param` syntax
- Automatic HTTP status color coding in logs
- Request method color coding
- Customizable 404 handling
- JSON body parsing
- Header management
- Clean and readable logging output

## Note

This router is designed for use with the Luvit runtime environment and requires the following Luvit modules:

- `coro-http`
- `json`
