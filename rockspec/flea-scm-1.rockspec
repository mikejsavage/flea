package = "flea"
version = "scm-1"

source = {
	url = "git://github.com/mikejsavage/flea.git",
}

description = {
	summary = "A lightweight Lua web framework",
	homepage = "http://github.com/mikejsavage/flea",
	license = "ISC",
	maintainer = "Mike Savage",
}

dependencies = {
	"lua >= 5.1",
	"fcgi",
	"lua-cjson",
	"symmetric",
	"arc4random",
}

build = {
	type = "builtin",

	modules = {
		[ "flea" ] = "src/flea.lua",
		[ "flea.config" ] = "src/flea/config.lua",
		[ "flea.cookies" ] = "src/flea/cookies.lua",
		[ "flea.csrf" ] = "src/flea/csrf.lua",
		[ "flea.request" ] = "src/flea/request.lua",
		[ "flea.routes" ] = "src/flea/routes.lua",
		[ "flea.secret" ] = "src/flea/secret.lua",
		[ "flea.sqlite" ] = "src/flea/sqlite.lua",
		[ "flea.template" ] = "src/flea/template.lua",
		[ "flea.time" ] = "src/flea/time.lua",
		[ "flea.utils" ] = "src/flea/utils.lua",
	},
}
