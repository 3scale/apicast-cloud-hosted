local tonumber = tonumber

local limit_req = require "resty.limit.req"
local prometheus = require('apicast.prometheus')

local _M = require('apicast.policy').new('Rate Limit', '0.1')

local new = _M.new

local function new_limiter(limit, burst)
  local limiter, err = limit_req.new("rate_limit_req_store", tonumber(limit), tonumber(burst) or 0)

  if limiter then
    ngx.log(ngx.NOTICE, 'rate limit: ', limit, '/s', ' burst: ', burst or limit, '/s')
  elseif not arg then -- if not being loaded on the CLI
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
  else
    ngx.log(ngx.NOTICE, 'rate limit not set')
  end

  return policy
end

local rate_limits_metric = prometheus('counter', 'cloud_hosted_rate_limit', "Cloud hosted rate limits", {'state'})

local delayed = { 'delayed ' }
local rejected = { 'rejected' }

function _M:access(context)
  local limiter = self.limiter

  if not limiter then return nil, 'missing limiter' end

  local key = context.host or ngx.var.host
  local status = self.status or 429

  local delay, err = limiter:incoming(key, true)

  if not delay then
    ngx.log(ngx.WARN, err, ' request over limit, key: ', key)
    if err == "rejected" then
      rate_limits_metric:inc(1, rejected)
      return ngx.exit(status)
    end
    ngx.log(ngx.ERR, "failed to limit req: ", err)
    return ngx.exit(500)
  end

  if delay >= 0.001 then
    local excess = err

    ngx.log(ngx.WARN, 'delaying request: ', key, ' for ', delay, 's, excess: ', excess)
    rate_limits_metric:inc(1, delayed)
    ngx.sleep(delay)
  end
end


return _M
