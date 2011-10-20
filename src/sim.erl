-module(sim).
-compile([export_all]).

-include_lib("eunit/include/eunit.hrl").

-include("common.hrl").
-include("game.hrl").
-include("pp.hrl").
-include("schema.hrl").
-include("texas/ctx.hrl").

init() ->
  schema:install(),
  player:create("1010", "pass", "5b635bee55S3", "5Lit5Zu9", 1000), %% Jack
  player:create("1020", "pass", "6buRSkFDSw==", "6aaZ5riv", 1000), %% Sam 

  player:update_photo(1, <<"def_face_1">>),
  player:update_photo(2, <<"def_face_2">>),

  server:start().

login() ->
  login:login(<<"1010">>, <<"pass">>, self()),
  login:login(<<"1020">>, <<"pass">>, self()),
  ok.

socket() -> 
  socket(players()).

socket([]) ->
  ok;

socket([H|T]) ->
  gen_server:cast(H, {'SOCKET', self()}),
  socket(T).

players() ->
  players([1,2,3]).

players(L) ->
  players(L, []).
  
players([], Acc) ->
  Acc;

players([H|T], Acc) ->
  [P] = db:read(tab_player, H),
  players(T, [P#tab_player.process | Acc]).

p(PID) ->
  [P] = db:read(tab_player, PID),
  P#tab_player.process.

g(GID) ->
  [G] = db:read(tab_game_xref, GID),
  G#tab_game_xref.process.

dg(GID) when is_integer(GID) ->
  dg(g(GID));

dg(GID) when is_pid(GID) ->
  gen_server:call(GID, 'DEBUG').

watch() ->
  gen_server:cast(p(1),#watch{game=g(1)}).

join() -> 
  join(1, 1),
  join(2, 2).

join(P, N) ->
  gen_server:cast(p(P), #join{game=g(1), seat=N, amount=100.0}).

rec() ->
  receive 
    {packet, M} -> M
  end.

flush() ->
    flush(false).

flush(Debug) ->
  receive
    X ->
      if 
        Debug ->
          io:format("Flush: ~p~n", [X]);
        true ->
          ok
      end,
      flush()
  after 0 ->
      ok
  end.
