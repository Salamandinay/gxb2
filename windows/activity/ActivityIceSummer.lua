local ActivityContent = import(".ActivityContent")
local ActivityIceSummer = class("ActivityIceSummer", ActivityContent)
local CountDown = import("app.components.CountDown")
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local IceSummerItem = class("IceSummerItem", import("app.common.ui.FixedMultiWrapContentItem"))
local ActivityIceSummerStoryTable = xyd.tables.activityIceSummerStoryTable

function ActivityIceSummer:ctor(parentGO, params)
	ActivityIceSummer.super.ctor(self, parentGO, params)

	self.itemType_ = xyd.split(xyd.tables.miscTable:getVal("activity_swimsuit_cost"), "#", true)[1]
	self.usedTimes = tonumber(self.activityData.detail.used_times)
	self.awardeds = self.activityData.detail.awardeds

	if self.awardeds[1] == 0 then
		xyd.WindowManager.get():openWindow("story_window", {
			is_back = true,
			story_type = xyd.StoryType.SWIMSUIT,
			story_id = tonumber(xyd.tables.activityIceSummerStoryTable:getPlot(1))
		})

		local msg = messages_pb.get_activity_award_req()
		msg.activity_id = xyd.ActivityID.ICE_SUMMER

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

		self.activityData.detail.awardeds[1] = 1
		self.awardeds[1] = 1
	end

	self.first = true
	self.unlocked = {}

	for i in ipairs(ActivityIceSummerStoryTable:getIDs()) do
		if (i == 1 or i > 1 and self.awardeds[i - 1] == 1) and ActivityIceSummerStoryTable:getCost(i) <= self.usedTimes then
			table.insert(self.unlocked, 1)
		else
			table.insert(self.unlocked, 0)
		end
	end

	self:getUIComponent()
	self:initUIComponet()
	self:RegisterEvent()
	self:euiComplete()
end

function ActivityIceSummer:getPrefabPath()
	return "Prefabs/Windows/activity/ice_summer"
end

function ActivityIceSummer:initUIComponet()
	self:layout()
	self:initUITexture()

	self.endLabel.text = __("END_TEXT")
	self.giftLabel.text = __("ACTIVITY_ICE_SUMMER_GIFTBAG")
	self.gachaLabel.text = __("ACTIVITY_ICE_SUMMER_DRINK")
end

function ActivityIceSummer:getUIComponent()
	local go = self.go
	self.mainGroup = go:NodeByName("mainGroup").gameObject
	self.bgImg = self.mainGroup:ComponentByName("bgImg", typeof(UISprite))
	self.textImg = self.mainGroup:ComponentByName("textImg", typeof(UITexture))
	self.charaImg = self.mainGroup:ComponentByName("charaImg", typeof(UITexture))
	self.giftBtn = self.mainGroup:NodeByName("giftBtn").gameObject
	self.giftLabel = self.giftBtn:ComponentByName("label", typeof(UILabel))
	self.helpBtn = self.mainGroup:NodeByName("helpBtn").gameObject
	self.awardBtn = self.mainGroup:NodeByName("awardBtn").gameObject
	self.timerGroup = self.mainGroup:NodeByName("timerGroup").gameObject
	self.timeLabel = self.timerGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timerGroup:ComponentByName("endLabel", typeof(UILabel))
	self.collectedGroup = self.mainGroup:NodeByName("collectedGroup").gameObject
	self.collectedIcon = self.collectedGroup:ComponentByName("icon", typeof(UISprite))
	self.textLabel = self.collectedGroup:ComponentByName("textLabel", typeof(UILabel))
	self.numLabel = self.collectedGroup:ComponentByName("numLabel", typeof(UILabel))
	self.gachaBtn = self.mainGroup:NodeByName("gachaBtn").gameObject
	self.gachaLabel = self.gachaBtn:ComponentByName("label", typeof(UILabel))
	self.itemGroup = self.mainGroup:NodeByName("itemGroup").gameObject
	self.itemIcon = self.itemGroup:ComponentByName("icon", typeof(UISprite))
	self.itemLabel = self.itemGroup:ComponentByName("label", typeof(UILabel))
	self.itemBtn = self.itemGroup:NodeByName("btn").gameObject
	self.scrollerGroup = go:NodeByName("scrollerGroup").gameObject
	self.scroll = self.scrollerGroup:NodeByName("scroller").gameObject
	self.scrollView = self.scrollerGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.scroller_uiPanel = self.scrollerGroup:ComponentByName("scroller", typeof(UIPanel))
	self.itemsGroup_ = self.scrollView:ComponentByName("itemGroup", typeof(UIWrapContent))
	local itemCell = self.scrollerGroup:NodeByName("itemCell").gameObject
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, self.itemsGroup_, itemCell, IceSummerItem, self)
end

function ActivityIceSummer:initUITexture()
	local langImgPath = "Textures/activity_text_web/"

	xyd.setUITextureAsync(self.textImg, langImgPath .. "activity_ice_summer_text_" .. xyd.Global.lang, nil, )
end

function ActivityIceSummer:layout()
	if xyd:getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	self.eventProxyInner_:addEventListener(xyd.event.RECHARGE, function (evt)
		self.onRecharge(evt)
	end)

	self.itemLabel.text = tostring(xyd.models.backpack:getItemNumByID(self.itemType_))
	self.numLabel.text = tostring(self.usedTimes)
	self.awardeds = self.activityData.detail.awardeds
	self.textLabel.text = __("ACTIVITY_ICE_SUMMER_COLLECT")
	local infos = {}

	for i = 1, #ActivityIceSummerStoryTable:getIDs() do
		table.insert(infos, {
			index = i,
			usedTimes = self.usedTimes,
			awardeds = self.awardeds
		})
	end

	if self.first then
		self.wrapContent:setInfos(infos, {})

		self.first = false
	else
		self.wrapContent:setInfos(infos, {
			keepPosition = true
		})
	end
end

function ActivityIceSummer:onRecharge()
end

function ActivityIceSummer:euiComplete()
	self.itemNum_ = xyd.models.backpack:getItemNumByID(self.itemType_)

	self:layout()
end

function ActivityIceSummer:RegisterEvent()
	UIEventListener.Get(self.giftBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("ice_summer_gift_window", {
			nowRound = self.nowRound
		})
	end)
	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		local params = {
			key = "ACTIVITY_ICE_SUMMER_HELP"
		}

		xyd.WindowManager.get():openWindow("help_window", params)
	end)
	UIEventListener.Get(self.awardBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("ice_summer_award_window", {
			nowRound = self.nowRound
		})
	end)
	UIEventListener.Get(self.gachaBtn).onClick = handler(self, function ()
		if xyd.models.backpack:getItemNumByID(self.itemType_) > 0 then
			xyd.WindowManager.get():openWindow("ice_summer_gacha_window", {
				nowRound = self.nowRound,
				num = xyd.models.backpack:getItemNumByID(self.itemType_)
			})
		else
			xyd.alert(xyd.AlertType.TIPS, __("FANPAI_TICKETS_NOT_ENOUGH"))
		end
	end)
	UIEventListener.Get(self.itemBtn).onClick = handler(self, function ()
		local params = {
			showGetWays = true,
			itemID = self.itemType_,
			itemNum = self.itemNum_,
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			ways_val = {
				-1,
				self.activityData.detail.missions[1].complete_times * 3,
				self.activityData.detail.missions[2].complete_times
			}
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end)

	self:registerEvent(xyd.event.SWIMSUIT_COST, handler(self, self.gachaResult))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.storyRead))
end

function ActivityIceSummer:storyRead(event)
end

function ActivityIceSummer:gachaResult(event)
	local myItems = {}

	for i = 1, #event.data.items do
		table.insert(myItems, {
			item_id = event.data.items[i].item_id,
			item_num = event.data.items[i].item_num
		})
	end

	self:itemFloat(myItems)

	self.usedTimes = event.data.used_times
	self.activityData.detail.used_times = event.data.used_times

	self:layout()
end

function IceSummerItem:ctor(go, parent)
	IceSummerItem.super.ctor(self, go, parent)
end

function IceSummerItem:initUI()
	local go = self.go
	self.labelFortName = go:ComponentByName("labelFortName", typeof(UILabel))
	self.fortImg = go:ComponentByName("fGroup/fortImg", typeof(UISprite))
	self.labelFortDes = go:ComponentByName("fGroup/labelFortDes", typeof(UILabel))
	self.maskGroup = go:NodeByName("maskGroup").gameObject
	self.touchMask = self.maskGroup:NodeByName("touchMask").gameObject:GetComponent(typeof(UnityEngine.BoxCollider))
	self.BoxCollider = go:GetComponent(typeof(UnityEngine.BoxCollider))
	self.groupItem = go:NodeByName("groupItem").gameObject
	self.layout = self.groupItem:GetComponent(typeof(UILayout))
	self.collectedGroup = go:NodeByName("collectedGroup").gameObject
	self.collectedLabel = go:ComponentByName("collectedGroup/label", typeof(UILabel))
	self.unlockEffetGroup = go:NodeByName("souxEffect").gameObject

	xyd.setDragScrollView(self.touchMask, self.parent.scrollView)
	xyd.setDragScrollView(self.BoxCollider, self.parent.scrollView)
	self.maskGroup:SetActive(true)
end

function IceSummerItem:updateInfo()
	self.index = self.data.index
	self.collected = self.data.usedTimes
	self.awardeds = self.data.awardeds

	self:initItem()
	self:checkLock()
end

function IceSummerItem:initItem()
	self.labelFortName.text = __("CHAPTER_COUNT", self.index)
	self.collectedLabel.text = "X" .. ActivityIceSummerStoryTable:getCost(self.index) .. __("UNLOCK_TEXT")
	self.labelFortDes.text = xyd.tables.activitySwimsuitStoryTextTable:getChapter(self.index)

	xyd.setUISpriteAsync(self.fortImg, nil, "bg_storyOnTheBeach_" .. tostring(self.index - 1))
	NGUITools.DestroyChildren(self.groupItem.transform)
	self:createItem()
end

function IceSummerItem:createItem()
	local rewards = ActivityIceSummerStoryTable:getAward(self.index)

	for i = 1, #rewards do
		local params = {
			hideText = true,
			itemID = rewards[i][1],
			num = rewards[i][2],
			uiRoot = self.groupItem,
			scale = Vector3(0.65, 0.65, 1)
		}
		local icon = xyd.getItemIcon(params)

		icon:setItemIconDepth(40)

		if self.awardeds[self.data.index] == 1 then
			icon:setMask(true)

			local go = NGUITools.AddChild(icon.go)
			local sp = go:AddComponent(typeof(UISprite))

			xyd.setUISpriteAsync(sp, nil, "select")

			sp.depth = 50
			sp.width = 80
			sp.height = 59
		end
	end

	self.layout:Reposition()
end

function IceSummerItem:checkLock()
	if ActivityIceSummerStoryTable:getCost(self.index) <= tonumber(self.collected) then
		if self.awardeds[self.data.index - 1] == 0 then
			self:lock()
			self.collectedGroup:SetActive(false)
		elseif self.parent.unlocked[self.index] == 0 then
			self.maskGroup:ComponentByName("imgLock", typeof(UISprite)).gameObject:SetActive(false)
			self:addUnlockEffect(true)

			self.parent.unlocked[self.index] = 1
		else
			self:unlock()
		end
	else
		self:lock()
	end
end

function IceSummerItem:unlock()
	self.isLocked = false

	self.maskGroup:SetActive(false)
	self.collectedGroup:SetActive(false)
end

function IceSummerItem:lock()
	self.isLocked = true

	self.maskGroup:SetActive(true)
	self.collectedGroup:SetActive(true)
end

function IceSummerItem:addUnlockEffect(ifAll)
	if not ifAll then
		self:unlock()
	end

	if not self.suoxEffect then
		self.suoxEffect = xyd.Spine.new(self.unlockEffetGroup)
	end

	self.suoxEffect:setInfo("suox", function ()
		self.suoxEffect:SetLocalPosition(0, 0, 0)
		self.suoxEffect:SetLocalScale(1, 1, 1)
		self.suoxEffect:play("texiao1", 1, 1, handler(self, function ()
			if ifAll then
				self:playUnlockAnimation()
			end
		end))
	end)
end

function IceSummerItem:playUnlockAnimation()
	local sequence1 = DG.Tweening.DOTween.Sequence()
	local w = self.maskGroup:GetComponent(typeof(UIWidget))

	sequence1:Append(xyd.getTweenAlpha(w, 0.01, 0.2))
	sequence1:AppendCallback(function ()
		self.maskGroup:SetActive(false)

		w.alpha = 1

		sequence1:Kill(false)

		sequence1 = nil
	end)
end

function IceSummerItem:registerEvent()
	UIEventListener.Get(self:getGameObject()).onClick = handler(self, self.onTouch)
	UIEventListener.Get(self.touchMask.gameObject).onClick = handler(self, self.showTip)
end

function IceSummerItem:onTouch()
	xyd.WindowManager.get():openWindow("story_window", {
		is_back = true,
		story_type = xyd.StoryType.SWIMSUIT,
		story_id = tonumber(xyd.tables.activityIceSummerStoryTable:getPlot(self.data.index)),
		callback = function ()
			if self.index ~= #ActivityIceSummerStoryTable:getIDs() then
				self.parent:layout()
			end
		end
	})

	local msg = messages_pb.get_activity_award_req()
	local rewards = ActivityIceSummerStoryTable:getAward(self.index)
	local params = {}

	if self.index ~= 1 then
		params = {
			award_id = rewards[1][1],
			num = rewards[1][2]
		}
	end

	local cjson = require("cjson")
	local data = cjson.encode(params)
	msg.activity_id = xyd.ActivityID.ICE_SUMMER
	msg.params = data

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

	self.parent.awardeds[self.index] = 1
	self.awardeds[self.index] = 1
end

function IceSummerItem:showTip()
	if ActivityIceSummerStoryTable:getCost(self.index) <= tonumber(self.collected) then
		xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_ICE_SUMMER_STORYTIPS1"))
	else
		xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_ICE_SUMMER_STORYTIPS2"))
	end
end

return ActivityIceSummer
