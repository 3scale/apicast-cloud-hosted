local http_ng = require('resty.http_ng')
local cache_store = require('resty.http_ng.cache_store')
local resty_backend = require('resty.http_ng.backend.resty')
local cache_backend = require('resty.http_ng.backend.cache')
local cjson = require('cjson')
local ngx_re = require('ngx.re')
local resty_env = require('resty.env')
local resty_url = require('resty.url')
local lrucache = require('resty.lrucache')

local getenv = os.getenv
local setmetatable = setmetatable
local format = string.format
local gsub = string.gsub
local unpack = unpack

--local binding = require('resty.repl')

local _M = {
  http_cache = cache_store.new(),
  sso_cache = lrucache.new(100),
  domain_cache = lrucache.new(100),
}

local mt = {
  __index = _M
}


function _M.new(options)
  local opts = options or {}
  local backend = cache_backend.new(opts.client or resty_backend, { cache_store = _M.http_cache })

  local http_client = http_ng.new({
    backend = backend,
    options = { ssl = { verify = resty_env.enabled('OPENSSL_VERIFY') or false } }
  })
  local api_host = opts.api_host or getenv('API_HOST') or 'https://multitenant-admin.3scale.net'
  local preview_base_domain = opts.preview_base_domain or getenv('PREVIEW_BASE_DOMAIN')
  -- local preview_base_domain = "preview01.3scale.net"
  local access_token = opts.access_token or getenv('MASTER_ACCESS_TOKEN')
  local environment = _M.normalize_environment(opts.environment)


  if not environment then
    ngx.log(ngx.WARN, 'missing environment')
    return ngx.exit(404)
  end

  return setmetatable({
    options = opts,
    http_client = http_client,
    api_host = api_host,
    access_token = access_token,
    environment = environment,
    preview_base_domain = preview_base_domain
  }, mt)
end

function _M:check()
  return self.http_client.get(self.api_host .. '/check.txt')
end

function _M:create_sso(provider_id)
  if not provider_id then
    ngx.log(ngx.WARN, 'missing provider_id')
    return ngx.exit(404)
  end

  local queries = { provider_id = provider_id, access_token = self.access_token, expires_in = 60 }
  local response = self.http_client.post(self.api_host .. '/admin/api/sso_tokens/provider_create.json', queries)

  if response.status == 201 then
    local sso = cjson.decode(response.body).sso_token
    local expires = response.headers.expires

    return true, sso.token, expires and ngx.parse_http_time(expires)
  else
    ngx.log(ngx.ERR, 'failed to create SSO token: ', response.error or response.status)
    return false
  end
end

local function get_sso_token(service)
  local provider_id = _M.provider_id()
  local cache = _M.sso_cache

  local credentials = cache:get(provider_id)

  if not credentials then
    local _, expires_at

    _, credentials, expires_at = service:create_sso(provider_id)

    if credentials then
      local ttl = (expires_at or ngx.time()) - ngx.time() - 30
      cache:set(provider_id, credentials, ttl)
    end
  end

  return credentials
end

local function get_provider_domain(service)
  local provider_id = _M.provider_id()
  local cache = _M.domain_cache

  local provider_domain = cache:get(provider_id)

  if not provider_domain then
    local _

    _, provider_domain = service:provider_domain(provider_id)

    if provider_domain then
      cache:set(provider_id, provider_domain)
    end
  end

  return provider_domain
end

function _M:load_configs()
  local sso_token = get_sso_token(self)
  local provider_domain = get_provider_domain(self)
  local arg_host = _M.arg_host()

  if not sso_token or not provider_domain or not arg_host then
    ngx.log(ngx.WARN, 'missing sso, domain or host')
    return ngx.exit(404)
  end

  local query = ngx.encode_args({ host = arg_host, token = sso_token })
  local url = provider_domain .. '/admin/api/services/proxy/configs/' .. self.environment .. '.json?' .. query
  local response = self.http_client.get(url)

  if response.status == 200 then
    return response.body
  else
    ngx.log(ngx.ERR, 'failed to load Proxy Configs')
    return false
  end
end

function _M:provider_domain(provider_id)
  if not provider_id then
    ngx.log(ngx.WARN, 'missing provider_id')
    return ngx.exit(404)
  end

  local query = ngx.encode_args({ access_token = self.access_token })
  local response = self.http_client.get(self.api_host .. '/admin/api/accounts/' .. provider_id .. '.json?' .. query)

  if response.status == 200 then
    local admin_domain = cjson.decode(response.body).account.admin_domain

    --[[
    This block of code is used to make apicast work in the preview environment.
    It takes the admin_domain as returned by system (which is the production one)
    and modifies it so the admin_domain points to the preview environment. Subsequent
    requests to system api are done with the modified admin_domain and thus correctly
    pointed to preview
    --]]
    if self.preview_base_domain then
      local preview_admin_domain = format('%s.%s', ngx_re.split(admin_domain, '[%.]')[1], self.preview_base_domain)
      ngx.log(ngx.NOTICE, 'PREVIEW: changed admin_domain "', admin_domain, '" by "', preview_admin_domain, '"')
      admin_domain = preview_admin_domain
    end

    local url = resty_url.split(self.api_host)
    local scheme, _, _, _, port = unpack(url)


    return true, format('%s://%s:%s', scheme, admin_domain, port or resty_url.default_port(scheme))
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
