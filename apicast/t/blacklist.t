BEGIN {
    $ENV{TEST_NGINX_APICAST_BINARY} ||= 'rover exec apicast';
}

use strict;
use warnings FATAL => 'all';
use Test::APIcast::Blackbox 'no_plan';

repeat_each(1);
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
          { "name": "cloud_hosted.balancer_blacklist" },
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
--- ONLY
--- configuration
{
  "services": [
    {
      "proxy": {
        "policy_chain": [
          { "name": "cloud_hosted.balancer_blacklist" },
          { "name": "cloud_hosted.upstream",
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
failed to set current backend peer: blacklisted while connecting to upstream

