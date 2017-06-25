%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. Jun 2017 16:41
%%%-------------------------------------------------------------------
-module(ex10_204130538).
-author("ron").

%% API
-export([commonFB/0]).

commonFB() ->
  STRLST = readfile('friendships.txt'),%read file
  NamesMap = mapNames(STRLST,#{}),%map names to friends
  Combinations = getFriendCombinations(maps:keys(NamesMap),[]),%get all posible combinations
  FinalList = lists:foldl(
    fun(X, Sum) ->
      {F1,F2} = X,
      Friends = compareFriends(maps:get(F1,NamesMap),maps:get(F2,NamesMap)), %compare mutual friends of couple
      [[F1,F2|Friends]|Sum] %list friends and mutual friends
    end,
    [], Combinations),
  STR = getFinalString(FinalList,[]),%get final string
  file:write_file("commonFB_204130538.fb", io_lib:fwrite("~s", [STR])) %write to file
.

getFinalString([],ACC)->ACC;
getFinalString([H|T],Acc)-> %receive final string and return a printable list
  NewList = lists:foldl(
    fun(X, Sum) ->
          Sum++X++" "
    end,
    [], H),
  getFinalString(T,Acc++lists:sublist(NewList,length(NewList)-1)++[10])%recurse with a new line sign
.

getFriendCombinations([],Res)->Res;
getFriendCombinations([H|T],Res)-> %get all possible combinations of friends
  ANS = lists:foldl(
    fun(X, Sum) ->
      [{H,X}|Sum]
    end,
    [], T),
  getFriendCombinations(T,Res++ANS)
.

mapNames([],M)->M;
mapNames([H|T],M) ->%map the names of friends
  NMS = getNames(H,[]),
  M1 = maps:put(hd(NMS),tl(NMS), M),%put inside map the person and his friends
  mapNames(T,M1)
.

getNames([],ACC)-> ACC;
getNames(List,ACC)->
  {SPH,SPT} = lists:splitwith(fun(A) ->A/=32  end, List),%remove spaces
    case SPT of %check if this is the last friend
       [] ->ACC++[SPH];
      _->  getNames(tl(SPT),ACC++[SPH])
  end
.

compareFriends(F1,F2)->%check whether F1 and F2 have mutual friends
  lists:foldl(
    fun(X, Sum) ->
      case lists:member(X, F2) of
        true->
          [X|Sum];
        _->Sum
      end
    end,
    [], F1)
.


readfile(FileName) ->%read file
  {ok, Binary} = file:read_file(FileName),
  string:tokens(erlang:binary_to_list(Binary), "\n").