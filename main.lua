local function getQuad(axis_x,axis_y,vert_x,vert_y)
	if vert_x < axis_x then
		if vert_y < axis_y then
			return 1
		else
			return 4
		end
	else
		if vert_y < axis_y then
			return 2
		else
			return 3
		end	
	end
end
local function pointInPolygon(pgon, tx, ty)
	if (#pgon < 6) then
		return false
	end
 
	local x1 = pgon[#pgon - 1]
	local y1 = pgon[#pgon]
	local cur_quad = getQuad(tx,ty,x1,y1)
	local next_quad
	local total = 0
	local i
 
	for i = 1,#pgon,2 do
		local x2 = pgon[i]
		local y2 = pgon[i+1]
		next_quad = getQuad(tx,ty,x2,y2)
		local diff = next_quad - cur_quad
 
		if (diff == 2) or (diff == -2) then
			if (x2 - (((y2 - ty) * (x1 - x2)) / (y1 - y2))) < tx then
				diff = -diff
			end
		elseif diff == 3 then
			diff = -1
		elseif diff == -3 then
			diff = 1
		end
 
		total = total + diff

    cur_quad = next_quad
		x1 = x2
		y1 = y2
	end
 
	return (math.abs(total)==4)
end

local sw, sh = love.graphics.getDimensions()
local cw, ch = 1280, 960
local sc = 2/3

local arrow = love.mouse.getSystemCursor("arrow")
local hand = love.mouse.getSystemCursor("hand")

local n_cubes = 0
local text = ""

local n = {}
n.play = function(name)
  --print(name, "||", n[name].current)
  n[name][n[name].current]:play()
  n[name].current = n[name].current + 1
  if n[name].current > 10 then
    n[name].current = 1
  end
end
do
  local notes = {
    "fa1", "sol1", "la1", "si1", "do1", "re1", "mi1",
    "fa2", "sol2", "la2", "si2", "do2", "re2", "mi2",
    "fa3", "sol3", "la3", "si3", "do3", "re3"
  }

  for i, v in ipairs(notes) do
    n[v] = {current=1}
    for j = 1, 10 do
      n[v][j] = love.audio.newSource("note/"..v..".mp3", "static")
    end
  end
end
local queue = {}
queue.add = function(name, delay)
  queue[#queue+1] = {name=name, t=delay}
end

local current = "menu"
local room = {}
function room.new(str)
  return {polygon={}, image=love.graphics.newImage("image/"..str)}
end
room["menu"] = room.new("menu.png")
room["menu"].polygon[1] = {450, 510, 450, 660, 850, 660, 850, 510, type="move", what="panoramica"}

room["panoramica"] = room.new("panoramica.jpg")
room["panoramica"].left = "scrivania"
room["panoramica"].right = "letto"
--room["panoramica"].back = "armadione"

room["scrivania"] = room.new("scrivania.jpg")
room["scrivania"].left = "porta"
room["scrivania"].right = "lavagna"
room["scrivania"].back = "panoramica"
table.insert(room["scrivania"].polygon, {260, 60, 300, 770, 790, 320, 450, 40, type="move", what="computer"})
table.insert(room["scrivania"].polygon, {930, 400, 890, 550, 1010, 560, 1070, 460, type="move", what="fogli"})

room["computer"] = room.new("computer.jpg")
room["computer"].back = "scrivania"

room["fogli"] = room.new("fogli.jpg")
room["fogli"].back = "scrivania"

room["letto"] = room.new("letto.jpg")
room["letto"].left = "mobile"
room["letto"].right = "armadione"
room["letto"].back = "panoramica"
table.insert(room["letto"].polygon, {710, 520, 920, 680, 910, 910, 1130, 860, 1040, 570, type="move", what="vestiti"})

room["vestiti"] = room.new("vestiti.jpg")
room["vestiti"].back = "letto"

room["porta"] = room.new("porta chiusa.jpg")
room["porta"].left = "armadione"
room["porta"].right = "scrivania"
table.insert(room["porta"].polygon, {200, 40, 200, 880, 600, 880, 600, 40, type="event", what="porta"})

room["armadione"] = room.new("armadione.jpg")
room["armadione"].left = "letto"
room["armadione"].right = "porta"
--room["armadione"].back = "panoramica"

room["mobile"] = room.new("mobile.jpg")
room["mobile"].left = "altra scrivania"
room["mobile"].right = "letto"
table.insert(room["mobile"].polygon, {400, 650, 400, 930, 580, 930, 580, 650, type="move", what="cassetti"})
table.insert(room["mobile"].polygon, {400, 100, 420, 320, 670, 320, 670, 100, type="move", what="pupazzi"})

room["cassetti"] = room.new("cassetti.jpg")
room["cassetti"].right = "mobile"
table.insert(room["cassetti"].polygon, {540, 820, 540, 1000, 700, 1000, 700, 820, type="event", what="chiave"})

room["pupazzi"] = room.new("pupazzi.jpg")
room["pupazzi"].back = "mobile"
table.insert(room["pupazzi"].polygon, {1150, 100, 790, 400, 1070, 430, 1260, 260, type="event", what="inizio corvo"})

room["altra scrivania"] = room.new("altra scrivania.jpg")
room["altra scrivania"].left = "finestra"
room["altra scrivania"].right = "mobile"
room["altra scrivania"].back = "presa"
table.insert(room["altra scrivania"].polygon, {170, 10, 170, 170, 1000, 170, 1000, 10, type="move", what="libri"})
table.insert(room["altra scrivania"].polygon, {330, 400, 200, 740, 960, 730, 880, 400, type="move", what="tastiera"})

room["presa"] = room.new("presa staccata.jpg")
room["presa"].back = "altra scrivania"
table.insert(room["presa"].polygon, {625.5, 298.5, 784.5, 303, 777, 394.5, 622.5, 387, type="event", what="presa_collegata"})

room["libri"] = room.new("libri.jpg")
room["libri"].back = "altra scrivania"
table.insert(room["libri"].polygon, {204,118.5,307.5,120,376.5,640.5,274.5,636, type="move", what="divina"})

room["divina"] = room.new("dante.jpg")
room["divina"].back = "libri"
table.insert(room["divina"].polygon, {286.5,342,738,252,867,792,286.5,769.5, type="event", what="commedia_aperta"})

room["tastiera"] = room.new("tastiera.jpg")
room["tastiera"].back = "altra scrivania"
table.insert(room["tastiera"].polygon, {42, 226, 0, 340, 0, 488, 90, 210, type="event", what="fa1"})
table.insert(room["tastiera"].polygon, {107, 226, 17, 484, 74, 484, 130, 221, type="event", what="sol1"})
table.insert(room["tastiera"].polygon, {159, 221, 84, 480, 138, 487, 197, 223, type="event", what="la1"})
table.insert(room["tastiera"].polygon, {224, 223, 156, 480, 203, 488, 257, 226, type="event", what="si1"})
table.insert(room["tastiera"].polygon, {275, 211, 221, 485, 275, 482, 311, 216, type="event", what="do1"})
table.insert(room["tastiera"].polygon, {339, 211, 291, 487, 342, 485, 374, 221, type="event", what="re1"})
table.insert(room["tastiera"].polygon, {399, 213, 361, 475, 412, 482, 431, 221, type="event", what="mi1"})
table.insert(room["tastiera"].polygon, {448, 223, 428, 480, 471, 477, 482, 231, type="event", what="fa2"})
table.insert(room["tastiera"].polygon, {503, 224, 490, 474, 537, 475, 529, 229, type="event", what="sol2"})
table.insert(room["tastiera"].polygon, {562, 228, 552, 482, 604, 482, 593, 229, type="event", what="la2"})
table.insert(room["tastiera"].polygon, {619, 220, 619, 482, 666, 479, 642, 228, type="event", what="si2"})
table.insert(room["tastiera"].polygon, {658, 226, 681, 474, 728, 474, 692, 234, type="event", what="do2"})
table.insert(room["tastiera"].polygon, {722, 216, 748, 469, 787, 479, 749, 226, type="event", what="re2"})
table.insert(room["tastiera"].polygon, {775, 224, 810, 475, 852, 475, 808, 228, type="event", what="mi2"})
table.insert(room["tastiera"].polygon, {821, 220, 867, 474, 915, 467, 852, 220, type="event", what="fa3"})
table.insert(room["tastiera"].polygon, {878, 224, 930, 471, 976, 475, 904, 226, type="event", what="sol3"})
table.insert(room["tastiera"].polygon, {937, 221, 997, 471, 1043, 471, 963, 224, type="event", what="la3"})
table.insert(room["tastiera"].polygon, {987, 220, 1056, 469, 1103, 471, 1017, 218, type="event", what="si3"})
table.insert(room["tastiera"].polygon, {1033, 221, 1119, 472, 1166, 474, 1072, 226, type="event", what="do3"})
table.insert(room["tastiera"].polygon, {1088, 220, 1183, 466, 1222, 475, 1124, 224, type="event", what="re3"})

room["finestra"] = room.new("finestra.jpg")
room["finestra"].left = "libreria"
room["finestra"].right = "altra scrivania"

room["libreria"] = room.new("libreria.jpg")
room["libreria"].left = "lavagna"
room["libreria"].right = "finestra"

room["lavagna"] = room.new("11.jpg")
room["lavagna"].left = "scrivania"
room["lavagna"].right = "libreria"
table.insert(room["lavagna"].polygon, {735,405,787.5,406.5,789,453,735,456, type="event", what="spalla_dx"})
table.insert(room["lavagna"].polygon, {981,408,1042.5,406.5,1047,451.5,991.5,454.5, type="event", what="spalla_sx"})
table.insert(room["lavagna"].polygon, {732,555,799.5,558,799.5,595.5,747,600, type="event", what="gomito_dx_giu"})
table.insert(room["lavagna"].polygon, {1008,558,1069.5,561,1069.5,598.5,1018.5,600, type="event", what="gomito_sx_giu"})
table.insert(room["lavagna"].polygon, {660,283.5,750,282,762,327,670.5,343.5, type="event", what="gomito_dx_su"})
table.insert(room["lavagna"].polygon, {1021.5,276,1092,277.5,1074,342,1018.5,334.5, type="event", what="gomito_sx_su"})

local pupazzi = 0

local is_hand = false
local sprangato = false
local spranga_t = 0
local barbero_img = love.graphics.newImage("image/barbero.png")

local event = {}

local chiave = false
local porta = false
local porta_t = 0

local cassetti_img = {
  love.graphics.newImage("image/cassetti1.jpg"),
  love.graphics.newImage("image/cassetti2.jpg"),
  love.graphics.newImage("image/cassetti3.jpg"),
  love.graphics.newImage("image/cassetti chiave.png"),
  love.graphics.newImage("image/cassetti4.png"),
}

local porta_img = {
  love.graphics.newImage("image/porta chiave.jpg"),
  love.graphics.newImage("image/porta poco aperta.jpg"),
  love.graphics.newImage("image/porta molto aperta.jpg"),
}

local cube = {n=1, t=0}
cube.image = {
  love.graphics.newImage("image/cube1w.png"),
  love.graphics.newImage("image/cube2w.png"),
  love.graphics.newImage("image/cube3w.png"),
  love.graphics.newImage("image/cube4w.png"),
  love.graphics.newImage("image/cube5w.png"),
  love.graphics.newImage("image/cube6w.png")
}
for i = 1, 8 do
  local n = love.math.random(1, 6)
  local x = love.math.random(1, cw)
  local y = love.math.random(0-20, ch-20)
  local t = love.math.random()/3
  cube[#cube+1] = {n=n, x=x, y=y, t=t}
end
local play_img = love.graphics.newImage("image/play.png")

local musica = {"d","r","d","m","m","r","d","r","s","s","r","m","r","f","f","s","l","s"}
local progresso = 0

local cassetto = false
local cassetto_t = 0

local cassetto_img = love.graphics.newImage("image/yee.jpg")

local corvo_img = {
  love.graphics.newImage("image/corvo 1.jpg"),
  love.graphics.newImage("image/corvo 2.jpg"),
  love.graphics.newImage("image/corvo 3.jpg"),
  love.graphics.newImage("image/corvo 4.jpg"),
  love.graphics.newImage("image/corvo 5.jpg"),
  love.graphics.newImage("image/corvo 6.jpg"),
  love.graphics.newImage("image/corvo 7.jpg"),
  love.graphics.newImage("image/corvo 8.jpg"),
  love.graphics.newImage("image/corvo 9.jpg")
}
local corvo = 0
local cubo_corvo = false
local cubo_corvo_t = 0

local collegato_a_corrente = false

local presa_img = {
  love.graphics.newImage("image/presa staccata.jpg"),
  love.graphics.newImage("image/presa attaccata.jpg")
}

local commedia_n = 0
commedia_img = love.graphics.newImage("image/spranga.jpg")

local scheletro_img = {}
for dx = 1, 4 do
  for dy = 1, 4 do
    scheletro_img[dx*10+dy] = love.graphics.newImage("image/"..dx..dy..".jpg")
  end
end
local scheletro = {spalla_dx=0, spalla_sx=0, gomito_dx=0, gomito_sx=0}

local ymca_fill = 0
local ymca_start = false
local ymca_t = 0

function love.update(dt)
  --print(current)
  if love.keyboard.isDown("escape") then
    love.event.quit()
  end

  for i = #queue, 1, -1 do
    if queue[i].t <= 0 then
      n.play(queue[i].name)
      table.remove(queue, i)
    end
  end

  for i = 1, #queue do
    queue[i].t = queue[i].t - dt
  end

  cube.t = cube.t + dt
  if cube.t > 0.5 then
    cube.t = cube.t - 0.5
    cube.n = cube.n + 1
    if cube.n > 6 then cube.n = cube.n - 6 end
  end

  if current == "menu" then
    for ic, c in ipairs(cube) do
      c.y = c.y + 50*dt
      if c.y > ch + 20 then
        c.y = -20
        c.x = love.math.random(1, cw)
      end
      c.t = c.t + dt
      if c.t > 1/3 then
        c.t = c.t - 1/3
        c.n = c.n + 1
        if c.n > 6 then c.n = c.n - 6 end
      end
    end
  end

  if current == "computer" then
    if text == "s  p  r  a  n  g  a  " then
      if sprangato == false then
        sprangato = true
        n_cubes = n_cubes + 1
      end
    end
  end

  if event[1] then
    if event[1] == "chiave" then
      if n_cubes == 4 then
        n_cubes = 5
        chiave = true
      end
    end

    if event[1] == "porta" then
      if chiave then
        porta = true
      end
    end

    local nota=false
    if collegato_a_corrente then
      if event[1] == "fa1" then queue.add("fa1", 0); nota="f" end
      if event[1] == "sol1" then queue.add("sol1", 0); nota="s" end
      if event[1] == "la1" then queue.add("la1", 0); nota="l" end
      if event[1] == "si1" then queue.add("si1", 0); nota="s" end
      if event[1] == "do1" then queue.add("do1", 0); nota="d" end
      if event[1] == "re1" then queue.add("re1", 0); nota="r" end
      if event[1] == "mi1" then queue.add("mi1", 0); nota="m" end
      if event[1] == "fa2" then queue.add("fa2", 0); nota="f" end
      if event[1] == "sol2" then queue.add("sol2", 0); nota="s" end
      if event[1] == "la2" then queue.add("la2", 0); nota="l" end
      if event[1] == "si2" then queue.add("si2", 0); nota="s" end
      if event[1] == "do2" then queue.add("do2", 0); nota="d" end
      if event[1] == "re2" then queue.add("re2", 0); nota="r" end
      if event[1] == "mi2" then queue.add("mi2", 0); nota="m" end
      if event[1] == "fa3" then queue.add("fa3", 0); nota="f" end
      if event[1] == "sol3" then queue.add("sol3", 0); nota="s" end
      if event[1] == "la3" then queue.add("la3", 0); nota="l" end
      if event[1] == "si3" then queue.add("si3", 0); nota="s" end
      if event[1] == "do3" then queue.add("do3", 0); nota="d" end
      if event[1] == "re3" then queue.add("re3", 0); nota="r" end
    end
    if nota then
      --print(progresso, nota, musica[progresso+1])
      if nota == musica[progresso+1] then
        progresso = progresso + 1
        --print(progresso)
        if progresso == 18 and not cassetto then
          cassetto = true
          n_cubes = n_cubes + 1
        end
      else
        progresso = 0
      end
    end

    if event[1] == "inizio corvo" and corvo == 0 then
      corvo = corvo + 1
    end

    if event[1] == "presa_collegata" then
      collegato_a_corrente = true
    end

    if event[1] == "commedia_aperta" then
      commedia_n = 1
    end

    if event[1] == "spalla_dx" then
      scheletro.spalla_dx = 1 - scheletro.spalla_dx
    end
    if event[1] == "spalla_sx" then
      scheletro.spalla_sx = 1 - scheletro.spalla_sx
    end
    if event[1] == "gomito_dx_giu" and scheletro.spalla_dx==0 then
      scheletro.gomito_dx = 1 - scheletro.gomito_dx
    end
    if event[1] == "gomito_dx_su" and scheletro.spalla_dx==1 then
      scheletro.gomito_dx = 1 - scheletro.gomito_dx
    end
    if event[1] == "gomito_sx_giu" and scheletro.spalla_sx==0 then
      scheletro.gomito_sx = 1 - scheletro.gomito_sx
    end
    if event[1] == "gomito_sx_su" and scheletro.spalla_sx==1 then
      scheletro.gomito_sx = 1 - scheletro.gomito_sx
    end

    table.remove(event, 1)
  end
  --print(progresso)
  if sprangato then
    spranga_t = spranga_t + dt
  end

  if porta then
    porta_t = porta_t + dt
  end

  if cassetto then
    cassetto_t = cassetto_t + dt
  end

  if cubo_corvo then
    cubo_corvo_t = cubo_corvo_t + dt
  end

  if ymca_start then
    ymca_t = ymca_t + dt
  end

  is_hand = false
  local mx, my = love.mouse.getPosition()
  mx, my = mx/sc, my/sc
  for ip, p in ipairs(room[current].polygon) do
    if pointInPolygon(p, mx, my) then
      is_hand = true
    end
  end
  if room[current].left and 10 <= mx and mx <= 180 and 10 <= my and my <= 750 then
    is_hand = true
  end
  if room[current].right and cw-180 <= mx and mx <= cw-10 and 10 <= my and my <= 750 then
    is_hand = true
  end
  if room[current].back and 10 <= mx and mx <= cw-10 and 800 <= my and my <= ch-10 then
    is_hand = true
  end

  if is_hand then
    love.mouse.setCursor(hand)
  else
    love.mouse.setCursor(arrow)
  end
end

function love.keypressed(key, scancode, isrepeat)
  if current == "computer" then
    if #text <= 20 then
      local key_table = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
      for ik, k in ipairs(key_table) do
        if key == k then
          text = text .. k .. "  "
        end
      end
    end
    if key == "backspace" then
      text = text:sub(1, -2)
      text = text:sub(1, -2)
      text = text:sub(1, -2)
    end
  end

  --if key == "tab" then
  --  n_cubes = n_cubes + 1
  --end

  if key == "space" then
    local mx, my = love.mouse.getPosition()
    mx, my = mx/sc, my/sc
    --print(mx, my)
  end
end



function love.mousepressed(x, y, button, istouch, presses)
  x = x/sc
  y = y/sc
  for ip, p in ipairs(room[current].polygon) do
    if pointInPolygon(p, x, y) then
      if p.type == "move" then
        current = p.what
      elseif p.type == "event" then
        table.insert(event, p.what)
      end
    end
  end

  if room[current].left then
    if 10 <= x and x <= 180 and 10 <= y and y <= 750 then
      current = room[current].left
    end
  end

  if room[current].right then
    if cw-180 <= x and x <= cw-10 and 10 <= y and y <= 750 then
      current = room[current].right
    end
  end

  if room[current].back then
    if 10 <= x and x <= cw-10 and 800 <= y and y <= ch-10 then
      current = room[current].back
    end
  end

  if current == "pupazzi" and corvo > 0 and corvo < 9 then
    corvo = corvo + 1
    if corvo == 9 then
      cubo_corvo = true
      n_cubes = n_cubes + 1
    end
  end
end

local canvas = love.graphics.newCanvas(cw, ch)
local font = love.graphics.newFont(55)
love.graphics.setFont(font)
function love.draw()
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0)

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(room[current].image)

  if current == "menu" then
    for ic, c in ipairs(cube) do
      love.graphics.draw(cube.image[c.n], c.x, c.y, 0, 0.5)
    end

    local img = cube.image[cube.n]
    love.graphics.draw(img, cw/2, 600, 0, 1.2, 1.2, img:getWidth()/2, img:getHeight()/2)
    love.graphics.draw(play_img, cw/2, 600, 0, 0.8, 0.8, play_img:getWidth()/2, play_img:getHeight()/2)
  end


  if current == "computer" then
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(text, 470, 260)

    if sprangato then
      if spranga_t < 1 then
        local r = love.math.random()
        local g = love.math.random()
        local b = love.math.random()
        local x = love.math.random()*10-5
        local y = love.math.random()*10-5
        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.draw(barbero_img, 100+x, y)
      elseif spranga_t < 5 then
        love.graphics.setColor(1, 1, 1, 1 - (spranga_t-1)/5)
        love.graphics.draw(cube.image[cube.n], 500, 340, 0, 2, 2)
      end
    end
  end

  if current == "cassetti" then
    if n_cubes > 0 then
      love.graphics.draw(cassetti_img[n_cubes])
    end
  end 

  if current == "tastiera" then
    if cassetto then
      if cassetto_t < 5 then
        love.graphics.draw(cassetto_img)
      end
      if cassetto_t < 5 then
        love.graphics.setColor(1, 1, 1, 1 - (cassetto_t-1)/5)
        local img = cube.image[cube.n]
        love.graphics.draw(img, 912, 694, 0, 1, 1, img:getWidth()/2, img:getHeight()/2)
      end
    end
  end

  love.graphics.setColor(1, 1, 1)
  if current == "porta" then
    if porta then
      if porta_t < 0.5 then
        love.graphics.draw(porta_img[1])
      elseif porta_t < 1 then
        love.graphics.draw(porta_img[2])
      elseif porta_t < 2 then
        love.graphics.draw(porta_img[3])
      else
        current = "menu"
      end
    end
  end

  love.graphics.setColor(1, 1, 1)
  if current == "pupazzi" then
    if corvo > 0 then
      love.graphics.draw(corvo_img[corvo])
    end

    if corvo == 9 then
      if cubo_corvo_t < 5 then
        love.graphics.setColor(1, 1, 1, 1 - (cubo_corvo_t-1)/5)
        local img = cube.image[cube.n]
        love.graphics.draw(img, 550, 830, 0, 1, 1, img:getWidth()/2, img:getHeight()/2)
      end
    end
  end

  if current == "presa" then
    if collegato_a_corrente then
      love.graphics.draw(presa_img[2])
    end
  end

  if current == "divina" then
    if commedia_n == 1 then
      love.graphics.draw(commedia_img)
    end
  end

  if current == "lavagna" then
    local dx = 1 + 2*scheletro.spalla_dx + scheletro.gomito_dx
    local sx = 1 + 2*scheletro.spalla_sx + scheletro.gomito_sx
    local str = dx*10 + sx
    if ymca_fill==0 and str==33 then
      ymca_fill=1
    end
    if ymca_fill==1 and str==44 then
      ymca_fill=2
    end
    if ymca_fill==2 and str==42 then
      ymca_fill=3
    end
    if ymca_fill==3 and str==44 then
      ymca_fill=4
      ymca_start = true
      n_cubes = n_cubes + 1
    end
    love.graphics.draw(scheletro_img[str])
    if ymca_fill>=1 then
      love.graphics.setColor(1/3, 1/5, 1/2)
      love.graphics.print("Y", 380, 200, 0, 2, 2)
    end
    if ymca_fill>=2 then
      love.graphics.setColor(2/3, 1, 0)
      love.graphics.print("M", 420, 190, 0, 2, 2)
    end
    if ymca_fill>=3 then
      love.graphics.setColor(1, 2/3, 0)
      love.graphics.print("C", 490, 180, 0, 2, 2)
    end
    if ymca_fill>=4 then
      love.graphics.setColor(2/3, 0, 0)
      love.graphics.print("A", 550, 170, 0, 2, 2)
    end
    if ymca_start and ymca_t < 5 then
      love.graphics.setColor(1, 1, 1, 1 - (ymca_t-1)/5)
      local img = cube.image[cube.n]
      love.graphics.draw(img, 496.5,336, 0, 1, 1, img:getWidth()/2, img:getHeight()/2)
    end
    love.graphics.setColor(1,1,1)
  end

  --love.graphics.setColor(1, 0, 0, 0.5)
  --for ip, p in ipairs(room[current].polygon) do
  --  love.graphics.polygon("fill", p)
  --end

  love.graphics.setCanvas()

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(canvas, 0, 0, 0, sc, sc)
end