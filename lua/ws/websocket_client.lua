local Url = require("ws.url")
local uv = vim.loop

local WebSocketClient = {}

function WebSocketClient:new(address)
  local o = {
    address = Url.parse(address),
    __tcp_client = uv.new_tcp(),
    __handlers = {},
    -- TODO: implement webhook key generator
    __generator_strategy = function()
      return "dummy-key"
    end,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function WebSocketClient:on_open(_) end

function WebSocketClient:on_close(_) end

function WebSocketClient:on_error(on_error)
  self.__handlers.on_error = on_error
end

function WebSocketClient:on_message(_) end

local function get_ipaddress(hostname)
  local addr_info = uv.getaddrinfo(hostname)
  for _, value in ipairs(addr_info) do
    if value.family == "inet" and value.protocol == "tcp" then
      return value.addr
    end
  end
end

function WebSocketClient:set_websocket_key_generator_strategy(generator_strategy)
  self.__generator_strategy = generator_strategy
end

function WebSocketClient:generate_websocket_key()
  return self.__generator_strategy()
end

function WebSocketClient:connect()
  local ip_addr = get_ipaddress(self.address.host)

  if not ip_addr then
    return self.__handlers.on_error("ENOTFOUND")
  end

  self.__tcp_client:connect(ip_addr, self.address.port, function(err)
    if err then
      return self.__handlers.on_error(err)
    end
    self.__tcp_client:write("GET / HTTP/1.1\r\n")
    self.__tcp_client:write("Host: " .. self.address.host .. ":" .. self.address.port .. "\r\n")
    self.__tcp_client:write("Upgrade: websocket\r\n")
    self.__tcp_client:write("Connection: Upgrade\r\n")
    self.__tcp_client:write("Sec-WebSocket-Key: " .. self:generate_websocket_key() .. "\r\n")
    self.__tcp_client:write("Sec-WebSocket-Version: 13\r\n")
    self.__tcp_client:write("\r\n")
  end)
end

function WebSocketClient:send(_) end

function WebSocketClient:close() end

return WebSocketClient
