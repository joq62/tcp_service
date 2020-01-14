%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(pod). 
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Data Type
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------

-define(START_POD_INTERVAL,50).
-define(START_POD_TRIES,50).
-define(STOP_POD_INTERVAL,50).
-define(STOP_POD_TRIES,50).
%% External exports

-export([create/2,delete/2]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
create(Machine,MachineId)->
    create_pod(Machine,MachineId).
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
create_pod(Machine,PodId)->
    Result= case create_pod_dir(Machine,PodId) of
		{ok,PodStr}->
		    case start_pod(Machine,PodId,PodStr) of
			{ok,Pod}->
			    {ok,Pod};
			 %   Service="pod_controller",  %glurk 
			 %   case create_container(Pod,PodId,"pod_controller") of
			%	{ok,Service}->
			%	    {ok,Pod};
			%	{error,Err}->
			%	    {error,Err}
			 %   end;
			{error,Err}->
			    {error,Err}
		    end;
		{error,Err}->
		    {error,Err}
	    end,
    Result.

start_pod(Machine,PodId,PodStr)->
  %  ErlCmd="erl -pa "++"* "++"-sname "++PodStr++" -detached",
%    ErlCmd="erl -pa "++PodId++"/*/* "++"-sname "++PodStr++" -detached",

    ErlCmd="erl "++"-sname "++PodStr++" -detached",
    Result= case rpc:call(Machine,os,cmd,[ErlCmd],5000) of
		[]->
		    case check_if_vm_started(list_to_atom(PodStr),?START_POD_INTERVAL,?START_POD_TRIES,error) of
			error->
			    {error,[couldnt_start_pod,PodId,?MODULE,?LINE]};
			ok->
			    {ok,list_to_atom(PodStr)}
		    end;
	        {badrpc,Err}->
		    {error,[badrpc,Err,?MODULE,?LINE]};
		Err ->
		    {error,[unknown_error,Err,?MODULE,?LINE]}
	    end,
    Result.			
create_pod_dir(Machine,PodId)->
    % Pod='PodId@Host'
    Result=case rpc:call(Machine,inet,gethostname,[],5000) of
	       {ok,Host}->
		   PodStr=PodId++"@"++Host,
		   %Pod=list_to_atom(PodStr),
		   case rpc:call(Machine,filelib,is_dir,[PodId],5000) of
		       true->
			   rpc:call(Machine,os,cmd,["rm -rf "++PodId],5000),
			   {error,[pod_already_loaded,PodId,?MODULE,?LINE]};
		       false-> 
			   case rpc:call(Machine,file,make_dir,[PodId],5000) of
			       ok->
				   {ok,PodStr};
			       {badrpc,Err}->
				   {error,[badrpc,Err,Machine,PodId,?MODULE,?LINE]};
			       Err ->
				   {error,[unknown_error,Err,Machine,PodId,?MODULE,?LINE]}
			   end;
		       {badrpc,Err}->
			   {error,[badrpc,Err,Machine,PodId,?MODULE,?LINE]};
		       Err ->
			   {error,[unknown_error,Err,Machine,PodId,?MODULE,?LINE]}
		   end;
	       {badrpc,Err}->
		   {error,[badrpc,Err,Machine,PodId,?MODULE,?LINE]};
	       Err ->
		   {error,[unknown_error,Err,Machine,PodId,?MODULE,?LINE]}
	   end,
    Result.

check_if_vm_started(_Vm,_Interval,0,ok)->
    ok;
check_if_vm_started(_Vm,_Interval,0,error)->
    error;
check_if_vm_started(_Vm,_Interval,_N,ok) ->
    ok;
check_if_vm_started(Vm,Interval,N,error) ->
    timer:sleep(Interval),
    case net_adm:ping(Vm) of
	pang->
	    NewResult=error;
	pong ->
	    NewResult=ok
    end,
    check_if_vm_started(Vm,Interval,N-1,NewResult).

%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
delete(Machine,MachineId)->
    delete_pod(Machine,MachineId).

%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
delete_pod(Machine,PodId)->
    % Pod='PodId@Host'
    Result=case rpc:call(Machine,inet,gethostname,[],5000) of
	       {ok,Host}->
		   PodStr=PodId++"@"++Host,
		   Pod=list_to_atom(PodStr),
		   rpc:call(Pod,init,stop,[],5000),
		    case check_if_vm_stopped(Pod,?STOP_POD_INTERVAL,?STOP_POD_TRIES,error) of
			error->
			    {error,[couldnt_stop_pod,PodId,?MODULE,?LINE]};
			ok->
			    RmCmd="rm -rf "++PodId,
			    case rpc:call(Machine,os,cmd,[RmCmd],5000) of
				[]->
				    {ok,stopped};
				Err ->
				    {error,[unknown_error,Err,?MODULE,?LINE]}
			    end
		    end;
	       {badrpc,Err}->
		   {error,[badrpc,Err,?MODULE,?LINE]};
	       Err ->
		   {error,[unknown_error,Err,?MODULE,?LINE]}
	   end,
    Result.
		       


check_if_vm_stopped(_Vm,_Interval,0,ok)->
    ok;
check_if_vm_stopped(_Vm,_Interval,0,error)->
    error;
check_if_vm_stopped(_Vm,_Interval,_N,ok) ->
    ok;
check_if_vm_stopped(Vm,Interval,N,error) ->
    timer:sleep(Interval),
    case net_adm:ping(Vm) of
	pong->
	    NewResult=error;
	pang->
	    NewResult=ok
    end,
    check_if_vm_stopped(Vm,Interval,N-1,NewResult).
