%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(test_support).
  


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------

%% External exports
-export([execute/3
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
execute(TestList,Module2Test,Timeout)->
    TestR=test(TestList,Module2Test,Timeout,[]),    
    Result=case [{error,F,Res}||{Res,F}<-TestR,Res/=ok] of
	       []->
		   ok;
	       ErrorMsg->
		   ErrorMsg
	   end,
    Result.

test([],_Module2Test,_Timeout,Result)->
    Result;
test([F|T],Module2Test,Timeout,Acc) ->
    io:format("~n"),
    io:format("~p",[{time(),Module2Test,F}]),
    R=rpc:call(node(),Module2Test,F,[],Timeout),
    case R of
	ok->
	    io:format(" => OK ~n");
	_->
	    io:format("Error ~p~n",[{time(),Module2Test,F,R}])
    end,
	
    test(T,Module2Test,Timeout,[{R,F}|Acc]).

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
