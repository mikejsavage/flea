package = "flea"
version = "scm-1"

source = {
	url = "git://github.com/mikejsavage/flea.git",
}

description = {
	summary = "A lightweight web framework",
	detailed = [[
		Flea is a minimal web framework which aims to be in the spirit
		of Lua by only providing the basics.
	]],
	homepage = "http://github.com/mikejsavage/flea",
	license = "BSD",
	maintainer = "Mike Savage",
}

dependencies = {
	"lua ~> 5.1",
}

external_dependencies = {
	libevent = {
		header = "event.h",
	},
	evhttp = {
		header = "evhttp.h",
	},
}

build = {
	type = "make",

	install_pass = false,

	install = {
		lua = {
			[ "flea" ] = "src/flea.lua",
			[ "flea.cookie" ] = "src/flea/cookie.lua",
			[ "flea.errorHandler" ] = "src/flea/errorHandler.lua",
			[ "flea.handler" ] = "src/flea/handler.lua",
			[ "flea.mime" ] = "src/flea/mime.lua",
			[ "flea.routes" ] = "src/flea/routes.lua",
			[ "flea.serialize" ] = "src/flea/serialize.lua",
			[ "flea.session" ] = "src/flea/session.lua",
			[ "flea.template" ] = "src/flea/template.lua",
			[ "flea.utils" ] = "src/flea/utils.lua",
		},

		lib = {
			[ "libflea" ] = "src/libflea.so",
		},
	},
}
