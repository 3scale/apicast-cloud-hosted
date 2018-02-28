local _M = require('apicast.policy').new('Metrics', '0.1')

local errlog = require('ngx.errlog')
local prometheus = require('apicast.prometheus')
local tonumber = tonumber
local select = select
local find = string.find

local new = _M.new

local log_map = {
 'emerg',
 'alert',
 'crit',
 'error',
 'warn',
 'notice',
 'info',
 'debug',
}


local function find_i(t, value)
  for i=1, #t do
    if t[i] == value then return i end
  end
end

local empty = {}

local function get_logs(max)
  return errlog.get_logs(max) or empty
end

function _M.new(configuration)
  local m = new()

  local config = configuration or empty
  local filter_level = config.log_level or 'error'

  local i = find_i(log_map, filter_level)

  if not i then
    ngx.log(ngx.WARN, _M._NAME, ': invalid level: ', filter_level, ' using error instead')
    i = find_i(log_map, 'error')
  end

  m.filter_level = i
  -- how many logs to take in one iteration
  m.max_logs = tonumber(config.max_logs) or 100

  return m
end

function _M:init()
  local ok, err = errlog.set_filter_level(self.filter_level)

  get_logs(100) -- to throw them away after setting the filter level (and get rid of debug ones)

  if not ok then
    ngx.log(ngx.WARN, self._NAME, ' failed to set errlog filter level: ', err)
  end
end

local logs_metric = prometheus('counter', 'nginx_error_log', "Items in nginx error log", {'level'})
local http_connections_metric =  prometheus('gauge', 'nginx_http_connections', 'Number of HTTP connections', {'state'})

function _M:metrics()
  local logs = get_logs(self.max_logs)
  local labels = {}

  for i = 1, #logs, 3 do
    labels[1] = log_map[logs[i]] or 'unknown'
    logs_metric:inc(1, labels)
  end

  local response = ngx.location.capture("/nginx_status")

  if response.status == 200 then
    local accepted, handled, total = select(3, find(response.body, [[accepts handled requests%s+(%d+) (%d+) (%d+)]]))
    local var = ngx.var

    http_connections_metric:set(tonumber(var.connections_reading) or 0, {"reading"})
    http_connections_metric:set(tonumber(var.connections_waiting) or 0, {"waiting"})
    http_connections_metric:set(tonumber(var.connections_writing) or 0, {"writing"})
    http_connections_metric:set(tonumber(var.connections_active) or 0, {"active"})
    http_connections_metric:set(accepted or 0, {"accepted"})
    http_connections_metric:set(handled or 0, {"handled"})
    http_connections_metric:set(total or 0, {"total"})
  else
    prometheus:log_error('Could not get status from nginx')
  end
end

return _M
