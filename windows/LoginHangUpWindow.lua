local BaseWindow = import(".BaseWindow")
local LoginHangUpWindow = class("LoginHangUpWindow", BaseWindow)
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local AwardItems = class("AwardItems", import("app.common.ui.FixedMultiWrapContentItem"))
local StageTable = xyd.tables.stageTable

function LoginHangUpWindow:ctor(name, params)
	LoginHangUpWindow.super.ctor(self, name, params)

	self.item_icons_ = {}
	self.ui_action_flag_ = false
	self.banner_action_flag_ = false
	self.content_action_flag_ = false
	self.item_action_flag_ = false
	self.tips_action_flag_ = false
	self.text_action_flag_ = false
	self.stage_id_ = params.stage_id
	self.gold_ = params.gold
	self.partner_exp_ = params.partner_exp
	self.exp_ = params.exp
	self.items_ = params.items
	local goldBase = xyd.split(StageTable:getGold(self.stage_id_), "#")[2]
	local goldPlus = 0
	local vip_lev = xyd.models.backpack:getVipLev()

	if vip_lev >= 1 then
		local count = xyd.tables.vipTable:extraOutput(vip_lev)
		goldPlus = goldPlus + count
	end

	if xyd.models.activity:isManaCardPurchased() then
		goldPlus = goldPlus + xyd.tables.miscTable:getNumber("subscription_rate_gold", "value")
	end

	goldPlus = goldBase * (goldPlus / 100 + 1) / 5
	local info = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
	local dropTime = info.drop_award_time
	local addTime = xyd.models.dress:getActiveSkillsNum(xyd.DressBuffAttrType.HANG_UP)
	local maxHangTime = xyd.tables.miscTable:getNumber("hang_up_time_max", "value")
	local minTime = maxHangTime + addTime
	self.time_ = math.min(xyd.getServerTime() - dropTime, minTime)
	self.skinName = "LoginHangUpWindowSkin"
	self.top = 0
end

function LoginHangUpWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.mainGroup = winTrans:NodeByName("mainGroup").gameObject
	self.cotentGroup = self.mainGroup:NodeByName("cotentGroup").gameObject
	self.bgImg = self.cotentGroup:ComponentByName("bgImg", typeof(UITexture))
	self.textGroup = self.cotentGroup:NodeByName("textGroup").gameObject
	self.textBg = self.textGroup:ComponentByName("textBg", typeof(UISprite))
	self.welcomeLabel = self.textGroup:ComponentByName("welcomeLabel", typeof(UILabel))
	self.touchGroup = self.mainGroup:NodeByName("touchGroup").gameObject
	self.groupAwards = self.mainGroup:NodeByName("groupAwards").gameObject
	self.bannerGroup = self.groupAwards:NodeByName("bannerGroup").gameObject
	self.group = self.groupAwards:NodeByName("group").gameObject
	self.actionGroup1 = self.group:NodeByName("actionGroup1").gameObject
	self.textImg = self.actionGroup1:ComponentByName("textImg", typeof(UISprite))
	self.actionGroup2 = self.group:NodeByName("actionGroup2").gameObject
	self.timeDescLabel = self.actionGroup2:ComponentByName("timeDescLabel", typeof(UILabel))
	self.timeLabel = self.actionGroup2:ComponentByName("timeLabel", typeof(UILabel))
	self.actionGroup3 = self.group:NodeByName("actionGroup3").gameObject
	self.stageDescLabel = self.actionGroup3:ComponentByName("stageDescLabel", typeof(UILabel))
	self.stageLabel = self.actionGroup3:ComponentByName("stageLabel", typeof(UILabel))
	self.actionGroup4 = self.group:NodeByName("actionGroup4").gameObject
	self.goldLabel = self.actionGroup4:ComponentByName("goldLabel", typeof(UILabel))
	self.partnerExpLabel = self.actionGroup4:ComponentByName("partnerExpLabel", typeof(UILabel))
	self.expLabel = self.actionGroup4:ComponentByName("expLabel", typeof(UILabel))
	self.scrollView = self.group:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scrollView:ComponentByName("itemGroup", typeof(UIWrapContent))
	local itemCell = self.scrollView:NodeByName("item").gameObject
	self.tipsLabel = self.group:ComponentByName("tipsLabel", typeof(UILabel))
	self.groupNone = self.group:NodeByName("groupNone").gameObject
	self.labelNoneTips = self.groupNone:ComponentByName("labelNoneTips", typeof(UILabel))
	self.posGroup = self.mainGroup:NodeByName("posGroup").gameObject
	self.wrapContent_ = FixedMultiWrapContent.new(self.scrollView, self.itemGroup, itemCell, AwardItems, self)
end

function LoginHangUpWindow:initWindow()
	LoginHangUpWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initItems()
	self:registerEvent()
	self:playAction()
end

function LoginHangUpWindow:layout()
	xyd.setTouchEnable(self.touchGroup, false)
	self:waitForTime(1, function ()
		xyd.setTouchEnable(self.touchGroup, true)
	end)

	self.welcomeLabel.text = __("AUTO_BATTLE_RESULTS_TALK")

	xyd.setUISpriteAsync(self.textImg, nil, "login_hangup_text01_" .. xyd.Global.lang)

	self.goldLabel.text = xyd.getRoughDisplayNumber(self.gold_)
	self.expLabel.text = xyd.getRoughDisplayNumber(self.exp_)
	self.partnerExpLabel.text = xyd.getRoughDisplayNumber(self.partner_exp_)
	self.timeLabel.text = self:getDisplayTime()
	self.tipsLabel.text = __("LOGIN_HANGUP_TEXT04")
	self.timeDescLabel.text = __("LOGIN_HANGUP_TEXT02")
	self.stageDescLabel.text = __("LOGIN_HANGUP_TEXT05")
	self.stageLabel.text = __("STAGE_NAME", StageTable:getFortID(self.stage_id_), StageTable:getName(self.stage_id_))
end

function LoginHangUpWindow:registerEvent()
	UIEventListener.Get(self.touchGroup).onClick = handler(self, self.onTouchGroup)
end

function LoginHangUpWindow:initItems()
	local map_info = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
	local dropItems = {}

	for i = 1, #map_info.drop_items do
		table.insert(dropItems, map_info.drop_items[i])
	end

	if UNITY_EDITOR then
		table.insert(dropItems, {
			item_num = 1,
			item_id = 2
		})
		table.insert(dropItems, {
			item_num = 1,
			item_id = 3
		})
		table.insert(dropItems, {
			item_num = 1,
			item_id = 4
		})
		table.insert(dropItems, {
			item_num = 1,
			item_id = 2
		})
		table.insert(dropItems, {
			item_num = 1,
			item_id = 3
		})
		table.insert(dropItems, {
			item_num = 1,
			item_id = 4
		})
		table.insert(dropItems, {
			item_num = 1,
			item_id = 2
		})
		table.insert(dropItems, {
			item_num = 1,
			item_id = 3
		})
		table.insert(dropItems, {
			item_num = 1,
			item_id = 4
		})
		table.insert(dropItems, {
			item_num = 1,
			item_id = 200
		})
	end

	local activityItemMap = self:getActivityItemMap()

	table.sort(dropItems, function (a, b)
		local actIda = activityItemMap[a.item_id] or 0
		local actIdb = activityItemMap[b.item_id] or 0

		if actIda > 0 and actIdb > 0 or actIda == 0 and actIdb == 0 then
			return b.item_id < a.item_id
		else
			return actIda > 0
		end
	end)

	for _, itemData in ipairs(dropItems) do
		itemData.activityTag = activityItemMap[itemData.item_id]
	end

	self.dropItems_ = dropItems

	self.wrapContent_:setInfos(dropItems, {})
	self:waitForTime(0.5, function ()
		self.scrollView:ResetPosition()
	end)
end

function LoginHangUpWindow:getActivityItemMap()
	local activityItemMap = {}
	local actIds, tmpIds = nil
	tmpIds = xyd.split(xyd.tables.stageTable:getDropShowActivity(self.stage_id_), "|", true)
	actIds = xyd.tables.miscTable:split2num("stage_activity_dropbox", "value", "|")

	for _, itemID in pairs(tmpIds) do
		activityItemMap[itemID] = actIds[1]
	end

	for i in pairs(actIds) do
		local actId = actIds[i]
		local activityData = xyd.models.activity:getActivity(actId)

		if activityData then
			for _, itemID in pairs(tmpIds) do
				activityItemMap[itemID] = actId
			end

			break
		end
	end

	tmpIds = xyd.split(xyd.tables.stageTable:getDropShowActivity2(self.stage_id_), "|", true)
	actIds = xyd.tables.miscTable:split2num("stage_activity_dropbox2", "value", "|")

	for _, itemID in pairs(tmpIds) do
		activityItemMap[itemID] = actIds[1]
	end

	for i in pairs(actIds) do
		local actId = actIds[i]
		local activityData = xyd.models.activity:getActivity(actId)

		if activityData then
			for _, itemID in pairs(tmpIds) do
				activityItemMap[itemID] = actId
			end

			break
		end
	end

	tmpIds = xyd.split(xyd.tables.stageTable:getDropShowActivity3(self.stage_id_), "|", true)
	actIds = xyd.tables.miscTable:split2num("stage_activity_dropbox3", "value", "|")

	for _, itemID in pairs(tmpIds) do
		activityItemMap[itemID] = actIds[1]
	end

	for i in pairs(actIds) do
		local actId = actIds[i]
		local activityData = xyd.models.activity:getActivity(actId)

		if activityData then
			for _, itemID in pairs(tmpIds) do
				activityItemMap[itemID] = actId
			end

			break
		end
	end

	tmpIds = xyd.split(xyd.tables.stageTable:getDropShowActivity4(self.stage_id_), "|", true)
	actIds = xyd.tables.miscTable:split2num("stage_activity_dropbox4", "value", "|")

	for _, itemID in pairs(tmpIds) do
		activityItemMap[itemID] = actIds[1]
	end

	for i in pairs(actIds) do
		local actId = actIds[i]
		local activityData = xyd.models.activity:getActivity(actId)

		if activityData then
			for _, itemID in pairs(tmpIds) do
				activityItemMap[itemID] = actId
			end

			break
		end
	end

	return activityItemMap
end

function LoginHangUpWindow:onTouchGroup()
	UIEventListener.Get(self.touchGroup).onClick = nil

	if #self.items_ == 0 then
		xyd.closeWindow(self.name_)

		return
	end

	local win = xyd.getWindow("main_window")
	local endPos = nil

	if win then
		local tmP = win.MainwinBottomBtn_3.transform.position
		endPos = self.posGroup.transform:InverseTransformPoint(tmP.x, tmP.y, 0)
	else
		xyd.closeWindow(self.name_)

		return
	end

	self.winBg_:SetActive(false)
	self.cotentGroup:SetActive(false)
	self.groupAwards:SetActive(false)

	local items = self.wrapContent_:getItems()
	local flag = true

	for i = 1, #items do
		local item = items[i]

		if item.go.activeSelf and item.itemIcon_ then
			local go = item.itemIcon_:getGameObject()
			local worldPos = go.transform.position

			ResCache.AddChild(self.posGroup, go)

			go.transform.position = worldPos

			go:SetLocalScale(0.8333333333333334, 0.8333333333333334, 1)

			local callback = nil

			if flag then
				function callback()
					local win = xyd.getWindow("main_window")

					if win then
						win:bottomBtnOnlyShake(3, function ()
							xyd.closeWindow(self.name_)
						end)
					end
				end
			end

			flag = false

			self:collectItem(go, endPos, callback)
		end
	end
end

function LoginHangUpWindow:collectItem(go, p, callback)
	local transform = go.transform
	local action = self:getSequence()

	action:AppendInterval(0.1):Append(transform:DOScale(Vector3(0.55, 0.55, 1), 0.6)):Join(transform:DOLocalMove(p, 0.6)):AppendCallback(function ()
		transform:SetActive(false)

		if callback then
			callback()
		end
	end)
end

function LoginHangUpWindow:getDisplayTime()
	local t = math.round(self.time_)
	local sec = t % 60
	t = math.round(t / 60)
	local min = t % 60
	t = math.round(t / 60)
	local hour = t % 24
	local res = ""

	if hour > 0 then
		return __("LOGIN_HANGUP_TEXT03", hour, min, sec)
	elseif min > 0 then
		return __("LOGIN_HANGUP_TEXT07", min, sec)
	else
		return __("LOGIN_HANGUP_TEXT08", sec)
	end
end

function LoginHangUpWindow:willOpen()
	LoginHangUpWindow.super.willOpen(self)
end

function LoginHangUpWindow:didClose()
	LoginHangUpWindow.super.didClose(self)
	xyd.models.map:getHangItem(1)
	xyd.models.map:getHangItem(2)

	xyd.MainController.get().openPopWindowNum = xyd.MainController.get().openPopWindowNum - 1
end

function LoginHangUpWindow:playAction()
	local uiAction = self:getSequence()

	self.bgImg:X(-160)

	self.bgImg.alpha = 0.5

	uiAction:Append(self.bgImg.transform:DOLocalMoveX(-60, 0.2)):Join(xyd.getTweenAlpha(self.bgImg, 1, 0.2)):Append(self.bgImg.transform:DOLocalMoveX(-80, 0.3)):AppendCallback(function ()
		self.textBg:SetActive(true)

		self.textBg.alpha = 0.01

		self.textBg:SetLocalScale(0.5, 0.5, 1)
	end):Append(self.textBg.transform:DOScale(Vector3(1.1, 0.95, 1), 0.16)):Join(xyd.getTweenAlpha(self.textBg, 1, 0.16)):Append(self.textBg.transform:DOScale(Vector3(0.95, 1.1, 1), 0.16)):Append(self.textBg.transform:DOScale(Vector3(1, 1, 1), 0.24)):AppendCallback(function ()
		self.ui_action_flag_ = true
	end)

	local textAction = self:getSequence()

	textAction:AppendInterval(0.82):AppendCallback(function ()
		self.welcomeLabel:SetActive(true)
		self.welcomeLabel:SetLocalScale(0.01, 0.01, 1)
	end):Append(self.welcomeLabel.transform:DOScale(Vector3(1, 1, 1), 0.3)):AppendCallback(function ()
		self.text_action_flag_ = true
	end)

	local banner_action = self:getSequence()
	local standard_x = self.bannerGroup:X()

	self.bannerGroup:SetActive(true)

	local bannerWidget = self.bannerGroup:GetComponent(typeof(UIWidget))
	bannerWidget.alpha = 0.5

	self.bannerGroup:X(standard_x - 80)
	banner_action:AppendInterval(0.1):Append(self.bannerGroup.transform:DOLocalMoveX(standard_x + 20, 0.2)):Join(xyd.getTweenAlpha(bannerWidget, 1, 0.2)):Append(self.bannerGroup.transform:DOLocalMoveX(standard_x, 0.2)):AppendCallback(function ()
		self.banner_action_flag_ = true
	end)

	local pos = {
		264,
		180,
		142,
		84
	}

	for i = 1, 4 do
		local item = self["actionGroup" .. tostring(i)]

		item:Y(pos[i] - 50)

		local itemW = item:GetComponent(typeof(UIWidget))
		local t = 0.3 + 0.06 * (i - 1)
		local content_action = self:getSequence()

		content_action:AppendInterval(t):AppendCallback(function ()
			itemW.alpha = 0.5

			item:SetActive(true)
		end):Append(item.transform:DOLocalMoveY(pos[i], 0.3)):Join(xyd.getTweenAlpha(itemW, 1, 0.3))

		if i == 4 then
			content_action:AppendCallback(function ()
				self.content_action_flag_ = true
			end)
		end
	end

	self:waitForTime(0.42, function ()
		local items = self.wrapContent_:getItems()

		for i = 1, #items do
			local delay = (i - 1) * 0.06

			items[i]:playAction(delay)
		end
	end)

	if not self.dropItems_ or #self.dropItems_ == 0 then
		local none_action = self:getSequence()
		local groupNoneW = self.groupNone:GetComponent(typeof(UIWidget))

		none_action:AppendInterval(0.42):AppendCallback(function ()
			self.groupNone:SetActive(true)

			groupNoneW.alpha = 0.01

			self.groupNone:SetLocalScale(1.2, 1.2, 1)
		end):Append(self.groupNone.transform:DOScale(Vector3(0.9, 0.9, 1), 0.2)):Join(xyd.getTweenAlpha(groupNoneW, 1, 0.2)):Append(self.groupNone.transform:DOScale(Vector3(1, 1, 1), 0.3)):AppendCallback(function ()
			self.item_action_flag_ = true
		end)

		self.labelNoneTips.text = __("LOGIN_HANGUP_TEXT06")
	else
		self.groupNone:SetActive(false)
	end

	local tips_action = self:getSequence()

	tips_action:AppendInterval(0.42):AppendCallback(function ()
		self.tipsLabel:SetActive(true)

		self.tipsLabel.alpha = 0.5
	end):Append(xyd.getTweenAlpha(self.tipsLabel, 1, 0.3)):AppendCallback(function ()
		self.tips_action_flag_ = true
	end)
end

function LoginHangUpWindow:checkCanTouch()
	return self.ui_action_flag_ and self.banner_action_flag_ and self.content_action_flag_ and self.item_action_flag_ and self.tips_action_flag_ and self.text_action_flag_
end

function AwardItems:initUI()
	AwardItems.super.initUI(self)
end

function AwardItems:updateInfo()
	AwardItems.super.updateInfo(self)

	if self.itemId == self.data.item_id and self.itemNum == self.data.item_num then
		return
	end

	NGUITools.DestroyChildren(self.go.transform)

	self.itemId = self.data.item_id
	self.itemNum = self.data.item_num
	local itemIcon = xyd.getItemIcon({
		scale = 0.8333333333333334,
		noClick = true,
		itemID = self.itemId,
		num = self.itemNum,
		uiRoot = self.go,
		dragScrollView = self.parent.scrollView,
		activityTag = self.data.activityTag,
		wndType = xyd.ItemTipsWndType.CAMPAIGN_HANG
	})

	if not self.isAction_ then
		itemIcon:SetActive(false)
	end

	self.itemIcon_ = itemIcon
end

function AwardItems:playAction(delay)
	self.isAction_ = true

	if not self.itemIcon_ then
		return
	end

	local action = self:getSequence()
	local standard_scale = 0.8333333333333334
	local w = self.itemIcon_:getGameObject():GetComponent(typeof(UIWidget))

	action:AppendInterval(delay):AppendCallback(function ()
		self.itemIcon_:SetActive(true)

		w.alpha = 0.01

		self.itemIcon_:SetLocalScale(standard_scale * 1.2, standard_scale * 1.2, 1)
	end):Append(w.transform:DOScale(Vector3(standard_scale * 0.9, standard_scale * 0.9, 1), 0.2)):Join(xyd.getTweenAlpha(w, 1, 0.2)):Append(w.transform:DOScale(Vector3(standard_scale, standard_scale, 1), 0.3))
end

return LoginHangUpWindow
