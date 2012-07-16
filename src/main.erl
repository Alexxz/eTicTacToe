-module(main).

-export([s/1]).

s(Port)-> 
	spawn(
		fun () -> 
			{ok, Socket} = get_listen_socket(Port, 60),  
			accept_loop(Socket) 
		end).
				
get_listen_socket(_,0)->
	{error,eaddrinuse};

get_listen_socket(Port, N) ->
	case gen_tcp:listen(Port, [list,{active, false},{packet, http}]) of
		{ok, Socket} -> io:format("Got socket ~p~n",[Socket]), {ok, Socket};
		{error,eaddrinuse} -> io:format("Waiting for 1 s (~p)~n",[N]), timer:sleep(1000), get_listen_socket(Port, N-1);
		X -> X
	end.

accept_loop(Socket) ->
	{ok, CSocket} = gen_tcp:accept(Socket),
	Pid = spawn(fun() -> client_socket(CSocket) end), % using fun to avoid function exporting
	ok = gen_tcp:controlling_process(CSocket, Pid),
	accept_loop(Socket).

client_socket(Socket) ->
	ok = inet:setopts(Socket, [{active, true}]),
	client_loop(Socket, [], []).
	
client_loop(Socket, MovesX, MovesY) ->
	receive
	   	{http, Socket, {http_request, 'GET', {abs_path, Path}, _Vers}} ->
			case http_uri2:parse_path_query(Path) of
				{"/", []} -> %index page
					ok = gen_tcp:send(Socket, internal:response(redirect, "/game")),
					log("Resetting game state: ~p", [{MovesX, MovesY}]),
					client_loop(Socket, [], []); % start a new game on refresh

				{"/game", []} -> %index page
					{ok, Data} = file:read_file("../html/index.html"),
					ok = gen_tcp:send(Socket, internal:response(200, Data)),
					log("Resetting game state: ~p", [{MovesX, MovesY}]),
					client_loop(Socket, [], []); % start a new game on refresh
					
				{"/jquery.js", []} ->
					{ok, Data} = file:read_file("../html/jquery.js"),
					ok = gen_tcp:send(Socket, internal:response(js, Data)),
					client_loop(Socket, MovesX, MovesY); % start a new game on refresh
					
				{"/newgame", []} -> 
					gen_tcp:send(Socket, internal:response(200, [ simple_json_encode([{ok,1}]) ])),
					log("Resetting game state: ~p", [{MovesX, MovesY}]),
					client_loop(Socket, [], []);
				
				{"/play",[{"x",Xin}, {"y",Yin}, {"aggress", Ain}]} ->
					X = list_to_integer(Xin), Y = list_to_integer(Yin),
					A = case string:to_float(Ain) of {F, []} -> F; {error, no_float} -> list_to_integer(Ain) end,
					Aggress = case  A < 0.1 orelse A > 3.6 of true -> 0.8; false -> A end, % проверка на корректность
					log("Player: ~p aggr ~p", [{X,Y}, Aggress]),

					Res = case internal:exist_in_list(lists:concat([MovesX, MovesY]), {X, Y}) of
					true  ->
						TmpX = MovesX,
						TmpY = MovesY,
						log("Result: wrong move", []),
						[{wrong, 1}];
					false ->
						TmpX = MovesX ++ [{X, Y}],
						{_,{X2,Y2}} = computer_logic:get_bot_move(TmpX, MovesY, Aggress),
						TmpY = MovesY ++ [{X2,Y2}],
						log("Bot: ~p", [{X2,Y2}]),
						Response = case check_winner:cw(TmpX, TmpY, {X,Y}, {X2, Y2}, []) of
							bot_win -> [{lose,1},{x,X2},{y,Y2}];
							player_win -> [{win,1}];
							draw -> [{draw,1}, {x,X2}, {y,Y2}];
							next -> [{x,X2}, {y,Y2}]
						end,
						log("Response: ~p", [Response]),
						Response
					end,
					D = simple_json_encode(Res),
					ok = gen_tcp:send(Socket, internal:response(200, D)),
					%io:format("Data ~p~n", [D]),
					client_loop(Socket, TmpX, TmpY);
				X -> 
				io:format("Unhandled HTTP request ~p~n", [X]),
 				ok = gen_tcp:send(Socket, internal:response(200, "Unknown request")),
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



log(Message)->
	log(Message, []).

log(Message, Args) ->
	{ok, File} = file:open("log", [write, append]),
	ok = io:format(File, "~p: " ++ Message ++ "~n", [calendar:now_to_datetime(now())| Args]),
	ok = file:close(File).

