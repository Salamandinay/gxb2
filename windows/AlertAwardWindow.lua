local BaseWindow = import(".BaseWindow")
local AlertAwardWindow = class("AlertAwardWindow", BaseWindow)
local ItemIcon = require("app.components.ItemIcon")
local HeroIcon = require("app.components.HeroIcon")

function AlertAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.items = params.items or {}
	self.title = params.title or __("GET_ITEMS")
	self.closeCallback = params.callback
	self.jumpToMode = params.jumpToMode
	self.jumpToBtnCallback = params.jumpToBtnCallback
	self.NoBtnCallback = params.NoBtnCallback
	self.NoBtnLabel = params.NoBtnLabel
	self.jumpToBtnLabel = params.jumpToBtnLabel
	self.showDesc = params.showDesc
	self.descText = params.descText
end

function AlertAwardWindow:initWindow()
	BaseWindow.initWindow(self)
	self:initData()
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function AlertAwardWindow:initData()
	local tmpData = {}
	local starData = {}
	local levData = {}
	local noWaysData = {}

	for i = 1, #self.items do
		local item = self.items[i]
		tmpData[item.item_id] = (tmpData[item.item_id] or 0) + tonumber(item.item_num)
		starData[item.item_id] = item.star
		levData[item.item_id] = item.lev
		noWaysData[item.item_id] = item.noWays
	end

	self.items = {}

	for id, v in pairs(tmpData) do
		table.insert(self.items, {
			item_id = id,
			item_num = v,
			star = starData[id],
			lev = levData[id],
			noWays = noWaysData[id]
		})
	end

	table.sort(self.items, function (a, b)
		return tonumber(a.item_id) < tonumber(b.item_id)
	end)
end

function AlertAwardWindow:getUIComponent()
	local go = self.window_
	local groupAction = go:NodeByName("groupAction").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.btnSure_ = groupAction:NodeByName("btnSure_").gameObject
	self.labelSure = groupAction:ComponentByName("btnSure_/button_label", typeof(UILabel))
	self.groupItem_ = groupAction:NodeByName("groupItem_").gameObject
	self.btnJumpTo = groupAction:NodeByName("btnJumpTo").gameObject
	self.labelJumpTo = groupAction:ComponentByName("btnJumpTo/button_label", typeof(UILabel))
	self.btnNo = groupAction:NodeByName("btnNo").gameObject
	self.labelNo = groupAction:ComponentByName("btnNo/button_label", typeof(UILabel))
	self.labelDesc = groupAction:ComponentByName("descLabel", typeof(UILabel))
end

function AlertAwardWindow:initUIComponent()
	print(self.items[1].item_id)

	local i = 1

	while i <= #self.items do
		local data = self.items[i]
		local itemID = data.item_id
		local itemNum = data.item_num
		local type_ = xyd.tables.itemTable:getType(itemID)
		local showBagType = xyd.tables.itemTable:showInBagType(itemID)
		local item = self:createItem(data)

		if type_ == xyd.ItemType.HERO or itemNum > 1 and (type_ == xyd.ItemType.ARTIFACT or showBagType == xyd.BackpackShowType.EQUIP) then
			self:createLabel(itemNum)
			item:setNum(nil)
		end

		i = i + 1
	end

	self.labelTitle_.text = self.title

	if self.NoBtnLabel then
		self.labelNo.text = self.NoBtnLabel
	end

	if self.jumpToBtnLabel then
		self.labelJumpTo.text = self.jumpToBtnLabel
	end

	self.labelSure.text = __("SURE_2")

	if self.descText then
		self.labelDesc.text = self.descText
	end

	xyd.setBgColorType(self.btnSure_, xyd.ButtonBgColorType.blue_btn_65_65)

	if self.jumpToMode then
		self.btnSure_:SetActive(false)
		self.btnNo:SetActive(true)
		self.btnJumpTo:SetActive(true)
	end

	if self.showDesc then
		self.labelDesc:SetActive(true)

		self.window_:ComponentByName("groupAction", typeof(UIWidget)).height = 400

		self.groupItem_:Y(-20)
	end
end

function AlertAwardWindow:createLabel(itemNum)
	local params = {
		c = 960513791,
		ec = 4294967295.0,
		s = 24,
		uiRoot = self.groupItem_,
		t = "x" .. tostring(itemNum)
	}
	local label = xyd.getLabel(params)

	label:SetLocalPosition(0, -67, 0)

	return label
end

function AlertAwardWindow:createItem(data)
	local type_ = xyd.tables.itemTable:getType(data.item_id)
	local itemIcon = nil

	if type_ == xyd.ItemType.HERO then
		itemIcon = HeroIcon.new(self.groupItem_)

		itemIcon:setInfo({
			itemID = data.item_id,
			star = data.star,
			lev = data.lev,
			noWays = data.noWays
		})
	elseif type_ == xyd.ItemType.HERO_DEBRIS or type_ == xyd.ItemType.HERO_RANDOM_DEBRIS then
		itemIcon = HeroIcon.new(self.groupItem_)

		itemIcon:setInfo({
			itemID = data.item_id,
			num = data.item_num
		})
	else
		itemIcon = ItemIcon.new(self.groupItem_)

		itemIcon:setInfo({
			hideText = true,
			itemID = data.item_id,
			num = data.item_num
		})
	end

	return itemIcon
end

function AlertAwardWindow:registerEvent()
	xyd.setDarkenBtnBehavior(self.btnSure_, self, self.btnSureTouch)

	if self.jumpToBtnCallback then
		UIEventListener.Get(self.btnJumpTo).onClick = handler(self, self.jumpToBtnCallback)
	end

	if self.NoBtnCallback then
		UIEventListener.Get(self.btnNo).onClick = handler(self, self.NoBtnCallback)
	end
end

function AlertAwardWindow:btnSureTouch()
	xyd.WindowManager.get():closeWindow(self.name_, function ()
	end)
end

function AlertAwardWindow:excuteCallBack(isCloseAll)
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG)

	if activityData and xyd.getServerTime() < activityData.start_time + tonumber(xyd.tables.miscTable:getVal("graduate_gift_open_limit")) and activityData.detail.active_time == 0 then
		for _, item in ipairs(self.items) do
			if item.item_id == tonumber(xyd.split(xyd.tables.miscTable:getVal("graduate_gift_partner"), "|")[1]) then
				xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG)
				xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_GRADUATE_TIP"), function (yes)
					if yes then
						xyd.WindowManager.get():openWindow("activity_window", {
							activity_type = xyd.EventType.LIMIT,
							select = xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG
						})
					end
				end)

				break
			end
		end
	end

	if isCloseAll then
		return
	end

	if self.closeCallback then
		self.closeCallback()
	end
end

function AlertAwardWindow:iosTestChangeUI()
	local allChildren = self.window_:GetComponentsInChildren(typeof(UISprite), true)

	for i = 0, allChildren.Length - 1 do
		local sprite = allChildren[i]

		xyd.setUISprite(sprite, nil, sprite.spriteName .. "_ios_test")
	end
end

return AlertAwardWindow
