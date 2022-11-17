local DogMiniGameWindow = class("DogMiniGameWindow", import(".BaseWindow"))
local DogClass = import("app.components.DogClass")
local HouseClass = import("app.components.HouseClass")

function DogMiniGameWindow:ctor(name, params)
	self.isCanDraw = true
	self.checkDis = 1.2
	self.lineWidth = 0.6
	self.caremaSize = 40
	self.houseArr = {}
	self.noArr = {}
	self.borderArr = {}
	self.level = params.level
	self.allLineArr = {}
	self.gameTime = 10

	self:changeCampaignWindowPos(true)
	DogMiniGameWindow.super.ctor(self, name, params)

	UnityEngine.Input.multiTouchEnabled = false
end

function DogMiniGameWindow:initWindow()
	self:getUIComponent()
	DogMiniGameWindow.super.initWindow(self)
	self:reSize()
	self:registerEvent()
	self:layout()
end

function DogMiniGameWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.dogMainController = self.groupAction:GetComponent(typeof(DogMainController))
	self.uiCamera_ = xyd.WindowManager.get():getUICamera()
	self.uiPanel = self.groupAction:NodeByName("uiPanel").gameObject
	self.closeBtn = self.uiPanel:NodeByName("closeBtn").gameObject

	if not xyd.GuideController.get():isGuideComplete() then
		self.closeBtn:SetActive(false)
	end

	self.resetBtn = self.uiPanel:NodeByName("resetBtn").gameObject
	self.clock = self.uiPanel:ComponentByName("clock", typeof(UISprite))
	self.clockLabel = self.clock:ComponentByName("clockLabel", typeof(UILabel))
	self.clockTimeImg = self.clock:ComponentByName("clockTimeImg", typeof(UISprite))
	self.zhiyinCon = self.uiPanel:NodeByName("zhiyinCon").gameObject
	self.borderDogMaterial = self.groupAction:NodeByName("borderDogMaterial ").gameObject
	self.beePanel = self.groupAction:NodeByName("beePanel").gameObject
	self.bee = self.beePanel:NodeByName("bee").gameObject
	self.dogPanel = self.groupAction:NodeByName("dogPanel").gameObject
	self.borderPanel = self.groupAction:NodeByName("borderPanel").gameObject
	self.linePanel = self.groupAction:NodeByName("linePanel").gameObject
	self.linePanelUIPanel = self.groupAction:ComponentByName("linePanel", typeof(UIPanel))
	self.lineMaterial = self.linePanel:NodeByName("lineMaterial").gameObject
	self.lineUIObjOrder = self.linePanel:ComponentByName("lineUIObjOrder", typeof(UITexture))
	self.deathPanel = self.borderPanel:NodeByName("deathPanel").gameObject
	self.waterPanel = self.borderPanel:NodeByName("waterPanel").gameObject
end

function DogMiniGameWindow:reSize()
end

function DogMiniGameWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.resetBtn.gameObject).onClick = handler(self, function ()
		self:reStart()
	end)
end

function DogMiniGameWindow:layout()
	self:reStart()
end

function DogMiniGameWindow:reStartByOnAppPause()
	local battleFailWd = xyd.WindowManager.get():getWindow("battle_fail_window")
	local battleWinWd = xyd.WindowManager.get():getWindow("battle_win_window")

	if not battleFailWd and not battleWinWd then
		self:reStart()
	end
end

function DogMiniGameWindow:reStart(isNext)
	if self.isRestarting then
		return
	end

	self.isRestarting = true

	self:setDeath(false, true)
	self:waitForFrame(2, function ()
		self:clearAll(isNext)
		self:waitForFrame(3, function ()
			self:newCreat()
			self:waitForFrame(1, function ()
				self.isRestarting = false
			end)
		end)
	end)
end

function DogMiniGameWindow:clearAll(isNext)
	if self.dogItem then
		UnityEngine.Object.Destroy(self.dogItem:getGameObject())

		self.dogItem = nil
	end

	if self.allLineArr and #self.allLineArr > 0 then
		for i in pairs(self.allLineArr) do
			UnityEngine.Object.Destroy(self.allLineArr[i].gameObject)
		end

		self.line = nil
		self.allLineArr = {}
	end

	if self.houseArr and #self.houseArr > 0 then
		for i in pairs(self.houseArr) do
			self.houseArr[i]:setDeath()

			local count = self.beePanel.transform.childCount

			self:waitForFrame(1, function ()
				for i = 1, count do
					local child = self.beePanel.transform:GetChild(i - 1).gameObject

					if child and child.activeSelf then
						UnityEngine.Object.Destroy(child)
					end
				end
			end)
			self.houseArr[i]:reStart()

			local obj = self.houseArr[i]:getGameObject()

			self:waitForFrame(2, function ()
				UnityEngine.Object.Destroy(obj)
			end)
		end

		self.houseArr = {}
	end

	for i in pairs(self.noArr) do
		local box = self.noArr[i].gameObject:GetComponent(typeof(UnityEngine.BoxCollider2D))
		box.enabled = true
	end

	if isNext then
		if self.borderArr and #self.borderArr > 0 then
			for i in pairs(self.borderArr) do
				UnityEngine.Object.Destroy(self.borderArr[i].gameObject)
			end
		end

		self.noArr = {}
		self.borderArr = {}
	end

	self.isEndDraw = false
	self.isCanDraw = true

	if self.timeCount then
		self.timeCount:Pause()
		self.timeCount:Kill(false)

		self.timeCount = nil
	end

	self.clockLabel.text = tostring(self.gameTime)
	self.clockTimeImg.fillAmount = 1
	self.previousPoint = nil
	self.lineFirst = true
	self.startDrawLineArr = {}
end

function DogMiniGameWindow:newCreat()
	self:creatDog()
	self:creatHouse()
	self:creatBorder()
	self:creatLine()

	if self.level == 1 then
		self.zhiyinCon.gameObject:SetLocalPosition(-268, -414, 0)
	end
end

function DogMiniGameWindow:creatDog()
	if self.dogItem == nil then
		local dogInfo = xyd.tables.dogMiniGameLevelTable:getDog(self.level)[1]
		local dogId = dogInfo[1]
		local dogObjName = xyd.tables.dogMiniGameTypeTable:getObjName(dogId)
		local obj = self.dogPanel:NodeByName(dogObjName).gameObject
		local tmp = NGUITools.AddChild(self.dogPanel.gameObject, obj.gameObject)
		local scaleX = xyd.tables.dogMiniGameTypeTable:getScaleX(dogId)

		tmp.gameObject:SetLocalScale(scaleX, 1, 1)

		tmp.transform.localPosition = Vector3(dogInfo[2], dogInfo[3], 0)
		self.dogItem = DogClass.new(tmp, self, {
			borderDogMaterial = self.borderDogMaterial
		})
	end
end

function DogMiniGameWindow:creatHouse()
	if #self.houseArr <= 0 then
		local houseInfo = xyd.tables.dogMiniGameLevelTable:getBeeHouse(self.level)

		for i, info in pairs(houseInfo) do
			local id = info[1]
			local dogObjName = xyd.tables.dogMiniGameTypeTable:getObjName(id)
			local obj = self.borderPanel:NodeByName(dogObjName).gameObject
			local tmp = NGUITools.AddChild(self.borderPanel.gameObject, obj)
			local beeNum = xyd.tables.dogMiniGameTypeTable:getBeeNum(id)
			local houseItem = HouseClass.new(tmp, self, {
				bee = self.bee,
				beeCon = self.beePanel,
				dog = self.dogItem,
				beeNum = beeNum,
				level = self.level
			})

			houseItem:SetLocalPosition(info[2], info[3], 0)
			table.insert(self.houseArr, houseItem)
			houseItem:setHouseIndex(i)

			local scaleX = xyd.tables.dogMiniGameTypeTable:getScaleX(id)

			tmp.gameObject:SetLocalScale(scaleX, 1, 1)
		end
	end
end

function DogMiniGameWindow:creatBorder()
	if #self.borderArr > 0 then
		return
	end

	local houseInfo = xyd.tables.dogMiniGameLevelTable:getBorder(self.level)

	for i, info in pairs(houseInfo) do
		local id = info[1]
		local dogObjName = xyd.tables.dogMiniGameTypeTable:getObjName(id)
		local obj = self.borderPanel:NodeByName(dogObjName).gameObject
		local type = xyd.tables.dogMiniGameTypeTable:getType(id)
		local tmp = nil

		if type == xyd.DogMiniGameType.DEATH then
			tmp = NGUITools.AddChild(self.deathPanel.gameObject, obj)
		elseif type == xyd.DogMiniGameType.WATER then
			tmp = NGUITools.AddChild(self.waterPanel.gameObject, obj)
		elseif type == xyd.DogMiniGameType.NO then
			tmp = NGUITools.AddChild(self.borderPanel.gameObject, obj)

			table.insert(self.noArr, tmp)
		else
			tmp = NGUITools.AddChild(self.borderPanel.gameObject, obj)
		end

		local noSize = xyd.tables.dogMiniGameTypeTable:getSize(id)
		local noUIWidget = tmp.gameObject:GetComponent(typeof(UIWidget))

		if noUIWidget and noSize and #noSize > 0 then
			noUIWidget.width = noSize[1]
			noUIWidget.height = noSize[2]
		end

		tmp:SetLocalPosition(info[2], info[3], 0)

		local isDeath = xyd.tables.dogMiniGameTypeTable:getIsDeath(id)

		if isDeath and isDeath == 1 then
			tmp.name = tmp.name .. "_death"
		end

		local scaleX = xyd.tables.dogMiniGameTypeTable:getScaleX(id)

		tmp.gameObject:SetLocalScale(scaleX, 1, 1)

		local angle = xyd.tables.dogMiniGameTypeTable:getAngle(id)
		tmp.gameObject.transform.localEulerAngles = Vector3(0, 0, angle)

		table.insert(self.borderArr, tmp)
	end
end

function DogMiniGameWindow:creatLine()
	self.dogMainController:AddUpdateCallBack(self.update)
end

function DogMiniGameWindow:update()
	local selfWd = xyd.WindowManager.get():getWindow("dog_mini_game_window")

	if selfWd.isEndDraw then
		return
	end

	local pos = xyd.mouseWorldPos()

	if not selfWd then
		return
	end

	local hit = UnityEngine.Physics2D.CircleCast(pos, selfWd.lineWidth / 2, Vector2.zero, 0)
	local isHit = false

	if hit and hit.transform and hit.transform.name and string.find(hit.transform.name, "border") then
		isHit = true
	end

	if selfWd.previousPoint then
		local dis = Vector2.Distance(pos, selfWd.previousPoint)
		local areadyCheckDis = 0
		local lastCheckPoint = nil

		if selfWd.lineWidth < dis then
			while areadyCheckDis < dis do
				local bili = selfWd.lineWidth / dis
				local addX = (pos.x - selfWd.previousPoint.x) * bili
				local addY = (pos.y - selfWd.previousPoint.y) * bili
				local checkTime = areadyCheckDis / selfWd.lineWidth + 1
				local curPos = Vector3(selfWd.previousPoint.x + addX * checkTime, selfWd.previousPoint.y + addY * checkTime, 0)
				local curPosHit = UnityEngine.Physics2D.CircleCast(curPos, selfWd.lineWidth / 2, Vector2.zero, 0)

				if curPosHit and curPosHit.transform and curPosHit.transform.name and string.find(curPosHit.transform.name, "border") then
					isHit = true
					selfWd.isCanDraw = false

					if lastCheckPoint and selfWd.isAutoDraw ~= false then
						pos = lastCheckPoint
						isHit = false
						selfWd.isCanDraw = true
						selfWd.isAutoDraw = false
					end

					break
				else
					lastCheckPoint = curPos
				end

				areadyCheckDis = areadyCheckDis + selfWd.lineWidth
			end
		end
	end

	if isHit then
		pos = selfWd.previousPoint
		selfWd.isCanDraw = false
	elseif not selfWd.previousPoint then
		selfWd.isCanDraw = true
	elseif not selfWd.isCanDraw then
		local dis = Vector2.Distance(pos, selfWd.previousPoint)

		if dis < selfWd.checkDis then
			selfWd.isCanDraw = true
			selfWd.isAutoDraw = true
		end
	end

	if UnityEngine.Input.GetMouseButtonDown(0) then
		if hit and hit.transform and hit.transform.name then
			if not string.find(hit.transform.name, "border") then
				if string.find(hit.transform.name, "Btn") then
					-- Nothing
				end
			end
		else
			selfWd:creatLineStart(pos)
		end
	elseif UnityEngine.Input.GetMouseButton(0) then
		if selfWd.previousPoint ~= pos or not selfWd.previousPoint then
			selfWd:draw(pos, isHit)
		end
	elseif UnityEngine.Input.GetMouseButtonUp(0) and selfWd.line and selfWd.line.positionCount > 1 then
		selfWd:endDraw()

		selfWd.isEndDraw = true
	end
end

function DogMiniGameWindow:creatLineStart(pos)
	self.line = NGUITools.AddChild(self.linePanel.gameObject, "LineRenderer")
	self.line = self.line:AddComponent(typeof(UnityEngine.LineRenderer))

	ResCache.SetMaterial(self.line, "Materials/Common/ui2dsprite_default_mtrl")

	self.line.useWorldSpace = false
	self.line.widthMultiplier = self.lineWidth
	self.line.sortingOrder = self.lineUIObjOrder.drawCall.sortingOrder

	self.dogMainController:AddLineTexture(self.line, self.lineUIObjOrder)

	self.line.positionCount = 1
	local setPos = self.groupAction:InverseTransformPoint(pos)

	self.line.gameObject:SetLocalPosition(0, 0, 0)

	self.previousPoint = pos
	self.lineFirst = true
	self.startDrawLineArr = {}

	table.insert(self.allLineArr, self.line)
end

function DogMiniGameWindow:draw(pos, isHit)
	if not self.line then
		return
	end

	if isHit then
		pos = self.previousPoint
		self.isCanDraw = false
	elseif not self.isCanDraw then
		local dis = Vector2.Distance(pos, self.previousPoint)

		if dis < self.checkDis then
			self.isCanDraw = true
		end
	end

	if not isHit and self.isCanDraw then
		if self.level == 1 then
			self.zhiyinCon.gameObject:SetLocalPosition(-2600, -414, 0)
		end

		if not self.lineFirst then
			self.line.positionCount = self.line.positionCount + 1
		else
			self.lineFirst = false
		end

		local setPos = self.groupAction:InverseTransformPoint(pos)
		local finalPos = Vector2(setPos.x, setPos.y)

		if self.line.positionCount >= 2 then
			local lastPos = self.line:GetPosition(self.line.positionCount - 2)
			local dis = Vector2.Distance(lastPos, finalPos)

			if dis > 40 then
				local num = math.ceil(dis / 40)
				local littleX = (finalPos.x - lastPos.x) / num
				local littleY = (finalPos.y - lastPos.y) / num

				for i = 1, num - 1 do
					local littlePos = Vector2(lastPos.x + littleX, lastPos.y + littleY)

					self.line:SetPosition(self.line.positionCount - 1, littlePos)

					lastPos = littlePos
					self.line.positionCount = self.line.positionCount + 1
				end
			end
		end

		self.line:SetPosition(self.line.positionCount - 1, finalPos)

		if self.line.positionCount > 1 then
			local collider = NGUITools.AddChild(self.line.gameObject, "boxCollider2DLine")
			collider = collider:AddComponent(typeof(UnityEngine.BoxCollider2D))
			local lastSetPos = self.groupAction:InverseTransformPoint(self.previousPoint)
			local x = (pos.x + self.previousPoint.x) * 0.5
			local y = (pos.y + self.previousPoint.y) * 0.5
			local colliderPos = collider.gameObject.transform:InverseTransformPoint(Vector3(x, y, 0))

			collider:SetLocalPosition(colliderPos.x, colliderPos.y, 0)

			local rad2Deg = 57.295779513082
			local angle = math.atan2((finalPos - lastSetPos).y, (finalPos - lastSetPos).x) * rad2Deg
			collider.transform.localEulerAngles = Vector3(0, 0, angle)
			collider.size = Vector2(Vector2.Distance(finalPos, lastSetPos), self.lineWidth * 850 / 40)
			collider.enabled = false

			table.insert(self.startDrawLineArr, collider)
		end

		self.previousPoint = pos
	end
end

function DogMiniGameWindow:endDraw()
	self:controllerCamera(true)

	local lineRigidbody2D = nil

	if self.line and not self.line.gameObject:GetComponent(typeof(UnityEngine.Rigidbody2D)) then
		lineRigidbody2D = self.line.gameObject:AddComponent(typeof(UnityEngine.Rigidbody2D))
	elseif self.line then
		lineRigidbody2D = self.line.gameObject:GetComponent(typeof(UnityEngine.Rigidbody2D))
	end

	lineRigidbody2D.sharedMaterial = self.lineMaterial:GetComponent(typeof(UnityEngine.Rigidbody2D)).sharedMaterial

	if self.dogItem then
		self.dogItem:startGame(self.caremaSize)
	end

	for i in pairs(self.houseArr) do
		self.houseArr[i]:startGame()
	end

	for i in pairs(self.noArr) do
		local box = self.noArr[i].gameObject:GetComponent(typeof(UnityEngine.BoxCollider2D))
		box.enabled = false
	end

	if self.startDrawLineArr then
		for i in pairs(self.startDrawLineArr) do
			self.startDrawLineArr[i].enabled = true
		end
	end

	if lineRigidbody2D then
		lineRigidbody2D.useAutoMass = true

		if lineRigidbody2D.mass > 6 then
			lineRigidbody2D.useAutoMass = false
			lineRigidbody2D.mass = 6
		end

		lineRigidbody2D.gravityScale = 0.2 * self.caremaSize
	end

	self.clockLabel.text = tostring(self.gameTime)
	self.timeCount = self:getSequence()
	self.clockTimeImg.fillAmount = 1

	local function setter1(value)
		local time = math.floor(value + 1)

		if self.gameTime < time then
			time = self.gameTime
		end

		self.clockLabel.text = time
		self.clockTimeImg.fillAmount = value / self.gameTime
	end

	self.timeCount:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), self.gameTime, 0, self.gameTime):SetEase(DG.Tweening.Ease.Linear))
	self.timeCount:AppendCallback(function ()
		if self.timeCount then
			self.timeCount:Kill(false)

			self.timeCount = nil

			self:win()
		end
	end)
end

function DogMiniGameWindow:controllerCamera(state)
end

function DogMiniGameWindow:getHouseByIndex(houseIndex)
	return self.houseArr[houseIndex]
end

function DogMiniGameWindow:getDog()
	return self.dogItem
end

function DogMiniGameWindow:setDeath(isShowDeathWindow, isNotPlayDie)
	if isShowDeathWindow == nil then
		isShowDeathWindow = true
	end

	if self.line then
		local lineRigidbody2D = self.line.gameObject:GetComponent(typeof(UnityEngine.Rigidbody2D))

		if lineRigidbody2D then
			lineRigidbody2D.bodyType = UnityEngine.RigidbodyType2D.Static
		end
	end

	if self.dogItem then
		self.dogItem:setDeath(isNotPlayDie)
	end

	for i in pairs(self.houseArr) do
		self.houseArr[i]:setDeath()
	end

	if isShowDeathWindow then
		xyd.WindowManager.get():openWindow("battle_fail_window", {
			battleParams = {},
			battle_type = xyd.BattleType.DOG_MINI_GAME,
			dogMiniGameRightBtnFun = function ()
				self:reStart()
			end,
			dogMiniGameLeftBtnFun = function ()
				self:close()
			end,
			dogLevel = self.level
		})
	end

	if self.timeCount then
		self.timeCount:Pause()
		self.timeCount:Kill(false)

		self.timeCount = nil
	end
end

function DogMiniGameWindow:win()
	if self.line then
		local lineRigidbody2D = self.line.gameObject:GetComponent(typeof(UnityEngine.Rigidbody2D))

		if lineRigidbody2D then
			lineRigidbody2D.bodyType = UnityEngine.RigidbodyType2D.Static
		end
	end

	if self.dogItem then
		self.dogItem:setWin()
	end

	for i in pairs(self.houseArr) do
		self.houseArr[i]:setWin()
	end

	xyd.WindowManager.get():openWindow("battle_win_window", {
		battleParams = {
			items = {}
		},
		battle_type = xyd.BattleType.DOG_MINI_GAME,
		dogMiniGameRightBtnFun = function ()
			if xyd.models.selfPlayer:getDogMiniPassLevel() <= self.level then
				self.level = xyd.models.selfPlayer:getDogMiniPassLevel() + 1
			else
				self.level = self.level + 1
			end

			local allLevelIds = xyd.tables.dogMiniGameLevelTable:getIDs()

			if allLevelIds[#allLevelIds] < self.level then
				self.level = allLevelIds[#allLevelIds]
			end

			local stageId = xyd.tables.dogMiniGameLevelTable:getStageId(self.level)
			local mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
			local maxStage = nil

			if mapInfo then
				maxStage = mapInfo.max_stage
			else
				maxStage = 0
			end

			if stageId <= maxStage then
				self:reStart(true)
			else
				self:close()

				local fortId = xyd.tables.stageTable:getFortID(stageId)
				local text = tostring(fortId) .. "-" .. tostring(xyd.tables.stageTable:getName(stageId))

				xyd.showToast(__("FUNC_OPEN_STAGE", text))
			end
		end,
		dogMiniGameLeftBtnFun = function ()
			self:close()

			if not xyd.GuideController.get():isGuideComplete() then
				local dogMiniGameChoiceLevelWd = xyd.WindowManager.get():getWindow("dog_mini_game_choice_level_window")

				if dogMiniGameChoiceLevelWd then
					xyd.WindowManager.get():closeWindow("dog_mini_game_choice_level_window")
				end
			end
		end,
		items = xyd.tables.dogMiniGameLevelTable:getAwards(self.level),
		dogLevel = self.level,
		dogIsShowItems = xyd.models.selfPlayer:getDogMiniPassLevel() < self.level
	})

	if xyd.models.selfPlayer:getDogMiniPassLevel() < self.level then
		xyd.models.selfPlayer:sendDogMiniLevel(self.level)
	end

	if self.timeCount then
		self.timeCount:Pause()
		self.timeCount:Kill(false)

		self.timeCount = nil
	end

	self.clockLabel.text = "0"
end

function DogMiniGameWindow:willClose()
	self:changeCampaignWindowPos(false)

	local dogMiniGameChoiceLevelWd = xyd.WindowManager.get():getWindow("dog_mini_game_choice_level_window")

	if dogMiniGameChoiceLevelWd then
		dogMiniGameChoiceLevelWd:update(true)
	end

	UnityEngine.Input.multiTouchEnabled = true

	DogMiniGameWindow.super.willClose(self)
end

function DogMiniGameWindow:changeCampaignWindowPos(state)
	local campaignWd = xyd.WindowManager.get():getWindow("campaign_window")

	if campaignWd then
		if state then
			campaignWd:getWindowTrans().gameObject:X(2000)
		else
			campaignWd:getWindowTrans().gameObject:X(0)
		end
	end
end

return DogMiniGameWindow
