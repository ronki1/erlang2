%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. Jun 2017 15:42
%%%-------------------------------------------------------------------
-module(monitor_server).
-author("ron").

%% API
-export([start/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
  terminate/2, code_change/3]).
-define(SERVER, ?MODULE).

start() -> gen_server:start({local, ?SERVER}, ?MODULE, [], []).
stop()  -> gen_server:call(?MODULE, stop).

init([]) ->
  {ok,main}
.

handle_call(mainDied, _From, Tab) ->
  %apply_after(500, main_server, start, [backup]),
  {reply, op, Tab}
;

handle_call(stop, _From, Tab) ->
  {stop, normal, stopped, Tab}.
handle_cast(mainDied, State) ->timer:sleep(500),main_server:start(backup),{noreply,backup};
handle_cast(_Msg, State) ->{reply, ok, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.