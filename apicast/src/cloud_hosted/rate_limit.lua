local setmetatable = setmetatable

local limit_req = require "resty.limit.req"

local _M = { _VERSION = '0.0', _NAME = 'Rate Limit' }
local mt = { __index = _M }

function _M.new(limit, burst)
  local limiter, err = limit_req.new("rate_limit_req_store", limit, burst)

  if limiter then
    ngx.log(ngx.NOTICE, 'rate limit: ', limit, '/s', ' burst: ', burst, '/s')
  elseif not arg then  -- arg is a table when executed from the CLI
    ngx.log(ngx.ERR, 'error loading rate limiter: ', err)
  end

  return setmetatable({
    limiter = limiter
  }, mt)
end

function _M:call(host)
  local limiter = self.limiter

  if not limiter then return nil, 'missing limiter' end

  local key = host or ngx.var.host

  local delay, err = limiter:incoming(key, true)

  if not delay then
    if err == "rejected" then
      return ngx.exit(503)
    end
    ngx.log(ngx.ERR, "failed to limit req: ", err)
    return ngx.exit(500)
  end

  if delay >= 0.001 then
    local excess = err

    ngx.log(ngx.WARN, 'delaying request: ', key, ' for ', delay, 's, excess: ', excess)
    ngx.sleep(delay)
  end
end


return _M
