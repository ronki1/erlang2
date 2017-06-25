%%%-------------------------------------------------------------------
%%% @author ron
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. Jun 2017 14:59
%%%-------------------------------------------------------------------
-module(gfx).
-author("ronatan").

-include_lib("wx/include/wx.hrl").

-behaviour(gen_server).
-export([start/0]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
  terminate/2, code_change/3]).
-compile(export_all).
-define(SERVER, ?MODULE).

-define(game_x,(1024)).
-define(game_y,(768)).

-define(score_x,(100)).
-define(score_y,?game_y).

-import(mnes,[init_db/0,print_db/0,insert_food/2,remove_food/1,getFoods/0,insert_player/1,getPlayerById/1]).

start() -> gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
stop()  -> gen_server:call(?MODULE, stop).

init([]) ->
  Wx = wx:new(),
  Frame = wxFrame:new(Wx, -1, "Erl.io - Yonatan Pearlmutter & Ron Kotlarsky", [{size, {?game_x+?score_x, ?game_y}}]),
  wxFrame:show(Frame),
  Panel = wxPanel:new(Frame,0,0,?game_x,?game_y),
  ScorePanel = wxPanel:new(Frame,?game_x,0,?score_x,?score_y),
  wxWindow:setBackgroundColour(Panel, {255,255,255}),
  {ok,{Frame,Panel,ScorePanel}}
.

dummy(X,Y,R)->
  gen_server:call(?MODULE,{playerMoved,1,X,Y,R})
.

handle_call(reDraw, _From, Tab) ->
  {Frame,MainPanel,ScorePanel} = Tab,
  paint_foods(mnes:getFoods(),MainPanel),
  paint_players(mnes:getPlayers(),MainPanel),
  NewScorePanel=draw_scores(Frame,ScorePanel),
  {reply, MainPanel, {Frame,MainPanel,NewScorePanel}};

handle_call({addShape,X,Y,R}, _From, Tab) ->
  {Frame,MainPanel,ScorePanel} = Tab,
  %Panel = wxPanel:new(Frame,X-R,Y-R,2*R+1,2*R+1),
  %wxWindow:setBackgroundStyle(Panel,?wxBG_STYLE_CUSTOM),
  draw_circle(X,Y,R,MainPanel,?wxBLUE),
  NewPanel = draw_scores(Frame,ScorePanel),
  {reply, MainPanel, {Frame,MainPanel,NewPanel}};

handle_call({movePlayer,FromX,FromY,FromR,ToX,ToY,ToR}, _From, Tab) ->
  {Frame,MainPanel,ScorePanel} = Tab,
  draw_circle(FromX,FromY,FromR,MainPanel,?wxWHITE),
  %paint_foods(mnes:getFoods(),MainPanel),
  paint_players(mnes:getPlayers(),MainPanel),
  %wxWindow:refresh(MainPanel),
  draw_circle(ToX,ToY,ToR,MainPanel,?wxBLUE),
  {reply, MainPanel, Tab};

handle_call({deleteFood,X,Y,R}, _From, Tab) ->
  {Frame,MainPanel,ScorePanel} = Tab,
  draw_circle(X,Y,R,MainPanel,?wxWHITE),
  NewPanel = draw_scores(Frame,ScorePanel),
  {reply, MainPanel, {Frame,MainPanel,NewPanel}};

handle_call(playersChanged, _From, Tab) ->
  {Frame,MainPanel,ScorePanel} = Tab,
  NewPanel = draw_scores(Frame,ScorePanel),
  {reply, MainPanel, {Frame,MainPanel,NewPanel}};

handle_call(stop, _From, Tab) ->
  {stop, normal, stopped, Tab}.
handle_cast(_Msg, State) ->{reply, ok, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

draw_circle(X,Y,Radius,Panel,Color) ->
  Paint = wxPaintDC:new(Panel),
  Brush = wxBrush:new(),
  Pen = wxPen:new(),
  wxPen:setColour(Pen,Color),
  wxBrush:setColour(Brush, Color),
  wxBrush:setStyle(Brush,?wxSOLID),
  wxDC:setBrush(Paint, Brush),
  wxDC:setPen(Paint,Pen),
  wxDC:drawCircle(Paint ,{X,Y},Radius),
  wxBrush:destroy(Brush),
  wxPaintDC:destroy(Paint),
  wxPen:destroy(Pen)
.


draw_scores(Frame,Panel) ->
  wxPanel:destroy(Panel),
  NewPanel = wxPanel:new(Frame,?game_x,0,?score_x,?score_y),
  DrawContext = wxPaintDC:new(NewPanel),
  Pen = wxPen:new(?wxGREEN, [{width, 2}]),
  Brush = wxBrush:new(),
  wxBrush:setColour(Brush, ?wxGREEN),
  wxDC:setPen(DrawContext, Pen),
  wxDC:setBrush(DrawContext, Brush),
  Players = mnes:getPlayers(),
  Text = make_score(Players),
  wxPaintDC:drawText(DrawContext,Text,{0,0}),
  wxBrush:destroy(Brush),
  wxPaintDC:destroy(DrawContext),
  NewPanel
.

make_score([]) -> " ";
make_score([{_,_,_,_,R,_,Name,_}|T]) -> Name ++ ":   " ++ integer_to_list(R) ++ "\n" ++ make_score(T).


paint_foods([],Panel)->
  Panel;
paint_foods([H|T],Panel)->
  {food,PID,X,Y,Radius,_} = H,
  draw_circle(X,Y,Radius,Panel,?wxBLUE),
  paint_foods(T,Panel).

paint_players([],Panel)->
  Panel;
paint_players([H|T],Panel)->
  {player,PID,X,Y,R,ID,Name,_Panel} = H,
  draw_circle(X,Y,R,Panel,?wxBLUE),
  paint_players(T,Panel).