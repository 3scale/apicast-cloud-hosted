local apicast = require('apicast').new()
local blacklist = require('cloud_hosted.balancer_blacklist')

local _M = { _VERSION = '0.1', _NAME = 'APIcast Cloud Hosted' }
local mt = { __index = setmetatable(_M, { __index = apicast }) }

function _M.new()
  return setmetatable({
    blacklist = blacklist.new()
  }, mt)
end

function _M:init()
  self.blacklist:init()
  apicast:init()
end

function _M:balancer()
  return self.blacklist:balancer()
end

return _M
