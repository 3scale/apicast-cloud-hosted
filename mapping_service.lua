local _M = {
}

local http_ng = require('resty.http_ng')
local cjson = require('cjson')
local getenv = os.getenv

local mt = {
  __index = _M
}

function _M.new(options)
  local opts = options or {}

  local http_client = http_ng.new({ backend = opts.client })
  local api_host = opts.api_host or getenv('API_HOST') or 'https://multitenant-admin.3scale.net'
  local access_token = opts.access_token or getenv('MASTER_ACCESS_TOKEN')

  return setmetatable({
    options = opts,
    http_client = http_client,
    api_host = api_host,
    access_token = access_token
  }, mt)
end

function _M:check()
  return self.http_client.get(self.api_host .. '/check.txt')
end

function _M:create_sso()
  local queries = { provider_id = _M.provider_id(), access_token = self.access_token }
  local response = self.http_client.post(self.api_host .. '/admin/api/sso_tokens/provider_create.json', queries)

  if response.status == 200 then
    return true, cjson.decode(response.body).sso_token
  else
    ngx.log(ngx.ERR, 'failed to create SSO token')
    return false
  end
end

function _M:load_configs()
  local sso_ok, sso_credentials = self:create_sso()
  local domain_ok, provider_domain = self:provider_domain()

  if not sso_ok or not domain_ok then
    return false
  end

  local query = ngx.encode_args({ host = _M.service_host(), token = sso_credentials.token })
  local url = provider_domain .. '/admin/api/services/proxy/configs/production.json?' .. query
  local response = self.http_client.get(url)

  if response.status == 200 then
    return true, cjson.decode(response.body)
  else
    ngx.log(ngx.ERR, 'failed to load Proxy Configs')
    return false
  end
end

function _M:provider_domain()
  local query = ngx.encode_args({ access_token = self.access_token })
  local url = self.api_host .. '/admin/api/accounts/' .. _M.provider_id() .. '.json?' .. query
  local response = self.http_client.get(url)

  if response.status == 200 then
    local admin_domain = cjson.decode(response.body).account.admin_domain
    return true, 'https://' .. admin_domain
  else
    ngx.log(ngx.ERR, 'failed to load Provider Domain')
    return false
  end
end

function _M.arg_host_args()
  local _, args = ngx.var.arg_host:match("(.+)?(.+)")
  return ngx.decode_args(args)
end

function _M.provider_id()
  local _, provider_id = _M.service_host():match("(api)-(%d)")
  return provider_id
end

function _M.service_host()
  local arg_host_args = _M.arg_host_args()
  return arg_host_args.host
end

return _M
