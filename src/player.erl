-module(player).

-behaviour(gen_server).
-export([start/1]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
  terminate/2, code_change/3]).
-compile(export_all).
-define(SERVER, ?MODULE).

-import(mnes,[init_db/0,print_db/0,insert_food/2,remove_food/1,getFoods/0,grow_player_db/1,move_player_db/1,getPlayers/0]).

-define(game_x,(1024)).
-define(game_y,(768)).

start(Args) -> gen_server:start_link(?MODULE, Args, []).
stop()  -> gen_server:call(?MODULE, stop).

init(Args) ->
  {X,Y,R,ID,Name,Panel} = Args,
  {ok,{X,Y,R,ID,Name,Panel}}
.

dummy(Dx,Dy,Dr)->
  gen_server:call(?MODULE,{movePlayer,Dx,Dy,Dr})
.

handle_call({movePlayer,BigDx,BigDy,Dr}, _From, Tab) ->
  {X,Y,R,ID,Name,Panel} = Tab,
  Dx = round(BigDx/50/(R/100)),
  Dy = round(BigDy/50/(R/100)),
  CantMove = (X+Dx > ?game_x orelse X+Dx < 0 orelse Y+Dy > ?game_y orelse Y+Dy < 0),
  case CantMove of
    true->
      {reply, playerMoved, {X,Y,R,ID,Name,Panel}};
    _->
      FoodsEaten = gen_server:call(food_server,{playerMoved,X+Dx,Y+Dy,R+Dr}),
      PlayersEaten = getPlayersEaten(X+Dx,Y+Dy,R+Dr),
      PlayersEatenBy = getPlayersEatenBy(X+Dx,Y+Dy,R+Dr),
      move_player_db({self(),Dx,Dy,Panel}),
      gen_server:call(gfx,{movePlayer,X,Y,R,X+Dx,Y+Dy,R+Dr}),
      case PlayersEatenBy of
        []-> %not eaten
          case PlayersEaten of
            []-> case FoodsEaten of
                   []->{reply, playerMoved, {X+Dx,Y+Dy,R+Dr,ID,Name,Panel}};
                   A->NewDelta = growPlayer(A,0),{reply, playerMoved, {X+Dx,Y+Dy,R+NewDelta,ID,Name,Panel}}
                 end;
            A->
              Sum = eatPlayers(A,0),
              gen_server:call(gfx,playersChanged),
              {reply, playerMoved, {X+Dx,Y+Dy,R+Sum,ID,Name,Panel}}%in case has eaten player
          end;
        [{P,_,_,_}]->%eaten
          {reply, {eatenBy,P}, {X+Dx,Y+Dy,R,ID,Name,Panel}}
      end
  end
;

handle_call({playerMoved,PlayerX,PlayerY,PlayerRadius}, _From, Tab) ->
  {X,Y,R,ID,Name,Panel} = Tab,
  Distance = math:sqrt(math:pow(PlayerX-X,2)+math:pow(PlayerY-Y,2)),
  Reply = Distance=<abs(PlayerRadius-R),%true if dot has been eaten, false if dot hasn't been eaten
  case Reply of
    false->{reply, Reply, Tab};
    _->{reply, Reply, Tab}
  end
;

handle_call(youAteSomeone, _From, Tab) ->
  gen_server:call(self(),{movePlayer,0,0,0})
;

handle_call(eaten, _From, Tab) ->
  mnes:remove_player(self()),
  {reply, stopped, Tab}
;

handle_call(stop, _From, Tab) ->
  {stop, normal, stopped, Tab}.
handle_cast(_Msg, State) ->{reply, ok, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

growPlayer([],Sum)->
  grow_player_db({self(),Sum}),
  Sum;
growPlayer([H|T],Sum)->
  {_X,_Y,R}=H,
  growPlayer(T,Sum+R)
.

eatPlayers([],Sum)->
  grow_player_db({self(),Sum}),
  Sum;
eatPlayers([H|T],Sum)->
  {P,X,Y,R}=H,
  gen_server:call(P,eaten),
  gen_server:call(P,stop),
  growPlayer(T,Sum+R)
.

eatenByPlayers([H|_T])->
  {P,_X,_Y,_R}=H,
  gen_server:call(P,youAteSomeone)
.

getPlayersEaten(MyX,MyY,MyR)->
  [{P,X,Y,R} || {player,P,X,Y,R,_ID,_Name,_Panel} <- getPlayers(), (P /= self() andalso math:sqrt(math:pow(X-MyX,2)+math:pow(Y-MyY,2))=<abs(MyR-R) andalso MyR>R)]
.

getPlayersEatenBy(MyX,MyY,MyR)->
  [{P,X,Y,R} || {player,P,X,Y,R,_ID,_Name,_Panel} <- getPlayers(), (P /= self() andalso math:sqrt(math:pow(X-MyX,2)+math:pow(Y-MyY,2))=<abs(MyR-R) andalso MyR<R)]
.