local limit_req = require "resty.limit.req"

local _M = require('apicast.policy').new('Rate Limit', '0.1')

local new = _M.new

local function new_limiter(limit, burst)
  local limiter, err = limit_req.new("rate_limit_req_store", limit, burst or 0)

  if limiter then
    ngx.log(ngx.NOTICE, 'rate limit: ', limit, '/s', ' burst: ', burst or limit, '/s')
  elseif not arg then  -- arg is a table when executed from the CLI
    ngx.log(ngx.ERR, 'error loading rate limiter: ', err)
  end

  return limiter
end

local empty = {}

function _M.new(configuration)
  local policy = new(configuration)
  local config = configuration or empty

  local limit = config.limit
  local burst = config.burst

  policy.status = config.status

  if limit then
    policy.limiter = new_limiter(limit, burst)
    assert(policy.limiter, 'missing limiter')
  else
    ngx.log(ngx.NOTICE, 'rate limit not set')
  end

  return policy
end

function _M:content()
  ngx.log(ngx.STDERR, 'this is content phase')
end

function _M:access(context)
  local limiter = self.limiter

  if not limiter then return nil, 'missing limiter' end

  local key = context.host or ngx.var.host
  local status = self.status or 503

  local delay, err = limiter:incoming(key, true)

  if not delay then
    ngx.log(ngx.WARN, err, ' request over limit, key: ', key)
    if err == "rejected" then
      return ngx.exit(status)
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
