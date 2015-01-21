local arc4 = require( "arc4random" )

local _M = { }

-- http://www.w3.org/html/wg/drafts/html/master/syntax.html#void-elements
-- local voids = { "area", "base", "br", "col", "embed", "hr", "img", "input", "keygen", "link", "menuitem", "meta", "param", "source", "track", "wbr", }
--
-- for _, void in ipairs( voids ) do
-- 	voids[ void ] = true
-- end

local bless_key

local function flatten_contents( contents, flat )
	if type( contents ) == "string" then
		table.insert( flat, contents:html_escape() )
	elseif type( contents ) == "function" then
		local chunks = { }

		contents( function( chunk )
			table.insert( chunks, chunk )
		end )

		flatten_contents( chunks, flat )
	elseif contents.blessing then
		assert( contents.blessing == bless_key, "unblessed html fragment" )
		table.insert( flat, contents[ 1 ] )
	else
		for i = 1, #contents do
			flatten_contents( contents[ i ], flat )
		end
	end
end

local mt = {
	__index = function( _, key )
		key = key:lower()

		return function( attr_or_contents, contents )
			local attr = { }
			if not attr_or_contents or type( attr_or_contents ) == "string" or attr_or_contents[ 1 ] then
				contents = attr_or_contents
			else
				attr = attr_or_contents
			end

			local result = "<" .. key

			for k, v in pairs( attr ) do
				result = result .. " " .. k .. "=\"" .. tostring( v ):url_escape() .. "\""
			end

			result = result .. ">"

			if contents then
				local flat = { }
				flatten_contents( contents, flat )

				return { result .. table.concat( flat ) .. "</" .. key .. ">", blessing = bless_key }
			end

			return { result, blessing = bless_key }
		end
	end
}

local html = setmetatable( {
	bless = function( contents )
		return { contents, blessing = bless_key }
	end,
}, mt )

function _M.render( f )
	bless_key = arc4.random( 2^32 - 1 )
	local rendered = f( html )

	assert( rendered.blessing == bless_key, "unblessed html fragment" )

	return rendered[ 1 ]
end

return _M
