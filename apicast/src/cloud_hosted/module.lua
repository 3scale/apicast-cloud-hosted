local policy_loader = require('apicast.policy_loader')

local apicast = policy_loader('apicast').new()
local blacklist = policy_loader('cloud_hosted.balancer_blacklist', '0.1')
local rate_limit = policy_loader('cloud_hosted.rate_limit', '0.1')
local resty_env = require('resty.env')

local _M = { _VERSION = '0.1', _NAME = 'APIcast Cloud Hosted' }
local mt = { __index = setmetatable(_M, { __index = apicast }) }

function _M.new()
  return setmetatable({
    blacklist = blacklist.new(),
    rate_limit = rate_limit.new(
      { limit = tonumber(resty_env.value('RATE_LIMIT') or 5),
        burst = tonumber(resty_env.value('RATE_LIMIT_BURST') or 50) }
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
