-module(switch).

-export([start/0]).


start() ->
  spawn(fun start1/0).

start1() ->
  {ok,Socket} = gen_udp:open(7777,[binary, {active,true}]),
  loop_udp(Socket).


loop_udp(Socket) ->
  receive
    {udp,_,IP,Port,<<0:8,X:32/signed-integer,Y:32/signed-integer>>} -> % x,y
      %io:format("move ~p:~p ~p,~p~n",[IP,Port,X,Y]),
      A=gen_server:call(main_server,{movePlayer,{IP,Port},X,Y}),
      case A of
        ok -> ok;
        dead -> gen_udp:send(Socket,IP,Port,<<101:8>>)
      end,
      loop_udp(Socket);
    {udp,_,IP,Port,<<1:8,N/binary>>} -> % register
      Name = binary_to_list(N),
      io:format("register ~p:~p ~p~n",[IP,Port,Name]),
      A=gen_server:call(main_server,{register,{IP,Port},Name}),
      case A of
        ok -> gen_udp:send(Socket,IP,Port,<<1:8>>);
        _ -> gen_udp:send(Socket,IP,Port,<<0:8>>)
      end,
      loop_udp(Socket)
  end.