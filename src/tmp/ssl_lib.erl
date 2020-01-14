%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Created : 7 March 2015
%%% Revsion : 2015-06-19: 1.0.0 :  Created
%%% Description : ssl_lib is a support package when using ssl in communication
%%% 
%%% -------------------------------------------------------------------
-module(ssl_lib).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Definitions
%% --------------------------------------------------------------------
-define (TIMEOUT_SSLCLIENT, 15*1000).
%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([start/4, stop/1]).
-export([call/3,cast/3,
	 connect/2,disconnect/1,call/2]).


%%
%% API Function
%%

%% --------------------------------------------------------------------
%% Func: start
%% Purpose: 
%% Returns:
%% --------------------------------------------------------------------
stop(Pid)->
    Pid!terminate.

%% --------------------------------------------------------------------
%% Func: start
%% Purpose: 
%% Returns:
%% --------------------------------------------------------------------

start(Port,CertFile,KeyFile,Type) ->
  %  Pid=spawn(fun()->test_server(self()) end),
    Pid=spawn(fun()->start_ssl_server(self(),Port,CertFile,KeyFile,Type) end),
   % Result=receive
%	       {Pid,{ok,ssl_start}}->
%		   {ok,Pid};
%	       {ok,ssl_listen}->
%		   {ok,Pid};
%	       {error,Err} ->
%		   {error,Err}
%	   after 1000->
%		   {error,[timeout,Pid,?FILE,?LINE]}
%	   end,
 %   Result.
    {ok,Pid}.
test_server(PidParent)->
    PidParent!{self(),{ok,ssl_start}}.
start_ssl_server(PidParent,Port,CertFile,KeyFile,Type) ->
    case ssl:start() of
 	ok->
	    case ssl:listen(Port, [binary,{packet,4},{certfile,CertFile}, {keyfile,KeyFile}, 
				   {reuseaddr, true}, {active, true}]) of
		{ok, LSocket}->
	%	    PidParent!{ok,ssl_listen},
		    case Type of
			parallell->
			    spawn(fun() -> par_connect(LSocket) end);
			sequence ->
			    glurk
		    end,
% Following statements must be here otherwise the connection is closed???? 
		    receive
			terminate->
			    io:format("Terminted : ~p~n", [{?MODULE,?LINE}])
		    end;
		_Err ->
		    error
		    %PidParent!{error,[ssl_listen,Err,?FILE,?LINE]}
	    end;
	_Err->
	    error
	    %PidParent!{error,[ssl_start,Err,?FILE,?LINE]}
    end.
%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Func: start
%% Purpose: 
%% Returns:
%% --------------------------------------------------------------------
par_connect(LSocket)->
    {ok, Socket} = ssl:transport_accept(LSocket),
    ok= ssl:handshake(Socket),
    spawn(fun() -> par_connect(LSocket)	end),
    loop(Socket).

loop(Socket) ->
    ssl:setopts(Socket, [{active, once}]),
    receive
	{ssl,Socket,Bin} ->
	%    io:format("Got packet: ~p~n", [binary_to_term(Bin)]),
	    Reply=case binary_to_term(Bin) of
		      {Pod,call,{M,F,A}}->
			  rpc:call(Pod,M,F,A);
		      {Pod,cast,{M,F,A}}->
			  rpc:cast(Pod,M,F,A);
		      Err->
			  {error,[Err, ?FILE,?LINE]}
		  end,
	    ssl:send(Socket, term_to_binary(Reply)),
	    loop(Socket);
	{ssl_closed, Socket} ->
	    ok=ssl:close(Socket);
	    %io:format("Closing socket: ~p~n", [Sock]);
	Error ->
	    ok=ssl:close(Socket),
	    io:format("Error on socket: ~p~n", [Error])
    end,
    ok.

%% --------------------------------------------------------------------
%% Func: start
%% Purpose: 
%% Returns:
%% --------------------------------------------------------------------
connect(Addr,Port)->
   % io:format(" ~p~n",[{?MODULE,?LINE,Msg}]),
    case ssl:connect(Addr, Port,  [binary,{packet,4}])of
	{ok,Socket}->
	    Reply = {ok,Socket};
	{error,Err} ->
	    Reply={error,{Err,?MODULE,?LINE}}
    end,	
    Reply.  

%% --------------------------------------------------------------------
%% Func: start
%% Purpose: 
%% Returns:
%% --------------------------------------------------------------------
call(Socket,MsgTerm)->
    MsgBin=term_to_binary(MsgTerm),
    ok = ssl:send(Socket,[MsgBin]),
    receive
	{ssl,{sslsocket,_Z1,_Z2},ReplyIoList}->
	    ReplyBin=iolist_to_binary(ReplyIoList),
	    Reply=binary_to_term(ReplyBin);
	{error,Err} ->
	    Reply={error,{Err,?MODULE,?LINE}};
	X->
	    io:format("unmatched signal ~p~n",[{?MODULE,?LINE,X}]),
	    Reply={error,unmatchd_signal,X}
    after ?TIMEOUT_SSLCLIENT ->
	    Reply={error,tcp_timeout}
    end,
    Reply.  

%% --------------------------------------------------------------------
%% Func: start
%% Purpose: 
%% Returns:
%% --------------------------------------------------------------------
disconnect(Socket)->
    ssl:close(Socket).

%% --------------------------------------------------------------------
%% Func: start
%% Purpose: 
%% Returns:
%% --------------------------------------------------------------------
call(Addr,Port,MsgTerm)->
    case ssl:connect(Addr, Port,  [binary,{packet,4}])of
	{ok,Socket}->
	    MsgBin=term_to_binary(MsgTerm),
	    ok = ssl:send(Socket,[MsgBin]),
	    receive
		{ssl,{sslsocket,_Z1,_Z2},ReplyIoList}->
		    ReplyBin=iolist_to_binary(ReplyIoList),
		    Reply=binary_to_term(ReplyBin),
		    ssl:close(Socket);
		{error,Err} ->
		    Reply={error,{Err,?MODULE,?LINE}},
		    ssl:close(Socket);
		X->
		    io:format("unmatched signal ~p~n",[{?MODULE,?LINE,X}]),
		    Reply={error,unmatchd_signal,X},
		    ssl:close(Socket)
	    after ?TIMEOUT_SSLCLIENT ->
		    Reply={error,tcp_timeout},
		    ssl:close(Socket)
	    end;
	{error,Err} ->
	    Reply={error,{Err,?MODULE,?LINE}}
    end,
    Reply.
%% --------------------------------------------------------------------
%% Func: start
%% Purpose: 
%% Returns:
%% --------------------------------------------------------------------
cast(Addr,Port,MsgTerm)->
   % io:format(" ~p~n",[{?MODULE,?LINE,Msg}]),
    case ssl:connect(Addr, Port,  [binary,{packet,4}])of
	{ok,Socket}->
	    MsgBin=term_to_binary(MsgTerm),
	    Reply = ssl:send(Socket,[MsgBin]),
	    ssl:close(Socket);
	{error,Err} ->
	    Reply={error,{Err,?MODULE,?LINE}}
    end,	
    Reply.  
%% --------------------------------------------------------------------
%% Func: start
%% Purpose: 
%% Returns:
%% --------------------------------------------------------------------
