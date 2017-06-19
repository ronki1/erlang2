%% File for wxWidget Lab
-module(gfx).
-export([start/0]).
-include_lib("wx/include/wx.hrl").
-define(max_x,(1024)).
-define(max_y,(768)).



%% Creeates the window and menus etc.
start() ->
  register(main_process,self()),
  Wx = wx:new(),
  Frame = wxFrame:new(Wx, -1, "Concurent and Distributed LAB", [{size, {?max_x, ?max_y}}]),
  Panel = wxPanel:new(Frame,0,0,500,500),
  wxWindow:setBackgroundColour(Panel, {255,255,255}),
  OnPaint = fun(_Evt, _Obj) ->
    Brush = wxBrush:new(),
    Paint = wxPaintDC:new(Panel),
    wxDC:setBrush(Paint, Brush)
    %wxDC:drawLabel(Paint,"Press File-> Start to Begin .",{(?max_x) div 3,(?max_y) div 3,200,200}),
%%    draw_line(50,50,{100,100},{100,100},Panel),
%%    draw_line(150,150,{100,100},{100,100},Panel),
%%    draw_line(150,50,{100,100},{100,100},Panel),
%%    draw_line(50,150,{100,100},{100,100},Panel),
%%    draw_line(250,250,{100,100},{100,100},Panel),
%%    draw_line(70,50,{100,100},{100,100},Panel),
%%    draw_line(80,120,{100,100},{100,100},Panel),
%%    draw_line(205,150,{100,100},{100,100},Panel)
            end,
  wxFrame:connect(Panel, paint, [{callback, OnPaint}]),
  MoveFunc = fun({wx,_A, {wx_ref,_B,wxFrame,[]},[],{wxKey,char_hook,_C,_D,_E,false,false,false,false,false,_G,_H,DIR}},_Obj) ->
    if
      DIR=:=116 -> io:format("Down~n"),Dir=down, main_process!{keyPressed,Dir};
      DIR=:=114 -> io:format("Right~n"),Dir=right,main_process!{keyPressed,Dir};
      DIR=:=113 -> io:format("Left~n"),Dir=left,main_process!{keyPressed,Dir};
      DIR=:=111 -> io:format("Up~n"),Dir=up,main_process!{keyPressed,Dir}
    end,
    wxWindow:setFocus(Frame)
   end,
  MenuBar = wxMenuBar:new(),
  wxFrame:setMenuBar (Frame, MenuBar),
  wxFrame:getMenuBar (Frame),
  FileMn = wxMenu:new(),
  wxMenuBar:append (MenuBar, FileMn, "&File"),
  Start=wxMenuItem:new ([{id,300},{text, "&Start"}]),wxMenu:append (FileMn, Start),
  LineD=wxMenuItem:new ([{id,600},{text, "&Draw Line"}]),wxMenu:append (FileMn, LineD),
  Circ=wxMenuItem:new ([{id,700},{text, "&Draw Circle"}]),wxMenu:append (FileMn, Circ),
  Quit = wxMenuItem:new ([{id,400},{text, "&Quit"}]),wxMenu:append (FileMn, Quit),
  HelpMn = wxMenu:new(),
  wxMenuBar:append (MenuBar, HelpMn, "&Help"),
  About = wxMenuItem:new ([{id,500},{text,"About"}]),
  wxMenu:append (HelpMn, About),
  wxFrame:connect (Frame, command_menu_selected),
  wxWindow:connect(Frame, char_hook, [{callback,MoveFunc}]),
  wxFrame:show(Frame),
  DotPid = spawn(fun()->  dotMover(50,50) end),
  register(dotPid,DotPid),
  io:fwrite("spawned at pid :~p",[DotPid]),
  spawn(fun() -> start_udp(7777) end),
  loop(Frame,Panel,DotPid). % pass the needed parameters here


%% Handles all the menu bar commands
loop(Frame,Panel,DotPid) ->
  receive
    {moveDot,X,Y}->
      io:fwrite("received X:~p Y:~p",[X,Y]),
      wxPanel:destroy(Panel),
      Panel2 = wxPanel:new(Frame,0,0,500,500),
      %%wxWindow:setBackgroundColour(Panel2, {255,255,255}),
      draw_line(X,Y,{100,100},{100,100},Panel2),
      loop(Frame,Panel2,DotPid)
  ;
    {keyPressed,up}->
        DotPid!{0,-5},loop(Frame,Panel,DotPid);

    {keyPressed,down}->
      DotPid!{0,5},loop(Frame,Panel,DotPid);

    {keyPressed,left}->
      DotPid!{-5,0},loop(Frame,Panel,DotPid);

    {keyPressed,right}->
      DotPid!{5,0},loop(Frame,Panel,DotPid);
    {_,X,_,_,_}->
      io:fwrite("~p ~n", [X]),
        DotPid!{5,5},
      loop(Frame,Panel,DotPid);
%%      case X of
%%        500 ->
%%        400 ->
%%        600 ->
%%        700 ->
%%        300 ->
        A -> io:fwrite("Received: ~p \n",[A])
end
.

%draw function
draw_line(X,Y,Dot2,Dot1,Panel)-> Paint = wxPaintDC:new(Panel),
  Brush = wxBrush:new(),
  wxBrush:setColour(Brush, ?wxBLUE),
  wxDC:setBrush(Paint,Brush),
  wxDC:drawLine(Paint,Dot2,Dot1), %draw line between two dots
  wxBrush:setColour(Brush, ?wxGREEN),
  wxDC:drawCircle(Paint ,{X,Y},3),  %draw circle center at {X,Y}
  wxBrush:destroy(Brush),
  wxPaintDC:destroy(Paint).

draw_circle(X,Y,Center,Panel) ->
  Paint = wxPaintDC:new(Panel),
  Brush = wxBrush:new(),
  wxBrush:setColour(Brush, ?wxBLUE),
  wxDC:drawCircle(Paint ,{X,Y},3).

dotMover(X,Y)->
  receive
    {Dx,Dy}->
      main_process!{moveDot,Dx+X,Dy+Y},
      dotMover(X+Dx,Y+Dy);
    A->io:fwrite("dotMover received: ~p \n ",[A])
  end
.

start_udp(Port) ->
  gen_udp:open(Port,[binary,{active,true}]),
  loop_udp().

loop_udp() ->
  receive
    {_,_,_,_,<<X:32/signed-integer,Y:32/signed-integer>>} ->
      io:format("received: ~p,~p~n", [X/50,Y/50]),
      dotPid!{round(X/50),round(-Y/50)},
      loop_udp();
    M ->
      io:format("received: ~p~n", [M]),
      loop_udp()
  end.
