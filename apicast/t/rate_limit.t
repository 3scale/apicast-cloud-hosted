BEGIN {
    $ENV{TEST_NGINX_APICAST_BINARY} ||= 'rover exec apicast';
    $ENV{APICAST_POLICY_LOAD_PATH} = './policies';
}

use strict;
use warnings FATAL => 'all';
use Test::APIcast::Blackbox 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: rate limit without limit
The module does not crash without configuration.
--- configuration
{
  "services": [
    {
      "proxy": {
        "policy_chain": [
          { "name": "cloud_hosted.rate_limit", "version": "0.1" },
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



=== TEST 2: rate limit with limit
The module does rate limiting.
--- configuration
{
  "services": [
    {
      "proxy": {
        "policy_chain": [
          { "name": "cloud_hosted.rate_limit", "version": "0.1", "configuration": { "limit": 1 } },
          { "name": "apicast.policy.echo", "configuration": { } }
        ]
      }
    }
  ]
}
--- request eval
["GET /t", "GET /t"]
--- error_code eval
[200, 429]
--- grep_error_log
rejected request over limit, key: localhost
--- grep_error_log_out eval
["", "rejected request over limit, key: localhost"]



=== TEST 3: rate limit with limit and burst
Delays the request.
--- configuration
{
  "services": [
    {
      "proxy": {
        "policy_chain": [
          { "name": "cloud_hosted.rate_limit", "version": "0.1", "configuration": { "limit": 1, "burst": 1 } },
          { "name": "apicast.policy.echo", "configuration": { } }
        ]
      }
    }
  ]
}
--- request eval
["GET /t", "GET /t"]
--- response_body eval
["GET /t HTTP/1.1\n", "GET /t HTTP/1.1\n" ]
--- error_code eval
[200, 200]
--- grep_error_log
delaying request: localhost for 1s, excess: 1
--- grep_error_log_out eval
["", "delaying request: localhost for 1s, excess: 1"]



=== TEST 4: rate limit with custom status
Sends the custom status code.
--- configuration
{
  "services": [
    {
      "proxy": {
        "policy_chain": [
          { "name": "cloud_hosted.rate_limit", "version": "0.1", "configuration": { "limit": 1, "status": 503 } },
          { "name": "apicast.policy.echo", "configuration": { } }
        ]
      }
    }
  ]
}
--- request eval
["GET /t", "GET /t"]
--- error_code eval
[200, 503]



=== TEST 5: rate limit with APIcast policy
Prints no errors when rate limited.
--- environment_file: config/cloud_hosted.lua
--- env eval
('APICAST_RATE_LIMIT' => 1, 'APICAST_RATE_LIMIT_BURST' => 0)
--- configuration
{
  "services": [
    {
      "backend_version": 1,
      "proxy": {
        "policy_chain": [
          { "name": "apicast.policy.echo", "configuration": { } },
          { "name": "apicast.policy.apicast" }
        ],
        "api_backend": "http://test:$TEST_NGINX_SERVER_PORT/",
        "proxy_rules": [
          { "pattern": "/", "http_method": "GET", "metric_system_name": "hits", "delta": 2 }
        ]
      }
    }
  ]
}
--- backend
  location /transactions/authrep.xml {
    content_by_lua_block {
      ngx.exit(200)
    }
  }
--- request eval
["GET /t?user_key=foo", "GET /t?user_key=foo"]
--- error_code eval
[200, 429]
--- no_error_log
[error]
