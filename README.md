Flea is a Lua web framework that aims to be tiny and secure by default.


Requirements
------------

lua >= 5.1, `luarocks install fcgi`, `luarocks install lua-cjson`,
`luarocks install symmetric`, `luarocks install arc4random`


Secure by default
-----------------

Flea tries to make the obvious and easy solution, also safe and secure.
Here are a few examples of attacks, and how flea helps prevent them.

### SQL Injection

flea includes a wrapper module for accessing SQLite databases, which you
can use like:

	for row in db(
		"SELECT * FROM users WHERE id = ?",
		request.get.user_id
	) do
		-- do things with row
	end

	local me = db:first( "SELECT * FROM users WHERE id = ?", 123 )
	db:exec( "DROP TABLE users" )

The SQLite module makes it easy to achieve common tasks (iterate, select
first, exec), and uses prepared statements in every case to help prevent
SQL injection.

### Cross-Site Scripting (XSS)

The template module automatically escapes text inside tags and
attributes. It does not yet warn the developer of unsafe tag usage, such
as `onerror` or `href="javascript:..."`, so be aware.

In the following example, `row.name` gets HTML escaped, and `row.id`
gets attribute escaped. It's a bit ugly, but that's because I couldn't
be bothered to write a parser:

	request:html( function( html )
		return html.div[ ".user" ]( {
			html.h1( row.name ),
			html.a(
				{ href = "/delete/" .. row.id },
				"delete this user"
			),
		} )
	end )

### Access Control

Request handlers are simply functions. If you want pages to be behind a
login screen, compose their request handlers with a function that
authenticates the user. This isn't secure by default, but it does make
it easier to see when your code is incorrect.

	local auth_routes = {
		{ "admin", admin_handler },
		{ "logout", logout_handler },
	}
	local normal_routes = {
		{ "", index_handler },
	}

	for _, route in ipairs( auth_routes ) do
		flea.get( route[ 1 ], require_auth( route[ 2 ] ) )
	end
	for _, route in ipairs( normal_routes ) do
		flea.get( route[ 1 ], route[ 2 ] )
	end

### Information Leakage on Redirects

This is a less common flaw, but I have seen websites that redirect you
away from sensitive pages with a 302 Found, then print the contents of
the page anyway. It won't show up if you visit the page in a web
browser, but curl can find it.

To prevent these attacks, flea clears all output and converts writes
into no-ops for most non-200 status codes.

### Response splitting

[split]: https://www.owasp.org/index.php/HTTP_Response_Splitting

flea doesn't allow `\r` or `\n` in response headers. This prevents a
clever little attack known as [response splitting][split]

### Cross-Site Request Forgery

Flea provides a module for generating and checking CSRF tokens.
I plan on automating this, but at the moment you have to remember to use
it.

Template:

	request:html( function( html )
		return html.form( { method = "post", action = "/dangerous" }, {
			csrf.token( request, html ),
			html.input( { name = "uh_oh", type = "text" } ),
			html.input( { type = "submit" } ),
		} )
	end )

Request handler:

	return function( request )
		if not request.post.uh_oh or not csrf.validate( request ) then
			return request:bad_request()
		end

		-- we're good
	end

### Encrypted/Authenticated Cookies

Cookies are encrypted and authenticated with libsodium. This gives you
two guarantees:

- Attackers cannot read sensitive information from cookies
- Attackers cannot tamper with your cookies

The implementation currently does nothing to mitigate replay attacks.
I'm not sure if there is a nice way to solve this completely, but I plan
on adding expiry information to cookies which provides some defence.

### FastCGI

Flea does not include its own HTTP parser, hand written nor machine
generated. I don't understand why people do this.
