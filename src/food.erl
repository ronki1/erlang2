-module(food).

-behaviour(gen_server).
-export([start/1]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
  terminate/2, code_change/3,dummy/3]).
-compile(export_all).
-define(SERVER, ?MODULE).

start(Args) -> gen_server:start_link(?MODULE, Args, []).
stop()  -> gen_server:call(?MODULE, stop).

init([]) ->
  {ok, {0,0,1}};
init({X,Y,R,Panel}) ->
  {ok, {X,Y,R,Panel}}
.

dummy(X,Y,R)->
  gen_server:call(?MODULE,{playerMoved,1,X,Y,R})
.

handle_call({playerMoved,PlayerX,PlayerY,PlayerRadius}, _From, Tab) ->
  {X,Y,Radius,Panel} = Tab,
  Distance = math:sqrt(math:pow(PlayerX-X,2)+math:pow(PlayerY-Y,2)),
  Reply = Distance=<abs(PlayerRadius-Radius),%true if dot has been eaten, false if dot hasn't been eaten
  case Reply of
    false->{reply, Reply, Tab};
    _->gen_server:call(gfx,{deleteFood,X,Y,Radius}),{reply, Reply, Tab}
  end
  ;

handle_call(stop, _From, Tab) ->
  {stop, normal, stopped, Tab}.
handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

    