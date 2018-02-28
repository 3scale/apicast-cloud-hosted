BEGIN {
    $ENV{TEST_NGINX_APICAST_BINARY} ||= 'rover exec apicast';
    $ENV{APICAST_POLICY_LOAD_PATH} = './policies';
    $ENV{APICAST_BALANCER_WHITELIST} = '127.0.0.1/32';
    $ENV{METRICS_LOG_LEVEL} = 'info';
}

use strict;
use warnings FATAL => 'all';
use Test::APIcast::Blackbox 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: metrics endpoint
--- environment_file: config/cloud_hosted.lua
--- configuration
{
  "services": [
    {
      "proxy": {
        "policy_chain": [
          { "name": "cloud_hosted.upstream", "version": "0.1",
            "configuration": {
              "url": "http://127.0.0.1:$TEST_NGINX_SERVER_PORT", "host": "prometheus"
            }
          }
        ]
      }
    }
  ]
}
--- request
GET /metrics
--- response_body
# HELP cloud_hosted_balancer Cloud hosted balancer
# TYPE cloud_hosted_balancer counter
cloud_hosted_balancer{status="success"} 1
# HELP nginx_error_log Items in nginx error log
# TYPE nginx_error_log counter
nginx_error_log{level="info"} 1
# HELP nginx_http_connections Number of HTTP connections
# TYPE nginx_http_connections gauge
nginx_http_connections{state="accepted"} 2
nginx_http_connections{state="active"} 2
nginx_http_connections{state="handled"} 2
nginx_http_connections{state="reading"} 0
nginx_http_connections{state="total"} 2
nginx_http_connections{state="waiting"} 0
nginx_http_connections{state="writing"} 2
# HELP nginx_metric_errors_total Number of nginx-lua-prometheus errors
# TYPE nginx_metric_errors_total counter
nginx_metric_errors_total 0
# HELP openresty_shdict_capacity OpenResty shared dictionary capacity
# TYPE openresty_shdict_capacity gauge
openresty_shdict_capacity{dict="api_keys"} 10485760
openresty_shdict_capacity{dict="configuration"} 10485760
openresty_shdict_capacity{dict="init"} 16384
openresty_shdict_capacity{dict="locks"} 1048576
openresty_shdict_capacity{dict="prometheus_metrics"} 16777216
openresty_shdict_capacity{dict="rate_limit_req_store"} 10485760
# HELP openresty_shdict_free_space OpenResty shared dictionary free space
# TYPE openresty_shdict_free_space gauge
openresty_shdict_free_space{dict="api_keys"} 10412032
openresty_shdict_free_space{dict="configuration"} 10412032
openresty_shdict_free_space{dict="init"} 4096
openresty_shdict_free_space{dict="locks"} 1032192
openresty_shdict_free_space{dict="prometheus_metrics"} 16662528
openresty_shdict_free_space{dict="rate_limit_req_store"} 10412032
--- error_code: 200
--- no_error_log
[error]
