local apicast = require('apicast').new()
local blacklist = require('cloud_hosted.balancer_blacklist')
local rate_limit = require('cloud_hosted.rate_limit')
local resty_env = require('resty.env')

local _M = { _VERSION = '0.1', _NAME = 'APIcast Cloud Hosted' }
local mt = { __index = setmetatable(_M, { __index = apicast }) }

function _M.new()
  return setmetatable({
    blacklist = blacklist.new(),
    rate_limit = rate_limit.new(
      tonumber(resty_env.get('RATE_LIMIT') or 5),
      tonumber(resty_env.get('RATE_LIMIT_BURST') or 50)
    )
  }, mt)
end

function _M:init()
  self.blacklist:init()
  apicast:init()
end

function _M:rewrite()
  self.rate_limit:call()
  return apicast:rewrite()
end

function _M:balancer()
  return self.blacklist:balancer()
end

return _M
