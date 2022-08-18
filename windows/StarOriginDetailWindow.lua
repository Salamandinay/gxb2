local StarOriginDetailWindow = class("StarOriginDetailWindow", import(".BaseWindow"))
local starNodeItem = class("starNodeItem", import("app.components.CopyComponent"))
local WindowTop = import("app.components.WindowTop")

function StarOriginDetailWindow:ctor(name, params)
	self.curSelectNodeTableID = 0
	self.curSelectNodeItem = nil
	self.fakeLev = {}
	self.fakeUseRes = {}

	StarOriginDetailWindow.super.ctor(self, name, params)

	self.partnerID = params.partnerID
	self.isQuickFormation = params.isQuickFormation
	self.starImgNameByState = {
		"star_origin_bg_xy_sj_zh",
		"star_origin_bg_xy_sj_kq",
		"star_origin_bg_xy_sj_dl"
	}
	self.lineImgNameByState = {
		"star_origin_bg_xy_sj_zh_1",
		"star_origin_bg_xy_sj_kq_1",
		"star_origin_bg_xy_sj_dl_1"
	}
end

function StarOriginDetailWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function StarOriginDetailWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.groupAction = groupAction
	self.Bg = self.groupAction:ComponentByName("Bg", typeof(UISprite))
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.btnHelp = self.groupAction:NodeByName("btnHelp").gameObject
	self.btnReset = self.groupAction:NodeByName("btnReset").gameObject
	self.mainContent = self.groupAction:NodeByName("mainContent").gameObject
	self.item = self.mainContent:NodeByName("item").gameObject
	self.imgGroupObj = self.mainContent:NodeByName("imgGroup").gameObject
	self.imgGroup = self.mainContent:ComponentByName("imgGroup", typeof(UISprite))
	self.levelUpGroup = self.groupAction:NodeByName("levelUpGroup").gameObject
	self.bgLevelGroupObj = self.levelUpGroup:NodeByName("bgLevelGroup").gameObject
	self.bgLevelGroup = self.levelUpGroup:ComponentByName("bgLevelGroup", typeof(UISprite))
	self.labelName = self.levelUpGroup:ComponentByName("labelName", typeof(UILabel))
	self.labelLevel = self.levelUpGroup:ComponentByName("labelLevel", typeof(UILabel))
	self.levelUpEffectPos = self.levelUpGroup:ComponentByName("effectPos", typeof(UITexture))
	self.descGroup = self.levelUpGroup:NodeByName("descGroup").gameObject
	self.descGroup_Layout = self.levelUpGroup:ComponentByName("descGroup", typeof(UILayout))
	self.descGroup1 = self.descGroup:NodeByName("descGroup1").gameObject
	self.descGroup2 = self.descGroup:NodeByName("descGroup2").gameObject
	self.descGroup3 = self.descGroup:NodeByName("descGroup3").gameObject
	self.labelTip = self.descGroup:ComponentByName("labelTip", typeof(UILabel))
	self.costGroup = self.levelUpGroup:NodeByName("costGroup").gameObject
	self.bgCostGroupObj = self.costGroup:NodeByName("bgCostGroup").gameObject
	self.bgCostGroup = self.costGroup:ComponentByName("bgCostGroup", typeof(UISprite))
	self.resGroup1 = self.costGroup:NodeByName("resGroup1").gameObject
	self.labelRes1Num = self.resGroup1:ComponentByName("labelNum", typeof(UILabel))
	self.iconRes1 = self.resGroup1:ComponentByName("icon", typeof(UISprite))
	self.resGroup2 = self.costGroup:NodeByName("resGroup2").gameObject
	self.labelRes2Num = self.resGroup2:ComponentByName("labelNum", typeof(UILabel))
	self.iconRes2 = self.resGroup2:ComponentByName("icon", typeof(UISprite))
	self.btnLevelUp = self.levelUpGroup:NodeByName("btnLevelUp").gameObject
	self.labelLevelUp = self.btnLevelUp:ComponentByName("labelLevelUp", typeof(UILabel))
	self.mask = self.groupAction:NodeByName("mask").gameObject
end

function StarOriginDetailWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.UPGRADE_STAR_ORIGIN, function (event)
		self:onGetMsgLevelUp(event)
	end)
	self.eventProxy_:addEventListener(xyd.event.RESET_STAR_ORIGIN, function (event)
		self:onGetMsgReset(event)
	end)

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "STAR_ORIGIN_HELP"
		})
	end

	UIEventListener.Get(self.btnLevelUp).onClick = function ()
		self:onclickBtnLevelUp()
	end

	UIEventListener.Get(self.btnReset).onClick = function ()
		if self.isQuickFormation then
			xyd.alertTips(__("QUICK_FORMATION_TEXT02"))

			return
		end

		self:reset()
	end

	UIEventListener.Get(self.btnLevelUp).onPress = handler(self, self.onLongTouchBtnLevleUp)
end

function StarOriginDetailWindow:layout()
	self.partner = xyd.models.slot:getPartner(self.partnerID)
	self.group = self.partner:getGroup()
	self.partnerTableID = self.partner:getTableID()
	self.listTableID = xyd.tables.partnerTable:getStarOrigin(self.partnerTableID)
	local starIDs = xyd.tables.starOriginListTable:getNode(self.listTableID)

	for i = 1, #starIDs do
		self.fakeLev[i] = 0
	end

	self.labelTitle.text = __("STAR_ORIGIN_TEXT03")
	self.btnLevelUp:ComponentByName("labelLevelUp", typeof(UILabel)).text = __("STAR_ORIGIN_TEXT05")

	if self.group == 7 then
		xyd.setUISpriteAsync(self.imgGroup, nil, xyd.tables.partnerGroup7Table:getStarOriginImg2(self.partnerTableID))
	else
		xyd.setUISpriteAsync(self.imgGroup, nil, xyd.tables.groupTable:getStarOriginImg2(self.group))
	end

	self:initStarGroup()
	self:updateLevelUpGroup()

	self.winTop = WindowTop.new(self.window_, self.name_, 1, false)
	local items = {
		{
			id = 359
		},
		{
			id = 360
		}
	}

	self.winTop:setItem(items)
	self.winTop:hideBg()

	if not self.firstInit then
		self.firstInit = true
		self.curSelectNodeItem = self.nodeItems[1]

		self:selectNode(starIDs[1])
	end
end

function StarOriginDetailWindow:initStarGroup()
	local starIDs = xyd.tables.starOriginListTable:getNode(self.listTableID)
	local nodeType = xyd.tables.starOriginListTable:getNodeType(self.listTableID)

	for i = 1, #starIDs do
		local nodeTableID = starIDs[i]
		local state = 0
		local lev = self:getLev(nodeTableID)
		local nodeGroup = xyd.tables.starOriginNodeTable:getOriginGroup(nodeTableID)
		local preNodeTableID = xyd.tables.starOriginNodeTable:getPreId(nodeTableID)
		local preNodeNeedLev = xyd.tables.starOriginNodeTable:getPreLv(nodeTableID)

		if preNodeTableID and preNodeTableID > 0 then
			local preNodeLev = self:getLev(preNodeTableID)

			if preNodeNeedLev <= preNodeLev then
				if lev > 0 then
					local beginID = xyd.tables.starOriginListTable:getStarIDs(self.listTableID)[i]
					local starOriginTableID = xyd.tables.starOriginTable:getIdByBeginIDAndLev(beginID, lev)
					local nextID = xyd.tables.starOriginTable:getNextId(starOriginTableID)

					if not nextID or nextID < 1 then
						state = 3
					else
						state = 2
					end
				else
					state = 2
				end
			else
				state = 1
			end
		elseif lev > 0 then
			local beginID = xyd.tables.starOriginListTable:getStarIDs(self.listTableID)[i]
			local starOriginTableID = xyd.tables.starOriginTable:getIdByBeginIDAndLev(beginID, lev)
			local nextID = xyd.tables.starOriginTable:getNextId(starOriginTableID)

			if not nextID or nextID < 1 then
				state = 3
			else
				state = 2
			end
		else
			state = 2
		end

		if not self.nodeItems then
			self.nodeItems = {}
		end

		if not self.nodeItems[i] then
			local tmp = NGUITools.AddChild(self.mainContent.gameObject, self.item)
			local item = starNodeItem.new(tmp, self)
			self.nodeItems[i] = item
		end

		self.nodeItems[i]:setInfo({
			nodeTableID = nodeTableID,
			lev = lev,
			state = state
		})
	end

	if nodeType and nodeType[1] and nodeType[2] then
		local allUnlock = true

		for i = 1, #starIDs do
			if self.nodeItems[i].state <= 1 then
				allUnlock = false
			end
		end

		if allUnlock then
			local state = 2

			if self.nodeItems[nodeType[2]].lev > 0 then
				state = 3
			end

			self.nodeItems[nodeType[1]]:setLineByPreNodeID(starIDs[nodeType[2]], state)
		end
	end
end

function StarOriginDetailWindow:updateLevelUpGroup()
	if not self.curSelectNodeTableID or self.curSelectNodeTableID == 0 then
		return
	end

	local beginID = xyd.tables.starOriginListTable:getStarIDByNodeID(self.listTableID, self.curSelectNodeTableID)
	local nodeGroup = xyd.tables.starOriginNodeTable:getOriginGroup(self.curSelectNodeTableID)
	local maxLev = xyd.tables.starOriginTable:getMaxLevByBeginID(beginID)
	local lev = self:getLev(self.curSelectNodeTableID)
	local strList = string.split(__("STAR_ORIGIN_TEXT08"), "|")
	self.labelName.text = strList[self:getIndexByNodeID(self.curSelectNodeTableID)]
	self.labelLevel.text = "lv." .. lev .. "/" .. maxLev

	if xyd.Global.lang == "fr_fr" then
		self.labelLevel.text = "Niv." .. lev .. "/" .. maxLev
	end

	local state = self.curSelectNodeItem.state

	if state == 1 then
		local preNodeTableID = xyd.tables.starOriginNodeTable:getPreId(self.curSelectNodeTableID)
		local preNodeNeedLev = xyd.tables.starOriginNodeTable:getPreLv(self.curSelectNodeTableID)
		self.labelTip.text = __("STAR_ORIGIN_TEXT04", preNodeNeedLev)

		self.btnLevelUp:SetActive(false)
		self.labelTip:SetActive(true)
	elseif state == 2 then
		self.labelTip:SetActive(false)
		self.btnLevelUp:SetActive(true)
	elseif state == 3 then
		self.labelTip:SetActive(false)
		self.btnLevelUp:SetActive(false)
	end

	local starOriginTableID = xyd.tables.starOriginTable:getIdByBeginIDAndLev(beginID, math.min(lev + 1, maxLev))
	local effects = xyd.tables.starOriginTable:getEffect(starOriginTableID)

	for i = 1, 3 do
		self["descGroup" .. i]:SetActive(false)
	end

	for i = 1, #effects do
		local labelDesc_ = self["descGroup" .. i]:ComponentByName("labelAttr", typeof(UILabel))
		labelDesc_.text = xyd.tables.dBuffTable:getDesc(effects[i][1])
		local labelOldValue_ = self["descGroup" .. i]:ComponentByName("labelOldValue", typeof(UILabel))
		local labelNewValue_ = self["descGroup" .. i]:ComponentByName("labelNewValue", typeof(UILabel))
		local img_ = self["descGroup" .. i]:ComponentByName("img", typeof(UISprite))
		local factor = xyd.tables.dBuffTable:getFactor(effects[i][1])

		if lev <= 0 then
			if xyd.tables.dBuffTable:isPercent(effects[i][1]) then
				labelOldValue_.text = "0%"
				labelNewValue_.text = string.format("%.1f", effects[i][2] * 100) .. "%"
			elseif factor and factor > 0 then
				labelOldValue_.text = "0%"
				labelNewValue_.text = string.format("%.1f", effects[i][2] * 100 / factor) .. "%"
			else
				labelOldValue_.text = 0
				labelNewValue_.text = effects[i][2]
			end

			img_:SetActive(true)
			labelNewValue_:SetActive(true)
		elseif maxLev <= lev then
			if xyd.tables.dBuffTable:isPercent(effects[i][1]) then
				labelOldValue_.text = string.format("%.1f", effects[i][2] * 100) .. "%"
			elseif factor and factor > 0 then
				labelOldValue_.text = string.format("%.1f", effects[i][2] * 100 / factor) .. "%"
			else
				labelOldValue_.text = effects[i][2]
			end

			img_:SetActive(false)
			labelNewValue_:SetActive(false)
		else
			local beginID = xyd.tables.starOriginListTable:getStarIDByNodeID(self.listTableID, self.curSelectNodeTableID)
			local oldStarOriginTableID = xyd.tables.starOriginTable:getIdByBeginIDAndLev(beginID, math.min(lev, maxLev))
			local oldEffects = xyd.tables.starOriginTable:getEffect(oldStarOriginTableID)

			if xyd.tables.dBuffTable:isPercent(effects[i][1]) then
				labelOldValue_.text = string.format("%.1f", oldEffects[i][2] * 100) .. "%"
				labelNewValue_.text = string.format("%.1f", effects[i][2] * 100) .. "%"
			elseif factor and factor > 0 then
				labelOldValue_.text = string.format("%.1f", oldEffects[i][2] * 100 / factor) .. "%"
				labelNewValue_.text = string.format("%.1f", effects[i][2] * 100 / factor) .. "%"
			else
				labelOldValue_.text = oldEffects[i][2]
				labelNewValue_.text = effects[i][2]
			end

			img_:SetActive(true)
			labelNewValue_:SetActive(true)
		end

		self["descGroup" .. i]:SetActive(true)
	end

	self.descGroup_Layout:Reposition()

	if state == 2 then
		self.costGroup:SetActive(true)

		local costs = xyd.tables.starOriginTable:getCost(starOriginTableID)

		for i = 1, 2 do
			if i <= #costs then
				xyd.setUISpriteAsync(self["iconRes" .. i], nil, xyd.tables.itemTable:getIcon(costs[i][1]))

				self["labelRes" .. i .. "Num"].text = costs[i][2]

				self["iconRes" .. i]:SetActive(true)
				self["labelRes" .. i .. "Num"]:SetActive(true)

				if costs[i][2] <= xyd.models.backpack:getItemNumByID(costs[i][1]) - self:getFakeUseRes(costs[i][1]) then
					self["labelRes" .. i .. "Num"].color = Color.New2(960513791)
				else
					self["labelRes" .. i .. "Num"].color = Color.New2(3422556671.0)
				end
			else
				self["iconRes" .. i]:SetActive(false)
				self["labelRes" .. i .. "Num"]:SetActive(false)
			end
		end

		if #costs == 1 then
			self.resGroup1:X(100)
		else
			self.resGroup1:X(0)
		end
	else
		self.costGroup:SetActive(false)
	end
end

function StarOriginDetailWindow:onclickBtnLevelUp()
	if not self.curSelectNodeTableID or self.curSelectNodeTableID <= 0 then
		xyd.alertTips(__("没配，请先选择"))

		self.levUpLongTouchFlag = false

		return
	end

	if self.isQuickFormation then
		xyd.alertTips(__("QUICK_FORMATION_TEXT02"))

		return
	end

	local state = self.curSelectNodeItem.state

	if state == 1 then
		local preNodeNeedLev = xyd.tables.starOriginNodeTable:getPreLv(self.curSelectNodeTableID)

		xyd.alertTips(__("STAR_ORIGIN_TEXT04", preNodeNeedLev))

		self.levUpLongTouchFlag = false

		return
	end

	if state == 3 then
		xyd.alertTips(__("没配，最大级"))

		self.levUpLongTouchFlag = false

		return
	end

	local nodeGroup = xyd.tables.starOriginNodeTable:getOriginGroup(self.curSelectNodeTableID)
	local beginID = xyd.tables.starOriginListTable:getStarIDByNodeID(self.listTableID, self.curSelectNodeTableID)
	local maxLev = xyd.tables.starOriginTable:getMaxLevByBeginID(beginID)
	local lev = self:getLev(self.curSelectNodeTableID)
	local starOriginTableID = xyd.tables.starOriginTable:getIdByBeginIDAndLev(beginID, math.min(lev + 1, maxLev))
	local costs = xyd.tables.starOriginTable:getCost(starOriginTableID)

	for i = 1, #costs do
		if xyd.models.backpack:getItemNumByID(costs[i][1]) - self:getFakeUseRes(costs[i][1]) < costs[i][2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(costs[i][1])))

			return
		end

		if not self.fakeUseRes[costs[i][1]] then
			self.fakeUseRes[costs[i][1]] = 0
		end

		self.fakeUseRes[costs[i][1]] = self.fakeUseRes[costs[i][1]] + costs[i][2]
	end

	self:showLevelUpEffect()

	local list = self.winTop:getResItemList()

	for i = 1, #list do
		local itemID = list[i]:getItemID()

		list[i]:setItemNum(xyd.models.backpack:getItemNumByID(itemID) - self:getFakeUseRes(itemID))
	end

	local index = self:getIndexByNodeID(self.curSelectNodeTableID)
	self.fakeLev[index] = self.fakeLev[index] + 1

	self:initStarGroup()
	self:updateLevelUpGroup()
end

function StarOriginDetailWindow:onLongTouchBtnLevleUp(go, isPressed)
	if self.isQuickFormation then
		return
	end

	local longTouchFunc = nil

	function longTouchFunc()
		self:onclickBtnLevelUp()

		if self.levUpLongTouchFlag == true then
			XYDCo.WaitForTime(0.05, function ()
				if not self or not go or go.activeSelf == false then
					return
				end

				longTouchFunc()
			end, "starOriginLevUpLongTouchClick")
		end
	end

	XYDCo.StopWait("starOriginLevUpLongTouchClick")

	if isPressed then
		self.levUpLongTouchFlag = true

		XYDCo.WaitForTime(0.5, function ()
			if not self then
				return
			end

			if self.levUpLongTouchFlag then
				longTouchFunc()
			end
		end, "chimeLevUpLongTouchClick")
	else
		self.levUpLongTouchFlag = false
	end
end

function StarOriginDetailWindow:reset()
	local flag = false
	local starIDs = xyd.tables.starOriginListTable:getNode(self.listTableID)

	for i = 1, #starIDs do
		local nodeTableID = starIDs[i]
		local lev = self:getLev(nodeTableID)

		if lev > 0 then
			flag = true

			break
		end
	end

	if not flag then
		xyd.showToast(__("STAR_ORIGIN_TEXT06"))

		return
	end

	local resetCost = xyd.tables.miscTable:split2Cost("star_origin_reset_cost", "value", "#")

	xyd.alertConfirm(__("STAR_ORIGIN_TEXT07"), function ()
		local selfNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL) - self:getFakeUseRes(xyd.ItemID.CRYSTAL)

		if selfNum < resetCost[2] then
			xyd.alertTips(__("NOT_ENOUGH_CRYSTAL"))
		else
			local starIDs = xyd.tables.starOriginListTable:getNode(self.listTableID)
			local flag = false

			for i = 1, #starIDs do
				if self.fakeLev[i] > 0 then
					flag = true
				end
			end

			if flag and not self.isclearingFakeLev then
				self:cleanFakeLev()

				self.isclearingFakeLev = true
				self.needReset = true
			else
				local msg = messages_pb.reset_star_origin_req()
				msg.partner_id = self.partner:getPartnerID()

				xyd.Backend.get():request(xyd.mid.RESET_STAR_ORIGIN, msg)
			end
		end
	end, __("SURE"), false, resetCost, __("GUILD_RESET"))
end

function StarOriginDetailWindow:getLev(NodeID)
	local lev = self.partner:getStarOrigin()
	local index = self:getIndexByNodeID(NodeID)

	if not self.fakeLev[index] then
		self.fakeLev[index] = 0
	end

	return self.fakeLev[index] + (lev[index] or 0)
end

function StarOriginDetailWindow:getIndexByNodeID(NodeID)
	if not self.indexByNodeID then
		self.indexByNodeID = {}
		local starIDs = xyd.tables.starOriginListTable:getNode(self.listTableID)

		for i = 1, #starIDs do
			local nodeTableID = starIDs[i]
			self.indexByNodeID[nodeTableID] = i
		end
	end

	return self.indexByNodeID[NodeID]
end

function StarOriginDetailWindow:selectNode(NodeTableID)
	self.curSelectNodeTableID = NodeTableID

	for i = 1, #self.nodeItems do
		self.nodeItems[i]:checkSelectState()
	end

	self:updateLevelUpGroup()
end

function StarOriginDetailWindow:getFakeUseRes(itemID)
	if not self.fakeUseRes[itemID] then
		self.fakeUseRes[itemID] = 0
	end

	return self.fakeUseRes[itemID]
end

function StarOriginDetailWindow:cleanFakeLev()
	local flag = false

	for i = 1, #self.fakeLev do
		if self.fakeLev[i] > 0 then
			flag = true
		end
	end

	if not flag then
		return
	end

	local msg = messages_pb:upgrade_star_origin_req()
	msg.partner_id = tonumber(self.partnerID)
	local starIDs = xyd.tables.starOriginListTable:getNode(self.listTableID)

	for i = 1, #starIDs do
		table.insert(msg.nums, self.fakeLev[i])
	end

	self.isclearingFakeLev = true

	xyd.Backend.get():request(xyd.mid.UPGRADE_STAR_ORIGIN, msg)
end

function StarOriginDetailWindow:showLevelUpEffect()
	if not self.isPlayingLevelUpEffect then
		if not self.levelUpEffect then
			self.levelUpEffectPos:SetActive(true)

			self.levelUpEffect = xyd.Spine.new(self.levelUpEffectPos.gameObject)

			self.levelUpEffect:setInfo("shetuan_shengji", function ()
				self.isPlayingLevelUpEffect = true

				self.levelUpEffect:play("texiao01", 1, 1, function ()
					self.isPlayingLevelUpEffect = false

					self.levelUpEffectPos:SetActive(false)
				end, true)
			end)
		else
			self.levelUpEffectPos:SetActive(true)

			self.isPlayingLevelUpEffect = true

			self.levelUpEffect:play("texiao01", 1, 1, function ()
				self.isPlayingLevelUpEffect = false

				self.levelUpEffectPos:SetActive(false)
			end, true)
		end
	end
end

function StarOriginDetailWindow:onGetMsgLevelUp(event)
	local data = event.data
	local starIDs = xyd.tables.starOriginListTable:getNode(self.listTableID)

	for i = 1, #starIDs do
		self.fakeLev[i] = 0
	end

	self.isclearingFakeLev = false
	self.fakeUseRes = {
		[xyd.ItemID.CRYSTAL] = 0,
		[xyd.ItemID.MANA] = 0
	}

	self.partner:updateStarOrigin(data.partner_info.star_origin)

	if self.needReset then
		local msg = messages_pb.reset_star_origin_req()
		msg.partner_id = self.partner:getPartnerID()

		xyd.Backend.get():request(xyd.mid.RESET_STAR_ORIGIN, msg)

		self.needReset = false
	end
end

function StarOriginDetailWindow:onGetMsgReset(event)
	local data = event.data
	local starIDs = xyd.tables.starOriginListTable:getNode(self.listTableID)

	for i = 1, #starIDs do
		self.fakeLev[i] = 0
	end

	self.fakeUseRes = {
		[xyd.ItemID.CRYSTAL] = 0,
		[xyd.ItemID.MANA] = 0
	}

	self.partner:updateStarOrigin(data.partner_info.star_origin)
	xyd.itemFloat(data.items)
	self:initStarGroup()
	self:updateLevelUpGroup()
end

function StarOriginDetailWindow:dispose()
	StarOriginDetailWindow.super.dispose(self)

	local starIDs = xyd.tables.starOriginListTable:getNode(self.listTableID)
	local flag = false

	for i = 1, #starIDs do
		if self.fakeLev[i] > 0 then
			flag = true
		end
	end

	if flag and not self.isclearingFakeLev then
		self:cleanFakeLev()

		self.isclearingFakeLev = true
	end
end

function starNodeItem:ctor(go, parent)
	starNodeItem.super.ctor(self, go, parent)

	self.parent = parent
	self.icons = {}
end

function starNodeItem:initUI()
	self.label = self.go:ComponentByName("label", typeof(UILabel))
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.icon = self.go:ComponentByName("icon", typeof(UISprite))
	self.chooseImg = self.icon:ComponentByName("chooseImg", typeof(UISprite))
	self.labelBg = self.go:ComponentByName("labelBg", typeof(UISprite))
	self.redPoint = self.go:ComponentByName("redPoint", typeof(UISprite))
	self.line = self.go:ComponentByName("line", typeof(UISprite))
	self.line2 = self.go:ComponentByName("line2", typeof(UISprite))

	UIEventListener.Get(self.go.gameObject).onClick = function ()
		self.parent.curSelectNodeItem = self

		self.parent:selectNode(self.nodeTableID)
	end
end

function starNodeItem:setInfo(data)
	self.state = data.state
	self.nodeTableID = data.nodeTableID
	self.lev = data.lev
	local xy = xyd.tables.starOriginNodeTable:getXy(self.nodeTableID)
	local preNodeTableID = xyd.tables.starOriginNodeTable:getPreId(self.nodeTableID)

	self.go:X(xy[1])
	self.go:Y(xy[2])

	local starImgName = self.parent.starImgNameByState[self.state]
	local lineImgName = self.parent.lineImgNameByState[self.state]

	if self.state == 2 and self.lev == 0 then
		starImgName = self.parent.starImgNameByState[2]
		lineImgName = self.parent.lineImgNameByState[2]
	elseif self.lev > 0 then
		starImgName = self.parent.starImgNameByState[3]
		lineImgName = self.parent.lineImgNameByState[3]
	end

	xyd.setUISpriteAsync(self.icon, nil, starImgName)
	xyd.setUISpriteAsync(self.line, nil, lineImgName, function ()
		if preNodeTableID and preNodeTableID > 0 then
			local preNodeXY = xyd.tables.starOriginNodeTable:getXy(preNodeTableID)

			self.line:X((preNodeXY[1] - xy[1]) / 2)
			self.line:Y((preNodeXY[2] - xy[2]) / 2)

			local angle = math.atan2(preNodeXY[2] - xy[2], preNodeXY[1] - xy[1]) * 180 / math.pi
			self.line.gameObject.transform.localEulerAngles = Vector3(0, 0, angle + 90)
			self.line.height = math.sqrt((preNodeXY[1] - xy[1]) * (preNodeXY[1] - xy[1]) + (preNodeXY[2] - xy[2]) * (preNodeXY[2] - xy[2]))

			self.line:SetActive(true)
		else
			self.line:SetActive(false)
		end
	end, nil, true)
	self:checkSelectState()

	if self.state == 2 then
		local nodeGroup = xyd.tables.starOriginNodeTable:getOriginGroup(self.nodeTableID)
		local beginID = xyd.tables.starOriginListTable:getStarIDByNodeID(self.parent.listTableID, self.nodeTableID)
		local maxLev = xyd.tables.starOriginTable:getMaxLevByBeginID(beginID)
		self.label.text = self.lev .. "/" .. maxLev

		self.label:SetActive(true)
	else
		self.label:SetActive(false)
	end

	if self.line2 then
		self.line2:SetActive(false)
	end
end

function starNodeItem:checkSelectState()
	self.chooseImg:SetActive(self.nodeTableID == self.parent.curSelectNodeTableID)
end

function starNodeItem:setLineByPreNodeID(preNodeTableID, state)
	local lineImgName = self.parent.lineImgNameByState[state]
	local xy = xyd.tables.starOriginNodeTable:getXy(self.nodeTableID)

	xyd.setUISpriteAsync(self.line2, nil, lineImgName, function ()
		local preNodeXY = xyd.tables.starOriginNodeTable:getXy(preNodeTableID)

		self.line2:X((preNodeXY[1] - xy[1]) / 2)
		self.line2:Y((preNodeXY[2] - xy[2]) / 2)

		local angle = math.atan2(preNodeXY[2] - xy[2], preNodeXY[1] - xy[1]) * 180 / math.pi
		self.line2.gameObject.transform.localEulerAngles = Vector3(0, 0, angle + 90)
		self.line2.height = math.sqrt((preNodeXY[1] - xy[1]) * (preNodeXY[1] - xy[1]) + (preNodeXY[2] - xy[2]) * (preNodeXY[2] - xy[2]))

		self.line2:SetActive(true)
	end, nil, true)
end

return StarOriginDetailWindow
