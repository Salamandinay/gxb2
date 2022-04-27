local ActivityDragonBoatAwardSelectWindow = class("ActivityDragonBoatAwardSelectWindow", import(".BaseWindow"))
local ActivityDragonBoatTable = xyd.tables.activityDragonBoatTable
local ReplaceIcon = import("app.components.ReplaceIcon")

function ActivityDragonBoatAwardSelectWindow:ctor(name, params)
	ActivityDragonBoatAwardSelectWindow.super.ctor(self, name, params)

	self.item = params.item
	self.id = self.item.id
	self.curIndex = params.index or 1
	self.exAwards = params.exAwards or {}
	self.isFree = params.isFree
	self.exAwardIndexs = {}
end

function ActivityDragonBoatAwardSelectWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:initReAward()
	self:updateCurIcon(self.curIndex)
	self:register()
end

function ActivityDragonBoatAwardSelectWindow:getUIComponent()
	local main = self.window_:NodeByName("groupAction").gameObject
	local group1 = main:NodeByName("group1").gameObject
	self.closeBtn = group1:NodeByName("closeBtn").gameObject
	self.labelTitle_0 = group1:ComponentByName("labelTitle_0", typeof(UILabel))
	self.arrow = group1:NodeByName("arrow").gameObject
	self.groupContent = group1:NodeByName("groupContent").gameObject
	self.groupRewards = self.groupContent:NodeByName("groupRewards").gameObject
	self.line = self.groupContent:NodeByName("groupDesc/line").gameObject
	self.labelName = self.groupContent:ComponentByName("groupDesc/labelName", typeof(UILabel))
	self.labelDesc = self.groupContent:ComponentByName("groupDesc/labelDesc", typeof(UILabel))
	self.checkBtn = self.groupContent:NodeByName("groupDesc/checkBtn").gameObject
	self.btnCancel = self.groupContent:NodeByName("groupBtns/btnCancel").gameObject
	self.labelBtnCancel = self.btnCancel:ComponentByName("labelBtnCancel", typeof(UILabel))
	self.btnNext = self.groupContent:NodeByName("groupBtns/btnNext").gameObject
	self.labelBtnNext = self.btnNext:ComponentByName("labelBtnNext", typeof(UILabel))
	local group2 = main:NodeByName("group2").gameObject
	self.labelTitle_1 = group2:ComponentByName("labelTitle_1", typeof(UILabel))
	self.scrollerView = group2:ComponentByName("scroller", typeof(UIScrollView))
	self.groupPools = group2:NodeByName("scroller/groupPools").gameObject
	self.groupPoolsGrid = group2:ComponentByName("scroller/groupPools", typeof(UIGrid))
end

function ActivityDragonBoatAwardSelectWindow:layout()
	self.labelTitle_0.text = __("ACTIVITY_DRAGON_BOAT_AWARD_SELECT_WINDOW")
	self.labelTitle_1.text = __("ACTIVITY_DRAGON_BOAT_AWARD_SELECT_WINDOW_SECOND_TITLE")
	self.labelBtnCancel.text = __("CANCEL")
end

function ActivityDragonBoatAwardSelectWindow:updateNextBtn()
	local num = ActivityDragonBoatTable:getExAwardNum(self.id)

	if self.isFree then
		num = 1
	end

	if self.curIndex < num then
		self.labelBtnNext.text = __("NEXT")
	else
		self.labelBtnNext.text = __("CONFIRM")
	end

	local flag = true

	for i = 1, num do
		if not self.exAwards[i] then
			flag = false

			break
		end
	end

	local freeId = xyd.tables.miscTable:split2num("activity_chose_gift_free", "value", "|")[1]

	if num and flag or self.exAwards[self.curIndex] and self.curIndex < num or self.id == freeId and self.exAwards[self.curIndex] then
		xyd.applyOrigin(self.btnNext:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnNext, true)
		self.labelBtnNext:ApplyOrigin()
	else
		xyd.applyGrey(self.btnNext:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnNext, false)
		self.labelBtnNext:ApplyGrey()
	end
end

function ActivityDragonBoatAwardSelectWindow:initReAward()
	local num = ActivityDragonBoatTable:getExAwardNum(self.id)

	if self.isFree then
		num = 1
	end

	NGUITools.DestroyChildren(self.groupRewards.transform)

	self.rewardsList = {}

	for i = 1, num do
		local icon = ReplaceIcon.new(self.groupRewards)
		local index = i

		if self.exAwards[i] then
			local data = self.exAwards[i]

			icon:setIcon(data[1], data[2], true)
		end

		table.insert(self.rewardsList, icon)

		UIEventListener.Get(icon:getGameObject()).onClick = function ()
			self.curIndex = index

			self:updateCurIcon(index)
		end
	end

	for i = 1, num do
		if self.exAwards[i] then
			local awards = ActivityDragonBoatTable:getExAward(self.id, i)

			if self.isFree then
				awards = self:getFreeGiftAwards()
			end

			for j = 1, #awards do
				local data = awards[j]

				if data[1] == self.exAwards[i][1] then
					self.exAwardIndexs[i] = j
				end
			end
		end
	end
end

function ActivityDragonBoatAwardSelectWindow:getFreeGiftAwards()
	local giftIds = xyd.tables.miscTable:split2num("activity_chose_gift_free", "value", "|")
	local awards = {}

	for i = 1, #giftIds do
		local arr = xyd.tables.giftTable:getAwards(giftIds[i])

		table.insert(awards, table.remove(arr))
	end

	return awards
end

function ActivityDragonBoatAwardSelectWindow:updateCurIcon(index)
	for i = 1, #self.rewardsList do
		local icon = self.rewardsList[i]
		local flag = i == index

		icon:selected(flag)

		if flag then
			self:waitForFrame(5, function ()
				local x = icon:getGameObject().transform.localPosition.x

				self.arrow:X(x)
			end)
		end
	end

	self.checkBtn:SetActive(false)
	self:initDesc()
	self:updateAwardPool(index)
	self:updateNextBtn()
end

function ActivityDragonBoatAwardSelectWindow:initDesc()
	self.line:SetActive(false)

	self.labelName.text = ""
	self.labelDesc.text = __("ACTIVITY_DUANWU_SHUOMING")
end

function ActivityDragonBoatAwardSelectWindow:updateAwardPool(index)
	local awards = ActivityDragonBoatTable:getExAward(self.id, index)

	if self.isFree then
		awards = self:getFreeGiftAwards()
	end

	NGUITools.DestroyChildren(self.groupPools.transform)

	self.selectedIcon = nil

	for i = 1, #awards do
		local data = awards[i]
		local id = i
		local icon = nil
		icon = xyd.getItemIcon({
			noClickSelected = true,
			uiRoot = self.groupPools,
			itemID = tonumber(data[1]),
			num = tonumber(data[2]),
			callback = function ()
				self.exAwards[index] = data
				self.exAwardIndexs[index] = id

				if self.selectedIcon then
					self.selectedIcon:setChoose(false)
				end

				self.selectedIcon = icon

				self.selectedIcon:setChoose(true)
				self:setCurIconInfo(data)
			end
		})

		if self.exAwards[index] and self.exAwards[index][1] == data[1] then
			self.exAwardIndexs[index] = id
			self.selectedIcon = icon

			self.selectedIcon:setChoose(true)
			self:setCurIconInfo(data)
		end
	end

	self.groupPoolsGrid:Reposition()
end

function ActivityDragonBoatAwardSelectWindow:setCurIconInfo(data)
	self.curData = data
	local curIcon = self.rewardsList[self.curIndex]

	curIcon:setIcon(data[1], data[2], true)

	self.labelName.text = xyd.tables.itemTextTable:getName(data[1])
	local desc = xyd.tables.itemTextTable:getDesc(data[1])

	if xyd.tables.itemTable:getType(data[1]) == xyd.ItemType.CONSUMABLE_HANGUP then
		local mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
		local max_stage = mapInfo.max_stage

		if not max_stage or max_stage < 1 then
			max_stage = 1
		end

		local goldData = xyd.split(xyd.tables.stageTable:getGold(max_stage), "#")
		local expData = xyd.split(xyd.tables.stageTable:getExpPartner(max_stage), "#")
		local num = 0

		if data[1] == xyd.ItemID.GOLD_BAG_24 then
			num = goldData[2] * 24 * 60 * 12
		elseif data[1] == xyd.ItemID.GOLD_BAG_8 then
			num = goldData[2] * 8 * 60 * 12
		elseif data[1] == xyd.ItemID.EXP_BAG_24 then
			num = expData[2] * 24 * 60 * 12
		elseif data[1] == xyd.ItemID.EXP_BAG_8 then
			num = expData[2] * 8 * 60 * 12
		end

		local descNum = xyd.getRoughDisplayNumber(num)
		desc = desc .. descNum
	end

	self.checkBtn:SetActive(false)

	if xyd.tables.itemTable:getType(data[1]) == xyd.ItemType.OPTIONAL_TREASURE_CHEST then
		self.checkBtn:SetActive(true)
	end

	self.labelDesc.text = desc

	self.line:SetActive(true)
	self:updateNextBtn()
end

function ActivityDragonBoatAwardSelectWindow:onClickCheck()
	xyd.openWindow("drop_probability_window", {
		isShowProbalitity = false,
		itemId = self.curData[1]
	})
end

function ActivityDragonBoatAwardSelectWindow:register()
	ActivityDragonBoatAwardSelectWindow.super.register(self)

	UIEventListener.Get(self.btnCancel).onClick = function ()
		self:onClickCloseButton()
	end

	UIEventListener.Get(self.checkBtn).onClick = function ()
		self:onClickCheck()
	end

	local num = ActivityDragonBoatTable:getExAwardNum(self.id)

	if self.isFree then
		num = 1
	end

	UIEventListener.Get(self.btnNext).onClick = function ()
		self.curIndex = self.curIndex + 1

		if self.curIndex <= num then
			self:updateCurIcon(self.curIndex)
		else
			self.item:setExAward(self.exAwards)
			self.item:setIcon()
			self:recordSelect()
			self:onClickCloseButton()
		end
	end
end

function ActivityDragonBoatAwardSelectWindow:recordSelect()
	local data = xyd.models.activity:getActivity(xyd.ActivityID.DRAGON_BOAT)

	if not self.isFree then
		local msg = messages_pb:duanwu_set_attach_index_req()
		msg.activity_id = xyd.ActivityID.DRAGON_BOAT

		for i = 1, #self.exAwardIndexs do
			table.insert(msg.indexs, self.exAwardIndexs[i])
		end

		msg.giftbag_id = self.id

		xyd.Backend.get():request(xyd.mid.DUANWU_SET_ATTACH_INDEX, msg)

		local rs = ""
		local t = {}

		for i = 1, #self.exAwardIndexs do
			table.insert(t, tostring(self.exAwardIndexs[i]))
		end

		rs = rs .. table.concat(t, "|")
		data.detail.self_chosen[tostring(self.id)] = rs
	else
		if self.exAwardIndexs[1] then
			local msg = messages_pb:duanwu_set_free_attach_index_req()
			msg.activity_id = xyd.ActivityID.DRAGON_BOAT
			msg.index = self.exAwardIndexs[1]

			xyd.Backend.get():request(xyd.mid.DUANWU_SET_FREE_ATTACH_INDEX, msg)
		end

		local giftIds = xyd.tables.miscTable:split2num("activity_chose_gift_free", "value", "|")
		data.detail.free_charge.gift_id = giftIds[self.exAwardIndexs[1]]
	end
end

return ActivityDragonBoatAwardSelectWindow
