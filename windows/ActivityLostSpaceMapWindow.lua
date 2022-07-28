local ActivityLostSpaceMapWindow = class("ActivityLostSpaceMapWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local MapGridItem = class("MapGridItem", import("app.components.CopyComponent"))
local json = require("cjson")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local rewardItem = class("rewardItem", require("app.components.CopyComponent"))
local PLACE_STATE = {
	EMPTY = 0,
	COMMON = 2,
	AWARD = 3,
	GREY = 1,
	EVENT = 4
}
local DOOR_POS = 360

function ActivityLostSpaceMapWindow:ctor(name, params)
	ActivityLostSpaceMapWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LOST_SPACE)
end

function ActivityLostSpaceMapWindow:initWindow()
	self:getUIComponent()
	ActivityLostSpaceMapWindow.super.initWindow(self)
	self:waitForFrame(10, function ()
		self.oldAutoPanelDepth = self.autoPanelUIPanel.depth
	end)
	self:reSize()
	self:registerEvent()
	self:layout()
end

function ActivityLostSpaceMapWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.Bg_ = self.groupAction:ComponentByName("Bg_", typeof(UITexture))
	self.centerCon = self.groupAction:NodeByName("centerCon").gameObject
	self.cardItem = self.centerCon:NodeByName("cardItem").gameObject
	self.cardCon = self.centerCon:NodeByName("cardCon").gameObject
	self.cardConUIGrid = self.centerCon:ComponentByName("cardCon", typeof(UIGrid))
	self.cardItem_awardCon = self.centerCon:NodeByName("cardItem_awardCon").gameObject
	self.cardItem_tipsCon = self.centerCon:NodeByName("cardItem_tipsCon").gameObject
	self.cardItem_lastCon = self.centerCon:NodeByName("cardItem_lastCon").gameObject
	self.cardItem_openCon = self.centerCon:NodeByName("cardItem_openCon").gameObject
	self.cardItem_skillCon = self.centerCon:NodeByName("cardItem_skillCon").gameObject
	self.personConPanel = self.groupAction:NodeByName("personConPanel").gameObject
	self.personCon = self.personConPanel:NodeByName("personCon").gameObject
	self.downCon = self.groupAction:NodeByName("downCon").gameObject
	self.doubleCon = self.downCon:NodeByName("doubleCon").gameObject
	self.doubleIcon = self.doubleCon:ComponentByName("doubleIcon", typeof(UISprite))
	self.doubleNumLabel = self.doubleCon:ComponentByName("doubleNumLabel", typeof(UILabel))
	self.treasurePartCon = self.downCon:NodeByName("treasurePartCon").gameObject
	self.treasurePartIcon = self.treasurePartCon:ComponentByName("treasurePartIcon", typeof(UISprite))
	self.treasurePartLabel = self.treasurePartCon:ComponentByName("treasurePartLabel", typeof(UILabel))
	self.autoGetAwardBtn = self.downCon:NodeByName("autoGetAwardBtn").gameObject
	self.autoGetAwardBtnLabel = self.autoGetAwardBtn:ComponentByName("autoGetAwardBtnLabel", typeof(UILabel))
	self.autoPanel = self.downCon:NodeByName("autoPanel").gameObject
	self.autoPanelUIPanel = self.autoPanel:GetComponent(typeof(UIPanel))
	self.autoBtn = self.autoPanel:NodeByName("autoBtn").gameObject
	self.autoBtnLabel = self.autoBtn:ComponentByName("autoBtnLabel", typeof(UILabel))
	self.autoEventBtn = self.autoPanel:NodeByName("autoEventBtn").gameObject
	self.autoEventBtnLabel = self.autoEventBtn:ComponentByName("autoEventBtnLabel", typeof(UILabel))
	self.autoEventBtnLabel2 = self.autoEventBtn:ComponentByName("autoEventBtnLabel2", typeof(UILabel))
	self.skillCon = self.downCon:NodeByName("skillCon").gameObject
	self.skillBtn = self.skillCon:NodeByName("skillBtn").gameObject
	self.skillBtnUISprite = self.skillCon:ComponentByName("skillBtn", typeof(UISprite))
	self.skillBtnLabel = self.skillBtn:ComponentByName("skillBtnLabel", typeof(UILabel))
	self.skillChangeBtn = self.skillCon:NodeByName("skillChangeBtn").gameObject
	self.skillBtnEffecCon = self.skillBtn:NodeByName("skillBtnEffecCon").gameObject
	self.skillBtnEffecTexture = self.skillBtnEffecCon:NodeByName("skillBtnEffecTexture").gameObject
	self.sweepBtn = self.downCon:NodeByName("sweepBtn").gameObject
	self.sweepLabel = self.sweepBtn:ComponentByName("sweepLabel", typeof(UILabel))
	self.xianCon = self.groupAction:NodeByName("xianCon").gameObject
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.tipsBtn = self.upCon:NodeByName("tipsBtn").gameObject
	self.finalAwardBtn = self.upCon:NodeByName("finalAwardBtn").gameObject
	self.scrollerCon = self.upCon:NodeByName("scrollerCon").gameObject
	self.awardScrollerBg = self.scrollerCon:ComponentByName("awardScrollerBg", typeof(UISprite))
	self.awardScroller = self.scrollerCon:NodeByName("awardScroller").gameObject
	self.awardScrollerUIScrollView = self.scrollerCon:ComponentByName("awardScroller", typeof(UIScrollView))
	self.itemGroupAll = self.awardScroller:NodeByName("itemGroupAll").gameObject
	self.itemGroupAllUIWrapContent = self.awardScroller:ComponentByName("itemGroupAll", typeof(UIWrapContent))
	self.drag = self.scrollerCon:NodeByName("drag").gameObject
	self.scrollerItem = self.scrollerCon:NodeByName("scrollerItem").gameObject
	self.wrapContent = FixedWrapContent.new(self.awardScrollerUIScrollView, self.itemGroupAllUIWrapContent, self.scrollerItem, rewardItem, self)
	self.leftArrow = self.scrollerCon:NodeByName("leftArrow").gameObject
	self.rightArrow = self.scrollerCon:NodeByName("rightArrow").gameObject
	self.newAwardBtn = self.upCon:NodeByName("newAwardBtn").gameObject
	self.newAwardBtnUISprite = self.upCon:ComponentByName("newAwardBtn", typeof(UISprite))
	self.newAwardBtnLabel = self.newAwardBtn:ComponentByName("newAwardBtnLabel", typeof(UILabel))
	self.newAwardBtnUpIcon = self.newAwardBtn:NodeByName("newAwardBtnUpIcon").gameObject
	self.skillAllMask = self.groupAction:NodeByName("skillAllMask").gameObject
end

function ActivityLostSpaceMapWindow:reSize()
	self:resizePosY(self.upCon, 484, 544)
	self:resizePosY(self.downCon, -566, -596)
	self:resizePosY(self.xianCon, -635, -673)
end

function ActivityLostSpaceMapWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGridEventBack))

	UIEventListener.Get(self.autoGetAwardBtn.gameObject).onClick = handler(self, function ()
		local ids = {}

		for i in pairs(self.gridArr) do
			if self.gridArr[i]:getState() == PLACE_STATE.AWARD then
				table.insert(ids, self.gridArr[i]:getGridId())
			end
		end

		if #ids < 1 then
			xyd.alertTips(__("ACTIVITY_LOST_SPACE_AUTO_GET_NO"))

			return
		end

		self:setOnTouchGetAwardType(xyd.ActivityLostSpaceTouchType.AUTO_GET_ALL)

		if self.activityData:getIsTreasure() then
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LOST_SPACE, json.encode({
				type = xyd.ActivityLostSpaceType.TREASURE_GET_AWARD,
				ids = ids
			}))
		else
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LOST_SPACE, json.encode({
				type = xyd.ActivityLostSpaceType.GET_AWARD,
				ids = ids
			}))
		end
	end)
	UIEventListener.Get(self.finalAwardBtn.gameObject).onClick = handler(self, function ()
		local awardsArr = {}

		for i = 1, 29 do
			local awards = xyd.tables.activityLostSpaceAwardsTable:getAward(i)
			local param = {
				isShowMark = false,
				itemId = awards[1],
				itemNum = awards[2],
				turn = i,
				text = __("ACTIVITY_LOST_SPACE_AWARD_NUM", tostring(i))
			}

			if self.activityData.detail.stage_id == i then
				param.isShowMark = true
			end

			table.insert(awardsArr, param)
		end

		local awards = xyd.tables.activityLostSpaceAwardsTable:getAward(30)
		local allLength = #xyd.tables.activityLostSpaceAwardsTable:getIDs()
		local param = {
			isShowMark = false,
			itemId = awards[1],
			itemNum = awards[2],
			turn = allLength,
			text = __("ACTIVITY_LOST_SPACE_AWARD_NUM", "30 - " .. allLength)
		}

		if self.activityData.detail.stage_id >= 30 and self.activityData.detail.stage_id <= allLength then
			param.isShowMark = true
		end

		table.insert(awardsArr, param)
		xyd.WindowManager.get():openWindow("anniversary_cake_award_window", {
			currentRound = self.activityData.detail.stage_id,
			awardList = awardsArr,
			titleText = __("ACTIVITY_LOST_SPACE_AWARD_TITLE")
		})
	end)

	local function checkScrollerCurId()
		local id = -1
		local minDis = -1
		local centerPosition = self.awardScrollerBg.gameObject.transform.position.x

		for i, item in pairs(self.wrapContent:getItems()) do
			local x = item:getGameObject().transform.position.x
			local dis = x - centerPosition

			if dis < 0 then
				dis = dis * -1
			end

			if minDis == -1 then
				minDis = dis
				id = item:getId()
			elseif dis < minDis then
				minDis = dis
				id = item:getId()
			end
		end

		return id
	end

	UIEventListener.Get(self.leftArrow.gameObject).onClick = handler(self, function ()
		self:updateUpAwardScroller(checkScrollerCurId() - 3)
	end)
	UIEventListener.Get(self.rightArrow.gameObject).onClick = handler(self, function ()
		self:updateUpAwardScroller(checkScrollerCurId() + 3)
	end)
	UIEventListener.Get(self.tipsBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_lost_space_event_window", {})
	end)
	UIEventListener.Get(self.doubleCon.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_lost_space_event_window", {})
	end)
	UIEventListener.Get(self.treasurePartCon.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_lost_space_event_window", {})
	end)
	UIEventListener.Get(self.skillChangeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_lost_space_skill_window", {})
	end)

	UIEventListener.Get(self.skillBtn.gameObject).onClick = function ()
		local skillId = self.activityData:getChooseSkill()
		local skillEnergyId = xyd.tables.miscTable:split2num("activity_lost_space_energy_get", "value", "#")[1]
		local hasNum = xyd.models.backpack:getItemNumByID(skillEnergyId)
		local maxNum = self:getSkillEnergy(skillId)

		if hasNum < maxNum then
			xyd.alertTips(__("ACTIVITY_LOST_SPACE_SKILL_ENERGY_NO"))
		else
			local canOpenIds = self:getSkillIds(skillId)

			if #canOpenIds == 0 then
				xyd.alertTips(__("ACTIVITY_LOST_SPACE_SKILL_NO_USE"))
			else
				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LOST_SPACE, json.encode({
					type = xyd.ActivityLostSpaceType.USE_SKILL
				}))
			end
		end
	end

	UIEventListener.Get(self.skillBtn.gameObject).onLongPress = function ()
		xyd.WindowManager.get():openWindow("activity_lost_space_skill_window", {})
	end

	UIEventListener.Get(self.autoBtn.gameObject).onClick = handler(self, function ()
		self:setIsAuto(not self.isAuto)
		self:updateAutoBtnShow()
		self:testClick()
	end)
	UIEventListener.Get(self.sweepBtn.gameObject).onClick = handler(self, function ()
		local needItemInfo = xyd.tables.miscTable:split2num("activity_lost_space_item_cost", "value", "#")
		local energy = xyd.models.backpack:getItemNumByID(needItemInfo[1])

		if energy < 5 then
			xyd.alertTips(__("ACTIVITY_LOST_SPACE_TEXT12"))

			return
		end

		if self.activityData:getIsTreasure() then
			xyd.alertTips(__("ACTIVITY_LOST_SPACE_TEXT16"))

			return
		end

		local map_info = self.activityData:getContentArr()

		for key, content in pairs(map_info) do
			if type(content) == "string" and #content > 0 then
				local events = xyd.split(content, "#")

				if events[1] == "e" then
					local eventId = tonumber(events[2])

					if eventId == xyd.ActivityLostSpaceEventType.EXIT and self.gridArr[key]:getState() == PLACE_STATE.EVENT then
						xyd.alertTips(__("ACTIVITY_LOST_SPACE_TEXT16"))

						return
					end
				end
			end
		end

		local timeStamp = xyd.db.misc:getValue("activity_lost_space_sweep_time_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "activity_lost_space_sweep",
				callback = function ()
					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LOST_SPACE, json.encode({
						type = xyd.ActivityLostSpaceType.SWEEP
					}))
				end,
				closeCallback = function ()
				end,
				text = __("ACTIVITY_LOST_SPACE_TEXT17")
			})

			return
		else
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LOST_SPACE, json.encode({
				type = xyd.ActivityLostSpaceType.SWEEP
			}))
		end
	end)
	UIEventListener.Get(self.autoEventBtn.gameObject).onClick = handler(self, function ()
		self.isAutoClickDoor = not self.isAutoClickDoor

		self:updateAutoClickDoorShow()
	end)
	UIEventListener.Get(self.newAwardBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_lost_space_award_new_window", {
			activityID = xyd.ActivityID.ACTIVITY_LOST_SPACE
		})
	end)
end

function ActivityLostSpaceMapWindow:getSkillEnergy(skillId)
	local skillLvs = self.activityData.detail.lvs
	local energyNum = xyd.tables.activityLostSpaceSkillTable:getEnergy(skillId)

	if skillLvs and #skillLvs > 0 then
		local isCanUp = xyd.tables.activityLostSpaceSkillTable:getCanLevelUp(skillId)

		if isCanUp and isCanUp == 1 then
			energyNum = energyNum - skillLvs[skillId] * xyd.tables.activityLostSpaceSkillTable:getLevelUpCost(skillId)
		end
	end

	return energyNum
end

function ActivityLostSpaceMapWindow:updateAutoBtnShow()
	if self.isAuto then
		self.autoBtnLabel.text = "is Auto"
	else
		self.autoBtnLabel.text = "not Auto"
	end
end

function ActivityLostSpaceMapWindow:updateAutoClickDoorShow()
	if self.isAutoClickDoor then
		self.autoEventBtnLabel2.text = "√"
	else
		self.autoEventBtnLabel2.text = "X"
	end
end

function ActivityLostSpaceMapWindow:testClick()
	if not self.isAuto then
		return
	end

	for i in pairs(self.gridArr) do
		if self.isAutoClickDoor and self.gridArr[i]:getState() == PLACE_STATE.EVENT then
			local content = self.activityData:getContentArr()[self.gridArr[i]:getGridId()]

			if type(content) == "string" and #content > 0 then
				local events = xyd.split(content, "#")

				if events[1] == "e" then
					local eventId = tonumber(events[2])

					if eventId == xyd.ActivityLostSpaceEventType.EXIT then
						self:waitForTime(0, function ()
							self.gridArr[i]:onTouch()
						end)

						return
					end
				end
			end
		elseif self.gridArr[i]:getState() == PLACE_STATE.COMMON then
			self:waitForTime(0, function ()
				self.gridArr[i]:onTouch()
			end)

			return
		end
	end

	self:setIsAuto(not self.isAuto)
	self:updateAutoBtnShow()
end

function ActivityLostSpaceMapWindow:layout()
	self.autoGetAwardBtnLabel.text = __("ACTIVITY_LOST_SPACE_AUTO_GET")
	self.sweepLabel.text = __("ACTIVITY_LOST_SPACE_TEXT11")

	self:setOnTouchGetAwardType(xyd.ActivityLostSpaceTouchType.DEFAULT)

	self.gridPosArr = {}
	self.isAuto = false
	self.isAutoClickDoor = false

	self:updateAutoBtnShow()
	self:updateAutoClickDoorShow()

	local checkData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LOST_SPACE_GIFTBAG)
	local isCheckBuy = nil

	if checkData then
		isCheckBuy = checkData:checkBuy()
	end

	if isCheckBuy then
		xyd.setUISpriteAsync(self.newAwardBtnUISprite, nil, "activity_lost_space_icon_djb2x90")

		self.newAwardBtnLabel.text = __("ACTIVITY_LOST_SPACE_TEXT08")

		self.newAwardBtnUpIcon.gameObject:SetActive(false)
	else
		xyd.setUISpriteAsync(self.newAwardBtnUISprite, nil, "activity_lost_space_icon_djbx90_2")

		self.newAwardBtnLabel.text = __("ACTIVITY_LOST_SPACE_TEXT09")

		self.newAwardBtnUpIcon.gameObject:SetActive(true)
	end

	xyd.setUITextureByNameAsync(self.Bg_, "activity_lost_space_bg_banner")
	self:initTop()

	for i = 1, 66 do
		table.insert(self.gridPosArr, i)
	end

	self.gridArr = {}

	if self.activityData.detail.stage_id > #xyd.tables.activityLostSpaceAwardsTable:getIDs() then
		xyd.alertConfirm(__("ACTIVITY_LOST_SPACE_SKILL_PASS_TIPS"))
	end

	self.personDress = import("app.components.SenpaiModel").new(self.personCon)

	self.personDress:setModelInfo({
		isNewClipShader = true,
		ids = xyd.models.dress:getEffectEquipedStyles()
	})
	self:initUpAwardScroller()
	self:updateDoubleLabel()
	self:updateTreasurePartLabel()
	self:updateSkillShow()

	local res = xyd.getEffectFilesByNames({
		"fx_lost_space_skill",
		"fx_lost_space_disappear",
		"fx_lost_space_camera"
	})
	local path1 = xyd.getSpritePath("activity_lost_space_gz_ktc")

	table.insert(res, path1)

	local allHasRes = xyd.isAllPathLoad(res)

	local function firstInitFun()
		for i in pairs(self.gridPosArr) do
			local tmp = NGUITools.AddChild(self.cardCon.gameObject, self.cardItem.gameObject)
			local item = MapGridItem.new(tmp, self.gridPosArr[i], self)
			self.gridArr[self.gridPosArr[i]] = item
		end

		self.cardConUIGrid:Reposition()
		self:updateGridState()
	end

	if allHasRes then
		firstInitFun()

		return
	else
		ResCache.DownloadAssets("activity_firework", res, function (success)
			xyd.WindowManager.get():closeWindow("res_loading_window")

			if tolua.isnull(self.window_) then
				return
			end

			firstInitFun()
		end, function (progress)
			local loading_win = xyd.WindowManager.get():getWindow("res_loading_window")

			if progress >= 1 and not loading_win then
				return
			end

			if not loading_win then
				xyd.WindowManager.get():openWindow("res_loading_window", {})
			end

			loading_win = xyd.WindowManager.get():getWindow("res_loading_window")

			loading_win:setLoadWndName("activity_lost_space_map_load_wd")
			loading_win:setLoadProgress("activity_lost_space_map_load_wd", progress)
		end, 1)
	end
end

function ActivityLostSpaceMapWindow:initTop()
	self.windowTop = WindowTop.new(self.window_, self.name_, 950)
	local items = {
		{
			id = xyd.ItemID.ACTIVITY_LOST_SPACE_MOVE_ENERGY
		},
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	self.windowTop:setItem(items)

	local resItems = self.windowTop:getResItems()
	local changeItem = resItems[1]
	local plusBtn = changeItem:getPlusBtn()
	local plusBtnBoxCollider = plusBtn.gameObject:AddComponent(typeof(UnityEngine.BoxCollider))
	plusBtnBoxCollider.size = Vector3(60, 60, 0)
	UIEventListener.Get(plusBtn.gameObject).onClick = handler(self, function ()
		local maxNumBeen = self.activityData.detail.buy_times
		maxNumBeen = maxNumBeen or 0
		local maxNumCanBuy = xyd.tables.miscTable:getNumber("activity_lost_space_buy_limit", "value") - maxNumBeen

		if maxNumCanBuy <= 0 then
			maxNumCanBuy = 0
		end

		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.ACTIVITY_LOST_SPACE_MOVE_ENERGY,
			activityData = self.activityData,
			openDepthTypeWindowCallBack = function (typeInfo)
				if typeInfo.layerType == xyd.UILayerType.FULL_SCREEN_UI then
					self:close()
				end
			end,
			openItemBuyWnd = function ()
				xyd.WindowManager.get():openWindow("item_buy_window", {
					hide_min_max = false,
					item_no_click = false,
					cost = xyd.tables.miscTable:split2Cost("activity_lost_space_buy_cost", "value", "#"),
					max_num = xyd.checkCondition(maxNumCanBuy == 0, 1, maxNumCanBuy),
					itemParams = {
						num = 1,
						itemID = xyd.ItemID.ACTIVITY_LOST_SPACE_MOVE_ENERGY
					},
					buyCallback = function (num)
						if maxNumCanBuy <= 0 then
							xyd.showToast(__("FULL_BUY_SLOT_TIME"))

							xyd.WindowManager.get():getWindow("item_buy_window").skipClose = true

							return
						end

						xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LOST_SPACE, json.encode({
							type = xyd.ActivityLostSpaceType.BUY_MOVE_ENERGY,
							num = num
						}))
					end,
					limitText = __("BUY_GIFTBAG_LIMIT", tostring(self.activityData.detail.buy_times) .. "/" .. tostring(xyd.tables.miscTable:getNumber("activity_lost_space_buy_limit", "value")))
				})
			end
		})
	end)
end

function ActivityLostSpaceMapWindow:updateSkillShow()
	local skillId = self.activityData:getChooseSkill()

	if skillId == 0 then
		xyd.WindowManager.get():openWindow("activity_lost_space_skill_window", {})
		xyd.setUISpriteAsync(self.skillBtnUISprite, nil, xyd.tables.activityLostSpaceSkillTable:getIcon(1))

		self.skillBtnLabel.text = "-/-"
	else
		xyd.setUISpriteAsync(self.skillBtnUISprite, nil, xyd.tables.activityLostSpaceSkillTable:getIcon(skillId))

		local skillEnergyId = xyd.tables.miscTable:split2num("activity_lost_space_energy_get", "value", "#")[1]
		local hasNum = xyd.models.backpack:getItemNumByID(skillEnergyId)
		local maxNum = self:getSkillEnergy(skillId)

		if maxNum <= hasNum then
			hasNum = maxNum

			self.skillBtnEffecCon.gameObject:SetActive(true)

			if not self.skillBtnEffect then
				self.skillBtnEffect = xyd.Spine.new(self.skillBtnEffecTexture.gameObject)

				self.skillBtnEffect:setInfo("fx_lost_space_camera", function ()
					self.skillBtnEffect:play("texiao02", 0)
				end)
			end
		else
			self.skillBtnEffecCon.gameObject:SetActive(false)
		end

		self.skillBtnLabel.text = hasNum .. "/" .. maxNum
	end
end

function ActivityLostSpaceMapWindow:getIsSkillEnergyFull()
	local skillId = self.activityData:getChooseSkill()
	local skillEnergyId = xyd.tables.miscTable:split2num("activity_lost_space_energy_get", "value", "#")[1]
	local hasNum = xyd.models.backpack:getItemNumByID(skillEnergyId)
	local maxNum = self:getSkillEnergy(skillId)

	if maxNum <= hasNum then
		return true
	end

	return false
end

function ActivityLostSpaceMapWindow:updateGridState(isNextStage)
	local waitTime = 0

	if isNextStage then
		self:updateUpAwardScroller()

		local showMaskArr = {
			xyd.ActivityLostSpaceMaskType.GET_FINIAL_AWARD
		}
		local isHasTreasure = xyd.tables.activityLostSpaceAwardsTable:getIfTreasure(self.activityData.detail.stage_id)

		if isHasTreasure and isHasTreasure == 1 then
			self:showMask(showMaskArr, xyd.ActivityLostSpaceMaskType.TREASURE_PART_SHOW_ENTER)
		else
			self:showMask(showMaskArr)
		end

		waitTime = 0.2
	end

	local function updateFun()
		for i in pairs(self.gridArr) do
			if self.gridArr[i]:getGridId() == DOOR_POS then
				self.gridArr[i]:updateState(PLACE_STATE.EMPTY)
			else
				self:updateOneGrid(self.gridArr[i]:getGridId())
			end
		end

		self:openUnLockGrid()
	end

	if self.isAuto then
		updateFun()
	else
		self:waitForTime(waitTime, function ()
			updateFun()
		end)
	end
end

function ActivityLostSpaceMapWindow:updateSkillBack(ids)
	if #ids == 0 then
		return
	end

	self.skillAllMask.gameObject:SetActive(true)

	self.skillEffectNum = 0
	self.skillEffectMax = #ids

	xyd.SoundManager:get():playSound(xyd.SoundID.ACTIVITY_LOST_SPACE_SOUND_USE_SKILL, nil, 2)

	self.showMasktypes = {}

	for i, id in pairs(ids) do
		local content = self.activityData:getContentArr()[id]

		if type(content) == "string" and #content > 0 then
			local events = xyd.split(content, "#")

			if events[1] == "e" then
				local eventId = tonumber(events[2])

				if eventId == xyd.ActivityLostSpaceEventType.EXIT then
					table.insert(self.showMasktypes, xyd.ActivityLostSpaceMaskType.EXIT_SHOW)
				elseif eventId == xyd.ActivityLostSpaceEventType.TREASURE_PART then
					table.insert(self.showMasktypes, xyd.ActivityLostSpaceMaskType.TREASURE_PART_SHOW)
				end
			end
		end
	end

	for i in pairs(self.gridArr) do
		if xyd.arrayIndexOf(ids, self.gridArr[i]:getGridId()) > 0 then
			self.gridArr[i]:setskillConVisible(true)
		end
	end
end

function ActivityLostSpaceMapWindow:setSkillCompleteNum(id)
	self.skillEffectNum = self.skillEffectNum + 1

	self:updateOneGrid(id)

	if self.skillEffectMax <= self.skillEffectNum then
		self:openUnLockGrid()
		self.skillAllMask.gameObject:SetActive(false)

		if #self.showMasktypes > 0 then
			self:showMask(xyd.cloneTable(self.showMasktypes))

			self.showMasktypes = {}
		end
	end
end

function ActivityLostSpaceMapWindow:openUnLockGrid()
	for i in pairs(self.gridArr) do
		if self.gridArr[i]:getState() ~= PLACE_STATE.GREY and self.gridArr[i]:getState() ~= PLACE_STATE.COMMON then
			local borderArr = self:getBorderIds(self.gridArr[i]:getGridId())

			for k, resetInfo in pairs(borderArr) do
				if self.gridArr[resetInfo.id]:getState() == PLACE_STATE.GREY and resetInfo.state == "four" then
					self.gridArr[resetInfo.id]:updateState(PLACE_STATE.COMMON)
				end
			end
		end
	end
end

function ActivityLostSpaceMapWindow:getBorderIds(id)
	local borderArr = {}
	local left_index = id - 1
	local right_index = id + 1
	local up_index = id - 6
	local down_index = id + 6
	local left_up = id - 7
	local left_down = id + 5
	local right_up = id - 5
	local right_down = id + 7

	if id % 6 == 1 then
		left_index = -1
		left_up = -1
		left_down = -1
	end

	if left_index ~= -1 then
		table.insert(borderArr, {
			state = "four",
			id = left_index
		})
	end

	if id % 6 == 0 then
		right_index = -1
		right_up = -1
		right_down = -1
	end

	if right_index ~= -1 then
		table.insert(borderArr, {
			state = "four",
			id = right_index
		})
	end

	if id >= 61 then
		down_index = -1
		left_down = -1
		right_down = -1
	end

	if down_index ~= -1 then
		table.insert(borderArr, {
			state = "four",
			id = down_index
		})
	end

	if id <= 6 then
		up_index = -1
		left_up = -1
		right_up = -1
	end

	if up_index ~= -1 then
		table.insert(borderArr, {
			state = "four",
			id = up_index
		})
	end

	return borderArr
end

function ActivityLostSpaceMapWindow:getSkillIds(skillId)
	local ids = {}
	local lastId = self.activityData.detail.last_id
	local rowNum = math.ceil(lastId / 6)
	local colNum = lastId % 6

	if skillId == xyd.ActivityLostSpaceSkillId.ONE then
		for i in pairs(self.gridArr) do
			if self.activityData:getMapArr()[self.gridArr[i]:getGridId()] == xyd.ActivityLostSpaceGridState.NO_OPEN or self.activityData:getMapArr()[self.gridArr[i]:getGridId()] == xyd.ActivityLostSpaceGridState.KNOW_POS then
				local checkRowNum = math.ceil(self.gridArr[i]:getGridId() / 6)

				if checkRowNum == rowNum then
					table.insert(ids, self.gridArr[i]:getGridId())
				end
			end
		end
	elseif skillId == xyd.ActivityLostSpaceSkillId.TWO then
		for i in pairs(self.gridArr) do
			if self.activityData:getMapArr()[self.gridArr[i]:getGridId()] == xyd.ActivityLostSpaceGridState.NO_OPEN or self.activityData:getMapArr()[self.gridArr[i]:getGridId()] == xyd.ActivityLostSpaceGridState.KNOW_POS then
				local checkId = self.gridArr[i]:getGridId()
				local checkRowNum = math.ceil(checkId / 6)
				local checkColNum = checkId % 6

				if checkRowNum == rowNum and (checkId == lastId - 2 or checkId == lastId - 1 or checkId == lastId + 1 or checkId == lastId + 2) then
					table.insert(ids, checkId)
				end

				if checkColNum == colNum and (checkId == lastId - 12 or checkId == lastId - 6 or checkId == lastId + 6 or checkId == lastId + 12) then
					table.insert(ids, checkId)
				end
			end
		end
	elseif skillId == xyd.ActivityLostSpaceSkillId.THREE then
		for i in pairs(self.gridArr) do
			if self.activityData:getMapArr()[self.gridArr[i]:getGridId()] == xyd.ActivityLostSpaceGridState.NO_OPEN or self.activityData:getMapArr()[self.gridArr[i]:getGridId()] == xyd.ActivityLostSpaceGridState.KNOW_POS then
				local checkId = self.gridArr[i]:getGridId()
				local checkRowNum = math.ceil(checkId / 6)
				local checkColNum = checkId % 6

				if checkColNum == colNum and (checkId == lastId - 18 or checkId == lastId - 12 or checkId == lastId - 6 or checkId == lastId + 6 or checkId == lastId + 12 or checkId == lastId + 18) then
					table.insert(ids, checkId)
				end
			end
		end
	elseif skillId == xyd.ActivityLostSpaceSkillId.FOUR then
		if colNum == 0 then
			colNum = 6
		end

		for i in pairs(self.gridArr) do
			if self.activityData:getMapArr()[self.gridArr[i]:getGridId()] == xyd.ActivityLostSpaceGridState.NO_OPEN or self.activityData:getMapArr()[self.gridArr[i]:getGridId()] == xyd.ActivityLostSpaceGridState.KNOW_POS then
				local checkId = self.gridArr[i]:getGridId()
				local checkRowNum = math.ceil(checkId / 6)
				local checkColNum = checkId % 6

				if checkColNum == 0 then
					checkColNum = 6
				end

				if (checkColNum == colNum or checkColNum - 1 == colNum or checkColNum + 1 == colNum) and (checkId == lastId - 7 or checkId == lastId - 6 or checkId == lastId - 5 or checkId == lastId - 1 or checkId == lastId + 1 or checkId == lastId + 5 or checkId == lastId + 6 or checkId == lastId + 7) then
					table.insert(ids, checkId)
				end
			end
		end
	elseif skillId == xyd.ActivityLostSpaceSkillId.FIVE then
		for i in pairs(self.gridArr) do
			if self.activityData:getMapArr()[self.gridArr[i]:getGridId()] == xyd.ActivityLostSpaceGridState.NO_OPEN or self.activityData:getMapArr()[self.gridArr[i]:getGridId()] == xyd.ActivityLostSpaceGridState.KNOW_POS then
				local checkId = self.gridArr[i]:getGridId()

				table.insert(ids, checkId)

				break
			end
		end
	elseif skillId == xyd.ActivityLostSpaceSkillId.SIX then
		local lv = self.activityData:getLevel(skillId)

		for i in pairs(self.gridArr) do
			if self.activityData:getMapArr()[self.gridArr[i]:getGridId()] == xyd.ActivityLostSpaceGridState.NO_OPEN or self.activityData:getMapArr()[self.gridArr[i]:getGridId()] == xyd.ActivityLostSpaceGridState.KNOW_POS then
				local checkId = self.gridArr[i]:getGridId()
				local checkRowNum = math.ceil(checkId / 6)
				local checkColNum = checkId % 6

				if checkColNum == colNum then
					if checkId == lastId - 6 or checkId == lastId + 6 then
						table.insert(ids, checkId)
					end

					if lv >= 1 and checkId == lastId - 12 then
						table.insert(ids, checkId)
					end

					if lv >= 2 and checkId == lastId + 12 then
						table.insert(ids, checkId)
					end

					if lv >= 3 and checkId == lastId - 18 then
						table.insert(ids, checkId)
					end

					if lv >= 4 and checkId == lastId + 18 then
						table.insert(ids, checkId)
					end
				end
			end
		end
	end

	return ids
end

function ActivityLostSpaceMapWindow:onGridEventBack(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_LOST_SPACE then
		return
	end

	local data = xyd.decodeProtoBuf(event.data)
	data.detail = json.decode(data.detail)

	if self.openBackUpdateBeforeId then
		for i in pairs(self.gridArr) do
			if self.gridArr[i]:getGridId() == self.openBackUpdateBeforeId then
				self.gridArr[i]:setLastConVisible(false)

				break
			end
		end
	end

	if data.detail.type == xyd.ActivityLostSpaceType.OPEN_GRID then
		self:updateOneGrid(data.detail.id)
		self:openUnLockGrid()
		self:updateSkillShow()

		local content = self.activityData:getContentArr()[data.detail.id]

		if type(content) == "string" and #content > 0 then
			local events = xyd.split(content, "#")

			if events[1] == "e" then
				local eventId = tonumber(events[2])

				if eventId == xyd.ActivityLostSpaceEventType.EXIT then
					self:showMask({
						xyd.ActivityLostSpaceMaskType.EXIT_SHOW
					})
				elseif eventId == xyd.ActivityLostSpaceEventType.TREASURE_ENTER then
					self:showMask({
						xyd.ActivityLostSpaceMaskType.TREASURE_SHOW
					})
				elseif eventId == xyd.ActivityLostSpaceEventType.TREASURE_PART then
					self:showMask({
						xyd.ActivityLostSpaceMaskType.TREASURE_PART_SHOW
					})
				end
			end
		end
	elseif data.detail.type == xyd.ActivityLostSpaceType.GET_AWARD or data.detail.type == xyd.ActivityLostSpaceType.TREASURE_GET_AWARD then
		for i, id in pairs(data.detail.ids) do
			self:updateOneGrid(id)
		end
	elseif data.detail.type == xyd.ActivityLostSpaceType.USE_EVENT or data.detail.type == xyd.ActivityLostSpaceType.TREASURE_USE_EVENT then
		local content = self.activityData:getContentArr()[data.detail.id]

		if type(content) == "string" and #content > 0 then
			local events = xyd.split(content, "#")

			if events[1] == "e" then
				local eventId = tonumber(events[2])

				if eventId == xyd.ActivityLostSpaceEventType.EXIT then
					-- Nothing
				else
					self:updateOneGrid(data.detail.id)

					if eventId == xyd.ActivityLostSpaceEventType.SEEK then
						self.gridArr[data.detail.extra.pos]:setTipsConVisible(true)
					elseif eventId == xyd.ActivityLostSpaceEventType.ENERGY_TWO or eventId == xyd.ActivityLostSpaceEventType.ENERGY_FOUR then
						self:updateSkillShow()
					elseif eventId == xyd.ActivityLostSpaceEventType.TREASURE_PART then
						self:updateTreasurePartLabel()
					end
				end
			end
		end
	elseif data.detail.type == xyd.ActivityLostSpaceType.CHOICE_SKILL then
		local activityLostSpaceSkillWd = xyd.WindowManager.get():getWindow("activity_lost_space_skill_window")

		if activityLostSpaceSkillWd then
			xyd.WindowManager.get():closeWindow("activity_lost_space_skill_window")
		end

		self:updateSkillShow()
	elseif data.detail.type == xyd.ActivityLostSpaceType.USE_SKILL then
		self:updateSkillShow()
	elseif data.detail.type == xyd.ActivityLostSpaceType.SWEEP then
		self:updateUpAwardScroller()
		self:updateDoubleLabel()
		self:updateTreasurePartLabel()
		self:updateSkillShow()
		self:updateGridState()

		local needItemInfo = xyd.tables.miscTable:split2num("activity_lost_space_item_cost", "value", "#")
		local data1 = {
			{
				349,
				data.detail.num * needItemInfo[2]
			}
		}
		local data2 = {}

		for item_id, item_num in pairs(data.detail.items) do
			table.insert(data2, {
				tonumber(item_id),
				tonumber(item_num)
			})
		end

		xyd.WindowManager.get():openWindow("common_activity_award_preview1_window", {
			specialCenterAndShowNum = true,
			groupTitleText1 = __("ACTIVITY_LOST_SPACE_TEXT14"),
			awardData1 = data1,
			groupTitleText2 = __("ACTIVITY_LOST_SPACE_TEXT15"),
			awardData2 = data2,
			winTitleText = __("ACTIVITY_LOST_SPACE_TEXT13")
		})
	end

	self:updateDoubleLabel()

	if self.isAuto then
		self:testClick()
	end
end

function ActivityLostSpaceMapWindow:autoUseTreasurePart(id)
	self:updateOneGrid(id)
	self:updateTreasurePartLabel()
	self:showMask({
		xyd.ActivityLostSpaceMaskType.TREASURE_SHOW
	})
end

function ActivityLostSpaceMapWindow:updateOneGrid(id)
	if self.activityData:getMapArr()[id] == xyd.ActivityLostSpaceGridState.NO_OPEN or self.activityData:getMapArr()[id] == xyd.ActivityLostSpaceGridState.KNOW_POS then
		self.gridArr[id]:updateState(PLACE_STATE.GREY)
	elseif self.activityData:getMapArr()[id] == xyd.ActivityLostSpaceGridState.CAN_GET then
		local content = self.activityData:getContentArr()[id]

		if type(content) == "number" then
			self.gridArr[id]:updateState(PLACE_STATE.AWARD)
		elseif type(content) == "string" and #content > 0 then
			local events = xyd.split(content, "#")

			if events[1] == "e" then
				self.gridArr[id]:updateState(PLACE_STATE.EVENT)
			end
		end
	elseif self.activityData:getMapArr()[id] == xyd.ActivityLostSpaceGridState.EMPTY then
		self.gridArr[id]:updateState(PLACE_STATE.EMPTY)
	end
end

function ActivityLostSpaceMapWindow:updateDoubleLabel()
	self.doubleNumLabel.text = self.activityData.detail.is_double

	if self.activityData.detail.is_double > 0 then
		xyd.applyChildrenOrigin(self.doubleIcon.gameObject)
	else
		xyd.applyChildrenGrey(self.doubleIcon.gameObject)
	end
end

function ActivityLostSpaceMapWindow:updateTreasurePartLabel()
	self.treasurePartLabel.text = tostring(self.activityData.detail.piece) .. "/" .. self.activityData:getAutoUseTreasurePartNum()

	if self.activityData.detail.piece > 0 then
		xyd.applyChildrenOrigin(self.treasurePartIcon.gameObject)
	else
		xyd.applyChildrenGrey(self.treasurePartIcon.gameObject)
	end
end

function ActivityLostSpaceMapWindow:getOnTouchGetAwardType()
	return self.onTouchGetAwardType
end

function ActivityLostSpaceMapWindow:setOnTouchGetAwardType(state)
	self.onTouchGetAwardType = state
end

function ActivityLostSpaceMapWindow:isNoOtherCommonAward(noSearchId)
	local isNoOther = true

	for i in pairs(self.gridArr) do
		if self.gridArr[i]:getGridId() ~= noSearchId and self.gridArr[i]:getState() == PLACE_STATE.AWARD then
			isNoOther = false

			break
		end
	end

	return isNoOther
end

function ActivityLostSpaceMapWindow:initUpAwardScroller()
	local ids = xyd.tables.activityLostSpaceAwardsTable:getIDs()
	self.scrollerAwardsArr = {}

	for i, id in pairs(ids) do
		table.insert(self.scrollerAwardsArr, {
			id = id
		})
	end

	self.wrapContent:setInfos(self.scrollerAwardsArr, {})
	self.awardScrollerUIScrollView:ResetPosition()
	self:waitForFrame(2, function ()
		self:updateUpAwardScroller()
	end)
end

function ActivityLostSpaceMapWindow:updateUpAwardScroller(id)
	local ids = xyd.tables.activityLostSpaceAwardsTable:getIDs()

	self.wrapContent:setInfos(self.scrollerAwardsArr, {
		keepPosition = true
	})

	local stage_id = self.activityData.detail.stage_id

	if id then
		stage_id = id
	end

	if stage_id > #ids - 2 then
		stage_id = #ids - 2
	end

	if stage_id < 3 then
		stage_id = 3
	end

	self.showAwardScrollerId = stage_id

	self:waitForFrame(2, function ()
		local sp = self.awardScrollerUIScrollView.gameObject:GetComponent(typeof(SpringPanel))
		sp = sp or self.awardScrollerUIScrollView.gameObject:AddComponent(typeof(SpringPanel))

		sp.Begin(sp.gameObject, Vector3(-1 * self:GetJumpToInfoDis(self.scrollerAwardsArr[stage_id]), 0, 0), 8)
	end)
end

function ActivityLostSpaceMapWindow:GetJumpToInfoDis(info)
	local currIndex = nil

	for index, info2 in ipairs(self.wrapContent:getInfos()) do
		if info2 == info then
			currIndex = index

			break
		end
	end

	if not currIndex then
		return
	end

	local panel = self.awardScrollerUIScrollView:GetComponent(typeof(UIPanel))
	local width = panel.baseClipRegion.z
	local itemSize = self.wrapContent:getWrapContent().itemSize
	local lastIndex = #self.wrapContent:getInfos()
	local allWidth = lastIndex * itemSize

	if width >= allWidth then
		return 0
	end

	local maxDeltaY = allWidth - width + 209 - 10
	local deltaY = (currIndex - 1) * itemSize + 209
	deltaY = math.min(deltaY, maxDeltaY)

	if currIndex < #xyd.tables.activityLostSpaceAwardsTable:getIDs() - 3 then
		deltaY = deltaY - 204
	end

	return deltaY
end

function ActivityLostSpaceMapWindow:showMask(types, anotherType)
	if not self.isAuto then
		xyd.WindowManager.get():openWindow("activity_lost_space_mask_window", {
			types = types,
			anotherType = anotherType
		})
	end
end

function ActivityLostSpaceMapWindow:setIsAuto(state)
	self.isAuto = state

	if self.isAuto then
		self.autoPanelUIPanel.depth = 9000
	else
		self.autoPanelUIPanel.depth = self.oldAutoPanelDepth
	end
end

function MapGridItem:ctor(goItem, gridId, parent)
	self.goItem_ = goItem
	self.parent = parent
	self.gridId = gridId

	MapGridItem.super.ctor(self, goItem)
end

function MapGridItem:initUI()
	self:getUIComponent()
	MapGridItem.super.initUI(self)

	UIEventListener.Get(self.cardItemBg.gameObject).onClick = handler(self, self.onTouch)
end

function MapGridItem:getUIComponent()
	local row = math.ceil(self.gridId / 6)
	self.depthNum = row * 50
	self.goUIWidget = self.go:GetComponent(typeof(UIWidget))
	self.goUIWidget.depth = self.depthNum
	self.cardItemBg = self.go:ComponentByName("cardItemBg", typeof(UISprite))
	self.cardItemBgBoxCollider = self.go:ComponentByName("cardItemBg", typeof(UnityEngine.BoxCollider))
	self.cardItemBg.depth = self.gridId
	self.cardItemUp = self.go:ComponentByName("cardItemUp", typeof(UISprite))
	self.cardItemUpUIWidget = self.go:ComponentByName("cardItemUp", typeof(UIWidget))
	self.cardItemUpUIWidget.depth = self.depthNum + 35
end

function MapGridItem:updateState(state)
	self.state = state

	self:setAwardConVisible(false)

	if self.awardImg then
		self.awardImg.gameObject:Y(0)
	end

	self.cardItemUp.gameObject:Y(12)

	if state == PLACE_STATE.EMPTY or state == PLACE_STATE.AWARD or state == PLACE_STATE.EVENT then
		self.cardItemBgBoxCollider.center = Vector3(0, 8, 0)

		self.cardItemUp.gameObject:SetActive(false)
		self:setAwardConVisible(false)
		self:setTipsConVisible(false)
		self:setLastConVisible(false)

		if not self.parent.activityData:getIsTreasure() and self.gridId == self.parent.activityData.detail.last_id then
			self:setLastConVisible(true)
		end

		if state == PLACE_STATE.EMPTY then
			xyd.setUISpriteAsync(self.cardItemBg, nil, "activity_lost_space_gz_pt")
		elseif state == PLACE_STATE.AWARD then
			xyd.setUISpriteAsync(self.cardItemBg, nil, "activity_lost_space_gz_hd")

			local awardIdData = self.parent.activityData:getContentArr()[self.gridId]
			local doubleNum = 1
			local awardId = awardIdData % 10000
			local awards = xyd.tables.activityLostSpaceBoxesTable:getAward(tonumber(awardId))

			self:setAwardConVisible(true, awardId, doubleNum)

			if awardIdData > 10000 and self.awardDoubleIcon then
				self.awardDoubleIcon.gameObject:SetActive(true)
			end

			xyd.setUISpriteAsync(self.awardImg, nil, "icon_" .. awards[1], function ()
				self.awardImg.gameObject:SetLocalScale(0.8, 0.8, 0.8)
			end, nil, true)

			self.awardNumLabel.text = xyd.getRoughDisplayNumber(awards[2] * doubleNum)
		elseif state == PLACE_STATE.EVENT then
			local content = self.parent.activityData:getContentArr()[self.gridId]

			if type(content) == "string" and #content > 0 then
				local events = xyd.split(content, "#")

				if events[1] == "e" then
					xyd.setUISpriteAsync(self.cardItemBg, nil, "activity_lost_space_gz_hd")
					self:setAwardConVisible(true)

					local eventId = tonumber(events[2])

					if eventId == xyd.ActivityLostSpaceEventType.DOUBLE then
						xyd.setUISpriteAsync(self.awardImg, nil, "activity_lost_space_gz_double", function ()
						end, nil, true)

						self.awardNumLabel.text = ""

						self.awardImg.gameObject:Y(9)
					elseif eventId == xyd.ActivityLostSpaceEventType.SEEK then
						xyd.setUISpriteAsync(self.awardImg, nil, "activity_lost_space_icon_xj", function ()
						end, nil, true)

						self.awardNumLabel.text = ""
					elseif eventId == xyd.ActivityLostSpaceEventType.ENERGY_TWO or eventId == xyd.ActivityLostSpaceEventType.ENERGY_FOUR then
						xyd.setUISpriteAsync(self.awardImg, nil, "activity_lost_space_icon_nl", function ()
						end, nil, true)

						self.awardNumLabel.text = tostring(xyd.tables.activityLostSpaceEventTable:getEnergyNum(tonumber(eventId)))
					elseif eventId == xyd.ActivityLostSpaceEventType.EXIT or eventId == xyd.ActivityLostSpaceEventType.TREASURE_ENTER or eventId == xyd.ActivityLostSpaceEventType.TREASURE_PART then
						self:updateStateSecondFloorGrid(state)
					end
				end
			end
		end
	else
		self:updateStateSecondFloorGrid(state)
	end
end

function MapGridItem:updateStateSecondFloorGrid(state)
	self.cardItemBgBoxCollider.center = Vector3(0, 13, 0)

	self.cardItemUp.gameObject:SetActive(true)
	self:setAwardConVisible(false)
	self:setTipsConVisible(false)
	self:setLastConVisible(false)

	if not self.parent.activityData:getIsTreasure() and self.gridId == self.parent.activityData.detail.last_id then
		self:setLastConVisible(true)
	end

	xyd.setUISpriteAsync(self.cardItemBg, nil, "activity_lost_space_gz_pt", nil, , true)

	if state == PLACE_STATE.GREY then
		self.cardItemUp.gameObject:Y(11)
		xyd.setUISpriteAsync(self.cardItemUp, nil, "activity_lost_space_gz_yc", nil, , true)

		if self.parent.activityData:getMapArr()[self.gridId] == xyd.ActivityLostSpaceGridState.KNOW_POS then
			self:setTipsConVisible(true)
		end
	elseif state == PLACE_STATE.COMMON then
		xyd.setUISpriteAsync(self.cardItemUp, nil, "activity_lost_space_gz_ktc", nil, , true)

		if self.parent.activityData:getMapArr()[self.gridId] == xyd.ActivityLostSpaceGridState.KNOW_POS then
			self:setTipsConVisible(true)
		end
	elseif state == PLACE_STATE.EVENT then
		local content = self.parent.activityData:getContentArr()[self.gridId]

		if type(content) == "string" and #content > 0 then
			local events = xyd.split(content, "#")

			if events[1] == "e" then
				local eventId = tonumber(events[2])

				if eventId == xyd.ActivityLostSpaceEventType.EXIT then
					xyd.setUISpriteAsync(self.cardItemUp, nil, "activity_lost_space_gz_xyg", nil, , true)
					xyd.setUISpriteAsync(self.cardItemBg, nil, "activity_lost_space_gz_dian", nil, , true)
					self.cardItemUp.gameObject:Y(19)
				elseif eventId == xyd.ActivityLostSpaceEventType.TREASURE_ENTER then
					xyd.setUISpriteAsync(self.cardItemUp, nil, "activity_lost_space_gz_bjd", nil, , true)
					xyd.setUISpriteAsync(self.cardItemBg, nil, "activity_lost_space_gz_dian", nil, , true)
					self.cardItemUp.gameObject:Y(19)
				elseif eventId == xyd.ActivityLostSpaceEventType.TREASURE_PART then
					xyd.setUISpriteAsync(self.cardItemUp, nil, "activity_lost_space_gz_bjzb", nil, , true)
					xyd.setUISpriteAsync(self.cardItemBg, nil, "activity_lost_space_gz_dian", nil, , true)
					self.cardItemUp.gameObject:Y(19)
				end
			end
		end
	end
end

function MapGridItem:getState()
	return self.state
end

function MapGridItem:getGridId()
	return self.gridId
end

function MapGridItem:onTouch()
	if self.parent.activityData and self.parent.activityData:getEndTime() <= xyd.getServerTime() then
		xyd.alertTips(__("ACTIVITY_END_YET"))

		if self.parent.isAuto then
			self.parent:setIsAuto(false)
		end

		return
	end

	if self.state == PLACE_STATE.COMMON then
		local needItemInfo = xyd.tables.miscTable:split2num("activity_lost_space_item_cost", "value", "#")
		local energy = xyd.models.backpack:getItemNumByID(needItemInfo[1])

		if needItemInfo[2] <= energy then
			local function openFun()
				if self.parent.activityData.detail.last_id then
					self.parent.openBackUpdateBeforeId = self.parent.activityData.detail.last_id
				end

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LOST_SPACE, json.encode({
					type = xyd.ActivityLostSpaceType.OPEN_GRID,
					id = self.gridId
				}))
				self:setOpenConVisible(true)
				xyd.SoundManager:get():playSound(xyd.SoundID.ACTIVITY_LOST_SPACE_SOUND_SEEK_GRID, nil, 2)
			end

			if self.parent:getIsSkillEnergyFull() then
				self:checkSkillEnergyFullTips(openFun)
			else
				openFun()
			end
		else
			xyd.alertTips(__("ACTIVITY_LOST_SPACE_MOVE_ENERGY_NO"))

			if self.parent.isAuto then
				self.parent:setIsAuto(false)
			end
		end
	elseif self.state == PLACE_STATE.AWARD then
		self.parent:setOnTouchGetAwardType(xyd.ActivityLostSpaceTouchType.GRID)

		if self.parent.activityData:getIsTreasure() then
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LOST_SPACE, json.encode({
				type = xyd.ActivityLostSpaceType.TREASURE_GET_AWARD,
				ids = {
					self.gridId
				}
			}))
		else
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LOST_SPACE, json.encode({
				type = xyd.ActivityLostSpaceType.GET_AWARD,
				ids = {
					self.gridId
				}
			}))
		end
	elseif self.state == PLACE_STATE.EVENT then
		local content = self.parent.activityData:getContentArr()[self.gridId]

		if type(content) == "string" and #content > 0 then
			local events = xyd.split(content, "#")

			if events[1] == "e" then
				local eventId = tonumber(events[2])

				if eventId == xyd.ActivityLostSpaceEventType.SEEK then
					if xyd.arrayIndexOf(self.parent.activityData:getMapArr(), 0) < 0 then
						xyd.alertTips(__("ACTIVITY_LOST_SPACE_NO_UNOPEN_GRID"))

						return
					end
				elseif eventId == xyd.ActivityLostSpaceEventType.EXIT then
					local function finialSend()
						if self.parent.activityData:getIsTreasure() then
							xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LOST_SPACE, json.encode({
								type = xyd.ActivityLostSpaceType.TREASURE_USE_EVENT,
								id = self.gridId
							}))
						else
							xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LOST_SPACE, json.encode({
								type = xyd.ActivityLostSpaceType.USE_EVENT,
								id = self.gridId
							}))
						end
					end

					local function sendFun()
						if self.parent.isAuto and self.parent.isAutoClickDoor then
							finialSend()

							return
						end

						local isHasTreasure = xyd.tables.activityLostSpaceAwardsTable:getIfTreasure(self.parent.activityData.detail.stage_id)
						local showTreasureTips = ""

						if not self.parent.activityData:getIsTreasure() and isHasTreasure and isHasTreasure == 1 then
							showTreasureTips = __("ACTIVITY_LOST_SPACE_SKILL_MASK_TREASURE_EXIT_TIPS1")

							for i, content in pairs(self.parent.activityData:getContentArr()) do
								if type(content) == "string" and #content > 0 then
									local events = xyd.split(content, "#")

									if events[1] == "e" then
										local eventId = tonumber(events[2])

										if eventId == xyd.ActivityLostSpaceEventType.TREASURE_ENTER then
											if self.parent.activityData:getMapArr()[i] == xyd.ActivityLostSpaceGridState.CAN_GET then
												showTreasureTips = __("ACTIVITY_LOST_SPACE_SKILL_MASK_TREASURE_EXIT_TIPS3")
											elseif self.parent.activityData:getMapArr()[i] == xyd.ActivityLostSpaceGridState.EMPTY then
												showTreasureTips = ""
											end
										elseif eventId == xyd.ActivityLostSpaceEventType.TREASURE_PART then
											if self.parent.activityData:getMapArr()[i] == xyd.ActivityLostSpaceGridState.CAN_GET then
												showTreasureTips = __("ACTIVITY_LOST_SPACE_SKILL_MASK_TREASURE_EXIT_TIPS2")
											elseif self.parent.activityData:getMapArr()[i] == xyd.ActivityLostSpaceGridState.EMPTY then
												showTreasureTips = ""
											end
										end
									end
								end
							end
						end

						if showTreasureTips ~= "" then
							xyd.alertYesNo(showTreasureTips, function (yes_no)
								if yes_no then
									finialSend()
								end
							end)
						else
							finialSend()
						end
					end

					if self.parent.isAuto and self.parent.isAutoClickDoor then
						sendFun()

						return
					end

					if self.parent:isNoOtherCommonAward(self.gridId) then
						local timeStamp = xyd.db.misc:getValue("actiivty_lost_space_exit_tips_time_stamp")

						if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
							xyd.openWindow("gamble_tips_window", {
								type = "actiivty_lost_space_exit_tips",
								wndType = self.curWindowType_,
								text = __("ACTIVITY_LOST_SPACE_EXIT_TIPS1"),
								callback = function ()
									sendFun()
								end
							})

							return
						else
							sendFun()

							return true
						end
					else
						xyd.alertConfirm(__("ACTIVITY_LOST_SPACE_EXIT_TIPS2"))
					end

					return
				end

				if self.parent.activityData:getIsTreasure() then
					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LOST_SPACE, json.encode({
						type = xyd.ActivityLostSpaceType.TREASURE_USE_EVENT,
						id = self.gridId
					}))
				else
					local function senFun()
						xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LOST_SPACE, json.encode({
							type = xyd.ActivityLostSpaceType.USE_EVENT,
							id = self.gridId
						}))
					end

					if eventId == xyd.ActivityLostSpaceEventType.ENERGY_TWO or eventId == xyd.ActivityLostSpaceEventType.ENERGY_FOUR then
						if self.parent:getIsSkillEnergyFull() then
							self:checkSkillEnergyFullTips(senFun)
						else
							senFun()
						end

						return
					end

					senFun()
				end
			end
		end
	elseif self.state == PLACE_STATE.GREY then
		xyd.alertTips(__("ACTIVITY_LOST_SPACE_SKILL_NO_CLICK"))
	end
end

function MapGridItem:checkSkillEnergyFullTips(callback)
	if not self.parent.isAuto then
		local timeStamp = xyd.db.misc:getValue("actiivty_lost_space_skill_energy_time_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			local param = {
				type = "actiivty_lost_space_skill_energy",
				isHideNoBtn = true,
				wndType = self.curWindowType_,
				text = __("ACTIVITY_LOST_SPACE_SKILL_ENERGY_TIPS"),
				callback = function ()
					callback()
				end
			}

			if xyd.Global.lang == "de_de" then
				param.tipsHeight = 90
				param.tipsTextY = 51
				param.groupChooseY = -21
			end

			xyd.openWindow("gamble_tips_window", param)
		else
			callback()
		end
	else
		callback()
	end
end

function MapGridItem:getAwardCon()
	if not self.awardCon then
		self.awardCon = NGUITools.AddChild(self.cardItemBg.gameObject, self.parent.cardItem_awardCon.gameObject)
		self.awardImg = self.awardCon:ComponentByName("awardImg", typeof(UISprite))
		self.awardDoubleIcon = self.awardCon:ComponentByName("awardDoubleIcon", typeof(UISprite))
		self.awardNumLabel = self.awardCon:ComponentByName("awardNumLabel", typeof(UILabel))
		self.awardItemCon = self.awardCon:NodeByName("awardItemCon").gameObject
		self.awardItemCon:GetComponent(typeof(UIWidget)).depth = self.depthNum + 2
		self.awardImg.depth = self.depthNum + 2
		self.awardDoubleIcon.depth = self.depthNum + 53
		self.awardNumLabel.depth = self.depthNum + 3

		self.awardCon.gameObject:Y(8)
		self.awardItemCon.gameObject:Y(3)
	end

	return self.awardCon
end

function MapGridItem:setAwardConVisible(visible, awardId, doubleNum)
	if visible and not self.awardCon then
		self:getAwardCon()
	end

	if self.awardCon then
		self.awardCon:SetActive(visible)

		if visible then
			self.awardDoubleIcon.gameObject:SetActive(false)

			if awardId then
				local awards = xyd.tables.activityLostSpaceBoxesTable:getAward(tonumber(awardId))
				local isShowIcon = xyd.tables.activityLostSpaceBoxesTable:getShowIcon(tonumber(awardId))

				if isShowIcon and isShowIcon == 1 then
					local params = {
						noClick = true,
						isShowSelected = false,
						uiRoot = self.awardItemCon.gameObject,
						itemID = awards[1],
						num = awards[2] * doubleNum
					}

					if not self.awardIcon then
						self.awardIcon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
					else
						self.awardIcon:setInfo(params)
					end

					self.awardImg.gameObject:SetActive(false)
					self.awardNumLabel.gameObject:SetActive(false)
					self.awardIcon:SetActive(true)
				else
					if self.awardIcon then
						self.awardIcon:SetActive(false)
					end

					self.awardImg.gameObject:SetActive(true)
					self.awardNumLabel.gameObject:SetActive(true)
				end
			else
				if self.awardIcon then
					self.awardIcon:SetActive(false)
				end

				self.awardImg.gameObject:SetActive(true)
				self.awardNumLabel.gameObject:SetActive(true)
			end
		end
	end
end

function MapGridItem:getTipsCon()
	if not self.tipsCon then
		self.tipsCon = NGUITools.AddChild(self.cardItemUp.gameObject, self.parent.cardItem_tipsCon.gameObject)
		self.tipsImg = self.tipsCon:ComponentByName("tipsImg", typeof(UITexture))
		self.tipsImg.depth = self.depthNum + 37 + 50

		self.tipsImg.gameObject:Y(14.1)
		self.tipsImg.gameObject:SetLocalScale(1, 1, 1)
		self.tipsCon.gameObject:Y(-13)

		self.tipsEffect = xyd.Spine.new(self.tipsImg.gameObject)

		self.tipsEffect:setInfo("fx_lost_space_camera", function ()
			self.tipsEffect:play("texiao01", 0)
		end)
	end

	return self.tipsCon
end

function MapGridItem:setTipsConVisible(visible)
	if visible and not self.tipsCon then
		self:getTipsCon()
	end

	if self.tipsCon then
		self.tipsCon:SetActive(visible)
	end
end

function MapGridItem:getLastCon()
	if not self.lastCon then
		self.lastCon = NGUITools.AddChild(self.cardItemBg.gameObject, self.parent.cardItem_lastCon.gameObject)
		self.lastImg = self.lastCon:ComponentByName("lastImg", typeof(UISprite))
		self.lastImg.depth = self.gridId + 1

		self.lastCon.gameObject:Y(51)
	end

	return self.lastCon
end

function MapGridItem:setLastConVisible(visible)
	if visible and not self.lastCon then
		self:getLastCon()
	end

	if self.lastCon then
		self.lastCon:SetActive(visible)
	end
end

function MapGridItem:getOpenCon()
	if not self.openCon then
		self.openCon = NGUITools.AddChild(self.cardItemBg.gameObject, self.parent.cardItem_openCon.gameObject)
		self.openImg = self.openCon:ComponentByName("openImg", typeof(UITexture))
		self.openImg.depth = self.depthNum + 38

		self.openCon.gameObject:Y(6)
	end

	return self.openCon
end

function MapGridItem:setOpenConVisible(visible)
	if visible and not self.openCon then
		self:getOpenCon()
	end

	if self.openCon then
		self.openCon:SetActive(visible)

		if visible then
			if not self.openEffect then
				self.openEffect = xyd.Spine.new(self.openImg.gameObject)

				self.openEffect:setInfo("fx_lost_space_disappear", function ()
					self.openEffect:play("texiao01", 1, 2)
				end)
			else
				self.openEffect:play("texiao01", 1, 2)
			end
		end
	end
end

function MapGridItem:getSkillCon()
	if not self.skillCon then
		self.skillCon = NGUITools.AddChild(self.cardItemUp.gameObject, self.parent.cardItem_skillCon.gameObject)
		self.skillImg = self.skillCon:ComponentByName("skillImg", typeof(UITexture))
		self.skillImg.depth = 600

		self.skillCon.gameObject:Y(6)
	end

	return self.skillCon
end

function MapGridItem:setskillConVisible(visible)
	if visible and not self.skillCon then
		self:getSkillCon()
	end

	if self.skillCon then
		self.skillCon:SetActive(visible)

		if visible then
			if not self.skillEffect then
				self.skillEffect = xyd.Spine.new(self.skillImg.gameObject)

				self.skillEffect:setInfo("fx_lost_space_skill", function ()
					self.skillEffect:playWithEvent("texiao01", 1, 2, {
						show = function ()
							self.parent:setSkillCompleteNum(self:getGridId())
						end
					})
				end)
			else
				self.skillEffect:playWithEvent("texiao01", 1, 2, {
					show = function ()
						self.parent:setSkillCompleteNum(self:getGridId())
					end
				})
			end
		end
	end
end

function rewardItem:ctor(go, parent)
	self.parent = parent

	rewardItem.super.ctor(self, go)
end

function rewardItem:initUI()
	self:getUIComponent()
	rewardItem.super.initUI(self)
end

function rewardItem:getUIComponent()
	self.itemCon = self.go:NodeByName("itemCon").gameObject
	self.arrowImg = self.go:ComponentByName("arrowImg", typeof(UISprite))
	self.tipsImg = self.go:ComponentByName("tipsImg", typeof(UISprite))
	local scale = 0.7037037037037037

	self.itemCon.gameObject:SetLocalScale(scale, scale, scale)
end

function rewardItem:update(_, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.info = info
	local award = xyd.tables.activityLostSpaceAwardsTable:getAward(info.id)
	local params = {
		isAddUIDragScrollView = true,
		isShowSelected = false,
		uiRoot = self.itemCon,
		itemID = award[1],
		avatar_frame_id = award[1],
		num = award[2]
	}

	if not self.icon or self.icon and self.id ~= info.id then
		if not self.icon then
			self.icon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.icon:setInfo(params)
		end
	end

	self.id = self.info.id

	if self.id <= 1 then
		if self.arrowImg.gameObject.activeSelf then
			self.arrowImg.gameObject:SetActive(false)
		end
	elseif not self.arrowImg.gameObject.activeSelf then
		self.arrowImg.gameObject:SetActive(true)
	end

	local curId = self.parent.activityData.detail.stage_id

	self.icon:setChoose(false)
	self.icon:setLock(false)

	if self.id < curId then
		self.icon:setChoose(true)
	elseif curId < self.id then
		self.icon:setLock(true)
	end

	local isHasTreasure = xyd.tables.activityLostSpaceAwardsTable:getIfTreasure(self.id)

	if isHasTreasure and isHasTreasure == 1 then
		self.tipsImg.gameObject:SetActive(true)
	else
		self.tipsImg.gameObject:SetActive(false)
	end
end

function rewardItem:getId()
	return self.id
end

return ActivityLostSpaceMapWindow
