%%% -------------------------------------------------------------------
%%% Author  : Joq Erlang
%%% Description : test application calc
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(lib_service). 

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common_macros.hrl").
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------
-record(state,{dns_address,tcp_servers}).


%% --------------------------------------------------------------------
%% Definitions 
%% --------------------------------------------------------------------




-export([start_tcp_server/2,start_tcp_server/3,
	  stop_tcp_server/1,stop_tcp_server/2,
	 ping/0,
	 dns_address/0,
	 myip/0
	]).

-export([start/0,
	 stop/0,
	 heart_beat/1
	]).

%% gen_server callbacks
-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% ====================================================================
%% External functions
%% ====================================================================

%% Asynchrounus Signals



%% Gen server functions

start()-> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
stop()-> gen_server:call(?MODULE, {stop},infinity).



%%-----------------------------------------------------------------------

dns_address()->
    gen_server:call(?MODULE, {dns_address},infinity).

ping()->
    gen_server:call(?MODULE, {ping},infinity).
myip()->
    gen_server:call(?MODULE, {myip},infinity).

start_tcp_server({IpAddr,Port},Mode)->
    gen_server:call(?MODULE, {start_tcp_server,IpAddr,Port,Mode},infinity).
start_tcp_server(IpAddr,Port,Mode)->
    gen_server:call(?MODULE, {start_tcp_server,IpAddr,Port,Mode},infinity).

stop_tcp_server({IpAddr,Port})->
    gen_server:call(?MODULE, {stop_tcp_server,IpAddr,Port},infinity).
stop_tcp_server(IpAddr,Port)->
    gen_server:call(?MODULE, {stop_tcp_server,IpAddr,Port},infinity).
%%-----------------------------------------------------------------------

heart_beat(Interval)->
    gen_server:cast(?MODULE, {heart_beat,Interval}).


%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%
%% --------------------------------------------------------------------
init([]) ->
  %  MyPid=self(),
   % spawn(fun()->do_dns_address(MyPid) end),
 %   spawn(fun()->h_beat(?HB_INTERVAL) end),
	
    {ok, #state{dns_address=[],tcp_servers=[]}}.   
    
%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (aterminate/2 is called)
%% --------------------------------------------------------------------
handle_call({dns_address}, _From, State) ->
  %  Reply=case tcp_client:call(?DNS_ADDRESS,{dns_service,ping,[]}) of
%	      {pong,_,_}->
%		  ?DNS_ADDRESS;
%	      Err->
%		  {error,[eexists,dns_service,?DNS_ADDRESS,Err,?MODULE,?LINE]}
%	  end,
    Reply=?DNS_ADDRESS,
    {reply, Reply,State};


handle_call({ping}, _From, State) ->
    Reply={pong,node(),?MODULE},
    {reply, Reply,State};

handle_call({start_tcp_server,NewIpAddr,NewPort,NewMode}, _From, State) ->
    TcpServers=State#state.tcp_servers,
    Reply=case TcpServers of
	      []-> % Only one Server
		  case NewMode of
		      sequence->
			  case tcp_server:start_seq_server(NewIpAddr,NewPort) of
			      {error,Err}->
				  NewState=State,
				  {error,Err};
			      {ok,SeqServer}->
				  NewState=State#state{tcp_servers=[{NewIpAddr,NewPort,NewMode,SeqServer}|TcpServers]},
				  ok
			  end;
		      parallell->
			  case tcp_server:start_par_server(NewIpAddr,NewPort) of
			      {error,Err}->
				  NewState=State,
				  {error,Err};
			      {ok,ParServer}->
				  NewState=State#state{tcp_servers=[{NewIpAddr,NewPort,NewMode,ParServer}|TcpServers]},
				  ok
			  end;
		      Err->
			  NewState=State,
			  {error,Err}
		  end;
	      [{_,_,_,_}]->
		  NewState=State,
		  {error,[already_started,NewIpAddr,NewPort,?MODULE,?LINE]}
	  end,
    {reply, Reply, NewState};


handle_call({stop_tcp_server,StopIpAddr,StopPort}, _From, State) ->
    TcpServers=State#state.tcp_servers,
    Reply=case TcpServers of
	      []->
		  NewState=State,
		  {error,[not_started,StopIpAddr,StopPort,?MODULE,?LINE]};
	      [{StopIpAddr,StopPort,Mode,Server}]->
		  ok=tcp_server:terminate(Server),
		  NewState=State#state{tcp_servers=lists:delete({StopIpAddr,StopPort,Mode,Server},TcpServers)},
		  {ok,stopped}
	  end,
    {reply, Reply, NewState};

handle_call({myip}, _From, State) ->
    TcpServers=State#state.tcp_servers,
    Reply=case TcpServers of
	      []->
		  {error,[myip,not_started,?MODULE,?LINE]};
	      [{IpAddr,Port,_Mode,_Server}]->
		  {IpAddr,Port}
	  end,
    {reply, Reply, State};

handle_call({stop}, _From, State) ->
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    Reply = {unmatched_signal,?MODULE,Request,From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({heart_beat,Interval}, State) ->

    spawn(fun()->h_beat(Interval) end),    
    {noreply, State};

handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{?MODULE,?LINE,Msg}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({_MyPid,{dns_address,DnsAddress}}, State) ->
    NewState=State#state{dns_address=DnsAddress},
    timer:sleep(1*20*1000),
   % MyPid=self(),
   % spawn(fun()->do_dns_address(MyPid) end),
    {noreply, NewState};
handle_info(Info, State) ->
    io:format("unmatched match info ~p~n",[{?MODULE,?LINE,Info}]),
    {noreply, State}.


%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
h_beat(Interval)->
    timer:sleep(Interval),
    rpc:cast(node(),?MODULE,heart_beat,[Interval]).

%% --------------------------------------------------------------------
%% Internal functions
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
