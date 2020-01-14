%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(unit_test_tcp_lib_service). 
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------
-define(PORT_PAR,10000).
-define(PORT_SEQ,10001).

-define(SERVER_ID,"test_tcp_server").



%% External exports

-export([]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init_test()->
 %   ok=application:start(lib_service),
  %  {ok,PodTcpServer}=pod:create(node(),?SERVER_ID),
  %  [{ok,"lib_service"}]=container:create(PodTcpServer,?SERVER_ID,["lib_service"]),
    PodTcpServer=misc_lib:get_node_by_id(?SERVER_ID),
    pong=net_adm:ping(PodTcpServer),
    ok.

%*****************************************************************************
tcp_start_lib_service_test()->
    PodTcpServer=misc_lib:get_node_by_id("test_tcp_server"),
    rpc:call(PodTcpServer,application,start,[lib_service]),
    ok.
tcp_server_start_para_test()->
    PodTcpServer=misc_lib:get_node_by_id("test_tcp_server"),
    Port=?PORT_PAR,
    ok=rpc:call(PodTcpServer,lib_service,start_tcp_server,[Port,parallell]),
    ok.

tcp_server_start_para_again_test()->
    PodTcpServer=misc_lib:get_node_by_id("test_tcp_server"),
    Port=?PORT_PAR,
    {error,[already_started,Port,lib_service,_Line]}=rpc:call(PodTcpServer,lib_service,start_tcp_server,[Port,parallell]),
    ok.

tcp_server_start_seq_test()->
    PodTcpServer=misc_lib:get_node_by_id("test_tcp_server"),
    Port=?PORT_SEQ,
    ok=rpc:call(PodTcpServer,lib_service,start_tcp_server,[Port,sequence]),
    ok.

tcp_server_start_seq_again_test()->
    PodTcpServer=misc_lib:get_node_by_id("test_tcp_server"),
    Port=?PORT_SEQ,
    {error,[already_started,Port,lib_service,_Line]}=rpc:call(PodTcpServer,lib_service,start_tcp_server,[Port,sequence]),
    ok.

tcp_client_para_1_test() ->
    D=date(),
    Reply1=tcp_client:call({"localhost",?PORT_PAR},node(),{erlang,date,[]}),
    Reply2=tcp_client:call({"localhost",?PORT_PAR},node(),{erlang,date,[]}),
    D=Reply1,
    D=Reply2,
    ok.

tcp_client_para_2_test() ->
    D=date(),
    R=massive("localhost",?PORT_PAR,node(),erlang,date,[],1000,[]),
    []=[R1||R1<-R,R1/=D],
    ok.

massive(_Addr,_Port,_node,_M,_F,_A,0,Result)->
    Result;
massive(Addr,Port,Node,M,F,A,N,Acc)->
    NewAcc=[tcp_client:call({Addr,Port},Node,{M,F,A})|Acc],
    massive(Addr,Port,Node,M,F,A,N-1,NewAcc).

tcp_client_seq_1_test() ->
    D=date(),
    Reply1=tcp_client:call({"localhost",?PORT_SEQ},node(),{erlang,date,[]}),
    Reply2=tcp_client:call({"localhost",?PORT_SEQ},node(),{erlang,date,[]}),
    D=Reply1,
    D=Reply2,
    ok.

tcp_client_seq_2_test() ->
    D=date(),
    R=massive("localhost",?PORT_SEQ,node(),erlang,date,[],1000,[]),
    []=[R1||R1<-R,R1/=D],
    ok.

tcp_server_stop_para_test()->
    PodTcpServer=misc_lib:get_node_by_id("test_tcp_server"),
    Port=?PORT_PAR,
    {ok,stopped}=rpc:call(PodTcpServer,lib_service,stop_tcp_server,[Port]),
    ok.
  
tcp_server_stop_seq_test()->
    PodTcpServer=misc_lib:get_node_by_id("test_tcp_server"),
    Port=?PORT_SEQ,
    {ok,stopped}=rpc:call(PodTcpServer,lib_service,stop_tcp_server,[Port]),
    ok.


tcp_server_start_seq_2_test()->
    PodTcpServer=misc_lib:get_node_by_id("test_tcp_server"),
    Port=?PORT_SEQ,
    ok=rpc:call(PodTcpServer,lib_service,start_tcp_server,[Port,sequence]),
    ok.

tcp_client_seq_21_test() ->
    D=date(),
    R=massive("localhost",?PORT_SEQ,node(),erlang,date,[],2,[]),
    []=[R1||R1<-R,R1/=D],
    ok.

tcp_server_stop_seq_2_test()->
    PodTcpServer=misc_lib:get_node_by_id("test_tcp_server"),
    Port=?PORT_SEQ,
    {ok,stopped}=rpc:call(PodTcpServer,lib_service,stop_tcp_server,[Port]),
    ok.
%**************************************************************
stop_test()->
  %  rpc:call(PodTcpServer,application,stop,[lib_service]),
   % rpc:call(PodTcpServer,application,unload,[lib_service]),
    PodTcpServer=misc_lib:get_node_by_id(?SERVER_ID),
    container:delete(PodTcpServer,?SERVER_ID,["lib_service"]),
    timer:sleep(500),
    {ok,stopped}=pod:delete(node(),?SERVER_ID),
  
    application:stop(lib_service),
    application:unload(lib_service),
    ok.
