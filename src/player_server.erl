-module(player_server).

-behaviour(gen_server).
-export([start/0]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
  terminate/2, code_change/3]).
-compile(export_all).
-define(SERVER, ?MODULE).

-import(mnes,[init_db/0,print_db/0,insert_food/2,remove_food/1,getFoods/0,insert_player/2,getPlayer/1,getPlayersExcept/1]).

start() -> gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
stop()  -> gen_server:call(?MODULE, stop).

init([]) ->
  %init_db(),
  %generatePlayers(5),
  {ok,tab}
.

dummy(X,Y,R)->
  gen_server:call(?MODULE,{playerMoved,1,X,Y,R})
.

handle_call({movePlayer,PlayerPid,Dx,Dy,Dr}, _From, Tab) ->
  Response = notifyPlayer(PlayerPid,{movePlayer,Dx,Dy,Dr}),
  case Response of
    {eatenBy,P}->
      notifyPlayer(P,{movePlayer,0,0,0});
    _-> ok
  end,
  {reply,ok, Tab};

handle_call(stop, _From, Tab) ->
  {stop, normal, stopped, Tab}.
handle_cast(_Msg, State) ->{reply, ok, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

%%generatePlayers(0)->
%%  ok;
%%generatePlayers(Num)->
%%  X=random:uniform(100),
%%  Y=random:uniform(100),
%%  {ok,PID} = player:start({X,Y,10,0}),
%%  insert_player({PID,X,Y,10,0,id}),
%%  generatePlayers(Num-1)
%%.

notifyPlayer(PID,Message) ->
  gen_server:call(PID,Message)
.