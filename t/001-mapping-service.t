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

__DATA__

=== TEST 1: load configs
--- http_config
  lua_package_path "$TEST_NGINX_LUA_PATH";
  include $TEST_NGINX_SERVER_CONFIG;
--- config
--- request
GET /api/staging.json?host=api-2.prod.apicast.io
--- error_code: 200
--- no_error_log
[error]
--- response_body

=== TEST 2: does not crash without host
--- http_config
  lua_package_path "$TEST_NGINX_LUA_PATH";
  include $TEST_NGINX_SERVER_CONFIG;
--- config
--- request
GET /api/staging.json
--- error_code: 404
--- no_error_log
[error]
--- response_body

=== TEST 3: does not crash without env
--- http_config
  lua_package_path "$TEST_NGINX_LUA_PATH";
  include $TEST_NGINX_SERVER_CONFIG;
--- config
--- request
GET /api/
--- error_code: 404
--- no_error_log
[error]
--- response_body

=== TEST 4: does not crash on services endpoint
--- http_config
  lua_package_path "$TEST_NGINX_LUA_PATH";
  include $TEST_NGINX_SERVER_CONFIG;
--- config
--- request
GET /api/admin/api/services.json
--- error_code: 404
--- no_error_log
[error]
--- response_body
