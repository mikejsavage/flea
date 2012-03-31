#! /usr/bin/lua

-- this isn't strictly necessary but it lets us run the app from a different dir
require( "lfs" )

lfs.chdir( arg[ 0 ]:match( "^(.-)[^/]*$" ) )

package.path = package.path .. ";../../src/?.lua"
package.cpath = package.cpath .. ";../../src/?.so"

require( "flea" )

flea.route( "", "index" )
flea.route( "(.+)", "index" )

flea.run()
