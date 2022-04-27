local ActivityContent = import(".ActivityContent")
local NewSevendayGiftbag = class("NewSevendayGiftbag", ActivityContent)
local NewSevendayGiftbagTag = class("NewSevendayGiftbagTag", import("app.components.CopyComponent"))
local NewSevendayGiftbagItem = class("NewSevendayGiftbagItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ActivityWeekFreeTable = xyd.tables.activityWeekFreeTable
local ActivityWeekBuyTable = xyd.tables.activityWeekBuyTable
local GiftBagTable = xyd.tables.giftBagTable
local GiftTable = xyd.tables.giftTable
local GiftBagTextTable = xyd.tables.giftBagTextTable
local json = require("cjson")

function NewSevendayGiftbag:ctor(parentGO, params, parent)
	NewSevendayGiftbag.super.ctor(self, parentGO, params, parent)

	self.giftBagID = 0
	local nowTime = xyd.db.misc:getValue("new_seven_giftbag_dadian")

	if not nowTime or not xyd.isToday(tonumber(nowTime)) then
		local msg = messages_pb.log_partner_data_touch_req()
		msg.touch_id = xyd.DaDian.NEW_SEVENDAY_GIFTBAG
		msg.desc = tostring(xyd.Global.playerID)

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
		xyd.db.misc:setValue({
			key = "new_seven_giftbag_dadian",
			value = xyd.getServerTime()
		})
	end
end

function NewSevendayGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/new_sevenday_giftbag"
end

function NewSevendayGiftbag:initUI()
	self:getUIComponent()
	NewSevendayGiftbag.super.initUI(self)
	self:initUIComponent()
	self:initContentGroup()
	self:updateRedMark()
end

function NewSevendayGiftbag:getUIComponent()
	local go = self.go
	self.textImg_ = go:ComponentByName("textImg_", typeof(UISprite))
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.timeLable_ = self.timeGroup:ComponentByName("timeLable_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.bgGroup = self.contentGroup:ComponentByName("bgGroup", typeof(UIWidget))
	self.tagGroup = self.contentGroup:NodeByName("tagGroup").gameObject
	self.scrollView = self.contentGroup:ComponentByName("scroller_", typeof(UIScrollView))
	self.itemGroup = self.contentGroup:NodeByName("scroller_/itemGroup").gameObject
	self.giftbagItem = self.contentGroup:NodeByName("scroller_/giftbag_item").gameObject
end

function NewSevendayGiftbag:initUIComponent()
	xyd.setUISpriteAsync(self.textImg_, nil, "new_seven_giftbag_text01_" .. xyd.Global.lang, nil, , true)
	import("app.components.CountDown").new(self.timeLable_, {
		duration = xyd.TimePeriod.WEEK_TIME - (xyd.getServerTime() - self.activityData.update_time)
	})

	self.endLabel_.text = __("TEXT_END")
end

function NewSevendayGiftbag:initContentGroup()
	self.scrollView:SetActive(true)

	self.nowDay = 0
	self.freeGiftBags = ActivityWeekFreeTable:getIds()
	self.buyGiftBags = ActivityWeekBuyTable:getIds()

	self:initTagGroup()
	self:waitForFrame(1, function ()
		local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
		self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.giftbagItem, NewSevendayGiftbagItem, self)

		self:setGiftBag(self.today)
	end)
end

function NewSevendayGiftbag:initTagGroup()
	local tagItem = self.tagGroup:NodeByName("copyTag").gameObject
	local onTime = xyd.getServerTime() - self.activityData.update_time
	local onDays = 0

	if onTime > 0 then
		onDays = math.ceil(onTime / xyd.TimePeriod.DAY_TIME)
	end

	if onDays > 7 then
		onDays = 7
	end

	self.today = onDays

	for i = 1, 7 do
		local tempGo = NGUITools.AddChild(self.tagGroup, tagItem)
		self["tag_" .. i] = NewSevendayGiftbagTag.new(tempGo, self, {
			id = i,
			unlock = i <= onDays,
			has_free = self.activityData.detail.free_awarded[i]
		})
	end

	self.tagGroup:GetComponent(typeof(UILayout)):Reposition()
end

function NewSevendayGiftbag:setGiftBag(day)
	if self.nowDay == day then
		return
	end

	if day > 7 then
		day = 7
	end

	self.nowDay = day
	local freeGiftBag = self.freeGiftBags[day]
	local buyGiftBags = self.buyGiftBags[day]
	local giftbags = {}

	table.insert(giftbags, {
		is_free = true,
		id = freeGiftBag,
		buy_times = self.activityData.detail.free_awarded[day]
	})

	local index = ActivityWeekBuyTable:getIndexByDay(day)

	for i = 1, #buyGiftBags do
		table.insert(giftbags, {
			is_free = false,
			id = buyGiftBags[i],
			index = index,
			buy_times = self.activityData.detail.charges[index].buy_times
		})

		index = index + 1
	end

	table.sort(giftbags, function (a, b)
		if a.buy_times == b.buy_times then
			return a.id < b.id
		else
			return a.buy_times < b.buy_times
		end
	end)
	self.wrapContent:setInfos(giftbags, {})
	self:updateTagGroup()
end

function NewSevendayGiftbag:updateTagGroup()
	for i = 1, 7 do
		local tag = self["tag_" .. i]

		if i == self.nowDay then
			xyd.setUISpriteAsync(tag.sprite_, nil, "new_seven_giftbag_tag01", function ()
				tag.sprite_:MakePixelPerfect()
			end)
			tag.go:Y(-40)
			tag.icon_:Y(80)
			tag.label_:Y(35)
		elseif tag.unlock then
			xyd.setUISpriteAsync(tag.sprite_, nil, "new_seven_giftbag_tag02", function ()
				tag.sprite_:MakePixelPerfect()
			end)
			tag.go:Y(-28)
			tag.icon_:Y(50)
			tag.label_:Y(20)
		else
			xyd.setUISpriteAsync(tag.sprite_, nil, "new_seven_giftbag_tag03", function ()
				tag.sprite_:MakePixelPerfect()
			end)
			tag.go:Y(-28)
			tag.icon_:Y(50)
			tag.label_:Y(20)
		end
	end
end

function NewSevendayGiftbag:onRegister()
	NewSevendayGiftbag.super.onRegister(self)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.openWindow("help_window", {
			key = "ACTIVITY_WEEK_GIFT_HELP"
		})
	end
end

function NewSevendayGiftbag:onAward(event)
	local data = event.data

	if data.activity_id ~= xyd.ActivityID.NEW_SEVENDAY_GIFTBAG then
		return
	end

	local awardID = self.activityData.freeID
	local awards = ActivityWeekFreeTable:getAwards(awardID)
	local items = {}

	for i = 1, #awards do
		local item = {
			item_id = awards[i][1],
			item_num = awards[i][2]
		}

		table.insert(items, item)
	end

	xyd.itemFloat(items, nil, , 6000)

	local giftItems = self.wrapContent:getItems()
	local len = xyd.getLength(giftItems)

	for i = -1, -len, -1 do
		if awardID == giftItems[tostring(i)].table_id then
			giftItems[tostring(i)]:updateState()

			break
		end
	end

	self:updateRedMark()
end

function NewSevendayGiftbag:onRecharge(event)
	if self.giftBagID ~= event.data.giftbag_id then
		return
	end

	local giftItems = self.wrapContent:getItems()
	local len = xyd.getLength(giftItems)

	for i = -1, -len, -1 do
		if self.giftBagID == giftItems[tostring(i)].table_id then
			giftItems[tostring(i)]:updateState()

			break
		end
	end
end

function NewSevendayGiftbag:resizeToParent()
	NewSevendayGiftbag.super.resizeToParent(self)
	self.go:Y(-440)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height
	self.bgGroup.height = 596 + (p_height - 869) / 2

	self.contentGroup:Y(-170 - (p_height - 869) * 0.7)
	self.textImg_:Y(320 - (p_height - 869) * 0.3)
	self.timeGroup:Y(235 - (p_height - 869) * 0.3)

	if p_height > 1040 then
		self.tagGroup:Y(328)
	end

	if xyd.Global.lang == "en_en" then
		self.timeGroup:X(5)

		local y = self.timeGroup.transform.localPosition.y

		self.timeGroup:Y(y + 10)
	elseif xyd.Global.lang == "fr_fr" then
		self.timeGroup:X(-5)

		local y = self.timeGroup.transform.localPosition.y

		self.timeGroup:Y(y + 10)

		self.timeLable_.fontSize = 22
		self.endLabel_.fontSize = 22

		self.timeGroup:GetComponent(typeof(UILayout)):Reposition()
	elseif xyd.Global.lang == "zh_tw" then
		-- Nothing
	elseif xyd.Global.lang == "ja_jp" or xyd.Global.lang == "ko_kr" then
		self.timeGroup:X(10)
	elseif xyd.Global.lang == "de_de" then
		self.timeGroup:X(-15)

		local y = self.timeGroup.transform.localPosition.y

		self.timeGroup:Y(y + 10)

		self.timeLable_.fontSize = 16
		self.endLabel_.fontSize = 16
		local layout = self.timeGroup:GetComponent(typeof(UILayout))
		layout.gap = Vector2(5, 0)

		layout:Reposition()
	end
end

function NewSevendayGiftbag:updateRedMark()
	local onTime = xyd.getServerTime() - self.activityData.update_time
	local onDays = 1

	if onTime > 0 then
		onDays = math.ceil(onTime / xyd.TimePeriod.DAY_TIME)
	end

	if onDays > 7 then
		onDays = 7
	end

	for i = 1, onDays do
		self["tag_" .. i]:setRedMark(self.activityData.detail.free_awarded[i] == 0)
	end
end

function NewSevendayGiftbagTag:ctor(go, parent, params)
	NewSevendayGiftbagTag.super.ctor(self, go)

	self.parent = parent
	self.id = params.id
	self.unlock = params.unlock
	self.has_free = params.has_free

	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function NewSevendayGiftbagTag:getUIComponent()
	local go = self.go
	self.sprite_ = go:GetComponent(typeof(UISprite))
	self.label_ = go:ComponentByName("tagLabel_", typeof(UILabel))
	self.icon_ = go:ComponentByName("tagIcon_", typeof(UISprite))
end

function NewSevendayGiftbagTag:initUIComponent()
	self.label_.text = __("ACTIVITY_WEEK_DATE", self.id)

	if not self.unlock then
		xyd.setUISpriteAsync(self.icon_, nil, "new_seven_giftbag_lock")

		self.icon_.width = 32
		self.icon_.height = 35

		self.icon_:SetActive(true)
	end
end

function NewSevendayGiftbagTag:setRedMark(flag)
	if not self.unlock then
		return
	end

	self.icon_:SetActive(flag)

	if flag then
		xyd.setUISpriteAsync(self.icon_, nil, "alert_icon", function ()
			self.icon_:MakePixelPerfect()
		end)
	end
end

function NewSevendayGiftbagTag:registerEvent()
	UIEventListener.Get(self.go).onClick = function ()
		if self.unlock then
			self.parent:setGiftBag(self.id)
		else
			xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_WEEK_LOCKING"))
		end
	end
end

function NewSevendayGiftbagItem:ctor(go, parent)
	NewSevendayGiftbagItem.super.ctor(self, go, parent)
end

function NewSevendayGiftbagItem:initUI()
	local go = self.go
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.buyBtn_ = go:NodeByName("buyBtn_").gameObject
	self.buttonLabel = self.buyBtn_:ComponentByName("button_label", typeof(UILabel))
	self.buttonRedIcon = self.buyBtn_:ComponentByName("redIcon", typeof(UISprite))
	self.labelLimit = go:ComponentByName("labelLimit", typeof(UILabel))
	self.labelVip = go:ComponentByName("labelVip", typeof(UILabel))
	self.labelVipNum = go:ComponentByName("labelVipNum", typeof(UILabel))
	self.labelVip.text = "VIP EXP"
end

function NewSevendayGiftbagItem:registerEvent()
	UIEventListener.Get(self.buyBtn_).onClick = handler(self, self.onBuy)
end

function NewSevendayGiftbagItem:onBuy()
	if self.is_free then
		self.parent.activityData:setFreeID(self.table_id)
		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.NEW_SEVENDAY_GIFTBAG, json.encode({
			award_id = self.table_id
		}))
	else
		self.parent.giftBagID = self.table_id

		xyd.SdkManager.get():showPayment(self.table_id)
	end
end

function NewSevendayGiftbagItem:updateInfo()
	if self.table_id == self.data.id then
		return
	end

	self.table_id = self.data.id
	self.is_free = self.data.is_free
	local awards = {}

	if self.is_free then
		awards = ActivityWeekFreeTable:getAwards(self.table_id)
	else
		self.index = self.data.index
		local giftbagID = GiftBagTable:getGiftID(self.table_id)
		awards = GiftTable:getAwards(giftbagID)
	end

	NGUITools.DestroyChildren(self.itemGroup.transform)

	for i = 1, #awards do
		local award = awards[i]

		if award[1] ~= xyd.ItemID.VIP_EXP then
			xyd.getItemIcon({
				show_has_num = true,
				scale = 0.7037037037037037,
				uiRoot = self.itemGroup,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scrollView
			})
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
	self:updateState()
end

function NewSevendayGiftbagItem:updateState()
	local limit = 0

	if self.is_free then
		self.buy_times = self.parent.activityData.detail.free_awarded[self.table_id]
		limit = ActivityWeekFreeTable:getLimit(self.table_id)
		self.buttonLabel.text = __("FREE2")
		self.labelVipNum.text = "+0"

		if limit <= self.buy_times then
			self.buttonRedIcon:SetActive(false)
		else
			self.buttonRedIcon:SetActive(true)
		end
	else
		self.buy_times = self.parent.activityData.detail.charges[self.index].buy_times

		self.buttonRedIcon:SetActive(false)

		limit = GiftBagTable:getBuyLimit(self.table_id)
		self.buttonLabel.text = GiftBagTextTable:getCurrency(self.table_id) .. " " .. GiftBagTextTable:getCharge(self.table_id)
		self.labelVipNum.text = "+" .. GiftBagTable:getVipExp(self.table_id)
	end

	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", limit - self.buy_times)

	if limit - self.buy_times <= 0 then
		xyd.setEnabled(self.buyBtn_, false)
	else
		xyd.setEnabled(self.buyBtn_, true)
	end
end

return NewSevendayGiftbag
