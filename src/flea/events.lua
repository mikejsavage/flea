local Events = { }

local function listen( event, states, id )
	if not Events[ event ] then
		Events[ event ] = { }
	end

	table.insert( Events[ event ], {
		states = states,
		id = id,
	} )
end

function flea.event( event, ... )
	enforce( event, "event", "string" )

	if Events[ event ] then
		for _, coro in ipairs( Events[ event ] ) do
			coroutine.resume( coro.states[ coro.id ], ... )

			if coroutine.status( coro.states[ coro.id ] ) == "dead" then
				coro.states[ coro.id ] = nil
			end
		end

		Events[ event ] = { }
	end
end

return {
	listen = listen,
}
