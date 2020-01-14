%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(lib_service_test).  
  
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

-export([test/0,init_test/0,
	 start_stop_container/0,
	 misc_lib_1_test/0,misc_lib_2_test/0,
	 init_tcp_test/0,
	 tcp_seq_server_start_stop/0,
	 tcp_par_server_start_stop/0,
	 end_tcp_test/0]).

%-compile(export_all).

-define(TIMEOUT,1000*15).

%% ====================================================================
%% External functions
%% ====================================================================
test()->
    TestList=[init_test,
	      start_stop_container,
	      misc_lib_1_test,misc_lib_2_test,
	      init_tcp_test,
	      tcp_seq_server_start_stop,
	    %  tcp_par_server_start_stop,
	    %  tcp_2_test,
	    %  tcp_3_test,
	      end_tcp_test],
    test_support:execute(TestList,?MODULE,?TIMEOUT).
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init_test()->
    pod:delete(node(),"pod_lib_1"),
    pod:delete(node(),"pod_lib_2"),
  pod:delete(node(),"pod_master"),
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
start_stop_container()->
% create Pod, start container - test application running - delete container
% delete Pod
    
    {ok,Pod1}=pod:create(node(),"pod_lib_1"),
    ok=container:create(Pod1,"pod_lib_1",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
    timer:sleep(100),
    ok=rpc:call(Pod1,lib_service,start_tcp_server,["localhost",50001,parallell],2000),
    {pong,Pod1,lib_service}=tcp_client:call({"localhost",50001},{lib_service,ping,[]}),
    [ok]=container:delete(Pod1,"pod_lib_1",["lib_service"]),
    {error,[econnrefused,tcp_client,_]}=tcp_client:call({"localhost",50001},{lib_service,ping,[]}),
    {error,[econnrefused,tcp_client,_]}=tcp_client:call({"localhost",50001},{lib_service,stop_tcp_server,["localhost",50001]}),
    pod:delete(node(),"pod_lib_1"), 
    
   ok.

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
    ok=rpc:call(PodServer,lib_service,start_tcp_server,["localhost",52000,sequence]),
    {error,_}=rpc:call(PodServer,lib_service,start_tcp_server,["localhost",52000,sequence]),
    
    %Check my ip
    {"localhost",52000}=rpc:call(PodServer,lib_service,myip,[],1000),
     D=date(),
    D=rpc:call(node(),tcp_client,call,[{"localhost",52000},{erlang,date,[]}],2000),
    
    % Normal case seq tcp:conne ..
    {ok,Socket1}=tcp_client:connect("localhost",52000),
    {ok,Socket2}=tcp_client:connect("localhost",52000),
    tcp_client:cast(Socket1,{erlang,date,[]}),
    tcp_client:cast(Socket2,{erlang,date,[]}),
    D=tcp_client:get_msg(Socket1,1000),
    {error,[tcp_timeout,_,tcp_client,_]}=tcp_client:get_msg(Socket2,1000),
    
    tcp_client:disconnect(Socket1),
    tcp_client:disconnect(Socket2),

    {ok,stopped}=rpc:call(PodServer,lib_service,stop_tcp_server,["localhost",52000],1000),
    {error,[econnrefused,tcp_client,_]}=tcp_client:connect("localhost",52000),
    {error,[econnrefused,tcp_client,_]}=tcp_client:call({"localhost",52000},{erlang,date,[]}),
    ok.

tcp_par_server_start_stop()->
    PodServer=misc_lib:get_node_by_id("pod_lib_1"),
    ok=rpc:call(PodServer,lib_service,start_tcp_server,["localhost",52001,parallell]),
    {error,_}=rpc:call(PodServer,lib_service,start_tcp_server,["localhost",52001,parallell]),
    
    %Check my ip
    {"localhost",52001}=rpc:call(PodServer,lib_service,myip,[],1000),
     D=date(),
    D=rpc:call(node(),tcp_client,call,[{"localhost",52001},{erlang,date,[]}],2000),
    
    % Normal case seq tcp:conne ..
    {ok,Socket1}=tcp_client:connect("localhost",52001),
    {ok,Socket2}=tcp_client:connect("localhost",52001),
    tcp_client:cast(Socket1,{erlang,date,[]}),
    tcp_client:cast(Socket2,{erlang,date,[]}),
    D=tcp_client:get_msg(Socket1,1000),
    D=tcp_client:get_msg(Socket2,1000),
    
    tcp_client:disconnect(Socket1),
    tcp_client:disconnect(Socket2),

    {ok,stopped}=rpc:call(PodServer,lib_service,stop_tcp_server,["localhost",52001],1000),
    {error,[econnrefused,tcp_client,_]}=tcp_client:connect("localhost",52001),
    {error,[econnrefused,tcp_client,_]}=tcp_client:call({"localhost",52001},{erlang,date,[]}),

   % pod:delete(node(),"pod_lib_1"),
   % pod:delete(node(),"pod_lib_2"),
    ok.

end_tcp_test()->
    container:delete('pod_lib_1@asus.com',"pod_lib_1",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_lib_1"),
    container:delete('pod_lib_2@asus.com',"pod_lib_2",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_lib_2"),
    ok.


%**************************************************************
