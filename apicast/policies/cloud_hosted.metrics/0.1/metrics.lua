local _M = require('apicast.policy').new('Metrics', '0.1')

local errlog = require('ngx.errlog')
local prometheus = require('apicast.prometheus')
local tonumber = tonumber
local select = select
local find = string.find
local pairs = pairs

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

local logs_metric = prometheus('counter', 'nginx_error_log', "Items in nginx error log", {'level'})
local http_connections_metric =  prometheus('gauge', 'nginx_http_connections', 'Number of HTTP connections', {'state'})
local shdict_capacity_metric = prometheus('gauge', 'openresty_shdict_capacity', 'OpenResty shared dictionary capacity', {'dict'})
local shdict_free_space_metric = prometheus('gauge', 'openresty_shdict_free_space', 'OpenResty shared dictionary free space', {'dict'})


local metric_labels = {}

local function metric_op(op, metric, value, label)
  if not metric then return end
  metric_labels[1] = label
  metric[op](metric, tonumber(value) or 0, metric_labels)
end

local function metric_set(metric, value, label)
  return metric_op('set', metric, value, label)
end

local function metric_inc(metric, label)
  return metric_op('inc', metric, 1, label)
end

function _M:init()
  local ok, err = errlog.set_filter_level(self.filter_level)

  get_logs(100) -- to throw them away after setting the filter level (and get rid of debug ones)

  if not ok then
    ngx.log(ngx.WARN, self._NAME, ' failed to set errlog filter level: ', err)
  end

  for name,dict in pairs(ngx.shared) do
    metric_set(shdict_capacity_metric, dict:capacity(), name)
  end
end

function _M:metrics()
  local logs = get_logs(self.max_logs)

  for i = 1, #logs, 3 do
    metric_inc(logs_metric, log_map[logs[i]] or 'unknown')
  end

  local response = ngx.location.capture("/nginx_status")

  if response.status == 200 then
    local accepted, handled, total = select(3, find(response.body, [[accepts handled requests%s+(%d+) (%d+) (%d+)]]))
    local var = ngx.var

    metric_set(http_connections_metric, var.connections_reading, 'reading')
    metric_set(http_connections_metric, var.connections_waiting, 'waiting')
    metric_set(http_connections_metric, var.connections_writing, 'writing')
    metric_set(http_connections_metric, var.connections_active, 'active')
    metric_set(http_connections_metric, accepted, 'accepted')
    metric_set(http_connections_metric, handled, 'handled')
    metric_set(http_connections_metric, total, 'total')
  else
    prometheus:log_error('Could not get status from nginx')
  end

  for name,dict in pairs(ngx.shared) do
    metric_set(shdict_free_space_metric, dict:free_space(), name)
  end
end

return _M
