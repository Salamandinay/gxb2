local ShrineHurdleEntranceWindow = class("ShrineHurdleEntranceWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local CountDown = import("app.components.CountDown")

function ShrineHurdleEntranceWindow:ctor(name, params)
	ShrineHurdleEntranceWindow.super.ctor(self, name, params)
	xyd.models.shrineHurdleModel:checkReqPartnerInfos()
end

function ShrineHurdleEntranceWindow:initWindow()
	self:getUIComponent()
	self:initTop()
	self:layout()
	self:updateChallengeTime()
	self:checkGuide()
	self:register()
end

function ShrineHurdleEntranceWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.bgImg_ = winTrans:ComponentByName("bgImg", typeof(UITexture))
	self.topGroup = self.window_:NodeByName("top_group").gameObject
	self.helpBtn_ = winTrans:NodeByName("helpBtn").gameObject
	self.storyReviewBtn_ = winTrans:NodeByName("story_review_btn").gameObject
	self.enterGroup_ = winTrans:NodeByName("enter_group").gameObject
	self.ddlGroup_ = self.enterGroup_:NodeByName("ddl_group").gameObject
	self.ddlLabel_ = self.ddlGroup_:ComponentByName("label_ddl", typeof(UILabel))
	self.midGroup_ = self.enterGroup_:NodeByName("mid_group").gameObject
	self.midTime_ = self.midGroup_:ComponentByName("img_bg_1/label_time", typeof(UILabel))
	self.enterBtn_ = self.enterGroup_:ComponentByName("enter_btn", typeof(UISprite))
	self.enterBtnLabel_ = self.enterBtn_.transform:ComponentByName("btn_label", typeof(UILabel))
	self.enterBtnRed_ = self.enterBtn_.transform:NodeByName("red_point").gameObject
	self.enterBox_ = self.enterGroup_:NodeByName("clickBox").gameObject
	self.enterEffectRoot_ = self.enterGroup_:NodeByName("effectRoot").gameObject
	self.treeGroup_ = winTrans:NodeByName("tree_group").gameObject
	self.treeBtn_ = self.treeGroup_:ComponentByName("tree_btn", typeof(UISprite))
	self.treeBtnLabel_ = self.treeBtn_.transform:ComponentByName("btn_label", typeof(UILabel))
	self.treeBtnRed_ = self.treeBtn_.transform:NodeByName("red_point").gameObject
	self.treeClickBox_ = self.treeGroup_:NodeByName("clickBox").gameObject
	self.treeEffectRoot_ = self.treeGroup_:NodeByName("effectRoot").gameObject
	self.broadcastGroup_ = winTrans:NodeByName("broadcast_group").gameObject
	self.broadcastBtn_ = self.broadcastGroup_:ComponentByName("broadcast_btn", typeof(UISprite))
	self.broadcastBtnLabel_ = self.broadcastBtn_.transform:ComponentByName("btn_label", typeof(UILabel))
	self.broadcastBtnRed_ = self.broadcastBtn_.transform:NodeByName("red_point").gameObject
	self.broadcastClickBox_ = self.broadcastGroup_:NodeByName("clickBox").gameObject
	self.broadcastEffectRoot_ = self.broadcastGroup_:NodeByName("effectRoot").gameObject
	self.wishGroup_ = winTrans:NodeByName("wish_group").gameObject
	self.wishBtn_ = self.wishGroup_:ComponentByName("wish_btn", typeof(UISprite))
	self.wishBtnLabel_ = self.wishBtn_.transform:ComponentByName("btn_label", typeof(UILabel))
	self.wishBtnRed_ = self.wishBtn_.transform:NodeByName("red_point").gameObject
	self.wishClickBox_ = self.wishGroup_:NodeByName("clickBox").gameObject
	self.wishEffectRoot_ = self.wishGroup_:NodeByName("effectRoot").gameObject
end

function ShrineHurdleEntranceWindow:initTop()
	self.windowTop = WindowTop.new(self.topGroup, self.name_, 1, true)
	local items = {
		{
			id = xyd.ItemID.SHRINE_TICKET
		}
	}

	self.windowTop:setItem(items)
end

function ShrineHurdleEntranceWindow:layout()
	self.enterBtnLabel_.text = __("SHRINE_HURDLE")
	self.treeBtnLabel_.text = __("SHRINE_TREE")
	self.broadcastBtnLabel_.text = __("SHRINE_NOTICE")
	self.wishBtnLabel_.text = __("SHRINE_POOL")

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "de_de" then
		xyd.setUISpriteAsync(self.broadcastBtn_, nil, "broadcast_bg_en", nil, , true)
	elseif xyd.Global.lang == "fr_fr" then
		xyd.setUISpriteAsync(self.broadcastBtn_, nil, "broadcast_fr", nil, , true)
	else
		xyd.setUISpriteAsync(self.broadcastBtn_, nil, "broadcast_bg", nil, , true)
	end

	self.treeEffect_ = xyd.Spine.new(self.treeEffectRoot_)

	self.treeEffect_:setInfo("hehua_sakura", function ()
		self.treeEffect_:play("texiao01", 0, 1)
		self.treeEffect_:SetLocalPosition(-130, -20)
	end)

	self.broadEffect_ = xyd.Spine.new(self.broadcastEffectRoot_)

	self.broadEffect_:setInfo("hehua_firefly", function ()
		self.broadEffect_:play("texiao01", 0, 1)
		self.broadEffect_:SetLocalScale(1.5, 1.5, 1)
		self.broadEffect_:SetLocalPosition(260, 335)
	end)

	self.wishEffect_ = xyd.Spine.new(self.wishEffectRoot_)

	self.wishEffect_:setInfo("hehua_water", function ()
		self.wishEffect_:play("texiao01", 0, 1)
		self.wishEffect_:SetLocalScale(1.5, 1.5, 1)
		self.wishEffect_:SetLocalPosition(-125, 335)
	end)

	if xyd.models.shrineHurdleModel:checkInBattleTime() then
		xyd.setUITextureByNameAsync(self.bgImg_, "shrine_main_bg2")

		self.enterEffect_ = xyd.Spine.new(self.enterEffectRoot_)

		self.enterEffect_:setInfo("hehua_light", function ()
			self.enterEffect_:play("texiao01", 0, 1)
			self.enterEffect_:SetLocalScale(1.5, 1.5, 1)
			self.enterEffect_:SetLocalPosition(195, -255)
		end)
	else
		xyd.setUITextureByNameAsync(self.bgImg_, "shrine_main_bg")
	end

	xyd.models.redMark:setMarkImg(xyd.RedMarkType.SHRINE_CHIME, self.treeBtnRed_)
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.SHRINE_NOTICE, self.broadcastBtnRed_)
end

function ShrineHurdleEntranceWindow:updateChallengeTime()
	local startTime = xyd.models.shrineHurdleModel:getStartTime()
	local timeSet = xyd.tables.miscTable:split2num("shrine_time_interval", "value", "|")
	local timePass = math.fmod(xyd.getServerTime() - startTime, (timeSet[1] + timeSet[2]) * xyd.DAY_TIME)
	self.timeCount = import("app.components.CountDown").new(self.ddlLabel_)
	self.midTime_.text = __("SHRINE_HOME_TEXT01")
	local route_id = xyd.models.shrineHurdleModel:getRouteID()

	if timePass <= timeSet[1] * xyd.DAY_TIME then
		self.timeCount:setInfo({
			key = "ACTIVITY_END_COUNT",
			duration = timeSet[1] * xyd.DAY_TIME - timePass
		})
	else
		self.timeCount:setInfo({
			key = "ACTIVITY_START_COUNT",
			duration = (timeSet[1] + timeSet[2]) * xyd.DAY_TIME - timePass
		})
	end

	if route_id and route_id > 0 and xyd.models.shrineHurdleModel:checkInBattleTime() then
		self.midGroup_:SetActive(true)
	else
		self.midGroup_:SetActive(false)
	end
end

function ShrineHurdleEntranceWindow:hideMid()
	self.midGroup_:SetActive(false)
end

function ShrineHurdleEntranceWindow:showMid()
	self.midGroup_:SetActive(true)
end

function ShrineHurdleEntranceWindow:register()
	ShrineHurdleEntranceWindow.super.register(self)

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SHRINE_HURDLE_HELP"
		})
	end

	UIEventListener.Get(self.enterBox_).onClick = handler(self, self.onClickFuntion1)

	self.eventProxy_:addEventListener(xyd.event.SHRINE_HURDLE_SELECT_RT, function ()
		xyd.WindowManager.get():closeWindow("shrine_hurdle_choose_way_window")
		xyd.WindowManager.get():closeWindow("shrine_hurdle_choose_level_window")
		xyd.WindowManager.get():openWindow("shrine_hurdle_window", {})
		self:showMid()
	end, self)
	self.eventProxy_:addEventListener(xyd.event.EXCHANGE_SHRINE_CARD, function ()
		xyd.showToast(__("PURCHASE_SUCCESS"))
	end, self)
	self.eventProxy_:addEventListener(xyd.event.SHRINE_HURDLE_END, function ()
		self:hideMid()
	end, self)

	UIEventListener.Get(self.storyReviewBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("shrine_story_review_window")
	end

	UIEventListener.Get(self.treeClickBox_).onClick = function ()
		xyd.WindowManager.get():openWindow("chime_main_window")
	end

	UIEventListener.Get(self.broadcastClickBox_).onClick = function ()
		xyd.WindowManager.get():openWindow("shrine_hurdle_notice_window")
	end

	UIEventListener.Get(self.wishClickBox_).onClick = function ()
		xyd.WindowManager.get():openWindow("shrine_hurdle_shop_window")
	end
end

function ShrineHurdleEntranceWindow:onClickFuntion1()
	local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()

	if xyd.models.shrineHurdleModel:checkInBattleTime() or guideIndex and guideIndex > 0 then
		if guideIndex and guideIndex > 1 then
			xyd.WindowManager.get():openWindow("shrine_hurdle_window", {})

			return
		elseif guideIndex == 1 then
			xyd.WindowManager.get():openWindow("shrine_hurdle_choose_way_window", {})

			return
		end

		local route_id = xyd.models.shrineHurdleModel:getRouteID()

		if route_id and route_id > 0 then
			xyd.WindowManager.get():openWindow("shrine_hurdle_window", {}, function ()
				xyd.WindowManager.get():openWindow("shrine_hurdle_info_window", {
					closeAll = true
				})
			end)
		else
			xyd.WindowManager.get():openWindow("shrine_hurdle_choose_way_window", {})
		end
	else
		local startTime = xyd.models.shrineHurdleModel:getStartTime()
		local timeSet = xyd.tables.miscTable:split2num("shrine_time_interval", "value", "|")
		local timePass = math.fmod(xyd.getServerTime() - startTime, (timeSet[1] + timeSet[2]) * xyd.DAY_TIME)

		xyd.alertTips(__("SHRINE_HURDLE_TEXT27", xyd.getRoughDisplayTime((timeSet[1] + timeSet[2]) * xyd.DAY_TIME - timePass)))
	end
end

function ShrineHurdleEntranceWindow:checkGuide()
	local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()

	if guideIndex and guideIndex == 1 then
		xyd.WindowManager:get():openWindow("common_trigger_guide_window", {
			guide_type = xyd.CommonTriggerGuideType.SHRINE_HURDLE_1
		})
	end

	if guideIndex and guideIndex == 10 then
		xyd.models.shrineHurdleModel:setFlag(nil, 10)
		self:hideMid()
	end
end

return ShrineHurdleEntranceWindow
