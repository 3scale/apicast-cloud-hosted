local Upstream = require('apicast.upstream')

local _M = require('apicast.policy').new('Upstream', '0.1')

local new = _M.new

local empty = {}
function _M.new(configuration)
  local policy = new(configuration)
  local config = configuration or empty

  policy.upstream = Upstream.new(config.url)

  return policy
end

function _M:content(context)
  self.upstream:call(context)
end

return _M
