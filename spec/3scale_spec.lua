
local _M = require('3scale')

describe('3scale client spec', function()
	it('returns check', function()
		assert(_M.check())
	end)
end)
