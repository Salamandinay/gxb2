local ActivityContent = import(".ActivityContent")
local SchoolOpensGiftbag = class("SchoolOpensGiftbag", ActivityContent)
local SchoolOpensGiftbagItem = class("SchoolOpensGiftbagItem", import("app.components.BaseComponent"))
local json = require("cjson")

function SchoolOpensGiftbag:ctor(go, params)
	ActivityContent.ctor(self, go, params)
end

function SchoolOpensGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/school_opens_gift_bag"
end

function SchoolOpensGiftbag:initUI()
	self:getUIComponent()
	SchoolOpensGiftbag.super.initUI(self)
	self:initUIComponent()
	self:initItems()
	self:onRegister()
end

function SchoolOpensGiftbag:resizeToParent()
	SchoolOpensGiftbag.super.resizeToParent(self)
	self:resizePosY(self.item1, -348, -394)
	self:resizePosY(self.item2, -348, -394)
	self:resizePosY(self.item3, -652, -776)
	self:resizePosY(self.item4, -652, -776)
	self:resizePosY(self.textImg, -17, -34)
end

function SchoolOpensGiftbag:getUIComponent()
	local go = self.go
	self.imgBottom = go:NodeByName("imgBottom").gameObject
	self.textImg = go:ComponentByName("textImg", typeof(UISprite))
	self.helpBtn = go:ComponentByName("helpBtn", typeof(UISprite))
	self.itemGroup = go:NodeByName("itemGroup").gameObject

	for i = 1, 4 do
		self["item" .. i] = self.itemGroup:NodeByName("item" .. i).gameObject
	end

	self.effect = go:NodeByName("effect").gameObject
end

function SchoolOpensGiftbag:initUIComponent()
	xyd.setUISpriteAsync(self.textImg, nil, "school_opens_giftbag2_" .. xyd.Global.lang, nil, , true)

	local ids = xyd.tables.activitySchoolGiftTable:getIDs()

	for i = 1, #ids do
		local item = self.itemGroup:NodeByName("item" .. tostring(ids[i])).gameObject
		local unlockBtn = item:NodeByName("unlockBtn").gameObject
		local buttonLabel = item:ComponentByName("unlockBtn/button_label", typeof(UILabel))
		local iconImg = unlockBtn:ComponentByName("iconImg", typeof(UISprite))

		if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
			iconImg:X(-52)

			buttonLabel.width = 100
		end
	end
end

function SchoolOpensGiftbag:initItems()
	local ids = xyd.tables.activitySchoolGiftTable:getIDs()

	for i = 1, #ids do
		local params = {
			id = tonumber(ids[i]),
			status = self.activityData.detail.box_lock_status[tonumber(ids[i])],
			counts = self.activityData.detail.award_counts[tonumber(ids[i])],
			unlockType = xyd.tables.activitySchoolGiftTable:getUnlockType(tonumber(ids[i]))
		}
		local item = self.itemGroup:NodeByName("item" .. tostring(params.id)).gameObject
		local unlockBtn = item:NodeByName("unlockBtn").gameObject
		local imgBg = item:ComponentByName("imgBg", typeof(UISprite))
		local buttonLabel = item:ComponentByName("unlockBtn/button_label", typeof(UILabel))
		local iconImg = unlockBtn:ComponentByName("iconImg", typeof(UISprite))

		self:setPurchaseBtnStatus(params.id)
		self:updateInfo(params.id)

		if params.status == 1 and params.counts ~= 0 then
			xyd.setUISpriteAsync(imgBg, nil, "activity_opens_giftbag2_icon" .. tostring(params.id) .. "_" .. 1, nil, , true)
		else
			xyd.setUISpriteAsync(imgBg, nil, "activity_opens_giftbag2_icon" .. tostring(params.id) .. "_" .. 0, nil, , true)
		end

		UIEventListener.Get(imgBg.gameObject).onClick = function ()
			local items = {}
			local awards = xyd.tables.activitySchoolGiftTable:getDailyAwards(params.id)
			local ratio = math.max(1, params.counts)

			for i = 1, #awards do
				local data = awards[i]

				table.insert(items, {
					item_id = data[1],
					item_num = data[2] * ratio
				})
			end

			local flag = params.status == 1 and params.counts == 0
			local title = nil

			if ratio <= 1 then
				title = __("EVERY_DAY_AWARD")
			else
				title = __("ALL_AWARD")
			end

			xyd.WindowManager.get():openWindow("activity_every_day_award_window", {
				items = items,
				status = flag,
				title = title
			})
		end
	end
end

function SchoolOpensGiftbag:updateInfo(id)
	local params = {
		id = id,
		status = self.activityData.detail.box_lock_status[id],
		counts = self.activityData.detail.award_counts[id],
		unlockType = xyd.tables.activitySchoolGiftTable:getUnlockType(id)
	}
	local item = self.itemGroup:NodeByName("item" .. tostring(params.id)).gameObject
	local unlockBtn = item:NodeByName("unlockBtn").gameObject
	local imgBg = item:ComponentByName("imgBg", typeof(UISprite))
	local buttonLabel = item:ComponentByName("unlockBtn/button_label", typeof(UILabel))
	local iconImg = unlockBtn:ComponentByName("iconImg", typeof(UISprite))

	if params.counts == 0 then
		xyd.applyChildrenGrey(unlockBtn)

		local button = unlockBtn:GetComponent(typeof(UIButtonScale))
		button.enabled = false
		buttonLabel.text = __("ALREADY_GET_PRIZE")

		buttonLabel:X(0)
		iconImg:SetActive(false)
	elseif params.status == 1 then
		buttonLabel.text = __("GET2")

		buttonLabel:X(0)
		iconImg:SetActive(false)
	end

	if params.status == 1 and params.counts ~= 0 then
		xyd.setUISpriteAsync(imgBg, nil, "activity_opens_giftbag2_icon" .. tostring(params.id) .. "_" .. 1, nil, , true)
	else
		xyd.setUISpriteAsync(imgBg, nil, "activity_opens_giftbag2_icon" .. tostring(params.id) .. "_" .. 0, nil, , true)
	end
end

function SchoolOpensGiftbag:setPurchaseBtnStatus(id)
	local params = {
		id = id,
		status = self.activityData.detail.box_lock_status[id],
		counts = self.activityData.detail.award_counts[id],
		unlockType = xyd.tables.activitySchoolGiftTable:getUnlockType(id)
	}
	params.type = params.unlockType.type
	params.cost = params.unlockType.cost
	local item = self.itemGroup:NodeByName("item" .. tostring(params.id)).gameObject
	local unlockBtn = item:NodeByName("unlockBtn").gameObject
	local imgBg = item:ComponentByName("imgBg", typeof(UISprite))
	local buttonLabel = item:ComponentByName("unlockBtn/button_label", typeof(UILabel))
	local iconImg = unlockBtn:ComponentByName("iconImg", typeof(UISprite))

	if params.type == 1 then
		buttonLabel.text = __("PUB_SPEED_FREE")

		buttonLabel:X(0)

		UIEventListener.Get(unlockBtn).onClick = function ()
			self:touchType1(params.id)
		end
	elseif params.type == 2 then
		local img = tostring(xyd.tables.itemTable:getIcon(params.cost[1]))

		xyd.setUISpriteAsync(iconImg, nil, img)

		iconImg.width = 44
		iconImg.height = 44

		iconImg:SetActive(true)

		buttonLabel.text = params.cost[2]

		UIEventListener.Get(unlockBtn).onClick = function ()
			self:touchType2(params.id)
		end
	elseif params.type == 3 then
		xyd.setUISpriteAsync(iconImg, nil, "act_lock")

		iconImg.width = 32
		iconImg.height = 36

		iconImg:SetActive(true)

		buttonLabel.text = __("UNLOCK_TEXT")

		UIEventListener.Get(unlockBtn).onClick = function ()
			self:touchType3(params.id)
		end
	end
end

function SchoolOpensGiftbag:reqAward(id)
	local params = {
		id = id,
		counts = self.activityData.detail.award_counts[id]
	}

	if params.counts == 0 then
		xyd.showToast(__("SCHOOL_GIFTBAG_EXCHANGE_TEXT02"))

		return
	end

	local data = json.encode({
		id = tonumber(params.id)
	})

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SCHOOL_GIFTBAG, data)
end

function SchoolOpensGiftbag:touchType1(id)
	local params = {
		id = id,
		status = self.activityData.detail.box_lock_status[id]
	}

	if params.status == 1 then
		self:reqAward(params.id)

		return
	end

	xyd.alert(xyd.AlertType.YES_NO, __("SCHOOL_GIFTBAG_EXCHANGE_TEXT03"), function (yes)
		if yes then
			local msg = messages_pb.unlock_school_gift_box_req()
			msg.activity_id = xyd.ActivityID.ACTIVITY_SCHOOL_GIFTBAG
			msg.id = tonumber(params.id)

			xyd.Backend.get():request(xyd.mid.UNLOCK_SCHOOL_GIFT_BOX, msg)
		end
	end)
end

function SchoolOpensGiftbag:touchType2(id)
	local params = {
		id = id,
		status = self.activityData.detail.box_lock_status[id],
		unlockType = xyd.tables.activitySchoolGiftTable:getUnlockType(id)
	}
	params.cost = params.unlockType.cost

	if params.status == 1 then
		self:reqAward(params.id)

		return
	end

	if xyd.models.backpack:getItemNumByID(tonumber(params.cost[1])) < tonumber(params.cost[2]) then
		xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(params.cost[1])))

		return
	end

	xyd.alert(xyd.AlertType.YES_NO, __("SCHOOL_GIFTBAG_EXCHANGE_TEXT03"), function (yes)
		if yes then
			local msg = messages_pb.unlock_school_gift_box_req()
			msg.activity_id = xyd.ActivityID.ACTIVITY_SCHOOL_GIFTBAG
			msg.id = tonumber(params.id)

			xyd.Backend.get():request(xyd.mid.UNLOCK_SCHOOL_GIFT_BOX, msg)
		end
	end)
end

function SchoolOpensGiftbag:touchType3(id)
	local params = {
		id = id,
		status = self.activityData.detail.box_lock_status[id]
	}

	if params.status == 1 then
		self:reqAward(params.id)

		return
	end

	xyd.WindowManager.get():closeWindow("activity_window", function ()
		xyd.openWindow("activity_window", {
			activity_type = xyd.EventType.COOL,
			select = xyd.ActivityID.BENEFIT_GIFTBAG03
		})
	end)
end

function SchoolOpensGiftbag:updateItems()
	local ids = xyd.tables.activitySchoolGiftTable:getIDs()

	for i = 1, #ids do
		self:updateInfo(tonumber(ids[i]))
	end
end

function SchoolOpensGiftbag:onRegister()
	UIEventListener.Get(self.helpBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_SCHOOL_GIFTBAG_HELP_TEXT"
		})
	end

	self:registerEvent(xyd.event.UNLOCK_SCHOOL_GIFT_BOX, handler(self, self.updateItems))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.updateItems))
end

return SchoolOpensGiftbag
