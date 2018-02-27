local _M = require('apicast.policy').new('Metrics', '0.1')

local errlog = require('ngx.errlog')
local prometheus = require('apicast.prometheus')

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

  return m
end

function _M:init()
  local ok, err = errlog.set_filter_level(self.filter_level)

  if not ok then
    ngx.log(ngx.WARN, self._NAME, ' failed to set errlog filter level: ', err)
  end
end

local logs_metric = prometheus('counter', 'nginx_error_log', "Items in nginx error log", {'level'})

function _M.metrics()
  local logs = errlog.get_logs()

  if not logs then return nil, 'could not get logs' end

  local labels = {}

  for i = 1, #logs, 3 do
    labels[1] = log_map[logs[i]] or 'unknown'
    logs_metric:inc(1, labels)
  end
end

return _M
