#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <signal.h>
#include <sys/queue.h>
#include <sys/stat.h>

#include <event2/event.h>
#include <event2/event_struct.h>
#include <event2/buffer.h>
#include <event2/http.h>
#include <event2/http_struct.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

typedef enum { false, true } bool;

static int handlerIdx = LUA_NOREF;
static int closeHandlerIdx = LUA_NOREF;
static int port;

#define lua_setkey( L, k, v ) lua_pushliteral( L, k ); \
	lua_pushstring( L, v ); \
	lua_settable( L, -3 )

#define PRETEND_TO_USE( x ) ( void ) ( x )

void pushKV( lua_State* L, struct evkeyvalq* keyvalq )
{
	lua_newtable( L );

	struct evkeyval* keyval;
	TAILQ_FOREACH( keyval, keyvalq, next )
	{
		lua_pushstring( L, keyval->key );
		lua_pushstring( L, keyval->value );
		lua_settable( L, -3 );
	}
}

void pushUri( lua_State* L, struct evhttp_uri* uri )
{
	lua_newtable( L );

	lua_setkey( L, "path", evhttp_uri_get_path( uri ) );
	lua_setkey( L, "query", evhttp_uri_get_query( uri ) );
}

const char* methodString( enum evhttp_cmd_type type )
{
	switch( type )
	{
		case EVHTTP_REQ_GET:
			return "get";

		case EVHTTP_REQ_POST:
			return "post";

		case EVHTTP_REQ_HEAD:
			return "head";

		case EVHTTP_REQ_PUT:
			return "put";

		case EVHTTP_REQ_DELETE:
			return "delete";

		case EVHTTP_REQ_OPTIONS:
			return "options";

		case EVHTTP_REQ_TRACE:
			return "trace";

		case EVHTTP_REQ_CONNECT:
			return "connect";

		case EVHTTP_REQ_PATCH:
			return "patch";

		default:
			printf( "You should run me behind a reverse proxy so I don't get garbage requests.\n" );

			exit( 1 );

			return NULL;
	}
}

void handler( struct evhttp_request* request, void* arg )
{
	assert( handlerIdx != LUA_NOREF );
	assert( closeHandlerIdx != LUA_NOREF );

	lua_State* L = ( lua_State* ) arg;

	lua_rawgeti( L, LUA_REGISTRYINDEX, handlerIdx );

	struct evhttp_request** flea = ( struct evhttp_request** ) lua_newuserdata( L, sizeof( struct evhttp_request* ) );
	*flea = request;

	luaL_getmetatable( L, "Flea.request" );

	lua_setkey( L, "method", methodString( evhttp_request_get_command( request ) ) );

	lua_setmetatable( L, -2 );

	struct evhttp_uri* uri = evhttp_uri_parse( request->uri );
	pushUri( L, uri );

	lua_call( L, 2, 0 );

	evhttp_uri_free( uri );

	assert( lua_gettop( L ) == 0 );
}

static int flea_run( lua_State* L )
{
	// http://www.mail-archive.com/libevent-users@monkey.org/msg01603.html
	struct sigaction action =
	{
		.sa_handler = SIG_IGN,
		.sa_flags = 0,
	};

	if( sigemptyset( &action.sa_mask ) == -1 || sigaction( SIGPIPE, &action, 0 ) == -1 )
	{
		lua_pushliteral( L, "failed to ignore SIGPIPE" );

		return lua_error( L );
	}

	struct event_base* base = event_base_new();
	struct evhttp* httpd = evhttp_new( base );

	evhttp_set_gencb( httpd, handler, L );
	evhttp_bind_socket( httpd, "0.0.0.0", port );

	event_base_dispatch( base );

	evhttp_free( httpd );
	event_base_free( base );

	return 0;
}

static int flea_parseQuery( lua_State* L )
{
	const char* query = luaL_checkstring( L, 1 );

	struct evkeyvalq parsed;
	evhttp_parse_query_str( query, &parsed );

	pushKV( L, &parsed );

	evhttp_clear_headers( &parsed );

	return 1;
}

static int flea_randomBytes( lua_State* L )
{
	size_t bytes = luaL_checkinteger( L, 1 );

	char* buffer = malloc( bytes );

	if( buffer == NULL )
	{
		lua_pushliteral( L, "out of memory" );

		return lua_error( L );
	}

	evutil_secure_rng_get_bytes( buffer, bytes );

	lua_pushlstring( L, buffer, bytes );

	free( buffer );
	
	return 1;
}

static struct evhttp_request* checkRequest( lua_State* L, int narg )
{
	void* udata = luaL_checkudata( L, narg, "Flea.request" );
	luaL_argcheck( L, udata != NULL, narg, "`request' expected" );

	return *( struct evhttp_request** ) udata;
}

static FILE* checkFile( lua_State* L, int narg )
{
	void* udata = luaL_checkudata( L, narg, LUA_FILEHANDLE );
	luaL_argcheck( L, udata != NULL, narg, "`file' expected" );

	return *( FILE** ) udata;
}

static int request_write( lua_State* L )
{
	struct evhttp_request* request = checkRequest( L, 1 );
	const char* data = luaL_checkstring( L, 2 );
	size_t len = lua_objlen( L, 2 );

	evbuffer_add( request->output_buffer, data, len );

	return 0;
}

static int request_clear( lua_State* L )
{
	struct evhttp_request* request = checkRequest( L, 1 );

	evbuffer_drain( request->output_buffer, evbuffer_get_length( request->output_buffer ) );

	return 0;
}

static int request_getHeader( lua_State* L )
{
	struct evhttp_request* request = checkRequest( L, 1 );
	const char* header = luaL_checkstring( L, 2 );

	const char* value = evhttp_find_header( request->input_headers, header );

	lua_pushstring( L, value );

	return 1;
}

static int request_addHeader( lua_State* L )
{
	struct evhttp_request* request = checkRequest( L, 1 );
	const char* header = luaL_checkstring( L, 2 );
	const char* value = luaL_checkstring( L, 3 );

	evhttp_add_header( request->output_headers, header, value );

	return 0;
}

static int request_clearHeaders( lua_State* L )
{
	struct evhttp_request* request = checkRequest( L, 1 );

	evhttp_clear_headers( request->output_headers );

	return 0;
}

static int request_postData( lua_State* L )
{
	struct evhttp_request* request = checkRequest( L, 1 );

	const char* contentLength = evhttp_find_header( request->input_headers, "Content-Length" );

	if( contentLength != NULL )
	{
		int length = atoi( contentLength );

		char* buffer = malloc( length );

		if( buffer == NULL )
		{
			lua_pushliteral( L, "out of memory" );

			return lua_error( L );
		}

		evbuffer_remove( request->input_buffer, buffer, length );

		lua_pushlstring( L, buffer, length );

		free( buffer );

		return 1;
	}

	return 0;
}

static int request_sendFile( lua_State* L )
{
	struct evhttp_request* request = checkRequest( L, 1 );
	FILE* file = checkFile( L, 2 );

	int fd = fileno( file );

	struct stat st;
	fstat( fd, &st );

	evbuffer_add_file( request->output_buffer, fd, 0, st.st_size );

	return 0;
}

static int request_send( lua_State* L )
{
	struct evhttp_request* request = checkRequest( L, 1 );
	int code = luaL_checkinteger( L, 2 );
	const char* reason = luaL_checkstring( L, 3 );

	evhttp_send_reply( request, code, reason, NULL );

	return 0;
}

static int init_setHandlers( lua_State* L )
{
	luaL_argcheck( L, lua_type( L, 1 ) == LUA_TFUNCTION, 1, "expected function" );
	luaL_argcheck( L, lua_type( L, 2 ) == LUA_TFUNCTION, 2, "expected function" );

	closeHandlerIdx = luaL_ref( L, LUA_REGISTRYINDEX );
	handlerIdx = luaL_ref( L, LUA_REGISTRYINDEX );

	return 0;
}

struct luaL_reg libFlea[] =
{
	{ "run", flea_run },
	{ "parseQuery", flea_parseQuery },
	{ "randomBytes", flea_randomBytes },
	{ NULL, NULL },
};

struct luaL_reg libRequest[] =
{
	{ "write", request_write },
	{ "clear", request_clear },
	{ "getHeader", request_getHeader },
	{ "addHeader", request_addHeader },
	{ "clearHeaders", request_clearHeaders },
	{ "postData", request_postData },
	{ "sendFile", request_sendFile },
	{ "send", request_send },
	{ NULL, NULL },
};

LUALIB_API int luaopen_libflea( lua_State* L )
{
	port = luaL_checkinteger( L, 1 );

	luaL_openlib( L, "flea", libFlea, 0 );

	luaL_newmetatable( L, "Flea.request" );
	lua_pushliteral( L, "__index" );
	lua_pushvalue( L, -2 );
	lua_settable( L, -3 );
	lua_pushliteral( L, "__metatable" );
	lua_pushvalue( L, -2 );
	lua_settable( L, -3 );
	luaL_openlib( L, NULL, libRequest, 0 );

	lua_pushcfunction( L, init_setHandlers );

	return 1;
}
