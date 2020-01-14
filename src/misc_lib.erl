%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(misc_lib).
  


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------

%% External exports
-export([get_node_by_id/1,get_vm_id/0,get_vm_id/1,
	 app_start/1
	]).
	 
%-compile(export_all).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
get_node_by_id(Id)->
    {ok,Host}=inet:gethostname(),
    list_to_atom(Id++"@"++Host).

get_vm_id()->
    get_vm_id(node()).
get_vm_id(Node)->
    % "NodeId@Host
    [NodeId,Host]=string:split(atom_to_list(Node),"@"), 
    {NodeId,Host}.
    
    
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
app_start(Module)->
    Result=case rpc:call(node(),lib_service,dns_address,[],5000) of
	      {error,Err}->
		   {error,[eexists,dns_address,Err,?MODULE,?LINE]};
	      {DnsIpAddr,DnsPort}->
		   {MyIpAddr,MyPort}=lib_service:myip(),
		   {ok,Socket}=tcp_client:connect(DnsIpAddr,DnsPort),
		   ok=rpc:call(node(),tcp_client,cast,[Socket,{dns_service,add,[atom_to_list(Module),MyIpAddr,MyPort,node()]}]),
		   {ok,[{MyIpAddr,MyPort},{DnsIpAddr,DnsPort},Socket]};
	       Err ->
		   {error,[unmatched,Err,?MODULE,?LINE]}
	  end,   
    Result.
    
