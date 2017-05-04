use Test::Nginx::Socket::Lua 'no_plan';
use Cwd qw(cwd);

my $pwd = cwd();
my $apicast = $ENV{TEST_NGINX_APICAST_PATH} || "$pwd";

$ENV{TEST_NGINX_LUA_PATH} = "$pwd/src/?.lua;$pwd/?.lua;;";
$ENV{TEST_NGINX_SERVER_CONFIG} = "$apicast/server.conf";

log_level('debug');
repeat_each(2);
no_root_location();
run_tests();

env_to_nginx(
    'API_HOST',
    'MASTER_ACCESS_TOKEN',
    'RESOLVER'
);

__DATA__

=== TEST 1: load configs
--- main_config
env RESOLVER=127.0.0.1;
env API_HOST=http://localhost:8081;
env MASTER_ACCESS_TOKEN=some-token;
--- http_config
  lua_package_path "$TEST_NGINX_LUA_PATH";
  include $TEST_NGINX_SERVER_CONFIG;
  server {
    listen 8081 default_server;
    location /admin/api/sso_tokens/provider_create.json {
        content_by_lua_block {
            ngx.status = 201
            ngx.say(require('cjson').encode({sso_token = { token = "some-sso-token" }}))
        }
    }
    location /admin/api/accounts/2.json {
        content_by_lua_block {
            if ngx.var.arg_access_token == 'some-token' then
                ngx.say(require('cjson').encode({ account = { admin_domain = '127.0.0.1' } }))
            else
              ngx.exit(403)
            end
        }
    }
  }

  server {
    listen 8081;
    server_name 127.0.0.1;

    location /admin/api/services/proxy/configs/sandbox.json {
        content_by_lua_block {
            if ngx.var.arg_host == 'api-test-2.production.apicast.io' then
                ngx.say(require('cjson').encode({ proxy_configs = { } }))
            else
                ngx.exit(404)
            end
        }
    }
  }
--- config
--- request
GET /api/staging.json?host=api-test-2.production.apicast.io
--- error_code: 200
--- no_error_log
[error]
--- response_body
{"proxy_configs":{}}

=== TEST 2: does not crash without host
--- main_config
env RESOLVER=127.0.0.1;
env API_HOST=http://127.0.0.1:$TEST_NGINX_CLIENT_PORT;
env MASTER_ACCESS_TOKEN=some-token;
--- http_config
  lua_package_path "$TEST_NGINX_LUA_PATH";
  include $TEST_NGINX_SERVER_CONFIG;
--- config
--- request
GET /api/staging.json
--- error_code: 404
--- no_error_log
[error]

=== TEST 3: does not crash without env
--- main_config
env RESOLVER=127.0.0.1;
env API_HOST=http://127.0.0.1:$TEST_NGINX_CLIENT_PORT;
env MASTER_ACCESS_TOKEN=some-token;
--- http_config
  lua_package_path "$TEST_NGINX_LUA_PATH";
  include $TEST_NGINX_SERVER_CONFIG;
--- config
--- request
GET /api/
--- error_code: 404
--- no_error_log
[error]

=== TEST 4: does not crash on services endpoint
--- main_config
env RESOLVER=127.0.0.1;
env API_HOST=http://127.0.0.1:$TEST_NGINX_CLIENT_PORT;
env MASTER_ACCESS_TOKEN=some-token;
--- http_config
  lua_package_path "$TEST_NGINX_LUA_PATH";
  include $TEST_NGINX_SERVER_CONFIG;
--- config
--- request
GET /api/admin/api/services.json
--- error_code: 404
--- no_error_log
[error]


