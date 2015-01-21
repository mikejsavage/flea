local _M = { }

function _M.seconds( s )
	return s
end

function _M.miutes( m )
	return m * 60
end

function _M.hours( h )
	return h * 60 * 60
end

function _M.days( d )
	return d * 24 * 60 * 60
end

return _M
