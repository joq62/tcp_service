%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% 2019-10-15:
%%% io:format dont work
%%% close tcp dont work needed to remove loop(Socket) call
%%% Add SSL
%%% -------------------------------------------------------------------
-module(tcp_server).
  


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
-define (SERVER_SETUP,[binary,{packet,4},{reuseaddr,true},{active,true}]).
-define (TIMEOUT_TCPSERVER, 100*1000).
-define(KEY_M_OS_CMD,89181808).
-define(KEY_F_OS_CMD,"95594968").
-define(KEY_MSG,'100200273').

%% External exports


-export([start_seq_server/2,
	 start_par_server/2,
	 myip/1,terminate/1
	]).


%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
%% --------------------------------------------------------------------
%% Function: fun/x
%% Description: fun x skeleton 
%% Returns:ok|error
%% ------------------------------------------------------------------
terminate(ServerPid)->
    ClientPid=self(),
    ServerPid!{ClientPid,terminate},
    Result=receive
	       {ServerPid,{terminate_ack}}->
		   ok;
	       Err->
		   {error,[unamatched_signal,Err,?MODULE,?LINE]}
	   after ?TIMEOUT_TCPSERVER->
		   {error,[timeout,terminate,?MODULE,?LINE]}
	   end,	
    Result. 

myip(ServerPid)->
    ClientPid=self(),
    ServerPid!{ClientPid,myip},
    Result=receive
	       {ServerPid,{myip_ack,IpAddr,Port}}->
		   {ok,IpAddr,Port};
	       Err->
		   {error,[unamatched_signal,Err,?MODULE,?LINE]}
	   after ?TIMEOUT_TCPSERVER->
		   {error,[timeout,myip,?MODULE,?LINE]}
	   end,	
    Result.

ctrl_loop(IpAddr,Port)->
    receive
	{Pid,myip} ->
	    Pid!{self(),{myip_ack,IpAddr,Port}},
	    ctrl_loop(IpAddr,Port);
	{Pid,terminate}->
	    Pid!{self(),{terminate_ack}}
    end.

start_seq_server(IpAddr,Port)->
    ClientPid=self(),
    Pid=spawn(fun()->seq_server(IpAddr,Port,ClientPid) end),
    Result=receive
	       {Pid,{start_seq_server_ack,ok}}->
		   {ok,Pid};
	       {Pid,{start_seq_server_ack,error,Err}}->
		   {error,[failed_to_start,start_seq_server,Err,?MODULE,?LINE]}
	   after ?TIMEOUT_TCPSERVER->
		   {error,[timeout,start_seq_server,?MODULE,?LINE]}
	   end,	
    Result.
		  
seq_server(IpAddr,Port,ClientPid)->
   Result = case gen_tcp:listen(Port,?SERVER_SETUP) of  
		{ok, LSock}->
		    ClientPid!{self(),{start_seq_server_ack,ok}},
		    spawn(fun()->seq_loop(LSock) end),
		    ctrl_loop(IpAddr,Port);
	       Err ->
		    ClientPid!{self(),{start_seq_server_ack,error,Err}}
	    end,
    Result.

seq_loop(LSock)->
    {ok,Socket}=gen_tcp:accept(LSock),
    loop(Socket),
    seq_loop(LSock).

%% --------------------------------------------------------------------
%% Function: fun/x
%% Description: fun x skeleton 
%% Returns:ok|error
%% ------------------------------------------------------------------
start_par_server(IpAddr,Port)->
    ClientPid=self(),
    Pid=spawn(fun()->par_server(IpAddr,Port,ClientPid) end),
    Result=receive
	       {Pid,{start_par_server_ack,ok}}->
		   {ok,Pid};
	       {Pid,{start_par_server_ack,error,Err}}->
		   {error,[failed_to_start,start_par_server,Err,?MODULE,?LINE]}
	   after ?TIMEOUT_TCPSERVER->
		   {error,[timeout,start_seq_server,?MODULE,?LINE]}
	   end,	
    Result.
		  
par_server(IpAddr,Port,ClientPid)->
   Result = case gen_tcp:listen(Port,?SERVER_SETUP) of  
		{ok, LSock}->
		    ClientPid!{self(),{start_par_server_ack,ok}},
		    spawn(fun()->par_loop(LSock) end),
		    ctrl_loop(IpAddr,Port);
	       Err ->
		    ClientPid!{self(),{start_par_server_ack,error,Err}}
	    end,
    Result.

par_loop(LSock)->
    {ok,Socket}=gen_tcp:accept(LSock),
    spawn(fun()-> par_loop(LSock) end),
    loop(Socket).


%% --------------------------------------------------------------------
%% Function: fun/x
%% Description: fun x skeleton 
%% Returns:ok|error
%% ------------------------------------------------------------------
loop(Socket)->
 %   io:format("~p~n",[{Socket,?MODULE,?LINE}]),
    receive
	{tcp, Socket, Bin} ->
	   % io:format("~p~n",[{Socket, binary_to_term(Bin),?MODULE,?LINE}]),
	    case binary_to_term(Bin) of
		{?KEY_MSG,Pod,cast,{?KEY_M_OS_CMD,?KEY_F_OS_CMD,A}}->
		    Result=rpc:cast(Pod,os,cmd,A),
		    gen_tcp:send(Socket, term_to_binary({?KEY_MSG,Result})),
		    loop(Socket);
		{?KEY_MSG,Pod,cast,{M,F,A}}->
		    Result=rpc:cast(Pod,M,F,A),
		    gen_tcp:send(Socket, term_to_binary({?KEY_MSG,Result})),
		    loop(Socket);
		{?KEY_MSG,Pod,call,{?KEY_M_OS_CMD,?KEY_F_OS_CMD,A}}->
		    Result=rpc:call(Pod,os,cmd,A,?TIMEOUT_TCPSERVER),
		    gen_tcp:send(Socket, term_to_binary({?KEY_MSG,Result})),
		    loop(Socket);
		{?KEY_MSG,Pod,call,{M,F,A}}->
		    Result=rpc:call(Pod,M,F,A,?TIMEOUT_TCPSERVER),
	      	   % io:format("~p~n",[{Socket,{?KEY_MSG,Pod,call,{M,F,A}},?MODULE,?LINE}]),
		    gen_tcp:send(Socket, term_to_binary({?KEY_MSG,Result})),
		    loop(Socket);
		
		{?KEY_MSG,cast,{?KEY_M_OS_CMD,?KEY_F_OS_CMD,A}}->
		    Result=rpc:cast(node(),os,cmd,A),
		    gen_tcp:send(Socket, term_to_binary({?KEY_MSG,Result})),
		    loop(Socket);
		{?KEY_MSG,cast,{M,F,A}}->
		    Result=rpc:cast(node(),M,F,A),
		    gen_tcp:send(Socket, term_to_binary({?KEY_MSG,Result})),
		    loop(Socket);
		{?KEY_MSG,call,{?KEY_M_OS_CMD,?KEY_F_OS_CMD,A}}->
		    Result=rpc:call(node(),os,cmd,A,?TIMEOUT_TCPSERVER),
		    gen_tcp:send(Socket, term_to_binary({?KEY_MSG,Result})),
		    loop(Socket);
		{?KEY_MSG,call,{M,F,A}}->
		    Result=rpc:call(node(),M,F,A,?TIMEOUT_TCPSERVER),
	      	   % io:format("~p~n",[{Socket,{?KEY_MSG,Pod,call,{M,F,A}},?MODULE,?LINE}]),
		    gen_tcp:send(Socket, term_to_binary({?KEY_MSG,Result})),
		    loop(Socket);
		Err ->
		    io:format("Err ~p~n",[{Err,?MODULE,?LINE}]),
		  %  glurk=Err,
		 %   io:format("error  ~p~n",[{node(),?MODULE,?LINE,Err,inet:socknames(Socket)}]),
		    gen_tcp:send(Socket, term_to_binary(Err)),
		    loop(Socket)
	    end;
	{tcp_closed, Socket} ->
	  %  io:format("socket closed ~n"),
	    tcp_closed;
	Err->		    
	    io:format("Err ~p~n",[{Err,?MODULE,?LINE}]),
	    gen_tcp:send(Socket, term_to_binary(Err)),
	    loop(Socket)
    end.
