extends Control
var game
var front: Control
var front_bg: TextureRect
var front_dim: ColorRect
var title_page: Control
var hub_page: Control
var ai_page: Panel
var intro_panel: Panel
var result_panel: Panel
var board_panel: Panel
var menu_page="hub"
var play_kind="local"
var front_music: Button
var front_effects: Button
var press_hint: Label
var ai_name: LineEdit
var save_game_button: Button
var save_shade: ColorRect
var save_panel: Panel
var save_heading: Label
var save_status: Label
var slot_buttons: Array[Button]=[]
var save_mode="load"
var save_return="menu"
var save_return_page="hub"
var pending_slot=-1
var journey_panel: Panel
var journey_scroll: ScrollContainer
var journey_grid: GridContainer
var journey_ids: Array[int]=[]
var journey_title: Label
var journey_summary: Label
var journey_path: Label
var journey_return="menu"
var journey_return_page="ai"
var journey_button: Button
var profile_panels: Array[Panel]=[]
var profile_images: Array[TextureRect]=[]
var profile_stamp=""
var face_cache: Dictionary={}
var display_font: Font=preload("res://assets/fonts/ClubDisplay.ttf")
var intro_art: TextureRect
var intro_name: Label
var intro_rank: Label
var intro_trait: Label
var intro_quote: Label
var intro_gear: Label
var intro_diamonds: Label
var result_title: Label
var result_quote: Label
var result_name: Label
var result_text: Label
var result_art: TextureRect
var result_action: Button
var result_end: Button
var intro_save: Button
var result_save: Button
var board_rows: Array[Label]=[]
var board_wins: Array[Label]=[]
var board_points: Array[Label]=[]
var atlas_cache: Dictionary={}
var club: Font=preload("res://assets/fonts/ClubSerif.ttf")
var extra_buttons: Array[Button]=[]
var bold: Font=preload("res://assets/fonts/Lato-Bold.ttf")
var regular: Font=preload("res://assets/fonts/Lato-Semibold.ttf")
var menu: Panel
var settings: Panel
var help_panel: Panel
var pause_button: Button
var play_button: Button
var pocket_buttons: Array[Button]=[]
var call_choice: OptionButton
var selected_mode = 0
var mode_buttons: Array[Button]=[]
var name_one: LineEdit
var name_two: LineEdit
var active_hint = ""
var mode_note: Label
var quality_button: Button
var sound_button: Button
var music_button: Button
var badge_cache: Dictionary={}
const BADGE_RADIUS=21.0
var spin_texture: ImageTexture
var draw_signature=0
const GOLD:=Color("d7b77a")
const LIGHT:=Color("edf3ed")
const DIM:=Color("9eaca9")
const INK:=Color("101b1f")

func _ready() -> void:
 # Bake the static shaded control once instead of drawing 48 overlapping discs.
 var image=Image.create(128,128,false,Image.FORMAT_RGBA8)
 for y in range(128):
  for x in range(128):
   var p=(Vector2(x,y)-Vector2(63.5,63.5))/63.5
   var radius=p.length()
   if radius>1.0:continue
   var normal=Vector3(p.x,-p.y,sqrt(maxf(0,1-p.length_squared())))
   var value=0.48+0.50*maxf(0,normal.dot(Vector3(-0.4,0.5,0.8).normalized()))
   image.set_pixel(x,y,Color(value,value,value*0.96,clampf((1-radius)*64,0,1)))
 spin_texture=ImageTexture.create_from_image(image)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 var theme =Theme.new();theme.default_font=regular;theme.default_font_size=18
 for state in ["normal","hover","pressed","focus"]:
  var style =StyleBoxFlat.new();style.bg_color=Color("142e35") if state=="normal" else Color("254952");style.border_color=Color("42636a");style.set_border_width_all(1);style.set_corner_radius_all(8);style.content_margin_left=15;style.content_margin_right=15
  theme.set_stylebox(state,"Button",style)
 theme.set_color("font_color","Button",LIGHT);self.theme=theme
 pause_button=_button("Ⅱ",Vector2(935,20),Vector2(52,50),func():game.toggle_pause())
 extra_buttons.append(_button("?  CONTROLS",Vector2(25,835),Vector2(155,39),func():help_panel.visible=not help_panel.visible))
 extra_buttons.append(_button("CAMERA [TAB]",Vector2(195,835),Vector2(160,39),func():game.switch_camera()))
 extra_buttons.append(_button("NEW MATCH",Vector2(370,835),Vector2(145,39),func():game.open_menu()))
 play_button=_button("SHOOT  [SPACE]",Vector2(1225,835),Vector2(230,44),func():game.strike())
 call_choice=OptionButton.new();call_choice.position=Vector2(315,842);call_choice.size=Vector2(220,39);add_child(call_choice);call_choice.item_selected.connect(_call_selected)
 for index in range(6):
  var pocket_index=index
  var button=_button(str(index+1),Vector2.ZERO,Vector2(36,36),func():game.select_pocket(pocket_index))
  button.add_theme_font_override("font",bold);button.add_theme_font_size_override("font_size",18)
  button.tooltip_text="Call pocket %d [%d]" % [index+1,index+1]
  pocket_buttons.append(button)
 _make_menu();_make_settings();_make_help();_make_profiles();_make_frontend();_make_saves()

func _process(_dt: float) -> void:
 var vp =get_viewport_rect().size
 var s =minf(vp.x/1600,vp.y/900)
 scale=Vector2.ONE*s;position=(vp-Vector2(1600,900)*s)*0.5
 size=Vector2(1600,900)
 if game==null: return
 menu.visible=game.state=="menu" and menu_page=="setup"
 _front_update()
 _sync_profiles()
 settings.visible=game.state=="paused"
 save_shade.visible=game.state=="saves"
 save_game_button.disabled=game.campaign.kind!="tournament"
 quality_button.text="Visuals\n"+("High quality" if game.high_quality else "Smooth performance")
 sound_button.text="Sound effects\n"+("On" if game.sound_enabled else "Off")+"  ·  M"
 music_button.text="Music\n"+("On" if game.music_enabled else "Off")+"  ·  N"
 journey_button.text="Your journey" if game.campaign.kind=="tournament" else "How to play"
 pause_button.visible=game.state in ["aim","rolling","paused"]
 pause_button.text="▶" if game.state=="paused" else "Ⅱ"
 for button in extra_buttons:button.visible=false
 play_button.visible=game.state=="aim" and game.human_turn() and not game.rules.ball_in_hand and not game.rules.match_over
 play_button.text="CHOOSE POCKET  [1–6]" if game.needs_pocket_call() and game.rules.called_pocket<0 else "SELECT BALL" if not game.shot_call_prompt().is_empty() else "SHOOT  [SPACE]"
 _sync_pocket_buttons()
 play_button.disabled=game.state!="aim" or game.rules.ball_in_hand or game.rules.match_over
 call_choice.focus_mode=Control.FOCUS_NONE
 call_choice.visible=game.state in ["aim","rolling"] and (game.rules.is_snooker() and game.rules.phase=="colour" or game.rules.mode in [2,3])
 var signature=hash([vp,game.state,game.rules.names,game.rules.player,game.rules.scores,
  game.rules.mode,game.rules.groups,game.rules.message,game.rules.target_text(game.sim),
  game.rules.remaining_group(game.sim,0),game.rules.remaining_group(game.sim,1),
  game.rules.called_pocket,game.rules.ball_in_hand,game.rules.match_over,
  game.power,game.spin,game.aim_locked,game.pocketed_by,game.table.camera.transform,game.show_debug,
  Engine.get_frames_per_second() if game.show_debug else 0,game.high_quality,game.campaign.points,game.campaign.diamonds,game.campaign.rival_index,game.ai_delay>0.35])
 if signature!=draw_signature:
  draw_signature=signature;queue_redraw()

func _sync_pocket_buttons() -> void:
 var visible_now=game.state=="aim" and game.human_turn() and not game.rules.ball_in_hand and not game.rules.match_over and game.needs_pocket_call()
 for index in range(pocket_buttons.size()):
  var button=pocket_buttons[index];button.visible=visible_now
  if not visible_now:continue
  var target: Vector2=game.table.pocket_target(index)
  var screen=game.table.camera.unproject_position(Vector3(target.x,game.table.BED+game.sim.radius,target.y))
  button.position=get_global_transform().affine_inverse()*screen-button.size*0.5
  var selected=game.rules.called_pocket==index
  var stamp=str(selected)
  if button.get_meta("selection","")!=stamp:
   button.set_meta("selection",stamp)
   for state_name in ["normal","hover","pressed","focus"]:
    var style=_style(Color("725721") if selected else Color("172326"),GOLD,18)
    style.content_margin_left=0;style.content_margin_right=0
    button.add_theme_stylebox_override(state_name,style)

func shot_hint() -> String:
 var requirement=game.shot_call_prompt()
 if not requirement.is_empty():return requirement
 if game.rules.called_pocket>=0:return "POCKET %d CALLED · SET AIM / POWER · SPACE TO SHOOT" % (game.rules.called_pocket+1)
 return "AIM LOCKED · RIGHT CLICK TO UNLOCK · SET POWER, THEN SPACE TO SHOOT" if game.aim_locked else "CLICK TO LOCK AIM · WHEEL / METER: POWER · SPACE: SHOOT"

func _button(text: String,pos: Vector2,dimensions: Vector2,callback: Callable,parent: Node=self) -> Button:
 var button =Button.new();button.text=text;button.position=pos;button.size=dimensions;button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;button.focus_mode=Control.FOCUS_NONE;parent.add_child(button);button.pressed.connect(func():game._play_sound("ui_confirm",0.4);callback.call());button.mouse_entered.connect(func():game._play_sound("ui_move",0.2));return button
func _panel(pos: Vector2,dimensions: Vector2) -> Panel:
 var p =Panel.new();p.position=pos;p.size=dimensions
 var style =StyleBoxFlat.new();style.bg_color=Color(0.055,0.046,0.034,0.97);style.border_color=Color("a08c65");style.set_border_width_all(1);style.set_corner_radius_all(18);style.shadow_color=Color(0,0,0,0.6);style.shadow_size=25;p.add_theme_stylebox_override("panel",style);add_child(p);return p
func _label(text: String,pos: Vector2,font_size: int,parent: Node=self,color: Color=LIGHT) -> Label:
 var l =Label.new();l.text=text;l.position=pos;l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",color);parent.add_child(l);return l

func _make_menu() -> void:
 menu=_panel(Vector2(375,115),Vector2(850,675))
 _label("THE LAST POCKET",Vector2(35,24),36,menu,GOLD)
 _label("LOCAL VERSUS  /  Two players, one table.",Vector2(36,72),18,menu,DIM)
 _button("BACK",Vector2(700,26),Vector2(110,40),show_hub,menu)
 for i in range(game.rules.MODES.size()):
  var index =i
  var row =i/2;var col =i%2
  var button =_button(game.rules.MODES[i],Vector2(35+col*395,120+row*66),Vector2(380,52),func():_select_mode(index),menu)
  mode_buttons.append(button)
 mode_note=_label("",Vector2(36,447),14,menu,DIM)
 _label("PLAYER ONE",Vector2(36,474),15,menu,DIM);_label("PLAYER TWO",Vector2(430,474),15,menu,DIM)
 name_one=LineEdit.new();name_one.position=Vector2(35,502);name_one.size=Vector2(380,42);name_one.text="PLAYER 1";name_one.max_length=18;menu.add_child(name_one)
 name_two=LineEdit.new();name_two.position=Vector2(430,502);name_two.size=Vector2(380,42);name_two.text="PLAYER 2";name_two.max_length=18;menu.add_child(name_two)
 _button("PLAY MATCH",Vector2(35,570),Vector2(500,63),func():
  game.rules.names=[name_one.text.strip_edges() if name_one.text.strip_edges()!="" else "PLAYER 1",name_two.text.strip_edges() if name_two.text.strip_edges()!="" else "PLAYER 2"]
  game.start_local(selected_mode),menu)
 _button("QUIT",Vector2(555,570),Vector2(255,63),func():game.quit_game(),menu)
 _select_mode(0)
func _select_mode(index: int) -> void:
 selected_mode=index
 if is_instance_valid(mode_note): mode_note.text=game.rules.NOTES[index]
 for i in range(mode_buttons.size()): mode_buttons[i].modulate=Color("e8c994") if i==index else Color.WHITE

func _make_settings() -> void:
 settings=_panel(Vector2(470,80),Vector2(660,740));settings.visible=false;settings.z_index=50
 _wood_surface(Vector2.ZERO,Vector2(660,740),settings,0.38)
 _label("THE LAST POCKET",Vector2(38,25),17,settings,GOLD)
 var heading=_label("Match paused",Vector2(35,61),42,settings,LIGHT);heading.add_theme_font_override("font",bold)
 _label("Your table is frozen. Resume whenever you are ready.",Vector2(38,117),16,settings,DIM)
 var resume=_wood_button("Resume play","play",Vector2(30,154),Vector2(600,70),func():game.resume_play(),settings)
 resume.name="ResumePlay";resume.tooltip_text="Resume the paused match [Esc]"
 save_game_button=_wood_button("Save tournament","save",Vector2(30,242),Vector2(290,70),func():show_saves("save"),settings)
 save_game_button.tooltip_text="Save this AI tournament to one of ten slots. Local matches are not saved."
 _wood_button("Load tournament","chart",Vector2(340,242),Vector2(290,70),func():show_saves("load"),settings)
 music_button=_wood_button("Music","music",Vector2(30,330),Vector2(290,80),func():game.toggle_music(),settings)
 sound_button=_wood_button("Sound effects","sound",Vector2(340,330),Vector2(290,80),func():game.toggle_sound(),settings)
 quality_button=_wood_button("Visuals","settings",Vector2(30,428),Vector2(290,80),func():game.toggle_quality(),settings)
 journey_button=_wood_button("Your journey","chart",Vector2(340,428),Vector2(290,80),func():
  if game.campaign.kind=="tournament":show_journey()
  else:help_panel.visible=true,settings)
 _wood_button("Main menu","back",Vector2(30,540),Vector2(290,65),func():game.open_menu(),settings)
 _wood_button("Quit game","close",Vector2(340,540),Vector2(290,65),func():game.quit_game(),settings)
 _wrapped("Progress is saved only when you choose Save tournament.
No automatic progress saving.",Vector2(38,638),Vector2(584,62),17,settings,DIM)

func _make_saves() -> void:
 save_shade=ColorRect.new();save_shade.size=Vector2(1600,900);save_shade.color=Color(0.008,0.013,0.014,0.92);save_shade.z_index=70;add_child(save_shade);save_shade.visible=false
 save_panel=_panel(Vector2(200,55),Vector2(1200,790));save_panel.reparent(save_shade);save_panel.position=Vector2(200,55)
 _wood_surface(Vector2.ZERO,Vector2(1200,790),save_panel,0.24)
 save_heading=_label("LOAD TOURNAMENT",Vector2(36,24),32,save_panel,GOLD);save_heading.add_theme_font_override("font",bold)
 _wrapped("Ten separate slots. Each save records the player and local date/time. Progress is never saved automatically.",Vector2(38,78),Vector2(1110,45),18,save_panel,DIM)
 for index in range(game.SAVE_SLOTS):
  var slot=index
  var button=_button("",Vector2(36,142+index*50),Vector2(1128,43),func():_choose_slot(slot),save_panel)
  button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.add_theme_font_size_override("font_size",18);slot_buttons.append(button)
 save_status=_wrapped("",Vector2(38,655),Vector2(1120,50),18,save_panel,GOLD)
 _icon_button(" BACK","back",Vector2(36,718),Vector2(1128,45),close_saves,save_panel)

func show_saves(mode: String) -> void:
 if mode=="save" and game.campaign.kind!="tournament":return
 if game.state=="saves":return
 save_return=game.state;save_return_page=menu_page;save_mode=mode;pending_slot=-1
 game.charging=false;game.power_drag=false;game.spin_drag=false;game.state="saves";help_panel.visible=false
 save_heading.text="SAVE TOURNAMENT" if mode=="save" else "LOAD TOURNAMENT"
 save_status.text="Choose an empty slot, or select an existing save to replace it." if mode=="save" else "Choose a saved tournament. Active frames open paused."
 _refresh_slots()

func _refresh_slots() -> void:
 var slots=game.list_save_slots()
 for info in slots:
  var button=slot_buttons[info.index]
  button.disabled=save_mode=="load" and not info.valid
  if info.empty:button.text="%02d   ·   EMPTY SLOT" % (info.index+1)
  elif not info.valid:button.text="%02d   ·   UNREADABLE SAVE%s" % [info.index+1," — select to replace" if save_mode=="save" else ""]
  else:
   var bias=int(info.offset);var offset="UTC%s%02d:%02d" % ["+" if bias>=0 else "-",absi(bias)/60,absi(bias)%60]
   button.text="%02d   ·   %s    |    %s (%s)    |    %s · Frame %02d / 48" % [info.index+1,info.player,info.timestamp,offset,game.Campaign.TIERS[int(info.tier)],info.frame]
  if pending_slot==info.index:button.text="%02d   ·   CONFIRM REPLACE THIS SAVE — CLICK AGAIN" % (info.index+1)

func _choose_slot(index: int) -> void:
 if save_mode=="load":
  if not game.load_slot(index):save_status.text="This save could not be loaded. Your current game is unchanged."
  return
 var result=game.save_slot(index,pending_slot==index)
 save_status.text=result.message
 pending_slot=index if result.get("confirm",false) else -1
 _refresh_slots()

func close_saves() -> void:
 if game.state!="saves":return
 if pending_slot>=0:
  pending_slot=-1;save_status.text="Replacement cancelled. The original save was kept.";_refresh_slots();return
 game.state=save_return;menu_page=save_return_page

func _make_help() -> void:
 help_panel=_panel(Vector2(310,165),Vector2(980,595));help_panel.visible=false;help_panel.z_index=60
 _label("AT THE TABLE",Vector2(35,25),32,help_panel,GOLD)
 _label("Aim with the mouse; click the cloth to lock your direction.\nSet power with the mouse wheel or drag the left meter.\nPress SPACE / ENTER or click SHOOT when ready. Right-click unlocks aim.\n\nDrag the white spin ball at the lower right for draw, follow and side.\nWhen you have ball in hand, click a clear position on the cloth.\nSnooker placement is restricted to the D; the outline shows the baulk area.\n\nFor called shots, select a ball below and choose a numbered pocket.\nSnooker colours are nominated using the colour selector.\nH: help. ESC: pause. F11: fullscreen. M: effects. N: music. F3: FPS.\n\nClub rules are used; referee-dependent tournament exceptions are\ndocumented in RULES.md. Local players share controls. In VS AI, you are player one.",Vector2(35,90),20,help_panel,LIGHT)
 _button("BACK TO TABLE",Vector2(35,510),Vector2(910,50),func():help_panel.visible=false,help_panel)

func refresh_calls() -> void:
 call_choice.clear()
 if game.rules.is_snooker():
  for id in range(2,8):
   call_choice.add_item(["","","Yellow · 2","Green · 3","Brown · 4","Blue · 5","Pink · 6","Black · 7"][id],id)
  call_choice.select(clampi(game.rules.nominated-2,0,5))
 else:
  game.rules.called_ball=-1
  call_choice.add_item("Call a ball",-1)
  for b in game.sim.balls:
   if b.active and b.id>0: call_choice.add_item("Ball %d" % b.id,b.id)
func _call_selected(index: int) -> void:
 var id =call_choice.get_item_id(index)
 if game.rules.is_snooker(): game.rules.nominated=id
 else: game.rules.called_ball=id

func _club_text(text: String,point: Vector2,font_size: int,color: Color=LIGHT) -> void:
 draw_string(bold,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _center_text(text: String,x: float,y: float,font_size: int,color: Color=LIGHT) -> void:
 var width=regular.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
 draw_string(regular,Vector2(x-width*0.5,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _badge(center: Vector2,active: bool) -> void:
 draw_circle(center,28,Color("171715"));draw_arc(center,28,0,TAU,64,GOLD if active else Color("9a9b96"),1.7,true)
 draw_arc(center,24,0,TAU,64,Color("514c3b"),0.7,true)
 for offset in [Vector2(0,-10),Vector2(-10,7),Vector2(10,7)]:
  draw_circle(center+offset,8,Color("b59655") if active else Color("8f918d"))
  draw_circle(center+offset,5,Color("302e24"));draw_circle(center+offset-Vector2(1,1),2,Color("d7c99f"))
func _draw() -> void:
 if game==null or game.state in ["title","menu"]:return
 draw_style_box(_style(Color(0.015,0.014,0.012,0.87),Color(0.4,0.36,0.27,0.45),0),Rect2(0,0,1600,92))
 var title=game.rules.MODES[game.rules.mode].to_upper().replace("8-BALL POOL","8  BALL").replace("9-BALL POOL","9  BALL").replace("10-BALL POOL","10  BALL")
 _center_hud("THE LAST POCKET",800,28,15,GOLD)
 var mode_size=27
 while mode_size>16 and bold.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,mode_size).x>230:mode_size-=1
 _center_hud(title,800,62,mode_size,LIGHT)
 for x in [625,1005]:draw_line(Vector2(x,21),Vector2(x,72),Color("6c6250"),1)
 for index in range(2):
  var name_at=Vector2(100,39) if index==0 else Vector2(1100,39)
  var active=game.rules.player==index
  var name_width=180.0 if index==0 else 155.0
  var fitted=fit_player_name(game.rules.names[index],name_width)
  draw_string(bold,name_at,fitted.text,HORIZONTAL_ALIGNMENT_LEFT,name_width,fitted.size,LIGHT)
  if active:
   draw_string(bold,name_at+Vector2(0,24),("LINING UP" if index==1 and game.campaign.kind!="local" else "YOUR TURN") if game.state!="rolling" else "AT THE TABLE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,GOLD)
   draw_line(name_at+Vector2(0,36),name_at+Vector2(name_width,36),GOLD,2)
  _ball_collection(index,Vector2(300,20) if index==0 else Vector2(1270,20))
  if game.rules.mode in [3,5,6,7,8]:_club_text(str(game.rules.scores[index]),name_at+Vector2(name_width-38,47),18,GOLD)
 if game.state=="menu":return
 _power_meter();_spin_ball()
 draw_line(Vector2(550,858),Vector2(650,858),Color("8d7b58"),0.8)
 draw_line(Vector2(950,858),Vector2(1050,858),Color("8d7b58"),0.8)
 var context="LOCAL VERSUS" if game.campaign.kind=="local" else "VERSUS AI"
 if game.campaign.kind=="tournament":context="%s  /  RIVAL %02d OF 12" % [game.Campaign.TIERS[game.campaign.tier()].to_upper(),game.campaign.rival_index%12+1]
 _center_text(context,800,864,18,Color("cbbd9d"))
 if game.campaign.kind=="tournament":
  for i in range(3):
   var center=Vector2(132+i*30,858)
   var colour=GOLD if i<game.campaign.diamonds else Color("484842")
   draw_colored_polygon(PackedVector2Array([center+Vector2(0,-12),center+Vector2(11,-3),center+Vector2(0,12),center+Vector2(-11,-3)]),colour)
   draw_line(center+Vector2(-11,-3),center+Vector2(11,-3),Color(1,1,1,0.4),1)
  _club_text("%06d" % game.campaign.points,Vector2(225,866),18,GOLD)
 var hint=shot_hint()
 if game.rules.ball_in_hand:hint="PLACE THE CUE BALL"+(" INSIDE THE D" if game.rules.is_snooker() else " BEHIND THE HEAD STRING" if game.rules.baulk_only else " ON THE CLOTH")
 elif not game.shot_call_prompt().is_empty():hint=game.shot_call_prompt()
 elif "FOUL" in game.rules.message:hint=game.rules.message.left(110)
 elif game.rules.is_snooker():hint="ON: "+game.rules.target_text(game.sim)
 if game.state=="aim" and game.human_turn() and not game.rules.ball_in_hand and not game.shot_call_prompt().is_empty():
  draw_style_box(_style(Color(0.035,0.027,0.015,0.96),GOLD,10),Rect2(450,778,700,43))
  _center_text("FINAL 8-BALL · CHOOSE ITS POCKET [1–6]" if game.rules.mode==0 else game.shot_call_prompt(),800,806,18,GOLD)
 _center_text(hint,800,891,12,Color("b5a98b"))
 if game.show_debug:_club_text("%d FPS" % Engine.get_frames_per_second(),Vector2(1420,875),14,GOLD)
 if game.rules.match_over and game.state!="result":
  draw_style_box(_style(Color(0.025,0.023,0.018,0.95),GOLD,12),Rect2(420,325,760,210))
  _center_text(game.rules.message,800,405,28,GOLD)
  _center_text("ENTER FOR A REMATCH",800,474,19)
func collection(index: int) -> Dictionary:
 if game.rules.mode in [0,4]:
  var group: int=game.rules.groups[index]
  if group<0:return {"label":"OPEN TABLE","ids":[],"assigned":true}
  var ids: Array=[]
  for b in game.sim.balls:
   if game.rules.group_of(b.id)==group:ids.append(b.id)
  ids.sort()
  var left: int=game.rules.remaining_group(game.sim,group)
  return {"label":("SOLIDS" if group==0 else "STRIPES")+"  %d/7" % (7-left),"ids":ids,"assigned":true}
 return {"label":"POTTED","ids":game.pocketed_by[index].slice(-7),"assigned":false}

func fit_player_name(text: String,width: float) -> Dictionary:
 var font_size=24
 while font_size>14 and bold.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width:font_size-=1
 var shown=text
 while shown.length()>1 and bold.get_string_size(shown,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>width:
  shown=shown.trim_suffix("…").left(shown.trim_suffix("…").length()-1)+"…"
 return {"text":shown,"size":font_size}

func prime_ball_badges() -> void:
 for ball in game.sim.balls:badge_texture(ball.id)

func badge_texture(id: int) -> ImageTexture:
 var colour: Color=game.table.ball_colour(id)
 var striped=game.rules.mode not in [4,5,6,7,8] and id>8 and id<16
 var key=colour.to_html()+str(striped)
 if badge_cache.has(key):return badge_cache[key]
 var image=Image.create(96,96,false,Image.FORMAT_RGBA8)
 var light=Vector3(-0.42,0.62,0.84).normalized()
 for y in range(96):
  for x in range(96):
   var p=(Vector2(x,y)-Vector2(47.5,47.5))/47.0
   var radius=p.length()
   if radius>1.0:continue
   var normal=Vector3(p.x,-p.y,sqrt(maxf(0.0,1.0-p.length_squared())))
   var base=colour
   if striped and absf(normal.y)>0.43:base=Color("f5efdb")
   if p.distance_to(Vector2(0.04,0.06))<0.34:base=Color("f7efdb")
   var shade=0.20+0.80*maxf(0.0,normal.dot(light))
   var reflection=pow(maxf(0.0,normal.dot(light)),48.0)*0.8
   var panel=exp(-pow((p.x+0.34)/0.13,8)-pow((p.y+0.49)/0.20,8))*0.78
   var small=exp(-pow((p.x+0.04)/0.055,8)-pow((p.y+0.56)/0.14,8))*0.64
   var result=base*shade+Color.WHITE*(reflection+panel+small)
   result.a=clampf((1.0-radius)*47,0.0,1.0)
   image.set_pixel(x,y,result)
 var texture=ImageTexture.create_from_image(image);badge_cache[key]=texture
 return texture

func _ball_collection(index: int,position_at: Vector2) -> void:
 var info=collection(index)
 draw_string(bold,position_at,info.label,HORIZONTAL_ALIGNMENT_LEFT,-1,10,DIM)
 for i in range(info.ids.size()):
  var id: int=info.ids[i]
  var center=position_at+Vector2(21+i*42,30)
  var ball: Dictionary=game.sim.ball(id)
  var taken=not ball.is_empty() and not ball.active
  var opacity=1.0 if taken or not info.assigned else 0.50
  draw_circle(center+Vector2(1.5,2),BADGE_RADIUS+0.6,Color(0,0,0,0.65))
  draw_texture_rect(badge_texture(id),Rect2(center-Vector2.ONE*BADGE_RADIUS,Vector2.ONE*BADGE_RADIUS*2),false,Color(1,1,1,opacity))
  if id<16:
   var text=str(id)
   var width=bold.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
   draw_string(bold,center+Vector2(-width*0.5+0.8,5.5),text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(0.045,0.035,0.02,opacity))
  if taken:draw_arc(center,BADGE_RADIUS+1.0,0.12,PI-0.12,24,GOLD,1.3,true)

func _power_meter() -> void:
 draw_style_box(_style(Color(0.04,0.04,0.035,0.85),Color("9e947b"),12),Rect2(27,206,28,480))
 var height=clampf(game.power,0,1)*466
 draw_style_box(_style(Color("b8954d"),Color("e2cf96"),4),Rect2(33,680-height,16,height))
 draw_line(Vector2(24,680-height),Vector2(58,680-height),Color("e5ce96"),4)
func _spin_ball() -> void:
 var c=Vector2(1534,836)
 draw_circle(c,44,Color("151512"));draw_arc(c,44,0,TAU,64,Color("a9a38b"),1.7,true)
 draw_texture_rect(spin_texture,Rect2(c-Vector2.ONE*35,Vector2.ONE*70),false)
 draw_line(c-Vector2(33,0),c+Vector2(33,0),Color(0.3,0.3,0.25,0.45),1)
 draw_line(c-Vector2(0,33),c+Vector2(0,33),Color(0.3,0.3,0.25,0.45),1)
 draw_circle(c+game.spin*30,5,Color("c03727"))
func _style(bg: Color,border: Color,rounding: int) -> StyleBoxFlat:
 var s =StyleBoxFlat.new();s.bg_color=bg;s.border_color=border;s.set_border_width_all(1);s.set_corner_radius_all(rounding);return s
func _text(text: String,p: Vector2,size_font: int,color: Color) -> void:
 draw_string(bold,p,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_font,color)

func _page_panel(position_at: Vector2,dimensions: Vector2) -> Panel:
 var panel=_panel(position_at,dimensions);panel.reparent(front)
 return panel
func _icon_button(text: String,icon_name: String,position_at: Vector2,dimensions: Vector2,callback: Callable,parent: Node) -> Button:
 var button=_button(text,position_at,dimensions,callback,parent)
 button.icon=load("res://assets/ui/icons/"+icon_name+".svg");button.add_theme_constant_override("icon_max_width",28)
 button.alignment=HORIZONTAL_ALIGNMENT_LEFT
 return button
func _portrait(rival: Dictionary,outcome: String="") -> AtlasTexture:
 var path=str(rival.get("portrait_"+outcome,rival.portrait)) if not outcome.is_empty() else str(rival.portrait)
 if not ResourceLoader.exists(path):path=str(rival.portrait)
 if not atlas_cache.has(path):atlas_cache[path]=load(path)
 var atlas: Texture2D=atlas_cache[path];var texture=AtlasTexture.new();texture.atlas=atlas
 var width=atlas.get_width()/3.0;var height=atlas.get_height()/4.0
 texture.filter_clip=true
 texture.region=Rect2((int(rival.slot)%3)*width+13,(int(rival.slot)/3)*height+3,width-26,height-6)
 return texture
func _art(position_at: Vector2,dimensions: Vector2,parent: Node) -> TextureRect:
 var image=TextureRect.new();image.position=position_at;image.size=dimensions
 image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(image);return image
func _wrapped(text: String,position_at: Vector2,dimensions: Vector2,font_size: int,parent: Node,color: Color=LIGHT) -> Label:
 var label=_label(text,position_at,font_size,parent,color);label.size=dimensions
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return label
func _make_frontend():
 front=Control.new();front.size=Vector2(1600,900);add_child(front)
 front_bg=_art(Vector2.ZERO,Vector2(1600,900),front)
 front_bg.texture=load("res://assets/characters/title_hero.png");front_bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 front_music=_icon_button("","music",Vector2(1460,23),Vector2(48,45),func():game.toggle_music(),front)
 front_music.tooltip_text="Music on/off [N]"
 front_effects=_icon_button("","sound",Vector2(1520,23),Vector2(48,45),func():game.toggle_sound(),front)
 front_effects.tooltip_text="Sound effects on/off [M]"
 front_dim=ColorRect.new();front_dim.size=Vector2(1600,900);front_dim.color=Color(0.01,0.025,0.03,0.75);front_dim.mouse_filter=Control.MOUSE_FILTER_IGNORE;front.add_child(front_dim)
 title_page=Control.new();front.add_child(title_page)
 _label("QUIETBYTE",Vector2(910,130),25,title_page,GOLD)
 var title=_label("THE LAST",Vector2(910,157),43,title_page,LIGHT);title.add_theme_font_override("font",bold)
 var pocket=_label("POCKET",Vector2(900,210),87,title_page,GOLD);pocket.add_theme_font_override("font",display_font)
 pocket.add_theme_color_override("font_shadow_color",Color(0,0,0,0.7));pocket.add_theme_constant_override("shadow_offset_y",4)
 _label("A LITTLE CHARM. A LOT OF CHALK.",Vector2(914,335),18,title_page,GOLD)
 press_hint=_label("PRESS ANY KEY TO START",Vector2(935,412),23,title_page,LIGHT)
 _label("LOCAL VERSUS   /   THE CHAMPIONSHIP",Vector2(916,620),16,title_page,DIM)
 hub_page=Control.new();front.add_child(hub_page)
 _label("YOUR NEXT FRAME",Vector2(940,150),36,hub_page,GOLD)
 _label("Choose your company.",Vector2(943,207),21,hub_page,LIGHT)
 _icon_button("  LOCAL VERSUS", "players",Vector2(940,285),Vector2(470,76),func():show_setup(),hub_page)
 _icon_button("  VERSUS AI", "ai",Vector2(940,378),Vector2(470,76),show_ai,hub_page)
 _icon_button("  TOP TEN", "chart",Vector2(940,485),Vector2(228,55),show_board,hub_page)
 _icon_button("  QUIT", "close",Vector2(1183,485),Vector2(227,55),func():game.quit_game(),hub_page)
 _icon_button("  LOAD TOURNAMENT","chart",Vector2(940,562),Vector2(470,53),func():show_saves("load"),hub_page)
 ai_page=_page_panel(Vector2(800,145),Vector2(710,620))
 var ai_heading=_label("THE CHAMPIONSHIP",Vector2(36,30),31,ai_page,GOLD);ai_heading.add_theme_font_override("font",bold)
 _icon_button(" BACK","back",Vector2(540,27),Vector2(135,43),show_hub,ai_page)
 _wrapped("Every journey starts in Amateur. Win each frame to rise through the ranks.",Vector2(37,94),Vector2(625,62),21,ai_page,LIGHT)
 _label("YOUR NAME",Vector2(38,184),14,ai_page,DIM)
 ai_name=LineEdit.new();ai_name.position=Vector2(36,211);ai_name.size=Vector2(637,48);ai_name.max_length=18;ai_name.text="PLAYER 1";ai_page.add_child(ai_name)
 _icon_button("  START AMATEUR TOUR","trophy",Vector2(36,289),Vector2(637,72),func():game.launch_tournament(ai_name.text),ai_page)
 _icon_button("  LOAD TOURNAMENT","chart",Vector2(36,383),Vector2(637,54),func():show_saves("load"),ai_page)
 _wrapped("Saving is your choice: Pause → Save tournament.
Ten named slots. No automatic saves.",Vector2(38,451),Vector2(625,65),19,ai_page,GOLD)
 _wrapped("Rivals are revealed as you meet them. Three diamonds give you another chance.",Vector2(38,540),Vector2(625,53),17,ai_page,DIM)
 intro_panel=_page_panel(Vector2(220,95),Vector2(1160,720))
 intro_art=_art(Vector2(32,90),Vector2(440,570),intro_panel)
 intro_rank=_label("",Vector2(520,53),17,intro_panel,GOLD)
 intro_name=_label("",Vector2(520,98),34,intro_panel,LIGHT)
 intro_trait=_label("",Vector2(520,154),18,intro_panel,DIM)
 intro_quote=_wrapped("",Vector2(520,233),Vector2(585,170),29,intro_panel,GOLD)
 intro_gear=_wrapped("",Vector2(520,430),Vector2(585,70),17,intro_panel,DIM)
 intro_diamonds=_label("",Vector2(520,522),20,intro_panel,GOLD)
 _icon_button("  LET'S PLAY","play",Vector2(520,602),Vector2(415,62),func():game.begin_frame(),intro_panel)
 _icon_button(" JOURNEY","chart",Vector2(950,602),Vector2(155,62),show_journey,intro_panel)
 result_panel=_page_panel(Vector2(220,95),Vector2(1160,720))
 result_art=_art(Vector2(32,90),Vector2(440,570),result_panel)
 result_name=_label("",Vector2(520,30),19,result_panel,DIM)
 result_title=_label("",Vector2(520,70),36,result_panel,GOLD)
 result_quote=_wrapped("",Vector2(520,145),Vector2(585,155),27,result_panel,GOLD)
 result_text=_wrapped("",Vector2(520,322),Vector2(585,180),19,result_panel,LIGHT)
 result_action=_icon_button("","play",Vector2(520,525),Vector2(585,60),func():game.result_primary(),result_panel)
 result_end=_icon_button("END RUN & VIEW TOP TEN","chart",Vector2(520,603),Vector2(585,48),func():game.end_tournament(),result_panel)
 intro_save=_icon_button(" SAVE","save",Vector2(950,24),Vector2(155,38),func():show_saves("save"),intro_panel)
 result_save=_icon_button(" SAVE","save",Vector2(950,24),Vector2(155,38),func():show_saves("save"),result_panel)
 _make_journey()
 board_panel=_page_panel(Vector2(340,75),Vector2(920,750))
 _label("THE TOP TEN",Vector2(44,28),36,board_panel,GOLD)
 _label("Best championship run per player · saved on this PC",Vector2(46,82),16,board_panel,DIM)
 _label("PLAYER",Vector2(110,137),15,board_panel,DIM);_label("WINS",Vector2(560,137),15,board_panel,DIM);_label("POINTS",Vector2(695,137),15,board_panel,DIM)
 for i in range(10):
  var row=_label("",Vector2(46,177+i*43),22,board_panel,LIGHT);row.size=Vector2(480,40);board_rows.append(row)
  board_wins.append(_label("",Vector2(560,177+i*43),22,board_panel,DIM))
  board_points.append(_label("",Vector2(695,177+i*43),22,board_panel,GOLD))
 _icon_button(" BACK","back",Vector2(45,665),Vector2(830,48),show_hub,board_panel)
 front.move_child(front_music,front.get_child_count()-1);front.move_child(front_effects,front.get_child_count()-1)
func _front_update():
 front.visible=game.state in ["title","menu","intro","result","journey"]
 front_bg.visible=game.state in ["title","menu"]
 front_dim.visible=game.state in ["intro","result","journey"]
 title_page.visible=game.state=="title";hub_page.visible=game.state=="menu" and menu_page=="hub"
 ai_page.visible=game.state=="menu" and menu_page=="ai"
 board_panel.visible=game.state=="menu" and menu_page=="board"
 journey_panel.visible=game.state=="journey"
 intro_panel.visible=game.state=="intro";result_panel.visible=game.state=="result"
 intro_save.visible=game.campaign.kind=="tournament";result_save.visible=game.campaign.kind=="tournament"
 if is_instance_valid(press_hint):press_hint.modulate.a=0.48+0.52*(0.5+0.5*sin(game.play_time*3.4))
 front_music.modulate=Color.WHITE if game.music_enabled else Color(0.40,0.40,0.40)
 front_effects.modulate=Color.WHITE if game.sound_enabled else Color(0.40,0.40,0.40)
 if front.visible and not menu.visible and front.get_index()!=get_child_count()-1:move_child(front,get_child_count()-1)
 # The setup panel predates the hero backdrop and must draw in front of it.
 if menu.visible:move_child(menu,get_child_count()-1)
func show_hub():
 game.state="menu";menu_page="hub";game._play_sound("ui_back",0.3)
func show_setup():
 game.state="menu";menu_page="setup";play_kind="local"
func show_ai():
 game.state="menu";menu_page="ai";ai_name.text=game.rules.names[0]
func show_intro():
 var rival=game.campaign.rival();intro_art.texture=_portrait(rival)
 var tier=game.campaign.tier()
 intro_rank.text="%s  /  RIVAL %02d OF 12" % [game.Campaign.TIERS[tier].to_upper(),int(rival.slot)+1]
 intro_name.text=rival.name;intro_trait.text=rival.personality
 intro_quote.text='“'+str(rival.quote)+'”'
 intro_gear.text=game.Campaign.EQUIPMENT[tier]
 intro_diamonds.text=("◆ ".repeat(game.campaign.diamonds)+"   %06d POINTS" % game.campaign.points) if game.campaign.kind=="tournament" else "SINGLE FRAME  /  "+game.rules.MODES[game.rules.mode]
func show_result():
 var won=game.rules.winner==0
 result_art.texture=_portrait(game.campaign.rival(),"loss" if won else "win") if game.campaign.kind!="local" else load("res://assets/characters/title_hero.png")
 result_title.text="FRAME WON!" if won else "FRAME LOST"
 result_name.text=game.campaign.rival().name if game.campaign.kind=="tournament" else "LOCAL VERSUS"
 result_quote.text="“"+str(game.campaign.rival().get("result_loss_quote" if won else "result_win_quote","Good frame!"))+"”" if game.campaign.kind=="tournament" else "Another frame? The table is ready."
 if game.campaign.kind=="tournament":
  result_end.text="END RUN & VIEW TOP TEN"
  if game.campaign.wins==48:
   result_title.text="THE GREATEST!";result_text.text="All 48 rivals defeated.
Four clubs conquered.

%06d POINTS
%d unused diamonds — a fine finish." % [game.campaign.points,game.campaign.diamonds]
  else:
   result_text.text=("%s defeated.

%s" % [game.campaign.rival().name,"A new club and better equipment await." if game.campaign.wins%12==0 else "One more name off the chalkboard."]) if won else "%s takes this frame.

Spend one diamond to retry this rival, or end your run and record your score." % game.campaign.rival().name
   result_text.text+="

%06d POINTS  /  %d WINS
%d RETRY DIAMONDS" % [game.campaign.points,game.campaign.wins,game.campaign.diamonds]
  result_action.text="VIEW TOP TEN" if game.campaign.finished else ("NEXT RIVAL" if won else "◆  RETRY FRAME — 1 DIAMOND")
  result_end.visible=not game.campaign.finished;result_action.disabled=false
 else:
  result_title.text=game.rules.names[game.rules.winner]+" WINS"
  result_text.text="A fine frame. The chalk is ready for another."
  result_action.text="REMATCH";result_action.disabled=false;result_end.visible=true;result_end.text="RETURN TO MENU"
func show_board():
 game.state="menu";menu_page="board"
 for i in range(10):
  var line="%02d     —" % (i+1)
  if i<game.leaderboard.entries.size():
   var row=game.leaderboard.entries[i]
   line="%02d     %s" % [i+1,row.name]
   board_wins[i].text="%02d / 48" % row.wins;board_points[i].text="%06d" % row.points
  if i>=game.leaderboard.entries.size():board_wins[i].text="";board_points[i].text=""
  board_rows[i].text=line

func _wood_surface(at: Vector2,dimensions: Vector2,parent: Node,darkness: float=0.7) -> TextureRect:
 var image=_art(at,dimensions,parent);image.texture=load("res://assets/materials/walnut.png");image.stretch_mode=TextureRect.STRETCH_SCALE;image.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 var shader=Shader.new();shader.code="""shader_type canvas_item; render_mode unshaded;
uniform vec2 size_px=vec2(600.0,80.0);
uniform float darkness=0.7;
void fragment(){
 vec2 p=UV*size_px;vec2 q=abs(p-size_px*0.5)-(size_px*0.5-12.0);
 float d=length(max(q,vec2(0.0)))+min(max(q.x,q.y),0.0)-12.0;
 vec3 wood=texture(TEXTURE,UV*vec2(1.7,1.0)).rgb;
 wood=wood*darkness*vec3(0.9,0.72,0.52);
 float edge=1.0-smoothstep(1.0,3.5,-d);
 wood=mix(wood,vec3(0.55,0.36,0.15),edge*0.75);
 wood+=vec3(0.10,0.07,0.03)*(1.0-UV.y)*0.35;
 COLOR=vec4(wood,1.0-smoothstep(-0.8,0.8,d));
}
"""
 var material=ShaderMaterial.new();material.shader=shader;material.set_shader_parameter("size_px",dimensions);material.set_shader_parameter("darkness",darkness);image.material=material
 return image
func _wood_button(text: String,icon: String,at: Vector2,dimensions: Vector2,action: Callable,parent: Node) -> Button:
 _wood_surface(at,dimensions,parent)
 var button=_icon_button(text,icon,at,dimensions,action,parent)
 button.add_theme_font_override("font",bold);button.add_theme_font_size_override("font_size",20)
 button.add_theme_color_override("font_shadow_color",Color(0,0,0,0.85));button.add_theme_constant_override("shadow_offset_y",2)
 for state in ["normal","hover","pressed","focus"]:
  var style=_style(Color(0,0,0,0.06) if state=="normal" else Color(0.85,0.65,0.3,0.10),Color(0.7,0.52,0.25,0.6) if state=="normal" else GOLD,12)
  style.content_margin_left=22;style.content_margin_right=15;button.add_theme_stylebox_override(state,style)
 return button
func _center_hud(text: String,x: float,y: float,font_size: int,color: Color):
 var width=bold.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
 draw_string(bold,Vector2(x-width*0.5,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func _face(rival: Dictionary={}) -> Texture2D:
 var key="hero" if rival.is_empty() else str(rival.id)
 if face_cache.has(key):return face_cache[key]
 var texture=AtlasTexture.new();texture.filter_clip=true
 if rival.is_empty():
  texture.atlas=load("res://assets/characters/title_hero.png");texture.region=Rect2(320,5,255,255)
 else:
  var portrait=_portrait(rival);texture.atlas=portrait.atlas
  var region=portrait.region
  texture.region=Rect2(region.position+Vector2(region.size.x*0.17,0),Vector2.ONE*region.size.x*0.66)
 face_cache[key]=texture;return texture
func _make_profiles():
 var shader=Shader.new();shader.code="""shader_type canvas_item; render_mode unshaded;
varying vec2 local_uv;
void vertex(){local_uv=VERTEX/vec2(60.0);}
void fragment(){vec4 c=texture(TEXTURE,UV);float a=1.0-smoothstep(0.47,0.5,length(local_uv-vec2(0.5)));COLOR=vec4(c.rgb,c.a*a);}
"""
 var material=ShaderMaterial.new();material.shader=shader
 for x in [20,1020]:
  var panel=Panel.new();panel.position=Vector2(x,16);panel.size=Vector2(64,64);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(panel)
  var image=_art(Vector2(2,2),Vector2(60,60),panel);image.stretch_mode=TextureRect.STRETCH_SCALE;image.material=material
  profile_panels.append(panel);profile_images.append(image)
func _sync_profiles():
 var visible_now=game.state in ["aim","rolling","paused"] or (game.state=="title" and game.prewarm_frames>0)
 for panel in profile_panels:panel.visible=visible_now
 var stamp=str([game.campaign.kind,game.campaign.rival_index,game.rules.player,game.state])
 if stamp==profile_stamp:return
 profile_stamp=stamp
 profile_images[0].texture=_face()
 profile_images[1].texture=_face(game.campaign.rival()) if game.campaign.kind=="tournament" else _face()
 profile_images[1].flip_h=game.campaign.kind=="local"
 for i in range(2):
  var style=_style(Color("121c1d"),GOLD if game.rules.player==i else Color("597075"),32)
  style.set_border_width_all(2);profile_panels[i].add_theme_stylebox_override("panel",style)
func _make_journey():
 journey_panel=_page_panel(Vector2(210,70),Vector2(1180,760))
 journey_title=_label("YOUR JOURNEY",Vector2(35,26),32,journey_panel,GOLD);journey_title.add_theme_font_override("font",bold)
 _icon_button(" BACK","back",Vector2(1000,27),Vector2(145,45),close_journey,journey_panel)
 journey_summary=_label("",Vector2(38,85),18,journey_panel,LIGHT)
 journey_path=_label("",Vector2(38,119),13,journey_panel,GOLD)
 journey_scroll=ScrollContainer.new();journey_scroll.position=Vector2(34,156);journey_scroll.size=Vector2(1110,517);journey_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;journey_panel.add_child(journey_scroll)
 journey_grid=GridContainer.new();journey_grid.columns=4;journey_grid.add_theme_constant_override("h_separation",12);journey_grid.add_theme_constant_override("v_separation",14);journey_scroll.add_child(journey_grid)
 _label("Only rivals you have met appear here. Keep winning to reveal the next.",Vector2(38,704),17,journey_panel,DIM)
func show_journey():
 if game.campaign.kind!="tournament":return
 journey_return=game.state;journey_return_page=menu_page
 game._invalidate_ai();game._stop_spoken();game.state="journey"
 journey_ids.clear()
 for node in journey_grid.get_children():node.free()
 var revealed=game.campaign.revealed_rivals()
 journey_title.text="YOUR JOURNEY  /  "+game.Campaign.TIERS[game.campaign.tier()].to_upper()
 journey_summary.text="%d victories   ·   %06d points   ·   %d continue diamonds" % [game.campaign.wins,game.campaign.points,game.campaign.diamonds]
 var path=[]
 for rank in range(game.campaign.tier()+1):path.append(game.Campaign.TIERS[rank]+(" · Cleared" if rank<game.campaign.tier() or game.campaign.wins==48 else " · Current"))
 journey_path.text="  ›  ".join(path)
 for rival in revealed:
  journey_ids.append(int(rival.id))
  var card=Panel.new();card.custom_minimum_size=Vector2(261,190);journey_grid.add_child(card)
  card.add_theme_stylebox_override("panel",_style(Color("14252a"),GOLD if rival.status=="Current rival" else Color("3c5557"),10))
  var picture=_art(Vector2(12,16),Vector2(74,86),card);picture.texture=_face(rival)
  var name=_wrapped(rival.name,Vector2(99,19),Vector2(148,55),19,card,LIGHT);name.add_theme_font_override("font",bold)
  _label("FRAME %02d" % (int(rival.id)+1),Vector2(100,81),12,card,DIM)
  _label(rival.status.to_upper(),Vector2(15,121),14,card,GOLD if rival.defeated else Color("8cdbc4"))
  var attempts=int(rival.losses)+(1 if rival.defeated else 0)
  var detail="%s · %d %s" % [game.Campaign.TIERS[int(rival.tier)],attempts,"attempt" if attempts==1 else "attempts"] if rival.losses>0 else game.Campaign.TIERS[int(rival.tier)]
  _label(detail,Vector2(15,151),14,card,DIM)
 if journey_grid.get_child_count()>0:_focus_journey_card(journey_grid.get_child(journey_grid.get_child_count()-1))
func close_journey():
 if game.state!="journey":return
 game.state=journey_return;menu_page=journey_return_page
 game._play_sound("ui_back",0.3)

func _focus_journey_card(card: Control):
 await get_tree().process_frame
 await get_tree().process_frame
 if game.state=="journey" and is_instance_valid(card):journey_scroll.ensure_control_visible(card)
