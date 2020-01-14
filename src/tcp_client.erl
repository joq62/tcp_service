%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(tcp_client).
  


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
-define (CLIENT_SETUP,[binary, {packet,4}]).
-define (TIMEOUT_TCPCLIENT,10*1000).
-define (TIMEOUT_CONNECT,3*1000).

-define(KEY_M_OS_CMD,89181808).
-define(KEY_F_OS_CMD,"95594968").
-define(KEY_MSG,'100200273').

%% External exports
-export([connect/2,connect/3,disconnect/1,
	 call/2,cast/2,
	 get_msg/2
	]).

-export([
	]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function: connect(IpAddr,Port)
%% Description:
%% Returns: {ok,Socket}|{error,Err}
%% --------------------------------------------------------------------
connect(IpAddr,Port)->
    Result=case gen_tcp:connect(IpAddr,Port,?CLIENT_SETUP) of
	       {ok,Socket}->
		   {ok,Socket};
	       {error,Err} ->
		   {error,[Err,?MODULE,?LINE]}
	   end,
    Result.
    
connect(IpAddr,Port,Timeout)->
    Client=self(),
    Pid=spawn(fun()->connect_timeout(IpAddr,Port,Client) end),
    Result=receive
	       {Pid,Reply}->
		   Reply
	   after Timeout ->
		   {error,[timeout,connect,IpAddr,Port,?MODULE,?LINE]}
	   end,
    Result.
		
connect_timeout(IpAddr,Port,Client)->
    Client!{self(),gen_tcp:connect(IpAddr,Port,?CLIENT_SETUP)}.

disconnect(Socket)->
    gen_tcp:close(Socket).

cast(Socket,{M,F,A})->
    Msg=case {M,F,A} of
	    {os,cmd,A}->
		{?KEY_MSG,call,{?KEY_M_OS_CMD,?KEY_F_OS_CMD,A}};
	    {M,F,A}->
		{?KEY_MSG,call,{M,F,A}}
	end, 
    gen_tcp:send(Socket,term_to_binary(Msg)).

get_msg(Socket,Timeout)->
    Result=receive
	       {tcp,Socket,Bin}->
		   case binary_to_term(Bin) of
		       {?KEY_MSG,R}->
			   R;
		       Err->
			   {error,[unmatched,Socket,Err,?MODULE,?LINE]}
		   end;
	       {tcp_closed, Socket}->
		   {error,[tcp_closed,Socket]}	       
	   after Timeout ->
		   {error,[tcp_timeout,Socket,?MODULE,?LINE]}
	   end,
    Result.


%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
call({IpAddr,Port},{M,F,A})->
    Msg=case {M,F,A} of
	    {os,cmd,A}->
		{?KEY_MSG,call,{?KEY_M_OS_CMD,?KEY_F_OS_CMD,A}};
	    {M,F,A}->
		{?KEY_MSG,call,{M,F,A}}
	end,
    send(IpAddr,Port,Msg).

send(IpAddr,Port,Msg)->
    case gen_tcp:connect(IpAddr,Port,?CLIENT_SETUP) of
	{ok,Socket}->
	    ok=gen_tcp:send(Socket,term_to_binary(Msg)),
	    receive
		{tcp,Socket,Bin}->
		    Result=case binary_to_term(Bin) of
			       {?KEY_MSG,R}->
				   R;
			       Err->
				   {error,[Err,?MODULE,?LINE]}
			   end;
		{tcp_closed, Socket}->
		    Result={error,tcp_closed}
	    after ?TIMEOUT_TCPCLIENT ->
		    Result={error,[tcp_timeout,IpAddr,Port,Msg],?MODULE,?LINE}
	    end,
	    ok=gen_tcp:close(Socket);
	{error,Err}->
	    Result={error,[Err,?MODULE,?LINE]}
    end,
   Result.
			   
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
