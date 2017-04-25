local _M = {
}

local http_ng = require('resty.http_ng')
local cjson = require('cjson')
local getenv = os.getenv
local ngx_re = require('ngx.re')
local resty_env = require('resty.env')
local resty_url = require('resty.url')
--local binding = require('resty.repl')

local mt = {
  __index = _M
}

function _M.new(options)
  local opts = options or {}

  local http_client = http_ng.new({
    backend = opts.client,
    options = { ssl = { verify = resty_env.enabled('OPENSSL_VERIFY') or false } }
  })
  local api_host = opts.api_host or getenv('API_HOST') or 'https://multitenant-admin.3scale.net'
  local access_token = opts.access_token or getenv('MASTER_ACCESS_TOKEN')
  local environment = _M.normalize_environment(opts.environment)

  if not environment then
    return ngx.exit(404)
  end

  return setmetatable({
    options = opts,
    http_client = http_client,
    api_host = api_host,
    access_token = access_token,
    environment = environment
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
    ngx.log(ngx.ERR, 'failed to create SSO token: ', response.error or response.status)
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
  local url = provider_domain .. '/admin/api/services/proxy/configs/' .. self.environment .. '.json?' .. query
  local response = self.http_client.get(url)

  if response.status == 200 then
    return response.body
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
  local response = self.http_client.get(self.api_host .. '/admin/api/accounts/' .. provider_id .. '.json?' .. query)

  if response.status == 200 then
    local admin_domain = cjson.decode(response.body).account.admin_domain
    local url = resty_url.split(self.api_host)
    local scheme, _, _, _, port = unpack(url)

    return true, string.format('%s://%s:%s', scheme, admin_domain, port or resty_url.default_port(scheme))
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

  local parts = ngx_re.split(provider_id_part, '-')
  return parts[#parts]
end

function _M.arg_host()
  local ngx_var = ngx.var or {}

  return ngx_var.arg_host
end

function _M.normalize_environment(env)
  local env_mapping = {
    staging = 'sandbox'
  }

  return env_mapping[env] or env
end

return _M
