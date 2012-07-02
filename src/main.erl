-module(main).

-export([s/1]).

s(Port)-> 
	spawn(
		fun () -> 
			{ok, Socket} = gen_tcp:listen(Port, [list,{active, false},{packet, http}]),  
			accept_loop(Socket) 
		end).
				
   	
accept_loop(Socket) ->
	{ok, CSocket} = gen_tcp:accept(Socket),
	Pid = spawn(fun() -> client_socket() end), % using fun to avoid function expoting
	ok = gen_tcp:controlling_process(CSocket, Pid),
	Pid ! {take_socket, CSocket},
	accept_loop(Socket).

client_socket() ->
	Socket = receive {take_socket, S} -> S end,
	ok = inet:setopts(Socket, [{active, true}]),
	client_loop(Socket, [], []).
	
client_loop(Socket, MovesX, MovesY) ->
	receive
	   	{http, Socket, {http_request, 'GET', {abs_path, Path}, _Vers}} ->
			case http_uri2:parse_path_query(Path) of
				{"/", []} -> %index page
					{ok, Data} = file:read_file("../html/index.html"),
					ok = gen_tcp:send(Socket, internal:response(200, Data)),
					client_loop(Socket, MovesX, MovesY);
					
				{"/newgame", []} -> 
					gen_tcp:send(Socket, internal:response(200, [ simple_json_encode([{ok,1}]) ])),
					client_loop(Socket, [], []);
				
				{"/play",[{"x",Xin}, {"y",Yin}, {"aggress", Ain}]} ->
					X = list_to_integer(Xin), Y = list_to_integer(Yin), 
					A = case string:to_float(Ain) of {F, []} -> F; {error, no_float} -> list_to_integer(Ain) end,
					Aggress = case  A < 0.1 orelse A > 3.6 of true -> 0.8; false -> A end, % проверка на корректность
					io:format("Aggress ~p~n", [Aggress]),
					TmpX = MovesX ++ [{X, Y}],
					{_,{X2,Y2}} = computer_logic:get_bot_move(TmpX, MovesY, Aggress),
					TmpY = MovesY ++ [{X2,Y2}],
					Res = case check_winner:cw(TmpX, TmpY, {X,Y}, {X2, Y2}, []) of
						bot_win -> [{loose,1},{x,X2},{y,Y2}];
						player_win -> [{win,1}];
						draw -> [{draw,1}];
						next -> [{x,X2}, {y,Y2}]
					end,
					ok = gen_tcp:send(Socket, internal:response(200, simple_json_encode(Res))),
					client_loop(Socket, TmpX, TmpY);
				X -> 
				io:format("Unhandled HTTP request ~p~n", [X]),
				client_loop(Socket, MovesX, MovesY)
			end;
		
		{tcp_closed, Socket} ->	
			io:format("tcp_closed received~n", []),
			gen_tcp:close(Socket);

		{tcp_error, Socket, _} ->
			io:format("tcp_error ocqured~n", []),
			gen_tcp:close(Socket);
		
		_Y ->
			%io:format("Unhandled TCP message ~p~n", [_Y]),
			client_loop(Socket, MovesX, MovesY)
	end.

simple_json_encode(List) ->
	lists:concat(["{", simple_json_encode_el(List), "}"]).

simple_json_encode_el([]) -> [];
simple_json_encode_el([Pair]) ->
	simple_json_pack_pair(Pair);
simple_json_encode_el([Pair|Tail]) ->
	[simple_json_pack_pair(Pair), ",", simple_json_encode_el(Tail)].

simple_json_pack_pair({Name, Val}) ->
	["\"", atom_to_list(Name), "\":", integer_to_list(Val)].


