local JumpGameWindow = class("JumpGameWindow", import(".BaseWindow"))
local json = require("cjson")
local _, screenHeight = xyd.getScreenSize()

function JumpGameWindow:ctor(name, params)
	JumpGameWindow.super.ctor(self, name, params)

	self.stages = {}
	self.score = 0
	self.extra = 0
	self.nowEmpty = 0
	self.destroyedStage = 0
	self.pressSpeed = 0
	self.stageMoveSpeed = 0
	self.hp = xyd.tables.miscTable:getNumber("nsshaft_max_hp", "value")
end

function JumpGameWindow:initWindow()
	JumpGameWindow.super.initWindow(self)
	self:getUIComponent()
	self:initGame()
	self:register()
end

function JumpGameWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.bg0 = winTrans:ComponentByName("backBg/bg0", typeof(UnityEngine.Rigidbody2D))
	self.bg1 = winTrans:ComponentByName("backBg/bg1", typeof(UnityEngine.Rigidbody2D))
	self.bg2 = winTrans:ComponentByName("backBg/bg2", typeof(UnityEngine.Rigidbody2D))
	self.bg3 = winTrans:ComponentByName("backBg/bg3", typeof(UnityEngine.Rigidbody2D))
	self.touchField = winTrans:NodeByName("touchField").gameObject
	self.stageGroup = winTrans:NodeByName("stageGroup").gameObject
	self.model = self.stageGroup:ComponentByName("model", typeof(UnityEngine.Rigidbody2D))
	self.stage0 = winTrans:NodeByName("stageGroup/stage0").gameObject
	self.buttomStage = winTrans:NodeByName("buttomStage").gameObject
	self.winTop = winTrans:NodeByName("winTop").gameObject
	self.progressBar = self.winTop:ComponentByName("progressBar", typeof(UIProgressBar))
	self.sanLabel = self.winTop:ComponentByName("sanLabel", typeof(UILabel))
	self.scoreLabel = self.winTop:ComponentByName("scoreLabel", typeof(UILabel))
	self.numLabel = self.winTop:ComponentByName("numLabel", typeof(UILabel))
	self.windowHeight = self.window_:GetComponent(typeof(UIPanel)).height
	self.defaultStagePixelSpeed = 200
	self.defaultStageMeterSpeed = self.defaultStagePixelSpeed / self.windowHeight * 2
end

function JumpGameWindow:initGame()
	self.stage0:SetActive(false)
	self:layout()
	self:initBg()
	self:CreateTypePool()

	for i = 1, self.windowHeight / 150 + 2 do
		self:CreateStage()
	end

	self:initModel()
end

function JumpGameWindow:layout()
	self.numLabel.text = self.score
	self.progressBar.value = self.hp / xyd.tables.miscTable:getNumber("nsshaft_max_hp", "value")

	self.buttomStage:Y(-screenHeight / 2 - 100)

	self.BGMID = xyd.tables.miscTable:getString("nsshaft_bgm", "value")

	self:playSound()
end

function JumpGameWindow:playSound()
	if self.BGMID then
		xyd.SoundManager.get():playSound(self.BGMID)
	end
end

function JumpGameWindow:stopSound()
	xyd.SoundManager.get():stopSound(self.BGMID)
end

function JumpGameWindow:initBg()
	self.bg0.velocity = Vector3(0, self.defaultStageMeterSpeed, 0)
	self.bg1.velocity = Vector3(0, self.defaultStageMeterSpeed, 0)
	self.bg2.velocity = Vector3(0, self.defaultStageMeterSpeed, 0)
	self.bg3.velocity = Vector3(0, self.defaultStageMeterSpeed, 0)

	self:waitForTime(1024 / self.defaultStagePixelSpeed, function ()
		NGUITools.Destroy(self.bg0.gameObject)
	end)
	self:waitForTime(2304 / self.defaultStagePixelSpeed, function ()
		self:moveBg(1)
	end, "JumpGameWindowBgMove" .. 1)
	self:waitForTime(3584 / self.defaultStagePixelSpeed, function ()
		self:moveBg(2)
	end, "JumpGameWindowBgMove" .. 2)
	self:waitForTime(4864 / self.defaultStagePixelSpeed, function ()
		self:moveBg(3)
	end, "JumpGameWindowBgMove" .. 3)
end

function JumpGameWindow:moveBg(index)
	self["bg" .. index].transform:Y(self["bg" .. (index == 1 and 3 or index - 1)].transform.localPosition.y - 1280)
	self:waitForTime(1280 / self.defaultStagePixelSpeed * 3, function ()
		self:moveBg(index)
	end, "JumpGameWindowBgMove" .. index)
end

function JumpGameWindow:changeSpeed(speed)
	self.defaultStagePixelSpeed = speed
	self.defaultStageMeterSpeed = self.defaultStagePixelSpeed / self.windowHeight * 2

	for i = 1, 3 do
		XYDCo.StopWait("JumpGameWindowBgMove" .. i)

		if speed ~= 0 then
			self:waitForTime((1280 - self["bg" .. i].transform.localPosition.y) / self.defaultStagePixelSpeed, function ()
				self:moveBg(i)
			end, "JumpGameWindowBgMove" .. i)
		end
	end

	self.bg1.velocity = Vector3(0, self.defaultStageMeterSpeed, 0)
	self.bg2.velocity = Vector3(0, self.defaultStageMeterSpeed, 0)
	self.bg3.velocity = Vector3(0, self.defaultStageMeterSpeed, 0)

	for i = 1, self.stageGroup.transform.childCount do
		local t = self.stageGroup.transform:GetChild(i - 1)

		if t.name ~= "model" then
			t:GetComponent(typeof(UnityEngine.Rigidbody2D)).velocity = Vector3(0, self.defaultStageMeterSpeed, 0)
		end
	end
end

function JumpGameWindow:CreateTypePool()
	local times = xyd.tables.miscTable:split2Cost("nsshaft_rd_limit_type", "value", "|#")
	self.stageTypePool = {}

	for i = 1, #times do
		local time = math.random(times[i][1], times[i][2])

		for j = 1, time do
			table.insert(self.stageTypePool, i)
		end
	end

	for i = 1, #self.stageTypePool do
		local index = math.random(#self.stageTypePool)
		local tmp = self.stageTypePool[i]
		self.stageTypePool[i] = self.stageTypePool[index]
		self.stageTypePool[index] = tmp
	end
end

function JumpGameWindow:CreateStage()
	local stageLimitX = xyd.tables.miscTable:split2Cost("nsshaft_rd_limit_x", "value", "|")[1]
	local stageLimit = xyd.tables.miscTable:split2Cost("nsshaft_rd_limit_x", "value", "|")[2] - 1
	local x = 0

	if not self.stageTypePool or not next(self.stageTypePool) then
		self:CreateTypePool()
	end

	if self.stageTypePool[1] == 6 then
		self.nowEmpty = self.nowEmpty + 1

		if xyd.tables.miscTable:getNumber("nsshaft_max_empty_line", "value") < self.nowEmpty then
			self.stageTypePool[1] = math.random(1, 5)
		else
			table.remove(self.stageTypePool, 1)
			self:CreateStage()

			return
		end
	end

	if #self.stages == 0 then
		local stage = NGUITools.AddChild(self.stageGroup.gameObject, self.stage0)

		stage:X(x)
		stage:Y(-(self.windowHeight / 2 - 39))
		xyd.setUISpriteAsync(stage:GetComponent(typeof(UISprite)), nil, "activity_book_research_16")

		stage:GetComponent(typeof(UnityEngine.Rigidbody2D)).velocity = Vector3(0, self.defaultStageMeterSpeed, 0)

		stage:GetComponent(typeof(CollisionDetecter)).triggerEnterCall = function ()
			if stage.transform.localPosition.y > 0 then
				self:stageDead(stage)
			end
		end

		table.insert(self.stages, stage)

		return
	elseif stageLimit > #self.stages then
		x = math.random(535) - 268
	elseif #self.stages == stageLimit then
		local flag = false

		for j = 1, stageLimit do
			if self.stages[j].transform.localPosition.x <= stageLimitX then
				flag = true
			end
		end

		if flag then
			x = math.random(535) - 268
		else
			x = math.random(stageLimitX * 2 + 1) - (stageLimitX + 1)
		end
	else
		local flag = false
		local topX = self.stages[#self.stages - stageLimit + 1].transform.localPosition.x

		for j = 1, stageLimit do
			if math.abs(self.stages[#self.stages - stageLimit + j].transform.localPosition.x - topX) <= stageLimitX then
				flag = true
			end
		end

		if flag then
			x = math.random(535) - 268
		else
			x = math.random(stageLimitX * 2 + 1) - (stageLimitX + 1)
		end
	end

	local stage = NGUITools.AddChild(self.stageGroup.gameObject, self.stage0)

	stage:X(x)
	stage:Y(self.stages[#self.stages].transform.localPosition.y - xyd.tables.miscTable:getNumber("nsshaft_floor_space", "value") * (1 + self.nowEmpty))

	self.nowEmpty = 0
	local randomNum = math.random(1, 2)

	if self.stageTypePool[1] ~= 5 then
		xyd.setUISpriteAsync(stage:GetComponent(typeof(UISprite)), nil, "activity_book_research_" .. 15 + self.stageTypePool[1])
	else
		local effect = xyd.Spine.new(stage:NodeByName("model").gameObject)

		effect:setInfo("nsshaft_line4", function ()
			effect:play("texiao01", 0, 1)
		end)

		if randomNum == 1 then
			stage:SetLocalScale(-1, 1, 1)
		end
	end

	stage:GetComponent(typeof(UnityEngine.Rigidbody2D)).velocity = Vector3(0, self.defaultStageMeterSpeed, 0)

	if self.stageTypePool[1] == 1 then
		stage:GetComponent(typeof(CollisionDetecter)).collisionEnterCall = function ()
			if stage.transform.localPosition.y < self.model.transform.localPosition.y - 78 then
				self:takeDamage(-xyd.tables.miscTable:getNumber("nsshaft_floor_heal", "value"))

				self.model.gravityScale = 0
			else
				stage:GetComponent(typeof(UnityEngine.BoxCollider2D)).isTrigger = true
			end
		end

		stage:GetComponent(typeof(CollisionDetecter)).collisionExitCall = function ()
			self.model.gravityScale = 0.3
		end

		local point = stage:NodeByName("point").gameObject

		point:SetActive(true)
		point:X(math.random(1, 3) * 60 - 120)
	elseif self.stageTypePool[1] == 2 then
		stage:GetComponent(typeof(CollisionDetecter)).collisionEnterCall = function ()
			if stage.transform.localPosition.y < self.model.transform.localPosition.y - 78 then
				self:takeDamage(-xyd.tables.miscTable:getNumber("nsshaft_floor_heal", "value"))
				self:waitForTime(xyd.tables.miscTable:getNumber("nsshaft_line2_time", "value") / 1000, function ()
					for i = 1, #self.stages do
						if self.stages[i] == stage then
							table.remove(self.stages, i)

							break
						end
					end

					NGUITools.Destroy(stage)

					self.destroyedStage = self.destroyedStage + 1

					self:CreateStage()
				end)

				self.model.gravityScale = 0
			else
				stage:GetComponent(typeof(UnityEngine.BoxCollider2D)).isTrigger = true
			end
		end

		stage:GetComponent(typeof(CollisionDetecter)).collisionExitCall = function ()
			self.model.gravityScale = 0.3
		end
	elseif self.stageTypePool[1] == 3 then
		stage:GetComponent(typeof(CollisionDetecter)).collisionEnterCall = function ()
			if stage.transform.localPosition.y < self.model.transform.localPosition.y - 78 then
				self:takeDamage(xyd.tables.miscTable:getNumber("nsshaft_line3_dmg", "value"))

				self.model.gravityScale = 0
			else
				stage:GetComponent(typeof(UnityEngine.BoxCollider2D)).isTrigger = true
			end
		end

		stage:GetComponent(typeof(CollisionDetecter)).collisionExitCall = function ()
			self.model.gravityScale = 0.3
		end
	elseif self.stageTypePool[1] == 4 then
		stage:GetComponent(typeof(CollisionDetecter)).collisionEnterCall = function ()
			if stage.transform.localPosition.y < self.model.transform.localPosition.y - 78 then
				self:takeDamage(-xyd.tables.miscTable:getNumber("nsshaft_floor_heal", "value"))

				self.model.velocity = Vector3(self.pressSpeed + self.stageMoveSpeed, self.defaultStageMeterSpeed + 0.7, 0)
			else
				stage:GetComponent(typeof(UnityEngine.BoxCollider2D)).isTrigger = true
			end
		end
	elseif self.stageTypePool[1] == 5 then
		if randomNum == 1 then
			stage:GetComponent(typeof(CollisionDetecter)).collisionEnterCall = function ()
				if stage.transform.localPosition.y < self.model.transform.localPosition.y - 78 then
					self:takeDamage(-xyd.tables.miscTable:getNumber("nsshaft_floor_heal", "value"))

					self.stageMoveSpeed = -0.2
					self.model.velocity = Vector3(self.pressSpeed + self.stageMoveSpeed, self.model.velocity.y, 0)
					self.model.gravityScale = 0
				else
					stage:GetComponent(typeof(UnityEngine.BoxCollider2D)).isTrigger = true
				end
			end
		else
			stage:GetComponent(typeof(CollisionDetecter)).collisionEnterCall = function ()
				if stage.transform.localPosition.y < self.model.transform.localPosition.y - 78 then
					self:takeDamage(-xyd.tables.miscTable:getNumber("nsshaft_floor_heal", "value"))

					self.stageMoveSpeed = 0.2
					self.model.velocity = Vector3(self.pressSpeed + self.stageMoveSpeed, self.model.velocity.y, 0)
					self.model.gravityScale = 0
				else
					stage:GetComponent(typeof(UnityEngine.BoxCollider2D)).isTrigger = true
				end
			end
		end

		stage:GetComponent(typeof(CollisionDetecter)).collisionExitCall = function ()
			self.stageMoveSpeed = 0
			self.model.velocity = Vector3(self.pressSpeed + self.stageMoveSpeed, self.model.velocity.y, 0)
			self.model.gravityScale = 0.3
		end

		local point = stage:NodeByName("point").gameObject

		point:SetActive(true)
		point:X(math.random(1, 3) * 60 - 120)
	end

	stage:GetComponent(typeof(CollisionDetecter)).triggerEnterCall = function ()
		if stage:GetComponent(typeof(CollisionDetecter)):GetColliderOther().transform.name == "topStage" then
			self:stageDead(stage)
		end
	end

	table.insert(self.stages, stage)
	table.remove(self.stageTypePool, 1)
end

function JumpGameWindow:stageDead(stage)
	self.score = self.score + xyd.tables.miscTable:getNumber("nsshaft_line_point", "value")
	self.numLabel.text = self.score
	self.destroyedStage = self.destroyedStage + 1

	table.remove(self.stages, 1)
	self:CreateStage()

	if self.score == 200 then
		self:changeSpeed(220)
	elseif self.score == 500 then
		self:changeSpeed(240)
	elseif self.score == 1000 then
		self:changeSpeed(250)
	elseif self.score == 2000 then
		self:changeSpeed(272)
	elseif self.score == 3000 then
		self:changeSpeed(295)
	elseif self.score == 4000 then
		self:endGame(true)
	end

	self:waitForTime(1, function ()
		NGUITools.Destroy(stage)
	end)
end

function JumpGameWindow:takeDamage(num)
	local lastHp = self.hp
	self.hp = math.min(self.hp - num, xyd.tables.miscTable:getNumber("nsshaft_max_hp", "value"))

	if self.hp <= 0 then
		self.progressBar.value = 0

		self:endGame()

		return
	end

	if self.hp ~= lastHp then
		for i = 1, 20 do
			self:waitForFrame(i, function ()
				self.progressBar.value = (lastHp + i * (self.hp - lastHp) / 20) / xyd.tables.miscTable:getNumber("nsshaft_max_hp", "value")
			end)
		end
	end
end

function JumpGameWindow:initModel()
	local cd = self.model:GetComponent(typeof(CollisionDetecter))

	function cd.triggerEnterCall()
		if cd:GetColliderOther().transform.name == "topStage" then
			self.model:GetComponent(typeof(UnityEngine.BoxCollider2D)).isTrigger = true

			self:waitForTime(0.3, function ()
				self.model:GetComponent(typeof(UnityEngine.BoxCollider2D)).isTrigger = false
			end)

			self.model.velocity = Vector3(self.model.velocity.x, 0, 0)

			self:takeDamage(xyd.tables.miscTable:getNumber("nsshaft_top_dmg", "value"))
		elseif cd:GetColliderOther().transform.name == "buttomStage" then
			self:endGame()
		elseif cd:GetColliderOther().transform.name == "point" then
			cd:GetColliderOther():SetActive(false)

			self.score = self.score + xyd.tables.miscTable:getNumber("nsshaft_ex_point", "value")
			self.extra = self.extra + 1
			self.numLabel.text = self.score
		end
	end
end

function JumpGameWindow:endGame(isWin)
	self.touchField:SetActive(false)
	UnityEngine.Object.Destroy(self.model.gameObject)
	self:stopSound()
	self:reqEnd()
	xyd.closeWindow(self.name_)
end

function JumpGameWindow:reqEnd()
	local num = 0

	for i = 1, #self.stages do
		if self.stages[i].transform.localPosition.y > -(screenHeight / 2) then
			num = num + 1
		end
	end

	dump(self.score)
	dump(self.destroyedStage + num)
	dump(self.extra)
	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.BOOK_RESEARCH, json.encode({
		score = self.score,
		distance = self.destroyedStage + num,
		extra = self.extra
	}))
end

local Input = UnityEngine.Input
local KeyCode = UnityEngine.KeyCode

function JumpGameWindow:register()
	JumpGameWindow.super.register(self)

	UIEventListener.Get(self.touchField).onPress = function (go, isPressed)
		if isPressed == true then
			if self.model.transform.localPosition.x < xyd.mouseToLocalPos(self.window_:NodeByName("groupAction")).x then
				self.pressSpeed = 0.7
				self.model.velocity = Vector3(self.pressSpeed + self.stageMoveSpeed, self.model.velocity.y, 0)
			else
				self.pressSpeed = -0.7
				self.model.velocity = Vector3(self.pressSpeed + self.stageMoveSpeed, self.model.velocity.y, 0)
			end
		else
			self.pressSpeed = 0
			self.model.velocity = Vector3(self.pressSpeed + self.stageMoveSpeed, self.model.velocity.y, 0)
		end
	end

	UpdateBeat:Add(self.keyboardControl, self)
end

function JumpGameWindow:keyboardControl()
	if Input.GetKeyDown(KeyCode.LeftArrow) then
		self.pressSpeed = -0.7
		self.model.velocity = Vector3(self.pressSpeed + self.stageMoveSpeed, self.model.velocity.y, 0)
	end

	if Input.GetKeyUp(KeyCode.LeftArrow) then
		self.pressSpeed = 0
		self.model.velocity = Vector3(self.pressSpeed + self.stageMoveSpeed, self.model.velocity.y, 0)
	end

	if Input.GetKeyDown(KeyCode.RightArrow) then
		self.pressSpeed = 0.7
		self.model.velocity = Vector3(self.pressSpeed + self.stageMoveSpeed, self.model.velocity.y, 0)
	end

	if Input.GetKeyUp(KeyCode.RightArrow) then
		self.pressSpeed = 0
		self.model.velocity = Vector3(self.pressSpeed + self.stageMoveSpeed, self.model.velocity.y, 0)
	end
end

function JumpGameWindow:dispose()
	UpdateBeat:Remove(self.keyboardControl, self)
	JumpGameWindow.super.dispose(self)
end

return JumpGameWindow
