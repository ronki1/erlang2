-module(s).
-export([start_udp/1]).

start_udp(Port) ->
	gen_udp:open(Port,[binary,{active,true}]),
	loop_udp().

loop_udp() ->
	receive
	{_,_,_,_,<<R:32/signed-integer,A:32/signed-integer>>} ->
		io:format("received: ~p,~p~n", [R,A]),
		A2 = list_to_pid("<0.47.0>"),
		A2!{5,5},
		loop_udp();
	M ->
		io:format("received: ~p~n", [M]),
		loop_udp()
	end.
