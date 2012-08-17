-- pretty much Zed Shaw's view.lua from Tir
-- http://tir.mongrel2.org/

local TemplatesDir = "templates"

local Templates

local Actions = {
	-- run code
	[ "{%" ] = function( block )
		return block
	end,

	-- run code and print return value
	-- will print nothing if equates to false
	[ "{{" ] = function( str )
		assert( loadstring( "return " .. str ) )

		return "if %s then request:write( %s ) end" % { str, str }
	end,

	-- same as above but make it html safe
	[ "{<" ] = function( str )
		return "if %s then request:write( ( %s ):htmlEscape():htmlDecode() ) end" % { str, str }
	end,

	-- load template
	[ "{(" ] = function( str )
		return "request:render( %s )" % str
	end,

	-- comment
	[ "{-" ] = function()
		return nil
	end,
}

local function compileTemplate( template, name )
	-- prepend \n for the gsub in a few lines
	-- append a {} so the last bit of text isn't
	-- chopped by the gmatch
	template = "\n" .. template .. "{}"

	template = template:gsub( "\n%%\n", "\n" ):gsub( "\n[\t ]*(%%[^}][^\n]*)", "\n{%1%%}" ):sub( 2 )

	local code = { }

	for text, block in template:gmatch( "([^{]-)(%b{})" ) do
		if text ~= "" then
			table.insert( code, "request:write( %q )" % text )
		end

		local action = Actions[ block:sub( 1, 2 ) ]

		if action then
			table.insert( code, action( block:sub( 3, -3 ) ) )
		else
			assert( block == "{}", "bad block in template %s: %s" % { name, block } )
		end
	end

	code = table.concat( code, "\n" )

	local func = assert( loadstring( code, name ) )

	return func
end

local function loadTemplates( path, relPath )
	for file in lfs.dir( path ) do
		if file ~= "." and file ~= ".." then
			local fullPath = "%s/%s" % { path, file }
			local attr = lfs.attributes( fullPath )

			if attr.mode == "directory" then
				loadTemplates( fullPath, relPath .. file .. "/" )
			else
				local name = file:match( "^(.+)%.flea$" )

				if name then
					local fullName = ( relPath .. name ):gsub( "/", "." )

					Templates[ fullName ] = compileTemplate(
						io.contents( fullPath ),
						fullName
					)
				else
					printf( "non-template in templates dir: %s", file )
				end
			end
		end
	end
end

if flea.production then
	Templates = setmetatable( { }, {
		__index = function( self, name )
			assert( nil, "no such template: %s" % name )
		end,
	} )

	if io.readable( TemplatesDir ) then
		loadTemplates( TemplatesDir, "" )
	end
else
	Templates = setmetatable( { }, {
		__index = function( self, name )
			assert( type( name ) == "string", "template name must be a string" )

			local path = "%s/%s.flea" % { TemplatesDir, name }

			local readable, err = io.readable( path )
			assert( readable, "could not open template `%s`: %s" % { name, err or "" } )

			return compileTemplate( io.contents( path ), name )
		end,
	} )
end

return Templates
