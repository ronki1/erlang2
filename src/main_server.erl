%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. Jun 2017 14:59
%%%-------------------------------------------------------------------
-module(main_server).
-author("ronatan").

-behaviour(gen_server).
-export([start/0]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
  terminate/2, code_change/3]).
-compile(export_all).
-define(SERVER, ?MODULE).

-define(game_x,(1024)).
-define(game_y,(768)).

-import(mnes,[init_db/0,print_db/0,insert_food/2,remove_food/1,getFoods/0,insert_player/1,getPlayerById/1]).

start() -> gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
stop()  -> gen_server:call(?MODULE, stop).

init([]) ->
  init_db(),
  switch:start(),
  Graphics  = gfx:start(),
  FoodServer = food_server:start(25),
  PlayerServer = player_server:start(),
  {ok,{FoodServer,PlayerServer}}
.

dummy(X,Y,R)->
  gen_server:call(?MODULE,{playerMoved,1,X,Y,R})
.

handle_call({movePlayer,PlayerID,Dx,Dy}, _From, Tab) ->
  A=getPlayerById(PlayerID),
  case A of
    []->{reply, dead, Tab};
    [{P,_X,_Y,_R,_ID,_Name,Panel}] ->
      gen_server:call(player_server,{movePlayer,P,Dx,-Dy,0}),
      {reply, ok, Tab}
  end;

handle_call({register,PlayerID,Name}, _From, Tab) ->
  io:format("RegisterReceived: ~p ID: ~p  ~n",[Name,PlayerID]),
  X=random:uniform(?game_x),
  Y=random:uniform(?game_y),
  Panel = gen_server:call(gfx,{addShape,X,Y,10}),
  {ok,PID} = player:start({X,Y,10,PlayerID,Name,Panel}),
  insert_player({PID,X,Y,10,PlayerID,Name,Panel}),
  gen_server:call(gfx,playersChanged),
  {reply,ok, Tab};

handle_call(stop, _From, Tab) ->
  {stop, normal, stopped, Tab}.
handle_cast(_Msg, State) ->{reply, ok, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

generateFoods(0)->
  ok;
generateFoods(Num)->
  X=random:uniform(100),
  Y=random:uniform(100),
  {ok,PID} = food:start({X,Y,2}),
  insert_food(PID,{X,Y,2}),
  generateFoods(Num-1)
.