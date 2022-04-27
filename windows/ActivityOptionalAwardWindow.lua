local ActivityOptionalAwardWindow = class("ActivityOptionalAwardWindow", import(".BaseWindow"))
local ReplaceIcon = import("app.components.ReplaceIcon")

function ActivityOptionalAwardWindow:ctor(name, params)
	ActivityOptionalAwardWindow.super.ctor(self, name, params)

	self.optionalList = params.optionalList
	self.opNum = params.opNum or 1
	self.curIndex = params.curIndex or 1
	self.exAwards = params.exAwards or {}
	self.exAwardIndexs = {}
	self.titleText = params.titleText
	self.callback = params.callback
end

function ActivityOptionalAwardWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:initReAward()
	self:updateCurIcon(self.curIndex)
	self:register()
end

function ActivityOptionalAwardWindow:getUIComponent()
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

function ActivityOptionalAwardWindow:layout()
	self.labelTitle_0.text = self.titleText
	self.labelTitle_1.text = __("ACTIVITY_DRAGON_BOAT_AWARD_SELECT_WINDOW_SECOND_TITLE")
	self.labelBtnCancel.text = __("CANCEL")
end

function ActivityOptionalAwardWindow:updateNextBtn()
	if self.curIndex < self.opNum then
		self.labelBtnNext.text = __("NEXT")
	else
		self.labelBtnNext.text = __("CONFIRM")
	end

	local flag = true

	for i = 1, self.opNum do
		if not self.exAwards[i] then
			flag = false

			break
		end
	end

	if flag or self.exAwards[self.curIndex] and self.curIndex < self.opNum then
		xyd.applyOrigin(self.btnNext:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnNext, true)
		self.labelBtnNext:ApplyOrigin()
	else
		xyd.applyGrey(self.btnNext:GetComponent(typeof(UISprite)))
		xyd.setTouchEnable(self.btnNext, false)
		self.labelBtnNext:ApplyGrey()
	end
end

function ActivityOptionalAwardWindow:initReAward()
	NGUITools.DestroyChildren(self.groupRewards.transform)

	self.rewardsList = {}

	for i = 1, self.opNum do
		local icon = ReplaceIcon.new(self.groupRewards)
		local index = i

		if self.exAwards[i] then
			local data = self.exAwards[i]

			icon:setIcon(data[1], data[2], true)
		end

		table.insert(self.rewardsList, icon)

		UIEventListener.Get(icon:getGameObject()).onClick = function ()
			if self.curIndex == index then
				return
			end

			self.curIndex = index

			self:updateCurIcon(index)
		end
	end

	for i = 1, self.opNum do
		if self.exAwards[i] then
			local awards = self.optionalList[i]

			for j = 1, #awards do
				local data = awards[j]

				if data[1] == self.exAwards[i][1] then
					self.exAwardIndexs[i] = j
				end
			end
		end
	end
end

function ActivityOptionalAwardWindow:updateCurIcon(index)
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

	self:initDesc()
	self:updateAwardPool(index)
	self:updateNextBtn()
end

function ActivityOptionalAwardWindow:initDesc()
	self.line:SetActive(false)

	self.labelName.text = ""
	self.labelDesc.text = __("ACTIVITY_DUANWU_SHUOMING")
end

function ActivityOptionalAwardWindow:updateAwardPool(index)
	local awards = self.optionalList[index]

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
				if self.exAwardIndexs[index] == id then
					return
				end

				self.exAwards[index] = data
				self.exAwardIndexs[index] = id

				if self.selectedIcon then
					self.selectedIcon:setChoose(false)
				end

				self.selectedIcon = icon

				self.selectedIcon:setChoose(true)
				self:setCurIconInfo(data)
			end,
			dragScrollView = self.scrollerView
		})

		if self.exAwards[index] and self.exAwards[index][1] == data[1] then
			self.exAwardIndexs[index] = id
			self.selectedIcon = icon

			self.selectedIcon:setChoose(true)
			self:setCurIconInfo(data)
		end
	end

	self.groupPoolsGrid:Reposition()
	self.scrollerView:ResetPosition()
end

function ActivityOptionalAwardWindow:setCurIconInfo(data)
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

	self.labelDesc.text = desc

	self.line:SetActive(true)
	self:updateNextBtn()
end

function ActivityOptionalAwardWindow:register()
	ActivityOptionalAwardWindow.super.register(self)

	UIEventListener.Get(self.btnCancel).onClick = function ()
		self:onClickCloseButton()
	end

	UIEventListener.Get(self.btnNext).onClick = function ()
		self.curIndex = self.curIndex + 1

		if self.curIndex <= self.opNum then
			self:updateCurIcon(self.curIndex)
		else
			if self.callback then
				self.callback(self.exAwards, self.exAwardIndexs)
			end

			self:onClickCloseButton()
		end
	end
end

return ActivityOptionalAwardWindow
