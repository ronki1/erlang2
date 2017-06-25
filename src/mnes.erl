%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. Jun 2017 16:37
%%%-------------------------------------------------------------------
-module(mnes).
-author("ron").

-include("foodDB.hrl").

%% API
-export([init_db/0,print_db/0,insert_food/2,changePID/3,remove_food/1,getFoods/0,insert_player/1,getPlayer/1,getPlayers/0,getPlayerById/1,grow_player_db/1,move_player_db/1,getPlayersExcept/1,remove_player/1]).

init_db() ->
  mnesia:delete_table(food),
  mnesia:delete_table(player),
  mnesia:delete_schema([node()]),
  mnesia:create_schema([node()]),
  mnesia:start(),
  mnesia:create_table(food,
    [{attributes, record_info(fields, food)}]),
  mnesia:create_table(player,
    [{attributes, record_info(fields, player)}])
.

print_db() ->
  CatchAll = [{'_',[],['$_']}],
  mnesia:dirty_select(food, CatchAll)
.

getFoods()->
  CatchAll = [{'_',[],['$_']}],
  mnesia:dirty_select(food, CatchAll)
.

getPlayers()->
  CatchAll = [{'_',[],['$_']}],
  mnesia:dirty_select(player, CatchAll)
.

getPlayersExcept(PID) ->
  [{P,X,Y,R,ID,Name,Panel} || {player,P,X,Y,R,ID,Name,Panel} <- getPlayers(), P /= PID]
.

getPlayer(PID) ->
  [{P,X,Y,R,ID,Name,Panel} || {player,P,X,Y,R,ID,Name,Panel} <- getPlayers(), P =:= PID]
.
getPlayerById(SearchId) ->
  [{P,X,Y,R,ID,Name,Panel} || {player,P,X,Y,R,ID,Name,Panel} <- getPlayers(), ID =:= SearchId]
.


insert_food(PID, {X,Y,R,Panel}) ->
  Fun = fun() ->
    FoodInfo = #food{pid = PID, x = X,y=Y,radius = R, panel=Panel},
    mnesia:write(FoodInfo)
  end,
  mnesia:transaction(Fun)
.

insert_player({PID,X,Y,R,ID,Name,Panel}) ->
  Fun = fun() ->
    PlayerInfo = #player{pid = PID, x = X,y=Y,radius = R,id=ID,name=Name,panel = Panel},
    mnesia:write(PlayerInfo)
  end,
  mnesia:transaction(Fun)
.

move_player_db({PID,Dx,Dy,Panel}) ->
  F = fun() ->
    [E] = mnesia:read(player,PID , write),
    X = E#player.x + Dx,
    Y = E#player.y + Dy,
    New = E#player{x = X,y=Y,panel=Panel},
    mnesia:write(New)
      end,
  mnesia:transaction(F).

changePID(Table,OldPID,NewPID)->
  F = fun() ->
    [E] = mnesia:read(Table,OldPID , write),
    case Table of
      player->New = E#player{pid=NewPID};
      _->New = E#food{pid=NewPID}
    end,
    mnesia:write(New)
      end,
  mnesia:transaction(F),
  case Table of
    player->remove_player(OldPID);
    _-> remove_food(OldPID)
  end
.

grow_player_db({PID,Dr}) ->
  F = fun() ->
  [E] = mnesia:read(player,PID , write),
  Radius = E#player.radius + Dr,
  New = E#player{radius = Radius},
  mnesia:write(New)
  end,
mnesia:transaction(F).

remove_food(PID)->
  Fun = fun()->
    mnesia:delete({food, PID})
  end,
  mnesia:transaction(Fun)
.

remove_player(PID)->
  Fun = fun()->
    mnesia:delete({player, PID})
        end,
  mnesia:transaction(Fun)
.