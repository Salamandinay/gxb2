local LevelFundItem = class("LevelFundItem")

function LevelFundItem:ctor(goItem, id, ifLock, awarded)
	self.goItem_ = goItem
	local transGo = goItem.transform
	self.id_ = tonumber(id)
	self.ifLock_ = ifLock
	self.ifGet_ = awarded and function ()
		return true
	end or function ()
		return false
	end()
	self.progressBar_ = transGo:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressImg = transGo:ComponentByName("progressBar_/progressImg", typeof(UISprite))
	self.progressDesc = transGo:ComponentByName("progressBar_/progressLabel", typeof(UILabel))
	self.labelTitle_ = transGo:ComponentByName("labelTitle", typeof(UILabel))
	self.itemsGroup_ = transGo:Find("itemsGroup")

	self:initItem()
end

function LevelFundItem:initItem()
	local level = xyd.tables.activityLevelUpTable:getLevel(self.id_)
	local rewards = xyd.tables.activityLevelUpTable:getRewards(self.id_)
	local currentLevel = xyd.models.backpack:getLev()
	self.labelTitle_.text = __("LEVEL_FUND_TEXT02", level)
	self.progressBar_.value = math.min(level, currentLevel) / level
	self.progressDesc.text = math.min(level, currentLevel) .. "/" .. level
	local icon = xyd.getItemIcon({
		itemID = rewards[1],
		num = rewards[2],
		uiRoot = self.itemsGroup_.gameObject,
		scale = Vector3(0.8, 0.8, 1)
	})

	self:updateIconState()
	icon:AddUIDragScrollView()
end

function LevelFundItem:updateIconState()
end

local ActivityContent = import(".ActivityContent")
local LevelFund = class("LevelFund", ActivityContent)

function LevelFund:ctor(name, params)
	ActivityContent.ctor(self, name, params)

	local gift_bag_id = tonumber(xyd.tables.activityTable:getGiftBag(self.id)[1])
	self.giftBagId_ = gift_bag_id

	self:getUIComponent()
	self:layout()
	self:initData()
	self:onRegisterEvent()
end

function LevelFund:getPrefabPath()
	return "Prefabs/Windows/activity/level_fund_window"
end

function LevelFund:getUIComponent()
	local go = self.go
	self.imgTitle_ = go:ComponentByName("imgTitle_", typeof(UISprite))
	self.imgBg_ = go:ComponentByName("imgBg_", typeof(UISprite))
	self.helpBtn_ = go:NodeByName("helpBtn").gameObject
	local group1 = go:NodeByName("group1").gameObject
	local scroller = group1:NodeByName("scroller").gameObject
	self.itemsGroup_ = scroller:NodeByName("itemsGroup_").gameObject
	self.itemsGroup_uiLayout = self.itemsGroup_:GetComponent(typeof(UILayout))
	local itemsGroup_uipanel = scroller:GetComponent(typeof(UIPanel))
	itemsGroup_uipanel.depth = itemsGroup_uipanel.depth + 2
	local group2 = go:NodeByName("group2").gameObject
	self.btnBuy_ = group2:NodeByName("btnBuy_").gameObject
	self.btnBuyLabel_ = self.btnBuy_:ComponentByName("button_label", typeof(UILabel))
	self.labelLimit_ = group2:ComponentByName("labelLimit_", typeof(UILabel))
	self.labelVip_ = group2:ComponentByName("labelVip_", typeof(UILabel))
	local scroller1 = go:NodeByName("scroller1").gameObject
	local scroller1_uipanel = scroller1:GetComponent(typeof(UIPanel))
	scroller1_uipanel.depth = scroller1_uipanel.depth + 1
	local group3 = scroller1:NodeByName("group3").gameObject
	self.labelDesc_ = group3:ComponentByName("labelDesc_", typeof(UILabel))
	self.littleItem = go.transform:Find("level_fund_item")
	local group3 = go:NodeByName("group3").gameObject
	self.group3 = group3
	local groupGain = group3:NodeByName("groupGain").gameObject
	self.gainText_ = groupGain:ComponentByName("imgText", typeof(UISprite))
	self.gainNum_ = groupGain:NodeByName("groupNum").gameObject
	local groupTotal = group3:NodeByName("groupTotal").gameObject
	self.totalText_ = groupTotal:ComponentByName("imgText", typeof(UISprite))
	self.totalNum_ = groupTotal:NodeByName("groupNum").gameObject
	self.numCell = group3:ComponentByName("numCell", typeof(UISprite))
end

function LevelFund:onRegisterEvent()
	UIEventListener.Get(self.btnBuy_).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftBagId_)

		local win = xyd.WindowManager.get():getWindow("activity_window")

		if win and win:ifNeedDaDian() then
			local msg = messages_pb:log_partner_data_touch_req()
			msg.touch_id = xyd.DaDian.POPUP_CLICK_IN_FUND

			xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
		end
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "LEVEL_FUND_TEXT01"
		})
	end

	self:registerEvent(xyd.event.RECHARGE, handler(self, function (self, evt)
		local gift_bag_id = evt.data.giftbag_id

		if xyd.tables.giftBagTable:getActivityID(gift_bag_id) ~= self.id then
			return
		end

		xyd.models.activity:reqActivityByID(xyd.ActivityID.LEVEL_FUND)
	end))
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, function (self, event)
		local id = event.data.act_info.activity_id

		if id ~= self.id then
			return
		end

		self:initData()
	end))
end

function LevelFund:layout()
	self.btnBuyLabel_.text = xyd.tables.giftBagTextTable:getCurrency(self.giftBagId_) .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftBagId_))
	self.labelDesc_.text = __("LEVEL_FUND_TEXT01")

	xyd.setUISpriteAsync(self.imgTitle_, nil, "level_fund_text_" .. tostring(xyd.Global.lang), nil, , true)
	xyd.setUISpriteAsync(self.imgBg_, nil, "level_fund_bg", nil, , true)

	self.labelVip_.text = "+" .. tostring(tostring(xyd.tables.giftBagTable:getVipExp(self.giftBagId_))) .. " VIP EXP"

	if self.activityData.detail.charges[1].limit_times <= self.activityData.detail.charges[1].buy_times then
		xyd.setUISpriteAsync(self.gainText_, nil, "level_fund_gain_" .. xyd.Global.lang, nil, , true)
	else
		xyd.setUISpriteAsync(self.gainText_, nil, "level_fund_addup_" .. xyd.Global.lang, nil, , true)
	end

	xyd.setUISpriteAsync(self.totalText_, nil, "level_fund_total_" .. xyd.Global.lang, nil, , true)

	local gainNum = 0
	local totalNum = 0
	local selfLevel = xyd.models.backpack:getLev()
	local ids = xyd.tables.activityLevelUpTable:getIds()

	for i, id in ipairs(ids) do
		local level = xyd.tables.activityLevelUpTable:getLevel(id)
		local award = xyd.tables.activityLevelUpTable:getRewards(id)

		if level <= selfLevel then
			gainNum = gainNum + award[2]
		end

		totalNum = totalNum + award[2]
	end

	gainNum = tostring(gainNum)
	totalNum = tostring(totalNum)

	for i = 1, string.len(gainNum) do
		local num = string.sub(gainNum, i, i)
		local go = NGUITools.AddChild(self.gainNum_.gameObject, self.numCell.gameObject)

		xyd.setUISpriteAsync(go:GetComponent(typeof(UISprite)), nil, "level_fund_num" .. num, nil, , true)
	end

	for i = 1, string.len(totalNum) do
		local num = string.sub(totalNum, i, i)
		local go = NGUITools.AddChild(self.totalNum_.gameObject, self.numCell.gameObject)

		xyd.setUISpriteAsync(go:GetComponent(typeof(UISprite)), nil, "level_fund_num" .. num, nil, , true)
	end

	self.gainNum_:GetComponent(typeof(UILayout)):Reposition()
	self.totalNum_:GetComponent(typeof(UILayout)):Reposition()

	if xyd.Global.lang == "fr_fr" then
		self.group3.transform.localScale = Vector3(0.9, 0.9, 0.9)

		self.group3:Y(-183.5)
	end
end

function LevelFund:initData()
	NGUITools.DestroyChildren(self.itemsGroup_.transform)

	local ids = xyd.tables.activityLevelUpTable:getIds()
	local charges = self.activityData.detail.charges[1]
	local awards_info = self.activityData.detail.awards_info
	local data = {}
	local backData = {}

	for i in ipairs(ids) do
		local id = ids[i]

		if awards_info.awarded[id] then
			table.insert(backData, {
				id = id,
				if_lock = charges.buy_times < 1 and function ()
					return true
				end or function ()
					return false
				end(),
				awarded = awards_info.awarded[id]
			})
		else
			table.insert(data, {
				id = id,
				if_lock = charges.buy_times < 1 and function ()
					return true
				end or function ()
					return false
				end(),
				awarded = awards_info.awarded[id]
			})
		end
	end

	table.insertto(data, backData)

	for i in ipairs(data) do
		local tmp = NGUITools.AddChild(self.itemsGroup_.gameObject, self.littleItem.gameObject)
		local item = LevelFundItem.new(tmp, data[i].id, data[i].if_lock, data[i].awarded)
	end

	self.littleItem:SetActive(false)
	self.itemsGroup_uiLayout:Reposition()
	self:updateState()
end

function LevelFund:updateState()
	local activityData = self.activityData
	local buyTimes = activityData.detail.charges[1].buy_times
	local limit = activityData.detail.charges[1].limit_times

	if limit <= buyTimes then
		xyd.applyChildrenGrey(self.btnBuy_.gameObject)

		self.btnBuy_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	end

	self.labelLimit_.text = __("BUY_GIFTBAG_LIMIT", tostring(limit - buyTimes))
end

return LevelFund
