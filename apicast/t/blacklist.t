BEGIN {
    $ENV{TEST_NGINX_APICAST_BINARY} ||= 'apicast';
    $ENV{APICAST_POLICY_LOAD_PATH} = './policies';
    # By default new versions of Blackbox uses `gateway` for upstream repo
    # https://github.com/3scale/Test-APIcast/blob/master/lib/Test/APIcast.pm#L20
    $ENV{TEST_NGINX_APICAST_PATH}  = "/opt/app-root/src/";
}

use strict;
use warnings FATAL => 'all';
use Test::APIcast::Blackbox 'no_plan';

run_tests();

__DATA__

=== TEST 1: balancer blacklist
The module does not crash without configuration.
--- configuration
{
  "services": [
    {
      "proxy": {
        "policy_chain": [
          { "name": "cloud_hosted.balancer_blacklist", "version": "0.1" },
          { "name": "apicast.policy.echo", "configuration": { } }
        ]
      }
    }
  ]
}
--- request
GET /t
--- response_body
GET /t HTTP/1.1
--- error_code: 200
--- no_error_log
[error]



=== TEST 2: balancer upstream blacklist
Going to prevent connecting to local upstream.
--- configuration
{
  "services": [
    {
      "proxy": {
        "policy_chain": [
          { "name": "cloud_hosted.balancer_blacklist", "version": "0.1" },
          { "name": "cloud_hosted.upstream", "version": "0.1",
            "configuration": {
              "url": "http://test:$TEST_NGINX_SERVER_PORT", "host": "test"
            }
          }
        ]
      }
    }
  ]
}
--- upstream
location /t {
  content_by_lua_block { ngx.say('ok') }
}
--- request
GET /t
--- error_code: 503
--- error_log
could not select peer:

