local ActivitySpfarmMapWindow = class("ActivitySpfarmMapWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local MapGridItem = class("MapGridItem", import("app.components.CopyComponent"))
local BackContentItem = class("BackContentItem")
local json = require("cjson")
PLACE_STATE = {
	EMPTY = 0,
	COMMON = 2,
	DOOR = 3,
	GREY = 1,
	BUILD = 4,
	LOCK = 6,
	NOT_OPEN = 5
}

function ActivitySpfarmMapWindow:ctor(name, params)
	ActivitySpfarmMapWindow.super.ctor(self, name, params)

	self.resItemIdArr = {
		xyd.ItemID.ACTIVITY_SPFARM_SEED,
		xyd.ItemID.ACTIVITY_SPFARM_HORN,
		-1,
		xyd.ItemID.ACTIVITY_SPFARM_ROB_TICKET
	}
end

function ActivitySpfarmMapWindow:initWindow()
	self:getUIComponent()
	ActivitySpfarmMapWindow.super.initWindow(self)
	self:reSize()
	self:registerEvent()
	self:layout()
end

function ActivitySpfarmMapWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.bgup = self.groupAction:ComponentByName("bgup", typeof(UITexture))
	self.leftUpCon = self.groupAction:NodeByName("leftUpCon").gameObject
	self.helpBtn = self.leftUpCon:NodeByName("helpBtn").gameObject
	self.rankBtn = self.leftUpCon:NodeByName("rankBtn").gameObject
	self.rightUpCon = self.groupAction:NodeByName("rightUpCon").gameObject
	self.recordUpBtn = self.rightUpCon:NodeByName("recordUpBtn").gameObject
	self.recordUpBtnUISprite = self.recordUpBtn:GetComponent(typeof(UISprite))
	self.recordUpLayoutCon = self.recordUpBtn:NodeByName("recordUpLayoutCon").gameObject
	self.recordUpLayoutConUILayout = self.recordUpBtn:ComponentByName("recordUpLayoutCon", typeof(UILayout))
	self.recordUpBtnLabel = self.recordUpLayoutCon:ComponentByName("recordUpBtnLabel", typeof(UILabel))
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.logoImg = self.upCon:ComponentByName("logoImg", typeof(UISprite))
	self.famousLabel = self.upCon:ComponentByName("famousLabel", typeof(UILabel))
	self.centerCon = self.groupAction:NodeByName("centerCon").gameObject
	self.cardItem = self.centerCon:NodeByName("cardItem").gameObject
	self.cardCon = self.centerCon:NodeByName("cardCon").gameObject
	self.cardConUIGrid = self.centerCon:ComponentByName("cardCon", typeof(UIGrid))
	self.testItemsCon = self.upCon:NodeByName("testItemsCon").gameObject

	for i = 1, 3 do
		self["upItem" .. i] = self.testItemsCon:NodeByName("upItem" .. i).gameObject
		self["resBg" .. i] = self["upItem" .. i]:ComponentByName("bg", typeof(UISprite))
		self["icon" .. i] = self["upItem" .. i]:ComponentByName("icon", typeof(UISprite))
		self["btnAdd" .. i] = self["upItem" .. i]:NodeByName("btnAdd").gameObject
		self["label" .. i] = self["upItem" .. i]:ComponentByName("label", typeof(UILabel))
	end

	self.downGroup = self.groupAction:NodeByName("downGroup").gameObject
	self.personPanel = self.downGroup:NodeByName("personPanel").gameObject
	self.downItem1 = self.downGroup:NodeByName("downItem1").gameObject
	self["icon" .. 4] = self.downItem1:ComponentByName("icon", typeof(UISprite))
	self["resBg" .. 4] = self.downItem1:ComponentByName("bg", typeof(UISprite))
	self["btnAdd" .. 4] = self.downItem1:NodeByName("btnAdd").gameObject
	self["label" .. 4] = self.downItem1:ComponentByName("label", typeof(UILabel))
	self.robBtn = self.downGroup:NodeByName("robBtn").gameObject
	self.robBtnBoxCollider = self.downGroup:ComponentByName("robBtn", typeof(UnityEngine.BoxCollider))
	self.robBtnLabel = self.robBtn:ComponentByName("robBtnLabel", typeof(UILabel))
	self.famousAwardCon = self.downGroup:ComponentByName("famousAwardCon", typeof(UISprite))
	self.famousAwardBtn = self.famousAwardCon:NodeByName("famousAwardBtn").gameObject
	self.recordLayoutCon = self.famousAwardBtn:NodeByName("recordLayoutCon").gameObject
	self.recordLayoutConUILayout = self.famousAwardBtn:ComponentByName("recordLayoutCon", typeof(UILayout))
	self.recordBtnLabel = self.recordLayoutCon:ComponentByName("recordBtnLabel", typeof(UILabel))
	self.recordBtnIcon = self.recordLayoutCon:NodeByName("recordBtnIcon").gameObject
	self.famousItemsCon = self.famousAwardCon:NodeByName("famousItemsCon").gameObject
	self.famousItemsConUILayout = self.famousAwardCon:ComponentByName("famousItemsCon", typeof(UILayout))
	self.cardItem_doorLabelCon = self.centerCon:NodeByName("cardItem_doorLabelCon").gameObject
	self.cardItem_buildCon = self.centerCon:NodeByName("cardItem_buildCon").gameObject
	self.cardItem_selectCon = self.centerCon:NodeByName("cardItem_selectCon").gameObject
	self.cardItem_noClickCon = self.centerCon:NodeByName("cardItem_noClickCon").gameObject
	self.cardItem_personCon = self.centerCon:NodeByName("cardItem_personCon").gameObject
	self.allMaskPanel = self.centerCon:NodeByName("allMaskPanel").gameObject
	self.maskTexture = self.allMaskPanel:ComponentByName("maskTexture", typeof(UITexture))

	for i = 1, 4 do
		self["maskBox" .. i] = self.allMaskPanel:NodeByName("maskBox" .. i).gameObject
	end

	self.maskLabel = self.allMaskPanel:ComponentByName("maskLabel", typeof(UILabel))
	self.getHangAwardPanel = self.groupAction:NodeByName("getHangAwardPanel").gameObject
	self.getHangAwardBtn = self.getHangAwardPanel:NodeByName("getHangAwardBtn").gameObject
	self.downBackCon = self.downGroup:ComponentByName("downBackCon", typeof(UISprite))
	self.backTipsBtn = self.downBackCon:NodeByName("backTipsBtn").gameObject
	self.backNameLabel = self.downBackCon:ComponentByName("backNameLabel", typeof(UILabel))
	self.backNumLabel = self.downBackCon:ComponentByName("backNumLabel", typeof(UILabel))
	self.backUIScroller = self.downBackCon:NodeByName("backUIScroller").gameObject
	self.backUIScrollerUIScrollView = self.downBackCon:ComponentByName("backUIScroller", typeof(UIScrollView))
	self.backScrollerContent = self.backUIScroller:NodeByName("backScrollerContent").gameObject
	self.backScrollerContentUIWrapContent = self.backUIScroller:ComponentByName("backScrollerContent", typeof(UIWrapContent))
	self.backItem = self.downBackCon:NodeByName("backItem").gameObject
	self.backWrapContent = require("app.common.ui.FixedWrapContent").new(self.backUIScrollerUIScrollView, self.backScrollerContentUIWrapContent, self.backItem, BackContentItem, self)
	self.showBackIconPanel = self.downGroup:NodeByName("showBackIconPanel").gameObject
	self.showBackIconCon = self.showBackIconPanel:NodeByName("showBackIconCon").gameObject
	self.showBackIcon = self.showBackIconCon:ComponentByName("showBackIcon", typeof(UISprite))
	self.plant1Con = self.groupAction:NodeByName("plant1Con").gameObject
	self.plant2Con = self.groupAction:NodeByName("plant2Con").gameObject
	self.blackPanel = self.groupAction:NodeByName("blackPanel").gameObject
	self.blackMask = self.blackPanel:NodeByName("blackMask").gameObject
	self.blackEffectCon = self.blackPanel:ComponentByName("blackEffectCon", typeof(UITexture))
end

function ActivitySpfarmMapWindow:reSize()
	self:resizePosY(self.leftUpCon.gameObject, 431, 501)
	self:resizePosY(self.rightUpCon.gameObject, 447.8, 510)
	self:resizePosY(self.logoImg.gameObject, 29.3, 15)
	self:resizePosY(self.famousLabel.gameObject, -32, -80)
	self:resizePosY(self.testItemsCon.gameObject, -20, -83)
	self:resizePosY(self.centerCon.gameObject, 8, -89)
	self:resizePosY(self.downGroup.gameObject, -420, -514)
	self:resizePosY(self.bgup.gameObject, 517, 451)
end

function ActivitySpfarmMapWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	UIEventListener.Get(self.famousAwardBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("spfarm_check_award_window", {})
	end

	UIEventListener.Get(self.rankBtn).onClick = function ()
		if not self.activityData:reqFriendRank() then
			xyd.WindowManager.get():openWindow("activity_spfarm_rank_window", {})
		end
	end

	for i = 1, 4 do
		UIEventListener.Get(self["maskBox" .. i].gameObject).onClick = handler(self, function ()
			self:closeMove()
		end)
	end

	for i = 1, 4 do
		if i ~= 3 then
			local function itemClick()
				if i == 4 then
					if self.activityData:isViewing() or self.activityData:isEnd() then
						xyd.alertTips(__("ACTIVITY_SPFARM_TEXT85", xyd.tables.itemTable:getName(self.resItemIdArr[i])))

						return
					end

					self:buyTickets()

					return
				end

				xyd.WindowManager.get():openWindow("activity_item_getway_window", {
					itemID = self.resItemIdArr[i],
					activityID = xyd.ActivityID.ACTIVITY_SPFARM,
					openDepthTypeWindowCallBack = function (typeInfo)
						if typeInfo.layerType == xyd.UILayerType.FULL_SCREEN_UI then
							self:close()
						end
					end
				})
			end

			UIEventListener.Get(self["resBg" .. i].gameObject).onClick = function ()
				itemClick()
			end

			UIEventListener.Get(self["btnAdd" .. i].gameObject).onClick = function ()
				itemClick()
			end
		end

		if i == 3 then
			local function rightUpItemFun()
				if self:getIsMySelf() then
					if self.activityData:getTypeDefMaxNum() <= self.activityData:getTypeDefLimitNum() then
						xyd.alertConfirm(__("ACTIVITY_SPFARM_TEXT69"), nil, __("SURE"))
					else
						xyd.alertConfirm(__("ACTIVITY_SPFARM_TEXT68"), nil, __("SURE"))
					end
				else
					xyd.WindowManager.get():openWindow("activity_spfarm_select_partner_window", {})
				end
			end

			UIEventListener.Get(self["resBg" .. i].gameObject).onClick = function ()
				rightUpItemFun()
			end

			UIEventListener.Get(self["btnAdd" .. i].gameObject).onClick = function ()
				rightUpItemFun()
			end
		end
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		if self:getIsMySelf() then
			xyd.WindowManager:get():openWindow("help_window", {
				key = "ACTIVITY_SPFARM_HELP1"
			})
		else
			xyd.WindowManager:get():openWindow("help_window", {
				key = "ACTIVITY_SPFARM_HELP2"
			})
		end
	end

	UIEventListener.Get(self.backTipsBtn.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_SPFARM_TEXT66"
		})
	end

	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.itemChange))

	UIEventListener.Get(self.getHangAwardBtn).onClick = function ()
		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
			type = xyd.ActivitySpfarmType.GET_HANG_AWARD
		}))
	end

	UIEventListener.Get(self.robBtn.gameObject).onClick = function ()
		if self.activityData:isViewing() or self.activityData:isEnd() then
			xyd.alertTips(__("ACTIVITY_END_YET"))

			return
		end

		if not self.activityData:checkHasOpponentArr() then
			xyd.alertTips(__("ACTIVITY_SPFARM_TEXT80"))
			self.activityData:sendNewOpponentInfos()

			return
		end

		local function choiceFun()
			xyd.WindowManager:get():openWindow("activity_spfarm_opponent_window", {
				infos = self.activityData:getNewOpponentInfos()
			})
		end

		local checkNum = xyd.tables.miscTable:getNumber("activity_spfarm_fight_lvl", "value")
		local curTotalNum = self.activityData:getAllBuildTotalLev()

		if curTotalNum < checkNum then
			local tipsWindow = xyd.alertYesNo(__("ACTIVITY_SPFARM_TEXT84"), function (yes_no)
				if not yes_no then
					choiceFun()
				end
			end, __("ACTIVITY_SPFARM_TEXT89"))

			tipsWindow:setCancelBtnLabel(__("ACTIVITY_SPFARM_TEXT88"))

			return
		end

		choiceFun()
	end

	UIEventListener.Get(self.recordUpBtn).onClick = function ()
		self.activityData:reqRecord()
	end
end

function ActivitySpfarmMapWindow:initTop()
	self.windowTop = WindowTop.new(self.window_, self.name_, 350)
	local items = {
		{
			id = xyd.ItemID.MANA
		},
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	self.windowTop:setItem(items)
end

function ActivitySpfarmMapWindow:layout()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)
	self.maskLabel.text = __("ACTIVITY_SPFARM_TEXT31")
	self.robBtnLabel.text = __("ACTIVITY_SPFARM_TEXT05")

	if self.activityData:isViewing() or self.activityData:isEnd() then
		self.robBtnLabel.text = __("ACTIVITY_SPFARM_TEXT81")
		self.robBtnBoxCollider.enabled = false

		xyd.applyChildrenGrey(self.robBtn.gameObject)
	end

	self.backNameLabel.text = __("ACTIVITY_SPFARM_TEXT08")
	self.recordBtnLabel.text = __("ACTIVITY_SPFARM_TEXT06")

	if xyd.Global.lang == "en_en" then
		self.recordUpBtnLabel.fontSize = 18
	end

	self.recordUpBtnLabel.text = __("REOCRD")

	self.recordUpLayoutConUILayout:Reposition()

	self.recordUpBtnUISprite.width = 72 + self.recordUpBtnLabel.width

	self.recordUpBtn.gameObject:X(19.8 - (self.recordUpBtnLabel.width - 44) / 2)
	self:initTop()
	xyd.setUISpriteAsync(self.logoImg, nil, "activity_spfarm_logo_" .. xyd.Global.lang)

	self.gridPosArr = {}

	for i = 1, 25 do
		table.insert(self.gridPosArr, i)
	end

	self.gridArr = {}

	for i in pairs(self.gridPosArr) do
		local tmp = NGUITools.AddChild(self.cardCon.gameObject, self.cardItem.gameObject)
		local item = MapGridItem.new(tmp, self.gridPosArr[i], self)
		self.gridArr[self.gridPosArr[i]] = item
	end

	self.cardConUIGrid:Reposition()
	self:updateCheckCanGetHange()
	self:updateGridState()
	self:updatePersonEffect()
	self:updateFamousNum()
	self:updateDownShow()
	self:updateUpBtnShow()
	self:updateRightUpItemShow()
	self:updateFamousAwardsCon()
	self:updateDoorEffect()
	self:updatePlantShow()

	for i = 1, 4 do
		if i ~= 3 then
			xyd.setUISpriteAsync(self["icon" .. i], nil, xyd.tables.itemTable:getIcon(self.resItemIdArr[i]) .. "_small", function ()
				local scale = 1.5

				if i == 1 or i == 2 then
					scale = 1.5
				elseif i == 4 then
					scale = 1.7
				end

				self["icon" .. i].gameObject:SetLocalScale(scale, scale, 1)
			end, nil, true)
		end
	end

	self:updateResItem()
end

function ActivitySpfarmMapWindow:updateFamousNum()
	if self:getIsMySelf() then
		self.famousLabel.text = __("ACTIVITY_SPFARM_TEXT04", self:getFamousNum())
	else
		self.famousLabel.text = __("ACTIVITY_SPFARM_TEXT07")
	end
end

function ActivitySpfarmMapWindow:updateUpBtnShow()
	if self:getIsMySelf() then
		self.rankBtn.gameObject:SetActive(true)
		self.recordUpBtn.gameObject:SetActive(true)
	else
		self.rankBtn.gameObject:SetActive(false)
		self.recordUpBtn.gameObject:SetActive(false)
	end
end

function ActivitySpfarmMapWindow:updateDownShow()
	if self:getIsMySelf() then
		self.downItem1.gameObject:SetActive(true)
		self.robBtn.gameObject:SetActive(true)
		self.famousAwardCon.gameObject:SetActive(true)
		self.downBackCon.gameObject:SetActive(false)
	else
		self.downItem1.gameObject:SetActive(false)
		self.robBtn.gameObject:SetActive(false)
		self.famousAwardCon.gameObject:SetActive(false)
		self.downBackCon.gameObject:SetActive(true)
		self:updateBackShow()
	end
end

function ActivitySpfarmMapWindow:updateBackShow(isSet)
	if not isSet then
		self.slotsRob = xyd.cloneTable(self.activityData:getSlotsRob())
	end

	local maxBackNum = self.activityData:getTypeBuildLimitNum(xyd.ActivitySpfarmPlicyType.ROOT_NUM)

	if not isSet then
		self.backNumLabel.text = #self.slotsRob .. "/" .. maxBackNum

		self:updateDoorEffect()
	end

	local tempArr = {}

	for i = #self.slotsRob, 1, -1 do
		table.insert(tempArr, self.slotsRob[i])
	end

	for i = #self.slotsRob + 1, maxBackNum do
		table.insert(tempArr, -1)
	end

	if isSet then
		table.insert(tempArr, 1, -1)
		table.remove(tempArr, #tempArr)
	end

	local setArr = {}

	for i in pairs(tempArr) do
		table.insert(setArr, {
			curIndex = i,
			id = tempArr[i]
		})
	end

	self.backWrapContent:setInfos(setArr, {})
	self.backUIScrollerUIScrollView:ResetPosition()
end

function ActivitySpfarmMapWindow:updatePersonEffect()
	if not self.normalModel_ then
		self.normalModel_ = import("app.components.SenpaiModel").new(self.personPanel.gameObject)

		self.normalModel_:SetLocalScale(0.66, 0.66, 1)
		self.normalModel_:SetLocalPosition(0, -99.2, 0)
	end

	local ids = xyd.cloneTable(xyd.models.dress:getEquipedStyles())

	if not self:getIsMySelf() then
		ids[4] = xyd.tables.miscTable:getNumber("activity_spfarm_dress", "value")
	end

	self.normalModel_:setModelInfo({
		isNewClipShader = false,
		ids = ids
	})
end

function ActivitySpfarmMapWindow:updateGridState()
	for i in pairs(self.gridArr) do
		if self.gridArr[i]:getGridId() == self.activityData:getDoorPos() then
			self.gridArr[i]:updateState(PLACE_STATE.DOOR)
		elseif self:getIsMySelf() then
			local myMap = self.activityData:getMyMap()

			if myMap[i] == 0 then
				self.gridArr[i]:updateState(PLACE_STATE.EMPTY)
			else
				self.gridArr[i]:updateState(PLACE_STATE.BUILD)
			end
		else
			local mapRob = self.activityData:getMapRob()

			self.gridArr[i]:setMaskState(false)
			self.gridArr[i]:setNoClickConVisible(false)

			if mapRob[i] == -1 then
				self.gridArr[i]:updateState(PLACE_STATE.NOT_OPEN)
				self.gridArr[i]:setMaskState(true)
			elseif mapRob[i] == 0 then
				self.gridArr[i]:updateState(PLACE_STATE.EMPTY)
			elseif mapRob[i] > 0 then
				self.gridArr[i]:updateState(PLACE_STATE.BUILD)
			end
		end
	end

	if not self:getIsMySelf() then
		self:updateRobMapLightGrid()
	end
end

function ActivitySpfarmMapWindow:updateRobMapLightGrid()
	if not self:getIsMySelf() then
		for i in pairs(self.gridArr) do
			if self.gridArr[i]:getState() ~= PLACE_STATE.NOT_OPEN then
				local borderArr = self:getBorderIds(i)

				for k in pairs(borderArr) do
					if self.gridArr[borderArr[k].id]:getState() == PLACE_STATE.NOT_OPEN then
						self.gridArr[borderArr[k].id]:setMaskState(false)
					end
				end
			end

			if self.gridArr[i]:getState() == PLACE_STATE.BUILD then
				local buildRobInfo = self.activityData:getRobBuildBaseInfo(self.gridArr[i]:getGridId())

				if buildRobInfo and buildRobInfo.partners and #buildRobInfo.partners > 0 and self:getCheckBuildEnemyIsAllDepth(buildRobInfo) then
					local borderArr = self:getBorderIds(i)

					for k in pairs(borderArr) do
						self.gridArr[borderArr[k].id]:setNoClickConVisible(false)
					end
				end
			end
		end

		for i in pairs(self.gridArr) do
			if self.gridArr[i]:getState() == PLACE_STATE.BUILD then
				local buildRobInfo = self.activityData:getRobBuildBaseInfo(self.gridArr[i]:getGridId())

				if buildRobInfo and buildRobInfo.partners and #buildRobInfo.partners > 0 then
					if not self:getCheckBuildEnemyIsAllDepth(buildRobInfo) then
						local borderArr = self:getBorderIds(i)

						for k in pairs(borderArr) do
							if self.gridArr[borderArr[k].id]:getState() == PLACE_STATE.NOT_OPEN then
								self.gridArr[borderArr[k].id]:setNoClickConVisible(true)
							end
						end
					end
				end
			end
		end
	end
end

function ActivitySpfarmMapWindow:getCheckBuildEnemyIsAllDepth(buildRobInfo)
	if buildRobInfo and buildRobInfo.partners and #buildRobInfo.partners > 0 then
		local enemyAllHp = -1

		for k, partnerInfo in pairs(buildRobInfo.partners) do
			if partnerInfo.status and partnerInfo.status.hp then
				enemyAllHp = 0

				break
			end
		end

		for k, partnerInfo in pairs(buildRobInfo.partners) do
			if partnerInfo.status and partnerInfo.status.hp then
				enemyAllHp = enemyAllHp + partnerInfo.status.hp
			end
		end

		if enemyAllHp == 0 then
			return true
		else
			return false
		end
	end
end

function ActivitySpfarmMapWindow:getBorderIds(id)
	local borderArr = {}
	local left_index = id - 1
	local right_index = id + 1
	local up_index = id - 5
	local down_index = id + 5
	local left_up = id - 6
	local left_down = id + 4
	local right_up = id - 4
	local right_down = id + 6

	if id % 5 == 1 then
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

	if id % 5 == 0 then
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

	if id >= 21 then
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

	if id <= 5 then
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

function ActivitySpfarmMapWindow:getFamousNum()
	return self.activityData:getFamousNum()
end

function ActivitySpfarmMapWindow:getIsMySelf()
	local mapRob = self.activityData:getMapRob()

	if mapRob and #mapRob > 0 then
		return false
	end

	return true
end

function ActivitySpfarmMapWindow:updateRobGrid(gridId)
	for i in pairs(self.gridArr) do
		if self.gridArr[i]:getGridId() == gridId then
			local mapRob = self.activityData:getMapRob()

			self.gridArr[i]:setMaskState(false)
			self.gridArr[i]:setNoClickConVisible(false)

			if mapRob[i] == -1 then
				self.gridArr[i]:updateState(PLACE_STATE.NOT_OPEN)
				self.gridArr[i]:setMaskState(true)

				break
			end

			if mapRob[i] == 0 then
				self.gridArr[i]:updateState(PLACE_STATE.EMPTY)

				break
			end

			if mapRob[i] > 0 then
				self.gridArr[i]:updateState(PLACE_STATE.BUILD)
			end

			break
		end
	end

	self:updateRobMapLightGrid()
end

function ActivitySpfarmMapWindow:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_SPFARM then
		return
	end

	local data = xyd.decodeProtoBuf(event.data)
	data.detail = json.decode(data.detail)
	local type = data.detail.type

	if type == xyd.ActivitySpfarmType.EXPLORE then
		self:updateRobGrid(data.detail.pos)
		self:updateDoorEffect()
	elseif type == xyd.ActivitySpfarmType.REMOVE_AWARD then
		self:updateDownShow()
	elseif type == xyd.ActivitySpfarmType.OCCUPY then
		for i in pairs(self.gridArr) do
			if self.activityData:getMapRob()[self.gridArr[i]:getGridId()] > 0 then
				local checkId = self.activityData:getRobBuildBaseInfo(self.gridArr[i]:getGridId()).id

				if checkId and checkId == data.detail.id then
					self.gridArr[i]:updateState(PLACE_STATE.BUILD)
					self:showBackIconFun(self.gridArr[i]:getGridId(), i)

					break
				end
			end
		end

		self:updateDoorEffect()
	elseif type == xyd.ActivitySpfarmType.END_ROB then
		self:updateCheckCanGetHange()
		self:updateGridState()
		self:updateFamousNum()
		self:updateDownShow()
		self:updateRightUpItemShow()
		self:updatePersonEffect()
		self:updateUpBtnShow()
		self:updatePlantShow()

		if self.activityData:isViewing() or self.activityData:isEnd() then
			self.robBtnLabel.text = __("ACTIVITY_SPFARM_TEXT81")
			self.robBtnBoxCollider.enabled = false

			xyd.applyChildrenGrey(self.robBtn.gameObject)
		end
	elseif type == xyd.ActivitySpfarmType.START_ROB then
		self:showBlackMask()
		self:waitForTime(1, function ()
			self:updateGridState()
			self:updateFamousNum()
			self:updateDownShow()
			self:updateRightUpItemShow()
			self:updatePersonEffect()
			self:updateUpBtnShow()
			self:updatePlantShow()

			local viewingEndFiveMinsTips = xyd.db.misc:getValue("viewing_end_mins_tips")
			viewingEndFiveMinsTips = viewingEndFiveMinsTips and tonumber(viewingEndFiveMinsTips)

			if (not viewingEndFiveMinsTips or viewingEndFiveMinsTips and (viewingEndFiveMinsTips < self.activityData:startTime() or self.activityData:getEndTime() <= viewingEndFiveMinsTips)) and xyd.getServerTime() >= self.activityData:getEndTime() - self.activityData:getViewTimeSec() - 300 and xyd.getServerTime() < self.activityData:getEndTime() - self.activityData:getViewTimeSec() then
				xyd.alertConfirm(__("ACTIVITY_SPFARM_TEXT86"), nil, __("SURE"))
				xyd.db.misc:setValue({
					key = "viewing_end_mins_tips",
					value = xyd.getServerTime()
				})
			end
		end)
	elseif type == xyd.ActivitySpfarmType.POLICY then
		self:updateFamousNum()

		if self:getIsMySelf() then
			for i in pairs(self.gridArr) do
				if self.gridArr[i]:getGridId() == self.activityData:getDoorPos() then
					self.gridArr[i]:updateState(PLACE_STATE.DOOR)

					break
				end
			end
		end

		self:updateRightUpItemShow()
		self:updateFamousAwardsCon()
	elseif type == xyd.ActivitySpfarmType.BUILD then
		local pos = data.detail.pos

		for i in pairs(self.gridArr) do
			if self.gridArr[i]:getGridId() == pos then
				self.gridArr[i]:updateState(PLACE_STATE.BUILD)

				break
			end
		end
	elseif type == xyd.ActivitySpfarmType.UP_GRADE then
		local info_id = data.detail.id
		local searchIndex = nil

		for i, id in pairs(self.activityData:getMyMap()) do
			if id == info_id then
				searchIndex = i

				break
			end
		end

		if searchIndex then
			for i in pairs(self.gridArr) do
				if self.gridArr[i]:getGridId() == searchIndex then
					self.gridArr[i]:updateState(PLACE_STATE.BUILD)

					break
				end
			end
		end
	elseif type == xyd.ActivitySpfarmType.CHANGE then
		local info_id = data.detail.id
		local searchIndex = nil

		for i, id in pairs(self.activityData:getMyMap()) do
			if id == info_id then
				searchIndex = i

				break
			end
		end

		if searchIndex then
			for i in pairs(self.gridArr) do
				if self.gridArr[i]:getGridId() == searchIndex then
					self.gridArr[i]:updateState(PLACE_STATE.BUILD)

					break
				end
			end
		end
	elseif type == xyd.ActivitySpfarmType.MOVE then
		self:closeMove(true)
		self:updateGridState()
	elseif type == xyd.ActivitySpfarmType.SET_DEF then
		local info_id = data.detail.id
		local searchIndex = nil

		for i, id in pairs(self.activityData:getMyMap()) do
			if id == info_id then
				searchIndex = i

				break
			end
		end

		if searchIndex then
			for i in pairs(self.gridArr) do
				if self.gridArr[i]:getGridId() == searchIndex then
					self.gridArr[i]:updateState(PLACE_STATE.BUILD)

					break
				end
			end
		end

		self:updateRightUpItemShow()
	elseif type == xyd.ActivitySpfarmType.FIGHT then
		self:updateRobGrid(data.detail.pos)
		self:updateDoorEffect()
	elseif type == xyd.ActivitySpfarmType.GET_HANG_AWARD then
		self:updateCheckCanGetHange()
		self:updateGridState()
	elseif type == xyd.ActivitySpfarmType.RECORD then
		local list = data.detail.list

		if not list or #list <= 0 then
			xyd.alertTips(__("ACTIVITY_SPFARM_TEXT108"))

			return
		end

		xyd.WindowManager.get():openWindow("activity_spfarm_record_window", {
			list = list
		})
	elseif type == xyd.ActivitySpfarmType.GET_AWARD then
		self:updateFamousAwardsCon()
	end
end

function ActivitySpfarmMapWindow:openMove(gridId, openMoveType, openMoveBuildInfoId)
	self.moving = gridId

	for i in pairs(self.gridArr) do
		if self.gridArr[i]:getGridId() == gridId then
			self.gridArr[i]:updateState(PLACE_STATE.BUILD)

			break
		end
	end

	self.openMoveType = openMoveType
	self.openMoveBuildInfoId = openMoveBuildInfoId

	self.allMaskPanel.gameObject:SetActive(true)
end

function ActivitySpfarmMapWindow:closeMove(succ)
	local tempId = self.moving
	self.moving = nil

	if not succ then
		if tempId then
			for i in pairs(self.gridArr) do
				if self.gridArr[i]:getGridId() == tempId then
					self.gridArr[i]:updateState(PLACE_STATE.BUILD)

					break
				end
			end
		end

		if self.openMoveType and self.openMoveType == xyd.ActivitySpfarmOpenMoveType.UP then
			xyd.WindowManager.get():openWindow("activity_spfarm_build_up_window", {
				gridId = tempId
			})
		end
	elseif self.openMoveType and self.openMoveType == xyd.ActivitySpfarmOpenMoveType.UP and self.openMoveBuildInfoId then
		local searchIndex = nil

		for i, id in pairs(self.activityData:getMyMap()) do
			if id == self.openMoveBuildInfoId then
				searchIndex = i

				break
			end
		end

		if searchIndex then
			for i in pairs(self.gridArr) do
				if self.gridArr[i]:getGridId() == searchIndex then
					xyd.WindowManager.get():openWindow("activity_spfarm_build_up_window", {
						gridId = self.gridArr[i]:getGridId()
					})

					break
				end
			end
		end
	end

	self.openMoveBuildInfoId = nil

	self.allMaskPanel.gameObject:SetActive(false)
end

function ActivitySpfarmMapWindow:getMoving()
	return self.moving
end

function ActivitySpfarmMapWindow:updateResItem()
	self["label" .. 1].text = tostring(xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_SPFARM_SEED))
	self["label" .. 2].text = tostring(xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_SPFARM_HORN))
	self["label" .. 4].text = tostring(xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_SPFARM_ROB_TICKET))
end

function ActivitySpfarmMapWindow:itemChange(event)
	local items = event.data.items

	for i, item in pairs(items) do
		if item.item_id == xyd.ItemID.ACTIVITY_SPFARM_SEED or item.item_id == xyd.ItemID.ACTIVITY_SPFARM_HORN or item.item_id == xyd.ItemID.ACTIVITY_SPFARM_ROB_TICKET then
			self:updateResItem()

			if item.item_id == xyd.ItemID.ACTIVITY_SPFARM_HORN then
				self:updateDoorEffect()
			end
		end
	end
end

function ActivitySpfarmMapWindow:updateCheckCanGetHange()
	self.getHangAwardPanel.gameObject:SetActive(false)

	if self:getIsMySelf() then
		local buildInfos = self.activityData:getMyBuildInfos()

		for i, buildInfo in pairs(buildInfos) do
			if buildInfo.items then
				self.getHangAwardPanel.gameObject:SetActive(true)
			end
		end
	end
end

function ActivitySpfarmMapWindow:showBackIconFun(gridId, gridIndex)
	self:updateBackShow(true)

	self.isSetBackimg = true
	self.backUIScrollerUIScrollView.enabled = false

	self.showBackIconCon.gameObject:SetActive(true)

	local robBuildInfo = self.activityData:getRobBuildBaseInfo(gridId)
	local outCome = xyd.tables.activitySpfarmBuildingTable:getOutcome(robBuildInfo.build_id)
	local startIcon = self.gridArr[gridIndex]:getBuildTipsIcon()
	local startPos = self.showBackIconCon.transform:InverseTransformPoint(startIcon.gameObject.transform.position)
	local backWrapItems = self.backWrapContent:getItems()
	local endIcon = nil

	for i, item in pairs(backWrapItems) do
		if item:getCurIndex() == 1 then
			endIcon = item:getBgIcon()
		end
	end

	local endPos = self.showBackIconCon.transform:InverseTransformPoint(endIcon.gameObject.transform.position)

	self.showBackIcon:SetLocalPosition(startPos.x, startPos.y, 0)
	xyd.setUISpriteAsync(self.showBackIcon, nil, xyd.tables.itemTable:getIcon(outCome[1]), function ()
		self.showBackIcon:SetLocalScale(0.55, 0.55, 1)
	end, nil, true)
	xyd.SoundManager.get():playSound(xyd.SoundID.CLICK_SHOP)

	local action = self:getSequence()

	local function setter(value)
		local scale = 0.55 + 0.14444444444444438 * value

		self.showBackIcon:SetLocalScale(scale, scale, 1)

		local x = startPos.x + (endPos.x - startPos.x) * value
		local y = startPos.y + (endPos.y - startPos.y) * value

		self.showBackIcon:SetLocalPosition(x, y, 0)
	end

	action:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 1, 0.2))
	action:AppendCallback(function ()
		action:Kill(false)
		self:updateBackShow()
		self.showBackIconCon.gameObject:SetActive(false)

		self.backUIScrollerUIScrollView.enabled = true
		self.isSetBackimg = false
	end)
end

function ActivitySpfarmMapWindow:getIsSetBacking()
	return self.isSetBackimg
end

function ActivitySpfarmMapWindow:updateDoorEffect()
	for i in pairs(self.gridArr) do
		if self.gridArr[i]:getGridId() == self.activityData:getDoorPos() then
			self.gridArr[i]:updateState(PLACE_STATE.DOOR)
		end
	end
end

function ActivitySpfarmMapWindow:updateRightUpItemShow()
	if self:getIsMySelf() then
		xyd.setUISpriteAsync(self["icon" .. 3], nil, "activity_spfarm_icon_fs", function ()
			self["icon" .. 3].gameObject:SetLocalScale(0.8, 0.8, 1)
			self["icon" .. 3].gameObject:Y(0.9)
		end, nil, true)

		self["label" .. 3].text = self.activityData:getTypeDefMyNum() .. "/" .. self.activityData:getTypeDefLimitNum()
	else
		xyd.setUISpriteAsync(self["icon" .. 3], nil, "bottom_icon_2_o_v3_h5", function ()
			self["icon" .. 3].gameObject:SetLocalScale(0.65, 0.65, 1)
			self["icon" .. 3].gameObject:Y(4)
		end, nil, true)

		local maxPartners = self.activityData:getTypeBuildLimitNum(xyd.ActivitySpfarmPlicyType.SELECT_PARTNER_NUM)
		self["label" .. 3].text = #self.activityData:getPartnerUse() .. "/" .. maxPartners
	end
end

function ActivitySpfarmMapWindow:updateFamousAwardsCon()
	local ids = xyd.tables.activitySpfarmAwardTable:getIds()

	local function checkIsAwarded(id)
		local awards = self.activityData.detail.awards

		if awards and awards[id] and tonumber(awards[id]) > 0 then
			return true
		end

		return false
	end

	local levelNow = self.activityData:getFamousNum()
	local ids = xyd.tables.activitySpfarmAwardTable:getIds()
	local showId, showType = nil

	for i, id in pairs(ids) do
		local level = xyd.tables.activitySpfarmAwardTable:getLevel(id)
		local is_awarded = checkIsAwarded(id)

		if not is_awarded and level <= levelNow then
			showId = id
			showType = 1

			break
		end
	end

	if not showId then
		for i, id in pairs(ids) do
			local is_awarded = checkIsAwarded(id)

			if not is_awarded then
				showId = id
				showType = 2

				break
			end
		end
	end

	if not showId then
		showId = ids[#ids]
		showType = 3
	end

	local function reqFamousAward()
		local reqList = {}

		for _, id in pairs(ids) do
			local level = xyd.tables.activitySpfarmAwardTable:getLevel(id)
			local is_awarded = checkIsAwarded(id)

			if not is_awarded and level <= levelNow then
				table.insert(reqList, id)
			end
		end

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
			type = xyd.ActivitySpfarmType.GET_AWARD,
			award_ids = reqList
		}))
	end

	for i = 1, 2 do
		local awards = xyd.tables.activitySpfarmAwardTable:getAwards(showId)
		local params = {
			notPlaySaoguang = true,
			scale = 0.6111111111111112,
			preGenarate = true,
			uiRoot = self.famousItemsCon.gameObject,
			itemID = awards[i][1],
			num = awards[i][2]
		}

		if not self["famousAwardIcon" .. i] then
			self["famousAwardIcon" .. i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		else
			self["famousAwardIcon" .. i]:setInfo(params)
		end

		if showType == 1 then
			self["famousAwardIcon" .. i]:setChoose(false)

			local effect = "bp_available"

			self["famousAwardIcon" .. i]:setEffect(true, effect, {
				effectPos = Vector3(0, -2, 0),
				effectScale = Vector3(1.1, 1.1, 1.1)
			})
			self["famousAwardIcon" .. i]:setCallBack(function ()
				reqFamousAward()
			end)
		elseif showType == 2 then
			self["famousAwardIcon" .. i]:setChoose(false)
			self["famousAwardIcon" .. i]:setEffect(false)
			self["famousAwardIcon" .. i]:setCallBack(nil)
		elseif showType == 3 then
			self["famousAwardIcon" .. i]:setChoose(true)
			self["famousAwardIcon" .. i]:setEffect(false)
			self["famousAwardIcon" .. i]:setCallBack(nil)
		end
	end

	self.famousItemsConUILayout:Reposition()
end

function ActivitySpfarmMapWindow:buyTickets()
	local maxNumBeen = self.activityData.detail.buy_times
	maxNumBeen = maxNumBeen or 0
	local maxNumCanBuy = xyd.tables.miscTable:getNumber("activity_spfarm_buy_max", "value") - maxNumBeen

	if maxNumCanBuy <= 0 then
		maxNumCanBuy = 0
	end

	xyd.WindowManager:get():openWindow("activity_item_getway_window", {
		itemID = xyd.ItemID.ACTIVITY_SPFARM_ROB_TICKET,
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
				cost = xyd.tables.miscTable:split2Cost("activity_spfarm_energy_price", "value", "#"),
				max_num = xyd.checkCondition(maxNumCanBuy == 0, 1, maxNumCanBuy),
				itemParams = {
					num = 1,
					itemID = xyd.ItemID.ACTIVITY_SPFARM_ROB_TICKET
				},
				buyCallback = function (num)
					if maxNumCanBuy <= 0 then
						xyd.showToast(__("FULL_BUY_SLOT_TIME"))

						xyd.WindowManager.get():getWindow("item_buy_window").skipClose = true

						return
					end

					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
						type = xyd.ActivitySpfarmType.BUY,
						num = num
					}))
				end,
				limitText = __("BUY_GIFTBAG_LIMIT", tostring(self.activityData.detail.buy_times) .. "/" .. tostring(xyd.tables.miscTable:getNumber("activity_spfarm_buy_max", "value")))
			})
		end
	})
end

function ActivitySpfarmMapWindow:resetCheck()
	self:updateCheckCanGetHange()

	if self.getHangAwardPanel.gameObject.activeSelf then
		self:updateGridState()
	end
end

function ActivitySpfarmMapWindow:updatePlantShow()
	if self:getIsMySelf() then
		self.plant1Con.gameObject:SetActive(true)
		self.plant2Con.gameObject:SetActive(false)
	else
		self.plant1Con.gameObject:SetActive(false)
		self.plant2Con.gameObject:SetActive(true)
	end
end

function ActivitySpfarmMapWindow:showBlackMask()
	self.blackPanel.gameObject:SetActive(true)

	local function playFun()
		xyd.SoundManager.get():playSound(xyd.SoundID.BATTLE_BLACK_IN, function ()
			xyd.SoundManager.get():playSound(xyd.SoundID.BATTLE_BLACK_OUT)
		end)
		self.blackEffect:play("texiao01", 1, 1, function ()
			self.blackEffect:destroy()
			self.blackPanel.gameObject:SetActive(false)
		end)
		self.blackEffect:startAtFrame(0)
	end

	if not self.blackEffect then
		self.blackEffect = xyd.Spine.new(self.blackEffectCon.gameObject)

		self.blackEffect:setInfo(xyd.Battle.effect_switch, function ()
			self.blackEffect:SetLocalScale(1.2, 1.2, 1)
			self.blackEffect:SetLocalPosition(10, 0, 0)
			playFun()
		end)
	else
		playFun()
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

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)
	UIEventListener.Get(self.cardItemBaseBg.gameObject).onClick = handler(self, self.onTouch)
	UIEventListener.Get(self.cardItemBaseBg.gameObject).onLongPress = handler(self, self.onTouchLong)
end

function MapGridItem:getUIComponent()
	local row = math.ceil(self.gridId / 5)
	self.depthNum = row * 15
	self.goUIWidget = self.go:GetComponent(typeof(UIWidget))
	self.goUIWidget.depth = 200 + self.depthNum
	self.cardItemBaseBg = self.go:ComponentByName("cardItemBaseBg", typeof(UISprite))
	self.cardItemBaseBg.depth = self.goUIWidget.depth
	self.cardItemBg = self.go:ComponentByName("cardItemBg", typeof(UISprite))
	self.cardItemBg.depth = self.goUIWidget.depth + 1
	self.cardItemMask = self.go:ComponentByName("cardItemMask", typeof(UISprite))
	self.cardItemMask.depth = self.goUIWidget.depth + 2
	self.stoneEffectCon = self.go:ComponentByName("stoneEffectCon", typeof(UITexture))
	self.doorEffectCon = self.go:ComponentByName("doorEffectCon", typeof(UITexture))
end

function MapGridItem:getGridId()
	return self.gridId
end

function MapGridItem:onTouchLong()
	if self.parent.activityData and self.parent.activityData:getEndTime() <= xyd.getServerTime() then
		xyd.alertTips(__("ACTIVITY_END_YET"))

		return
	end

	if self.parent:getMoving() then
		return
	end

	if self.state == PLACE_STATE.BUILD and self.parent:getIsMySelf() then
		self.parent:openMove(self.gridId, xyd.ActivitySpfarmOpenMoveType.MAP_LONG_BUILF)
	end
end

function MapGridItem:onTouch()
	if self.parent.activityData and self.parent.activityData:getEndTime() <= xyd.getServerTime() then
		xyd.alertTips(__("ACTIVITY_END_YET"))

		return
	end

	if self.parent:getMoving() then
		if self.parent:getMoving() == self.gridId then
			self.parent:closeMove()

			return
		end

		if self.gridId == self.activityData:getDoorPos() then
			xyd.alertTips(__("ACTIVITY_SPFARM_TEXT33"))

			return
		end

		local function sendFun(pos1, pos2)
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
				type = xyd.ActivitySpfarmType.MOVE,
				pos1 = pos1,
				pos2 = pos2
			}))
		end

		if xyd.arrayIndexOf(self.activityData:getDoorRoundIds(), self.gridId) > 0 then
			local tipsStr = __("ACTIVITY_SPFARM_TEXT32")
			local movingPartners = self.activityData:getBuildBaseInfo(self.parent:getMoving()).partners

			if movingPartners and #movingPartners > 0 then
				tipsStr = __("ACTIVITY_SPFARM_TEXT34")
			else
				tipsStr = __("ACTIVITY_SPFARM_TEXT32")
			end

			xyd.alertYesNo(tipsStr, function (yes_no)
				if yes_no then
					sendFun(self.parent:getMoving(), self.gridId)
				end
			end)
		else
			local tipsStr = __("ACTIVITY_SPFARM_TEXT32")

			if xyd.arrayIndexOf(self.activityData:getDoorRoundIds(), self.parent:getMoving()) > 0 then
				local partners = nil

				if self.activityData:getMyMap()[self.gridId] > 0 then
					partners = self.activityData:getBuildBaseInfo(self.gridId).partners
				end

				if partners and #partners > 0 then
					tipsStr = __("ACTIVITY_SPFARM_TEXT34")
				else
					tipsStr = __("ACTIVITY_SPFARM_TEXT32")
				end
			else
				tipsStr = __("ACTIVITY_SPFARM_TEXT32")
			end

			xyd.alertYesNo(tipsStr, function (yes_no)
				if yes_no then
					sendFun(self.parent:getMoving(), self.gridId)
				end
			end)
		end

		return
	end

	if self.state == PLACE_STATE.EMPTY then
		if self.parent:getIsMySelf() then
			xyd.WindowManager.get():openWindow("activity_spfarm_build_window", {
				type = xyd.ActivitySpfarmBuildWindowType.BUILD,
				pos = self.gridId
			})
		end
	elseif self.state == PLACE_STATE.BUILD then
		if self.parent:getIsMySelf() then
			xyd.WindowManager.get():openWindow("activity_spfarm_build_up_window", {
				gridId = self.gridId
			})
		elseif self.personCon and self.personCon.activeSelf then
			print("點擊攻打敵人")
			xyd.WindowManager.get():openWindow("battle_formation_spfarm_window", {
				showSkip = false,
				spfarm_type = xyd.ActivitySpfarmOpenBattleFormationType.BATTLE,
				battleType = xyd.BattleType.ACTIVITY_SPFARM,
				gridId = self.gridId
			})
		else
			if self.tipsCon and self.tipsCon.gameObject.activeSelf then
				local robBuildInfo = self.activityData:getRobBuildBaseInfo(self.gridId)
				local outCome = xyd.tables.activitySpfarmBuildingTable:getOutcome(robBuildInfo.build_id)
				local canGetMisc = xyd.tables.miscTable:getNumber("activity_spfarm_invase_amount", "value")
				local canGetNum = math.floor(outCome[2] * robBuildInfo.lv * canGetMisc)

				if self.activityData:getTypeBuildLimitNum(xyd.ActivitySpfarmPlicyType.ROOT_NUM) <= #self.activityData:getSlotsRob() then
					xyd.alertConfirm(__("ACTIVITY_SPFARM_TEXT62"), nil, __("SURE"))

					return
				end

				local function sendFun()
					if self.parent:getIsSetBacking() then
						xyd.alertTips(__("ACTIVITY_SPFARM_TEXT65"))

						return
					end

					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
						type = xyd.ActivitySpfarmType.OCCUPY,
						id = robBuildInfo.id
					}))
				end

				local timeStamp = xyd.db.misc:getValue("actiivty_spfarm_build_occupy_time_stamp")
				timeStamp = timeStamp and tonumber(timeStamp)

				if not timeStamp or timeStamp < self.activityData:startTime() or self.activityData:getEndTime() < timeStamp then
					local params = {
						type = "actiivty_spfarm_build_occupy",
						wndType = self.curWindowType_,
						text = __("ACTIVITY_SPFARM_TEXT61", canGetNum, xyd.tables.itemTable:getName(outCome[1])),
						callback = function ()
							sendFun()
						end,
						labelNeverText = __("ACTIVITY_SPFARM_TEXT30")
					}

					if xyd.Global.lang == "de_de" then
						params.tipsHeight = 100
						params.tipsTextY = 45
						params.groupChooseY = -34
					elseif xyd.Global.lang == "fr_fr" then
						params.tipsHeight = 100
						params.tipsTextY = 45
						params.groupChooseY = -30
					end

					xyd.openWindow("gamble_tips_window", params)

					return
				else
					sendFun()
				end

				return
			end

			local robBuildInfo = self.activityData:getRobBuildBaseInfo(self.gridId)
			local defense = xyd.tables.activitySpfarmBuildingTable:getDefense(robBuildInfo.build_id)

			if defense and defense > 0 then
				local name = xyd.tables.activitySpfarmBuildingTextTable:getName(robBuildInfo.build_id)

				xyd.alertTips(__("ACTIVITY_SPFARM_TEXT56", name))
			end
		end
	elseif self.state == PLACE_STATE.DOOR then
		if self.parent:getIsMySelf() then
			xyd.WindowManager.get():openWindow("spfarm_policy_window", {})
		else
			local slotsRob = xyd.cloneTable(self.activityData:getSlotsRob())
			local maxBackNum = self.activityData:getTypeBuildLimitNum(xyd.ActivitySpfarmPlicyType.ROOT_NUM)

			if maxBackNum > #slotsRob and not self.activityData:isGridAllEmpty() then
				xyd.alertYesNo(__("ACTIVITY_SPFARM_TEXT60"), function (yes_no)
					if yes_no then
						self.activityData:endRob()
					end
				end)

				return
			end

			local timeStamp = xyd.db.misc:getValue("actiivty_spfarm_build_end_rob_time_stamp")
			timeStamp = timeStamp and tonumber(timeStamp)

			if not timeStamp or timeStamp < self.activityData:startTime() or self.activityData:getEndTime() < timeStamp then
				xyd.openWindow("gamble_tips_window", {
					type = "actiivty_spfarm_build_end_rob",
					wndType = self.curWindowType_,
					text = __("ACTIVITY_SPFARM_TEXT58"),
					callback = function ()
						self.activityData:endRob()
					end,
					labelNeverText = __("ACTIVITY_SPFARM_TEXT30")
				})

				return
			else
				self.activityData:endRob()
			end
		end
	elseif self.state == PLACE_STATE.NOT_OPEN and not self.parent:getIsMySelf() then
		if self.cardItemMask.gameObject.activeSelf then
			xyd.alertTips(__("ACTIVITY_SPFARM_TEXT54"))
		elseif self.noClickCon and self.noClickCon.gameObject.activeSelf then
			xyd.alertTips(__("ACTIVITY_SPFARM_TEXT55"))
		else
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
				type = xyd.ActivitySpfarmType.EXPLORE,
				pos = self.gridId
			}))
		end
	end
end

function MapGridItem:updateState(state)
	self.state = state
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)

	self:setDoorConVisible(false)
	self:setBuildConVisible(false)
	self:setSelectConVisible(false)
	self:setPersonConVisible(false)

	if self.parent:getIsMySelf() then
		self.cardItemMask.gameObject:SetActive(false)
		self:setNoClickConVisible(false)
	end

	if state ~= PLACE_STATE.EMPTY then
		self.cardItemBg.gameObject:SetActive(true)
	end

	if state == PLACE_STATE.EMPTY then
		self.cardItemBg.gameObject:SetActive(false)
	elseif state == PLACE_STATE.DOOR then
		self:setDoorConVisible(true)

		local famousNum = self.parent:getFamousNum()
		self.doorLabel.text = tostring(famousNum)
		local famousLevelArr = xyd.tables.miscTable:split2num("activity_spfarm_gate_style", "value", "|")

		for i = #famousLevelArr, 1, -1 do
			if famousLevelArr[i] <= famousNum then
				local imgStr = "activity_spfarm_gate_3"

				if i == 2 then
					imgStr = "activity_spfarm_gate_2"
				elseif i == 1 then
					imgStr = "activity_space_explore_bg_m_1"
				end

				xyd.setUISpriteAsync(self.cardItemBg, nil, imgStr)

				break
			end
		end

		if self.parent:getIsMySelf() then
			if self.effectDoor then
				self.effectDoor:SetActive(false)
			end

			self.doorLabelBg.gameObject:SetActive(true)

			if self.effectDoor then
				self.effectDoor:SetActive(false)
			end

			if self.activityData:checkCanAddPolicy() then
				if not self.policyEffectDoor then
					self.policyEffectDoor = xyd.Spine.new(self.doorEffect.gameObject)

					self.policyEffectDoor:setInfo("fx_spfarm_gate_upgrade", function ()
						self.policyEffectDoor:play("texiao01", 0)
					end)
				else
					self.policyEffectDoor:SetActive(true)
				end
			elseif self.policyEffectDoor then
				self.policyEffectDoor:SetActive(false)
			end
		else
			if self.policyEffectDoor then
				self.policyEffectDoor:SetActive(false)
			end

			local slotsRob = xyd.cloneTable(self.activityData:getSlotsRob())
			local maxBackNum = self.activityData:getTypeBuildLimitNum(xyd.ActivitySpfarmPlicyType.ROOT_NUM)

			if maxBackNum <= #slotsRob or self.activityData:checkPartnerRobAllDie() or self.activityData:isGridAllEmpty() then
				if not self.effectDoor then
					self.effectDoor = xyd.Spine.new(self.doorEffect.gameObject)

					self.effectDoor:setInfo("fx_spfarm_gate_exit", function ()
						self.effectDoor:play("texiao01", 0)
					end)
				else
					self.effectDoor:SetActive(true)
				end
			elseif self.effectDoor then
				self.effectDoor:SetActive(false)
			end

			self.doorLabelBg.gameObject:SetActive(false)
		end
	elseif state == PLACE_STATE.BUILD then
		if self.parent:getIsMySelf() then
			local buildInfo = self.activityData:getBuildBaseInfo(self.gridId)

			self:setBuildConVisible(true)

			local buildImg = xyd.tables.activitySpfarmBuildingTable:getIcon(buildInfo.build_id)
			local buildType = xyd.tables.activitySpfarmBuildingTable:getType(buildInfo.build_id)

			xyd.setUISpriteAsync(self.cardItemBg, nil, "activity_spfarm_bg_" .. buildType)
			xyd.setUISpriteAsync(self.buildImg, nil, buildImg)

			self.buildLevLabel.text = "Lv." .. buildInfo.lv

			if xyd.Global.lang == "fr_fr" then
				self.buildLevLabel.text = "Niv." .. buildInfo.lv
			end

			if self.parent:getMoving() and self.parent:getMoving() == self.gridId then
				self:setSelectConVisible(true)
			end

			if buildInfo.items then
				if not self.parent.getHangAwardPanel.gameObject.activeSelf then
					self.parent:resetCheck()
				end

				for key, value in pairs(buildInfo.items) do
					self.tipsCon:SetActive(true)
					self.tipsFsIcon.gameObject:SetActive(false)
					self.tipsGetIcon.gameObject:SetActive(true)
					self.tipsGetLabel.gameObject:SetActive(true)

					self.tipsGetLabel.text = tostring(xyd.getRoughDisplayNumber(value))

					xyd.setUISpriteAsync(self.tipsGetIcon, nil, xyd.tables.itemTable:getIcon(key), function ()
						self.tipsGetIcon:SetLocalScale(0.55, 0.55, 0.55)
					end, nil, true)
				end
			elseif buildInfo.partners and #buildInfo.partners > 0 then
				self.tipsCon:SetActive(true)
				self.tipsFsIcon.gameObject:SetActive(true)
				self.tipsGetIcon.gameObject:SetActive(false)
				self.tipsGetLabel.gameObject:SetActive(false)
			else
				self.tipsCon:SetActive(false)
			end
		else
			local function showRobBuildImg(robBuildInfo)
				self:setBuildConVisible(true)
				self.tipsCon:SetActive(false)

				local buildImg = xyd.tables.activitySpfarmBuildingTable:getIcon(robBuildInfo.build_id)
				local buildType = xyd.tables.activitySpfarmBuildingTable:getType(robBuildInfo.build_id)

				xyd.setUISpriteAsync(self.cardItemBg, nil, "activity_spfarm_bg_" .. buildType)
				xyd.setUISpriteAsync(self.buildImg, nil, buildImg)

				self.buildLevLabel.text = "Lv." .. robBuildInfo.lv

				if xyd.Global.lang == "fr_fr" then
					self.buildLevLabel.text = "Niv." .. robBuildInfo.lv
				end

				if robBuildInfo.is_rob and robBuildInfo.is_rob == 1 then
					return
				end

				local outCome = xyd.tables.activitySpfarmBuildingTable:getOutcome(robBuildInfo.build_id)

				if outCome and #outCome > 0 then
					self.tipsCon:SetActive(true)
					self.tipsFsIcon.gameObject:SetActive(false)
					self.tipsGetIcon.gameObject:SetActive(true)
					self.tipsGetLabel.gameObject:SetActive(true)

					local canGetMisc = xyd.tables.miscTable:getNumber("activity_spfarm_invase_amount", "value")
					self.tipsGetLabel.text = tostring(xyd.getRoughDisplayNumber(outCome[2] * robBuildInfo.lv * canGetMisc))

					xyd.setUISpriteAsync(self.tipsGetIcon, nil, xyd.tables.itemTable:getIcon(outCome[1]), function ()
						self.tipsGetIcon:SetLocalScale(0.55, 0.55, 0.55)
					end, nil, true)
				end
			end

			local robBuildInfo = self.activityData:getRobBuildBaseInfo(self.gridId)

			if robBuildInfo.is_rob and robBuildInfo.is_rob == 1 then
				self.cardItemBg.gameObject:SetActive(true)
				showRobBuildImg(robBuildInfo)
			elseif robBuildInfo.partners and #robBuildInfo.partners > 0 then
				local allEnemyHp = -1

				for i, partnerInfo in pairs(robBuildInfo.partners) do
					if partnerInfo.status and partnerInfo.status.hp then
						allEnemyHp = 0

						break
					end
				end

				for i, partnerInfo in pairs(robBuildInfo.partners) do
					if partnerInfo.status and partnerInfo.status.hp then
						allEnemyHp = allEnemyHp + partnerInfo.status.hp
					end
				end

				local function showPerson()
					local modelId = xyd.tables.partnerTable:getModelID(robBuildInfo.partners[1].table_id)
					local modelName = xyd.tables.modelTable:getModelName(modelId)
					local modelScale = xyd.tables.modelTable:getScale(modelId)

					if self.personEffect_spine then
						self.personEffect_spine:destroy()
					end

					self.personEffect_spine = xyd.Spine.new(self.personEffect.gameObject)

					self.personEffect_spine:setInfo(modelName, function ()
						self.personEffect_spine:setRenderTarget(self.personEffect, math.floor((self.gridId - 1) % 5))
						self.personEffect_spine:play("idle", 0)
						self.personEffect_spine:SetLocalScale(modelScale, modelScale, modelScale)
					end)
				end

				if allEnemyHp == -1 then
					self:setPersonConVisible(true)
					showPerson()

					self.hpProgress.value = 1

					self.cardItemBg.gameObject:SetActive(false)
				elseif allEnemyHp > 0 then
					self:setPersonConVisible(true)
					showPerson()

					self.hpProgress.value = allEnemyHp / (#robBuildInfo.partners * 100)

					self.cardItemBg.gameObject:SetActive(false)
				elseif allEnemyHp == 0 then
					self.cardItemBg.gameObject:SetActive(true)
					showRobBuildImg(robBuildInfo)
				end
			else
				self.cardItemBg.gameObject:SetActive(true)
				showRobBuildImg(robBuildInfo)
			end
		end
	elseif state == PLACE_STATE.NOT_OPEN then
		local default_img_id = math.ceil(math.random() * 4)

		xyd.setUISpriteAsync(self.cardItemBg, nil, "activity_space_explore_grid_" .. default_img_id, nil, )
	end
end

function MapGridItem:getState()
	return self.state
end

function MapGridItem:setChildrenDepth(go)
	local depth = self.goUIWidget.depth

	for i = 1, go.transform.childCount do
		local child = go.transform:GetChild(i - 1).gameObject
		local widget = child:GetComponent(typeof(UIWidget))

		if widget then
			widget.depth = depth + widget.depth
		end

		if child.transform.childCount > 0 then
			self:setChildrenDepth(child, depth)
		end
	end
end

function MapGridItem:setMaskState(state)
	self.cardItemMask.gameObject:SetActive(state)
end

function MapGridItem:getDoorCon()
	if not self.doorCon then
		self.doorCon = NGUITools.AddChild(self.go.gameObject, self.parent.cardItem_doorLabelCon.gameObject)
		self.doorLabelBg = self.doorCon:ComponentByName("doorLabelBg", typeof(UISprite))
		self.doorLabel = self.doorLabelBg:ComponentByName("doorLabel", typeof(UILabel))
		self.doorEffect = self.doorCon:ComponentByName("doorEffect", typeof(UITexture))

		self:setChildrenDepth(self.doorCon)
	end

	return self.doorCon
end

function MapGridItem:setDoorConVisible(visible)
	if visible and not self.doorCon then
		self:getDoorCon()
	end

	if self.doorCon then
		self.doorCon:SetActive(visible)
	end
end

function MapGridItem:getBuildCon()
	if not self.buildCon then
		self.buildCon = NGUITools.AddChild(self.go.gameObject, self.parent.cardItem_buildCon.gameObject)
		self.buildImg = self.buildCon:ComponentByName("buildImg", typeof(UISprite))
		self.buildLevLabel = self.buildCon:ComponentByName("buildLevLabel", typeof(UILabel))
		self.tipsCon = self.buildCon:ComponentByName("tipsCon", typeof(UISprite))
		self.tipsFsIcon = self.tipsCon:ComponentByName("tipsFsIcon", typeof(UISprite))
		self.tipsGetIcon = self.tipsCon:ComponentByName("tipsGetIcon", typeof(UISprite))
		self.tipsGetLabel = self.tipsCon:ComponentByName("tipsGetLabel", typeof(UILabel))

		self:setChildrenDepth(self.buildCon)
	end

	return self.buildCon
end

function MapGridItem:getBuildTipsIcon()
	return self.tipsGetIcon
end

function MapGridItem:setBuildConVisible(visible)
	if visible and not self.buildCon then
		self:getBuildCon()
	end

	if self.buildCon then
		self.buildCon:SetActive(visible)
	end
end

function MapGridItem:getSelectCon()
	if not self.selectCon then
		self.selectCon = NGUITools.AddChild(self.go.gameObject, self.parent.cardItem_selectCon.gameObject)

		self:setChildrenDepth(self.selectCon)
	end

	return self.selectCon
end

function MapGridItem:setSelectConVisible(visible)
	if visible and not self.selectCon then
		self:getSelectCon()
	end

	if self.selectCon then
		self.selectCon:SetActive(visible)
	end
end

function MapGridItem:getNoClickCon()
	if not self.noClickCon then
		self.noClickCon = NGUITools.AddChild(self.go.gameObject, self.parent.cardItem_noClickCon.gameObject)

		self:setChildrenDepth(self.noClickCon)
	end

	return self.noClickCon
end

function MapGridItem:setNoClickConVisible(visible)
	if visible and not self.noClickCon then
		self:getNoClickCon()
	end

	if self.noClickCon then
		self.noClickCon:SetActive(visible)
	end
end

function MapGridItem:getPersonCon()
	if not self.personCon then
		self.personCon = NGUITools.AddChild(self.go.gameObject, self.parent.cardItem_personCon.gameObject)
		self.personEffect = self.personCon:ComponentByName("personEffect", typeof(UITexture))
		self.hpProgress = self.personCon:ComponentByName("hpProgress", typeof(UIProgressBar))

		self:setChildrenDepth(self.personCon)
	end

	return self.personCon
end

function MapGridItem:setPersonConVisible(visible)
	if visible and not self.personCon then
		self:getPersonCon()
	end

	if self.personCon then
		self.personCon:SetActive(visible)
	end
end

function BackContentItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)
	self.backItemBg = self.go:ComponentByName("backItemBg", typeof(UISprite))
	self.backItemClose = self.go:ComponentByName("backItemClose", typeof(UISprite))

	UIEventListener.Get(self.backItemClose.gameObject).onClick = function ()
		if self.parent:getIsSetBacking() then
			xyd.alertTips(__("ACTIVITY_SPFARM_TEXT65"))

			return
		end

		xyd.alertYesNo(__("ACTIVITY_SPFARM_TEXT59"), function (yes_no)
			if yes_no then
				local slotsRob = self.activityData:getSlotsRob()
				local index = nil

				for i, id in pairs(slotsRob) do
					if id == self.id then
						index = i

						break
					end
				end

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
					type = xyd.ActivitySpfarmType.REMOVE_AWARD,
					index = index
				}))
			end
		end)
	end
end

function BackContentItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.id = info.id
	self.curIndex = info.curIndex

	if self.id > 0 then
		local robBuildInfo = self.activityData:getRobBuildBaseInfoWithId(self.id)
		local outCome = xyd.tables.activitySpfarmBuildingTable:getOutcome(robBuildInfo.build_id)
		local canGetMisc = xyd.tables.miscTable:getNumber("activity_spfarm_invase_amount", "value")
		local canGetNum = math.floor(outCome[2] * robBuildInfo.lv * canGetMisc)
		local params = {
			isAddUIDragScrollView = true,
			isShowSelected = false,
			uiRoot = self.backItemBg.gameObject,
			itemID = outCome[1],
			num = canGetNum
		}

		if not self.icon then
			self.icon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		else
			self.icon:SetActive(true)
			self.icon:setInfo(params)
		end

		self.icon:setScale(0.6944444444444444)
		self.backItemClose.gameObject:SetActive(true)
	else
		if self.icon then
			self.icon:SetActive(false)
		end

		self.backItemClose.gameObject:SetActive(false)
	end
end

function BackContentItem:getGameObject()
	return self.go
end

function BackContentItem:getBgIcon()
	return self.backItemBg
end

function BackContentItem:getCurIndex()
	return self.curIndex
end

return ActivitySpfarmMapWindow
