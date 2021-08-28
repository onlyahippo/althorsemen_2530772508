Althorsemen = RegisterMod("Alt Horsemen",1)
local mod = Althorsemen
local game = Game()
local sfx = SFXManager()

local loadText = "Alt Horsemen v2.0 (War Update)"
local loadTextFailed = "Alt Horsemen v2.0 (w/ no stageapi so it wont work)"

------------------------BOSSES------------------------
------------------------------------------------------

--FAMINE2--------------------
Althorsemen.Famine2 = {
	name = "Tainted Famine",
	portrait = "gfx/bosses/famine2/portrait_famine2.png",
	altPortrait = "gfx/bosses/famine2/portrait_famine2_dross.png",
	bossName = "gfx/bosses/famine2/bossname_famine2.png",
	id = 630,
	variant = 101,
	chance = 0.2,
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
local f2 = Althorsemen.Famine2

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
			d.dross = true
		end
		
		if d.dross == true then
			d.tearType = ProjectileVariant.PROJECTILE_PUKE
			d.waterColor = Color(0.6,0.5,0.3)
		else
			d.tearType = ProjectileVariant.PROJECTILE_TEAR
			d.waterColor = Color.Default
		end

		d.movesBeforeCharge = 1 + math.random(1,3)	
		d.state = "idle"
	end
	
	--IDLE
	if d.state == "idle" then
		
		mod:SpritePlay(sprite, "Idle")
		
		if not d.idleWait then
			d.idleWait = math.random(f2.bal.idleWaitMin,f2.bal.idleWaitMax)
		end
		
		if d.idleWait <= 0 and d.idleWait ~= nil then
			--idle time finish
			d.idleWait = nil
			d.moveWait = nil
			d.movesBeforeCharge = d.movesBeforeCharge - 1
			
			d.dice = math.random(1,2)
			if d.movesBeforeCharge <= 0 then
				d.dice = 3
			end
			
			if d.dice == 1 then
				local enemyNum = mod:CountRoom(EntityPartition.ENEMY,EntityType.ENTITY_SMALL_LEECH,0)
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
			d.moveWait = math.random(f2.bal.moveWaitMin,f2.bal.moveWaitMax)
			d.targetvelocity = ((target.Position - npc.Position):Normalized()*2):Rotated(-50+math.random(100))
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
			
			d.dice = math.random(2)
			if d.dice == 1 then
				local spider = EntityNPC.ThrowSpider(npc.Position, npc, npc.Position + Vector(math.random(-50, 50), math.random(50, 80)), false, -40)
				spider:ToNPC():Morph(810,0,0,-1)
			elseif d.dice == 2 then
				for i=1,2 do
					local spider = EntityNPC.ThrowSpider(npc.Position, npc, npc.Position + Vector(math.random(-50, 50), math.random(50, 80)), false, -40)
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
		
			d.spewR = math.random(1,60)
			d.spewD = math.random(1,2)
			d.spewAction = true
		end
		
		if d.spewAction ~= nil then
		
			if not d.shootSeq then
				d.shootSeq = 24 + math.random(1,6)
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
		if not d.chargeSeq then
		
			mod:SpritePlay(sprite,"AttackDashStart")
			npc:PlaySound(SoundEffect.SOUND_MONSTER_YELL_A, 1, 0, false, 1)
			npc.Velocity = Vector(0,0)
			if target.Position.X < npc.Position.X then
				d.roomBegin = (room:GetGridWidth() * 40) + cWrap
				d.roomEnd = -cWrap
				d.dir = -1
				sprite.FlipX = true
			else
				d.roomEnd = (room:GetGridWidth() * 40) + cWrap
				d.roomBegin = -cWrap
				d.dir = 1
				sprite.FlipX = false
			end
			
			d.chargeSeq = 1
		---start charge
		elseif d.chargeSeq == 1 then
			npc.Friction = f2.bal.attackFriction
			if sprite:IsEventTriggered("Shoot") then
				d.chargeSeq = 2
			end
		--charge first
		elseif d.chargeSeq == 2 then
		
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
				d.chargeSeq = 3
			end			
		--charge splash
		elseif d.chargeSeq == 3 then
		
			npc.Velocity = Vector(15*f2.bal.splashChargeSpeed*d.dir, 0)
			npc.Friction = 0.8
			
			game:SpawnParticles(Vector(npc.Position.X+(60*d.dir),npc.Position.Y), EffectVariant.WATER_SPLASH, 1, 0.4,d.waterColor)
			local params = ProjectileParams()
			params.HeightModifier = 15
			params.Variant = d.tearType
			npc:FireBossProjectiles(1,Vector(npc.Position.X-(f2.bal.splashForce*d.dir),npc.Position.Y+math.random(-f2.bal.splashRange,f2.bal.splashRange)), 0,params)
			--npc:FireBossProjectiles(1,target.Position, 0,params)
			
			if (npc.Position.X > d.roomEnd and d.dir == 1) or (npc.Position.X < d.roomEnd and d.dir == -1) then
				mod:SpritePlay(sprite,"AttackDash")
				npc.Position = Vector(d.roomBegin,target.Position.Y + math.random(-10,10))
				d.targetPos = (room:GetGridWidth() * 40)/2 + (math.random(f2.bal.chargeDistMin,f2.bal.chargeDistMax)*d.dir)
				d.chargeSeq = 4
			end	
		--charge end
		elseif d.chargeSeq == 4 then
		
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
					d.chargeSeq = nil
					d.roomEnd = nil
					d.roomBegin = nil
					d.dir = nil
					d.movesBeforeCharge = 2 + math.random(1,4)	
					d.idleWait = math.random(2,6)
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
			enemyNum = mod:CountRoom(EntityPartition.ENEMY,EntityType.ENTITY_SMALL_LEECH,0)
			if enemyNum <= 4 then
				local spider = EntityNPC.ThrowSpider(npc.Position, npc, npc.Position + Vector(math.random(-50, 50), math.random(20, 40)), false, -80)
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
				d.chaseSeq = f2.bal.subchaseTime + math.random(1,f2.bal.subchasePlus)
			end
			
			if d.chaseSeq % 2 == 0 then
				game:SpawnParticles(npc.Position, EffectVariant.WATER_SPLASH, 1, 0.4,d.waterColor)
				local params = ProjectileParams()
				params.HeightModifier = 10
				params.Variant = d.tearType
				params.VelocityMulti = 1
				params.CircleAngle = 60
				params.FallingAccelModifier = 1.2
				params.PositionOffset = Vector(math.random(-20,20),15)
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
					d.watergunSeq = f2.bal.watergunTime + math.random(1,f2.bal.watergunPlus)
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
						params.Scale = math.random(f2.bal.watergunShotScale, f2.bal.watergunShotScale+5)/10
						--params.FallingAccelModifier = math.random(1,10)/100
						local scatter = Vector(math.random(-f2.bal.watergunScatter,f2.bal.watergunScatter),math.random(-f2.bal.watergunScatter,f2.bal.watergunScatter))
						
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
				
				d.dice = math.random(3)
				if d.dice == 1 then
					local spider = EntityNPC.ThrowSpider(npc.Position, npc, npc.Position + Vector(math.random(-20, 20), math.random(20, 40)), false, -80)
					spider:ToNPC():Morph(810,0,0,-1)
				elseif d.dice == 2 then
					for i=1,2 do
						local spider = EntityNPC.ThrowSpider(npc.Position, npc, npc.Position + Vector(math.random(-20, 20), math.random(20, 40)), false, -80)
						spider:ToNPC():Morph(810,0,0,-1)
					end
				end
			end
		end
	end
end

mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.Famine2AI, f2.id)

--WAR2--------------------

Althorsemen.War2 = {
	name = "Tainted War",
	portrait = "gfx/bosses/war2/portrait_war2.png",
	altPortrait = "gfx/bosses/war2/portrait_war2_ashpit.png",
	bossName = "gfx/bosses/war2/bossname_war2.png",
	id = 650,
	variant = 101,
	chance = 0.2,
	army = {
		name = "Army",
		id = 651,
		variant = 101,
		variantBomb = 102,
		reflectChance = 2,
		walkingBombDamage = 20,
		bombDamage = 40,
		bombPower = 14,
		bombCountdown = 25,
		speed = 3.5,
	},
	bal = {
		idleWaitMin = 40,
		idleWaitMax = 70,
		moveWaitMin = 20,
		moveWaitMax = 30,
		attackFriction = 0.85,
		speed = 1.2,
		minionTime = 80, --horn duration
		minionDelayMin = 50,
		minionDelayMax = 100,
		minionRapidDelay = 10, --delay during horn
		minionBombLimit = 5, --limit before bombs show up
		minionSmallTotalLimit = 12, --limit in small rooms
		minionBigTotalLimit = 18, --limit in big rooms
		bombDamage = 20,
		bombPowerMin = 10,
		bombPowerMax = 15,
		bombCountdown = 25,
		scatterCountdown = 40,
		chargeSpeed = 2.5
	}
}
local w2 = Althorsemen.War2

function mod:War2AI(npc)
	local sprite = npc:GetSprite()
	local d = npc:GetData()
	local target = npc:GetPlayerTarget()
	local level = game:GetLevel()
	local room = game:GetRoom()

	--INIT
	if not d.init then
		d.init = true
		
		npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
		
		if (level:GetStage() == LevelStage.STAGE2_1 or level:GetStage() == LevelStage.STAGE2_2)
		and level:GetStageType() == StageType.STAGETYPE_REPENTANCE_B then
			d.ashpit = true
		end
		
		d.roomSize = "small"
		if room:GetRoomShape() == 4 then
			d.roomSize = "big"
		end
		
		d.movesBeforeHorn = 0
		d.movesBeforeCharge = math.random(2,3)
		d.idleWait = 10
		d.state = "idle"
	end
	
	--IDLE
	if d.state == "idle" then
		
		mod:SpritePlay(sprite, "Idle")
		
		if not d.idleWait then
			d.idleWait = math.random(w2.bal.idleWaitMin,w2.bal.idleWaitMax)
		end
		
		if d.idleWait <= 0 and d.idleWait ~= nil then
			--idle time finish
			d.idleWait = nil
			d.moveWait = nil
			d.movesBeforeHorn = d.movesBeforeHorn - 1
			d.movesBeforeCharge = d.movesBeforeCharge - 1
			
			d.dice = 1
			--horn timer
			if d.movesBeforeHorn <= 0 then
				if not d.hornMoment then
					d.movesBeforeHorn = 4 + math.random(1,2)
					d.dice = 2
				else
					d.hornMoment = nil
				end
			end
			--charge timer
			if d.movesBeforeCharge <= 0 then
				if not d.chargeMoment then
					d.movesBeforeCharge = 4 + math.random(1,2)
					d.dice = 3
				else
					d.chargeMoment = nil
				end
			end
			
			--d.dice = 3
			
			if d.dice == 1 then
				d.state = "throwbomb"
			elseif d.dice == 2 then
				d.state = "horn"
			elseif d.dice == 3 then
				d.state = "charge"
			end
		else
			d.idleWait = d.idleWait - 1
		end
		
		--float move
		if not d.moveWait then
			d.moveWait = math.random(w2.bal.moveWaitMin,w2.bal.moveWaitMax)
			d.targetvelocity = ((target.Position - npc.Position):Normalized()*2):Rotated(-50+math.random(100))
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
			d.movesBeforeCharge = d.movesBeforeCharge + 2
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
			d.bombType = math.random(1,3)
			
			if not d.bombMoves then
				d.bombMoves = math.random(0,2)
			elseif d.bombMoves == 0 then
				d.bombType = math.random(1,4)
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
			d.shootVec = (target.Position - npc.Position):Resized(math.random(w2.bal.bombPowerMin,w2.bal.bombPowerMax))
		elseif sprite:IsEventTriggered("Shoot") then
			
			if d.bombType == 1 then
				d.shootVec = (target.Position - npc.Position):Resized(math.random(w2.bal.bombPowerMin,w2.bal.bombPowerMax))
			end
		
			npc:PlaySound(SoundEffect.SOUND_SHELLGAME, 1, 0, false, 1)
			local bombe = Isaac.Spawn(4, d.bombVariant, 0, npc.Position + d.shootVec, d.shootVec, npc):ToBomb()
			bombe:SetExplosionCountdown(w2.bal.bombCountdown)
			bombe.ExplosionDamage = w2.bal.bombDamage
			bombe:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			bombe.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
			
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
		local cWrap = 90
		--init
		if not d.chargeSeq then
		
			mod:SpritePlay(sprite,"AttackDashStart")
			npc:PlaySound(SoundEffect.SOUND_MONSTER_YELL_A, 1, 0, false, 1)
			npc.Velocity = Vector(0,0)
			if target.Position.X < npc.Position.X then
				d.roomBegin = (room:GetGridWidth() * 40) + cWrap
				d.roomEnd = -cWrap
				d.dir = -1
				sprite.FlipX = true
			else
				d.roomEnd = (room:GetGridWidth() * 40) + cWrap
				d.roomBegin = -cWrap
				d.dir = 1
				sprite.FlipX = false
			end
			
			d.chargeSeq = 1
		---start charge
		elseif d.chargeSeq == 1 then
			npc.Friction = f2.bal.attackFriction
			if sprite:IsEventTriggered("Shoot") then
				Isaac.Explode(npc.Position, npc, 0)
				d.chargeSeq = 2
			end
		--charge first
		elseif d.chargeSeq == 2 then
		
			if sprite:IsFinished("AttackDashStart") then
				mod:SpritePlay(sprite,"AttackDash")
			end
			npc.Velocity = Vector(15*w2.bal.chargeSpeed*d.dir, 0)
			npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS_Y
			if (npc.Position.X > d.roomEnd and d.dir == 1) or (npc.Position.X < d.roomEnd and d.dir == -1) then
				mod:SpritePlay(sprite,"AttackDash")
				--npc.Position = Vector(d.roomBegin,(room:GetGridHeight() * 32))
				npc.Position = Vector(d.roomBegin,(target.Position.Y + room:GetCenterPos().Y) / 2)
				--game:SpawnParticles(Vector(npc.Position.X,npc.Position.Y), EffectVariant.BIG_SPLASH, 1, 0.4,d.waterColor)
				d.chargeSeq = 3
			end			
		--charge splash
		elseif d.chargeSeq == 3 then
		
			npc.Velocity = Vector(15*w2.bal.chargeSpeed*d.dir, 0)
			npc.Friction = 0.8
			
			game:SpawnParticles(Vector(npc.Position.X+(60*d.dir),npc.Position.Y), EffectVariant.WATER_SPLASH, 1, 0.4,d.waterColor)
			local params = ProjectileParams()
			params.HeightModifier = 15
			--params.Variant = d.tearType
			npc:FireBossProjectiles(1,Vector(npc.Position.X-(f2.bal.splashForce*d.dir),npc.Position.Y+math.random(-f2.bal.splashRange,f2.bal.splashRange)), 0,params)
			--npc:FireBossProjectiles(1,target.Position, 0,params)
			
			if (npc.Position.X > d.roomEnd and d.dir == 1) or (npc.Position.X < d.roomEnd and d.dir == -1) then
				mod:SpritePlay(sprite,"AttackDash")
				npc.Position = Vector(d.roomBegin,target.Position.Y + math.random(-10,10))
				d.targetPos = (room:GetGridWidth() * 40)/2 + (math.random(f2.bal.chargeDistMin,f2.bal.chargeDistMax)*d.dir)
				d.chargeSeq = 4
			end	
		--charge end
		elseif d.chargeSeq == 4 then
		
			npc.Velocity = Vector(15*w2.bal.chargeSpeed*d.dir, 0)
			npc.Friction = 1
			
			if (npc.Position.X > d.targetPos and d.dir == 1) or (npc.Position.X < d.targetPos and d.dir == -1) then
				mod:SpritePlay(sprite, "Idle")
				npc.Velocity = npc.Velocity * 0.8
				npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
				
				if (npc.Position.X > d.targetPos + (f2.bal.chargeOvershoot*d.dir) and d.dir == 1) 
				or (npc.Position.X < d.targetPos + (f2.bal.chargeOvershoot*d.dir) and d.dir == -1) then
					--end sequence
					d.targetPos = nil
					d.chargeSeq = nil
					d.roomEnd = nil
					d.roomBegin = nil
					d.dir = nil
					d.idleWait = math.random(2,6)
					d.state = "idle"
				end
			end	
		end
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
					d.minionDelay = d.minionDelay * 0.5
				end
			else
				d.minionDelay = math.random(w2.bal.minionDelayMin,w2.bal.minionDelayMax)
				
				if d.roomSize == "big" then
					d.minionDelay = d.minionDelay * 0.5
				end
			end
		elseif d.minionDelay > 0 then
			d.minionDelay = d.minionDelay - 1
		else
			d.minionDelay = nil
			
			d.minionPos = Isaac.GetRandomPosition()
			local distance = 0
			while distance < 150 do
				d.minionPos = Isaac.GetRandomPosition()
				distance = math.sqrt(((target.Position.X-d.minionPos.X)^2)+((target.Position.Y-d.minionPos.Y)^2))
			end
			
			local posGrid = room:GetGridIndex(d.minionPos)
			d.minionPos = room:GetGridPosition(posGrid)
			
			local minionCount = mod:CountRoom(EntityPartition.ENEMY,w2.army.id,w2.army.variant) 
			local minionLimit = w2.bal.minionSmallTotalLimit
			if d.roomSize == "big" then
				minionLimit = w2.bal.minionBigTotalLimit
			end
			--spawn minion
			if minionCount < minionLimit then
				local minionDice = 0
				if minionCount >= w2.bal.minionBombLimit then
					minionDice = math.random(1,4)
				else
					minionDice = math.random(1,3)
				end
				local army = Isaac.Spawn(w2.army.id, w2.army.variant, minionDice, d.minionPos, Vector(0,0), npc)
				army:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
			end
		end
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

	if not d.init then
		npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
		d.staticPos = npc.Position
		
		if target:ToPlayer().Damage < (npc.MaxHitPoints / 2) then
			npc.HitPoints = target:ToPlayer().Damage * 2
		end
		
		if npc.Variant == w2.army.variant then
			if npc.SubType == 0 then
				npc:ToNPC():Morph(w2.army.id, w2.army.variant, math.random(1,4), -1)
			end
			d.state = "spawn"
		elseif npc.Variant == w2.army.variantBomb then
			if npc.SubType == 0 then
				npc:ToNPC():Morph(w2.army.id, w2.army.variantBomb, math.random(1,3), -1)
			end
			d.state = "bombspawn"
		end
		d.init = true
	elseif d.init then
		npc.StateFrame = npc.StateFrame + 1
	end
	
	if d.state == "spawn" then
		npc.Friction = 0
		npc.Position = d.staticPos
		if not d.spawnSeq then
			mod:SpritePlay(sprite, "DigOut")
			if sprite:IsEventTriggered("Appear") then
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			end
			if sprite:IsFinished("DigOut") then
				d.spawnSeq = 1
			end
		elseif d.spawnSeq == 1 then
			mod:SpritePlay(sprite, "JumpOut")
			if sprite:IsFinished("JumpOut") then
				d.spawnSeq = nil
				d.state = "idle"
			end
		end
	end 
	
	if d.state == "bombspawn" then
		npc.Friction = 0
		npc.Position = d.staticPos
		d.shootVec = (target.Position - npc.Position):Resized(w2.army.bombPower)
		if not d.spawnSeq then
			mod:SpritePlay(sprite, "ThrowBomb")
			if sprite:IsEventTriggered("Appear") then
				d.holdingBomb = true
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
			end
			if sprite:IsEventTriggered("Throw") then
				d.holdingBomb = false
				npc:PlaySound(SoundEffect.SOUND_SHELLGAME, 1, 0, false, 1)
				local bombe = Isaac.Spawn(4, 0, 0, npc.Position, d.shootVec, npc):ToBomb()
				bombe:SetExplosionCountdown(w2.army.bombCountdown)
				bombe.ExplosionDamage = w2.army.bombDamage
				bombe:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
				bombe.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
			end
			if sprite:IsEventTriggered("Disappear") then
				npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			end
			if sprite:IsFinished("ThrowBomb") then
				npc:Remove()
			end
		end
	end 
	
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

------------------------COOL FUNCTIONS------------------------
--------------------------------------------------------------

--check mirror
local function isMirror()
    for i=0,168 do
        local data=Game():GetLevel():GetRoomByIdx(i).Data
        if data and data.Name=='Knife Piece Room' then
            return true
        end
    end
    return false
end

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
function mod:CountRoom(entityPartition,entityType,entityVariant)
	local number = 0
	for i, entity in ipairs(Isaac.FindInRadius(Vector(640, 580), 875, entityPartition)) do
		if entity.Type == entityType and entity.Variant == entityVariant then
			number = number + 1
		end
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

--tears up
local function TearsUp(firedelay, val)
    local currentTears = 30 / (firedelay + 1)
    local newTears = currentTears + val
    return math.max((30 / newTears) - 1, -0.99)
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

--tear collisions
function mod:OnTearCollision(tear, npc, _)
	if npc.Type == w2.army.id and (npc.Variant == w2.army.variant or npc.Variant == w2.army.variantBomb) and npc.SubType == 3 then
		local dice = math.random(w2.army.reflectChance)
		if dice == 1 then
			tear.Velocity = (tear.Velocity * -0.8):Rotated(-20 + math.random(40))
			return false
		end
	end
end

mod:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, mod.OnTearCollision)

--TUMOR CUBE --------------------
Althorsemen.Tumorcube = {
	id = Isaac.GetItemIdByName("Wad of Tumors"),
	variant1 = Isaac.GetEntityVariantByName("Wad of Tumors L1"),
	variant2 = Isaac.GetEntityVariantByName("Wad of Tumors L2"),
	variant3 = Isaac.GetEntityVariantByName("Wad of Tumors L3"),
	variant4 = Isaac.GetEntityVariantByName("Wad of Tumors L4"),
	nugget = Isaac.GetEntityVariantByName("Tumor Nugget"),
	helperid = 270,
	helper = 56,
	helperKeys = 39,
	bal = {
		orbitSpeed = 0.035,
		orbitDistance = Vector(30, 30),
		tearsUp = 0.4,
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
		tumorOrbChance = 2,
		tumorBoyChance = 3,
		jumpCooldown = 200,
		jumpDamage = 65,
		jumpRange = 250,
		stompRange = 90,
		tumorMax1 = 4,
		tumorMax2 = 6,
		tumorMax3 = 15
	}
}

local tc = Althorsemen.Tumorcube

--index------
CollectibleType.COLLECTIBLE_WAD_OF_TUMORS = tc.id
FamiliarVariant.WAD_OF_TUMORS_L1 = Isaac.GetEntityVariantByName("Wad of Tumors L1")
FamiliarVariant.WAD_OF_TUMORS_L2 = Isaac.GetEntityVariantByName("Wad of Tumors L2")
FamiliarVariant.WAD_OF_TUMORS_L3 = Isaac.GetEntityVariantByName("Wad of Tumors L3")
FamiliarVariant.WAD_OF_TUMORS_L4 = Isaac.GetEntityVariantByName("Wad of Tumors L4")
FamiliarVariant.TUMOR_NUGGET = Isaac.GetEntityVariantByName("Tumor Nugget")
--EID--------
if EID then
	EID:addCollectible(CollectibleType.COLLECTIBLE_WAD_OF_TUMORS, "↑ +0.4 Tears up#LVL1: Sticky Orbital#LVL2: Shooting Orbital#LVL3: Ash LVL 1#LVL4: Ash LVL 2")
end
------------------------------------

--cache update
function mod:CacheUpdate(player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
		local tumorNum = player:GetCollectibleNum(tc.id, true)
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
		
		local helperNum = player:GetCollectibleNum(tc.helperid, true)
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
	if flag == CacheFlag.CACHE_FIREDELAY then
		if player:HasCollectible(tc.id) then
			local tumorNum = player:GetCollectibleNum(tc.id, true)
			local tearAmp = 0
			if tumorNum == 2 then tearAmp = 0.3
			elseif tumorNum == 3 then tearAmp = 0.5
			elseif tumorNum >= 4 then tearAmp = 0.6 end
			local tearCalculate = TearsUp(player.MaxFireDelay, tc.bal.tearsUp + tearAmp)
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

--tumor spur
function mod:TumorSpur(tumor,limit)
	local spurCount = 0
	for i, entity in ipairs(Isaac.FindInRadius(tumor.Position, 875, EntityPartition.FAMILIAR)) do
		if entity.Type == EntityType.ENTITY_FAMILIAR and entity.Variant == tc.nugget then
			spurCount = spurCount + 1
		end
	end
	
	if spurCount < limit then
		local spur = Isaac.Spawn(EntityType.ENTITY_FAMILIAR, tc.nugget, 0, tumor.Position, Vector(math.random(-4,4),math.random(-4,4)), tumor):ToFamiliar()
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
		d.creeptime = tc.bal.creepMin + math.random(1,tc.bal.creepBonus)
	else
		if d.creeptime <= 0 then
			d.creeptime = tc.bal.creepMin + math.random(1,tc.bal.creepBonus)
			
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
	
	if not d.cooldown then
		d.cooldown = tumor.FrameCount + tc.bal.shootDelay
	else
		if not (player:GetShootingInput().X == 0 and player:GetShootingInput().Y == 0) and d.cooldown - tumor.FrameCount <= 0 then
			d.animpre = "FloatShoot"
			d.cooldown = tumor.FrameCount + tc.bal.shootDelay
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
		for i, entity in ipairs(Isaac.FindInRadius(Vector(640, 580), 875, EntityPartition.FAMILIAR)) do
			if entity.Type == EntityType.ENTITY_FAMILIAR and entity.Variant == tc.helper then
				if entity:ToFamiliar().Keys ~= tc.helperKeys then
					d.helper = entity
					d.helperInit = true
					break
				end
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
				d.creeptime = tc.bal.creepMin2 + math.random(1,tc.bal.creepBonus2)
			else
				if d.creeptime <= 0 then
					d.creeptime = tc.bal.creepMin2 + math.random(1,tc.bal.creepBonus2)
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
		for i, entity in ipairs(Isaac.FindInRadius(Vector(640, 580), 875, EntityPartition.FAMILIAR)) do
			if entity.Type == EntityType.ENTITY_FAMILIAR and entity.Variant == tc.helper then
				if entity:ToFamiliar().Keys ~= tc.helperKeys then
					d.helper = entity
					d.helperInit = true
					break
				end
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
					d.creeptime = tc.bal.creepMin2 + math.random(1,tc.bal.creepBonus2)
				else
					if d.creeptime <= 0 then
						d.creeptime = tc.bal.creepMin2 + math.random(1,tc.bal.creepBonus2)
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
	local spriteRand = math.random(1,8)
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
		entity:Kill()
		mod:TumorSpur(tumor,tc.bal.tumorMax1)
    elseif entity:IsVulnerableEnemy() then 
		entity:AddSlowing(EntityRef(tumors), tc.bal.slowDuration, tc.bal.slowAmount, tc.bal.slowColor) 
		local tumorDice = math.random(1,tc.bal.tumorBoyChance)
		if entity.HitPoints < tumor.CollisionDamage and tumorDice == 1 and not entity:GetData().tumorSpawned then
			entity:GetData().tumorSpawned = true
			mod:TumorSpur(tumor,tc.bal.tumorMax1)
		end
	end
end

--t3
function mod:TumorCollision3(tumor, entity, _)
    if entity:IsVulnerableEnemy() then 
		entity:AddSlowing(EntityRef(tumors), tc.bal.slowDuration, tc.bal.slowAmount, tc.bal.slowColor) 
		local tumorDice = math.random(1,tc.bal.tumorOrbChance)
		if entity.HitPoints < tumor.CollisionDamage and tumorDice == 1 and not entity:GetData().tumorSpawned then
			entity:GetData().tumorSpawned = true
			mod:TumorSpur(tumor,tc.bal.tumorMax2)
		end
	end
end

--t4
function mod:TumorCollision4(tumor, entity, _)
	if entity:IsVulnerableEnemy() then 
		entity:AddSlowing(EntityRef(tumors), tc.bal.slowDuration, tc.bal.slowAmount, tc.bal.slowColor)
		local tumorDice = math.random(1,tc.bal.tumorOrbChance)
		if entity.HitPoints < tumor.CollisionDamage and tumorDice == 1 and not entity:GetData().tumorSpawned then
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
local revChance = 1

local bossSeen = {
		famine,
		war
	}
local famineTrigger
local bossGen
local tumorConstruct

local firstLoaded = true

--new game
function mod:NewGame(isContinue)
	if not isContinue then
		if firstLoaded then
			if StageAPI then
				print(loadText)
			else
				print(loadTextFailed)
			end
			firstLoaded = false
		end
		bossSeen.famine = false
		bossSeen.war = false
		famineTrigger = false
	end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.NewGame)

--new level
function mod:NewLevel()
	--Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, tc.id, Vector(230, 300), Vector(0,0), nil)
	--Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, tc.id, Vector(290, 300), Vector(0,0), nil)
	--Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, tc.id, Vector(350, 300), Vector(0,0), nil)
	--Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, tc.id, Vector(410, 300), Vector(0,0), nil)
	--Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, tc.id, Vector(100, 220), Vector(0,0), nil)
	--Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 73, Vector(100, 350), Vector(0,0), nil)
	--Isaac.Spawn(EntityType.ENTITY_DUMMY, 0, 0, Vector(320, 220), Vector(0,0), nil)
	--Isaac.Spawn(EntityType.ENTITY_DUMMY, 0, 0, Vector(320, 350), Vector(0,0), nil)
	doHorseDrop = false
	meatCheck = false
	bandageCheck = false
	bossGen = nil
	revChance = 0
	
	if famineTrigger then
		bossSeen.famine = true
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.NewLevel)

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

function mod:BookOfRevelations(collectible)
	if collectible == CollectibleType.COLLECTIBLE_BOOK_OF_REVELATIONS then
		revChance = 1
	end
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM,mod.BookOfRevelations, collectible)

--post mod update
function mod:ILoveHorses()
	local room = game:GetRoom()
	
	--[[local level = game:GetLevel()
	local roomDescript = level:GetRoomByIdx(level:GetCurrentRoomIndex())
	roomDescript.HasWater = true
	
	print(roomDescript.HasWater)]]
	
	if room:GetType() == RoomType.ROOM_BOSS then
		if doHorseDrop then
			for i, entity in ipairs(Isaac.FindInRadius(Vector(640, 580), 875, EntityPartition.PICKUP)) do
				if entity.Type == 5 and entity.Variant == 100 
				and entity.Position.X <= room:GetCenterPos().X and entity.Position.Y > room:GetCenterPos().Y then
					--print("meat time")
					--local dice = math.random(2)
					doHorseDrop = false
					local thisDrop = tc.id 
					
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
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.ILoveHorses)

-------------------------STAGEAPI--------------------------
-----------------------------------------------------------
if StageAPI then	
	mod.StageAPIBosses = {
		StageAPI.AddBossData("Famine2 Downpour", {
			Name = f2.name,
			Portrait = f2.portrait,
			Offset = Vector(0,-15),
			Bossname = f2.bossName,
			Rooms = StageAPI.RoomsList("BossRooms", require("resources.luarooms.boss_famine2"))
		}),
		StageAPI.AddBossData("Famine2 Dross", {
			Name = f2.name,
			Portrait = f2.altPortrait,
			Offset = Vector(0,-15),
			Bossname = f2.bossName,
			Rooms = StageAPI.RoomsList("BossRooms", require("resources.luarooms.boss_famine2_alt"))
		}),
		StageAPI.AddBossData("Famine2 Mirror", {
			Name = f2.name,
			Portrait = f2.portrait,
			Offset = Vector(0,-15),
			Bossname = f2.bossName,
			Rooms = StageAPI.RoomsList("BossRooms", require("resources.luarooms.boss_famine2"))
		}),
		StageAPI.AddBossData("Famine2 Dross Mirror", {
			Name = f2.name,
			Portrait = f2.altPortrait,
			Offset = Vector(0,-15),
			Bossname = f2.bossName,
			Rooms = StageAPI.RoomsList("BossRooms", require("resources.luarooms.boss_famine2_alt"))
		}),
		StageAPI.AddBossData("War2 Mines", {
			Name = w2.name,
			Portrait = w2.portrait,
			Offset = Vector(0,-15),
			Bossname = w2.bossName,
			Rooms = StageAPI.RoomsList("BossRooms", require("resources.luarooms.boss_war2"))
		}),
		StageAPI.AddBossData("War2 Ashpit", {
			Name = w2.name,
			Portrait = w2.altPortrait,
			Offset = Vector(0,-15),
			Bossname = w2.bossName,
			Rooms = StageAPI.RoomsList("BossRooms", require("resources.luarooms.boss_war2"))
		})
	}
end

function mod:StageAPIBossHandling()
	if StageAPI and StageAPI.Loaded and not StageAPI.InTestMode then
		local room = Game():GetRoom()
        if room:GetType() == RoomType.ROOM_BOSS and room:IsFirstVisit() and not StageAPI.InNewStage() then
			
			local level = Game():GetLevel()
			local stage = level:GetStage()
			local stageType = level:GetStageType()
			local dice = RNG()	
			dice:SetSeed(room:GetSpawnSeed(),0)
			if bossGen == nil then
				bossGen = dice:RandomFloat()
			end
			--print(bossGen)
			
			--DOWNPOUR/DROSS
			if (stage == LevelStage.STAGE1_1 or stage == LevelStage.STAGE1_2)
			and (stageType == StageType.STAGETYPE_REPENTANCE or stageType == StageType.STAGETYPE_REPENTANCE_B) then
				--FAMINE
				if bossGen < f2.chance + revChance and not bossSeen.famine then
					--not mirror
					if not isMirror() then
						if stageType == StageType.STAGETYPE_REPENTANCE then
							local validRooms = StageAPI.GetValidRoomsForLayout({
							RoomList = StageAPI.GetBossData("Famine2 Downpour").Rooms,
							})
							if #validRooms > 0 then
								StageAPI.SetCurrentBossRoom("Famine2 Downpour", true)
							end
						elseif stageType == StageType.STAGETYPE_REPENTANCE_B then
							local validRooms = StageAPI.GetValidRoomsForLayout({
							RoomList = StageAPI.GetBossData("Famine2 Dross").Rooms,
							})
							if #validRooms > 0 then
								StageAPI.SetCurrentBossRoom("Famine2 Dross", true)
							end
						end					
						--CheckThatMeat()
						doHorseDrop = true
						famineTrigger = true
					--mirror
					elseif isMirror() then
						if stageType == StageType.STAGETYPE_REPENTANCE then
							local validRooms = StageAPI.GetValidRoomsForLayout({
							RoomList = StageAPI.GetBossData("Famine2 Mirror").Rooms,
							})
							if #validRooms > 0 then
								StageAPI.SetCurrentBossRoom("Famine2 Mirror", true)
							end
						elseif stageType == StageType.STAGETYPE_REPENTANCE_B then
							local validRooms = StageAPI.GetValidRoomsForLayout({
							RoomList = StageAPI.GetBossData("Famine2 Dross Mirror").Rooms,
							})
							if #validRooms > 0 then
								StageAPI.SetCurrentBossRoom("Famine2 Dross Mirror", true)
							end
						end	
						doHorseDrop = true
						famineTrigger = true
					end
				end
			end
			
			--MINES/ASHPIT
			if (stage == LevelStage.STAGE2_1 or stage == LevelStage.STAGE2_2)
			and (stageType == StageType.STAGETYPE_REPENTANCE or stageType == StageType.STAGETYPE_REPENTANCE_B) then
				--WAR
				if bossGen < w2.chance + revChance and not bossSeen.war then
					if stageType == StageType.STAGETYPE_REPENTANCE then
						local validRooms = StageAPI.GetValidRoomsForLayout({
						RoomList = StageAPI.GetBossData("War2 Mines").Rooms,
						})
						if #validRooms > 0 then
							StageAPI.SetCurrentBossRoom("War2 Mines", true)
						end
					elseif stageType == StageType.STAGETYPE_REPENTANCE_B then
						local validRooms = StageAPI.GetValidRoomsForLayout({
						RoomList = StageAPI.GetBossData("War2 Ashpit").Rooms,
						})
						if #validRooms > 0 then
							StageAPI.SetCurrentBossRoom("War2 Ashpit", true)
						end
					end					
					--CheckThatMeat()
					doHorseDrop = true
					bossSeen.war = true
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.StageAPIBossHandling)

--[[
mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    if not StageAPI or not StageAPI.Loaded then
        Isaac.RenderText("StageAPI missing, no alt horsemen :(", 20, 250, 255, 255, 255, 1)
    end
end)]]