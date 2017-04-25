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
env API_HOST=http://master-account-admin.3scale.net.dev:3000;
env MASTER_ACCESS_TOKEN=c695b1e6921706fd1cb32730b385157797267c44ef013769bb1d337fcdb2a2f3;
--- http_config
  lua_package_path "$TEST_NGINX_LUA_PATH";
  include $TEST_NGINX_SERVER_CONFIG;
--- config
--- request
GET /api/staging.json?host=api-2.production.apicast.io
--- error_code: 200
--- no_error_log
[error]
--- response_body

=== TEST 2: does not crash without host
--- main_config
env RESOLVER=127.0.0.1;
env API_HOST=http://master-account-admin.3scale.net.dev:3000;
env MASTER_ACCESS_TOKEN=c695b1e6921706fd1cb32730b385157797267c44ef013769bb1d337fcdb2a2f3;
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
env API_HOST=http://master-account-admin.3scale.net.dev:3000;
env MASTER_ACCESS_TOKEN=c695b1e6921706fd1cb32730b385157797267c44ef013769bb1d337fcdb2a2f3;
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
env API_HOST=http://master-account-admin.3scale.net.dev:3000;
env MASTER_ACCESS_TOKEN=c695b1e6921706fd1cb32730b385157797267c44ef013769bb1d337fcdb2a2f3;
--- http_config
  lua_package_path "$TEST_NGINX_LUA_PATH";
  include $TEST_NGINX_SERVER_CONFIG;
--- config
--- request
GET /api/admin/api/services.json
--- error_code: 404
--- no_error_log
[error]


