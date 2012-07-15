-module(test_check_winner).

-export([test/0]).

test()->
	[test(I) || I <- lists:seq(1,100)].

test(1) ->
	player_win = check_winner:cw([{0,0},{1,0},{2,0},{3,0},{4,0}], [], {0,0}, {0,0}, []),
	player_win = check_winner:cw([{0,0},{1,0},{2,0},{3,0},{4,0}], [], {1,0}, {0,0}, []),
	player_win = check_winner:cw([{0,0},{1,0},{2,0},{3,0},{4,0}], [], {2,0}, {0,0}, []),
	player_win = check_winner:cw([{0,0},{1,0},{2,0},{3,0},{4,0}], [], {3,0}, {0,0}, []),
	player_win = check_winner:cw([{0,0},{1,0},{2,0},{3,0},{4,0}], [], {4,0}, {0,0}, []),
	ok;

test(2) ->
	player_win = check_winner:cw([{0,0},{0,1},{0,2},{0,3},{0,4}], [], {0,0}, {0,0}, []),
	player_win = check_winner:cw([{0,0},{0,1},{0,2},{0,3},{0,4}], [], {0,1}, {0,0}, []),
	player_win = check_winner:cw([{0,0},{0,1},{0,2},{0,3},{0,4}], [], {0,2}, {0,0}, []),
	player_win = check_winner:cw([{0,0},{0,1},{0,2},{0,3},{0,4}], [], {0,3}, {0,0}, []),
	player_win = check_winner:cw([{0,0},{0,1},{0,2},{0,3},{0,4}], [], {0,4}, {0,0}, []),
	ok;

test(3) ->
	player_win = check_winner:cw([{0,0},{1,1},{2,2},{3,3},{4,4}], [], {0,0}, {0,0}, []),
	player_win = check_winner:cw([{0,0},{1,1},{2,2},{3,3},{4,4}], [], {1,1}, {0,0}, []),
	player_win = check_winner:cw([{0,0},{1,1},{2,2},{3,3},{4,4}], [], {2,2}, {0,0}, []),
	player_win = check_winner:cw([{0,0},{1,1},{2,2},{3,3},{4,4}], [], {3,3}, {0,0}, []),
	player_win = check_winner:cw([{0,0},{1,1},{2,2},{3,3},{4,4}], [], {4,4}, {0,0}, []),
	ok;

test(4) ->
	player_win = check_winner:cw([{0,4},{1,3},{2,2},{3,1},{4,0}], [], {0,4}, {0,0}, []),
	player_win = check_winner:cw([{0,4},{1,3},{2,2},{3,1},{4,0}], [], {1,3}, {0,0}, []),
	player_win = check_winner:cw([{0,4},{1,3},{2,2},{3,1},{4,0}], [], {2,2}, {0,0}, []),
	player_win = check_winner:cw([{0,4},{1,3},{2,2},{3,1},{4,0}], [], {3,1}, {0,0}, []),
	player_win = check_winner:cw([{0,4},{1,3},{2,2},{3,1},{4,0}], [], {4,0}, {0,0}, []),
	ok;

test(_) ->
	ok.
