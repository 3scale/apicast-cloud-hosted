local _M = {
}

local http_ng = require('resty.http_ng')

function _M.check()
	local http = http_ng.new()

	return http.get('https://multitenant-admin.3scale.net/check.txt')
end

return _M
