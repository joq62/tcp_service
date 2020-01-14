%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(unit_test_ssl_lib_service). 
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------
-define(PORT_PAR,10000).
-define(PORT_SEQ,10001).

-define(CERT_FILE,"src/certs/cert.pem").
-define(KEY_FILE,"src/certs/key.pem").

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
    ok=application:start(lib_service),
    ok.

%*****************************************************************************
ssl_server_init_test()->
    PodSslServer=misc_lib:get_node_by_id("test_ssl_server"),
    Port=?PORT_PAR,
%    CertFile=filename:join(["pod_ssl_server","lib_service",?CERT_FILE]),
%    KeyFile=filename:join(["pod_ssl_server","lib_service",?KEY_FILE]),
    Type=parallell,
    {ok,Pid}=rpc:call(PodSslServer,ssl_lib,start,[Port,?CERT_FILE,?KEY_FILE,Type]),
%    Pid!terminate,
    ok.

ssl_client_1_test() ->
    {ok,Socket}=ssl_lib:connect("localhost",Port=?PORT_PAR),
    glurk=ssl_lib:call(Socket,erlang,date,[]),
    ok.
    

ssl_server_delete_test_XX()->
    Pod=misc_lib:get_node_by_id("test_ssl_server"),
    pong=net_adm:ping(Pod),
    
    ok.
  
%**************************************************************
stop_test()->
    application:stop(lib_service),
    application:unload(lib_service),
    init:stop(),
    ok.
