-- Clean warning on openresty 1.15.8.1, where some global variables are set
-- using ngx.timer that triggers an invalid warning message.
-- Code related: https://github.com/openresty/lua-nginx-module/blob/61e4d0aac8974b8fad1b5b93d0d3d694d257d328/src/ngx_http_lua_util.c#L795-L839
getmetatable(_G).__newindex = nil

if ngx ~= nil then
  ngx.exit = function()end
end

-- Busted command-line runner
require 'busted.runner'({ standalone = false })
