#! /usr/bin/lua

-- this isn't strictly necessary but it lets us run the app from a different dir
require( "lfs" )

lfs.chdir( arg[ 0 ]:match( "^(.-)[^/]*$" ) )

-- this is so you can run the examples just by cloning the repo
-- you shouldn't include this in anything you write
package.path = package.path .. ";../../src/?.lua"
package.cpath = package.cpath .. ";../../src/?.so"

require( "flea" )

flea.route( "", "index", { stateful = true } )
flea.route( "click", "click", { stateful = true } )
flea.route( "listen", "listen", { stateful = true } )

flea.run()
