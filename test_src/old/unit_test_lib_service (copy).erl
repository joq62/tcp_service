%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(unit_test_lib_service). 
  
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
% -include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------
-define(SERVER_ID,"test_tcp_server").
%% External exports
%-export([test/0,init_test/0,start_container_1_test/0,start_container_2_test/0,
%	 adder_1_test/0,adder_2_test/0,
%	 stop_container_1_test/0,stop_container_2_test/0,
%	 misc_lib_1_test/0,misc_lib_2_test/0,
%	 init_tcp_test/0,tcp_1_test/0,tcp_2_test/0,
%	 tcp_3_test/0,
%	 dns_address_test/0,
%	 end_tcp_test/0]).

-export([test/0,init_test/0,start_container_1_test/0,start_container_2_test/0,
	 adder_1_test/0,adder_2_test/0,
	 stop_container_1_test/0,stop_container_2_test/0,
	 misc_lib_1_test/0,misc_lib_2_test/0,
	 init_tcp_test/0,
	 tcp_seq_server_start_stop/0,
	 tcp_par_server_start_stop/0,
	 tcp_2_test/0,
	 tcp_3_test/0,
	 end_tcp_test/0]).

%-compile(export_all).

-define(TIMEOUT,1000*15).

%% ====================================================================
%% External functions
%% ====================================================================
test()->
    TestList=[init_test,
	      start_container_1_test,start_container_2_test,
	      adder_1_test,adder_2_test,
	      stop_container_1_test,stop_container_2_test,
	      misc_lib_1_test,misc_lib_2_test,
	      init_tcp_test,
	      tcp_seq_server_start_stop,
	      tcp_par_server_start_stop,
	      tcp_2_test,
	      tcp_3_test,
	      end_tcp_test],
    TestR=[{rpc:call(node(),?MODULE,F,[],?TIMEOUT),F}||F<-TestList],
    
    
    Result=case [{error,F,Res}||{Res,F}<-TestR,Res/=ok] of
	       []->
		   ok;
	       ErrorMsg->
		   ErrorMsg
	   end,
    Result.
	


%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init_test()->
 %   ok=application:start(lib_service),
    Pod=misc_lib:get_node_by_id("pod_adder_1"),
    container:delete(Pod,"pod_adder_1",["adder_service"]),
    pod:delete(node(),"pod_adder_1"),
    container:delete(Pod,"pod_adder_2",["adder_service"]),
    pod:delete(node(),"pod_adder_2"),
    {pong,_,lib_service}=lib_service:ping(),
    ok.
    

%------------------ misc_lib -----------------------------------
misc_lib_1_test()->
    ok.

misc_lib_2_test()->
    {ok,Host}=inet:gethostname(),
    PodIdServer=?SERVER_ID++"@"++Host,
    PodServer=list_to_atom(PodIdServer),
    PodServer=misc_lib:get_node_by_id(?SERVER_ID), 
    ok.


%------------------ ceate and delete Pods and containers -------
%create_container(Pod,PodId,[{{service,ServiceId},{Type,Source}}

start_container_1_test()->
    {ok,PodAdder}=pod:create(node(),"pod_adder_1"),
    ok=container:create(PodAdder,"pod_adder_1",
			[{{service,"adder_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
   ok.

start_container_2_test()->
    {ok,PodAdder}=pod:create(node(),"pod_adder_2"),
    ok=container:create(PodAdder,"pod_adder_2",
			[{{service,"adder_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
   ok.
adder_1_test()->
    Pod=misc_lib:get_node_by_id("pod_adder_1"),
    42=rpc:call(Pod,adder_service,add,[20,22]),
    ok.

adder_2_test()->
    Pod=misc_lib:get_node_by_id("pod_adder_2"),
    142=rpc:call(Pod,adder_service,add,[120,22]),
    ok.

stop_container_1_test()->
    Pod=misc_lib:get_node_by_id("pod_adder_1"),
    container:delete(Pod,"pod_adder_1",["adder_service"]),
   % timer:sleep(500),
    {ok,stopped}=pod:delete(node(),"pod_adder_1"),
    ok.

stop_container_2_test()->
    Pod=misc_lib:get_node_by_id("pod_adder_2"),
    container:delete(Pod,"pod_adder_2",["adder_service"]),
  %  timer:sleep(500),
    {ok,stopped}=pod:delete(node(),"pod_adder_2"),
    ok.

%------------------------------------------------------------





%**************************** tcp test   ****************************
init_tcp_test()->
    pod:delete(node(),"pod_lib_1"),
    pod:delete(node(),"pod_lib_2"),
    {ok,Pod_1}=pod:create(node(),"pod_lib_1"),
    ok=container:create(Pod_1,"pod_lib_1",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),    
    {ok,Pod_2}=pod:create(node(),"pod_lib_2"),
    ok=container:create(Pod_2,"pod_lib_2",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),    
    ok.

tcp_seq_server_start_stop()->
    PodServer=misc_lib:get_node_by_id("pod_lib_1"),
    {ok,ServerSeq}=rpc:call(PodServer,tcp_server,start_seq_server,["localhost",52000]),
    
    %Check my ip
    {ok,"localhost",52000}=rpc:call(PodServer,tcp_server,myip,[ServerSeq],1000),
    % Normal case seq tcp:call(
    D=date(),
    D=rpc:call(node(),tcp_client,call,[{"localhost",52000},{erlang,date,[]}],2000),
    
    % Normal case seq tcp:conne ..
    {ok,ServerSeq2}=tcp_client:connect("localhost",52000),
    {ok,ServerSeq3}=tcp_client:connect("localhost",52000),
    tcp_client:session_call(ServerSeq2,{erlang,date,[]}),
    tcp_client:session_call(ServerSeq3,{erlang,date,[]}),
    D=tcp_client:get_msg(ServerSeq2,1000),
    {error,[get_msg_timeout,tcp_client,_Line]}=tcp_client:get_msg(ServerSeq3,1000),
    
    tcp_client:disconnect(ServerSeq2),
    tcp_client:disconnect(ServerSeq3),

    ok=rpc:call(PodServer,tcp_server,terminate,[ServerSeq],1000),
    {error,[timeout,"localhost",52000,tcp_client,_]}=tcp_client:connect("localhost",52000),
    {error,econnrefused}=tcp_client:call({"localhost",52000},{erlang,date,[]}),
    ok.
% funkar hit 
tcp_par_server_start_stop()->
    PodServer=misc_lib:get_node_by_id("pod_lib_1"),
    {ok,ServerPar}=rpc:call(PodServer,tcp_server,start_par_server,["localhost",52001]),
    
    %Check my ip
   {ok,"localhost",52001}=rpc:call(PodServer,tcp_server,myip,[ServerPar],1000),
    % Normal case seq tcp:call(
    D=date(),
    D=rpc:call(node(),tcp_client,call,[{"localhost",52001},{erlang,date,[]}],2000),
    
    % Normal case seq tcp:conne ..
    {ok,Server2}=tcp_client:connect("localhost",52001),
    {ok,Server3}=tcp_client:connect("localhost",52001),
    tcp_client:session_call(Server2,{erlang,date,[]}),
    tcp_client:session_call(Server3,{erlang,date,[]}),
    D=tcp_client:get_msg(Server2,1000),
    D=tcp_client:get_msg(Server3,1000),
    
    tcp_client:disconnect(Server2),
    tcp_client:disconnect(Server3),
    ok=rpc:call(PodServer,tcp_server,terminate,[ServerPar],1000),
  
    {error,econnrefused}=tcp_client:call({"localhost",52001},{erlang,date,[]}),
    {error,[timeout,"localhost",52001,tcp_client,_]}=tcp_client:connect("localhost",52001),
    ok.


tcp_2_test()->
    PodServer=misc_lib:get_node_by_id("pod_lib_1"),
    {ok,_}=rpc:call(PodServer,tcp_server,start_par_server,["localhost",53000]),
    {error,[eexists,dns_service,lib_service,_]}=tcp_client:call({"localhost",53000},{lib_service,dns_address,[]}),
    {ok,_}=rpc:call(PodServer,tcp_server,start_par_server,["localhost",42000]),
    {"localhost",42000}=tcp_client:call({"localhost",53000},{lib_service,dns_address,[]}),
    
    {ok,Session}=tcp_client:connect("localhost",53000),
    {"localhost",42000}=tcp_client:call({"localhost",53000},{lib_service,dns_address,[]}),
 % tcp_client:session_call(PidSession,{erlang,date,[]}),
    loop_send(2,Session),
    _R1=loop_get(2,Session,[]),
    loop_send2(2,Session,PodServer),
    _R2=loop_get(2,Session,[]),
    tcp_client:disconnect(Session),
    ok.

tcp_3_test()->
    PodServer=misc_lib:get_node_by_id("pod_lib_1"),
    {ok,_Server}=rpc:call(PodServer,tcp_server,start_seq_server,["localhost",54000]),
    do_call(2,"localhost",54000),
    %Check dns_address
    
    ok.
    
do_call(0,_,_)->
    ok;
do_call(N,IpAddr,Port) ->
    D=date(),
    D=tcp_client:call({IpAddr,Port},{erlang,date,[]}),
    do_call(N-1,IpAddr,Port).

loop_send2(0,_,_)->
    ok;
loop_send2(N,PidSession,Pod) ->
    tcp_client:session_call(PidSession,{erlang,date,[]}),
    loop_send2(N-1,PidSession,Pod).
loop_send(0,_)->
    ok;
loop_send(N,PidSession) ->
    tcp_client:session_call(PidSession,{erlang,date,[]}),
    loop_send(N-1,PidSession).
loop_get(0,_PidSession,Result)->
    Result;
loop_get(N,PidSession,Acc) ->
    loop_get(N-1,PidSession,[{N,tcp_client:get_msg(PidSession,100)}|Acc]).
    
end_tcp_test()->
    container:delete('pod_lib_1@asus.com',"pod_adder_1",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_lib_1"),
    container:delete('pod_lib_2@asus.com',"pod_adder_2",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_lib_2"),
    ok.


%**************************************************************
