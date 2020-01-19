%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(local_tcp_service_test).  
  
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
% -include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------
-define(TCP_SERVER,'test_tcp_server@asus').
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
    pong=net_adm:ping(?TCP_SERVER),
    ok=rpc:call(?TCP_SERVER,application,start,[tcp_service]),
    ok=rpc:call(node(),application,start,[tcp_service]),
    ok.
    
%**************************** tcp test   ****************************

tcp_seq_server_start_stop()->
    ok=rpc:call(?TCP_SERVER,tcp_service,start_tcp_server,["localhost",52000,sequence]),
    {error,_}=rpc:call(?TCP_SERVER,tcp_service,start_tcp_server,["localhost",52000,sequence]),
    D=date(),
    D=rpc:call(node(),tcp_client,call,[{"localhost",52000},{erlang,date,[]}],2000),
    
    % Normal case seq tcp:conne ..
    {ok,Socket1}=tcp_service:connect("localhost",52000),
    {ok,Socket2}=tcp_service:connect("localhost",52000),
    tcp_service:cast(Socket1,{erlang,date,[]}),
    tcp_service:cast(Socket2,{erlang,date,[]}),
    D=tcp_service:get_msg(Socket1,1000),
    {error,[tcp_timeout,_,tcp_client,_]}=tcp_service:get_msg(Socket2,1000),
    
    tcp_service:disconnect(Socket1),
    tcp_service:disconnect(Socket2),

    ok=rpc:call(?TCP_SERVER,tcp_service,stop_tcp_server,["localhost",52000],1000),
    {error,[econnrefused,tcp_client,_]}=tcp_service:connect("localhost",52000),
    {error,[econnrefused,tcp_client,_]}=tcp_service:call({"localhost",52000},{erlang,date,[]}),
    ok.

tcp_par_server_start_stop()->
    ok=rpc:call(?TCP_SERVER,tcp_service,start_tcp_server,["localhost",52001,parallell]),
    {error,_}=rpc:call(?TCP_SERVER,tcp_service,start_tcp_server,["localhost",52001,parallell]),
    
    D=date(),
    D=rpc:call(node(),tcp_service,call,[{"localhost",52001},{erlang,date,[]}],2000),
    
    % Normal case seq tcp:conne ..
    {ok,Socket1}=tcp_service:connect("localhost",52001),
    {ok,Socket2}=tcp_service:connect("localhost",52001),
    tcp_service:cast(Socket1,{erlang,date,[]}),
    tcp_service:cast(Socket2,{erlang,date,[]}),
    D=tcp_service:get_msg(Socket1,1000),
    D=tcp_service:get_msg(Socket2,1000),
    
    tcp_service:disconnect(Socket1),
    tcp_service:disconnect(Socket2),

    {ok,stopped}=rpc:call(?TCP_SERVER,tcp_service,stop_tcp_server,["localhost",52001],1000),
    {error,[econnrefused,tcp_service,_]}=tcp_service:connect("localhost",52001),
    {error,[econnrefused,tcp_service,_]}=tcp_service:call({"localhost",52001},{erlang,date,[]}),
    ok.

end_tcp_test()->
    ok=rpc:call(?TCP_SERVER,application,stop,[tcp_service]),
    ok=rpc:call(node(),application,stop,[tcp_service]),
    init:stop(),
    ok.


%**************************************************************
