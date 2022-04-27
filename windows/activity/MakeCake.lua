local cjson = require("cjson")
local ActivityContent = import(".ActivityContent")
local MakeCake = class("MakeCake", ActivityContent)
local MakeCakeItem = class("MakeCakeItem", import("app.components.BaseComponent"))
local ActivityMakeCakeTable = xyd.tables.activityMakeCakeTable
local ItemTable = xyd.tables.itemTable
local Backpack = xyd.models.backpack
local CountDown = import("app.components.CountDown")

function MakeCake:ctor(parentGO, params)
	self.items_ = {}

	MakeCake.super.ctor(self, parentGO, params)

	local val = xyd.db.misc:getValue("make_cake_caffe_flag")

	if val == nil or val == false then
		xyd.db.misc:setValue({
			value = true,
			key = "make_cake_caffe_flag"
		})
	end

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.MAKE_CAKE, function ()
		self.activityData.isShowRedPoint = self.activityData:initRedMarkState()
	end)
	self:initItems()
	self:layout()
	self:registerEvent()
end

function MakeCake:getPrefabPath()
	return "Prefabs/Windows/activity/make_cake"
end

function MakeCake:resizeToParent()
	if not self.parentWidget then
		return
	end

	local widget = self.go:GetComponent(typeof(UIWidget))
	widget.width = self.parentWidget.width
	widget.height = self.parentWidget.height + 4
end

function MakeCake:initUI()
	self:getUIComponent()
	MakeCake.super.initUI(self)
end

function MakeCake:getUIComponent()
	local go = self.go
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.numGroup = self.itemGroup:NodeByName("numGroup").gameObject
	self.resIcon = self.numGroup:NodeByName("icon").gameObject
	self.labelNum = self.numGroup:ComponentByName("label", typeof(UILabel))
	self.timerGroup = go:NodeByName("timerGroup").gameObject
	self.timeLabel = self.timerGroup:ComponentByName("timerLabel", typeof(UILabel))
	self.endLabel = self.timerGroup:ComponentByName("endLabel", typeof(UILabel))
	self.modelGroup = go:NodeByName("l2dNode").gameObject
	self.titleImg = go:ComponentByName("titleImg", typeof(UITexture))
end

function MakeCake:initItems()
	local ids = ActivityMakeCakeTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local lock = true

		if tonumber(id) == 1 then
			lock = false
		else
			local times = self.activityData.detail["times_" .. id - 1]

			for i = 1, #times do
				if times[i] ~= 0 then
					lock = false

					break
				end
			end
		end

		local params = {
			id = id,
			times = self.activityData.detail["times_" .. id],
			lock = lock
		}
		local item = MakeCakeItem.new(self.itemGroup)
		local switch = {
			function ()
				item:SetLocalPosition(-170, 88, 0)
				item:setRedPos(35, 60)
				item:setLockPos(26, 30)
			end,
			function ()
				item:SetLocalPosition(69, 102, 0)
				item:setRedPos(60, 54)
				item:setLockPos(-6, -14)
			end,
			function ()
				item:SetLocalPosition(-262, -47, 0)
				item:setRedPos(68, 58)
				item:setLockPos(4, 10)
			end,
			function ()
				item:SetLocalPosition(-43, -50, 0)
				item:setRedPos(94, 50)
				item:setLockPos(1, 22)

				item.imgIcon_.depth = 18
			end,
			function ()
				item:SetLocalPosition(207, -71, 0)
				item:setRedPos(82, 69)
				item:setLockPos(2, 36)
			end
		}

		switch[tonumber(id)]()
		item:setInfo(params)
		table.insert(self.items_, item)
	end
end

function MakeCake:layout()
	self.endLabel.text = __("END_TEXT")
	self.labelNum.text = tostring(Backpack:getItemNumByID(xyd.ItemID.MAKE_CAKE_THREE_COIN))

	xyd.setUITextureAsync(self.titleImg, "Textures/activity_text_web/activity_make_cake_caffe_" .. xyd.Global.lang, nil, )

	if xyd:getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})

		if xyd.Global.lang == "de_de" then
			self.timerGroup:X(-235)

			self.timeLabel.fontSize = 16
			self.endLabel.fontSize = 16
		end
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	self.timerGroup:GetComponent(typeof(UILayout)):Reposition()

	local strArr = xyd.tables.miscTable:split("activity_63_hero_model", "value", "|")
	local turn = 1

	if tonumber(strArr[5]) == 1 then
		turn = -1
	end

	if strArr then
		self.modelSpine = xyd.Spine.new(self.modelGroup)
		local scale = tonumber(strArr[4])

		self.modelSpine:setInfo(strArr[1], function ()
			self.modelSpine:play("animation", 0)
			self.modelSpine:SetLocalPosition(tonumber(strArr[2]), tonumber(strArr[3]), 0)
			self.modelGroup:SetLocalScale(turn * scale, scale, scale)
			self.modelSpine:setRenderTarget(self.modelGroup:GetComponent(typeof(UITexture)), 1)
		end, true)
	end

	self:updateRedPoint()
end

function MakeCake:resizeToParent()
	MakeCake.super.resizeToParent(self)

	local height = self.go:GetComponent(typeof(UIWidget)).height
end

function MakeCake:registerEvent()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			str_list = xyd.split(__("MAKE_CAKE_HELP", xyd.tables.itemTextTable:getName(xyd.tables.activityMakeCakeTable:getAwardInfo(1, 1).cost[1])), "|")
		})
	end

	UIEventListener.Get(self.resIcon).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.MAKE_CAKE_THREE_COIN
		})
	end

	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxyInner_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, function ()
		self.labelNum.text = tostring(Backpack:getItemNumByID(xyd.ItemID.MAKE_CAKE_THREE_COIN))

		self:updateRedPoint()
	end))
end

function MakeCake:onAward(event)
	local detail = cjson.decode(event.data.detail)

	for i = 1, #ActivityMakeCakeTable:getIDs() do
		if self.items_[i] ~= nil then
			local lock = true

			if tonumber(self.items_[i].id_) == 1 then
				lock = false
			else
				local times = detail["times_" .. tostring(tonumber(self.items_[i].id_) - 1)]

				for i = 1, #times do
					if times[i] ~= 0 then
						lock = false

						break
					end
				end
			end

			self.items_[i]:update(lock, detail["times_" .. self.items_[i].id_])
		end
	end

	local skins = {}

	for i = 1, #detail.items do
		local table_id = detail.items[i].item_id

		if ItemTable:getType(table_id) == xyd.ItemType.SKIN then
			table.insert(skins, table_id)
		end
	end

	if skins ~= nil and #skins > 0 then
		xyd.onGetNewPartnersOrSkins({
			skins = skins
		})
	else
		xyd.models.itemFloatModel:pushNewItems(detail.items)
	end

	self:updateRedPoint()
end

function MakeCake:updateRedPoint()
	local data = self.activityData
	local detail = data.detail

	for i = 1, #ActivityMakeCakeTable:getIDs() do
		if self.items_[i].lock_ then
			self.items_[i]:setRedPoint(false)
		else
			local useRed = true
			local max = 0

			for j = 1, 3 do
				local info = ActivityMakeCakeTable:getAwardInfo(self.items_[i].id_, j)

				if info ~= nil then
					if max < info.cost[2] then
						max = info.cost[2]
					end

					if info.limit <= detail["times_" .. self.items_[i].id_][j] then
						useRed = false

						break
					end
				end
			end

			self.items_[i]:setRedPoint(useRed and max <= Backpack:getItemNumByID(xyd.ItemID.MAKE_CAKE_THREE_COIN))
		end
	end
end

function MakeCakeItem:ctor(parentGO)
	MakeCakeItem.super.ctor(self, parentGO)
end

function MakeCakeItem:getPrefabPath()
	return "Prefabs/Components/make_cake_item"
end

function MakeCakeItem:initUI()
	MakeCakeItem.super.initUI(self)
	self:getComponent()
end

function MakeCakeItem:getComponent()
	local go = self.go
	self.imgIcon_ = go:ComponentByName("imgIcon", typeof(UISprite))
	self.label = go:ComponentByName("label", typeof(UILabel))
	self.mask = self.label:ComponentByName("mask", typeof(UISprite))
	self.imgLock_ = self.label:ComponentByName("imgLock", typeof(UISprite))
	self.imgRed_ = self.label:ComponentByName("imgRed", typeof(UISprite))

	self.imgRed_:SetActive(false)
end

function MakeCakeItem:setInfo(params)
	self.id_ = params.id
	self.times_ = params.times
	self.lock_ = params.lock

	self:layout()
	self:onRegister()
end

function MakeCakeItem:onRegister()
	UIEventListener.Get(self.imgIcon_.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("make_cake_exchange_window", {
			lock = self.lock_,
			times = self.times_,
			id = self.id_
		})
	end
end

function MakeCakeItem:setRedPos(x, y)
	self.imgRed_.gameObject:SetLocalPosition(x, y, 0)
end

function MakeCakeItem:setRedPoint(flag)
	self.imgRed_.gameObject:SetActive(flag)
end

function MakeCakeItem:setLockPos(x, y)
	self.imgLock_.gameObject:SetLocalPosition(x, y, 0)
end

function MakeCakeItem:setLabelPos(x, y)
	self.label.gameObject:SetLocalPosition(x, y, 0)
end

function MakeCakeItem:setMaskPos(x, y)
	self.mask.gameObject:SetLocalPosition(x, y, 0)
end

function MakeCakeItem:update(lock, times)
	self.lock_ = lock
	self.times_ = times

	self:layout()
end

function MakeCakeItem:layout()
	if self.lock_ then
		xyd.setUISpriteAsync(self.imgIcon_, nil, "activity_make_cake_caffe_" .. self.id_, function ()
			self.imgIcon_:MakePixelPerfect()
		end)
		self.imgLock_:SetActive(true)
		self.mask:SetActive(true)
	else
		xyd.setUISpriteAsync(self.imgIcon_, nil, "activity_make_cake_caffe_" .. self.id_, function ()
			self.imgIcon_:MakePixelPerfect()
		end)
		self.imgLock_:SetActive(false)
		self.mask:SetActive(false)
	end
end

return MakeCake
