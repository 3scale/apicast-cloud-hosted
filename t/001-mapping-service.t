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

=== TEST 1: authentication credentials missing
The message is configurable as well as the status.
--- http_config
  lua_package_path "$TEST_NGINX_LUA_PATH";
  include $TEST_NGINX_SERVER_CONFIG;
--- config
--- request
GET /api/test
--- error_code: 200
--- response_body
hello
