#! /usr/bin/lua

require( "lfs" )

lfs.chdir( arg[ 0 ]:match( "^(.-)[^/]*$" ) )

package.path = package.path .. ";../../src/?.lua"
package.cpath = package.cpath .. ";../../src/?.so"

require( "flea" )

flea.route( "", "index" )
flea.route( "(.+)", "index" )

flea.registerMimetype( "lua", "text/x-lua" )

flea.run()
