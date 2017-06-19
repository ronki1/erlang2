-module(food_server).

-behaviour(gen_server).
-export([start/1]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
  terminate/2, code_change/3]).
-compile(export_all).
-define(SERVER, ?MODULE).

-import(mnes,[init_db/0,print_db/0,insert_food/2,remove_food/1,getFoods/0]).

-define(game_x,(1024)).
-define(game_y,(768)).

start(Args) -> gen_server:start_link({local, ?SERVER}, ?MODULE, Args, []).
stop()  -> gen_server:call(?MODULE, stop).

init(Args) ->
  %init_db(),
  generateFoods(Args),
  {ok,tab}
.

dummy(X,Y,R)->
  gen_server:call(?MODULE,{playerMoved,1,X,Y,R})
.

handle_call({playerMoved,PlayerX,PlayerY,PlayerRadius}, _From, Tab) ->
  DeletedPIDs = notifyFoods(getFoods(),{playerMoved,PlayerX,PlayerY,PlayerRadius},[]),
  generateFoods(length(DeletedPIDs)),%generate a quantity of new foods, which is similar to the foods player has eaten
  {reply, DeletedPIDs, Tab};

handle_call(stop, _From, Tab) ->
  {stop, normal, stopped, Tab}.
handle_cast(_Msg, State) ->{reply, ok, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

generateFoods(0)->
  ok;
generateFoods(Num)->
  X=random:uniform(?game_x),
  Y=random:uniform(?game_y),
  Panel = gen_server:call(gfx,{addShape,X,Y,2}),
  {ok,PID} = food:start({X,Y,2,Panel}),
  insert_food(PID,{X,Y,2,Panel}),
  generateFoods(Num-1)
.

notifyFoods([],_Message,DeletedPIDs)->
  DeletedPIDs
;
notifyFoods([H|T],Message,DeletedPIDs) ->
  {food,PID,X,Y,R,Panel} = H,
  Reply = gen_server:call(PID,Message),
  case Reply of
    true->%if eaten
      remove_food(PID),
      gen_server:call(PID,stop),
      notifyFoods(T,Message,[{X,Y,R}|DeletedPIDs])
    ;
    _ ->  notifyFoods(T,Message,DeletedPIDs)
  end
.