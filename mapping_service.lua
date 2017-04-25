local _M = {
}

local http_ng = require('resty.http_ng')
local cjson = require('cjson')
local getenv = os.getenv
local ngx_re = require('ngx.re')
local binding = require('resty.repl')

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
  local provider_id = _M.provider_id()

  if not provider_id then
    return ngx.exit(404)
  end

  local queries = { provider_id = provider_id, access_token = self.access_token }
  local response = self.http_client.post(self.api_host .. '/admin/api/sso_tokens/provider_create.json', queries)

  if response.status == 201 then
    return true, cjson.decode(response.body).sso_token
  else
    ngx.log(ngx.ERR, 'failed to create SSO token')
    return false
  end
end

function _M:load_configs()
  local sso_ok, sso_credentials = self:create_sso()
  local domain_ok, provider_domain = self:provider_domain()
  local arg_host = _M.arg_host()

  if not sso_ok or not domain_ok or not arg_host then
    return ngx.exit(404)
  end

  local query = ngx.encode_args({ host = arg_host, token = sso_credentials.token })
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
  local provider_id = _M.provider_id()

  if not provider_id then
    return ngx.exit(404)
  end

  local query = ngx.encode_args({ access_token = self.access_token })
  local url = self.api_host .. '/admin/api/accounts/' .. provider_id .. '.json?' .. query
  local response = self.http_client.get(url)

  if response.status == 200 then
    local admin_domain = cjson.decode(response.body).account.admin_domain
    return true, 'https://' .. admin_domain
  else
    ngx.log(ngx.ERR, 'failed to load Provider Domain')
    return false
  end
end

function _M.provider_id()
  local arg_host = _M.arg_host()
  if not arg_host then
    return false
  end

  local provider_id_part = ngx_re.split(arg_host, '[%.]')[1]
  if not provider_id_part then
    return false
  end

  return ngx_re.split(provider_id_part, '-')[2]
end

function _M.arg_host()
  local ngx_var = ngx.var or {}

  return ngx_var.arg_host
end

return _M
