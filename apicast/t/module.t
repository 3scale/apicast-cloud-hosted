BEGIN {
    $ENV{TEST_NGINX_APICAST_BINARY} ||= 'APICAST_MODULE="" rover exec ./lua_modules/bin/apicast';
    $ENV{APICAST_MODULE} = 'cloud_hosted.module';
    $ENV{APICAST_POLICY_LOAD_PATH} = './policies';
    $ENV{LUA_PATH} = './src/?.lua;;';
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
`
