local _M = require('mapping_service')
local cjson = require 'cjson'
local test_backend_client = require 'resty.http_ng.backend.test'

describe('3scale client spec', function()

  local test_backend
  local service

  before_each(function()
    ngx.var = { arg_host = 'api-2.production.apicast.io' }

    test_backend = test_backend_client.new()
    service = _M.new({
      client = test_backend,
      api_host = 'https://example.com',
      access_token = 'abc'
    })
  end)

  it('provider_id', function ()
    assert.are.equal('2', service.provider_id())
  end)

  it(':provider_domain', function ()
    test_backend.expect{ url = 'https://example.com/admin/api/accounts/2.json?access_token=abc' }.
      respond_with{ status = 200, body = cjson.encode({
        account = { admin_domain = 'alaska.com' }
      })}
    local ok, domain = service:provider_domain()
    assert.True(ok)
    assert.are.equal('https://alaska.com', domain)

    test_backend.expect{ url = 'https://example.com/admin/api/accounts/2.json?access_token=abc' }.
      respond_with{ status = 403 }
    local ok_2, domain_2 = service:provider_domain()
    assert.False(ok_2)
    assert.Nil(domain_2)
  end)

  it(':check', function()
    test_backend.expect{ url = 'https://example.com/check.txt' }.
      respond_with{ status = 200 }
    local response = assert(service:check())
    assert(response.ok, response.error)
  end)

  it(':create_sso', function()
    test_backend.expect{ url = 'https://example.com/admin/api/sso_tokens/provider_create.json' }.
      respond_with{ status = 201, body = cjson.encode({
        sso_token = { token = 'alaska' }
      })}
    local ok, sso_token = service:create_sso()
    assert.True(ok)
    assert.are.equal('alaska', sso_token.token)

    test_backend.expect{ url = 'https://example.com/admin/api/sso_tokens/provider_create.json' }.
      respond_with{ status = 403 }
    local ok_2, sso_token_2 = service:create_sso()
    assert.False(ok_2)
    assert.Nil(sso_token_2)
  end)
--
  it('load_configs', function()
    stub(service, 'create_sso', function ()
      return true, { token = 'abc' }
    end)
    stub(_M, 'provider_domain', function ()
      return true, 'http://provider.com'
    end)
    test_backend.expect{ url = 'http://provider.com/admin/api/services/proxy/configs/' ..
        'production.json?host=api-2.production.apicast.io&token=abc' }.
      respond_with{ status = 200, body = cjson.encode({
        proxy_configs = {{ version = '1', content = 'west_is_the_best' }}
      })}
    local ok, configs = service:load_configs()
    assert.True(ok)
    assert.truthy(configs)
    assert.equal('table', type(configs))
    assert.equals(1, #configs.proxy_configs)
    assert.equals('1', configs.proxy_configs[1].version)
    assert.equals('west_is_the_best', configs.proxy_configs[1].content)

    test_backend.expect{ url = 'http://provider.com/admin/api/services/proxy/configs/' ..
        'production.json?host=api-2.production.apicast.io&token=abc' }.
      respond_with{ status = 403 }
    local ok_2, configs_2 = service:load_configs()
    assert.False(ok_2)
    assert.Nil(configs_2)
  end)
end)
