local ActivityContent = import(".ActivityContent")
local WarmUpGift = class("WarmUpGift", ActivityContent)
local GiftBagTable = xyd.tables.giftBagTable
local GiftBagTextTable = xyd.tables.giftBagTextTable

function WarmUpGift:ctor(parentGO, params, parent)
	WarmUpGift.super.ctor(self, parentGO, params, parent)
end

function WarmUpGift:getPrefabPath()
	return "Prefabs/Windows/activity/warm_up_gift"
end

function WarmUpGift:getUIComponent()
	local go = self.go
	local contentGroup = go:NodeByName("contentGroup").gameObject
	local groupMain = contentGroup:NodeByName("groupMain").gameObject
	self.groupMain = groupMain
	local priceGroup = groupMain:NodeByName("priceGroup").gameObject
	self.btnPurchase = priceGroup:NodeByName("btnPurchase").gameObject
	self.labelLimit = priceGroup:ComponentByName("labelLimit", typeof(UILabel))
	self.labelVIP = priceGroup:ComponentByName("labelVIP", typeof(UILabel))
	self.awardGroup = groupMain:NodeByName("awardGroup").gameObject
	self.awardNum = self.awardGroup:ComponentByName("num", typeof(UILabel))
	self.taskAwardGroup = self.awardGroup:NodeByName("taskAwardGroup").gameObject
	self.taskAwardtTitle = self.taskAwardGroup:ComponentByName("title", typeof(UILabel))
	self.taskAwardIconGroup = self.taskAwardGroup:NodeByName("iconGroup").gameObject
	self.taskAwardIconGroup_Grid = self.taskAwardGroup:ComponentByName("iconGroup", typeof(UIGrid))
	self.giftBgaAwardGroup = self.awardGroup:NodeByName("giftBgaAwardGroup").gameObject
	self.giftBgaAwardTitle = self.giftBgaAwardGroup:ComponentByName("title", typeof(UILabel))
	self.giftBgaAwardIconGroup = self.giftBgaAwardGroup:NodeByName("iconGroup").gameObject
	self.giftBgaAwardIconGroup_Grid = self.giftBgaAwardGroup:ComponentByName("iconGroup", typeof(UIGrid))
	local salesGroup = groupMain:NodeByName("salesGroup").gameObject
	self.salesLabel = salesGroup:ComponentByName("text", typeof(UILabel))
	local avatarFrameGroup = contentGroup:NodeByName("avatarFrameGroup").gameObject
	self.avatarFrameGroup = avatarFrameGroup
	self.avatarFrameLabel = avatarFrameGroup:ComponentByName("avatarFrameLabel", typeof(UILabel))
	self.iconGroup = avatarFrameGroup:NodeByName("iconGroup").gameObject
	self.helpBtn = contentGroup:NodeByName("helpBtn").gameObject
	self.imgText = go:ComponentByName("imgText", typeof(UITexture))
	self.missionBtn = contentGroup:NodeByName("missionBtn").gameObject
	self.missionBtnLabel = self.missionBtn:ComponentByName("label", typeof(UILabel))
	self.missionBtnEffectNode = self.missionBtn:NodeByName("effect").gameObject
end

function WarmUpGift:initUIComponent()
	self.go:Y(-510 + -20 * self.scale_num_contrary)

	if xyd.Global.lang == "ja_jp" or xyd.Global.lang == "zh_tw" then
		local titleBg = self.taskAwardGroup:ComponentByName("titleBg", typeof(UISprite))
		titleBg.width = 250
		self.taskAwardtTitle.width = 200
	end

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "en_en" then
		local titleBg = self.taskAwardGroup:ComponentByName("titleBg", typeof(UISprite))
		titleBg.width = 280
		self.taskAwardtTitle.width = 250
	end

	if xyd.Global.lang == "fr_fr" then
		local titleBg = self.taskAwardGroup:ComponentByName("titleBg", typeof(UISprite))
		local titleBg2 = self.giftBgaAwardGroup:ComponentByName("titleBg", typeof(UISprite))
		titleBg.width = 300
		titleBg2.width = 172
		self.taskAwardtTitle.width = 280
	end

	if xyd.Global.lang == "ko_kr" then
		local titleBg = self.taskAwardGroup:ComponentByName("titleBg", typeof(UISprite))
		local titleBg2 = self.giftBgaAwardGroup:ComponentByName("titleBg", typeof(UISprite))
		titleBg.width = 250
		self.taskAwardtTitle.width = 200
		self.taskAwardtTitle.fontSize = 22
		self.taskAwardtTitle.height = 22
		self.giftBgaAwardTitle.fontSize = 22
		self.giftBgaAwardTitle.height = 22
	end

	local gigtbagID = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.WARMUP_GIFT)
	local giftID = xyd.tables.giftBagTable:getGiftID(gigtbagID[1])
	local items = xyd.tables.giftTable:getAwards(giftID)
	self.icon_ = xyd.getItemIcon({
		itemID = items[2][1],
		num = items[2][2],
		uiRoot = self.iconGroup
	})

	self.icon_:setImgBorder_("avator_bg", 30)

	self.missionBtnLabel.text = __("ACTIVITY_WARMUP_PACK_TEXT06")
	local effect = xyd.Spine.new(self.missionBtnEffectNode)

	effect:setInfo("fx_warmup_gift_show", function ()
		effect:play("texiao01", 0)
	end)

	local items = {}
	local awards = xyd.tables.giftTable:getAwards(giftID)

	dump(awards)

	for i = 3, #awards do
		items[awards[i][1]] = (items[awards[i][1]] or 0) + awards[i][2]
	end

	for k, v in pairs(items) do
		xyd.getItemIcon({
			itemID = tonumber(k),
			num = tonumber(v),
			uiRoot = self.giftBgaAwardIconGroup
		})
	end

	self.giftBgaAwardTitle.text = __("WARM_UP_GIFT_TEXT_02")
	local items = {}
	local ids = xyd.tables.activityWarmupArenaTaskAwardTable:getIDs()

	dump(ids)

	for k, v in pairs(ids) do
		local awards = xyd.tables.activityWarmupArenaTaskAwardTable:getPackAwards(v)

		for i = 1, #awards do
			items[awards[i][1]] = (items[awards[i][1]] or 0) + awards[i][2]
		end
	end

	for k, v in pairs(items) do
		xyd.getItemIcon({
			itemID = tonumber(k),
			num = tonumber(v),
			uiRoot = self.taskAwardIconGroup
		})
	end

	self.taskAwardtTitle.text = __("WARM_UP_GIFT_TEXT_01")
end

function WarmUpGift:resizeToParent()
	WarmUpGift.super.resizeToParent(self)
	self:resizePosY(self.groupMain, -110, -223)
	self:resizePosY(self.avatarFrameGroup, 162, 111)
end

function WarmUpGift:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)

	self.giftbag_id = self.activityData.detail_.charges[1].table_id

	self:initUIComponent()
	self:setText()
	self:setBtnState()
end

function WarmUpGift:setText()
	local buy_time = self.activityData.detail_.charges[1].buy_times
	self.avatarFrameLabel.text = __("ACTIVITY_WARMUP_PACK_TEXT04")
	self.salesLabel.text = __("ACTIVITY_WARMUP_PACK_TEXT05")
	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", GiftBagTable:getBuyLimit(self.giftbag_id) - buy_time)
	self.labelVIP.text = "+" .. tostring(GiftBagTable:getVipExp(self.giftbag_id)) .. " VIP EXP"
	local ids = xyd.tables.activityWarmCardAwardTable:getIds()
	self.awardNum.text = "40"

	xyd.setUITextureAsync(self.imgText, "Textures/activity_text_web/warm_up_gift_text_" .. xyd.Global.lang)
end

function WarmUpGift:setBtnState()
	local data = self.activityData.detail_.charges[1]
	local giftBagID = data.table_id
	local purchaseLabel = self.btnPurchase:ComponentByName("button_label", typeof(UILabel))
	purchaseLabel.text = tostring(GiftBagTextTable:getCurrency(giftBagID)) .. " " .. tostring(GiftBagTextTable:getCharge(giftBagID))

	if data.buy_times < data.limit_times then
		xyd.setEnabled(self.btnPurchase, true)
	else
		xyd.setEnabled(self.btnPurchase, false)
	end
end

function WarmUpGift:onRegister()
	ActivityContent.onRegister(self)

	UIEventListener.Get(self.btnPurchase).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftbag_id)
	end

	UIEventListener.Get(self.missionBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_entrance_test_challenge_task_window", {
			showJumpBtn = true
		})
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		local params = {
			key = "ACTIVITY_WARMUP_PACK_HELP"
		}

		if xyd.Global.lang == "fr_fr" then
			params.myFontSize = 18
		end

		local wnd = xyd.openWindow("help_window", params)
	end

	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function WarmUpGift:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if GiftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	self.activityData:updateInfo()
	self:setBtnState()
end

return WarmUpGift
