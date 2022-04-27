local ActivityContent = import(".ActivityContent")
local ActivityWorldBoss = class("ActivityWorldBoss", ActivityContent)
local CountDown = import("app.components.CountDown")
local ActivityWorldBossItem = class("ActivityWorldBossItem", import("app.components.CopyComponent"))

function ActivityWorldBoss:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.cost_type = 28
	self.itemList = {}
	self.posList = {
		-96,
		-333,
		-573
	}
	self.skinName = "ActivityWorldBossSkin"
	self.currentState = xyd.Global.lang

	self:getUIComponent()
	self:euiComplete()
end

function ActivityWorldBoss:getPrefabPath()
	return "Prefabs/Windows/activity/activity_word_boss"
end

function ActivityWorldBoss:getUIComponent()
	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UITexture))

	xyd.setUITextureAsync(self.imgBg, "Textures/scenes_web/activity_world_boss_bg")

	local allGroup = go:NodeByName("allGroup").gameObject
	self.upBgImg = allGroup:ComponentByName("upBgImg", typeof(UITexture))

	xyd.setUITextureAsync(self.upBgImg, "Textures/activity_web/activity_world_boss/activity_world_status_bg")

	local leftUpCon = allGroup:NodeByName("leftUpCon").gameObject
	self.costIcon = leftUpCon:ComponentByName("costIcon", typeof(UITexture))

	xyd.setUITextureAsync(self.costIcon, "Textures/activity_web/activity_world_boss/activity_world_boss_cost_icon")

	self.numberLabel = leftUpCon:ComponentByName("numberLabel", typeof(UILabel))
	self.addBtn = leftUpCon:NodeByName("addBtn").gameObject
	local btnGroup = allGroup:NodeByName("btnGroup").gameObject
	self.awardBtn = btnGroup:NodeByName("awardBtn").gameObject
	self.rankBtn = btnGroup:NodeByName("rankBtn").gameObject
	self.helpBtn = btnGroup:NodeByName("helpBtn").gameObject

	self.rankBtn:SetActive(false)
	self.awardBtn:SetActive(false)

	self.timeLabel = allGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = allGroup:ComponentByName("endLabel", typeof(UILabel))
	self.itemGroup = allGroup:NodeByName("itemGroup").gameObject
	self.activity_boss_item = allGroup:NodeByName("activity_boss_item").gameObject
end

function ActivityWorldBoss:euiComplete()
	if self.activityData:getUpdateTime() < xyd.getServerTime() then
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	else
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	end

	self.endLabel.text = __("END_TEXT")

	self:initItem()
	self:initAddGroup()
	self:initHelp()
	self:registerEvent()
end

function ActivityWorldBoss:registerEvent()
	self.eventProxyInner_:addEventListener(xyd.event.BOSS_BUY, function (evt)
		self.activityData.detail.buy_times = evt.data.buy_times

		self:updateItemNumber()
	end)
	self.eventProxyInner_:addEventListener(xyd.event.BOSS_FIGHT, handler(self, self.updateItemNumber))
	self.eventProxyInner_:addEventListener(xyd.event.BOSS_SWEEP, handler(self, self.updateItemNumber))
	self.eventProxyInner_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.updateItemNumber))
end

function ActivityWorldBoss:initItem()
	for i = 1, 3 do
		local params = {
			id = i,
			titleImgSource = "activity_world_boss_text0" .. tostring(i) .. "_" .. tostring(xyd.Global.lang),
			bgImgSource = "activity_world_boss_bg0" .. tostring(i),
			baseInfo = self.activityData.detail.boss_infos[i]
		}
		local tmp = NGUITools.AddChild(self.itemGroup.gameObject, self.activity_boss_item.gameObject)

		table.insert(self.itemList, tmp)
		tmp.transform:SetLocalPosition(0, self.posList[i], 0)

		local item = ActivityWorldBossItem.new(tmp, params)
	end
end

function ActivityWorldBoss:initAddGroup()
	self:updateItemNumber()
	self.eventProxyInner_:addEventListener(xyd.event.ITEM_EXCHANGE, self.updateItemNumber, self)

	UIEventListener.Get(self.addBtn.gameObject).onClick = handler(self, function ()
		if self:getBuyTime() <= 0 then
			xyd.showToast(__("ACTIVITY_WORLD_BOSS_LIMIT"))

			return
		end

		local data = xyd.tables.miscTable:split2Cost("activity_boss_buy_cost", "value", "#")

		xyd.WindowManager.get():openWindow("limit_purchase_item_window", {
			limitKey = "ACTIVITY_WORLD_BOSS_LIMIT",
			notEnoughKey = "PERSON_NO_CRYSTAL",
			needTips = true,
			buyNum = 1,
			buyType = 28,
			titleKey = "WORLD_BOSS_BUY_TITLE",
			costType = data[1],
			costNum = data[2],
			purchaseCallback = function (evt, num)
				local msg = messages_pb:boss_buy_req()
				msg.activity_id = self.id
				msg.num = num

				xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)
			end,
			limitNum = self:getBuyTime(),
			eventType = xyd.event.BOSS_BUY,
			showWindowCallback = function ()
				xyd.WindowManager.get():openWindow("vip_window")
			end
		})
	end)
end

function ActivityWorldBoss:updateItemNumber()
	self.numberLabel.text = tostring(xyd.models.backpack:getItemNumByID(self.cost_type))
	local win = xyd.WindowManager.get():getWindow("activity_world_boss_window")

	if win then
		win:updateNumber()
	end
end

function ActivityWorldBoss:initRank()
	UIEventListener.Get(self.rankBtn.gameObject).onClick = handler(self, self.onTouchRank)
end

function ActivityWorldBoss:onTouchRank()
	xyd.WindowManager.get():openWindow("world_boss_rank_window")
end

function ActivityWorldBoss:initAward()
	self.awardBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, self.onTouchAward, self)
end

function ActivityWorldBoss:onTouchAward(evt)
	xyd.WindowManager:get():openWindow("activity_world_award_window")
end

function ActivityWorldBoss:initHelp()
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		local params = {
			key = "ACTIVITY_WORLD_BOSS_HELP",
			title = __("ACTIVITY_WORLD_BOSS_HELP_TITLE")
		}

		xyd.WindowManager.get():openWindow("help_window", params)
	end)
end

function ActivityWorldBoss:getBuyTime()
	return tonumber(xyd.tables.miscTable:getVal("activity_boss_buy_limit")) - self.activityData.detail.buy_times
end

function ActivityWorldBossItem:ctor(goItem, params)
	ActivityWorldBossItem.super.ctor(self, goItem)

	self.goItem_ = goItem
	local transGo = goItem.transform
	self.skinName = "ActivityWorldBossItemSkin"
	self.id = params.id
	self.titleImgSource = params.titleImgSource
	self.bgImgSource = params.bgImgSource
	self.baseInfo = params.baseInfo
	self.currentState = xyd.Global.lang
	self.bgImg = transGo:ComponentByName("bgImg", typeof(UISprite))

	xyd.setUISpriteAsync(self.bgImg, nil, self.bgImgSource, nil, , true)

	self.bgImg_uiWidget = self.bgImg:GetComponent(typeof(UIWidget))

	if self.id == 3 then
		self.bgImg_uiWidget.height = 240
	end

	self.titleImg = transGo:ComponentByName("titleImg", typeof(UISprite))

	xyd.setUISpriteAsync(self.titleImg, nil, self.titleImgSource, nil, , true)

	self.fightBtn = transGo:ComponentByName("e:Group/fightBtn", typeof(UISprite))
	self.fightBtn_button_label = transGo:ComponentByName("e:Group/fightBtn/button_label", typeof(UILabel))

	self:createChildren()
end

function ActivityWorldBossItem:createChildren()
	self:initText()
	self:registerEvent()
	self:addParentDepth()
end

function ActivityWorldBossItem:initText()
	self.fightBtn_button_label.text = __("WORLD_BOSS_FIGHT")
end

function ActivityWorldBossItem:registerEvent()
	UIEventListener.Get(self.fightBtn.gameObject).onClick = handler(self, self.onTouchFight)
end

function ActivityWorldBossItem:onTouchFight(event)
	if not self.baseInfo or not self.baseInfo.boss_id or self.baseInfo.boss_id <= 0 then
		xyd.showToast(__("ACTIVITY_WORLD_BOSS_COMPLETE"))

		return
	end

	xyd.WindowManager.get():openWindow("activity_world_boss_window", {
		activity_id = xyd.ActivityID.ACTIVITY_WORLD_BOSS,
		boss_type = self.id,
		base_info = self.baseInfo
	})
end

function ActivityWorldBossItem:solveDif()
	if self.id == 1 then
		self.titleImg.y = 419
	else
		self.titleImg.y = 400
	end
end

local BaseWindow = import("app.windows.BaseWindow")
local ActivityWorldBossAwardWindow = class("ActivityWorldBossAwardWindow", BaseWindow)

function ActivityWorldBossAwardWindow:ctor(name, params)
	if params == nil then
		params = nil
	end

	BaseWindow.ctor(self, name, params)

	self.skinName = "ActivityWorldBossAwardWindowSkin"
end

function ActivityWorldBossAwardWindow:initWindow()
	BaseWindow.initWindow(self)
end

function ActivityWorldBossAwardWindow:playOpenAnimations(preWinName, callback)
	BaseWindow.playOpenAnimations(self, preWinName, function ()
		self:layout()
	end)
end

function ActivityWorldBossAwardWindow:layout()
	self.titleLabel.text = __(_G, "ACTIVITY_WORLD_BOSS_AWARD_TITLE")
	self.descLabel.text = __(_G, "ACTIVITY_WORLD_BOSS_AWARD_DESC")
	local ids = ActivityBossAwardTable:get():getIDs()
	local i = 0

	while i < ids.length do
		local id = ids[i]

		self.itemGroup:addChild(ActivityWorldBossAwardWindowItem.new({
			id = id
		}))

		i = i + 1
	end
end

function ActivityWorldBossAwardWindow:willClose(params, skipAnimation, force)
	BaseWindow.willClose(self, params, skipAnimation, force)
	self.itemGroup:removeChildren()
end

local ActivityWorldBossAwardWindowItem = class("ActivityWorldBossAwardWindowItem", import("app.components.CopyComponent"))

function ActivityWorldBossAwardWindowItem:ctor(params)
	ActivityWorldBossAwardWindowItem.____super.ctor(self)

	self.skinName = "ActivityWorldBossAwardWindowItemSkin"
	self.id = params.id
end

function ActivityWorldBossAwardWindowItem:createChildren()
	ActivityWorldBossAwardWindowItem.____super.createChildren(self)
	self:update()
end

function ActivityWorldBossAwardWindowItem:update()
	local rank = ActivityBossAwardTable:get():getRank(self.id)
	local lastRank = ActivityBossAwardTable:get():getRank(self.id - 1)
	local awards = ActivityBossAwardTable:get():getAwards(self.id)

	if rank <= 3 then
		self.imgRankIcon.source = "rank_icon0" .. tostring(rank) .. "_png"
		self.imgRankIcon.visible = true
		self.labelRank.visible = false
	else
		self.imgRankIcon.visible = false

		if lastRank + 1 == rank then
			self.labelRank.text = String(_G, rank)
		elseif rank >= 1000 then
			self.labelRank.text = tostring(lastRank + 1) .. "~\n" .. tostring(rank)
		else
			self.labelRank.text = tostring(lastRank + 1) .. "~" .. tostring(rank)
		end

		self.labelRank.visible = true
	end

	self.groupIcons_:removeChildren()

	local i = 0

	while i < awards.length do
		local award = awards[i]
		local item = xyd:getItemIcon({
			show_has_num = true,
			itemID = award[0],
			num = award[1],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
		item.scaleX = 60 / item.width
		item.scaleY = 60 / item.width
		item.labelNumScale = 1.3

		self.groupIcons_:addChild(item)

		i = i + 1
	end
end

return ActivityWorldBoss
