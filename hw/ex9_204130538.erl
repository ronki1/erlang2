%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. Jun 2017 17:29
%%%-------------------------------------------------------------------
-module(ex9_204130538).
-author("ron").

%% API
-export([etsBot/0]).

etsBot()->
  {ok,Data} = file:read_file("etsCommands.txt"),%read file
  [H|T] = binary:split(Data,[<<"\n">>],[global]),%get sorting
  ets:new(tbl,[str2Term(H),named_table]),%create table
  run(T),%run on lines
  file:write_file("etsRes_204130538.ets",io_lib:fwrite("", []),[]),%create empty file
  write2File(ets:match(tbl,'$1')),%write contents of ets
  ets:delete(tbl)%delete ets for future use
.

run([<<>>])->finished;
run([H|T])->
  [HH|TT] = binary:split(H,[<<" ">>],[global]),%get op
  executeLine(str2Term(HH),TT),%execute line
  run(T)
.
executeLine(_,[])->finished;
executeLine(_,[<<>>]) -> finished;
executeLine(insert,[Kn,Vn|T])->
  Found = ets:lookup(tbl,str2Term(Kn)),
  case Found of
    []->%if not found
      ets:insert(tbl,{str2Term(Kn),str2Term(Vn)})%insert to table
  end,
  executeLine(insert,T)
;
executeLine(update,[Kn,Vn|T])->
  Found = ets:lookup(tbl,str2Term(Kn)),
  case Found of
    []->%if not found
      executeLine(update,T);
    _->ets:insert(tbl,{str2Term(Kn),str2Term(Vn)}),
      executeLine(update,T)%if found->update
  end
;
executeLine(delete,[Kn|T])->
  Found = ets:lookup(tbl,str2Term(Kn)),
  case Found of
    []->%if not found
      executeLine(delete,T);
    _->ets:delete(tbl,str2Term(Kn)),%if fount-> delete
      executeLine(delete,T)
  end
;
executeLine(lookup,[Kn|T])->
  Look=ets:lookup(tbl,str2Term(Kn)),
  print(Look),
  executeLine(lookup,T)
.


print([]) -> ok;
print([{K,V}|T]) ->
  io:format("key: ~p val: ~p~n",[K,V]),%print according to format
  print(T).

write2File([])->finished;
write2File([[{K,V}]|T])->
  file:write_file("etsRes_204130538.ets",io_lib:fwrite("~p ~p~n", [K,V]),[append]),%append text to file
  write2File(T)
.

str2Term(Str) ->%create erlang term from string
  {ok,A,_} = erl_scan:string(erlang:binary_to_list(Str) ++ "."),
  {ok,Term} = erl_parse:parse_term(A),
  Term.