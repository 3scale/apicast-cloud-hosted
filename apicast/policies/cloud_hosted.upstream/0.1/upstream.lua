local resty_resolver = require('resty.resolver')
local resty_url = require('resty.url')
local format = string.format

local _M = require('apicast.policy').new('Upstream', '0.1')

local new = _M.new

local empty = {}
function _M.new(configuration)
  local policy = new(configuration)
  local config = configuration or empty

  local url = resty_url.parse(config.url) or empty
  local host = config.host or url.host

  policy.host = host
  policy.url = url

  return policy
end

function _M:content()
  local url = self.url
  local host = self.host

  ngx.ctx.upstream = resty_resolver:instance():get_servers(url.host, { port = url.port })
  ngx.var.proxy_pass = format('%s://upstream%s', url.scheme, url.path or '')
  ngx.req.set_header('Host', host or ngx.var.host)

  if not ngx.headers_sent then
    ngx.exec("@upstream")
  end
end


return _M
