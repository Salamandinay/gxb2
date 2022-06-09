local ActivitySpfarmBuildUpWindow = class("ActivitySpfarmBuildUpWindow", import(".BaseWindow"))
local json = require("cjson")
local Partner = import("app.models.Partner")

function ActivitySpfarmBuildUpWindow:ctor(name, params)
	ActivitySpfarmBuildUpWindow.super.ctor(self, name, params)

	self.gridId = params.gridId
	self.isDowningBtn = false
	self.isMiddleSend = false
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)
	self.buildInfo = self.activityData:getBuildBaseInfo(self.gridId)
	self.showLev = self.buildInfo.lv
end

function ActivitySpfarmBuildUpWindow:initWindow()
	self:getUIComponent()
	ActivitySpfarmBuildUpWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function ActivitySpfarmBuildUpWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.winTitle = self.topGroup:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = self.topGroup:NodeByName("closeBtn").gameObject
	self.infoCon = self.groupAction:NodeByName("infoCon").gameObject
	self.buildImg = self.infoCon:ComponentByName("buildImg", typeof(UISprite))
	self.infoBg = self.infoCon:ComponentByName("infoBg", typeof(UISprite))
	self.levLabel = self.infoBg:ComponentByName("levLabel", typeof(UILabel))
	self.nameLabel = self.infoBg:ComponentByName("nameLabel", typeof(UILabel))
	self.defendCon = self.groupAction:NodeByName("defendCon").gameObject
	self.defendIcon = self.defendCon:ComponentByName("defendIcon", typeof(UISprite))
	self.defendLabel = self.defendIcon:ComponentByName("defendLabel", typeof(UILabel))
	self.posCOn = self.defendCon:NodeByName("posCOn").gameObject

	for i = 1, 3 do
		self["posBg" .. i] = self.posCOn:ComponentByName("posBg" .. i, typeof(UISprite))
		self["posLabel" .. i] = self["posBg" .. i]:ComponentByName("posLabel" .. i, typeof(UILabel))
		self["posLock" .. i] = self["posBg" .. i]:ComponentByName("posLock" .. i, typeof(UISprite))
		self["heroCon" .. i] = self["posBg" .. i]:NodeByName("heroCon" .. i).gameObject
	end

	self.defendConBg = self.defendCon:ComponentByName("defendConBg", typeof(UISprite))
	self.downGroup = self.groupAction:NodeByName("downGroup").gameObject
	self.showItem3 = self.downGroup:NodeByName("showItem3").gameObject
	self.showItemLabel3 = self.showItem3:ComponentByName("showItemLabel3", typeof(UILabel))
	self.showItem1 = self.downGroup:NodeByName("showItem1").gameObject
	self.showItemBg1 = self.showItem1:ComponentByName("showItemBg1", typeof(UISprite))
	self.showItemLabel1 = self.showItemBg1:ComponentByName("showItemLabel1", typeof(UILabel))
	self.showItemLine1 = self.showItem1:ComponentByName("showItemLine1", typeof(UISprite))
	self.showItem1Left = self.showItem1:NodeByName("showItem1Left").gameObject
	self.showItem1LeftUILayout = self.showItem1:ComponentByName("showItem1Left", typeof(UILayout))
	self.showItem1LeftIcon = self.showItem1Left:ComponentByName("showItem1LeftIcon", typeof(UISprite))
	self.showItem1LeftLabelCon = self.showItem1Left:NodeByName("showItem1LeftLabelCon").gameObject
	self.showItem1LeftLabel = self.showItem1LeftLabelCon:ComponentByName("showItem1LeftLabel", typeof(UILabel))
	self.showItem1Right = self.showItem1:NodeByName("showItem1Right").gameObject
	self.showItem1RightUILayout = self.showItem1:ComponentByName("showItem1Right", typeof(UILayout))
	self.showItem1RightIcon = self.showItem1Right:ComponentByName("showItem1RightIcon", typeof(UISprite))
	self.showItem1RightLabelCon = self.showItem1Right:NodeByName("showItem1RightLabelCon").gameObject
	self.showItem1RightLabel = self.showItem1RightLabelCon:ComponentByName("showItem1RightLabel", typeof(UILabel))
	self.showItem1Arrow = self.showItem1:ComponentByName("showItem1Arrow", typeof(UISprite))
	self.showItem2 = self.downGroup:NodeByName("showItem2").gameObject
	self.showItemBg2 = self.showItem2:ComponentByName("showItemBg2", typeof(UISprite))
	self.showItemLabel2 = self.showItemBg2:ComponentByName("showItemLabel2", typeof(UILabel))
	self.showItemLine2 = self.showItem2:ComponentByName("showItemLine2", typeof(UISprite))
	self.showItem2Left = self.showItem2:NodeByName("showItem2Left").gameObject
	self.showItem2LeftLabel = self.showItem2Left:ComponentByName("showItem2LeftLabel", typeof(UILabel))
	self.showItem2Right = self.showItem2:NodeByName("showItem2Right").gameObject
	self.showItem2RightLabel = self.showItem2Right:ComponentByName("showItem2RightLabel", typeof(UILabel))
	self.showItem2Arrow = self.showItem2:ComponentByName("showItem2Arrow", typeof(UISprite))
	self.btn = self.downGroup:NodeByName("btn").gameObject
	self.btnBoxCollider = self.downGroup:ComponentByName("btn", typeof(UnityEngine.BoxCollider))
	self.btnLable = self.btn:ComponentByName("btnLable", typeof(UILabel))
	self.resItem = self.btn:NodeByName("resItem").gameObject
	self.resItemIcon = self.resItem:ComponentByName("resItemIcon", typeof(UISprite))
	self.resItemLabel = self.resItem:ComponentByName("resItemLabel", typeof(UILabel))
	self.btnMask = self.btn:NodeByName("btnMask").gameObject
	self.collectionBtn = self.downGroup:NodeByName("collectionBtn").gameObject
	self.collectionBtnBoxCollider = self.downGroup:ComponentByName("collectionBtn", typeof(UnityEngine.BoxCollider))
	self.collectionBtnLable = self.collectionBtn:ComponentByName("collectionBtnLable", typeof(UILabel))
	self.collectionResItem = self.collectionBtn:NodeByName("collectionResItem").gameObject
	self.collectionResItemIcon = self.collectionResItem:ComponentByName("collectionResItemIcon", typeof(UISprite))
	self.collectionResItemLabel = self.collectionResItem:ComponentByName("collectionResItemLabel", typeof(UILabel))
	self.scrollView2 = self.groupAction:NodeByName("scrollView2").gameObject
	self.scrollView2UIScrollView = self.groupAction:ComponentByName("scrollView2", typeof(UIScrollView))
	self.descLabel = self.scrollView2:ComponentByName("descLabel", typeof(UILabel))
	self.anotherCon = self.groupAction:NodeByName("anotherCon").gameObject
	self.anotherChangeBtn = self.anotherCon:NodeByName("anotherChangeBtn").gameObject
	self.anotherChangeLabel = self.anotherChangeBtn:ComponentByName("anotherChangeLabel", typeof(UILabel))
	self.anotherMoveBtn = self.anotherCon:NodeByName("anotherMoveBtn").gameObject
	self.anotherMoveLabel = self.anotherMoveBtn:ComponentByName("anotherMoveLabel", typeof(UILabel))
	self.effectPanel = self.groupAction:NodeByName("effectPanel").gameObject
	self.effectCon = self.effectPanel:ComponentByName("effectCon", typeof(UITexture))
end

function ActivitySpfarmBuildUpWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.btn).onPress = handler(self, function ()
		local function clickBtnFun()
			if not self.isDowningBtn then
				self.isDowningBtn = true
				self.countTime = 0

				self.btnMask:SetActive(true)
				self:startCountTime()

				return
			end

			if self.isMiddleSend then
				self.isMiddleSend = false

				if self.isDowningBtn then
					self.isDowningBtn = false
				end

				self:waitForTime(0.3, function ()
					self.btnMask:SetActive(false)
				end)

				return
			end

			if self.isDowningBtn then
				self.isDowningBtn = false

				self:checkNowLevShow()

				self.isMiddleSend = false
			end
		end

		if not self.isDowningBtn and self.activityData:isViewing() then
			local maxLev = self.activityData:getTypeBuildMaxLevUp(self.buildType)
			local limitLev = self.activityData:getTypeBuildLimitLevUp(self.buildType)

			if maxLev <= self.showLev then
				clickBtnFun()

				return
			end

			if limitLev <= self.showLev then
				clickBtnFun()

				return
			end

			local timeStamp = xyd.db.misc:getValue("actiivty_spfarm_isviewing_click_time_stamp")
			timeStamp = timeStamp and tonumber(timeStamp)
			local gambleTipsWd = xyd.WindowManager.get():getWindow("gamble_tips_window")

			if gambleTipsWd then
				return
			end

			if not timeStamp or timeStamp < self.activityData:startTime() or self.activityData:getEndTime() < timeStamp then
				xyd.openWindow("gamble_tips_window", {
					type = "actiivty_spfarm_isviewing_click",
					wndType = self.curWindowType_,
					text = __("ACTIVITY_SPFARM_TEXT116"),
					callback = function ()
						local upCost = xyd.tables.activitySpfarmBuildingTable:getCost(self.buildId)

						if xyd.models.backpack:getItemNumByID(upCost[1]) >= upCost[2] * 1 then
							self:sendUp(1)
						else
							xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(upCost[1])))
						end
					end,
					labelNeverText = __("ACTIVITY_SPFARM_TEXT30")
				})
			else
				clickBtnFun()
			end
		else
			clickBtnFun()
		end
	end)

	UIEventListener.Get(self.collectionBtn.gameObject).onClick = function ()
		local collectionLimit = xyd.tables.miscTable:split2num("activity_spfarm_fast", "value", "|")
		local famousLimt = collectionLimit[1]

		if self.activityData:getFamousNum() < famousLimt then
			xyd.alertTips(__("ACTIVITY_SPFARM_TEXT94", famousLimt))

			return
		end

		local collectionCost = xyd.tables.activitySpfarmBuildingTable:getCostFast(self.buildId)

		if xyd.models.backpack:getItemNumByID(collectionCost[1]) < collectionCost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(collectionCost[1])))

			return
		end

		xyd.alertYesNo(__("ACTIVITY_SPFARM_TEXT95", collectionCost[2], xyd.tables.itemTable:getName(collectionCost[1])), function (yes_no)
			if yes_no then
				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
					type = xyd.ActivitySpfarmType.FORCE_HANG,
					id = self.buildInfo.id
				}))
			end
		end)
	end

	UIEventListener.Get(self.anotherChangeBtn.gameObject).onClick = handler(self, function ()
		local function changeFun()
			xyd.WindowManager.get():openWindow("activity_spfarm_build_window", {
				type = xyd.ActivitySpfarmBuildWindowType.CHANGE,
				pos = self.gridId,
				defaultLev = self.buildInfo.lv
			})
		end

		if self.buildInfo.build_id == self.activityData:getTreeBuildId() and self.activityData:checkIsOnlyBuildId2IsOne() then
			xyd.alertYesNo(__("ACTIVITY_SPFARM_TEXT67"), function (yes_no)
				if yes_no then
					changeFun()
				end
			end)
		else
			changeFun()
		end
	end)
	UIEventListener.Get(self.anotherMoveBtn.gameObject).onClick = handler(self, function ()
		local activitySpfarmMapWd = xyd.WindowManager.get():getWindow("activity_spfarm_map_window")

		if activitySpfarmMapWd then
			activitySpfarmMapWd:openMove(self.gridId, xyd.ActivitySpfarmOpenMoveType.UP, self.buildInfo.id)
			self:close()
		end
	end)
	UIEventListener.Get(self.defendConBg.gameObject).onClick = handler(self, function ()
		if xyd.arrayIndexOf(self.activityData:getDoorRoundIds(), self.gridId) > 0 then
			xyd.alertTips(__("ACTIVITY_SPFARM_TEXT37"))

			return
		end

		if (not self.buildInfo.partners or self.buildInfo.partners and #self.buildInfo.partners == 0) and self.activityData:getTypeDefLimitNum() <= self.activityData:getTypeDefMyNum() then
			xyd.alertTips(__("ACTIVITY_SPFARM_TEXT38"))

			return
		end

		xyd.WindowManager.get():openWindow("battle_formation_spfarm_window", {
			showSkip = false,
			spfarm_type = xyd.ActivitySpfarmOpenBattleFormationType.DEF,
			battleType = xyd.BattleType.ACTIVITY_SPFARM,
			gridId = self.gridId
		})
	end)
end

function ActivitySpfarmBuildUpWindow:layout()
	self.buildId = self.activityData:getBuildBaseInfo(self.gridId).build_id
	self.buildType = xyd.tables.activitySpfarmBuildingTable:getType(self.buildId)
	self.winTitle.text = __("ACTIVITY_SPFARM_TEXT20")
	self.showItemLabel1.text = __("ACTIVITY_SPFARM_TEXT21")
	self.showItemLabel2.text = __("ACTIVITY_SPFARM_TEXT22")
	self.defendLabel.text = __("ACTIVITY_SPFARM_TEXT23")
	self.showItemLabel3.text = __("ACTIVITY_SPFARM_TEXT24")
	self.anotherChangeLabel.text = __("ACTIVITY_SPFARM_TEXT27")
	self.anotherMoveLabel.text = __("ACTIVITY_SPFARM_TEXT28")
	self.collectionBtnLable.text = __("ACTIVITY_SPFARM_TEXT93")

	self:updateBaseInfo()
	self:updateDown()
	self:updateDefPartners()
end

function ActivitySpfarmBuildUpWindow:updateBaseInfo()
	local buildImg = xyd.tables.activitySpfarmBuildingTable:getIcon(self.buildId)

	xyd.setUISpriteAsync(self.buildImg, nil, buildImg)

	self.levLabel.text = "Lv." .. self.showLev .. "/" .. self.activityData:getTypeBuildLimitLevUp(self.buildType)

	if xyd.Global.lang == "fr_fr" then
		self.levLabel.text = "Niv." .. self.showLev .. "/" .. self.activityData:getTypeBuildLimitLevUp(self.buildType)
	end

	self.nameLabel.text = xyd.tables.activitySpfarmBuildingTextTable:getName(self.buildId)
end

function ActivitySpfarmBuildUpWindow:updateDown()
	local defense = xyd.tables.activitySpfarmBuildingTable:getDefense(self.buildId)
	local outCome = xyd.tables.activitySpfarmBuildingTable:getOutcome(self.buildId)
	local buildType = xyd.tables.activitySpfarmBuildingTable:getType(self.buildId)
	local maxLev = self.activityData:getTypeBuildMaxLevUp(buildType)

	if xyd.Global.lang == "fr_fr" then
		self.descLabel.width = 500
		self.descLabel.fontSize = 19
	end

	if defense and defense > 0 then
		self.descLabel.text = __("ACTIVITY_SPFARM_TEXT17", tostring(defense * 100 * self.showLev) .. "%")

		self.showItem1:SetActive(false)
		self.showItem2:SetActive(true)

		self.showItem2LeftLabel.text = defense * 100 * self.showLev .. "%"

		if maxLev <= self.showLev then
			self.showItem2RightLabel.text = " "

			self.showItem2Arrow.gameObject:SetActive(false)
		else
			self.showItem2RightLabel.text = defense * 100 * (self.showLev + 1) .. "%"

			self.showItem2Arrow.gameObject:SetActive(true)
		end
	elseif outCome and #outCome > 0 then
		local nameStr = xyd.tables.itemTable:getName(outCome[1])
		self.descLabel.text = __("ACTIVITY_SPFARM_TEXT16", xyd.getRoughDisplayNumber(outCome[2] * self.showLev), nameStr)

		self.showItem1:SetActive(true)
		self.showItem2:SetActive(false)

		self.showItem1LeftLabel.text = "x " .. xyd.getRoughDisplayNumber(outCome[2] * self.showLev)

		xyd.setUISpriteAsync(self.showItem1LeftIcon, nil, xyd.tables.itemTable:getIcon(outCome[1]))
		xyd.setUISpriteAsync(self.showItem1RightIcon, nil, xyd.tables.itemTable:getIcon(outCome[1]))
		self:waitForFrame(1, function ()
			self.showItem1LeftUILayout:Reposition()
		end)

		if maxLev <= self.showLev then
			self.showItem1RightLabel.text = " "

			self.showItem1Arrow.gameObject:SetActive(false)
			self.showItem1Right.gameObject:SetActive(false)
			self.resItem.gameObject:SetActive(false)
		else
			self.showItem1RightLabel.text = "x " .. xyd.getRoughDisplayNumber(outCome[2] * (self.showLev + 1))

			self.showItem1Arrow.gameObject:SetActive(true)
			self.showItem1Right.gameObject:SetActive(true)
			self.resItem.gameObject:SetActive(true)
			self:waitForFrame(1, function ()
				self.showItem1RightUILayout:Reposition()
			end)
		end
	end

	if maxLev <= self.showLev then
		self.resItem.gameObject:SetActive(false)
		self.btnLable.gameObject:X(0)

		self.btnLable.text = __("ACTIVITY_SPFARM_TEXT25")
		self.btnLable.width = 150

		if maxLev <= self.buildInfo.lv then
			if outCome and #outCome > 0 then
				self.btn.gameObject:SetActive(false)
				self.collectionBtn.gameObject:SetActive(true)

				if self.buildInfo.force and self.buildInfo.force == self.activityData:getCurTimeDay() then
					self.collectionBtnBoxCollider.enabled = false
					self.collectionBtnLable.text = __("ACTIVITY_SPFARM_TEXT96")

					xyd.applyChildrenGrey(self.collectionBtn.gameObject)
				end
			else
				xyd.applyChildrenGrey(self.btn.gameObject)

				self.btnBoxCollider.enabled = false
			end
		end
	else
		self.resItem.gameObject:SetActive(true)
		self.btnLable.gameObject:X(24.3)

		self.btnLable.text = __("LEV_UP")
		self.btnLable.width = 88
	end

	self.scrollView2UIScrollView:ResetPosition()

	local upCost = xyd.tables.activitySpfarmBuildingTable:getCost(self.buildId)

	xyd.setUISpriteAsync(self.resItemIcon, nil, xyd.tables.itemTable:getIcon(upCost[1]))

	self.resItemLabel.text = tostring(upCost[2])
	local collectionCost = xyd.tables.activitySpfarmBuildingTable:getCostFast(self.buildId)

	xyd.setUISpriteAsync(self.collectionResItemIcon, nil, xyd.tables.itemTable:getIcon(collectionCost[1]))

	self.collectionResItemLabel.text = tostring(collectionCost[2])
end

function ActivitySpfarmBuildUpWindow:startCountTime()
	self:waitForTime(0.3, function ()
		if self.isDowningBtn and not self.isMiddleSend then
			self.countTime = self.countTime + 0.3

			self:checkNowLevShow()
			self:startCountTime()
		end

		if not self.isDowningBtn then
			self.btnMask:SetActive(false)
		end
	end)
end

function ActivitySpfarmBuildUpWindow:checkNowLevShow()
	local needAddNum = 0
	local limitLev = self.activityData:getTypeBuildLimitLevUp(self.buildType)
	local maxLev = self.activityData:getTypeBuildMaxLevUp(self.buildType)
	local isShowEffect = false
	local upCost = xyd.tables.activitySpfarmBuildingTable:getCost(self.buildId)

	if maxLev <= self.showLev then
		xyd.alertTips(__("ACTIVITY_SPFARM_TEXT25"))

		self.isMiddleSend = true

		if self.buildInfo.lv < self.showLev then
			if xyd.models.backpack:getItemNumByID(upCost[1]) >= upCost[2] * (maxLev - self.buildInfo.lv) then
				self:sendUp(maxLev - self.buildInfo.lv)

				isShowEffect = true
			else
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(upCost[1])))
			end
		end

		return
	end

	if limitLev <= self.showLev then
		xyd.alertTips(__("ACTIVITY_SPFARM_TEXT26"))

		self.isMiddleSend = true

		if self.buildInfo.lv < self.showLev then
			if xyd.models.backpack:getItemNumByID(upCost[1]) >= upCost[2] * (limitLev - self.buildInfo.lv) then
				self:sendUp(limitLev - self.buildInfo.lv)

				isShowEffect = true
			else
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(upCost[1])))
			end
		end

		return
	end

	if self.countTime < 0.3 then
		needAddNum = 1

		if xyd.models.backpack:getItemNumByID(upCost[1]) >= upCost[2] * needAddNum then
			self:sendUp(needAddNum)

			isShowEffect = true
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(upCost[1])))
		end
	elseif self.countTime > 0.3 then
		needAddNum = math.floor(self.countTime / 0.3)

		if xyd.models.backpack:getItemNumByID(upCost[1]) < upCost[2] * needAddNum then
			self.isMiddleSend = true

			if maxLev <= self.showLev + 1 then
				xyd.alertTips(__("ACTIVITY_SPFARM_TEXT25"))
			elseif limitLev <= self.showLev + 1 then
				xyd.alertTips(__("ACTIVITY_SPFARM_TEXT26"))
			else
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(upCost[1])))
			end

			if needAddNum >= 2 and xyd.models.backpack:getItemNumByID(upCost[1]) >= upCost[2] * (needAddNum - 1) then
				self:sendUp(needAddNum - 1)

				isShowEffect = true
			end
		else
			self.showLev = self.showLev + 1

			if self.isDowningBtn then
				self:updateBaseInfo()
				self:updateDown()

				isShowEffect = true
			else
				self:sendUp(needAddNum)

				isShowEffect = true
			end
		end
	end

	if isShowEffect then
		self:playUpEffect()
	end
end

function ActivitySpfarmBuildUpWindow:playUpEffect()
	self.isEffectPlaying = true

	if not self.up_effect then
		self.up_effect = xyd.Spine.new(self.effectCon.gameObject)

		self.up_effect:setInfo("fx_ui_saoxing", function ()
			self.up_effect:play("texiao01", 1, 1.5, function ()
				self.isEffectPlaying = false
			end)
		end)
	else
		self.up_effect:play("texiao01", 1, 1.5, function ()
			self.isEffectPlaying = false
		end)
	end
end

function ActivitySpfarmBuildUpWindow:sendUp(num)
	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
		type = xyd.ActivitySpfarmType.UP_GRADE,
		id = self.buildInfo.id,
		num = num
	}))
end

function ActivitySpfarmBuildUpWindow:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_SPFARM then
		return
	end

	local data = xyd.decodeProtoBuf(event.data)
	data.detail = json.decode(data.detail)

	if data.detail.type == xyd.ActivitySpfarmType.UP_GRADE then
		self.buildInfo = self.activityData:getBuildBaseInfo(self.gridId)
		self.showLev = self.buildInfo.lv

		self:updateBaseInfo()
		self:updateDown()
	elseif data.detail.type == xyd.ActivitySpfarmType.CHANGE then
		self:close()
	elseif data.detail.type == xyd.ActivitySpfarmType.SET_DEF then
		self:updateDefPartners()
	elseif data.detail.type == xyd.ActivitySpfarmType.FORCE_HANG then
		self.buildInfo = self.activityData:getBuildBaseInfo(self.gridId)

		self:updateDown()
	end
end

function ActivitySpfarmBuildUpWindow:updateDefPartners()
	if xyd.arrayIndexOf(self.activityData:getDoorRoundIds(), self.gridId) > 0 then
		for i = 1, 3 do
			xyd.setUISpriteAsync(self["posBg" .. i], nil, "activity_spfarm_bg_wjs")
			self["posLock" .. i]:SetActive(true)

			self["posLabel" .. i].text = " "
		end
	else
		for i = 1, 3 do
			xyd.setUISpriteAsync(self["posBg" .. i], nil, "formation_front_bg")
			self["posLock" .. i]:SetActive(false)

			self["posLabel" .. i].text = tostring(i)
		end
	end

	if not self.heroArr then
		self.heroArr = {}
	end

	if self.buildInfo.partners and #self.buildInfo.partners > 0 then
		local hasArr = {}

		for i, info in pairs(self.buildInfo.partners) do
			local np = Partner.new()

			np:populate(info)

			local inInfo = np:getInfo()
			local index = nil

			if info.pos == 1 then
				index = 1
			elseif info.pos == 3 then
				index = 2
			elseif info.pos == 5 then
				index = 3
			end

			table.insert(hasArr, index)

			if not self.heroArr[index] then
				self.heroArr[index] = import("app.components.HeroIcon").new(self["heroCon" .. index].gameObject)
				local scale = 0.6018518518518519

				self.heroArr[index]:setScale(scale)
			end

			self.heroArr[index]:SetActive(true)
			self.heroArr[index]:setInfo(inInfo)
			self.heroArr[index]:setNoClick(true)
		end

		for i = 1, 3 do
			if xyd.arrayIndexOf(hasArr, i) <= 0 and self.heroArr[i] then
				self.heroArr[i]:SetActive(false)
			end
		end
	else
		for i in pairs(self.heroArr) do
			if self.heroArr[i] then
				self.heroArr[i]:SetActive(false)
			end
		end
	end
end

return ActivitySpfarmBuildUpWindow
