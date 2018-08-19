local menu = 1
class "Talon"

require = 'DamageLib'

local function Ready(spell)
		return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end 
local function HpPred(unit, delay)
	if _G.GOS then
	hp =  GOS:HP_Pred(unit,delay)
	else
	hp = unit.health
	end
	return hp
end

local _atan                         = math.atan2
local _min                          = math.min
local _abs                          = math.abs
local _sqrt                         = math.sqrt
local _floor                        = math.floor
local _max                          = math.max
local _pow                          = math.pow
local _huge                         = math.huge
local _pi                           = math.pi
local _insert                       = table.insert
local _contains                     = table.contains
local _sort                         = table.sort
local _pairs                        = pairs
local _find                         = string.find
local _sub                          = string.sub
local _len                          = string.len

local LocalDrawLine					= Draw.Line;
local LocalDrawColor				= Draw.Color;
local LocalDrawCircle				= Draw.Circle;
local LocalDrawCircleMinimap        = Draw.CircleMinimap;
local LocalDrawText					= Draw.Text;
local LocalControlIsKeyDown			= Control.IsKeyDown;
local LocalControlMouseEvent		= Control.mouse_event;
local LocalControlSetCursorPos		= Control.SetCursorPos;
local LocalControlCastSpell         = Control.CastSpell;
local LocalControlKeyUp				= Control.KeyUp;
local LocalControlKeyDown			= Control.KeyDown;
local LocalControlMove              = Control.Move;
local LocalGetTickCount             = GetTickCount;
local LocalGamecursorPos            = Game.cursorPos;
local LocalGameCanUseSpell			= Game.CanUseSpell;
local LocalGameLatency				= Game.Latency;
local LocalGameTimer				= Game.Timer;
local LocalGameHeroCount 			= Game.HeroCount;
local LocalGameHero 				= Game.Hero;
local LocalGameMinionCount 			= Game.MinionCount;
local LocalGameMinion 				= Game.Minion;
local LocalGameTurretCount 			= Game.TurretCount;
local LocalGameTurret 				= Game.Turret;
local LocalGameWardCount 			= Game.WardCount;
local LocalGameWard 				= Game.Ward;
local LocalGameObjectCount 			= Game.ObjectCount;
local LocalGameObject				= Game.Object;
local LocalGameMissileCount 		= Game.MissileCount;
local LocalGameMissile				= Game.Missile;
local LocalGameParticleCount 		= Game.ParticleCount;
local LocalGameParticle				= Game.Particle;
local LocalGameIsChatOpen			= Game.IsChatOpen;
local LocalGameIsOnTop				= Game.IsOnTop;

local _EnemyHeroes
function GetEnemyHeroes()
    if _EnemyHeroes then return _EnemyHeroes end
    for i = 1, LocalGameHeroCount() do
        local unit = LocalGameHero(i)
        if unit.isEnemy then
	        if _EnemyHeroes == nil then _EnemyHeroes = {} end
        _insert(_EnemyHeroes, unit)
        end
    end
    return {}
end

local _OnVision = {}
function OnVision(unit)
    if _OnVision[unit.networkID] == nil then _OnVision[unit.networkID] = {state = unit.visible , tick = LocalGetTickCount(), pos = unit.pos} end
	if _OnVision[unit.networkID].state == true and not unit.visible then _OnVision[unit.networkID].state = false _OnVision[unit.networkID].tick = LocalGetTickCount() end
	if _OnVision[unit.networkID].state == false and unit.visible then _OnVision[unit.networkID].state = true _OnVision[unit.networkID].tick = LocalGetTickCount() end
	return _OnVision[unit.networkID]
end
Callback.Add("Tick", function() OnVisionF() end)
local visionTick = LocalGetTickCount()
function OnVisionF()
	if LocalGetTickCount() - visionTick > 100 then
		for i,v in _pairs(GetEnemyHeroes()) do
			OnVision(v)
		end
	end
end

function GetDistance(p1,p2)
    return _sqrt(_pow((p2.x - p1.x),2) + _pow((p2.y - p1.y),2) + _pow((p2.z - p1.z),2))
end

function GetDistance2D(p1,p2)
    return _sqrt(_pow((p2.x - p1.x),2) + _pow((p2.y - p1.y),2))
end

function GetDistanceSqr(Pos1, Pos2)
	local Pos2 = Pos2 or myHero.pos
	local dx = Pos1.x - Pos2.x
	local dz = (Pos1.z or Pos1.y) - (Pos2.z or Pos2.y)
	return dx^2 + dz^2
end

function SetAttacks(bool)
	if _G.SDK and _G.SDK.Orbwalker then
        _G.SDK.Orbwalker:SetAttack(bool)
    else
		GOS.BlockAttack = not bool
	end
end

function Talon:__init()
	if menu ~= 1 then return end
	menu = 2
	if myHero.charName ~= "Talon" then return end
	PrintChat("Welcome to the Noxian Way Of Life")
	self.W = { delay = 0.25, speed = 1850, radius = 35, range = 650  }
	self:LoadSpells()
	self:LoadMenu()																							--Init
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
end

function Priority(charName)
    local p1 = {"Alistar", "Amumu", "Blitzcrank", "Braum", "Cho'Gath", "Dr. Mundo", "Garen", "Gnar", "Maokai", "Hecarim", "Jarvan IV", "Leona", "Lulu", "Malphite", "Nasus", "Nautilus", "Nunu", "Olaf", "Rammus", "Renekton", "Sejuani", "Shen", "Shyvana", "Singed", "Sion", "Skarner", "Taric", "TahmKench", "Thresh", "Volibear", "Warwick", "MonkeyKing", "Yorick", "Zac", "Poppy"}
    local p2 = {"Aatrox", "Darius", "Elise", "Evelynn", "Galio", "Gragas", "Irelia", "Jax", "Lee Sin", "Morgana", "Janna", "Nocturne", "Pantheon", "Rengar", "Rumble", "Swain", "Trundle", "Tryndamere", "Udyr", "Urgot", "Vi", "XinZhao", "RekSai", "Bard", "Nami", "Sona", "Camille"}
    local p3 = {"Akali", "Diana", "Ekko", "FiddleSticks", "Fiora", "Gangplank", "Fizz", "Heimerdinger", "Jayce", "Kassadin", "Kayle", "Kha'Zix", "Lissandra", "Mordekaiser", "Nidalee", "Riven", "Shaco", "Vladimir", "Yasuo", "Zilean", "Zyra", "Ryze"}
    local p4 = {"Ahri", "Anivia", "Annie", "Ashe", "Azir", "Brand", "Caitlyn", "Cassiopeia", "Corki", "Draven", "Ezreal", "Graves", "Jinx", "Kalista", "Karma", "Karthus", "Katarina", "Kennen", "KogMaw", "Kindred", "Leblanc", "Lucian", "Lux", "Malzahar", "MasterYi", "MissFortune", "Orianna", "Quinn", "Sivir", "Syndra", "Talon", "Teemo", "Tristana", "TwistedFate", "Twitch", "Varus", "Vayne", "Veigar", "Velkoz", "Viktor", "Xerath", "Zed", "Ziggs", "Jhin", "Soraka"}
    if _contains(p1, charName) then return 1 end
    if _contains(p2, charName) then return 1.25 end
    if _contains(p3, charName) then return 1.75 end
    return _contains(p4, charName) and 2.25 or 1
end

function GetMode()
	if _G.SDK then
        if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
            return "Combo"
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
            return "Harass"	
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then 
            return "Clear"
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
            return "LastHit"
        elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
            return "Flee"
        end
    else
        return GOS.GetMode()
    end
end

function GetTarget(range,t,pos)
    local t = t or "AD"
    local pos = pos or myHero.pos
    local target = {}
	for i = 1, LocalGameHeroCount() do
		local hero = LocalGameHero(i)
		if hero.isEnemy and not hero.dead then
			OnVision(hero)
		end
		if hero.isEnemy and hero.valid and not hero.dead and (OnVision(hero).state == true or (OnVision(hero).state == false and LocalGetTickCount() - OnVision(hero).tick < 650)) and hero.isTargetable then
			local heroPos = hero.pos
			if OnVision(hero).state == false then heroPos = hero.pos + Vector(hero.pos,hero.posTo):Normalized() * ((LocalGetTickCount() - OnVision(hero).tick)/1000 * hero.ms) end
			if GetDistance(pos,heroPos) <= range then
				if t == "AD" then
					target[(CalcPhysicalDamage(myHero,hero,100) / hero.health) * Priority(hero.charName)] = hero
				elseif t == "AP" then
					target[(CalcMagicalDamage(myHero,hero,100) / hero.health) * Priority(hero.charName)] = hero
				elseif t == "HYB" then
					target[((CalcMagicalDamage(myHero,hero,50) + CalcPhysicalDamage(myHero,hero,50))/ hero.health) * Priority(hero.charName)] = hero
				end
			end
		end
	end
	local bT = 0
	for d,v in _pairs(target) do
		if d > bT then
			bT = d
		end
	end
	if bT ~= 0 then return target[bT] end
end

local castSpell = {state = 0, tick = LocalGetTickCount(), casting = LocalGetTickCount() - 1000, mouse = mousePos}
function CastSpell(spell,pos,range,delay)
    local range = range or _huge
    local delay = delay or 250
    local ticker = LocalGetTickCount()

	if castSpell.state == 0 and GetDistance(myHero.pos,pos) < range and ticker - castSpell.casting > delay + LocalGameLatency() and pos:ToScreen().onScreen then
		castSpell.state = 1
		castSpell.mouse = mousePos
		castSpell.tick = ticker
	end
	if castSpell.state == 1 then
		if ticker - castSpell.tick < LocalGameLatency() then
			LocalControlSetCursorPos(pos)
			LocalControlKeyDown(spell)
			LocalControlKeyUp(spell)
			castSpell.casting = ticker + delay
			DelayAction(function()
				if castSpell.state == 1 then
					LocalControlSetCursorPos(castSpell.mouse)
					castSpell.state = 0
				end
			end,0.01)
		end
		if ticker - castSpell.casting > LocalGameLatency() then
			LocalControlSetCursorPos(castSpell.mouse)
			castSpell.state = 0
		end
	end
end

local _OnWaypoint = {}
function OnWaypoint(unit)
	if _OnWaypoint[unit.networkID] == nil then _OnWaypoint[unit.networkID] = {pos = unit.posTo , speed = unit.ms, time = LocalGameTimer()} end
	if _OnWaypoint[unit.networkID].pos ~= unit.posTo then
		_OnWaypoint[unit.networkID] = {startPos = unit.pos, pos = unit.posTo , speed = unit.ms, time = LocalGameTimer()}
			DelayAction(function()
				local time = (LocalGameTimer() - _OnWaypoint[unit.networkID].time)
				local speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(LocalGameTimer() - _OnWaypoint[unit.networkID].time)
				if speed > 1250 and time > 0 and unit.posTo == _OnWaypoint[unit.networkID].pos and GetDistance(unit.pos,_OnWaypoint[unit.networkID].pos) > 200 then
					_OnWaypoint[unit.networkID].speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(LocalGameTimer() - _OnWaypoint[unit.networkID].time)
				end
			end,0.05)
	end
	return _OnWaypoint[unit.networkID]
end

function Talon:Tick()
	if myHero.dead then return end
		if GetMode() == "Combo" then
			self:Combo()
		elseif GetMode() == "Harass" then								--OnTick
			self:Harass()
		elseif GetMode() == "Clear" then
			self:Clear()
		elseif GetMode() == "LastHit" then
			self:LastHit()
		elseif GetMode() == "Flee" then
			self:Flee()	
		end
end

function Talon:Combo()
	if GetTarget(1000,"AD") == nil then return end
	self:DisableAtk()
	self:EnableAtk()
	local targ = GetTarget(550,"AD")
	if self.Menu.Combo.UseR:Value() and Ready(_R) and not self:HasBuff(myHero, "TalonRStealth") then
		if EnemiesAround(myHero.pos, 1000) >= self.Menu.Combo.MinR:Value() then
    		Control.CastSpell(HK_R)
    	end
    end
	if self.Menu.Combo.UseQ:Value() and Ready(_Q) and targ ~= nil then
		Control.CastSpell(HK_Q, targ)
	end	
	if self.Menu.Combo.UseW:Value() and Ready(_W) and targ ~= nil then														--Combo
    	local Cpred = targ:GetPrediction(W.speed, 0.25 + Game.Latency()/1000)
    	Control.CastSpell(HK_W, Cpred)
    end
    
end
function Talon:Harass()
	if GetTarget(W.range + 100,"AD") == nil then return end
	if self.Menu.Harass.UseW:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Harass.Mana:Value() / 100 ) then
		--local Wtarg = GetTarget(W.range + 100,"AD")											--Harass
		--local Hpred = Wtarg:GetPrediction(W.speed, 0.25 + Game.Latency()/1000)
		--Control.CastSpell(HK_W, Hpred)
		self:Wlogic()
	end
end
function Talon:Wlogic()
	if LocalGameCanUseSpell(_W) == 0 and castSpell.state == 0 then
		local target = GetTarget(W.range,"AD")
		if target then
			local hitChance, aimPosition = HPred:GetHitchance(myHero.pos, target, W.range, self.W.delay, W.speed, self.W.radius, false)
			if hitChance and hitChance >= 2 then
				self:CastW(target,aimPosition)
			end
		end
	end
end
function Talon:CastW(target,WcastPos)
	if LocalGameTimer() - OnWaypoint(target).time > 0.05 and (LocalGameTimer() - OnWaypoint(target).time < 0.125 or LocalGameTimer() - OnWaypoint(target).time > 1.25) then
		if GetDistance(myHero.pos,WcastPos) <= self.W.range then
			LocalControlCastSpell(HK_W,WcastPos)
		end
	end
end
function Talon:LastHit()
	if Ready(_Q) then
		local level = myHero:GetSpellData(_Q).level	
  		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local Qdamage = (({60, 85, 110, 135, 160})[level] + myHero.bonusDamage)
			if myHero.pos:DistanceTo(minion.pos) < 550 and self.Menu.Lasthit.UseQ:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Lasthit.Mana:Value() / 100 ) and minion.isEnemy then
				if Qdamage >= minion.health then
					Control.CastSpell(HK_Q,minion)																																					--Last Hit
				end
			end
			local QMelee = (({60, 85, 110, 135, 160})[level] * 1.5 )
			if myHero.pos:DistanceTo(minion.pos) < 170 and self.Menu.Lasthit.UseQ:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Lasthit.Mana:Value() / 100 ) and minion.isEnemy then
				if QMelee >= minion.health then
					Control.CastSpell(HK_Q,minion)
				end
			end
      		
		end
	end
end

function Talon:IsValidTarget(unit,range) 
	return unit ~= nil and unit.valid and unit.visible and not unit.dead and unit.isTargetable and not unit.isImmortal 
end

function Talon:HasBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return true
		end
	end
	return false
end

function CountEnemyMinions(range)
	local minionsCount = 0
    for i = 1,Game.MinionCount() do
        local minion = Game.Minion(i)
        if  minion.team ~= myHero.team and minion.valid and minion.pos:DistanceTo(myHero.pos) < 650 then
            minionsCount = minionsCount + 1
        end
    end
    return minionsCount
end

function Talon:Clear()
	if self.Menu.Clear.Usage:Value() == false then return end
	for i = 1, Game.MinionCount() do
	local minion = Game.Minion(i)
		if self:IsValidTarget(minion,550) and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) < 550 and self.Menu.Clear.UseQ:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Clear.Mana:Value() / 100 ) and minion.isEnemy then
			Control.CastSpell(HK_Q,minion.pos)
		end
		if self:IsValidTarget(minion,650) and Ready(_W) and myHero.pos:DistanceTo(minion.pos) < 650 and self.Menu.Clear.UseW:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Clear.Mana:Value() / 100 ) and minion.isEnemy then
			if CountEnemyMinions(650) >= self.Menu.Clear.WHit:Value() then
				Control.CastSpell(HK_W,minion.pos)
			end
		end
		if self:IsValidTarget(minion,550) and Ready(_Q) and myHero.pos:DistanceTo(minion.pos) < 550 and self.Menu.Clear.UseQ:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Clear.Mana:Value() / 100 ) and minion.isEnemy then
			Control.CastSpell(HK_Q,minion.pos)
		end
		if self:IsValidTarget(minion,650) and Ready(_W) and myHero.pos:DistanceTo(minion.pos) < 650 and self.Menu.Clear.UseW:Value() and (myHero.mana/myHero.maxMana >= self.Menu.Clear.Mana:Value() / 100 ) and minion.isEnemy then
			Control.CastSpell(HK_W,minion.pos)
		end
		
	end
end

function Talon:Flee()
	if Game.IsChatOpen() == false then
		Control.CastSpell(HK_E, cursorPos)
	end
	
end


local Icons = {
["TalonIcon"] = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/7/74/Blade%27s_End.png",
["Q"] = "https://vignette1.wikia.nocookie.net/leagueoflegends/images/6/6b/Noxian_Diplomacy.png",
["W"] = "https://vignette3.wikia.nocookie.net/leagueoflegends/images/b/bd/Rake.png",								--Icons
["E"] = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/d/de/Assassin%27s_Path.png",
["R"] = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/6/66/Shadow_Assault.png",
}

function Talon:LoadSpells()

	Q = { range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed, width = myHero:GetSpellData(_Q).width }
	W = { range = myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed, width = myHero:GetSpellData(_W).width }
	E = { range = myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed, width = myHero:GetSpellData(_E).width }
	R = { range = myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed, width = myHero:GetSpellData(_R).width }
end

function Talon:LoadMenu()											
	--MainMenu
	self.Menu = MenuElement({type = MENU, id = "Talon", name = "Noxian Way Of Life", leftIcon = Icons["TalonIcon"]})
	--ComboMenu
	self.Menu:MenuElement({type = MENU, id = "Combo", name = "Combo"})
	self.Menu.Combo:MenuElement({id = "UseQ", name = "[Q] Noxian Diplomacy", value = true, leftIcon = Icons.Q})
	self.Menu.Combo:MenuElement({id = "UseW", name = "[W] Rake", value = true, leftIcon = Icons.W})
	self.Menu.Combo:MenuElement({id = "UseR", name = "[R] Shadow Assault", value = true, leftIcon = Icons.R})
	self.Menu.Combo:MenuElement({id = "MinR", name = "Min Enemies to use R", value = 2, min = 1, max = 5})
	--HarassMenu
	self.Menu:MenuElement({type = MENU, id = "Harass", name = "Harass"})
	self.Menu.Harass:MenuElement({id = "UseW", name = "[W] Rake", value = true, leftIcon = Icons.W})
	self.Menu.Harass:MenuElement({id = "Mana", name = "Min Mana to Harass(%)", value = 65, min = 0, max = 100})
	--LaneClear Menu
	self.Menu:MenuElement({type = MENU, id = "Clear", name = "Lane Clear"})
	self.Menu.Clear:MenuElement({id = "Usage", name = "Spells Usage", key = string.byte("A"),toggle = true})
	self.Menu.Clear:MenuElement({id = "UseQ", name = "[Q] Noxian Diplomacy", value = true, leftIcon = Icons.Q})					--Menus
	self.Menu.Clear:MenuElement({id = "UseW", name = "[W] Rake", value = true, leftIcon = Icons.W})
	self.Menu.Clear:MenuElement({id = "WHit", name = "[W] if x minions", value = 3, min = 1, max = 7})
	self.Menu.Clear:MenuElement({id = "Mana", name = "Min Mana to Clear(%)", value = 50, min = 0, max = 100})
	--LastHit Menu
	self.Menu:MenuElement({type = MENU, id = "Lasthit", name = "Lasthit"})
	self.Menu.Lasthit:MenuElement({id = "UseQ", name = "[Q] Noxian Diplomacy", value = true, leftIcon = Icons.Q})
	self.Menu.Lasthit:MenuElement({id = "Mana", name = "Min Mana to Lasthit (%)", value = 65, min = 0, max = 100})
	--Drawing Menu
	self.Menu:MenuElement({type = MENU, id = "Drawing", name = "Drawings"})
	self.Menu.Drawing:MenuElement({id = "DrawQ", name = "Draw [Q] Range", value = true, leftIcon = Icons.Q})
	self.Menu.Drawing:MenuElement({id = "DrawW", name = "Draw [W] Range", value = true, leftIcon = Icons.W})
end


function Talon:Draw()
	if myHero.dead then return end
	if(self.Menu.Drawing.DrawW:Value())then
		Draw.Circle(myHero, W.range + 100, 3, Draw.Color(255, 225, 255, 10))
	end 																								--OnDraw
	if(self.Menu.Drawing.DrawQ:Value())then
		Draw.Circle(myHero, 550, 3, Draw.Color(225, 225, 0, 10))
	end
end
function EnemiesAround(pos, range)
    local Count = 0
    for i = 1, Game.HeroCount() do
        local Hero = Game.Hero(i)      
        if not Hero.dead and Hero.isEnemy and Hero.pos:DistanceTo(pos, Hero.pos) < range then
            Count = Count + 1
        end
    end
    return Count
end
local atk = 1
function Talon:DisableAtk()
	if (self:HasBuff(myHero, "TalonRStealth")) and atk == 1 then
		SetAttacks(false)
		atk = 0
	end
end

function Talon:EnableAtk()
	if not (self:HasBuff(myHero, "TalonRStealth")) and atk == 0 then
	 	SetAttacks(true)
		atk = 1
	end
end



function OnLoad()
	Talon()
end

class "HPred"
	
local _tickFrequency = .2
local _nextTick = LocalGameTimer()
local _reviveLookupTable = 
	{ 
		["LifeAura.troy"] = 4, 
		["ZileanBase_R_Buf.troy"] = 3,
		["Aatrox_Base_Passive_Death_Activate"] = 3
	}

local _blinkSpellLookupTable = 
	{ 
		["EzrealArcaneShift"] = 475, 
		["RiftWalk"] = 500,
		["EkkoEAttack"] = 0,
		["AlphaStrike"] = 0,
		["KatarinaE"] = -255,
		["KatarinaEDagger"] = { "Katarina_Base_Dagger_Ground_Indicator","Katarina_Skin01_Dagger_Ground_Indicator","Katarina_Skin02_Dagger_Ground_Indicator","Katarina_Skin03_Dagger_Ground_Indicator","Katarina_Skin04_Dagger_Ground_Indicator","Katarina_Skin05_Dagger_Ground_Indicator","Katarina_Skin06_Dagger_Ground_Indicator","Katarina_Skin07_Dagger_Ground_Indicator" ,"Katarina_Skin08_Dagger_Ground_Indicator","Katarina_Skin09_Dagger_Ground_Indicator"  }, 
	}

local _blinkLookupTable = 
	{ 
		"global_ss_flash_02.troy",
		"Lissandra_Base_E_Arrival.troy",
		"LeBlanc_Base_W_return_activation.troy"
	}

local _cachedBlinks = {}
local _cachedRevives = {}
local _cachedTeleports = {}
local _cachedMissiles = {}
local _incomingDamage = {}
local _windwall
local _windwallStartPos
local _windwallWidth

local _OnVision = {}
function HPred:OnVision(unit)
	if unit == nil or type(unit) ~= "userdata" then return end
	if _OnVision[unit.networkID] == nil then _OnVision[unit.networkID] = {visible = unit.visible , tick = LocalGetTickCount(), pos = unit.pos } end
	if _OnVision[unit.networkID].visible == true and not unit.visible then _OnVision[unit.networkID].visible = false _OnVision[unit.networkID].tick = LocalGetTickCount() end
	if _OnVision[unit.networkID].visible == false and unit.visible then _OnVision[unit.networkID].visible = true _OnVision[unit.networkID].tick = LocalGetTickCount() _OnVision[unit.networkID].pos = unit.pos end
	return _OnVision[unit.networkID]
end

function HPred:Tick()
	if _nextTick > LocalGameTimer() then return end
	_nextTick = LocalGameTimer() + _tickFrequency
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)
		if t then
			if t.isEnemy then
				HPred:OnVision(t)
			end
		end
	end
	if true then return end
	for _, teleport in _pairs(_cachedTeleports) do
		if teleport and LocalGameTimer() > teleport.expireTime + .5 then
			_cachedTeleports[_] = nil
		end
	end	
	HPred:CacheTeleports()
	HPred:CacheParticles()
	for _, revive in _pairs(_cachedRevives) do
		if LocalGameTimer() > revive.expireTime + .5 then
			_cachedRevives[_] = nil
		end
	end
	for _, revive in _pairs(_cachedRevives) do
		if LocalGameTimer() > revive.expireTime + .5 then
			_cachedRevives[_] = nil
		end
	end
	for i = 1, LocalGameParticleCount() do 
		local particle = LocalGameParticle(i)
		if particle and not _cachedRevives[particle.networkID] and  _reviveLookupTable[particle.name] then
			_cachedRevives[particle.networkID] = {}
			_cachedRevives[particle.networkID]["expireTime"] = LocalGameTimer() + _reviveLookupTable[particle.name]			
			local target = HPred:GetHeroByPosition(particle.pos)
			if target.isEnemy then				
				_cachedRevives[particle.networkID]["target"] = target
				_cachedRevives[particle.networkID]["pos"] = target.pos
				_cachedRevives[particle.networkID]["isEnemy"] = target.isEnemy	
			end
		end
		if particle and not _cachedBlinks[particle.networkID] and  _blinkLookupTable[particle.name] then
			_cachedBlinks[particle.networkID] = {}
			_cachedBlinks[particle.networkID]["expireTime"] = LocalGameTimer() + _reviveLookupTable[particle.name]			
			local target = HPred:GetHeroByPosition(particle.pos)
			if target.isEnemy then				
				_cachedBlinks[particle.networkID]["target"] = target
				_cachedBlinks[particle.networkID]["pos"] = target.pos
				_cachedBlinks[particle.networkID]["isEnemy"] = target.isEnemy	
			end
		end
	end
	
end

function HPred:GetEnemyNexusPosition()
	if myHero.team == 100 then return Vector(14340, 171.977722167969, 14390); else return Vector(396,182.132507324219,462); end
end


function HPred:GetGuarenteedTarget(source, range, delay, speed, radius, timingAccuracy, checkCollision)
	local target, aimPosition =self:GetHourglassTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetRevivingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetTeleportingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)	
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetImmobileTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
end


function HPred:GetReliableTarget(source, range, delay, speed, radius, timingAccuracy, checkCollision)
	local target, aimPosition =self:GetHourglassTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetRevivingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetTeleportingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)	
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetInstantDashTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetDashingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius, midDash)
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetImmobileTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end
	local target, aimPosition =self:GetBlinkTarget(source, range, speed, delay, checkCollision, radius)
	if target and aimPosition then
		return target, aimPosition
	end	
end

function HPred:GetLineTargetCount(source, aimPos, delay, speed, width, targetAllies)
	local targetCount = 0
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)
		if t and self:CanTargetALL(t) and ( targetAllies or t.isEnemy) then
			local predictedPos = self:PredictUnitPosition(t, delay+ self:GetDistance(source, t.pos) / speed)
			local proj1, pointLine, isOnSegment = self:VectorPointProjectionOnLineSegment(source, aimPos, predictedPos)
			if proj1 and isOnSegment and (self:GetDistanceSqr(predictedPos, proj1) <= (t.boundingRadius + width) * (t.boundingRadius + width)) then
				targetCount = targetCount + 1
			end
		end
	end
	return targetCount
end

function HPred:GetUnreliableTarget(source, range, delay, speed, radius, checkCollision, minimumHitChance, whitelist, isLine)
	local _validTargets = {}
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)		
		if t and self:CanTarget(t, true) and (not whitelist or whitelist[t.charName]) then
			local hitChance, aimPosition = self:GetHitchance(source, t, range, delay, speed, radius, checkCollision, isLine)		
			if hitChance >= minimumHitChance then
				_insert(_validTargets, {aimPosition,hitChance, hitChance * 100 + self:CalculateMagicDamage(t, 400)})
			end
		end
	end	
	_sort(_validTargets, function( a, b ) return a[3] >b[3] end)	
	if #_validTargets > 0 then	
		return _validTargets[1][2], _validTargets[1][1]
	end
end

function HPred:GetHitchance(source, target, range, delay, speed, radius, checkCollision, isLine)
	if isLine == nil and checkCollision then
		isLine = true
	end
	local hitChance = 1
	local aimPosition = self:PredictUnitPosition(target, delay + self:GetDistance(source, target.pos) / speed)	
	local interceptTime = self:GetSpellInterceptTime(source, aimPosition, delay, speed)
	local reactionTime = self:PredictReactionTime(target, .1, isLine)
	if isLine then
		local pathVector = aimPosition - target.pos
		local castVector = (aimPosition - myHero.pos):Normalized()
		if pathVector.x + pathVector.z ~= 0 then
			pathVector = pathVector:Normalized()
			if pathVector:DotProduct(castVector) < -.85 or pathVector:DotProduct(castVector) > .85 then
				if speed > 3000 then
					reactionTime = reactionTime + .25
				else
					reactionTime = reactionTime + .15
				end
			end
		end
	end
	Waypoints = self:GetCurrentWayPoints(target)
	if (#Waypoints == 1) then
		HitChance = 2
	end
	if self:isSlowed(target, delay, speed, source) then
		HitChance = 2
	end
	if self:GetDistance(source, target.pos) < 350 then
		HitChance = 2
	end
	local angletemp = Vector(source):AngleBetween(Vector(target.pos), Vector(aimPosition))
	if angletemp > 60 then
		HitChance = 1
	elseif angletemp < 10 then
		HitChance = 2
	end
	if not target.pathing or not target.pathing.hasMovePath then
		hitChancevisionData = 2
		hitChance = 2
	end
	local origin,movementRadius = self:UnitMovementBounds(target, interceptTime, reactionTime)
	if movementRadius - target.boundingRadius <= radius /2 then
		origin,movementRadius = self:UnitMovementBounds(target, interceptTime, 0)
		if movementRadius - target.boundingRadius <= radius /2 then
			hitChance = 4
		else		
			hitChance = 3
		end
	end	
	if target.activeSpell and target.activeSpell.valid then
		if target.activeSpell.startTime + target.activeSpell.windup - LocalGameTimer() >= delay then
			hitChance = 5
		else			
			hitChance = 3
		end
	end
	local visionData = HPred:OnVision(target)
	if visionData and visionData.visible == false then
		local hiddenTime = visionData.tick -LocalGetTickCount()
		if hiddenTime < -1000 then
			hitChance = -1
		else
			local targetSpeed = self:GetTargetMS(target)
			local unitPos = target.pos + Vector(target.pos,target.posTo):Normalized() * ((LocalGetTickCount() - visionData.tick)/1000 * targetSpeed)
			local aimPosition = unitPos + Vector(target.pos,target.posTo):Normalized() * (targetSpeed * (delay + (self:GetDistance(myHero.pos,unitPos)/speed)))
			if self:GetDistance(target.pos,aimPosition) > self:GetDistance(target.pos,target.posTo) then aimPosition = target.posTo end
			hitChance = _min(hitChance, 2)
		end
	end
	if not self:IsInRange(source, aimPosition, range) then
		hitChance = -1
	end
	if hitChance > 0 and checkCollision then
		if self:IsWindwallBlocking(source, aimPosition) then
			hitChance = -1		
		elseif self:CheckMinionCollision(source, aimPosition, delay, speed, radius) then
			hitChance = -1
		end
	end
	
	return hitChance, aimPosition
end

function HPred:PredictReactionTime(unit, minimumReactionTime)
    local reactionTime = minimumReactionTime
    if unit.activeSpell and unit.activeSpell.valid then
		local windupRemaining = unit.activeSpell.startTime + unit.activeSpell.windup - LocalGameTimer()
		if windupRemaining > 0 then
			reactionTime = windupRemaining
		end
	end	
	return reactionTime
end

function HPred:GetCurrentWayPoints(object)
	local result = {}
	if object.pathing.hasMovePath then
		_insert(result, Vector(object.pos.x,object.pos.y, object.pos.z))
		for i = object.pathing.pathIndex, object.pathing.pathCount do
			path = object:GetPath(i)
			_insert(result, Vector(path.x, path.y, path.z))
		end
	else
		_insert(result, object and Vector(object.pos.x,object.pos.y, object.pos.z) or Vector(object.pos.x,object.pos.y, object.pos.z))
	end
	return result
end

function HPred:GetDashingTarget(source, range, delay, speed, dashThreshold, checkCollision, radius, midDash)
	local target
	local aimPosition
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)
		if t and t.isEnemy and t.pathing.hasMovePath and t.pathing.isDashing and t.pathing.dashSpeed>500  then
			local dashEndPosition = t:GetPath(1)
			if self:IsInRange(source, dashEndPosition, range) then				
				local dashTimeRemaining = self:GetDistance(t.pos, dashEndPosition) / t.pathing.dashSpeed
				local skillInterceptTime = self:GetSpellInterceptTime(source, dashEndPosition, delay, speed)
				local deltaInterceptTime =skillInterceptTime - dashTimeRemaining
				if deltaInterceptTime > 0 and deltaInterceptTime < dashThreshold and (not checkCollision or not self:CheckMinionCollision(source, dashEndPosition, delay, speed, radius)) then
					target = t
					aimPosition = dashEndPosition
					return target, aimPosition
				end
			end			
		end
	end
end

function HPred:GetHourglassTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)
		if t and t.isEnemy then		
			local success, timeRemaining = self:HasBuff(t, "zhonyasringshield")
			if success then
				local spellInterceptTime = self:GetSpellInterceptTime(source, t.pos, delay, speed)
				local deltaInterceptTime = spellInterceptTime - timeRemaining
				if spellInterceptTime > timeRemaining and deltaInterceptTime < timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, interceptPosition, delay, speed, radius)) then
					target = t
					aimPosition = t.pos
					return target, aimPosition
				end
			end
		end
	end
end

function HPred:GetRevivingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for _, revive in _pairs(_cachedRevives) do	
		if revive.isEnemy then
			local interceptTime = self:GetSpellInterceptTime(source, revive.pos, delay, speed)
			if interceptTime > revive.expireTime - LocalGameTimer() and interceptTime - revive.expireTime - LocalGameTimer() < timingAccuracy then
				target = revive.target
				aimPosition = revive.pos
				return target, aimPosition
			end
		end
	end	
end

function HPred:GetInstantDashTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)
		if t and t.isEnemy and t.activeSpell and t.activeSpell.valid and _blinkSpellLookupTable[t.activeSpell.name] then
			local windupRemaining = t.activeSpell.startTime + t.activeSpell.windup - LocalGameTimer()
			if windupRemaining > 0 then
				local endPos
				local blinkRange = _blinkSpellLookupTable[t.activeSpell.name]
				if type(blinkRange) == "table" then
				elseif blinkRange > 0 then
					endPos = Vector(t.activeSpell.placementPos.x, t.activeSpell.placementPos.y, t.activeSpell.placementPos.z)					
					endPos = t.activeSpell.startPos + (endPos- t.activeSpell.startPos):Normalized() * _min(self:GetDistance(t.activeSpell.startPos,endPos), range)
				else
					local blinkTarget = self:GetObjectByHandle(t.activeSpell.target)
					if blinkTarget then				
						local offsetDirection
						if blinkRange == 0 then				
							if t.activeSpell.name ==  "AlphaStrike" then
								windupRemaining = windupRemaining + .75
							end						
							offsetDirection = (blinkTarget.pos - t.pos):Normalized()
						elseif blinkRange == -1 then						
							offsetDirection = (t.pos-blinkTarget.pos):Normalized()
						elseif blinkRange == -255 then
							if radius > 250 then
								endPos = blinkTarget.pos
							end							
						end
						if offsetDirection then
							endPos = blinkTarget.pos - offsetDirection * blinkTarget.boundingRadius
						end
					end
				end
				local interceptTime = self:GetSpellInterceptTime(source, endPos, delay,speed)
				local deltaInterceptTime = interceptTime - windupRemaining
				if self:IsInRange(source, endPos, range) and deltaInterceptTime < timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, endPos, delay, speed, radius)) then
					target = t
					aimPosition = endPos
					return target,aimPosition					
				end
			end
		end
	end
end

function HPred:GetBlinkTarget(source, range, speed, delay, checkCollision, radius)
	local target
	local aimPosition
	for _, particle in _pairs(_cachedBlinks) do
		if particle  and self:IsInRange(source, particle.pos, range) then
			local t = particle.target
			local pPos = particle.pos
			if t and t.isEnemy and (not checkCollision or not self:CheckMinionCollision(source, pPos, delay, speed, radius)) then
				target = t
				aimPosition = pPos
				return target,aimPosition
			end
		end		
	end
end

function HPred:GetChannelingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)
		if t then
			local interceptTime = self:GetSpellInterceptTime(source, t.pos, delay, speed)
			if self:CanTarget(t) and self:IsInRange(source, t.pos, range) and self:IsChannelling(t, interceptTime) and (not checkCollision or not self:CheckMinionCollision(source, t.pos, delay, speed, radius)) then
				target = t
				aimPosition = t.pos	
				return target, aimPosition
			end
		end
	end
end

function HPred:GetImmobileTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for i = 1, LocalGameHeroCount() do
		local t = LocalGameHero(i)
		if t and self:CanTarget(t) and self:IsInRange(source, t.pos, range) then
			local immobileTime = self:GetImmobileTime(t)
			
			local interceptTime = self:GetSpellInterceptTime(source, t.pos, delay, speed)
			if immobileTime - interceptTime > timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, t.pos, delay, speed, radius)) then
				target = t
				aimPosition = t.pos
				return target, aimPosition
			end
		end
	end
end

function HPred:CacheTeleports()
	for i = 1, LocalGameTurretCount() do
		local turret = LocalGameTurret(i);
		if turret and turret.isEnemy and not _cachedTeleports[turret.networkID] then
			local hasBuff, expiresAt = self:HasBuff(turret, "teleport_target")
			if hasBuff then
				self:RecordTeleport(turret, self:GetTeleportOffset(turret.pos,223.31),expiresAt)
			end
		end
	end
	for i = 1, LocalGameWardCount() do
		local ward = LocalGameWard(i);
		if ward and ward.isEnemy and not _cachedTeleports[ward.networkID] then
			local hasBuff, expiresAt = self:HasBuff(ward, "teleport_target")
			if hasBuff then
				self:RecordTeleport(ward, self:GetTeleportOffset(ward.pos,100.01),expiresAt)
			end
		end
	end
	for i = 1, LocalGameMinionCount() do
		local minion = LocalGameMinion(i);
		if minion and minion.isEnemy and not _cachedTeleports[minion.networkID] then
			local hasBuff, expiresAt = self:HasBuff(minion, "teleport_target")
			if hasBuff then
				self:RecordTeleport(minion, self:GetTeleportOffset(minion.pos,143.25),expiresAt)
			end
		end
	end	
end

function HPred:RecordTeleport(target, aimPos, endTime)
	_cachedTeleports[target.networkID] = {}
	_cachedTeleports[target.networkID]["target"] = target
	_cachedTeleports[target.networkID]["aimPos"] = aimPos
	_cachedTeleports[target.networkID]["expireTime"] = endTime + LocalGameTimer()
end


function HPred:CalculateIncomingDamage()
	_incomingDamage = {}
	local currentTime = LocalGameTimer()
	for _, missile in _pairs(_cachedMissiles) do
		if missile then 
			local dist = self:GetDistance(missile.data.pos, missile.target.pos)			
			if missile.name == "" or currentTime >= missile.timeout or dist < missile.target.boundingRadius then
				_cachedMissiles[_] = nil
			else
				if not _incomingDamage[missile.target.networkID] then
					_incomingDamage[missile.target.networkID] = missile.damage
				else
					_incomingDamage[missile.target.networkID] = _incomingDamage[missile.target.networkID] + missile.damage
				end
			end
		end
	end	
end

function HPred:GetIncomingDamage(target)
	local damage = 0
	if _incomingDamage[target.networkID] then
		damage = _incomingDamage[target.networkID]
	end
	return damage
end

local _maxCacheRange = 3000
function HPred:CacheParticles()	
	if _windwall and _windwall.name == "" then
		_windwall = nil
	end
	
	for i = 1, LocalGameParticleCount() do
		local particle = LocalGameParticle(i)		
		if particle and self:IsInRange(particle.pos, myHero.pos, _maxCacheRange) then			
			if _find(particle.name, "W_windwall%d") and not _windwall then
				local owner =  self:GetObjectByHandle(particle.handle)
				if owner and owner.isEnemy then
					_windwall = particle
					_windwallStartPos = Vector(particle.pos.x, particle.pos.y, particle.pos.z)
					local index = _len(particle.name) - 5
					local spellLevel = _sub(particle.name, index, index) -1
					if type(spellLevel) ~= "number" then
						spellLevel = 1
					end
					_windwallWidth = 150 + spellLevel * 25					
				end
			end
		end
	end
end

function HPred:CacheMissiles()
	local currentTime = LocalGameTimer()
	for i = 1, LocalGameMissileCount() do
		local missile = LocalGameMissile(i)
		if missile and not _cachedMissiles[missile.networkID] and missile.missileData then
			if missile.missileData.target and missile.missileData.owner then
				local missileName = missile.missileData.name
				local owner =  self:GetObjectByHandle(missile.missileData.owner)	
				local target =  self:GetObjectByHandle(missile.missileData.target)		
				if owner and target and _find(target.type, "Hero") then
					if (_find(missileName, "BasicAttack") or _find(missileName, "CritAttack")) then
						_cachedMissiles[missile.networkID] = {}
						_cachedMissiles[missile.networkID].target = target
						_cachedMissiles[missile.networkID].data = missile
						_cachedMissiles[missile.networkID].danger = 1
						_cachedMissiles[missile.networkID].timeout = currentTime + 1.5
						local damage = owner.totalDamage
						if _find(missileName, "CritAttack") then
							damage = damage * 1.5
						end						
						_cachedMissiles[missile.networkID].damage = self:CalculatePhysicalDamage(target, damage)
					end
				end
			end
		end
	end
end

function HPred:CalculatePhysicalDamage(target, damage)			
	local targetArmor = target.armor * myHero.armorPenPercent - myHero.armorPen
	local damageReduction = 100 / ( 100 + targetArmor)
	if targetArmor < 0 then
		damageReduction = 2 - (100 / (100 - targetArmor))
	end		
	damage = damage * damageReduction	
	return damage
end

function HPred:CalculateMagicDamage(target, damage)			
	local targetMR = target.magicResist * myHero.magicPenPercent - myHero.magicPen
	local damageReduction = 100 / ( 100 + targetMR)
	if targetMR < 0 then
		damageReduction = 2 - (100 / (100 - targetMR))
	end		
	damage = damage * damageReduction
	return damage
end


function HPred:GetTeleportingTarget(source, range, delay, speed, timingAccuracy, checkCollision, radius)
	local target
	local aimPosition
	for _, teleport in _pairs(_cachedTeleports) do
		if teleport.expireTime > LocalGameTimer() and self:IsInRange(source,teleport.aimPos, range) then			
			local spellInterceptTime = self:GetSpellInterceptTime(source, teleport.aimPos, delay, speed)
			local teleportRemaining = teleport.expireTime - LocalGameTimer()
			if spellInterceptTime > teleportRemaining and spellInterceptTime - teleportRemaining <= timingAccuracy and (not checkCollision or not self:CheckMinionCollision(source, teleport.aimPos, delay, speed, radius)) then								
				target = teleport.target
				aimPosition = teleport.aimPos
				return target, aimPosition
			end
		end
	end		
end

function HPred:GetTargetMS(target)
	local ms = target.pathing.isDashing and target.pathing.dashSpeed or target.ms
	return ms
end

function HPred:Angle(A, B)
	local deltaPos = A - B
	local angle = _atan(deltaPos.x, deltaPos.z) *  180 / _pi	
	if angle < 0 then angle = angle + 360 end
	return angle
end

function HPred:PredictUnitPosition(unit, delay)
	local predictedPosition = unit.pos
	local timeRemaining = delay
	local pathNodes = self:GetPathNodes(unit)
	for i = 1, #pathNodes -1 do
		local nodeDistance = self:GetDistance(pathNodes[i], pathNodes[i +1])
		local nodeTraversalTime = nodeDistance / self:GetTargetMS(unit)
		if timeRemaining > nodeTraversalTime then
			timeRemaining =  timeRemaining - nodeTraversalTime
			predictedPosition = pathNodes[i + 1]
		else
			local directionVector = (pathNodes[i+1] - pathNodes[i]):Normalized()
			predictedPosition = pathNodes[i] + directionVector *  self:GetTargetMS(unit) * timeRemaining
			break;
		end
	end
	return predictedPosition
end

function HPred:IsChannelling(target, interceptTime)
	if target.activeSpell and target.activeSpell.valid and target.activeSpell.isChanneling then
		return true
	end
end

function HPred:HasBuff(target, buffName, minimumDuration)
	local duration = minimumDuration
	if not minimumDuration then
		duration = 0
	end
	local durationRemaining
	for i = 1, target.buffCount do 
		local buff = target:GetBuff(i)
		if buff.duration > duration and buff.name == buffName then
			durationRemaining = buff.duration
			return true, durationRemaining
		end
	end
end

function HPred:GetTeleportOffset(origin, magnitude)
	local teleportOffset = origin + (self:GetEnemyNexusPosition()- origin):Normalized() * magnitude
	return teleportOffset
end

function HPred:GetSpellInterceptTime(startPos, endPos, delay, speed)	
	local interceptTime = Game.Latency()/2000 + delay + self:GetDistance(startPos, endPos) / speed
	return interceptTime
end

function HPred:CanTarget(target, allowInvisible)
	return target.isEnemy and target.alive and target.health > 0  and (allowInvisible or target.visible) and target.isTargetable
end

function HPred:CanTargetALL(target)
	return target.alive and target.health > 0 and target.visible and target.isTargetable
end

function HPred:UnitMovementBounds(unit, delay, reactionTime)
	local startPosition = self:PredictUnitPosition(unit, delay)
	local radius = 0
	local deltaDelay = delay -reactionTime- self:GetImmobileTime(unit)	
	if (deltaDelay >0) then
		radius = self:GetTargetMS(unit) * deltaDelay	
	end
	return startPosition, radius	
end

function HPred:GetImmobileTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i);
		if buff.count > 0 and buff.duration> duration and (buff.type == 5 or buff.type == 8 or buff.type == 21 or buff.type == 22 or buff.type == 24 or buff.type == 11 or buff.type == 29 or buff.type == 30 or buff.type == 39 ) then
			duration = buff.duration
		end
	end
	return duration		
end

function HPred:isSlowed(unit, delay, speed, from)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i);
		if from and unit and buff.count > 0 and buff.duration>=(delay + GetDistance(unit.pos, from) / speed) then
			if (buff.type == 10) then
				return true
			end
		end
	end
	return false
end

function HPred:GetSlowedTime(unit)
	local duration = 0
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i);
		if buff.count > 0 and buff.duration > duration and buff.type == 10 then
			duration = buff.duration			
			return duration
		end
	end
	return duration		
end

function HPred:GetPathNodes(unit)
	local nodes = {}
	_insert(nodes, unit.pos)
	if unit.pathing.hasMovePath then
		for i = unit.pathing.pathIndex, unit.pathing.pathCount do
			path = unit:GetPath(i)
			_insert(nodes, path)
		end
	end		
	return nodes
end

function HPred:GetObjectByHandle(handle)
	local target
	for i = 1, LocalGameHeroCount() do
		local enemy = LocalGameHero(i)
		if enemy and enemy.handle == handle then
			target = enemy
			return target
		end
	end
	for i = 1, LocalGameMinionCount() do
		local minion = LocalGameMinion(i)
		if minion and minion.handle == handle then
			target = minion
			return target
		end
	end
	for i = 1, LocalGameWardCount() do
		local ward = LocalGameWard(i);
		if ward and ward.handle == handle then
			target = ward
			return target
		end
	end
	for i = 1, LocalGameTurretCount() do 
		local turret = LocalGameTurret(i)
		if turret and turret.handle == handle then
			target = turret
			return target
		end
	end
	for i = 1, LocalGameParticleCount() do 
		local particle = LocalGameParticle(i)
		if particle and particle.handle == handle then
			target = particle
			return target
		end
	end
end

function HPred:GetHeroByPosition(position)
	local target
	for i = 1, LocalGameHeroCount() do
		local enemy = LocalGameHero(i)
		if enemy and enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
end

function HPred:GetObjectByPosition(position)
	local target
	for i = 1, LocalGameHeroCount() do
		local enemy = LocalGameHero(i)
		if enemy and enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
	for i = 1, LocalGameMinionCount() do
		local enemy = LocalGameMinion(i)
		if enemy and enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
	for i = 1, LocalGameWardCount() do
		local enemy = LocalGameWard(i);
		if enemy and enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
	for i = 1, LocalGameParticleCount() do 
		local enemy = LocalGameParticle(i)
		if enemy and enemy.pos.x == position.x and enemy.pos.y == position.y and enemy.pos.z == position.z then
			target = enemy
			return target
		end
	end
end

function HPred:GetEnemyHeroByHandle(handle)	
	local target
	for i = 1, LocalGameHeroCount() do
		local enemy = LocalGameHero(i)
		if enemy and enemy.handle == handle then
			target = enemy
			return target
		end
	end
end

function HPred:GetNearestParticleByNames(origin, names)
	local target
	local distance = 999999
	for i = 1, LocalGameParticleCount() do 
		local particle = LocalGameParticle(i)
		if particle then 
			local d = self:GetDistance(origin, particle.pos)
			if d < distance then
				distance = d
				target = particle
			end
		end
	end
	return target, distance
end

function HPred:GetPathLength(nodes)
	local result = 0
	for i = 1, #nodes -1 do
		result = result + self:GetDistance(nodes[i], nodes[i + 1])
	end
	return result
end

function HPred:CheckMinionCollision(origin, endPos, delay, speed, radius, frequency)
	if not frequency then
		frequency = radius
	end
	local directionVector = (endPos - origin):Normalized()
	local checkCount = self:GetDistance(origin, endPos) / frequency
	for i = 1, checkCount do
		local checkPosition = origin + directionVector * i * frequency
		local checkDelay = delay + self:GetDistance(origin, checkPosition) / speed
		if self:IsMinionIntersection(checkPosition, radius, checkDelay, radius * 3) then
			return true
		end
	end
	return false
end

function HPred:IsMinionIntersection(location, radius, delay, maxDistance)
	if not maxDistance then
		maxDistance = 500
	end
	for i = 1, LocalGameMinionCount() do
		local minion = LocalGameMinion(i)
		if minion and self:CanTarget(minion) and self:IsInRange(minion.pos, location, maxDistance) then
			local predictedPosition = self:PredictUnitPosition(minion, delay)
			if self:IsInRange(location, predictedPosition, radius + minion.boundingRadius) then
				return true
			end
		end
	end
	return false
end

function HPred:VectorPointProjectionOnLineSegment(v1, v2, v)
	assert(v1 and v2 and v, "VectorPointProjectionOnLineSegment: wrong argument types (3 <Vector> expected)")
	local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
	local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) * (bx - ax) + (by - ay) * (by - ay))
	local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
	local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
	local isOnSegment = rS == rL
	local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
	return pointSegment, pointLine, isOnSegment
end

function HPred:IsWindwallBlocking(source, target)
	if _windwall then
		local windwallFacing = (_windwallStartPos-_windwall.pos):Normalized()
		return self:DoLineSegmentsIntersect(source, target, _windwall.pos + windwallFacing:Perpendicular() * _windwallWidth, _windwall.pos + windwallFacing:Perpendicular2() * _windwallWidth)
	end	
	return false
end

function HPred:DoLineSegmentsIntersect(A, B, C, D)
	local o1 = self:GetOrientation(A, B, C)
	local o2 = self:GetOrientation(A, B, D)
	local o3 = self:GetOrientation(C, D, A)
	local o4 = self:GetOrientation(C, D, B)
	if o1 ~= o2 and o3 ~= o4 then
		return true
	end
	if o1 == 0 and self:IsOnSegment(A, C, B) then return true end
	if o2 == 0 and self:IsOnSegment(A, D, B) then return true end
	if o3 == 0 and self:IsOnSegment(C, A, D) then return true end
	if o4 == 0 and self:IsOnSegment(C, B, D) then return true end
	
	return false
end

function HPred:GetOrientation(A,B,C)
	local val = (B.z - A.z) * (C.x - B.x) -
		(B.x - A.x) * (C.z - B.z)
	if val == 0 then
		return 0
	elseif val > 0 then
		return 1
	else
		return 2
	end
	
end

function HPred:IsOnSegment(A, B, C)
	return B.x <= _max(A.x, C.x) and 
		B.x >= _min(A.x, C.x) and
		B.z <= _max(A.z, C.z) and
		B.z >= _min(A.z, C.z)
end

function HPred:GetSlope(A, B)
	return (B.z - A.z) / (B.x - A.x)
end

function HPred:GetEnemyByName(name)
	local target
	for i = 1, LocalGameHeroCount() do
		local enemy = LocalGameHero(i)
		if enemy and enemy.isEnemy and enemy.charName == name then
			target = enemy
			return target
		end
	end
end

function HPred:IsPointInArc(source, origin, target, angle, range)
	local deltaAngle = _abs(HPred:Angle(origin, target) - HPred:Angle(source, origin))
	if deltaAngle < angle and self:IsInRange(origin,target,range) then
		return true
	end
end

function HPred:GetDistanceSqr(p1, p2)
	if not p1 or not p2 then
		local dInfo = debug.getinfo(2)
		print("Undefined GetDistanceSqr target. Please report. Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
		return _huge
	end
	return (p1.x - p2.x) *  (p1.x - p2.x) + ((p1.z or p1.y) - (p2.z or p2.y)) * ((p1.z or p1.y) - (p2.z or p2.y)) 
end

function HPred:IsInRange(p1, p2, range)
	if not p1 or not p2 then
		local dInfo = debug.getinfo(2)
		print("Undefined IsInRange target. Please report. Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
		return false
	end
	return (p1.x - p2.x) *  (p1.x - p2.x) + ((p1.z or p1.y) - (p2.z or p2.y)) * ((p1.z or p1.y) - (p2.z or p2.y)) < range * range 
end

function HPred:GetDistance(p1, p2)
	if not p1 or not p2 then
		local dInfo = debug.getinfo(2)
		_print("Undefined GetDistance target. Please report. Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
		return _huge
	end
	return _sqrt(self:GetDistanceSqr(p1, p2))
end
