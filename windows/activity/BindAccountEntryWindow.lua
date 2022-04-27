local ActivityContent = import(".ActivityContent")
local BindAccountEntryWindow = class("BindAccountEntryWindow", ActivityContent)
local ActivityModel = xyd.models.activity

function BindAccountEntryWindow:ctor(parentGO, params, parent)
	ActivityContent.ctor(self, parentGO, params, parent)

	self.collectionBefore = xyd.models.slot:getCollectionCopy()
end

function BindAccountEntryWindow:getPrefabPath()
	return "Prefabs/Windows/activity/bind_account_entry"
end

function BindAccountEntryWindow:initUI()
	ActivityContent.initUI(self)
	self:getUIComponent()
	self:initUIComponent()
	self:addEvent()
	self:setItem()
	self:updateStatus()
end

function BindAccountEntryWindow:getUIComponent()
	local winTrans = self.go.transform
	local allGroup = winTrans:NodeByName("e:Group").gameObject
	self.bindBtn = allGroup:NodeByName("bindBtn").gameObject
	self.bindBtn_uiSprite = self.bindBtn:GetComponent(typeof(UISprite))
	self.button_label = self.bindBtn:ComponentByName("button_label", typeof(UILabel))
	self.maskImg = self.bindBtn:ComponentByName("maskImg", typeof(UISprite))
	self.closeBtn = allGroup:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.imgText1 = allGroup:ComponentByName("imgText1", typeof(UISprite))
	self.imgText2 = allGroup:ComponentByName("imgText2", typeof(UISprite))
	self.itemGroup = allGroup:NodeByName("itemGroup").gameObject
	self.labelText = allGroup:ComponentByName("labelText", typeof(UILabel))
end

function BindAccountEntryWindow:initUIComponent()
	xyd.setUISpriteAsync(self.imgText1, "main_win_text_" .. xyd.Global.lang, "bind_acount_text01_" .. xyd.Global.lang, function ()
		self.imgText1:MakePixelPerfect()
	end, nil)
	xyd.setUISpriteAsync(self.imgText2, "main_win_text_" .. xyd.Global.lang, "bind_acount_text02_" .. xyd.Global.lang, function ()
		self.imgText2:MakePixelPerfect()
	end, nil)

	self.labelText.text = __("BIND_ACCOUNT_TEXT01")

	if xyd.Global.lang == "ja_jp" then
		self.imgText2:Y(215)
	end

	if xyd.Global.lang == "fr_fr" then
		self.labelText:X(60)
	end
end

function BindAccountEntryWindow:addEvent()
	UIEventListener.Get(self.bindBtn.gameObject).onClick = handler(self, function ()
		local status = xyd.models.achievement:checkBindAccount()

		if status == 0 then
			xyd.WindowManager.get():openWindow("account_window", {
				type = "register"
			})
		elseif status == 1 then
			if xyd.models.slot:getCanSummonNum() < 1 then
				xyd.openWindow("partner_slot_increase_window")

				return
			end

			xyd.models.achievement:getAward(xyd.ACHIEVEMENT_TYPE.BINDING_ACCOUNT)
		end
	end)

	self:registerEvent(xyd.event.GET_ACHIEVEMENT_AWARD, handler(self, function (____, event)
		if event.data.achieve_type ~= xyd.ACHIEVEMENT_TYPE.BINDING_ACCOUNT then
			return
		end

		local awards = xyd.tables.achievementTable:getAward(1001)

		xyd.models.summon:summonPartner(xyd.tables.itemTable:getSummonID(awards[1][1]), 1)
		self:updateStatus()
	end))
	self:registerEvent(xyd.event.ACHIEVEMENT_LIST_INFO, handler(self, self.updateStatus))
	self:updateStatus()
	self:registerEvent(xyd.event.SUMMON, handler(self, self.onBindSummon))
	self:registerEvent(xyd.event.ON_BIND_ACCOUNT, handler(self, self.onBindAccount))
end

function BindAccountEntryWindow:onBindAccount()
	xyd.models.achievement:getData()
end

function BindAccountEntryWindow:onBindSummon(event)
	local items = event.data.summon_result.items
	local partners = event.data.summon_result.partners
	local params = {}
	self.flag = false
	self.itemID_ = 0
	local callback = nil
	local hasFive = false

	if #items > 0 then
		for i in pairs(items) do
			table.insert(params, items[i])
			self:checkMore(items[i].item_id)
		end
	end

	local new5stars = {}
	local res_partners = {}

	if #partners > 0 then
		local summonCost = xyd.tables.summonTable:getCost(event.data.summon_id)
		local summonItemID = summonCost[0]
		new5stars = xyd.isHasNew5Stars(event, self.collectionBefore)

		for i, v in ipairs(partners) do
			table.insert(params, {
				item_num = 1,
				item_id = partners[i].table_id
			})
			table.insert(res_partners, partners[i].table_id)
			self:checkMore(partners[i].table_id)

			if not hasFive then
				local star = xyd.tables.partnerTable:getStar(partners[i].table_id)

				if star >= 5 then
					hasFive = true
				end
			end
		end
	end

	if hasFive then
		function callback()
			xyd.EventDispatcher.inner():dispatchEvent({
				name = xyd.event.HIGH_PRAISE
			})
		end
	end

	local effectCallBack = handler(self, function ()
		if self.flag then
			xyd.WindowManager:openWindow("alert_heros_window", {
				data = params,
				callback = callback
			})
		else
			xyd.alertItems(params, callback, __("SUMMON"))
		end
	end)

	if #new5stars > 0 then
		xyd.WindowManager.get():openWindow("summon_effect_res_window", {
			partners = {
				new5stars[1].table_id
			},
			callback = effectCallBack
		})
	else
		effectCallBack()
	end

	self:updateStatus()
end

function BindAccountEntryWindow:checkMore(itemID)
	if self.itemID_ ~= 0 and self.itemID_ ~= itemID then
		self.flag = true
	else
		self.itemID_ = itemID
	end
end

function BindAccountEntryWindow:setItem()
	local awrads = xyd.tables.achievementTable:getAward(1001)
	local itemGroup = self.itemGroup

	for idx in pairs(awrads) do
		local item = xyd.getItemIcon({
			itemID = 543007,
			uiRoot = itemGroup
		})
	end
end

function BindAccountEntryWindow:updateStatus()
	local status = xyd.models.achievement:checkBindAccount()
	local bindBtn = self.bindBtn

	if status == 0 then
		self.maskImg:SetActive(false)

		self.button_label.text = __("GO_BIND_ACCOUNT")

		xyd.setUISpriteAsync(self.bindBtn_uiSprite, nil, "mana_week_card_btn01", nil, )

		self.button_label.color = Color.New2(3224980479.0)
		self.button_label.effectColor = Color.New2(4294967295.0)
	elseif status == 1 then
		self.maskImg:SetActive(false)

		self.button_label.text = __("GET2")

		xyd.setUISpriteAsync(self.bindBtn_uiSprite, nil, "green_btn_192_67", nil, )

		self.button_label.color = Color.New2(4294967295.0)
		self.button_label.effectColor = Color.New2(560209151)
	else
		self.maskImg:SetActive(true)
		xyd.setUISpriteAsync(self.bindBtn_uiSprite, nil, "green_btn_192_67", nil, )

		self.button_label.text = __("ALREADY_GET_PRIZE")
		self.button_label.color = Color.New2(4294967295.0)
		self.button_label.effectColor = Color.New2(560209151)
	end

	local win = xyd.WindowManager.get():getWindow("main_window")

	self:updateRedMark()
end

function BindAccountEntryWindow:updateRedMark()
	local data = ActivityModel:updateRedMarkCount(xyd.ActivityID.BIND_ACCOUNT_ENTRY, function ()
		xyd.models.achievement.isShowBindAccountRedMark = xyd.models.achievement:checkBindAccount() ~= 2
	end)
end

return BindAccountEntryWindow
