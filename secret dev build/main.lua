Althorsemen = RegisterMod("Alt Horsemen",1)
local mod = Althorsemen
local game = Game()
local sfx = SFXManager()
local rng = RNG()

local firstLoaded = true
local loadText = "Alt Horsemen v4.15 (+Death)"
local loadTextFailed = "Alt Horsemen load failed (STAGEAPI Disabled)"

------------------------BOSSES------------------------
------------------------------------------------------

--FAMINE2--------------------
mod.Famine2 = {
	name = "Tainted Famine",
	nameAlt = "Tainted Famine Alt",
	portrait = "gfx/bosses/famine2/portrait_famine2.png",
	portraitAlt = "gfx/bosses/famine2/portrait_famine2_dross.png",
	bossName = "gfx/bosses/famine2/bossname_famine2.png",
	weight = 1,
	weightAlt = 1,
	id = 630,
	variant = 101,
	bal = {
		idleWaitMin = 20,
		idleWaitMax = 50,
		moveWaitMin = 5,
		moveWaitMax = 40,
		attackFriction = 0.85,
		speed = 1.2,
		swirlShotStrength = 9,
		chargeSpeed = 1.3,
		splashChargeSpeed = 1.1,
		splashForce = 15,
		splashRange = 10,
		chargeDistMin = -200,
		chargeDistMax = 20,
		chargeOvershoot = 30,
		phase2Health = 0.35,
		subchaseAccel = 0.45,
		subchaseVelocity = 10,
		subchaseTime = 120,
		subchasePlus = 40,
		watergunTime = 200,
		watergunPlus = 50,
		watergunShotStrength = 11.5,
		watergunShotScale = 4,
		watergunShotTime = 14,
		watergunShotPause = 8,
		watergunScatter = 25,
		watergunFriction = 1.008
	}
}
local f2 = mod.Famine2

function mod:Famine2AI(npc)
	local sprite = npc:GetSprite()
	local d = npc:GetData()
	local target = npc:GetPlayerTarget()
	local level = game:GetLevel()
	local room = game:GetRoom()

	--INIT
	if not d.init then
		d.init = true
		
		npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		
		if (level:GetStage() == LevelStage.STAGE1_1 or level:GetStage() == LevelStage.STAGE1_2)
		and level:GetStageType() == StageType.STAGETYPE_REPENTANCE_B then
			d.altSkin = true
		end
		
		if d.altSkin == true then
			d.tearType = ProjectileVariant.PROJECTILE_PUKE
			d.waterColor = Color(0.6,0.5,0.3)
		else
			d.tearType = ProjectileVariant.PROJECTILE_TEAR
			d.waterColor = Color.Default
		end

		d.movesBeforeCharge = 1 + mod:RandomInt(3)	
		d.state = "idle"
	end
	
	--IDLE
	if d.state == "idle" then
		
		mod:SpritePlay(sprite, "Idle")
		
		if not d.idleWait then
			d.idleWait = mod:RandomInt(f2.bal.idleWaitMin,f2.bal.idleWaitMax)
		end
		
		if d.idleWait <= 0 then
			--idle time finish
			d.idleWait = nil
			d.moveWait = nil
			d.movesBeforeCharge = d.movesBeforeCharge - 1
			
			d.dice = mod:RandomInt(2)
			if d.movesBeforeCharge <= 0 then
				d.dice = 3
			end
			
			if d.dice == 1 then
				local enemyNum = mod:CountRoom(EntityType.ENTITY_SMALL_LEECH,0)
				if enemyNum <= 4 then 
					d.state = "cough"
				else
					d.state = "spew"
				end
			elseif d.dice == 2 then
				d.state = "spew"
			elseif d.dice == 3 then
				d.state = "charge"
			end
			
		else
			d.idleWait = d.idleWait - 1
		end
		
		--float move
		if not d.moveWait then
			d.moveWait = mod:RandomInt(f2.bal.moveWaitMin,f2.bal.moveWaitMax)
			d.targetvelocity = ((target.Position - npc.Position):Normalized()*2):Rotated(-50+mod:RandomInt(100))
		end
		
		if d.moveWait <= 0 and d.moveWait ~= nil then
			d.moveWait = nil
		else
			d.moveWait = d.moveWait - 1
		end
		
		npc.Friction = 1
		npc.Velocity = ((d.targetvelocity * 0.3) + (npc.Velocity * 0.7)) * f2.bal.speed
		d.targetvelocity = d.targetvelocity * 0.99
	end
	
	--COUGH
	if d.state == "cough" then
		mod:SpritePlay(sprite, "Cough")
		
		if sprite:IsFinished("Cough") then
			d.state = "idle"
		elseif sprite:IsEventTriggered("Shoot") then
			
			d.dice = mod:RandomInt(2)
			if d.dice == 1 then
				local spider = EntityNPC.ThrowSpider(npc.Position, npc, npc.Position + Vector(mod:RandomInt(-50, 50), mod:RandomInt(50, 80)), false, -40)
				spider:ToNPC():Morph(810,0,0,-1)
			elseif d.dice == 2 then
				for i=1,2 do
					local spider = EntityNPC.ThrowSpider(npc.Position, npc, npc.Position + Vector(mod:RandomInt(-50, 50), mod:RandomInt(50, 80)), false, -40)
					spider:ToNPC():Morph(810,0,0,-1)
				end
			end
			npc:PlaySound(SoundEffect.SOUND_MONSTER_GRUNT_0, 1, 0, false, 1)
		end
		npc.Friction = f2.bal.attackFriction
	end
	
	--SPEW
	if d.state == "spew" then
		mod:SpritePlay(sprite, "Spew")
		
		if sprite:IsFinished("Spew") and d.SpewAction == nil then
			d.state = "idle"
		end
		
		if sprite:IsEventTriggered("Shoot") then
		
			d.spewR = mod:RandomInt(60)
			d.spewD = mod:RandomInt(2)
			d.spewAction = true
		end
		
		if d.spewAction ~= nil then
		
			if not d.shootSeq then
				d.shootSeq = 24 + mod:RandomInt(6)
			end
			
			if d.shootSeq % 2 == 0 then
				local seq = d.shootSeq
				if (d.spewD == 2) then
					seq = seq * -1
				end
				local vector = Vector(math.cos((d.spewR+seq)*math.pi/14),math.sin((d.spewR+seq)*math.pi/14)):Resized(f2.bal.swirlShotStrength)
				Isaac.Spawn(EntityType.ENTITY_PROJECTILE, d.tearType, 0,npc.Position, vector, npc)
				npc:PlaySound(SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1)
			end
			
			if d.shootSeq <= 0 and d.shootSeq ~= nil then
				--spew sequence finish
				d.shootSeq = nil
				d.spewAction = nil
				d.spewR = nil
				d.spewD = nil
			else
				d.shootSeq = d.shootSeq - 1
			end
		end
		npc.Friction = f2.bal.attackFriction
	end
	
	--CHARGE
	if d.state == "charge" then
		local cWrap = 90
		--init
		if not d.substate then
		
			mod:SpritePlay(sprite,"AttackDashStart")
			npc:PlaySound(SoundEffect.SOUND_MONSTER_YELL_A, 1, 0, false, 1)
			npc.Velocity = Vector(0,0)
			if target.Position.X < npc.Position.X then
				d.roomBegin, d.roomEnd, d.dir, sprite.FlipX = mod:HorseChargeSetup(-1,cWrap)
			else
				d.roomBegin, d.roomEnd, d.dir, sprite.FlipX = mod:HorseChargeSetup(1,cWrap)
			end
			
			d.substate = 1
		---start charge
		elseif d.substate == 1 then
			npc.Friction = f2.bal.attackFriction
			if sprite:IsEventTriggered("Shoot") then
				d.substate = 2
			end
		--charge first
		elseif d.substate == 2 then
		
			if sprite:IsFinished("AttackDashStart") then
				mod:SpritePlay(sprite,"AttackDash")
			end
			npc.Velocity = Vector(15*f2.bal.chargeSpeed*d.dir, 0)
			npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_Y
			if (npc.Position.X > d.roomEnd and d.dir == 1) or (npc.Position.X < d.roomEnd and d.dir == -1) then
				mod:SpritePlay(sprite,"AttackDashSub")
				--npc.Position = Vector(d.roomBegin,(room:GetGridHeight() * 32))
				npc.Position = Vector(d.roomBegin,(target.Position.Y + room:GetCenterPos().Y) / 2)
				npc:PlaySound(SoundEffect.SOUND_BOSS2INTRO_WATER_EXPLOSION, 1, 0, false, 1)
				npc:PlaySound(SoundEffect.SOUND_BOSS2_WATERTHRASHING, 1, 0, false, 1)
				game:SpawnParticles(Vector(npc.Position.X,npc.Position.Y), EffectVariant.BIG_SPLASH, 1, 0.4,d.waterColor)
				d.substate = 3
			end			
		--charge splash
		elseif d.substate == 3 then
		
			npc.Velocity = Vector(15*f2.bal.splashChargeSpeed*d.dir, 0)
			npc.Friction = 0.8
			
			game:SpawnParticles(Vector(npc.Position.X+(60*d.dir),npc.Position.Y), EffectVariant.WATER_SPLASH, 1, 0.4,d.waterColor)
			local params = ProjectileParams()
			params.HeightModifier = 15
			params.Variant = d.tearType
			npc:FireBossProjectiles(1,Vector(npc.Position.X-(f2.bal.splashForce*d.dir),npc.Position.Y+mod:RandomInt(-f2.bal.splashRange,f2.bal.splashRange)), 0,params)
			--npc:FireBossProjectiles(1,target.Position, 0,params)
			
			if (npc.Position.X > d.roomEnd and d.dir == 1) or (npc.Position.X < d.roomEnd and d.dir == -1) then
				mod:SpritePlay(sprite,"AttackDash")
				npc.Position = Vector(d.roomBegin,target.Position.Y + mod:RandomInt(-10,10))
				d.targetPos = (room:GetGridWidth() * 40)/2 + (mod:RandomInt(f2.bal.chargeDistMin,f2.bal.chargeDistMax)*d.dir)
				d.substate = 4
			end	
		--charge end
		elseif d.substate == 4 then
		
			npc.Velocity = Vector(15*f2.bal.chargeSpeed*d.dir, 0)
			npc.Friction = 1
			
			if (npc.Position.X > d.targetPos and d.dir == 1) or (npc.Position.X < d.targetPos and d.dir == -1) then
				mod:SpritePlay(sprite, "Idle")
				npc.Velocity = npc.Velocity * 0.8
				npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
				
				if (npc.Position.X > d.targetPos + (f2.bal.chargeOvershoot*d.dir) and d.dir == 1) 
				or (npc.Position.X < d.targetPos + (f2.bal.chargeOvershoot*d.dir) and d.dir == -1) then
					--end sequence
					d.targetPos = nil
					d.substate = nil
					d.roomEnd = nil
					d.roomBegin = nil
					d.dir = nil
					d.movesBeforeCharge = 2 + mod:RandomInt(4)	
					d.idleWait = mod:RandomInt(2,6)
					d.state = "idle"
				end
			end	
		end
	end
	
	--PHASE 2 INIT
	if npc.HitPoints <= npc.MaxHitPoints*f2.bal.phase2Health and not d.phase2 then
		d.phase2 = true
		sprite.FlipX = false
		npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		--npc:PlaySound(SoundEffect.SOUND_DEATH_BURST_LARGE, 1, 0, false, 1)
		--game:SpawnParticles(npc.Position, EffectVariant.BLOOD_EXPLOSION, 1, 1)
		npc:BloodExplode()
		local enemyNum
		for i=1, 3 do			
			enemyNum = mod:CountRoom(EntityType.ENTITY_SMALL_LEECH,0)
			if enemyNum <= 4 then
				local spider = EntityNPC.ThrowSpider(npc.Position, npc, npc.Position + Vector(mod:RandomInt(-50, 50), mod:RandomInt(20, 40)), false, -80)
				spider:ToNPC():Morph(810,0,0,-1)
			end
		end
		npc.Friction = 0.1
		
		d.state = "submerge"
	end
	
	--SUBMERGE
	if d.state == "submerge" then
		
		if sprite:IsFinished("HeadSubStart") then
			d.subChase = true
		elseif sprite:IsEventTriggered("Shoot") then
			game:SpawnParticles(npc.Position, EffectVariant.BIG_SPLASH, 1, 1,d.waterColor)
			local params = ProjectileParams()
			params.HeightModifier = 15
			params.Variant = d.tearType
			npc:FireBossProjectiles(20,Vector(0,0),0,params)
			npc:PlaySound(SoundEffect.SOUND_BOSS2INTRO_WATER_EXPLOSION, 1, 0, false, 1)
		end
		
		if d.subChase ~= nil then
			mod:SpritePlay(sprite, "HeadSub")
			npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
			mod:RubberbandRun(npc, d, target.Position, f2.bal.subchaseAccel, f2.bal.subchaseVelocity)
			
			if not d.chaseSeq then
				npc.Friction = 1
				d.chaseSeq = f2.bal.subchaseTime + mod:RandomInt(f2.bal.subchasePlus)
			end
			
			if d.chaseSeq % 2 == 0 then
				game:SpawnParticles(npc.Position, EffectVariant.WATER_SPLASH, 1, 0.4,d.waterColor)
				local params = ProjectileParams()
				params.HeightModifier = 10
				params.Variant = d.tearType
				params.VelocityMulti = 1
				params.CircleAngle = 60
				params.FallingAccelModifier = 1.2
				params.PositionOffset = Vector(mod:RandomInt(-20,20),15)
				npc:FireBossProjectiles(1,npc.Position, 0,params)
				npc:PlaySound(SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1)
			end
			
			if d.chaseSeq <= 0 and d.chaseSeq ~= nil then
				--chase sequence finish
				d.chaseSeq = nil
				d.subChase = nil
				d.state = "watergun"
			else
				d.chaseSeq = d.chaseSeq - 1
			end
		else
			mod:SpritePlay(sprite, "HeadSubStart")
		end
	end
	
	--WATERGUN
	if d.state == "watergun" then
		
		local tarDir = target.Position - npc.Position
		if d.hit ~= nil then
			if d.hit > npc.HitPoints then
				npc.Velocity = (npc.Position-target.Position):Normalized() * 4
			end
			d.hit = npc.HitPoints
		end
				
		npc.Friction = f2.bal.watergunFriction
		
		if not d.exhaust then
			if sprite:IsFinished("HeadSubEnd") then
				d.subShoot = true
			elseif sprite:IsEventTriggered("Shoot") then
				game:SpawnParticles(npc.Position, EffectVariant.BIG_SPLASH, 1, 1,d.waterColor)
				local params = ProjectileParams()
				params.HeightModifier = 15
				params.Variant = d.tearType
				npc:FireBossProjectiles(20,Vector(0,0),0,params)
				npc:PlaySound(SoundEffect.SOUND_BOSS2INTRO_WATER_EXPLOSION, 1, 0, false, 1)
				d.hit = npc.HitPoints
			end
		
			if d.subShoot ~= nil then
				
				--head rotation logic
				local faceDir = math.atan(tarDir.Y/tarDir.X)
				if faceDir < 0 then
					faceDir = faceDir * -1
				end

				if target.Position.Y > npc.Position.Y and target.Position.X < npc.Position.X and faceDir > 0.78 and faceDir < 1.28 then
					mod:SpritePlay(sprite, "Watergun01")
				elseif target.Position.Y > npc.Position.Y and target.Position.X < npc.Position.X and faceDir > 0.28 and faceDir < 0.78 then
					mod:SpritePlay(sprite, "Watergun02")
				elseif target.Position.X < npc.Position.X and faceDir < 0.28 then
					mod:SpritePlay(sprite, "Watergun03")
				elseif target.Position.Y < npc.Position.Y and target.Position.X < npc.Position.X and faceDir > 0.28 and faceDir < 0.78 then
					mod:SpritePlay(sprite, "Watergun04")
				elseif target.Position.Y < npc.Position.Y and target.Position.X < npc.Position.X and faceDir > 0.78 and faceDir < 1.28 then
					mod:SpritePlay(sprite, "Watergun05")
				elseif target.Position.Y < npc.Position.Y and faceDir > 1.28 then
					mod:SpritePlay(sprite, "Watergun06")
				elseif target.Position.Y < npc.Position.Y and target.Position.X > npc.Position.X and faceDir > 0.78 and faceDir < 1.28 then
					mod:SpritePlay(sprite, "Watergun07")
				elseif target.Position.Y < npc.Position.Y and target.Position.X > npc.Position.X and faceDir > 0.28 and faceDir < 0.78 then
					mod:SpritePlay(sprite, "Watergun08")
				elseif target.Position.X > npc.Position.X and faceDir < 0.28 then
					mod:SpritePlay(sprite, "Watergun09")
				elseif target.Position.Y > npc.Position.Y and target.Position.X > npc.Position.X and faceDir > 0.28 and faceDir < 0.78 then
					mod:SpritePlay(sprite, "Watergun10")
				elseif target.Position.Y > npc.Position.Y and target.Position.X > npc.Position.X and faceDir > 0.78 and faceDir < 1.28 then
					mod:SpritePlay(sprite, "Watergun11")
				else
					mod:SpritePlay(sprite, "Watergun00")
				end
				
				--attack logic
				npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
				
				if not d.watergunSeq then
					d.watergunSeq = f2.bal.watergunTime + mod:RandomInt(f2.bal.watergunPlus)
					d.watergunShots = 0
					d.watergunPause = f2.bal.watergunShotPause
				end
				
				--leak shot
				if d.watergunSeq % 8 == 0 then
					local params = ProjectileParams()
					params.Variant = d.tearType
					params.FallingAccelModifier = 1.1
					params.HeightModifier = -18
					npc:FireBossProjectiles(1,target.Position, 0,params)
				end
				
				--stream shot
				if d.watergunSeq % 2 == 0 then
					
					if d.watergunShots >= f2.bal.watergunShotTime then
						d.watergunShots = 0
						d.watergunPause = f2.bal.watergunShotPause
					end
				
					if d.watergunPause > 0 then
						d.watergunPause = d.watergunPause - 1
					else
						d.watergunShots = d.watergunShots + 1
					
						local params = ProjectileParams()
						params.Variant = d.tearType
						params.HeightModifier = -18
						params.Scale = mod:RandomInt(f2.bal.watergunShotScale, f2.bal.watergunShotScale+5)/10
						--params.FallingAccelModifier = mod:RandomInt(10)/100
						local scatter = Vector(mod:RandomInt(-f2.bal.watergunScatter,f2.bal.watergunScatter),mod:RandomInt(-f2.bal.watergunScatter,f2.bal.watergunScatter))
						
						npc:FireProjectiles(npc.Position,(tarDir + scatter):Normalized() * f2.bal.watergunShotStrength,0,params)
						npc:PlaySound(SoundEffect.SOUND_BLOODSHOOT, 1, 0, false, 1)
					end
				end
				
				if d.watergunSeq <= 0 and d.watergunSeq ~= nil then
					mod:SpritePlay(sprite, "HeadExhaust")
					d.exhaust = true
				else
					d.watergunSeq = d.watergunSeq - 1
				end
			else
				mod:SpritePlay(sprite, "HeadSubEnd")
			end
		else
			if sprite:IsFinished("HeadExhaust") then
				--shoot sequence finish
				d.watergunSeq = nil
				d.watergunShots = nil
				d.watergunPause = nil
				d.subShoot = nil
				d.exhaust = nil
				d.hit = nil
				d.state = "submerge"
			elseif sprite:IsEventTriggered("Shoot") then
				local params = ProjectileParams()
				params.Variant = d.tearType
				params.FallingAccelModifier = 0.1
				params.HeightModifier = -15
				npc:FireBossProjectiles(10,target.Position, 0,params)
				npc:PlaySound(SoundEffect.SOUND_MONSTER_GRUNT_4, 1, 0, false, 1)
				
				d.dice = mod:RandomInt(3)
				if d.dice == 1 then
					local spider = EntityNPC.ThrowSpider(npc.Position, npc, npc.Position + Vector(mod:RandomInt(-20, 20), mod:RandomInt(20, 40)), false, -80)
					spider:ToNPC():Morph(810,0,0,-1)
				elseif d.dice == 2 then
					for i=1,2 do
						local spider = EntityNPC.ThrowSpider(npc.Position, npc, npc.Position + Vector(mod:RandomInt(-20, 20), mod:RandomInt(20, 40)), false, -80)
						spider:ToNPC():Morph(810,0,0,-1)
					end
				end
			end
		end
	end
	
	--death
	if npc:IsDead() then
		if d.state == "watergun" or d.chaseSeq then
			local params = ProjectileParams()
			params.HeightModifier = 10
			params.Variant = d.tearType
			npc:FireBossProjectiles(20,Vector(0,0),0,params)
		end
	end
end

mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.Famine2AI, f2.id)

--WAR2--------------------

mod.War2 = {
	name = "Tainted War",
	nameAlt = "Tainted War Alt",
	portrait = "gfx/bosses/war2/portrait_war2.png",
	portraitAlt = "gfx/bosses/war2/portrait_war2_ashpit.png",
	bossName = "gfx/bosses/war2/bossname_war2.png",
	weight = 2,
	weightAlt = 2,
	id = 650,
	variant = 101,
	army = {
		name = "Army",
		id = 651,
		variant = 101,
		variantBomb = 102,
		reflectChance = 2,
		walkingBombDamage = 20,
		bombDamage = 30,
		bombPower = 17,
		bombCountdown = 22,
		speed = 3.5,
		roomSpawnDist = 100,
		roomDelay = 50,
		roomBombDelay = 20,
		hpBuffAmount = 3,
	},
	bal = {
		idleWaitMin = 40,
		idleWaitMax = 70,
		moveWaitMin = 20,
		moveWaitMax = 30,
		attackFriction = 0.85,
		speed = 1.2,
		minionTime = 75, --horn duration
		minionDelayMin = 70,
		minionDelayMax = 120,
		minionRapidDelay = 10, --minion spawn interval during horn
		minionBigDelay = 0.6, --delay multiplier for big rooms
		minionBombLimit = 5, --limit before bombs show up
		minionSmallTotalLimit = 12, --limit in small rooms
		minionBigTotalLimit = 18, --limit in big rooms
		bombDamage = 20,
		bombPowerMin = 12,
		bombPowerMax = 15,
		bombCountdown = 25,
		bombThrowsMin = 1,
		bombThrowsMax = 3,
		scatterCountdown = 40,
		chargeSpeed = 3,
		chargeDamage = 10,
		rockPower = 10,
		rockDist = 10,
		phase2Health = 0.45,
		phase2Bomb = 20,
		walkArmor = 0.3,
		walkWait = 140,
		walkMax = 7,
		armyDistMin = 150,
		armyDistMax = 170,
		deathArmyDist = 120,
		fireAmount = 3,
		firePower = 6,
	}
}
local w2 = mod.War2

function mod:War2AI(npc)
	local sprite = npc:GetSprite()
	local d = npc:GetData()
	local path = npc.Pathfinder
	local target = npc:GetPlayerTarget()
	local level = game:GetLevel()
	local room = game:GetRoom()

	--INIT
	if not d.init then
		d.init = true
		
		npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		
		if (level:GetStage() == LevelStage.STAGE2_1 or level:GetStage() == LevelStage.STAGE2_2)
		and level:GetStageType() == StageType.STAGETYPE_REPENTANCE_B then
			d.altSkin = true
		end
		
		local roomShape = room:GetRoomShape()
		d.roomSize = "small"
		if roomShape == 4 or roomShape == 6 
		or (roomShape >= 8 and roomShape < 13) then
			d.roomSize = "big"
		end
		
		d.movesBeforeHorn = 0
		d.movesBeforeCharge = mod:RandomInt(4,5)
		d.idleWait = 10
		d.state = "idle"
	end
	
	--IDLE
	if d.state == "idle" then
		
		mod:SpritePlay(sprite, "Idle")
		
		if not d.idleWait then
			d.idleWait = mod:RandomInt(w2.bal.idleWaitMin,w2.bal.idleWaitMax)
		end
		
		if d.idleWait <= 0 then
			--idle time finish
			d.idleWait = nil
			d.moveWait = nil
			
			d.movesBeforeHorn = d.movesBeforeHorn - 1
			d.movesBeforeCharge = d.movesBeforeCharge - 1
			
			d.dice = 1
			--horn timer
			if d.movesBeforeHorn <= 0 then
				if not d.hornMoment then
					d.movesBeforeHorn = mod:RandomInt(3,5)
					d.dice = 2
				else
					d.hornMoment = nil
				end
			end
			--charge timer
			if d.movesBeforeCharge <= 0 then
				if not d.chargeMoment then
					d.movesBeforeCharge = mod:RandomInt(4,6)
					d.dice = 3
				else
					d.chargeMoment = nil
				end
			end
			
			if d.dice == 1 then
				d.state = "throwbomb"
			elseif d.dice == 2 then
				d.state = "horn"
			elseif d.dice == 3 then
				d.state = "charge"
			end
			
			--phase 2 begin
			if npc.HitPoints <= npc.MaxHitPoints*w2.bal.phase2Health and not d.phase2 then
				d.state = "bigboom"
			end
		else
			d.idleWait = d.idleWait - 1
		end
		
		--float move
		if not d.moveWait then
			d.moveWait = mod:RandomInt(w2.bal.moveWaitMin,w2.bal.moveWaitMax)
			d.targetvelocity = ((target.Position - npc.Position):Normalized()*2):Rotated(-50+mod:RandomInt(100))
		end
		
		if d.moveWait <= 0 and d.moveWait ~= nil then
			d.moveWait = nil
		else
			d.moveWait = d.moveWait - 1
		end
		
		npc.Friction = 1
		npc.Velocity = ((d.targetvelocity * 0.3) + (npc.Velocity * 0.7)) * w2.bal.speed
		d.targetvelocity = d.targetvelocity * 0.99
		
		if npc.Velocity.X < -2 then
			sprite.FlipX = true
		elseif npc.Velocity.X > 2 then
			sprite.FlipX = false
		end
	end
	
	--HORN
	if d.state == "horn" then
		mod:SpritePlay(sprite, "Horn")
		
		if sprite:IsFinished("Horn") then
			d.state = "idle"
		elseif sprite:IsEventTriggered("Shoot") then
			d.minions = true
			d.minionsRapid = true
			npc:PlaySound(SoundEffect.SOUND_FLUTE, 1.6, 0, false, 0.5)
		end
		npc.Friction = w2.bal.attackFriction
	end

	--THROW BOMB
	if d.state == "throwbomb" then
		if not d.bombType then
			d.bombType = mod:RandomInt(3)
			
			if not d.bombMoves then
				d.bombMoves = mod:RandomInt(w2.bal.bombThrowsMin-1,w2.bal.bombThrowsMax-1)
			--[[elseif d.bombMoves == 0 then
				d.bombType = mod:RandomInt(4)]]
			end

			if d.bombType == 1 then
				d.bombAnim = "ThrowBomb1"
				d.bombVariant = 0
			elseif d.bombType == 2 then
				d.bombAnim = "ThrowBomb2"
				d.bombVariant = 8
			elseif d.bombType == 3 then
				d.bombAnim = "ThrowBomb3"
				d.bombVariant = 16
			elseif d.bombType == 4 then
				d.bombAnim = "ThrowBomb4"
				d.bombVariant = 1
			end
		end
	
		mod:SpritePlay(sprite, d.bombAnim)
		
		if sprite:IsFinished(d.bombAnim) then
			d.bombType = nil
			d.bombMoves = nil
			d.state = "idle"
			
		elseif sprite:IsEventTriggered("Target") then
			d.shootVec = (target.Position - npc.Position):Resized(mod:RandomInt(w2.bal.bombPowerMin,w2.bal.bombPowerMax))
		elseif sprite:IsEventTriggered("Shoot") then
			
			if d.bombType == 1 then
				d.shootVec = (target.Position - npc.Position):Resized(mod:RandomInt(w2.bal.bombPowerMin,w2.bal.bombPowerMax))
			end
		
			npc:PlaySound(SoundEffect.SOUND_SHELLGAME, 1, 0, false, 1)
			local bombe = Isaac.Spawn(4, d.bombVariant, 0, npc.Position + d.shootVec, d.shootVec, npc):ToBomb()
			bombe:SetExplosionCountdown(w2.bal.bombCountdown)
			bombe.ExplosionDamage = w2.bal.bombDamage
			bombe:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			bombe.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
			bombe.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
			
			if d.bombType == 2 then
				bombe:AddTearFlags(TearFlags.TEAR_BURN)
			elseif d.bombType == 3 then
				bombe:AddTearFlags(TearFlags.TEAR_SAD_BOMB)
			elseif d.bombType == 4 then
				bombe:AddTearFlags(TearFlags.TEAR_SCATTER_BOMB)
				bombe:SetExplosionCountdown(w2.bal.scatterCountdown)
			end
			
			if npc.Position.X > target.Position.X then
				sprite.FlipX = true
			elseif npc.Position.X < target.Position.X then
				sprite.FlipX = false
			end
			
			if d.bombMoves > 0 then
				sprite:SetFrame(10)
				d.bombType = nil
				d.bombMoves = d.bombMoves - 1
			end
		end
		npc.Friction = w2.bal.attackFriction
	end
	
	--CHARGE
	if d.state == "charge" then
		local cWrap = 90 --charging offscreen
		local iWrap = 140 --appearing onscreen
				
		--init
		if not d.substate then
			mod:SpritePlay(sprite,"AttackDashStart")
			npc:PlaySound(SoundEffect.SOUND_MONSTER_YELL_A, 1, 0, false, 1)
			npc.Velocity = Vector(0,0)
			if target.Position.X < npc.Position.X then
				d.roomBegin, d.roomEnd, d.dir, sprite.FlipX = mod:HorseChargeSetup(-1,cWrap)
			else
				d.roomBegin, d.roomEnd, d.dir, sprite.FlipX = mod:HorseChargeSetup(1,cWrap)
			end
			
			d.substate = 1
		---start charge
		elseif d.substate == 1 then
			npc.Friction = w2.bal.attackFriction
			
			if sprite:IsEventTriggered("Flame") then
				npc:PlaySound(SoundEffect.SOUND_WAR_FLAME, 1, 0, false, 1)
			end
			
			if sprite:IsFinished("AttackDashStart") then
				mod:SpritePlay(sprite,"AttackDash")
				Isaac.Explode(npc.Position, npc, 0)
				d.substate = 2
			end
		--charge first
		elseif d.substate == 2 then
			npc.Velocity = Vector(15*w2.bal.chargeSpeed*d.dir, 0)
			npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_Y
			
			if (npc.Position.X > d.roomEnd and d.dir == 1) or (npc.Position.X < d.roomEnd and d.dir == -1) then
				if d.dir == 1 then
					d.roomBegin, d.roomEnd, d.dir, sprite.FlipX = mod:HorseChargeSetup(-1,cWrap)
				else
					d.roomBegin, d.roomEnd, d.dir, sprite.FlipX = mod:HorseChargeSetup(1,cWrap)
				end	
				mod:SpritePlay(sprite,"AttackDashAgain")
				npc.Position = Vector(d.roomBegin+(iWrap*d.dir),(target.Position.Y))
				npc.Velocity = Vector(0,0)
				d.substate = 3
			end			
		--charge windup
		elseif d.substate == 3 then
			if sprite:IsEventTriggered("Flame") then
				npc:PlaySound(SoundEffect.SOUND_WAR_FLAME, 1, 0, false, 1)
			end
		
			if sprite:IsFinished("AttackDashAgain") then
				mod:SpritePlay(sprite,"AttackDash")
				
				if not d.chargeCount then
					d.chargeCount = 2
					if d.roomSize == "big" then
						d.chargeCount = 3
					end
				end
				
				Isaac.Explode(npc.Position, npc, 0)
				d.chargeCount = d.chargeCount - 1
				d.substate = 4
			end
			npc.Velocity = Vector(0,0)
		--charge fire
		elseif d.substate == 4 then
			npc.Velocity = Vector(15*w2.bal.chargeSpeed*d.dir, 0)
			npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_Y
			
			if d.chargeCount > 0 then
			
				if (npc.Position.X > d.roomEnd and d.dir == 1) or (npc.Position.X < d.roomEnd and d.dir == -1) then	
					if d.dir == 1 then
						d.roomBegin, d.roomEnd, d.dir, sprite.FlipX = mod:HorseChargeSetup(-1,cWrap)
					else
						d.roomBegin, d.roomEnd, d.dir, sprite.FlipX = mod:HorseChargeSetup(1,cWrap)
					end	
					mod:SpritePlay(sprite,"AttackDashAgain")
					npc.Position = Vector(d.roomBegin+(iWrap*d.dir),(target.Position.Y))
					npc.Velocity = Vector(0,0)
					d.substate = 3
				end		
			else	
				if (npc.Position.X > d.roomEnd-(iWrap*d.dir) and d.dir == 1) or (npc.Position.X < d.roomEnd-(iWrap*d.dir) and d.dir == -1) then	
					mod:SpritePlay(sprite,"AttackDashCrash")
					npc:PlaySound(SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 0, false, 1)
					game:ShakeScreen(10)
					npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
					
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_ROCK
					params.GridCollision = false
					params.PositionOffset = Vector(-d.dir*2,0)
					params.Scale = 0.5
					for i=-2,2 do
						local rock = Isaac.Spawn(9, 9, 0,npc.Position+Vector(-d.dir*2,0), Vector(-d.dir*w2.bal.rockPower,0):Rotated(i*30), npc):ToProjectile()
						rock.FallingAccel = 0.1-(0.01*w2.bal.rockDist)
					end
					npc:FireBossProjectiles(3,npc.Position+Vector(-d.dir*(w2.bal.rockPower/4),0), 8,params)
					
					d.substate = 5
				end
			end
		elseif d.substate == 5 then
			npc.Velocity = npc.Velocity * 0.5
			if sprite:IsFinished("AttackDashCrash") then
				--end sequence
				d.substate = nil
				d.roomEnd = nil
				d.roomBegin = nil
				d.dir = nil
				d.chargeCount = nil
				d.state = "idle"
			end
		end
		
		--line of fire
		if d.substate == 1 or d.substate == 3 then
		
			if sprite:IsEventTriggered("Flame") then
				d.flameyFlame = true
			end	
			
			if d.flameyFlame and npc.FrameCount % 3 == 0 then
				local dirRand = mod:RandomInt(-40,40)
				local fire = Isaac.Spawn(9, ProjectileVariant.PROJECTILE_FIRE,0,Vector(npc.Position.X-(d.dir*7),npc.Position.Y), Vector(-d.dir*4,0):Rotated(dirRand), npc):ToProjectile()
			end
		end
		
		if d.substate == 2 or d.substate == 4 then
			d.flameyFlame = nil
			
			if npc.FrameCount % 3 == 0 then
				local bombe = Isaac.Spawn(4, 14, 0, npc.Position-Vector(d.dir,0), Vector(-d.dir,mod:RandomInt(-1,1)), npc):ToBomb()
				bombe.ExplosionDamage = 5
				bombe:SetExplosionCountdown(5)
				bombe.RadiusMultiplier = 0.5
				
				if npc.FrameCount % 6 == 0 then
					bombe:AddTearFlags(TearFlags.TEAR_BURN)
				end
			end
		end
	end
	
	--phase2 transition
	if d.state == "bigboom" then
	
		if not d.substate then
			d.substate = 1
			d.minions = false
			mod:SpritePlay(sprite, "BigBoomTime")
		end
		
		if sprite:IsFinished("BigBoomTime") then
			local boom = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION, 0, npc.Position, Vector(0,0), player):ToEffect()
			boom.SpriteScale = Vector(2,2)
			local boom = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 1, npc.Position, Vector(0,0), player):ToEffect()
			boom.SpriteScale = Vector(2,2)
			
			for i, entity in ipairs(Isaac.FindByType(w2.army.id, w2.army.variant)) do
				entity:Kill()
			end
			for i, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_PLAYER)) do
				entity.Velocity = (entity.Position-npc.Position):Normalized()*15
			end
			for i, entity in ipairs(Isaac.FindInRadius(npc.Position, 180, EntityPartition.ENEMY)) do
				entity:TakeDamage(w2.bal.phase2Bomb, DamageFlag.DAMAGE_EXPLOSION, EntityRef(npc), 0)
			end
			for i, entity in ipairs(Isaac.FindInRadius(npc.Position, 120, EntityPartition.PLAYER)) do
				entity:TakeDamage(2, DamageFlag.DAMAGE_EXPLOSION, EntityRef(npc), 0)
			end
			
			npc:BloodExplode()
			game:ShakeScreen(25)
			npc:TakeDamage(w2.bal.phase2Bomb, 0, EntityRef(npc), 0)
			npc:PlaySound(SoundEffect.SOUND_FLAMETHROWER_START, 1, 0, false, 1)
			npc:PlaySound(SoundEffect.SOUND_EXPLOSION_STRONG, 1, 0, false, 1)
			npc:PlaySound(SoundEffect.SOUND_MONSTER_ROAR_2, 1, 0, false, 1)
			
			npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
			
			d.phase2 = true
			mod:SpritePlay(sprite, "P2_Inferno")
			sprite:SetOverlayRenderPriority(true)
			mod:OverlayPlay(sprite,"P2_Fire")
			sprite:SetFrame(10)
		end
		
		if sprite:IsEventTriggered("Flame") then
			local dirRand = mod:RandomInt(180)
			local times = 360/w2.bal.fireAmount
			for i=0,360,times do
				local fire = Isaac.Spawn(9, ProjectileVariant.PROJECTILE_FIRE, 0,npc.Position, Vector(w2.bal.firePower,0):Rotated(i+dirRand), npc):ToProjectile()
			end
			npc:PlaySound(SoundEffect.SOUND_FLAMETHROWER_END, 1, 0, false, 1)
			game:ShakeScreen(5)
		end
		
		if sprite:IsFinished("P2_Inferno") then
			d.substate = nil
			d.minions = true
			d.minionDelay = 20
			d.idleWait = nil
			d.state = "idle2"
		end
		npc.Friction = w2.bal.attackFriction
	end
	
	--idle2
	if d.state == "idle2" then
		npc.Friction = 1
		npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
		
		if not d.idleWait then
			d.idleWait = w2.bal.walkWait
		end
		
		--increasing speed
		if target:ToPlayer() ~= nil then
			if target:ToPlayer().MoveSpeed < 1 then
				d.walkMax = (w2.bal.walkMax / 2) + (4 * target:ToPlayer().MoveSpeed)
			else
				d.walkMax = w2.bal.walkMax
			end
		end
		
		--sprite direction
		if npc.Velocity:Length() > 0.1 then
			npc:AnimWalkFrame("P2_WalkHori","P2_WalkVert",0)
		else
			sprite:SetFrame("P2_WalkVert", 0)
		end
		
		--step fire
		if sprite:IsEventTriggered("Flame") then
			local fire = Isaac.Spawn(33, 10, 0,npc.Position, -(target.Position - npc.Position):Normalized(), npc)
			fire.HitPoints = 4
			fire.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
			fire:GetSprite():Load("gfx/grid/effect_005_fire.anm2", true)
			
			local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position, Vector(0,0), npc):ToEffect()
			poof.SpriteScale = Vector(0.5,0.5)
			poof.Color = Color(0.8,0.6,0.4,1)
		end
		
		--walking system
		if not d.walkSpeed then
			d.walkSpeed = d.walkMax / 2
		else
			if d.walkSpeed < d.walkMax then
				d.walkSpeed = d.walkSpeed + 0.05
			else
				d.walkSpeed = d.walkMax
			end
		
			if room:CheckLine(npc.Position,target.Position,0,1,false,false) then
				local targetvel = (target.Position - npc.Position):Resized(d.walkSpeed)
				npc.Velocity = mod:Lerp(npc.Velocity, targetvel,0.25)
			else
				path:FindGridPath(target.Position, 0.6, 900, true)
			end
			
			if d.idleWait <= 0 then
				d.idleWait = nil
				d.walkSpeed = nil
				d.state = "inferno"
			else
				d.idleWait = d.idleWait - 1
			end
		end
	end
	
	--inferno
	if d.state == "inferno" then
		mod:SpritePlay(sprite, "P2_Inferno")
		
		if sprite:IsFinished("P2_Inferno") then
			d.state = "idle2"
		elseif sprite:IsEventTriggered("Shoot") then
			npc:PlaySound(SoundEffect.SOUND_MONSTER_GRUNT_4, 1, 0, false, 1)
			npc:PlaySound(SoundEffect.SOUND_FLAMETHROWER_START, 1, 0, false, 1)
		elseif sprite:IsEventTriggered("Flame") then
			local dirRand = mod:RandomInt(180)
			local times = 360/w2.bal.fireAmount
			for i=0,360,times do
				local fire = Isaac.Spawn(9, ProjectileVariant.PROJECTILE_FIRE, 0,npc.Position, Vector(w2.bal.firePower,0):Rotated(i+dirRand), npc):ToProjectile()
			end
			npc:PlaySound(SoundEffect.SOUND_FLAMETHROWER_END, 1, 0, false, 1)
			game:ShakeScreen(5)
		end
		npc.Friction = w2.bal.attackFriction
	end

	--MINION SPAWN
	if d.minions then
	
		--post horn
		if d.minionsRapid then
			--overall time
			if not d.minionTime then
				d.minionTime = w2.bal.minionTime
				d.minionDelay = 30 --extra delay for the horn animation
			elseif d.minionTime > 0 then
				d.minionTime = d.minionTime - 1
			else
				d.minionTime = nil
				d.minionsRapid = false
			end
		end
		
		--individual time
		if not d.minionDelay then
			if d.minionsRapid then
				d.minionDelay = w2.bal.minionRapidDelay
				
				if d.roomSize == "big" then
					d.minionDelay = d.minionDelay * w2.bal.minionBigDelay
				end
			else
				d.minionDelay = mod:RandomInt(w2.bal.minionDelayMin,w2.bal.minionDelayMax)
				
				if d.roomSize == "big" then
					d.minionDelay = d.minionDelay * w2.bal.minionBigDelay
				end
			end
		elseif d.minionDelay > 0 then
			d.minionDelay = d.minionDelay - 1
		else
			d.minionDelay = nil
			
			d.minionPos = Isaac.GetRandomPosition()
			local distance = 0
			
			if not d.phase2 then
				while distance < w2.bal.armyDistMin do
					d.minionPos = Isaac.GetRandomPosition()
					distance = math.sqrt(((target.Position.X-d.minionPos.X)^2)+((target.Position.Y-d.minionPos.Y)^2))
				end
			else
				while distance < w2.bal.armyDistMin+30 or distance > w2.bal.armyDistMax+30 do
					d.minionPos = Isaac.GetRandomPosition()
					distance = math.sqrt(((target.Position.X-d.minionPos.X)^2)+((target.Position.Y-d.minionPos.Y)^2))
				end
			end
			
			local posGrid = room:GetGridIndex(d.minionPos)
			d.minionPos = room:GetGridPosition(posGrid)
			
			local minionCount = mod:CountRoom(w2.army.id,w2.army.variant) 
			local minionLimit = w2.bal.minionSmallTotalLimit
			if d.roomSize == "big" then
				minionLimit = w2.bal.minionBigTotalLimit
			end
			--spawn minion
			if minionCount < minionLimit then
				local minionDice = 0
				if minionCount >= w2.bal.minionBombLimit then
					minionDice = mod:RandomInt(4)
				else
					minionDice = mod:RandomInt(3)
				end
				
				if not d.phase2 then
					--regular army
					local army = Isaac.Spawn(w2.army.id, w2.army.variant, minionDice, d.minionPos, Vector(0,0), npc)
					army:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				else
					--bomb army
					local army = Isaac.Spawn(w2.army.id, w2.army.variantBomb, minionDice, d.minionPos, Vector(0,0), npc)
					army:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				end
			end
		end
	end
	
	--death
	if npc:IsDead() then
		for i, entity in ipairs(Isaac.FindByType(w2.army.id, w2.army.variant)) do
			entity:Kill()
		end
		
		if d.phase2 then
			npc:PlaySound(SoundEffect.SOUND_FIREDEATH_HISS, 1, 0, false, 1)
			Isaac.Explode(npc.Position, npc, 0)
			local fire = Isaac.Spawn(33, 10, 0,npc.Position, Vector(0,0), npc)
		end
		
		
		d.minionPos = Isaac.GetRandomPosition()
		local distance = 0
		while distance < w2.bal.deathArmyDist do
			d.minionPos = Isaac.GetRandomPosition()
			distance = math.sqrt(((target.Position.X-d.minionPos.X)^2)+((target.Position.Y-d.minionPos.Y)^2))
		end
		local posGrid = room:GetGridIndex(d.minionPos)
		d.minionPos = room:GetGridPosition(posGrid)
		minionDice = mod:RandomInt(4)
		
		local army = Isaac.Spawn(w2.army.id, w2.army.variant, minionDice, d.minionPos, Vector(0,0), npc)
		army:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		army:GetData().popoff = 12
		army:GetData().frameToPop = 4
	end
end

mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.War2AI, w2.id)

--ARMY--------------------

function mod:ArmyAI(npc)
	local sprite = npc:GetSprite()
	local path = npc.Pathfinder
	local d = npc:GetData()
	local target = npc:GetPlayerTarget()
	local targetpos = mod:RandomConfuse(npc, target.Position)
	local level = game:GetLevel()
	local room = game:GetRoom()

	--init
	if not d.init then
		npc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		d.staticPos = npc.Position
		
		if not d.popoff then
			d.popoff = 0
			d.frameToPop = 0
		end
		
		if npc.Variant == w2.army.variant then
			if npc.SubType == 0 then
				npc:ToNPC():Morph(w2.army.id, w2.army.variant, mod:RandomInt(4), -1)
			elseif npc.SubType == 10 then
				npc:ToNPC():Morph(w2.army.id, w2.army.variant, mod:RandomInt(2), -1)
			end
			d.state = "spawn"
		elseif npc.Variant == w2.army.variantBomb then
			if npc.SubType == 0 then
				npc:ToNPC():Morph(w2.army.id, w2.army.variantBomb, mod:RandomInt(3), -1)
			end
			d.state = "bombspawn"
		end
		
		if not d.roomArmy and room:GetAliveBossesCount() < 1 and d.popoff < 1 then
			d.roomArmy = true
			if d.state == "spawn" then 
				d.spawnDelay = mod:RandomInt(2,w2.army.roomDelay) 
			elseif d.state == "bombspawn" then 
				d.spawnDelay = mod:RandomInt(2,w2.army.roomBombDelay) 
			end
		end
		
		if target:ToPlayer() ~= nil then
			if target:ToPlayer().Damage >= npc.HitPoints then
				npc.HitPoints = npc.HitPoints + w2.army.hpBuffAmount
			end
		end
		d.colDmg = npc.CollisionDamage

		d.init = true
	elseif d.init then
		npc.StateFrame = npc.StateFrame + 1
	end
	
	--spawn
	if d.state == "spawn" then
		npc.Friction = 0
		npc.Position = d.staticPos
		
		if d.roomArmy and d.spawnDelay then	
			if d.spawnDelay < 2 then
				local distance = math.sqrt(((target.Position.X-npc.Position.X)^2)+((target.Position.Y-npc.Position.Y)^2))
				if distance > w2.army.roomSpawnDist then
					d.spawnDelay = nil
				end
			else
				d.spawnDelay = d.spawnDelay - 1
			end
		end
		
		if not d.spawnSeq and not d.spawnDelay then
			mod:SpritePlay(sprite, "DigOut")
			if sprite:IsEventTriggered("Appear") then
				npc:PlaySound(SoundEffect.SOUND_SUMMON_POOF, 1, 0, false, 1)
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
				npc.CollisionDamage = 0
			end
			if sprite:IsFinished("DigOut") then
				npc.CollisionDamage = d.colDmg
				d.spawnSeq = 1
			end
			
			--war death animation
			if sprite:GetFrame() == d.frameToPop and d.popoff > 1 and d.spawnOne == nil then
				d.spawnOne = true
				d.minionPos = Isaac.GetRandomPosition()
				local distance = 0
				while distance < w2.bal.deathArmyDist do
					d.minionPos = Isaac.GetRandomPosition()
					distance = math.sqrt(((target.Position.X-d.minionPos.X)^2)+((target.Position.Y-d.minionPos.Y)^2))
				end
				local posGrid = room:GetGridIndex(d.minionPos)
				d.minionPos = room:GetGridPosition(posGrid)
				minionDice = mod:RandomInt(4)
				
				local nextFrame = d.frameToPop
				if d.popoff < 7 then nextFrame = nextFrame + 2 end
				if d.popoff < 5 then nextFrame = nextFrame + 4 end
				if d.popoff < 3 then nextFrame = nextFrame + 10 end
				
				local army = Isaac.Spawn(w2.army.id, w2.army.variant, minionDice, d.minionPos, Vector(0,0), npc)
				army:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				army:GetData().popoff = d.popoff - 1
				army:GetData().frameToPop = nextFrame
			end
		elseif d.spawnSeq == 1 then
			mod:SpritePlay(sprite, "JumpOut")
			
			if sprite:IsEventTriggered("Jump") then
				if d.popoff > 0 then
					npc:Kill()
				else
					npc:PlaySound(SoundEffect.SOUND_MOTHER_ISAAC_RISE, 0.4, 0, false, 2)
					for i=1,3 do
						local dirt = Isaac.Spawn(1000, EffectVariant.ROCK_PARTICLE, 0, npc.Position, Vector(mod:RandomInt(-2,2),mod:RandomInt(-2,2)), npc)
					end
				end
			end
			
			
			if sprite:IsFinished("JumpOut") then
				d.spawnSeq = nil
				d.state = "idle"
			end
		end
	end 
	
	--bombspawn
	if d.state == "bombspawn" then
		npc.Friction = 0
		npc.Position = d.staticPos
		d.shootVec = (target.Position - npc.Position):Resized(w2.army.bombPower)
		
		if d.roomArmy and d.spawnDelay then	
			if d.spawnDelay < 2 then
				local distance = math.sqrt(((target.Position.X-npc.Position.X)^2)+((target.Position.Y-npc.Position.Y)^2))
				if distance > w2.army.roomSpawnDist then
					d.spawnDelay = nil
				end
			else
				d.spawnDelay = d.spawnDelay - 1
			end
		end
		
		if not d.spawnSeq and not d.spawnDelay then
			mod:SpritePlay(sprite, "ThrowBomb")
			if sprite:IsEventTriggered("Appear") then
				d.holdingBomb = true
				npc:PlaySound(SoundEffect.SOUND_MOTHER_ISAAC_RISE, 0.4, 0, false, 2)
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			end
			if sprite:IsEventTriggered("Throw") then
				d.holdingBomb = false
				npc:PlaySound(SoundEffect.SOUND_SHELLGAME, 1, 0, false, 1)
				local bombe = Isaac.Spawn(4, 0, 0, npc.Position+d.shootVec, d.shootVec, npc):ToBomb()
				bombe:SetExplosionCountdown(w2.army.bombCountdown)
				bombe.ExplosionDamage = w2.army.bombDamage
				bombe:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				bombe.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
			end
			if sprite:IsEventTriggered("Disappear") then
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			end
			if sprite:IsFinished("ThrowBomb") then
				npc:Remove()
			end
		end
	end 
	
	--idle
	if d.state == "idle" then
		npc.Friction = 1
		mod:OverlayPlay(sprite,"Head")
		
		if npc.Velocity:Length() > 0.1 then
			npc:AnimWalkFrame("WalkHori","WalkVert",0)
		else
			sprite:SetFrame("WalkVert", 0)
		end
		
		if mod:isScare(npc) then
			local targetvel = (targetpos - npc.Position):Resized(-w2.army.speed)
			npc.Velocity = mod:Lerp(npc.Velocity, targetvel,0.25)
		elseif room:CheckLine(npc.Position,targetpos,0,1,false,false) then
			local targetvel = (targetpos - npc.Position):Resized(w2.army.speed)
			npc.Velocity = mod:Lerp(npc.Velocity, targetvel,0.25)
		else
			path:FindGridPath(targetpos, 0.6, 900, true)
		end
	end 
	
	--death
	if npc:IsDead() then
		if d.holdingBomb then
			d.shootVec = (target.Position - npc.Position):Resized(4)
			local bombe = Isaac.Spawn(4, 0, 0, npc.Position, d.shootVec, npc):ToBomb()
			bombe:SetExplosionCountdown(w2.army.bombCountdown)
			bombe.ExplosionDamage = w2.army.bombDamage
		elseif npc.SubType == 4 then
			Isaac.Explode(npc.Position, npc, w2.army.walkingBombDamage)
		end
	end
end

mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.ArmyAI, w2.army.id)

--DEATH2--------------------

mod.Death2 = {
	name = "Tainted Death",
	nameAlt = "Tainted Death Alt",
	portrait = "gfx/bosses/death2/portrait_death2.png",
	portraitAlt = "gfx/bosses/death2/portrait_death2_gehenna.png",
	bossName = "gfx/bosses/death2/bossname_death2.png",
	weight = 1,
	weightAlt = 1,
	id = 660,
	variant = 101,
	horse = {
		name = "Tainted Death Horse",
		id = 660,
		variant = 102,
		speed = 14,
		slowSpeed = 0.4,
		accelRate = 0.15,
		steerRate = 0.012,
		scytheRate = 1,
		scytheRateSlow = 4,
		gasPause = 15,
		gasSpread = 7,
	},
	scythe = {
		name = "Purple Scythe",
		id = 660,
		variant = 103,
		gasTime = 10,
		accel = 0.34,
		fastAccel = 0.5,
	},
	cloud = {
		name = "Death Cloud",
		id = 660,
		variant = 104,
		accel = 8,
		velocity = 9.5,
		hitSphere = 32,
		slowValue = 0.90,
		slowHandicap = 0.03, --added slowness for higher speeds
		slowTime = 400,
	},
	ghost = {
		name = "Tainted Death Ghost",
		id = 660,
		variant = 105,
		moveWaitMin = 10,
		moveWaitMax = 30,
		speed = 1.15,
		ghostDistMin = 100,
		lifeTimerMin = 30,
		lifeTimerMax = 100,
		attackDelayMin = 1,
		attackDelayMax = 70,
		boneAttackSpeed = 11.8,
		boneCurve = 7,
		fireAttackSpeed = 9,
		fireCurve = 2,
		boneLimit = 1,
		bonusArmor = 200,
	},
	bal = {
		scytheIdleTail = 26,
		scytheIdleFast = 14,
		scytheIdleSlow = 32,
		slashIdleHead = 20,
		slashIdleTail = 10,
		moveWaitMin = 20,
		moveWaitMax = 30,
		attackFriction = 0.85,
		speed = 1.2,
		slashSpeed = 80,
		slashCurve = 30,
		slashFriction = 0.82,
		slashCircle = 60,
		slashTime = 7,
		boneShotDist = 18,
		boneShotSpeed = 10,
		boneShotAmount = 6,
		boneShotAmount2 = 10,
		phase2Health = 0.4,
		ghostRateMin = 10,
		ghostRateMax = 60,
		ghostMax = 3,
		ghostCount = 7,
		ghostExtra = 3,
		postGhostPause = 50,
	}
}
local d2 = mod.Death2

function mod:Death2AI(npc)
	local sprite = npc:GetSprite()
	local d = npc:GetData()
	local path = npc.Pathfinder
	local target = npc:GetPlayerTarget()
	local level = game:GetLevel()
	local room = game:GetRoom()
	
	--INIT
	if not d.init then
		d.init = true
		
		if (level:GetStage() == LevelStage.STAGE3_1 or level:GetStage() == LevelStage.STAGE3_2)
		and level:GetStageType() == StageType.STAGETYPE_REPENTANCE_B then
			d.altSkin = true
		end
		
		--[[for playerNum = 1, game:GetNumPlayers() do
			local player = game:GetPlayer(playerNum)
			if Isaac.GetPlayer(playerNum):GetPlayerType() == PlayerType.PLAYER_EVE_B then
				d.tpSafe = true
			end
		end]]

		--add safespots because this isnt a boss room
		if npc.SubType == 1 then
			d.tpSafe = true
		end
		
		local roomShape = room:GetRoomShape()
		d.roomSize = "odd"
		if roomShape == 1 then
			d.roomSize = "normal"
		end
		
		if not d.altSkin then
		--MAUSOLEUM COLORS
		d.poofColor = Color(0.9,0.6,1,1)
		
		d.floorColor = Color(1,1,1,1)
        d.floorColor:SetColorize(1.5,1,2,1)
		else
		--GEHENNA COLORS
		d.poofColor = Color(0.9,0.35,0.3,1)
		
		d.floorColor = Color(1,1,1,1)
        d.floorColor:SetColorize(1.5,0.3,0,1)
		end

		npc.SplatColor = Color(0.1, 0.05, 0.2, 1)
		
		d.P2text = ""
		d.idleState = "idle"

		if npc.Variant == d2.scythe.variant then
			--PURPLE SCYTHE
			npc.GridCollisionClass = GridCollisionClass.COLLISION_NONE
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
			if d.altSkin then
				sprite:Load("gfx/purplescythe_gehenna.anm2", true)
			end
			d.state = "scythe"
		elseif npc.Variant == d2.cloud.variant then
			--PURPLE SHADOW
			npc.GridCollisionClass = GridCollisionClass.COLLISION_NONE
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			d.state = "cloud"
		elseif npc.Variant == d2.horse.variant then
			--HORSE
			npc.GridCollisionClass = GridCollisionClass.COLLISION_NONE
			d.state = "horse"
		elseif npc.Variant == d2.ghost.variant then
			--GHOST
			npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			if d.altSkin then
				sprite:Load("gfx/boss_death2_ghost_gehenna.anm2", true)
			end
			d.state = "ghost"
		else
			--DEATH
			npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			d.movesBeforeSlash = mod:RandomInt(2,3)
			if d.altSkin then
				sprite:Load("gfx/boss_death2_gehenna.anm2", true)
			end
			d.state = "idle"
		end
	end
	
	--IDLE
	if d.state == "idle" then
		
		mod:SpritePlay(sprite, "Idle")
		
		if not d.idleWait then
			d.idleWait = d2.bal.scytheIdleTail
		end
		
		--decide state
		if not d.stateDecide then
		
			d.dice = 1
			if d.movesBeforeSlash == 0 then
				d.dice = 2
			elseif d.movesBeforeSlash < 0 then
				local q = mod:RandomInt(2)
				if q == 1 then
					d.dice = 3
				else
					d.dice = 4
				end
			end
			
			--beginning of idle
			if d.dice == 1 then
				d.stateDecide = "scythewall"
			elseif d.dice == 2 then
				d.idleWait = d2.bal.slashIdleHead
				d.stateDecide = "slash"
			elseif d.dice == 3 then
				d.stateDecide = "slowcloud"
			elseif d.dice == 4 then
				d.stateDecide = "bigbone"
			end
		end
		
		if d.idleWait <= 0 and d.stateDecide then
			--idle time finish
			d.idleWait = nil
			d.moveWait = nil
			
			--before next idle
			if d.dice == 1 then
				d.idleWait = d2.bal.scytheIdleTail
				d.movesBeforeSlash = d.movesBeforeSlash - 1
			elseif d.dice == 2 then
				d.idleWait = d2.bal.slashIdleTail
				d.movesBeforeSlash = -1
			elseif d.dice == 3 then
				d.idleWait = d2.bal.slashIdleTail*2
				d.movesBeforeSlash = mod:RandomInt(2,5)
			elseif d.dice >= 4 then
				d.idleWait = d2.bal.slashIdleTail
				d.movesBeforeSlash = mod:RandomInt(2,5)
			end
			
			d.state = d.stateDecide
			
			d.stateDecide = nil
			
			--phase 2 begin
			if npc.HitPoints <= npc.MaxHitPoints*d2.bal.phase2Health and not d.phase2 then
				d.state = "horselaunch"
			end
		else
			d.idleWait = d.idleWait - 1
		end
		
		--float move
		if not d.moveWait then
			d.moveWait = mod:RandomInt(d2.bal.moveWaitMin,d2.bal.moveWaitMax)
			
			local distance = math.sqrt(((room:GetCenterPos().X-npc.Position.X)^2)+((room:GetCenterPos().Y-npc.Position.Y)^2))
			
			if distance > 100 then
				d.targetvelocity = ((room:GetCenterPos() - npc.Position):Normalized()*2):Rotated(-10+mod:RandomInt(20))
			else
				d.targetvelocity = ((target.Position - npc.Position):Normalized()*2):Rotated(-50+mod:RandomInt(100))
			end
		end
		
		if d.moveWait <= 0 and d.moveWait ~= nil then
			d.moveWait = nil
		else
			d.moveWait = d.moveWait - 1
		end
		
		npc.Friction = 1
		npc.Velocity = ((d.targetvelocity * 0.3) + (npc.Velocity * 0.7)) * d2.bal.speed
		d.targetvelocity = d.targetvelocity * 0.99
		
		if npc.Velocity.X < -2 then
			sprite.FlipX = true
		elseif npc.Velocity.X > 2 then
			sprite.FlipX = false
		end
	end
	
	--SUMMON SCYTHEWALL
	if d.state == "scythewall" then
		mod:SpritePlay(sprite, "Summon")
		
		if not d.wallType then
			d.wallType = mod:RandomInt(9)
			
			if d.lastWallType then
				while d.lastWallType == d.wallType do
					d.wallType = mod:RandomInt(9)
				end
			end
			
			if d.movesBeforeSlash then
				if d.movesBeforeSlash <= 0 and d.wallType == 9 then
					d.wallType = mod:RandomInt(8)
				end
			end
		end
		
		if d.wallType and sprite:IsEventTriggered("Shoot") then
			if not d.spawnBegin then
				d.spawnBegin = true
				
				if d.wallType <= 2 then 
					d.scytheNum = 13
				elseif d.wallType <= 6 then
					d.scytheNum = 7
				elseif d.wallType <= 8 then
					d.scytheNum = 3
				else
					d.scytheNum = 7
				end
				
				if d.wallType == 5 or d.wallType == 6 then
					if target.Position.X <= room:GetCenterPos().X then
						d.wallType = 5
					else
						d.wallType = 6
					end
				end
				
				d.scytheGap = -1
				
				if d.wallType <= 6 then
					if d.wallType <= 4 or d.tpSafe then
						d.scytheGap = mod:RandomInt(d.scytheNum)
					end
				end
				
				npc:PlaySound(SoundEffect.SOUND_BLACK_POOF, 1, 0, false, 1)
				d.lastWallType = d.wallType
			end
		end
		
		if d.spawnBegin and d.scytheNum then
			if d.scytheNum >= 0 then
				local posx = 0
				local posy = 0
				local scythePos = Vector(0,0) 
				local getDir = "down"
				local scytheSpeed = d2.scythe.accel
				
				local xStart = room:GetTopLeftPos().X + 10 --70
				local yStart = room:GetTopLeftPos().Y + 10 --150
				local xEnd = room:GetBottomRightPos().X - 10 --570
				local yEnd = room:GetBottomRightPos().Y - 10 --560
				local sDist = math.floor(room:GetGridSize()/9)+23 --38
				local mid = room:GetCenterPos().X
				
				--TOP WALL
				if d.wallType == 1 then
					posx = xStart+(d.scytheNum*sDist)
					posy = 0
					getDir = "down"
				--BOTTOM WALL
				elseif d.wallType == 2 then
					posx = xStart+(d.scytheNum*sDist)
					posy = yEnd
					getDir = "up"
				--LEFT WALL
				elseif d.wallType == 3 then
					posx = xStart
					posy = yStart+(d.scytheNum*sDist)
					getDir = "right"
				--RIGHT WALL
				elseif d.wallType == 4 then
					posx = xEnd
					posy = yStart+(d.scytheNum*sDist)
					getDir = "left"
				--MIDDLE LEFT
				elseif d.wallType == 5 then
					posx = mid + 40
					posy = yStart+(d.scytheNum*sDist)
					getDir = "left"
					scytheSpeed = d2.scythe.fastAccel
				--MIDDLE RIGHT
				elseif d.wallType == 6 then
					posx = mid - 40
					posy = yStart+(d.scytheNum*sDist)
					getDir = "right"
					scytheSpeed = d2.scythe.fastAccel
				--4 SIDES CLOCKWISE
				elseif d.wallType == 7 then
					if d.scytheNum == 3 then
						posx = xStart
						posy = yStart+(3*sDist)
						getDir = "right"
					elseif d.scytheNum == 2 then
						posx = xStart+(5*sDist)
						posy = yEnd
						getDir = "up"
					elseif d.scytheNum == 1 then
						posx = xEnd
						posy = yStart+(4*sDist)
						getDir = "left"
					elseif d.scytheNum == 0 then
						posx = xStart+(8*sDist)
						posy = 0
						getDir = "down"
						d.idleWait = d2.bal.scytheIdleFast
					end
					scytheSpeed = d2.scythe.fastAccel
				--4 SIDES COUNTERCLOCKWISE
				elseif d.wallType == 8 then
					if d.scytheNum == 3 then
						posx = xStart
						posy = yStart+(5*sDist)
						getDir = "right"
					elseif d.scytheNum == 2 then
						posx = xStart+(10*sDist)
						posy = yEnd
						getDir = "up"
					elseif d.scytheNum == 1 then
						posx = xEnd
						posy = yStart+(2*sDist)
						getDir = "left"
					elseif d.scytheNum == 0 then
						posx = xStart+(3*sDist)
						posy = 0
						getDir = "down"
						d.idleWait = d2.bal.scytheIdleFast
					end
					scytheSpeed = d2.scythe.fastAccel
				--4 CORNERS
				elseif d.wallType == 9 then
					if not d.subScytheNum then d.subScytheNum = 0 end
					if d.scytheNum == 7 or d.scytheNum == 3 then
						posx = xStart
						posy = yStart+((7-d.subScytheNum)*sDist) - 20
						getDir = "right"
					elseif d.scytheNum == 6 or d.scytheNum == 2 then
						posx = xStart+((13-d.subScytheNum)*sDist) - 20
						posy = yEnd
						getDir = "up"
					elseif d.scytheNum == 5 or d.scytheNum == 1 then
						posx = xEnd
						posy = yStart+((0+d.subScytheNum)*sDist) + 20
						getDir = "left"
					elseif d.scytheNum == 4 or d.scytheNum == 0 then
						posx = xStart+((0+d.subScytheNum)*sDist) + 20
						posy = 0
						getDir = "down"
						d.subScytheNum = d.subScytheNum + 1
						d.idleWait = d2.bal.scytheIdleSlow
					end
					scytheSpeed = d2.scythe.fastAccel
				end
				
				if d.scytheNum ~= d.scytheGap and d.scytheNum ~= d.scytheGap-1 then 
					scythePos = Vector(posx,posy)
					local scythe = Isaac.Spawn(d2.scythe.id, d2.scythe.variant, 0, scythePos, Vector(0,0), npc)
					scythe:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
					scythe:GetData().scytheDir = getDir
					scythe:GetData().scythePause = d.scytheNum
					scythe:GetData().scytheSpeed = scytheSpeed
					scythe.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
					if scythe:GetData().scytheDir == "left" then scythe:GetSprite().FlipX = true end
				end
				
				d.scytheNum = d.scytheNum-1
			else
				d.scytheNum = nil
				d.subScytheNum = nil
			end
		end
		
		if sprite:IsFinished("Summon") and not d.scytheNum then
			d.spawnBegin = nil
			d.scytheGap = nil
			d.wallType = nil
			
			d.state = "idle"
		end
		npc.Friction = d2.bal.attackFriction
	end
	
	--HORSE SLASH
	if d.state == "slash" then
		if not d.substate then
			mod:SpritePlay(sprite,d.P2text.."SlashCharge")
			d.substate = 1
		--charge up
		elseif d.substate == 1 then
		
			npc.Friction = d2.bal.attackFriction
			
			if sprite:IsEventTriggered("Flash") then
				npc:PlaySound(SoundEffect.SOUND_BEEP, 1, 0, false, 1)
			elseif sprite:IsEventTriggered("Flash2") then
				npc:PlaySound(SoundEffect.SOUND_BEEP, 1, 0, false, 1.2)
			end
			
			if sprite:IsEventTriggered("Target") and not d.reshoot then
				d.shootVec = (target.Position - npc.Position):Normalized() * d2.bal.slashSpeed
			end
			
			if sprite:IsFinished(d.P2text.."SlashCharge") or d.reshoot == 1 then
				if d.reshoot then
					d.reshoot = 2
				end
				
				if not d.tpSafe and not d.reshoot then
					d.shootVec = d.shootVec + target.Velocity:Resized(d2.bal.slashCurve)
					d.shootVec = d.shootVec:Normalized() * d2.bal.slashSpeed
				end
			
				targetPos = d.shootVec + npc.Position
				if targetPos.Y >= npc.Position.Y-20 then mod:SpritePlay(sprite,d.P2text.."SlashDashA")
				else mod:SpritePlay(sprite,d.P2text.."SlashDashB") end
				
				if targetPos.X < npc.Position.X then
					sprite.FlipX = true
				else
					sprite.FlipX = false
				end
				
				npc.Friction = 1
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				
				d.substate = 2
			end
		--slash
		elseif d.substate == 2 then

			if sprite:IsEventTriggered("Shoot") then
				if not d.reshoot and d.phase2 then
					npc:PlaySound(SoundEffect.SOUND_TOOTH_AND_NAIL, 1, 0, false, 1.2)
				else
					npc:PlaySound(SoundEffect.SOUND_TOOTH_AND_NAIL, 1, 0, false, 1)
				end
				npc.Velocity = d.shootVec
				d.stateTimer = d2.bal.slashTime
			end
			
			if sprite:IsEventTriggered("Target") then
				d.shootVec = (target.Position - npc.Position):Resized(d2.bal.slashSpeed)
			end
			
			if d.phase2 and sprite:IsEventTriggered("Reshoot") and d.reshoot ~= 2 then
				sprite:SetFrame(0)
				d.reshoot = 1
				d.substate = 1
			end
			
			if sprite:IsEventTriggered("Unwind") then
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
			end
			
			if d.stateTimer then 

				if d.stateTimer == d2.bal.slashTime-1 then
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_BONE
					--if not d.phase2 then
						if (npc.Velocity.X > 0) then params.BulletFlags = ProjectileFlags.CURVE_LEFT
						else params.BulletFlags = ProjectileFlags.CURVE_RIGHT end
						--params.BulletFlags = ProjectileFlags.WIGGLE
						params.FallingAccelModifier = 0.1-(0.01*d2.bal.boneShotDist)
					--end
					local shotAmount
					if not d.reshoot then
						shotAmount = d2.bal.boneShotAmount
					else
						shotAmount = d2.bal.boneShotAmount2
					end
					npc:FireProjectiles(npc.Position, Vector(d2.bal.boneShotSpeed,shotAmount), 9, params)
				end

				if d.stateTimer > 0 then
					local distance = math.sqrt(((target.Position.X-npc.Position.X)^2)+((target.Position.Y-npc.Position.Y)^2))
					if distance < d2.bal.slashCircle then
						target:TakeDamage(1, 0, EntityRef(npc), 0)
						target.Velocity = npc.Velocity*0.5*-1
						d.stateTimer = 0
					end
				
					d.stateTimer = d.stateTimer - 1 
				end
			end
			
			npc.Friction = npc.Friction * d2.bal.slashFriction
			
			if sprite:IsFinished(d.P2text.."SlashDashA") or sprite:IsFinished(d.P2text.."SlashDashB") then
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
				d.substate = nil
				d.stateTimer = nil
				d.reshoot = nil
				npc.Friction = d2.bal.attackFriction
				d.state = d.idleState
			end
		end
	end
	
	--slow cloud
	if d.state == "slowcloud" then
		mod:SpritePlay(sprite,d.P2text.."QuickCharge")
		
		if sprite:IsFinished(d.P2text.."QuickCharge") then
			d.substate = nil
			d.state = d.idleState
		elseif sprite:IsEventTriggered("Shoot") then
		
			if target.Position.X < npc.Position.X then sprite.FlipX = true
			else sprite.FlipX = false end
		
			local cloud = Isaac.Spawn(d2.cloud.id, d2.cloud.variant, 0, npc.Position, Vector(0,0), npc)
			cloud:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			
			npc:PlaySound(SoundEffect.SOUND_BLACK_POOF, 1, 0, false, 1)
		end
		npc.Friction = d2.bal.attackFriction
	end
	
	--big bone
	if d.state == "bigbone" then
		mod:SpritePlay(sprite, "QuickSummon")
		
		if sprite:IsFinished("QuickSummon") then
			d.state = "idle"
		elseif sprite:IsEventTriggered("Shoot") then
		
			if targetPos.X < npc.Position.X then
				sprite.FlipX = true
			else
				sprite.FlipX = false
			end
		
			d.shootVec = (target.Position - npc.Position):Normalized()*3
			local bigbone = Isaac.Spawn(EntityType.ENTITY_BIG_BONY, 10, 0, npc.Position+d.shootVec, d.shootVec, npc)
			bigbone:GetData().purple = true

			game:SpawnParticles(npc.Position+d.shootVec,EffectVariant.SCYTHE_BREAK,1,1)
			npc:PlaySound(SoundEffect.SOUND_BONE_SNAP, 1, 0, false, 1)
		end
		npc.Friction = d2.bal.attackFriction
	end
	
	--phase2 transition
	if d.state == "horselaunch" then
		if not d.substate then
			if target.Position.X < npc.Position.X then
				sprite.FlipX = true
				d.launchDir = -1
			else
				sprite.FlipX = false
				d.launchDir = 1
			end
		
			d.substate = 1
			mod:SpritePlay(sprite, "HorseLaunch")
		end
		
		if sprite:IsFinished("HorseLaunch") then		
			local spawnVec = Vector(npc.Position.X+10*d.launchDir,npc.Position.Y) 
			d.horseNpc = Isaac.Spawn(d2.horse.id, d2.horse.variant, 0, spawnVec, Vector(0,0), npc)
			d.horseNpc:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			d.horseNpc:GetData().parentNpc = npc
			if d.tpSafe then d.horseNpc:GetData().tpSafe = true end
			d.horseNpc:GetSprite().FlipX = sprite.FlipX
			
			npc.Velocity = Vector(npc.Velocity.X - 6*d.launchDir,0)
			npc:PlaySound(SoundEffect.SOUND_SUMMONSOUND, 1, 0, false, 1)
			
			mod:SpritePlay(sprite, "HorseLaunch2")
		end
		
		if sprite:IsFinished("HorseLaunch2") then
			d.phase2 = true
			d.P2text = "P2_"
			d.idleState = "realghost"
			d.substate = nil
			d.launchDir = nil
			d.state = "invisible"
		end
		
		npc.Friction = 0.9
	end
	
	if d.phase2 then
		--invisible
		if d.state == "invisible" then
			if not d.stateTimer then
				d.stateTimer = 20
			elseif d.stateTimer <= 0 then
				d.stateTimer = nil
				d.state = "waiting"
			else
				d.stateTimer = d.stateTimer - 1
			end
		
			npc.Visible = false
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		end
		
		--waiting (for horse phase to end)
		if d.state == "waiting" then
			if d.horseNpc then
				if d.horseNpc:GetData().substate == 2 or not d.horseNpc:Exists() then
					d.horseWait = true
				end
			else
				d.horseWait = true
			end
			
			if d.horseWait then
				if not d.stateTimer then
					d.stateTimer = 40
				elseif d.stateTimer <= 0 then
					d.stateTimer = nil
					d.horseWait = nil
					d.state = "ghosting"
				else
					d.stateTimer = d.stateTimer - 1
				end
			end
		
			npc.Visible = false
			npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		end
		--ghosting
		if d.state == "ghosting" then
			
			if not d.ghostCount then
				d.ghostCount = d2.bal.ghostCount + d2.bal.ghostExtra
			end
			if mod:CountRoom(d2.ghost.id,d2.ghost.variant) <= d2.bal.ghostMax then
				if not d.stateTimer then
					d.ghostPos = Isaac.GetRandomPosition()
					local distance = 0
					
					while distance < d2.ghost.ghostDistMin do
						d.ghostPos = Isaac.GetRandomPosition()
						distance = math.sqrt(((target.Position.X-d.ghostPos.X)^2)+((target.Position.Y-d.ghostPos.Y)^2))
					end
					d.stateTimer = mod:RandomInt(d2.bal.ghostRateMin,d2.bal.ghostRateMax)
					
					if not d.ghostNum then
						d.ghostNum = 0 + mod:RandomInt(d2.bal.ghostExtra)
						d.stateTimer = 10
					else
						d.ghostNum = d.ghostNum + 1
					end
					
					if d.ghostNum < d.ghostCount then
						local ghost = Isaac.Spawn(d2.ghost.id, d2.ghost.variant, 0, d.ghostPos, Vector(0,0), npc)
						ghost:GetData().parentNpc = npc
						ghost:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
						
						if d.ghostNum%4 == 0 then
							ghost:GetData().attackPrimed = -1
						end
					else
						d.realOne = true
					end
					
				elseif d.stateTimer <= 0 then
					d.stateTimer = nil
				else
					d.stateTimer = d.stateTimer - 1
				end
			end
			
			if d.realOne then
				d.stateTimer = nil
				d.realOne = nil
				d.ghostNum = nil
				d.ghostCount = nil
				d.state = "realghost"
			else
				npc.Visible = false
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			end
		end
		--real ghost
		if d.state == "realghost" then
			if not d.ghoststate then 
				d.ghostPos = Isaac.GetRandomPosition()
				local distance = 0
				
				while distance < d2.ghost.ghostDistMin do
					d.ghostPos = Isaac.GetRandomPosition()
					distance = math.sqrt(((target.Position.X-d.ghostPos.X)^2)+((target.Position.Y-d.ghostPos.Y)^2))
				end
				npc.Position = d.ghostPos
				
				if target.Position.X < npc.Position.X then sprite.FlipX = true
				else sprite.FlipX = false end
			
				npc.Visible = true
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
				mod:SpritePlay(sprite,"P2_Appear")
				d.ghoststate = 1
				
			elseif d.ghoststate == 1 then
				if sprite:IsFinished("P2_Appear") then
					--bonus ghost!!!
					d.ghostPos = Isaac.GetRandomPosition()
					local distance = 0
					
					while distance < d2.ghost.ghostDistMin do
						d.ghostPos = Isaac.GetRandomPosition()
						distance = math.sqrt(((target.Position.X-d.ghostPos.X)^2)+((target.Position.Y-d.ghostPos.Y)^2))
					end
					local ghost = Isaac.Spawn(d2.ghost.id, d2.ghost.variant, 0, d.ghostPos, Vector(0,0), npc)
					ghost:GetData().parentNpc = npc
					ghost:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				
					d.moveWait = nil
					d.atkCount = 0
					d.ghoststate = 2
				end
			elseif d.ghoststate == 2 then
				mod:SpritePlay(sprite,"P2_Idle")
				
				--float move
				if not d.moveWait then
					d.moveWait = mod:RandomInt(d2.ghost.moveWaitMin,d2.ghost.moveWaitMax)
					d.targetvelocity = ((target.Position - npc.Position):Normalized()*2):Rotated(-100+mod:RandomInt(200))
				elseif d.moveWait <= 0 then
					if target.Position.X < npc.Position.X then sprite.FlipX = true
					else sprite.FlipX = false end
					d.moveWait = nil
				else
					d.moveWait = d.moveWait - 1
				end
				
				--attack timer
				if not d.attackTimer then
					d.attackTimer = 80
				elseif d.attackTimer <= 0 then
					if d.atkCount == 0 then --and mod:CountRoom(d2.ghost.id, d2.ghost.variant) <= 0 then
						local rand = mod:RandomInt(2)
						if rand == 1 then 
							d.state = "slash"
							d.atkCount = 1						
						else 
							d.state = "slowcloud"
							d.atkCount = 2
						end
						d.attackTimer = 30
					elseif d.atkCount == 1 then
						d.state = "slowcloud"
						d.atkCount = 3
						d.attackTimer = d2.bal.postGhostPause
					elseif d.atkCount == 2 then
						d.state = "slash"
						d.atkCount = 3
						d.attackTimer = d2.bal.postGhostPause
					elseif d.atkCount == 3 then
						d.atkCount = 4
					end
				else
					d.attackTimer = d.attackTimer - 1
				end
				
				if d.atkCount >= 4 then
					d.ghoststate = 3
				end
				
				npc.Friction = 1
				npc.Velocity = ((d.targetvelocity * 0.3) + (npc.Velocity * 0.7)) * d2.ghost.speed
				d.targetvelocity = d.targetvelocity * 0.99
			elseif d.ghoststate == 3 then
				mod:SpritePlay(sprite,"P2_Fadeout")
				if sprite:IsFinished("P2_Fadeout") then		
					d.atkCount = nil
					d.attackTimer = nil
					d.ghoststate = nil
					d.state = "invisible"
				end
				npc.Friction = npc.Friction * 0.9
			end
		end
	end
	
	--ENTITY HORSE---------
	
	if d.state == "horse" then
		--init
		if not d.substate then
			d.xStart = room:GetTopLeftPos().X - 220
			d.xEnd = room:GetBottomRightPos().X + 220
			d.mid = room:GetCenterPos().X
			
			if d.parentNpc ~= nil then
				d.hasParent = true
			else
				d.parentNpc = npc
				d.hasParent = false
			end
			
			if not d.hasParent or d.tpSafe then
				d.scytheRate = d2.horse.scytheRateSlow
				d.steerHalved = 0.5
			else
				d.scytheRate = d2.horse.scytheRate
				d.steerHalved = 1
			end
		
			d.substate = 1
		else
			if d.hasParent and not d.parentNpc:Exists() then
				npc:Kill()
			elseif not d.hasParent and room:IsClear() then
				npc:Kill()
			end
			--Going offscreen
			if d.substate == 1 then
				mod:SpritePlay(sprite, "Idle")
				if sprite.FlipX then
					d.dir = -1
				else
					d.dir = 1
				end
				
				if npc.Position.X > d.xEnd or npc.Position.X < d.xStart then
					d.substate = 2
				end
				npc.Velocity = Vector(d.dir,0) * d2.horse.speed
			--Waiting for action
			elseif d.substate == 2 then
				npc.Visible = false
				
				if not d.hasParent or d.parentNpc:GetData().state == "invisible" then
					if d.dir == 1 then
						npc.Position = Vector(d.xStart,d.mid)
						sprite.FlipX = false
					else
						npc.Position = Vector(d.xEnd,d.mid)
						sprite.FlipX = true
					end
					d.substate = 3
				end
			--Gas phase
			elseif d.substate == 3 then
				npc.Visible = true
				mod:SpritePlay(sprite, "Gas")
				if not d.horseAccel then 
					d.horseAccel = 0.1
					d.steerPower = 0
				else
					d.horseAccel = d.horseAccel + d2.horse.accelRate
				end
				
				--vertical steering
				if (d.dir == 1 and target.Position.X > npc.Position.X) 
				or (d.dir == -1 and target.Position.X < npc.Position.X) then
					d.steerPower = (target.Position.Y - npc.Position.Y) * d.steerHalved
					if d.steerPower > 50 then
						d.steerPower = 50
					elseif d.steerPower < -50 then
						d.steerPower = -50
					end
				else
					d.steerPower = d.steerPower * 0.9
				end
				
				npc.Velocity = Vector(d.dir,d2.horse.steerRate*d.steerPower) * (d2.horse.slowSpeed+d.horseAccel)
				
				--scythe
				if not d.horseTimer then
					d.horseTimer = 100
				elseif d.horseTimer > 0 then
					d.horseTimer = d.horseTimer - 1
				end
				
				if not d.scytheTimer then
					d.scytheTimer = d.scytheRate	
				elseif d.scytheTimer <= 0 then
					d.scytheTimer = d.scytheRate	
					
					local lightPause = (d.horseTimer*0.03)*20
					local scythe = Isaac.Spawn(d2.scythe.id, d2.scythe.variant, 0, Vector(npc.Position.X-(d.dir*20),npc.Position.Y), Vector(d.dir*-3,mod:RandomInt(-d2.horse.gasSpread,d2.horse.gasSpread)), npc)
					scythe:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
					scythe:GetData().gasPause = lightPause-10+d2.horse.gasPause
					scythe:GetData().scytheSpeed = d2.scythe.accel
					scythe.GridCollisionClass = GridCollisionClass.COLLISION_NONE
					scythe.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				else
					d.scytheTimer = d.scytheTimer - 1
				end
				
				if d.horseTimer < 50 and (npc.Position.X > d.xEnd+10 or npc.Position.X < d.xStart-10) then
					d.horseTimer = nil
					d.scytheTimer = nil
					d.steerPower = nil
					d.horseAccel = nil
					npc.Velocity = Vector(0,0)
					d.dir = d.dir*-1
					d.substate = 2
				end
			end
		end
	end
	
	--ENTITY GHOST----------
	
	if d.state == "ghost" then
		--init
		if d.deathPhase then
			d.substate = -1
			if target.Position.X < npc.Position.X then sprite.FlipX = true
			else sprite.FlipX = false end
			mod:SpritePlay(sprite,"G_Phase")
			if sprite:IsFinished("G_Phase") then
				npc:Remove()
			end
		end
		
		if not d.substate then
			mod:SpritePlay(sprite,"G_Appear")
			
			if target.Position.X < npc.Position.X then
				sprite.FlipX = true
			else
				sprite.FlipX = false
			end
			
			if sprite:IsFinished("G_Appear") then
				if d.parentNpc ~= nil then
					d.hasParent = true
				else
					d.parentNpc = npc
					d.hasParent = false
				end
				d.lastHealth = npc.HitPoints
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
				d.substate = 1
			end
		elseif d.substate > 0 then
			if d.hasParent and not d.parentNpc:Exists() then
				npc:Kill()
			end
			
			if not d.lifeTimer then
				d.lifeTimer = mod:RandomInt(d2.ghost.lifeTimerMin,d2.ghost.lifeTimerMax)
			elseif d.lifeTimer > 0 then
				d.lifeTimer = d.lifeTimer - 1
			end
			
			if not d.attackPrimed then
				d.attackPrimed = 1
			end
			
			if npc.HitPoints < d.lastHealth then
				if target:ToPlayer() and d.hasParent then
					--if d.parentNpc.HitPoints > target:ToPlayer().Damage*2 then
						local p = d.parentNpc.HitPoints / (d.parentNpc.MaxHitPoints*d2.bal.phase2Health+d2.ghost.bonusArmor)
						if p < 0.15 then p = 0.15 end
						local pp = p*target:ToPlayer().Damage
						d.parentNpc:TakeDamage(pp, 0, EntityRef(target), 0)
					--end
				end
			end
			d.lastHealth = npc.HitPoints

			--idle
			if d.substate == 1 then
				mod:SpritePlay(sprite, "G_Idle")
				
				--float move
				if not d.moveWait then
					d.moveWait = mod:RandomInt(d2.ghost.moveWaitMin,d2.ghost.moveWaitMax)
					d.targetvelocity = ((target.Position - npc.Position):Normalized()*2):Rotated(-100+mod:RandomInt(200))
				elseif d.moveWait <= 0 then
					if target.Position.X < npc.Position.X then
						sprite.FlipX = true
					else
						sprite.FlipX = false
					end
					d.moveWait = nil
				else
					d.moveWait = d.moveWait - 1
				end
				
				if d.lifeTimer <= 0 then
					d.substate = 2
				elseif d.lifeTimer == 1 and d.attackPrimed == 1 then
					d.attackPrimed = -1
					if mod:RandomInt(4) == 1 then
						d.substate = 5
					elseif mod:CountRoom(EntityType.ENTITY_BIG_BONY, 10) >= d2.ghost.boneLimit then
						d.substate = 4
					else
						d.substate = mod:RandomInt(3,4)
					end
				end
				
				npc.Friction = 1
				npc.Velocity = ((d.targetvelocity * 0.3) + (npc.Velocity * 0.7)) * d2.ghost.speed
				d.targetvelocity = d.targetvelocity * 0.99
			--fadeout
			elseif d.substate == 2 then
				if not d.rand then
					d.rand = mod:RandomInt(2)
				elseif d.rand == 1 then
					mod:SpritePlay(sprite, "G_Fadeout1")
					if sprite:IsFinished("G_Fadeout1") then
						npc:Remove()
					end
				else
					mod:SpritePlay(sprite, "G_Fadeout2")
					if sprite:IsFinished("G_Fadeout2") then
						npc:Remove()
					end
				end
				npc.Friction = npc.Friction * 0.9
			--big bone
			elseif d.substate == 3 then
				mod:SpritePlay(sprite, "G_Attack1")
				if sprite:IsFinished("G_Attack1") then
					d.lifeTimer = d.lifeTimer + mod:RandomInt(d2.ghost.attackDelayMin,d2.ghost.attackDelayMax)
					d.substate = 1
				elseif sprite:IsEventTriggered("Shoot") then
					if target.Position.X < npc.Position.X then sprite.FlipX = true
					else sprite.FlipX = false end
					local shootVec = (target.Position - npc.Position):Normalized()*3
					local bigbone = Isaac.Spawn(EntityType.ENTITY_BIG_BONY, 10, 0, npc.Position+shootVec, shootVec, npc)
					bigbone:GetData().purple = true

					game:SpawnParticles(npc.Position+shootVec,EffectVariant.SCYTHE_BREAK,1,1)
					npc:PlaySound(SoundEffect.SOUND_BONE_SNAP, 1, 0, false, 1)
				end
				npc.Friction = d2.bal.attackFriction
			
			--small bones
			elseif d.substate == 4 then
				mod:SpritePlay(sprite, "G_Attack2")
				if sprite:IsFinished("G_Attack2") then
					d.lifeTimer = d.lifeTimer + mod:RandomInt(d2.ghost.attackDelayMin,d2.ghost.attackDelayMax)
					d.substate = 1
				elseif sprite:IsEventTriggered("Target") then
					d.shootVec = (target.Position - npc.Position):Normalized()*d2.ghost.boneAttackSpeed
					d.shootVec = d.shootVec + target.Velocity:Resized(d2.ghost.boneCurve)
					d.shootVec = d.shootVec:Normalized()*d2.ghost.boneAttackSpeed
				elseif sprite:IsEventTriggered("Shoot") then
					if not d.shootVec then d.shootVec = (target.Position - npc.Position):Normalized()*d2.ghost.boneAttackSpeed end
					if npc.Position.X+d.shootVec.X < npc.Position.X then sprite.FlipX = true
					else sprite.FlipX = false end
					local params = ProjectileParams()
					params.Variant = ProjectileVariant.PROJECTILE_BONE
					npc:FireProjectiles(npc.Position, d.shootVec, 3, params)

					npc:PlaySound(SoundEffect.SOUND_GHOST_SHOOT, 1, 0, false, 1)
				end
				npc.Friction = d2.bal.attackFriction
			--purple fire
			elseif d.substate == 5 then				
				if sprite:IsFinished("G_Attack3") or sprite:IsFinished("G_Attack3B") then
					d.lifeTimer = d.lifeTimer + mod:RandomInt(d2.ghost.attackDelayMin,d2.ghost.attackDelayMax)
					d.currentPos = nil
					d.substate = 1
				elseif sprite:IsEventTriggered("Shoot") then
					d.lastPos = target.Position
					npc:PlaySound(SoundEffect.SOUND_GHOST_ROAR, 1, 0, false, 1)
					npc:PlaySound(SoundEffect.SOUND_FIRE_RUSH, 1, 0, false, 1)
					d.Firing = true
				elseif sprite:IsEventTriggered("Stop") then
					d.Firing = false
				elseif sprite:IsEventTriggered("Target") then
					d.lastPos = target.Position
				end
				
				if not sprite:IsPlaying("G_Attack3") and not sprite:IsPlaying("G_Attack3B") then
					d.lastPos = target.Position
					mod:SpritePlay(sprite, "G_Attack3")
				elseif d.lastPos.Y < npc.Position.Y-20 then 
					sprite:SetAnimation("G_Attack3B", false)
				else 
					sprite:SetAnimation("G_Attack3", false)
				end
				
				if d.Firing and npc.FrameCount % 2 == 0 then
					if d.lastPos.X < npc.Position.X then sprite.FlipX = true
					else sprite.FlipX = false end
					
					local shootVec
					local distance = math.sqrt(((target.Position.X-d.lastPos.X)^2)+((target.Position.Y-d.lastPos.Y)^2))
					if distance < 200 then 
						shootVec = (target.Position - npc.Position):Normalized()*d2.ghost.fireAttackSpeed
						shootVec = shootVec + target.Velocity:Resized(d2.ghost.fireCurve)
						shootVec = shootVec:Normalized()*d2.ghost.fireAttackSpeed
						d.lastPos = target.Position
					else 
						shootVec = (d.lastPos - npc.Position):Normalized()*d2.ghost.fireAttackSpeed 
					end
					
					local posOffset = 20
					local fire = Isaac.Spawn(9, ProjectileVariant.PROJECTILE_FIRE,1,npc.Position-Vector(0,posOffset), shootVec:Rotated(math.random(-2,2)), npc):ToProjectile()
					fire.Height = -60
					fire:SetColor(d.floorColor, 100, 1, false, false)
					fire.DepthOffset = posOffset
					fire.SpriteOffset = Vector(0,10)
					fire.FallingAccel = 0.12
				end
				npc.Friction = d2.bal.attackFriction
			end
		end
	end
	
	--ENTITY SCYTHE---------
	
	if d.state == "scythe" then
		--init
		if not d.substate then
			mod:SpritePlay(sprite, "Idle")
			npc.Friction = npc.Friction*0.9
			
			if not d.stateTimer then
				local gasExtra = 0
				if d.gasPause then
					gasExtra = d.gasPause
				end
				d.stateTimer = d2.scythe.gasTime+gasExtra
				
			elseif d.stateTimer > 0 then
				d.stateTimer = d.stateTimer - 1 
			else
				if d.scythePause == 0 then
					npc:PlaySound(SoundEffect.SOUND_SUMMON_POOF, 1, 0, false, 1)
				end
				mod:SpritePlay(sprite, "Transform")
				d.stateTimer = nil
				d.substate = 1
			end
		--transform
		elseif d.substate == 1 then
			if sprite:IsEventTriggered("Effect") then
				local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position, Vector(0,0), player):ToEffect()
				poof.Color = d.poofColor
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
				
				if not d.scytheDir then 
					if target.Position.Y < npc.Position.Y then
						d.scytheDir = "up"
					else
						d.scytheDir = "down"
					end
				end
				
				if not d.pause then d.pause = 0 end
				
				local accel = d.scytheSpeed
				
				if d.scytheDir == "left" then d.scytheVel = Vector(-1,0)*accel
				elseif d.scytheDir == "right" then d.scytheVel = Vector(1,0)*accel
				elseif d.scytheDir == "up" then d.scytheVel = Vector(0,-1)*accel
				elseif d.scytheDir == "down" then d.scytheVel = Vector(0,1)*accel end
			end
		
			if sprite:IsFinished("Transform") then
				mod:SpritePlay(sprite, "Throw")
				d.substate = 2
			end
		--movement
		elseif d.substate == 2 then
		
			if not d.scythePause then
				if not d.scytheVel then
					d.scytheVel = Vector(-1,0)*accel
				end
				npc.Velocity = npc.Velocity + d.scytheVel
			else
				if d.scythePause > 0 then
					d.scythePause = d.scythePause - 1
				else
					d.scythePause = nil
				end
			end
			
			sprite.PlaybackSpeed = 0.8
			npc.Friction = 1
			
			if not d.stateTimer then
				d.stateTimer = 80
			elseif d.stateTimer > 0 then
				d.stateTimer = d.stateTimer - 1 
			else
				local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position, Vector(0,0), npc):ToEffect()
				poof.Color = npc:GetData().poofColor
				npc:Remove()
			end
		end
	end
	
	--ENTITY CLOUD---------
	
	if d.state == "cloud" then
	
		if sprite:IsFinished("Appear") then
			mod:SpritePlay(sprite, "Idle")
		end
		
		if not d.touched then
			local distance = math.sqrt(((target.Position.X-npc.Position.X)^2)+((target.Position.Y-npc.Position.Y)^2))
			if distance < d2.cloud.hitSphere then
				local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, target.Position, Vector(0,0), npc):ToEffect()
				poof.Color = npc:GetData().poofColor
				
				local slowValue = d2.cloud.slowValue
				if target:ToPlayer() then
					local handicap = 0
					if target:ToPlayer().MoveSpeed > 1 then
						handicap = d2.cloud.slowHandicap*target:ToPlayer().MoveSpeed
					end
					slowValue = d2.cloud.slowValue - handicap
				end
				
				local slowColor = Color.Lerp(d.poofColor,Color(0,0,0),0.5)
				
				if not (target:GetEntityFlags() & EntityFlag.FLAG_SLOW == EntityFlag.FLAG_SLOW) then
					target:AddSlowing(EntityRef(npc), d2.cloud.slowTime, slowValue, slowColor)
				end
				npc:PlaySound(SoundEffect.SOUND_SUMMON_POOF, 1, 0, false, 1)
				d.touched = true
			end
		end
		
		if not d.stateTimer then
			d.stateTimer = 80
			d.shootVec = (target.Position - npc.Position):Resized(d2.cloud.velocity)
			npc.Velocity = d.shootVec
			d.lastPos = target.Position
			
		elseif d.stateTimer > 0 then
			if d.stateTimer > 50 and not d.touched then
				local distance = math.sqrt(((target.Position.X-d.lastPos.X)^2)+((target.Position.Y-d.lastPos.Y)^2))
				if distance < 200 then 
					d.lastPos = target.Position
					mod:RubberbandRun(npc, d, target.Position, d2.cloud.accel*(d.stateTimer/80), d2.cloud.velocity)
				else
					d.touched = true
				end
			end
			
			d.stateTimer = d.stateTimer - 1 
		else
			local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position, Vector(0,0), npc):ToEffect()
			poof.Color = d.poofColor
			npc:Remove()
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.Death2AI, d2.id)

--DEATHS death
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, npc)
	if not (npc.Type == d2.id
		and npc.Variant == d2.variant) then
		return
	end

	local room = game:GetRoom()
	
	--drop trinket
	if room:GetType() == RoomType.ROOM_BOSS then
		if npc:IsDead() and not game:IsPaused() then
			local dice = mod:RandomInt(2)
			if dice == 1 then
				local trinket = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, TrinketType.TRINKET_YOUR_SOUL, npc.Position, Vector(0,0), npc)
			end
		end
	end
end)

function mod:deathRender(npc)
	if not (npc.Type == d2.id
		and npc.Variant == d2.variant) then
		return
	end
	
	local sprite = npc:GetSprite()
	local d = npc:GetData()
	if sprite:IsPlaying("Death") then
		if sprite:GetFrame() == 1 and not d.deathState then
			if not d.phase2 then
				npc:BloodExplode()
			end
			npc:PlaySound(SoundEffect.SOUND_BONE_SNAP, 1, 0, false, 1)
			
			for i, entity in ipairs(Isaac.FindByType(d2.scythe.id, d2.scythe.variant)) do
				entity:Kill()
			end
			
			for i, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_BIG_BONY, 10)) do
				entity:Kill()
			end
			
			for i, entity in ipairs(Isaac.FindByType(d2.ghost.id, d2.ghost.variant)) do
				entity:Kill()
			end
			
			npc.Visible = true
			d.deathState = 1
		elseif sprite:GetFrame() >= 10 and sprite:GetFrame() <= 50 then
			if sprite:GetFrame()%4 == 0 and d.deathState ~= sprite:GetFrame() then
				local ghostPos = Isaac.GetRandomPosition()
				local ghost = Isaac.Spawn(d2.ghost.id, d2.ghost.variant, 0, ghostPos, Vector(0,0), npc)
				ghost:GetData().deathPhase = true
				ghost:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				d.deathState = sprite:GetFrame()
				
				if sprite:IsEventTriggered("Dying") then
					sfx:Play(SoundEffect.SOUND_FAT_GRUNT, 1, 2, false, 1)
				end
			end
		end
	end
end

function mod:PurpleBoneTrail(npc)
	local sprite = npc:GetSprite()
	local d = npc:GetData()
	local level = game:GetLevel()
	local room = game:GetRoom()
	
	if npc.Variant == 10 and d.purple then
		if not d.init then
			if (level:GetStage() == LevelStage.STAGE3_1 or level:GetStage() == LevelStage.STAGE3_2)
			and level:GetStageType() == StageType.STAGETYPE_REPENTANCE_B then
				d.altSkin = true
			end

			if not d.altSkin then
			--MAUSOLEUM COLORS
			d.floorColor = Color(1,1,1,1)
			d.floorColor:SetColorize(4,1,6,1)
			else
			--GEHENNA COLORS
			d.floorColor = Color(1,1,1,1)
			d.floorColor:SetColorize(4,0.5,0,1)
			end
			d.init = true
		end
		if npc.FrameCount % 3 == 0 then
			local trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HAEMO_TRAIL, 0, npc.Position+Vector(0,-15), Vector(0,0), npc):ToEffect()
			trail.Color = d.floorColor
			trail.Scale = 0.7
		end
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.PurpleBoneTrail, EntityType.ENTITY_BIG_BONY)

--PESTILENCE2--------------------

mod.Pestilence2 = {
	name = "Tainted Pestilence",
	--nameAlt = "Tainted Pestilence Alt",
	portrait = "gfx/bosses/pestilence2/portrait_pestilence2.png",
	--portraitAlt = "gfx/bosses/pestilence2/portrait_pestilence2_mortis.png",
	bossName = "gfx/bosses/pestilence2/bossname_pestilence2.png",
	weight = 1,
	weightAlt = 1,
	id = 640,
	variant = 101,
	bal = {
		idleWaitMin = 20,
		idleWaitMax = 50,
		moveWaitMin = 5,
		moveWaitMax = 40,
		attackFriction = 0.85,
		speed = 1.2,
	}
}
local p2 = mod.Pestilence2

function mod:Pestilence2AI(npc)
	local sprite = npc:GetSprite()
	local d = npc:GetData()
	local target = npc:GetPlayerTarget()
	local level = game:GetLevel()
	local room = game:GetRoom()
	
	if not d.init then
		d.init = true
		--print("spawned")
		
		--local cord = Isaac.Spawn(865, 10, 0, npc.Position, Vector(0,0), npc)
		--cord.Parent = npc
		--cord.Target = target
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.Pestilence2AI, p2.id)

------------------------COOL FUNCTIONS------------------------
--------------------------------------------------------------

--play sprite
function mod:SpritePlay(sprite, anim)
	if not sprite:IsPlaying(anim) then
		sprite:Play(anim)
	end
end

--play overlay
function mod:OverlayPlay(sprite, anim)
	if not sprite:IsOverlayPlaying(anim) then
		sprite:PlayOverlay(anim)
	end
end

--count room for specific entity
function mod:CountRoom(entityType,entityVariant)
	local number = 0
	for i, entity in ipairs(Isaac.FindByType(entityType, entityVariant)) do
			number = number + 1
	end
	return number
end

--rubberband run (fiend folio)
function mod:RubberbandRun(npc, npcdata, target, acceleration, velocitymax)
	local distance = math.sqrt(((target.X-npc.Position.X)^2)+((target.Y-npc.Position.Y)^2));
	local angle = math.atan((target.Y-npc.Position.Y)/(target.X-npc.Position.X));
	angle = math.deg(angle);
	if npc.Position.X >= target.X then
	angle = angle + 180;
	end
	if velocitymax ~= nil then
		local speed = math.sqrt(((npc.Velocity.X)^2)+((npc.Velocity.Y)^2));
		local velocityangle = 0;
		if npc.Velocity.X == 0 then
			velocityangle = 0;
		else
			velocityangle = math.atan((npc.Velocity.Y)/(npc.Velocity.X));
			velocityangle = math.deg(velocityangle);
		end
		if npc.Velocity.X <= 0 then
			velocityangle = velocityangle + 180;
		end
		npc.Velocity = Vector(speed,0):Rotated(velocityangle) + Vector(acceleration,0):Rotated(angle);
		if speed > velocitymax then
			npc.Velocity = Vector(velocitymax, 0):Rotated(velocityangle)+Vector(acceleration,0):Rotated(angle);
		else
			npc.Velocity = Vector(speed,0):Rotated(velocityangle) + Vector(acceleration,0):Rotated(angle);
		end
	else
		npc.Velocity = npc.Velocity + Vector(acceleration,0):Rotated(angle)
	end
end

--horse charge setup
function mod:HorseChargeSetup(direction, cWrap)
	local roomBegin, roomEnd, dir, flip
	room = game:GetRoom()
	if direction == -1 then
		roomBegin = (room:GetGridWidth() * 40) + cWrap
		roomEnd = -cWrap + 35
		dir = -1
		flip = true
	elseif direction == 1 then
		roomEnd = (room:GetGridWidth() * 40) + cWrap
		roomBegin = -cWrap + 35
		dir = 1
		flip = false
	end
	return roomBegin, roomEnd, dir, flip
end

--tears up
local function TearsUp(firedelay, val, mult)
    local currentTears = 30 / (firedelay + 1)
	
	local newTears = currentTears + val
	if mult then
		newTears = currentTears * val
	end
    return math.max((30 / newTears) - 1, -0.99)
end

--mirror check
local function IsMirror()
    for i=0,168 do
        local data=Game():GetLevel():GetRoomByIdx(i).Data
        if data and data.Name=='Knife Piece Room' then
            return true
        end
    end
    return false
end

--replaces math.random
function mod:RandomInt(iMin, iMax)
	if not iMax then
		iMax = iMin
		iMin = 1
	end

    if iMin > iMax then 
        print("Error: Min higher than Max in mod:RandomInt()")
    else
        return iMin + (rng:RandomInt(iMax - iMin + 1))
    end
end

--npc flag functions
function mod:isFriend(npc)
	return npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
end
function mod:isCharm(npc)
	return npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY | EntityFlag.FLAG_CHARM)
end
function mod:isScare(npc)
	return npc:HasEntityFlags(EntityFlag.FLAG_FEAR | EntityFlag.FLAG_SHRINK)
end
function mod:isConfuse(npc)
	return npc:HasEntityFlags(EntityFlag.FLAG_CONFUSION)
end
function mod:isScareOrConfuse(npc)
	return npc:HasEntityFlags(EntityFlag.FLAG_CONFUSION | EntityFlag.FLAG_FEAR | EntityFlag.FLAG_SHRINK)
end

function mod:RandomConfuse(npc, pos)
	if mod:isConfuse(npc) then
		room = game:GetRoom()
		return room:GetRandomPosition(1)
	else
		return pos
	end
end

--lerp
function mod:Lerp(first,second,percent)
	return (first + (second - first)*percent)
end

--------------------------MOD STUFF--------------------------
-------------------------------------------------------------

--npc collisions
mod:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, function(_, npc, npc2)
	--war
	if npc2.Type == w2.id and npc2.Variant == w2.variant and npc2:GetData().state == "charge" then
		if npc.Type == w2.army.id and npc.Variant == w2.army.variant then
			npc:Kill()
		end
		npc:TakeDamage(w2.bal.chargeDamage, 0, EntityRef(npc2), 0)
	end
	
	--purple scythe
	if npc.Type == d2.scythe.id and npc.Variant == d2.scythe.variant then
		if npc2.Type == EntityType.ENTITY_PLAYER then
			local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position, Vector(0,0), player):ToEffect()
			poof.Color = npc:GetData().poofColor
			npc:Remove()
		end
	end
end
)

--npc damage
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, npc,amount,flag,source)
	--war armor
	if npc.Type == w2.id and npc.Variant == w2.variant and npc:GetData().phase2 then
		if flag <= DamageFlag.DAMAGE_EXPLOSION then
			if npc:GetData().armorDamage ~= nil then
				npc:GetData().armorDamage = nil
				return true
			else
				amount = amount * w2.bal.walkArmor
				npc:GetData().armorDamage = amount
				npc:TakeDamage(npc:GetData().armorDamage, 0, source, 0)
				npc:ToNPC():PlaySound(SoundEffect.SOUND_FIREDEATH_HISS, 0.18, 0, false, 2)
				local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, npc.Position, Vector(0,0), player):ToEffect()
				poof.SpriteScale = Vector(0.3,0.3)
				poof.Color = Color(0.8,0.6,0.4,1)
				return false
			end
		end
	end
	
	--death under phase 2
	if npc.Type == d2.id and npc.Variant == d2.variant then
		if not npc:GetData().phase2 and npc.HitPoints <= npc.MaxHitPoints * d2.bal.phase2Health then
			if npc:GetData().armorDamage ~= nil then
				npc:GetData().armorDamage = nil
				return true
			else
				amount = amount * 0.1
				npc:GetData().armorDamage = amount
				npc:TakeDamage(npc:GetData().armorDamage, 0, source, 0)
				return false
			end
		end
	end
	
	--death horse
	if npc.Type == d2.horse.id and npc.Variant == d2.horse.variant then
		return false
	end
	
	--death scythe
	if npc.Type == d2.scythe.id and npc.Variant == d2.scythe.variant then
		return false
	end
	
	--telefrag death
	if source.Entity and npc.Type == EntityType.ENTITY_PLAYER then
		if source.Type == d2.id and source.Variant == d2.variant then
			if npc:GetSprite():GetAnimation() == "TeleportDown" then
				return false
			end
		elseif source.Type == d2.scythe.id and source.Variant == d2.scythe.variant then
			if npc:GetSprite():GetAnimation() == "TeleportDown" then
				return false
			end
		elseif source.Type == d2.ghost.id and source.Variant == d2.ghost.variant then
			if npc:GetSprite():GetAnimation() == "TeleportDown" then
				source.Entity:Kill()
				return false
			end
		end
	end
end
)

--tear collisions
mod:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, function(_, tear, npc)
	if npc.Type == w2.army.id and (npc.Variant == w2.army.variant or npc.Variant == w2.army.variantBomb) and npc.SubType == 3 then
		local dice = mod:RandomInt(w2.army.reflectChance)
		if dice == 1 then
			tear.Velocity = (tear.Velocity * -0.8):Rotated(-20 + mod:RandomInt(40))
			return false
		end
	end
end
)

function mod:renderBosses(npc)
	mod:deathRender(npc)
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, mod.renderBosses, d2.id)

--TUMOR CUBE --------------------
mod.Tumorcube = {
	id = Isaac.GetItemIdByName("Wad of Tumors"),
	variant1 = Isaac.GetEntityVariantByName("Wad of Tumors L1"),
	variant2 = Isaac.GetEntityVariantByName("Wad of Tumors L2"),
	variant3 = Isaac.GetEntityVariantByName("Wad of Tumors L3"),
	variant4 = Isaac.GetEntityVariantByName("Wad of Tumors L4"),
	nugget = Isaac.GetEntityVariantByName("Tumor Nugget"),
	tearsUp = true,
	helperid = 270,
	helper = 56,
	helperKeys = 39,
	bal = {
		orbitSpeed = 0.035,
		orbitDistance = Vector(30, 30),
		slowDuration = 40,
		slowAmount = 0.5,
		creepMin = 50,
		creepBonus = 20,
		shootDelay = 22,
		shootDamage = 3.5,
		shootSize = 0.75,
		slowColor = Color(0.15,0.15,0.15,1),
		creepMin2 = 1,
		creepBonus2 = 5,
		tumorSmallChance = 3,
		tumorBigChance = 2,
		jumpCooldown = 200,
		jumpDamage = 65,
		jumpRange = 250,
		stompRange = 90,
		tumorMax1 = 5,
		tumorMax2 = 7,
		tumorMax3 = 15,
	},
	tears = {
		flat = 0.10, --flat bonus, applied per wad
		multiplier = 0.12, --multiplier, applied after flat bonus
		multiplierPlus = 0.07 --how much the multiplier increases per wad
	}
}

local tc = mod.Tumorcube

--index------
CollectibleType.COLLECTIBLE_WAD_OF_TUMORS = tc.id
FamiliarVariant.WAD_OF_TUMORS_L1 = Isaac.GetEntityVariantByName("Wad of Tumors L1")
FamiliarVariant.WAD_OF_TUMORS_L2 = Isaac.GetEntityVariantByName("Wad of Tumors L2")
FamiliarVariant.WAD_OF_TUMORS_L3 = Isaac.GetEntityVariantByName("Wad of Tumors L3")
FamiliarVariant.WAD_OF_TUMORS_L4 = Isaac.GetEntityVariantByName("Wad of Tumors L4")
FamiliarVariant.TUMOR_NUGGET = Isaac.GetEntityVariantByName("Tumor Nugget")

------------------------------------

--cache update
function mod:CacheUpdate(player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
		local boxOfFriends = player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS)
		local tumorNum = player:GetCollectibleNum(tc.id)
		if tumorNum > 0 then
			tumorNum = player:GetCollectibleNum(tc.id) + boxOfFriends
		end
		local tumorSub = tumorNum
		local tumorFull = 0
		while tumorSub > 4 do
			tumorSub = tumorSub - 4
			tumorFull = tumorFull + 1
		end
		local tumorS1 = 0
		local tumorS2 = 0
		local tumorS3 = 0
		local tumorS4 = 0
		
		local helperNum = player:GetCollectibleNum(tc.helperid) --just in case you have the actual item
		local helper = 0
		if tumorSub == 1 then
			tumorS1 = 1
		elseif tumorSub == 2 then
			tumorS2 = 1
		elseif tumorSub == 3 then
			tumorS3 = 1
			helper = 1
		elseif tumorSub == 4 then
			tumorS4 = 1
			helper = 1
		end

		player:CheckFamiliar(tc.variant1, tumorS1, player:GetCollectibleRNG(tc.id))
		player:CheckFamiliar(tc.variant2, tumorS2, player:GetCollectibleRNG(tc.id))
		player:CheckFamiliar(tc.variant3, tumorS3, player:GetCollectibleRNG(tc.id))
		player:CheckFamiliar(tc.variant4, tumorS4 + tumorFull, player:GetCollectibleRNG(tc.id))
		
		player:CheckFamiliar(tc.helper, helper + tumorFull + helperNum, player:GetCollectibleRNG(tc.helper))
	end
	if flag == CacheFlag.CACHE_FIREDELAY and tc.tearsUp then
		if player:HasCollectible(tc.id) then
			local tumorNum = player:GetCollectibleNum(tc.id, true)
			
			local tearsFlat = tumorNum * tc.tears.flat
			local tearsMult = 1 + tc.tears.multiplier
			local tearsAmp = (tumorNum-1)*tc.tears.multiplierPlus
			
			local tearCalculate = TearsUp(player.MaxFireDelay, tearsFlat, false)
			tearCalculate = TearsUp(tearCalculate, tearsMult+tearsAmp, true)
			player.MaxFireDelay = tearCalculate
		end
	end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.CacheUpdate)

local dirtostring = {
	[Direction.DOWN] = "Down",
	[Direction.UP] = "Up",
	[Direction.LEFT] = "Side",
	[Direction.RIGHT] = "Side",
}
local dirtovect = {
	[Direction.DOWN] = Vector(0, 1),
	[Direction.UP] = Vector(0, -1),
	[Direction.LEFT] = Vector(-1, 0),
	[Direction.RIGHT] = Vector(1, 0),
}

--tumor spurs
function mod:TumorSpur(tumor,limit)
	local spurCount = 0
	
	for i, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, tc.nugget)) do
		spurCount = spurCount + 1
	end
	
	if spurCount < limit then
		local spur = Isaac.Spawn(EntityType.ENTITY_FAMILIAR, tc.nugget, 0, tumor.Position, Vector(mod:RandomInt(-4,4),mod:RandomInt(-4,4)), tumor):ToFamiliar()
		spur:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
	end
end

--tumor update
--t1
function mod:TumorUpdate1(tumor)
    local player = tumor.Player
    local sprite = tumor:GetSprite()
    local room = game:GetRoom()
	local d = tumor:GetData()
	
	if not d.creeptime then
		d.creeptime = tc.bal.creepMin + mod:RandomInt(tc.bal.creepBonus)
	else
		if d.creeptime <= 0 then
			d.creeptime = tc.bal.creepMin + mod:RandomInt(tc.bal.creepBonus)
			
			local activeEnemies = false
			for i, entity in ipairs(Isaac.FindInRadius(Vector(640, 580), 875, EntityPartition.ENEMY)) do
				if entity:IsActiveEnemy(0) then
					activeEnemies = true
				end
			end
			
			if activeEnemies then
				local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_BLACK, 0, tumor.Position, Vector(0,0), player):ToEffect()
				--local blackSplat = game:SpawnParticles(tumor.Position,EffectVariant.BLOOD_SPLAT,1,1,Color(0,0,0,0.8))
			end
		else
			d.creeptime = d.creeptime - 1
		end
	end
	
	if sprite:IsEventTriggered("Drip") then
		local effect = Isaac.Spawn(1000, 7, 0, tumor.Position, Vector(0,0), tumor):ToEffect()
		effect.Color = Color(0,0,0,0.6)
		effect.Scale = 0.4  
	end
	
    tumor.OrbitDistance = tc.bal.orbitDistance
    tumor.OrbitSpeed = tc.bal.orbitSpeed
    tumor.Velocity = tumor:GetOrbitPosition(player.Position + player.Velocity) - tumor.Position
	tumor.SplatColor = Color(0,0,0,1)
end

--t2
function mod:TumorUpdate2(tumor)
    local player = tumor.Player
    local sprite = tumor:GetSprite()
    local room = game:GetRoom()
	local d = tumor:GetData()
	
	local dir = player:GetHeadDirection()
	local animdir = dirtostring[dir]
	d.animpre = d.animpre or "Float"
	
	local shootMultiplier
	
	if player:HasTrinket(TrinketType.TRINKET_FORGOTTEN_LULLABY) then
		shootMultiplier = 0.5
	else
		shootMultiplier = 1
	end
	
	if not d.cooldown then
		d.cooldown = tumor.FrameCount + (tc.bal.shootDelay * shootMultiplier)
	else
		if not (player:GetShootingInput().X == 0 and player:GetShootingInput().Y == 0) and d.cooldown - tumor.FrameCount <= 0 then
			d.animpre = "FloatShoot"
			d.cooldown = tumor.FrameCount + (tc.bal.shootDelay * shootMultiplier)
			local tear = tumor:FireProjectile(dirtovect[dir]):ToTear()
			tear.CollisionDamage = tc.bal.shootDamage
			tear.Scale = tc.bal.shootSize
			tear:ChangeVariant(TearVariant.BLOOD)
			tear:AddTearFlags(TearFlags.TEAR_SLOW)
			tear:AddTearFlags(TearFlags.TEAR_GISH)
			tear:SetColor(tc.bal.slowColor, -1, 1, false, false)
		end
		
		if dir == Direction.LEFT then
			sprite.FlipX = true
		else
			sprite.FlipX = false
		end
		
		if (player:GetShootingInput().X == 0 and player:GetShootingInput().Y == 0) then
			animdir = dirtostring[Direction.DOWN]
			sprite.FlipX = false
		end

		if d.animpre == "FloatShoot" and d.cooldown - tumor.FrameCount <= (tc.bal.shootDelay - 8) then
			d.animpre = "Float"
		end	
		
		sprite:SetFrame(d.animpre..animdir, tumor.FrameCount % 15)
	end

    tumor.OrbitDistance = tc.bal.orbitDistance
    tumor.OrbitSpeed = tc.bal.orbitSpeed
    tumor.Velocity = tumor:GetOrbitPosition(player.Position + player.Velocity) - tumor.Position
	tumor.SplatColor = Color(0,0,0,1)
end

--t3
function mod:TumorUpdate3(tumor)
	local player = tumor.Player
    local sprite = tumor:GetSprite()
    local room = game:GetRoom()
	local d = tumor:GetData()
	
	if not d.helper then
		for i, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, tc.helper)) do
			if entity:ToFamiliar().Keys ~= tc.helperKeys then
				d.helper = entity
				d.helperInit = true
				break
			end
		end
		
		if d.helperInit then
			tumor.Position = d.helper.Position
			d.helper:ToFamiliar():AddKeys(tc.helperKeys)
		end
	else	
		local hsprite = d.helper:GetSprite()
		local tardir = d.helper.Position - tumor.Position
		
		tumor.Velocity = d.helper.Velocity 
		tumor.SplatColor = Color(0,0,0,1)
		d.helper.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		d.helper.Visible = false
		
		if tumor.Velocity.X >= 0 then
			sprite.FlipX = false
		else
			sprite.FlipX = true
		end

		if tumor.Velocity.X < 3 and tumor.Velocity.X > -3
		and tumor.Velocity.Y < 3 and tumor.Velocity.Y > -3 then
			mod:SpritePlay(sprite, "Idle")
		else
			--currently walking
			mod:SpritePlay(sprite, "Walk")
			
			--creep trail
			if not d.creeptime then
				d.creeptime = tc.bal.creepMin2 + mod:RandomInt(tc.bal.creepBonus2)
			else
				if d.creeptime <= 0 then
					d.creeptime = tc.bal.creepMin2 + mod:RandomInt(tc.bal.creepBonus2)
					local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_BLACK, 0, tumor.Position, Vector(0,0), player):ToEffect()
					--local blackSplat = game:SpawnParticles(tumor.Position,EffectVariant.BLOOD_SPLAT,1,1,Color(0,0,0,0.3))
				else
					d.creeptime = d.creeptime - 1
				end
			end
		end
		
		if (tardir.X > 25 or tardir.X < -25) 
		or (tardir.Y > 25 or tardir.Y < -25) then
			tumor.Position = d.helper.Position
		end
		
		if not d.helper:Exists() then
			d.helper = nil
		end
	end
end

--t4
function mod:TumorUpdate4(tumor)
	local player = tumor.Player
    local sprite = tumor:GetSprite()
    local room = game:GetRoom()
	local d = tumor:GetData()
	
	if not d.helper then
		for i, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, tc.helper)) do
			if entity:ToFamiliar().Keys ~= tc.helperKeys then
				d.helper = entity
				d.helperInit = true
				break
			end
		end
		
		if d.helperInit then
			tumor.Position = d.helper.Position
			d.helper:ToFamiliar():AddKeys(tc.helperKeys)
		end
	else	
		local hsprite = d.helper:GetSprite()
		local tardir = d.helper.Position - tumor.Position
		
		tumor.Velocity = d.helper.Velocity 
		tumor.SplatColor = Color(0,0,0,1)
		d.helper.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		d.helper.Visible = false
		
		if tumor.Velocity.X >= 0 then
			sprite.FlipX = false
		else
			sprite.FlipX = true
		end
		
		local activeEnemies = false
		for i, entity in ipairs(Isaac.FindInRadius(tumor.Position, 875, EntityPartition.ENEMY)) do
			if entity:IsActiveEnemy(false) and entity:IsVulnerableEnemy() then
				activeEnemies = true
				d.smile = true
			end
		end

		if not d.state then
			d.state = "normal"
		end

		--standard
		if d.state == "normal" then
			tumor.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
		
			if tumor.Velocity.X < 3 and tumor.Velocity.X > -3
			and tumor.Velocity.Y < 3 and tumor.Velocity.Y > -3 then
				mod:SpritePlay(sprite, "Idle")
			else
				--currently walking				
				if not activeEnemies and d.smile then
					mod:SpritePlay(sprite, "WalkSmile")
				else
					mod:SpritePlay(sprite, "Walk")
				end
				
				--creep trail
				if not d.creeptime then
					d.creeptime = tc.bal.creepMin2 + mod:RandomInt(tc.bal.creepBonus2)
				else
					if d.creeptime <= 0 then
						d.creeptime = tc.bal.creepMin2 + mod:RandomInt(tc.bal.creepBonus2)
						local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_BLACK, 0, tumor.Position, Vector(0,0), player):ToEffect()
						--local blackSplat = game:SpawnParticles(tumor.Position,EffectVariant.BLOOD_SPLAT,1,1,Color(0,0,0,0.3))
					else
						d.creeptime = d.creeptime - 1
					end
				end
			end
			
			--smile cooldown
			if not d.smileCooldown then
				d.smileCooldown = 50
			else
				if d.smileCooldown <= 0 then
					d.smileCooldown = nil
					d.smile = false
				else
					d.smileCooldown = d.smileCooldown - 1
				end
			end
			
			--jump cooldown
			if not d.jumpCooldown then
				d.jumpCooldown = tc.bal.jumpCooldown
			else
				if d.jumpCooldown <= 0 then
					mod:SpritePlay(sprite, "Jump")
					d.state = "jump"
				elseif activeEnemies then
					d.jumpCooldown = d.jumpCooldown - 1
				end
			end
		--jump
		elseif d.state == "jump" then
			tumor.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		
			if sprite:IsFinished("Jump") then
				for i, entity in ipairs(Isaac.FindInRadius(player.Position, tc.bal.jumpRange)) do
					if entity:IsVulnerableEnemy() then 
						d.helper.Position = entity.Position
						tumor.Position = entity.Position
						break
					elseif entity.Type == EntityType.ENTITY_PROJECTILE then 
						d.helper.Position = entity.Position
						tumor.Position = entity.Position
						break
					end
				end
				mod:SpritePlay(sprite, "Land")
				d.state = "land"
			elseif sprite:IsEventTriggered("Jump") then
				sfx:Play(SoundEffect.SOUND_MEAT_JUMPS, 1, 2, false, 1)
			end
		--land
		elseif d.state == "land" then
			d.helper.Friction = 0
			
			if sprite:IsFinished("Land") then
				d.jumpCooldown = nil
				d.helper.Friction = 1
				d.state = "normal"
				
			elseif sprite:IsEventTriggered("Land") then
			
				local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_BLACK, 0, tumor.Position, Vector(0,0), player):ToEffect()
				creep.SpriteScale = Vector(2.5,2.5)
				
				game:SpawnParticles(tumor.Position,EffectVariant.BLOOD_EXPLOSION,1,1,Color(0,0,0,1))
				game:SpawnParticles(tumor.Position,EffectVariant.IMPACT,1,0.2)
				sfx:Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 1, 2, false, 1.5)
				
				for i, entity in ipairs(Isaac.FindInRadius(tumor.Position, tc.bal.stompRange)) do
					if entity.Type == EntityType.ENTITY_PROJECTILE then 
						mod:TumorSpur(tumor,15)
						entity:Kill()
					elseif entity:IsVulnerableEnemy() then 
						mod:TumorSpur(tumor,15)
						entity:AddSlowing(EntityRef(tumors), tc.bal.slowDuration, tc.bal.slowAmount, tc.bal.slowColor)
						entity:TakeDamage(tc.bal.jumpDamage, 0, EntityRef(tumor), 1)
					end
				end
			end
		
		end
		
		if (tardir.X > 25 or tardir.X < -25) 
		or (tardir.Y > 25 or tardir.Y < -25) then
			tumor.Position = d.helper.Position
		end
		
		if not d.helper:Exists() then
			d.helper = nil
		end
	end
end

--nugget
function mod:NuggetUpdate(tumor)
	local player = tumor.Player
    local sprite = tumor:GetSprite()
	local d = tumor:GetData()
	
	sprite.Scale = Vector(0.8,0.8)
	tumor.SplatColor = Color(0,0,0,1)
	
	if tumor.Velocity.X > 0.1 and tumor.Velocity.Y > 0.1  then
		tumor.Velocity = Vector(0,0)
	else
		tumor.Velocity = tumor.Velocity * 0.9
	end

	if d.hp <= 0 then
		tumor:Kill()
		game:SpawnParticles(tumor.Position, EffectVariant.BLOOD_EXPLOSION, 1, 1, Color(0,0,0,1))
	end
	
	if d.currentRoom ~= game:GetLevel():GetCurrentRoomIndex() then
		tumor:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.TumorUpdate1, tc.variant1)
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.TumorUpdate2, tc.variant2)
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.TumorUpdate3, tc.variant3)
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.TumorUpdate4, tc.variant4)
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.NuggetUpdate, tc.nugget)

--tumor initialize
--t1
function mod:TumorInit1(tumor)
    tumor:GetSprite():Play("Float")
    tumor:AddToFollowers()
    tumor:AddToOrbit(95)
	tumor.OrbitDistance = tc.bal.orbitDistance
	tumor.OrbitSpeed = tc.bal.orbitSpeed
end

--t2
function mod:TumorInit2(tumor)
    tumor:GetSprite():Play("FloatDown")
    tumor:AddToFollowers()
    tumor:AddToOrbit(95)
	tumor.OrbitDistance = tc.bal.orbitDistance
	tumor.OrbitSpeed = tc.bal.orbitSpeed
end

--t3
function mod:TumorInit3(tumor)
	tumor:GetSprite():Play("Idle")
end

--t4
function mod:TumorInit4(tumor)
	tumor:GetSprite():Play("Idle")
	tumor:GetData().state = "normal"
end

--nugget
function mod:NuggetInit(tumor)
	sprite = tumor:GetSprite()
	local spriteRand = mod:RandomInt(8)
	tumor:GetData().hp = 2
	tumor:GetData().currentRoom = game:GetLevel():GetCurrentRoomIndex()
	
	if spriteRand == 1 then
		mod:SpritePlay(sprite,"Idle0")
	elseif spriteRand == 2 then
		mod:SpritePlay(sprite,"Idle1")
	elseif spriteRand == 3 then
		mod:SpritePlay(sprite,"Idle2")
	elseif spriteRand == 4 then
		mod:SpritePlay(sprite,"Idle3")
	elseif spriteRand == 5 then
		mod:SpritePlay(sprite,"Idle4")
	elseif spriteRand == 6 then
		mod:SpritePlay(sprite,"Idle5")
	elseif spriteRand == 7 then
		mod:SpritePlay(sprite,"Idle6")
	elseif spriteRand == 8 then
		mod:SpritePlay(sprite,"Idle7")
	end
end
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, mod.TumorInit1, tc.variant1)
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, mod.TumorInit2, tc.variant2)
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, mod.TumorInit3, tc.variant3)
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, mod.TumorInit4, tc.variant4)
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, mod.NuggetInit, tc.nugget)

--tumor collision
--t1
function mod:TumorCollision1(tumor, entity, _)
    if entity.Type == EntityType.ENTITY_PROJECTILE then entity:Kill()
    elseif entity:IsVulnerableEnemy() then 
		entity:AddSlowing(EntityRef(tumors), tc.bal.slowDuration, tc.bal.slowAmount, tc.bal.slowColor) 
	end
end

--t2
function mod:TumorCollision2(tumor, entity, _)
    if entity.Type == EntityType.ENTITY_PROJECTILE then 
		if not entity:GetData().tumorSpawned then
			entity:GetData().tumorSpawned = true
			mod:TumorSpur(tumor,tc.bal.tumorMax1)
		end
		entity:Kill()
    elseif entity:IsVulnerableEnemy() and not EntityRef(entity).IsFriendly and not EntityRef(entity).IsCharmed then 
		entity:AddSlowing(EntityRef(tumors), tc.bal.slowDuration, tc.bal.slowAmount, tc.bal.slowColor) 
		local tumorDice = mod:RandomInt(tc.bal.tumorBigChance)
		if entity.HitPoints <= tumor.CollisionDamage and tumorDice == 1 and not entity:GetData().tumorSpawned then
			entity:GetData().tumorSpawned = true
			mod:TumorSpur(tumor,tc.bal.tumorMax1)
		end
	end
end

--t3
function mod:TumorCollision3(tumor, entity, _)
	if entity.Type == EntityType.ENTITY_PROJECTILE then 
		local tumorDice = mod:RandomInt(tc.bal.tumorBigChance)
		if tumorDice == 1 and not entity:GetData().tumorSpawned then
			entity:GetData().tumorSpawned = true
			mod:TumorSpur(tumor,tc.bal.tumorMax2)
		end
    elseif entity:IsVulnerableEnemy() and not EntityRef(entity).IsFriendly and not EntityRef(entity).IsCharmed then 
		entity:AddSlowing(EntityRef(tumors), tc.bal.slowDuration, tc.bal.slowAmount, tc.bal.slowColor) 
		local tumorDice = mod:RandomInt(tc.bal.tumorSmallChance)
		if entity.HitPoints <= tumor.CollisionDamage and tumorDice == 1 and not entity:GetData().tumorSpawned then
			entity:GetData().tumorSpawned = true
			mod:TumorSpur(tumor,tc.bal.tumorMax2)
		end
	end
end

--t4
function mod:TumorCollision4(tumor, entity, _)
	if entity.Type == EntityType.ENTITY_PROJECTILE then 
		local tumorDice = mod:RandomInt(tc.bal.tumorBigChance)
		if tumorDice == 1 and not entity:GetData().tumorSpawned then
			entity:GetData().tumorSpawned = true
			mod:TumorSpur(tumor,tc.bal.tumorMax3)
		end
	elseif entity:IsVulnerableEnemy() and not EntityRef(entity).IsFriendly and not EntityRef(entity).IsCharmed then 
		entity:AddSlowing(EntityRef(tumors), tc.bal.slowDuration, tc.bal.slowAmount, tc.bal.slowColor)
		local tumorDice = mod:RandomInt(tc.bal.tumorSmallChance)
		if entity.HitPoints <= tumor.CollisionDamage and tumorDice == 1 and not entity:GetData().tumorSpawned then
			entity:GetData().tumorSpawned = true
			mod:TumorSpur(tumor,tc.bal.tumorMax3)
		end
	end
end

--nugget
function mod:NuggetCollision(tumor, entity, _)
    if entity.Type == EntityType.ENTITY_PROJECTILE and (tumor.Velocity.X < 0.1 and tumor.Velocity.Y < 0.1) then 
		entity:Kill()
		tumor:GetData().hp = tumor:GetData().hp - 1
	elseif entity:IsVulnerableEnemy() and (tumor.Velocity.X < 0.1 and tumor.Velocity.Y < 0.1) then
		tumor:GetData().hp = tumor:GetData().hp - 1
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, mod.TumorCollision1,  tc.variant1)
mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, mod.TumorCollision2,  tc.variant2)
mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, mod.TumorCollision3,  tc.variant3)
mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, mod.TumorCollision4,  tc.variant4)
mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, mod.NuggetCollision,  tc.nugget)

----------------------------------------------

local doHorseDrop
local meatCheck
local bandageCheck

local revChance = false
local bossEntered = false
local bossGen
local tumorConstruct

--boss encounters
local bossSeen = {
		f2 = false,
		w2 = false,
		d2 = false,
		p2 = false
	}

--meat check
local function CheckThatMeat()
	for playerNum = 1, game:GetNumPlayers() do
		local player = game:GetPlayer(playerNum)
		
		if player:GetCollectibleNum(CollectibleType.COLLECTIBLE_CUBE_OF_MEAT) > 0 then
			meatCheck = true
			break
		end
		
		if player:GetCollectibleNum(CollectibleType.COLLECTIBLE_BALL_OF_BANDAGES) > 0 then
			bandageCheck = true
			break
		end
	end
end

--horsemen check
local function FloorVerify()
	local level = game:GetLevel()
	local stage = level:GetStage()
	local stageType = level:GetStageType()
	local bossID = nil
		
	--normal
	if (stageType == StageType.STAGETYPE_REPENTANCE and stageType ~= StageType.STAGETYPE_REPENTANCE_B) then
		if (stage == LevelStage.STAGE1_1 or stage == LevelStage.STAGE1_2) and not bossSeen.f2 then
			bossID = f2.name
		elseif (stage == LevelStage.STAGE2_1 or stage == LevelStage.STAGE2_2) and not bossSeen.w2 then
			bossID = w2.name
		elseif (stage == LevelStage.STAGE3_1) and not bossSeen.d2 then
			bossID = d2.name
		--[[elseif (stage == LevelStage.STAGE4_1) and not bossSeen.p2 then
			bossID = p2.name]]
		end
	--alt
	elseif (stageType ~= StageType.STAGETYPE_REPENTANCE and stageType == StageType.STAGETYPE_REPENTANCE_B) then
		if (stage == LevelStage.STAGE1_1 or stage == LevelStage.STAGE1_2) and not bossSeen.f2 then
			bossID = f2.nameAlt
		elseif (stage == LevelStage.STAGE2_1 or stage == LevelStage.STAGE2_2) and not bossSeen.w2 then
			bossID = w2.nameAlt
		elseif (stage == LevelStage.STAGE3_1) and not bossSeen.d2 then
			bossID = d2.nameAlt
		--[[elseif (stage == LevelStage.STAGE4_1) and not bossSeen.p2 then
			bossID = p2.name]]
		end
	end
	
	return bossID
end

--book of revelations
mod:AddCallback(ModCallbacks.MC_USE_ITEM,function(_,collectible)
	local level = game:GetLevel()
	local stage = level:GetStage()
	local stageType = level:GetStageType()

	if (stageType == StageType.STAGETYPE_REPENTANCE or stageType == StageType.STAGETYPE_REPENTANCE_B) then
		if not revChance and not bossEntered and StageAPI then
			local baseFloorInfo = StageAPI.GetBaseFloorInfo()
			local backwards = game:GetStateFlag(GameStateFlag.STATE_BACKWARDS_PATH_INIT) or game:GetStateFlag(GameStateFlag.STATE_BACKWARDS_PATH)
			local bossID = FloorVerify()
			local successCheck = false

			--print(bossID)

				if bossID then
				
					local laby
					if level:GetCurses() & LevelCurse.CURSE_OF_LABYRINTH ~= 0 then
						laby = true
					end
					
					--print("detected possible boss")
					
					local roomsList = level:GetRooms()
					for i = 0, roomsList.Size - 1 do
						local roomDesc = roomsList:Get(i)
						if roomDesc and not laby then
							local dimension = StageAPI.GetDimension(roomDesc)
							local newRoom
							
							if roomDesc.Data.Type == RoomType.ROOM_BOSS and roomDesc.Data.Shape ~= RoomShape.ROOMSHAPE_2x1 and (roomDesc.Data.Subtype ~= 82 and roomDesc.Data.Subtype ~= 83)
							and dimension == 0 and not backwards and i == level:GetLastBossRoomListIndex() then
								local bossData = StageAPI.GetBossData(bossID)
								if bossData and not bossData.BaseGameBoss and bossData.Rooms then
									newRoom = StageAPI.GenerateBossRoom({
										BossID = bossID,
										NoPlayBossAnim = true
									}, {
										RoomDescriptor = roomDesc
									})
									
									successCheck = true
									print("Horseman generation: Success!")
									
									--[[if roomDesc.Data.Subtype == 82 or roomDesc.Data.Subtype == 83 then
										print("jk this ons gonna be monstro")
										local overwritableRoomDesc = level:GetRoomByIdx(roomDesc.SafeGridIndex, dimension)
										local replaceData = StageAPI.GetGotoDataForTypeShape(RoomType.ROOM_BOSS, roomDesc.Data.Shape)
										overwritableRoomDesc.Data = replaceData
									end]]
								end
								
								if newRoom then						
									local listIndex = roomDesc.ListIndex
									StageAPI.SetLevelRoom(newRoom, listIndex, dimension)
									if roomDesc.Data.Type == RoomType.ROOM_BOSS and baseFloorInfo.HasMirrorLevel and dimension == 0 then
										StageAPI.Log("Mirroring!")
										local mirroredRoom = newRoom:Copy(roomDesc)
										local mirroredDesc = level:GetRoomByIdx(roomDesc.SafeGridIndex, 1)
										StageAPI.SetLevelRoom(mirroredRoom, mirroredDesc.ListIndex, 1)
									end
								end
							end
						end
					end
				end
				
			if not successCheck then
				print("Horseman generation: Failed (Invalid Room)")
			end	
			revChance = true
		end
	end
end,CollectibleType.COLLECTIBLE_BOOK_OF_REVELATIONS)

--post mod update
mod:AddCallback(ModCallbacks.MC_POST_UPDATE,function(_)
	local room = game:GetRoom()

	if room:GetType() == RoomType.ROOM_BOSS then
		if doHorseDrop then
			for i, entity in ipairs(Isaac.FindByType(5, 100)) do
				if entity.Position.X <= room:GetCenterPos().X and entity.Position.Y > room:GetCenterPos().Y then
					doHorseDrop = false
					local thisDrop = tc.id 
					
					--local dice = mod:RandomInt(2)
					
					--[[if dice == 1 then
						thisDrop = CollectibleType.COLLECTIBLE_CUBE_OF_MEAT
					else
						thisDrop = CollectibleType.COLLECTIBLE_BALL_OF_BANDAGES
					end
					
					if meatCheck then
						thisDrop = CollectibleType.COLLECTIBLE_CUBE_OF_MEAT
					elseif bandageCheck then
						thisDrop = CollectibleType.COLLECTIBLE_BALL_OF_BANDAGES
					end]]
					
					entity:ToPickup():Morph(5,100,thisDrop,-1)
				end
			end
		end
	end
end
)

-------------------------SYSTEMS--------------------------
----------------------------------------------------------

if StageAPI and firstLoaded then	
	mod.StageAPIBosses = {
		f2 = StageAPI.AddBossData(f2.name, {
			Name = f2.name,
			Portrait = f2.portrait,
			Offset = Vector(0,-15),
			Bossname = f2.bossName,
			Weight = f2.weight,
			Rooms = StageAPI.RoomsList("Famine Rooms", require("resources.luarooms.boss_famine2")),
		}),
		f2alt = StageAPI.AddBossData(f2.nameAlt, {
			Name = f2.name,
			Portrait = f2.portraitAlt,
			Offset = Vector(0,-15),
			Bossname = f2.bossName,
			Weight = f2.weightAlt,
			Rooms = StageAPI.RoomsList("BossRooms", require("resources.luarooms.boss_famine2_alt")),
		}),
		w2 = StageAPI.AddBossData(w2.name, {
			Name = w2.name,
			Portrait = w2.portrait,
			Offset = Vector(0,-15),
			Bossname = w2.bossName,
			Weight = w2.weight,
			Rooms = StageAPI.RoomsList("BossRooms", require("resources.luarooms.boss_war2")),
		}),
		w2alt = StageAPI.AddBossData(w2.nameAlt, {
			Name = w2.name,
			Portrait = w2.portraitAlt,
			Offset = Vector(0,-15),
			Bossname = w2.bossName,
			Weight = w2.weightAlt,
			Rooms = StageAPI.RoomsList("BossRooms", require("resources.luarooms.boss_war2_alt")),
		}),
		d2 = StageAPI.AddBossData(d2.name, {
			Name = d2.name,
			Portrait = d2.portrait,
			Offset = Vector(0,-15),
			Bossname = d2.bossName,
			Weight = d2.weight,
			Rooms = StageAPI.RoomsList("BossRooms", require("resources.luarooms.boss_death2")),
		}),
		d2alt = StageAPI.AddBossData(d2.nameAlt, {
			Name = d2.name,
			Portrait = d2.portraitAlt,
			Offset = Vector(0,-15),
			Bossname = d2.bossName,
			Weight = d2.weightAlt,
			Rooms = StageAPI.RoomsList("BossRooms", require("resources.luarooms.boss_death2_alt")),
		}),
		--[[p2 = StageAPI.AddBossData(p2.name, {
			Name = p2.name,
			Portrait = p2.portrait,
			Offset = Vector(0,-15),
			Bossname = p2.bossName,
			Weight = p2.weightAlt,
			Rooms = StageAPI.RoomsList("BossRooms", require("resources.luarooms.boss_pestilence")),
		})]]
	}
	
	StageAPI.AddBossToBaseFloorPool({BossID = f2.name},LevelStage.STAGE1_1,StageType.STAGETYPE_REPENTANCE)
	StageAPI.AddBossToBaseFloorPool({BossID = f2.nameAlt},LevelStage.STAGE1_1,StageType.STAGETYPE_REPENTANCE_B)
	StageAPI.AddBossToBaseFloorPool({BossID = w2.name},LevelStage.STAGE2_1,StageType.STAGETYPE_REPENTANCE)
	StageAPI.AddBossToBaseFloorPool({BossID = w2.nameAlt},LevelStage.STAGE2_1,StageType.STAGETYPE_REPENTANCE_B)
	StageAPI.AddBossToBaseFloorPool({BossID = d2.name},LevelStage.STAGE3_1,StageType.STAGETYPE_REPENTANCE)
	StageAPI.AddBossToBaseFloorPool({BossID = d2.nameAlt},LevelStage.STAGE3_1,StageType.STAGETYPE_REPENTANCE_B)
	--StageAPI.AddBossToBaseFloorPool({BossID = p2.name},LevelStage.STAGE4_1,StageType.STAGETYPE_REPENTANCE)
end

--New Game
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isContinue)
	--local floorInfo = StageAPI.GetBaseFloorInfo(LevelStage.STAGE2_1,StageType.STAGETYPE_REPENTANCE, false)
	--for k, v in pairs(floorInfo.Bosses.Pool) do 
		--print (v.BossID)
	--end

	if not isContinue then
		if firstLoaded then
			if StageAPI then
				print(loadText)
			else
				print(loadTextFailed)
			end
			firstLoaded = false
		end
		
		--make all bosses unseen
		for k, v in pairs(bossSeen) do
			bossSeen[k] = false
		end
		
		--reset weights
		StageAPI.GetBossData(f2.name).Weight = f2.weight
		StageAPI.GetBossData(f2.nameAlt).Weight = f2.weightAlt
		StageAPI.GetBossData(w2.name).Weight = w2.weight
		StageAPI.GetBossData(w2.nameAlt).Weight = w2.weightAlt
		StageAPI.GetBossData(d2.name).Weight = d2.weight
		StageAPI.GetBossData(d2.nameAlt).Weight = d2.weightAlt
		--StageAPI.GetBossData(p2.name).Weight = p2.weight
	end
end
)

--New Level
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL ,function(_)
	doHorseDrop = false
	meatCheck = false
	bandageCheck = false
	bossGen = nil
	revChance = false
	bossEntered = false
end
)

--New Room
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function(_)
	if StageAPI and StageAPI.Loaded and not StageAPI.InTestMode then
	
		local room = Game():GetRoom()
        if room:GetType() == RoomType.ROOM_BOSS then
			if room:IsFirstVisit() and not StageAPI.InNewStage() then
				bossEntered = true
			end
			
			local bossGet
			for i, entity in ipairs(Isaac.FindInRadius(room:GetCenterPos(), 1000, EntityPartition.ENEMY)) do
				--FAMINE
				if entity.Type == f2.id and entity.Variant == f2.variant then
					bossGet = f2.name
					bossSeen.f2 = true
					
					--50% chance tumor drop in the mirror
					if (IsMirror()) then
						local tumorChance = mod:RandomInt(2)
						--print(tumorChance)
						if (tumorChance == 1) then
							doHorseDrop = true
						end
					else
						doHorseDrop = true
					end
					
					StageAPI.GetBossData(f2.name).Weight = 0
					StageAPI.GetBossData(f2.nameAlt).Weight = 0
					break
				--WAR
				elseif entity.Type == w2.id and entity.Variant == w2.variant then
					bossGet = w2.name
					bossSeen.w2 = true
					doHorseDrop = true
					
					StageAPI.GetBossData(w2.name).Weight = 0
					StageAPI.GetBossData(w2.nameAlt).Weight = 0
					break
				--DEATH
				elseif entity.Type == d2.id and entity.Variant == d2.variant then
					bossGet = d2.name
					bossSeen.d2 = true
					doHorseDrop = true
					
					StageAPI.GetBossData(d2.name).Weight = 0
					StageAPI.GetBossData(d2.nameAlt).Weight = 0
					break
				--PESTILENCE
				elseif entity.Type == p2.id and entity.Variant == p2.variant then
					bossGet = p2.name
					bossSeen.p2 = true
					doHorseDrop = true
					
					StageAPI.GetBossData(p2.name).Weight = 0
					StageAPI.GetBossData(p2.nameAlt).Weight = 0
					break
				end
			end
		end
	end
end
)

--EID--------
if EID then
	EID:addCollectible(CollectibleType.COLLECTIBLE_WAD_OF_TUMORS, "↑ +0.4 Tears up#LVL1: Sticky Orbital#LVL2: Shooting Orbital#LVL3: Ash LVL 1#LVL4: Ash LVL 2")
end

--Enhanced Boss Bars
if HPBars then
	f2id = tostring(f2.id) .. "." .. tostring(f2.variant)
	w2id = tostring(w2.id) .. "." .. tostring(w2.variant)
	d2id = tostring(d2.id) .. "." .. tostring(d2.variant)

    HPBars.BossDefinitions[f2id] = {
        sprite = "gfx/bosses/famine2/small_famine_head.png",
		conditionalSprites = {
			{"isStageType","gfx/bosses/famine2/small_famine_head_dross.png", {StageType.STAGETYPE_REPENTANCE_B}}
		},
    }
	HPBars.BossDefinitions[w2id] = {
        sprite = "gfx/bosses/war2/small_war_head.png",
		conditionalSprites = {
			{"animationNameStartsWith","gfx/bosses/war2/small_war_head_fire.png", {"P2"}},
			{"isStageType","gfx/bosses/war2/small_war_head_ashpit.png", {StageType.STAGETYPE_REPENTANCE_B}},
		},
    }
	HPBars.BossDefinitions[d2id] = {
        sprite = "gfx/bosses/death2/small_death_head.png",
		conditionalSprites = {
			{"isStageType","gfx/bosses/death2/small_death_head_gehenna.png", {StageType.STAGETYPE_REPENTANCE_B}},
		},
    }
end

--[[
mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    if not StageAPI or not StageAPI.Loaded then
        Isaac.RenderText("StageAPI missing, no alt horsemen :(", 20, 250, 255, 255, 255, 1)
    end
end)]]