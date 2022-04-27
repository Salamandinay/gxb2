local BaseWindow = import(".BaseWindow")
local BaseComponent = import("app.components.BaseComponent")
local NewPartnerWarmingUpEntryWindow = class("NewPartnerWarmingUpEntryWindow", BaseWindow)
local NewPartnerWarmingUpEntryAwardItem = class("NewPartnerWarmingUpEntryAwardItem", BaseComponent)
local NewPartnerWarmingUpProgressItem = class("NewPartnerWarmingUpProgressItem")
local CountDown = import("app.components.CountDown")
local ActivityModel = xyd.models.activity

function NewPartnerWarmingUpEntryWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.items_ = {}
	self.partner_challenge_fort_id_ = 1
	self.arrow_action_ = self:getSequence()
	self.data_flag_ = false
	self.ui_flag_ = false
	local needLoadRes = {}

	table.insert(needLoadRes, xyd.getSpritePath("partner_preheat_bg01"))
	table.insert(needLoadRes, xyd.getSpritePath("partner_preheat_text01_" .. xyd.Global.lang))
	self:setResourcePaths(needLoadRes)
end

function NewPartnerWarmingUpEntryWindow:playOpenAnimation(callback)
	NewPartnerWarmingUpEntryWindow.super.playOpenAnimation(self, function ()
		local fr = 30
		local action = self:getSequence()

		local function setter1(value)
			self.Bg01.alpha = value
		end

		self.Bg01.alpha = 0
		self.Bg01.transform.localScale = Vector3(0.2, 0.2, 0.2)

		local function setter3(value)
			self.contentGroup_widget.alpha = value
		end

		self.contentGroup_widget.alpha = 0
		self.contentGroup_widget.transform.localScale = Vector3(0.5, 0.5, 0.5)
		local contentGroup_X = self.contentGroup_widget.transform.localPosition.x
		local contentGroup_Y = self.contentGroup_widget.transform.localPosition.y

		self.contentGroup_widget.transform:X(contentGroup_X - 3.9656)
		self.contentGroup_widget.transform:Y(contentGroup_Y - 28.54)

		local function setter4(value)
			self.nameGroup.alpha = value
		end

		self.nameGroup.alpha = 0
		self.nameGroup.transform.localScale = Vector3(0, 0, 0)

		local function setter5(value)
			self.textImg01.alpha = value
		end

		self.textImg01.alpha = 0
		self.textImg01.transform.localScale = Vector3(1, 1, 1)

		action:Insert(0 / fr, self.Bg01.transform:DOScale(Vector3(1.2, 1.2, 1.2), 9 / fr))
		action:Insert(9 / fr, self.Bg01.transform:DOScale(Vector3(0.97, 0.97, 0.97), 4 / fr))
		action:Insert(13 / fr, self.Bg01.transform:DOScale(Vector3(1, 1, 1), 5 / fr))
		action:Insert(0 / fr, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 4 / fr))
		action:Insert(0 / fr, self.contentGroup_widget.transform:DOScale(Vector3(0.24, 0.24, 0.24), 40 / fr))
		action:Insert(40 / fr, self.contentGroup_widget.transform:DOScale(Vector3(1.1, 1.1, 1.1), 8 / fr))
		action:Insert(48 / fr, self.contentGroup_widget.transform:DOScale(Vector3(0.98, 0.98, 0.98), 3 / fr))
		action:Insert(51 / fr, self.contentGroup_widget.transform:DOScale(Vector3(1, 1, 1), 4 / fr))
		action:Insert(0 / fr, self.contentGroup_widget.transform:DOLocalMove(Vector3(contentGroup_X, contentGroup_Y - 28.54, 0), 40 / fr))
		action:Insert(40 / fr, self.contentGroup_widget.transform:DOLocalMove(Vector3(contentGroup_X, contentGroup_Y + 2, 0), 8 / fr))
		action:Insert(48 / fr, self.contentGroup_widget.transform:DOLocalMove(Vector3(contentGroup_X, contentGroup_Y, 0), 3 / fr))
		action:Insert(40 / fr, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 0, 1, 4 / fr))
		action:Insert(0 / fr, self.nameGroup.transform:DOScale(Vector3(0.4, 0.4, 0.4), 35 / fr))
		action:Insert(35 / fr, self.nameGroup.transform:DOScale(Vector3(1.3, 1.3, 1.3), 6 / fr))
		action:Insert(41 / fr, self.nameGroup.transform:DOScale(Vector3(0.93, 0.93, 0.93), 4 / fr))
		action:Insert(45 / fr, self.nameGroup.transform:DOScale(Vector3(1, 1, 1), 4 / fr))
		action:Insert(35 / fr, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter4), 0, 1, 2 / fr))
		action:Insert(0 / fr, self.textImg01.transform:DOScale(Vector3(2.5, 2.5, 2.5), 22 / fr))
		action:Insert(22 / fr, self.textImg01.transform:DOScale(Vector3(0.8, 0.8, 0.8), 8 / fr))
		action:Insert(30 / fr, self.textImg01.transform:DOScale(Vector3(1.1, 1.1, 1.1), 5 / fr))
		action:Insert(35 / fr, self.textImg01.transform:DOScale(Vector3(1, 1, 1), 6 / fr))
		action:Insert(22 / fr, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter5), 0, 1, 3 / fr))

		if callback then
			callback()
		end
	end)
end

function NewPartnerWarmingUpEntryWindow:initWindow()
	NewPartnerWarmingUpEntryWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:dataInit()
	self:resizeToParent()
	self:registerEvent()
	self:playArrow()
	ActivityModel:reqActivityByID(xyd.ActivityID.NEW_PARTNER_WARMUP)
end

function NewPartnerWarmingUpEntryWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainGroup = winTrans:NodeByName("groupAction").gameObject
	self.BgGroup = mainGroup:ComponentByName("BgGroup", typeof(UIWidget))
	self.nameGroup = mainGroup:ComponentByName("nameGroup", typeof(UIWidget))
	self.NameLabel_1 = mainGroup:ComponentByName("nameGroup/label_", typeof(UILabel))
	self.nameGroup2 = mainGroup:ComponentByName("nameGroup2", typeof(UIWidget))
	self.NameLabel_2 = mainGroup:ComponentByName("nameGroup2/label_", typeof(UILabel))
	self.Bg01 = mainGroup:ComponentByName("BgGroup/Bg01", typeof(UISprite))
	self.Bg02 = mainGroup:ComponentByName("BgGroup/Bg02", typeof(UISprite))
	self.Bg03 = mainGroup:ComponentByName("BgGroup/Bg03", typeof(UISprite))
	self.effect1 = mainGroup:NodeByName("effect1").gameObject
	self.effect2 = mainGroup:NodeByName("effect2").gameObject
	self.touchGroup = mainGroup:NodeByName("touchGroup").gameObject
	self.textGroupNode = mainGroup:NodeByName("textGroup").gameObject
	self.textGroup = mainGroup:ComponentByName("textGroup", typeof(UIWidget))
	self.textGroup_boxCollider = self.textGroup:GetComponent(typeof(UnityEngine.BoxCollider))
	self.textBg_ = self.textGroup:ComponentByName("textBg_", typeof(UISprite))
	self.textLabel_ = self.textGroup:ComponentByName("textLabel_", typeof(UILabel))
	self.textImg01 = mainGroup:ComponentByName("textImg01", typeof(UISprite))
	self.contentGroup = mainGroup:NodeByName("contentGroup").gameObject
	self.contentGroup_widget = self.contentGroup:GetComponent(typeof(UIWidget))
	self.awardGroup = self.contentGroup:NodeByName("awardGroup").gameObject
	self.prepareBtn = self.contentGroup:NodeByName("prepareBtn").gameObject
	self.progressGroup = self.contentGroup:NodeByName("progressGroup").gameObject
	self.prepareDescLabel = self.contentGroup:ComponentByName("prepareGroup/prepareDescLabel", typeof(UILabel))
	self.prepareCountLabel = self.contentGroup:ComponentByName("prepareGroup/prepareCountLabel", typeof(UILabel))
	self.timeLabel = self.contentGroup:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.endLabel = self.contentGroup:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.helpBtn = self.contentGroup:NodeByName("helpBtn").gameObject
	self.tipsGroup = self.contentGroup:NodeByName("tipsGroup").gameObject
	self.tipsEffectGroup = self.tipsGroup:NodeByName("tipsEffectGroup").gameObject
	self.tipsItemGroup = self.tipsGroup:NodeByName("tipsItemGroup").gameObject
	self.itemNumLabel = self.tipsGroup:ComponentByName("itemNumLabel", typeof(UILabel))
	self.jumpGroup = self.contentGroup:NodeByName("jumpGroup").gameObject
	self.jumpGroup_widget = self.jumpGroup:GetComponent(typeof(UIWidget))
	self.buyGiftBtn = self.jumpGroup:NodeByName("buyGiftBtn").gameObject
	self.arrowImg = self.jumpGroup:NodeByName("arrowImg").gameObject
end

function NewPartnerWarmingUpEntryWindow:initUIComponent()
	xyd.setUISpriteAsync(self.textImg01, nil, "partner_preheat_text01_" .. xyd.Global.lang, nil, , true)

	self.textLabel_.text = __("ENTRANCE_TEST_COMING")
	self.prepareBtn:ComponentByName("button_label", typeof(UILabel)).text = __("NEW_PARTNER_WARMING_UP_TEXT01")
	self.prepareDescLabel.text = __("NEW_PARTNER_WARMING_UP_TEXT02")
	self.endLabel.text = __("END_TEXT")
	self.buyGiftBtn:ComponentByName("button_label", typeof(UILabel)).text = __("WARM_UP_JUMP_TEXT")
	local partnerID = xyd.split(xyd.tables.miscTable:getVal("activity_gacha_partners"), "|", true)
	self.NameLabel_1.text = xyd.tables.partnerTable:getName(partnerID[1])

	CountDown.new(self.timeLabel, {
		duration = self:getTime() - xyd.getServerTime()
	})

	local days = #xyd.tables.newPartnerWarmUpStageTable:getIds()

	for i = 1, days do
		NewPartnerWarmingUpProgressItem.new(self.progressGroup)
	end

	self.progressGroup:GetComponent(typeof(UILayout)):Reposition()

	local ids = xyd.tables.newPartnerWarmUpAwardTable:getIds()

	for i = 1, #ids do
		local item = NewPartnerWarmingUpEntryAwardItem.new(self.awardGroup, {
			id = ids[i],
			server_num = self:getCount(),
			is_awarded = self:checkIsAwarded(ids[i])
		})

		table.insert(self.items_, item)
	end

	self.awardGroup:GetComponent(typeof(UILayout)):Reposition()
end

function NewPartnerWarmingUpEntryWindow:initEffect()
end

function NewPartnerWarmingUpEntryWindow:dataInit()
	self.prepareCountLabel.text = tostring(self:getCount())

	if self:checkTips() then
		self.tipsGroup:SetActive(true)
	else
		self.tipsGroup:SetActive(false)
	end

	self:updateServerNum()
	self:updateTips()
end

function NewPartnerWarmingUpEntryWindow:updateServerNum()
	for i = 1, #self.items_ do
		local item = self.items_[i]

		item:updateCount(self:getCount(), self:checkIsAwarded(i))
	end

	self:updateProgress()
end

function NewPartnerWarmingUpEntryWindow:updateProgress()
	local childNum = self.progressGroup.transform.childCount
	local data = ActivityModel:getActivity(xyd.ActivityID.NEW_PARTNER_WARMUP)

	if not data then
		return
	end

	local stage_id = data.detail_.current_stage

	for i = 1, childNum do
		local item = self.progressGroup.transform:GetChild(i - 1)
		local star = item:NodeByName("star").gameObject

		star:SetActive(stage_id == -1 or i < stage_id)
	end
end

function NewPartnerWarmingUpEntryWindow:updateTips()
	if self:checkTips() then
		self.tipsGroup:SetActive(true)

		local stage_id = ActivityModel:getActivity(xyd.ActivityID.NEW_PARTNER_WARMUP).detail_.current_stage or 1
		local awards = xyd.tables.newPartnerWarmUpStageTable:getReward(stage_id)

		NGUITools.DestroyChildren(self.tipsItemGroup.transform)

		for i = 1, #awards do
			local item = NGUITools.AddChild(self.tipsItemGroup, "item")
			local sprite = item:AddComponent(typeof(UISprite))

			xyd.setUISpriteAsync(sprite, nil, xyd.tables.itemTable:getIcon(awards[i][1]))

			self.itemNumLabel.text = awards[i][2]
			sprite.width = 40
			sprite.height = 40
			sprite.depth = 35
		end

		xyd.setEnabled(self.prepareBtn, true)
	else
		local data = ActivityModel:getActivity(xyd.ActivityID.NEW_PARTNER_WARMUP)

		if data then
			local stage_id = data.detail_.current_stage

			if stage_id == -1 then
				xyd.setEnabled(self.prepareBtn, false)
			end
		end

		self.tipsGroup:SetActive(false)
	end
end

function NewPartnerWarmingUpEntryWindow:registerEvent()
	BaseWindow.register(self)

	UIEventListener.Get(self.buyGiftBtn).onClick = handler(self, self.onClicJump)

	UIEventListener.Get(self.prepareBtn).onClick = function ()
		local data = ActivityModel:getActivity(xyd.ActivityID.NEW_PARTNER_WARMUP)

		if not data then
			return
		end

		local stage_id = data.detail_.current_stage

		if not self:checkTips() then
			if stage_id ~= -1 then
				xyd.showToast(__("NEW_PARTNER_WARMING_UP_CLOSETIP"))
			end

			return
		end

		local msg = messages_pb.new_partner_warmup_fight_req()
		msg.activity_id = xyd.ActivityID.NEW_PARTNER_WARMUP
		msg.stage_id = stage_id

		xyd.Backend.get():request(xyd.mid.NEW_PARTNER_WARMUP_FIGHT, msg)
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local activity_id = event.data.activity_id

		if activity_id ~= xyd.ActivityID.NEW_PARTNER_WARMUP then
			return
		end

		local ids = xyd.tables.newPartnerWarmUpAwardTable:getIds()
		local count = self:getCount()

		for i = 1, #ids do
			local id = ids[i]
			local num = xyd.tables.newPartnerWarmUpAwardTable:getAmount(id)
			local isAwarded = self:checkIsAwarded(id)

			if num <= count and not isAwarded then
				ActivityModel:reqAwardWithParams(xyd.ActivityID.NEW_PARTNER_WARMUP, tostring(id))

				return
			end
		end

		self:updateServerNum()
	end)
	self.eventProxy_:addEventListener(xyd.event.NEW_PARTNER_WARMUP_FIGHT, handler(self, self.dataInit))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.dataInit))
end

function NewPartnerWarmingUpEntryWindow:playArrow()
	local transform = self.arrowImg.transform
	local position = transform.localPosition
	local x = position.x
	local y = position.y

	self.arrow_action_:Append(transform:DOLocalMove(Vector3(x + 5, y, 0), 0.2))
	self.arrow_action_:Append(transform:DOLocalMove(Vector3(x - 10, y, 0), 0.4))
	self.arrow_action_:Append(transform:DOLocalMove(Vector3(x, y, 0), 0.2))
	self.arrow_action_:SetLoops(-1)
end

function NewPartnerWarmingUpEntryWindow:onClicJump()
	ActivityModel:removeLimitGiftParams()

	local actwin = xyd.getWindow("activity_window")

	if actwin then
		xyd.closeWindow("activity_window")
	end

	xyd.openWindow("activity_window", {
		activity_type = xyd.EventType.LIMIT,
		select = xyd.ActivityID.WARMUP_GIFT
	}, function ()
		local win = xyd.getWindow("activity_window")

		if win then
			self:close()
			xyd.closeWindow("summon_window")
		end
	end)
end

function NewPartnerWarmingUpEntryWindow:checkIsAwarded(id)
	local data = xyd.models.activity:getActivity(xyd.ActivityID.NEW_PARTNER_WARMUP)

	if data then
		return data.detail_.rewards[tonumber(id)] ~= 0
	end

	return false
end

function NewPartnerWarmingUpEntryWindow:checkTips()
	local data = ActivityModel:getActivity(xyd.ActivityID.NEW_PARTNER_WARMUP)

	if data then
		local stage_id = data.detail_.current_stage
		local cur_days = math.ceil((xyd.getServerTime() - data.start_time) / 86400)

		if stage_id == -1 or cur_days < stage_id then
			return false
		else
			return true
		end
	end

	return false
end

function NewPartnerWarmingUpEntryWindow:getCount()
	local data = ActivityModel:getActivity(xyd.ActivityID.NEW_PARTNER_WARMUP)

	if data then
		return data.detail_.stage_play_count
	end

	return 0
end

function NewPartnerWarmingUpEntryWindow:getTime()
	local data = ActivityModel:getActivity(xyd.ActivityID.NEW_PARTNER_WARMUP)

	if data then
		return data:getUpdateTime()
	end

	return 0
end

function NewPartnerWarmingUpEntryWindow:resizeToParent()
	local stageHeight = xyd.Global.getRealHeight()
	local num = (stageHeight - 1280) / (xyd.Global.getMaxHeight() - 1280)

	if xyd.Global.getMaxHeight() < stageHeight then
		num = 1
	end

	local scale_num = 1 - num

	self.window_.transform:NodeByName("groupAction").gameObject:Y(-78 * scale_num)
end

function NewPartnerWarmingUpEntryAwardItem:ctor(parentGo, params)
	self.effect_ = nil

	if params then
		self.id_ = params.id
		self.server_num_ = params.server_num
		self.is_awarded_ = params.is_awarded
	end

	NewPartnerWarmingUpEntryAwardItem.super.ctor(self, parentGo)
end

function NewPartnerWarmingUpEntryAwardItem:getPrefabPath()
	return "Prefabs/Windows/new_partner_warming_up_entry_award_item"
end

function NewPartnerWarmingUpEntryAwardItem:getUIComponent()
	local go = self.go
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.countLabel = go:ComponentByName("countLabel", typeof(UILabel))
	self.effect_ = go:NodeByName("effect_").gameObject
end

function NewPartnerWarmingUpEntryAwardItem:initUIComponent()
	self.countLabel.text = __("NEW_PARTNER_WARMING_UP_TEXT05_" .. tostring(self.id_), xyd.tables.newPartnerWarmUpAwardTable:getAmount(self.id_))
	local award = xyd.tables.newPartnerWarmUpAwardTable:getAwards(self.id_)
	local item = xyd.getItemIcon({
		noClickSelected = true,
		scale = 0.5925925925925926,
		itemID = award[1],
		num = award[2],
		uiRoot = self.itemGroup
	})
	self.item_ = item
end

function NewPartnerWarmingUpEntryAwardItem:initUI()
	NewPartnerWarmingUpEntryAwardItem.super.initUI(self)
	self:getUIComponent()
	self:initUIComponent()
	self:updateStates()
end

function NewPartnerWarmingUpEntryAwardItem:updateCount(server_num, is_awarded)
	self.server_num_ = server_num
	self.is_awarded_ = is_awarded

	self:updateStates()
end

function NewPartnerWarmingUpEntryAwardItem:updateStates()
	if xyd.tables.newPartnerWarmUpAwardTable:getAmount(self.id_) <= self.server_num_ then
		if self.is_awarded_ then
			self.item_:setNoClick(true)
			self.item_:setChoose(true)
			self:removeAwardEffect()
		else
			function self.item_.callback()
				ActivityModel:reqAwardWithParams(xyd.ActivityID.NEW_PARTNER_WARMUP, tostring(self.id_))
			end

			self:addAwardEffect()
		end
	else
		self.item_:setNoClick(false)
		self:removeAwardEffect()
	end
end

function NewPartnerWarmingUpEntryAwardItem:addAwardEffect()
	if self.effect_.transform.childCount == 0 then
		local effect = xyd.Spine.new(self.effect_)

		effect:setInfo("fx_ui_warmup_available", function (fx)
			effect:play("texiao01", 0)
		end)
	end

	self.effect_:SetActive(true)
end

function NewPartnerWarmingUpEntryAwardItem:removeAwardEffect()
	if self.effect_ then
		self.effect_:SetActive(false)
	end
end

function NewPartnerWarmingUpProgressItem:ctor(parentGo)
	local item = NGUITools.AddChild(parentGo, "progressItem")
	local widget = item:AddComponent(typeof(UIWidget))
	widget.depth = 35
	widget.width = 30
	widget.height = 30
	self.bg = NGUITools.AddChild(item, "bg"):AddComponent(typeof(UISprite))
	self.star = NGUITools.AddChild(item, "star"):AddComponent(typeof(UISprite))

	xyd.setUISpriteAsync(self.bg, nil, "partner_preheat_star_icon0", function ()
		self.bg:MakePixelPerfect()
	end)
	xyd.setUISpriteAsync(self.star, nil, "partner_preheat_star_icon1", function ()
		self.star:MakePixelPerfect()
	end)

	self.bg.depth = 10
	self.star.depth = 11

	self.star:SetActive(false)
end

return NewPartnerWarmingUpEntryWindow
