local BaseWindow = import(".BaseWindow")
local FairArenaExploreWindow = class("FairArenaExploreWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local WindowTop = import("app.components.WindowTop")
local GroupBuffIcon = import("app.components.GroupBuffIcon")
local Partner = import("app.models.Partner")
local HeroIcon = import("app.components.HeroIcon")
local PartnerBoxTable = xyd.tables.activityFairArenaBoxPartnerTable
local ArtifactBoxTable = xyd.tables.activityFairArenaBoxEquipTable
local FairArena = xyd.models.fairArena
local BuffTipsLev = {
	2,
	4,
	6,
	8
}

function FairArenaExploreWindow:ctor(name, params)
	FairArenaExploreWindow.super.ctor(self, name, params)

	self.needReqData = params.needReqData

	xyd.db.misc:setValue({
		value = 1,
		key = "fair_arena_first_challenge"
	})
end

function FairArenaExploreWindow:initWindow()
	FairArenaExploreWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:resizeToParent()
	self:register()

	self.show_partners = {}
	self.select_partners = {}
	self.isFirst_part = false
	self.isFirst_equi = false
	self.isFirst_buff = false
	self.isFirst_pre = false
	self.idFirst_res = false

	if self.needReqData then
		xyd.models.fairArena:reqArenaInfo()
	else
		self:update()
	end
end

function FairArenaExploreWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.Bg_ = winTrans:NodeByName("Bg_")
	self.textImg_ = winTrans:ComponentByName("textImg_", typeof(UISprite))
	self.topGroup = winTrans:NodeByName("topGroup").gameObject
	self.timeLayout = winTrans:ComponentByName("timeGroup", typeof(UILayout))
	self.endLabel_ = winTrans:ComponentByName("timeGroup/endLabel_", typeof(UILabel))
	self.timeLabel_ = winTrans:ComponentByName("timeGroup/timeLabel_", typeof(UILabel))
	self.awardIcon_ = winTrans:ComponentByName("awardIcon_", typeof(UISprite))
	self.awardIconLabel_ = winTrans:ComponentByName("awardIcon_/awardLabel_", typeof(UILabel))
	self.rankBtn_ = winTrans:NodeByName("rankBtn_").gameObject
	self.awardBtn_ = winTrans:NodeByName("awardBtn_").gameObject
	self.collectionBtn_ = winTrans:NodeByName("collectionBtn_").gameObject
	self.helpBtn_ = winTrans:NodeByName("helpBtn_").gameObject
	self.middleGroup = winTrans:NodeByName("middleGroup").gameObject
	self.middleBg_ = self.middleGroup:NodeByName("middleBg_").gameObject
	self.middleMask_ = self.middleGroup:NodeByName("middleMask_").gameObject
	self.cardGroup = self.middleGroup:NodeByName("cardGroup").gameObject
	self.cardWidget = self.cardGroup:GetComponent(typeof(UIWidget))
	self.tipsLabel1_ = self.cardGroup:ComponentByName("tipsLabel_", typeof(UILabel))

	for i = 1, 3 do
		self["card" .. i] = self.cardGroup:NodeByName("card" .. i).gameObject
		self["cardIconNode" .. i] = self["card" .. i]:NodeByName("iconNode").gameObject
		self["cardBtn_" .. i] = self["card" .. i]:NodeByName("selectBtn_").gameObject
	end

	self.swithBtn_ = self.cardGroup:NodeByName("swithBtn_").gameObject
	self.prepareGroup = self.middleGroup:NodeByName("prepareGroup").gameObject
	self.prepareWidget = self.prepareGroup:GetComponent(typeof(UIWidget))
	self.tipsLabel2_ = self.prepareGroup:ComponentByName("tipsLabel_", typeof(UILabel))
	self.winGroup = self.prepareGroup:NodeByName("winGroup").gameObject
	self.winLabel_ = self.winGroup:ComponentByName("winLabel_", typeof(UILabel))
	self.previewBtn_ = self.winGroup:NodeByName("previewBtn_").gameObject
	self.previewBtnSprite = self.previewBtn_:GetComponent(typeof(UISprite))
	self.previewBtnLabel1 = self.winGroup:ComponentByName("previewBtn_/awardLabel_", typeof(UILabel))
	self.previewEffect = self.previewBtn_:NodeByName("effect_").gameObject
	self.failGroup = self.prepareGroup:NodeByName("failGroup").gameObject
	self.failLabel_ = self.failGroup:ComponentByName("failLabel_", typeof(UILabel))
	self.shovelBtn1 = self.failGroup:NodeByName("shovelBtn1_").gameObject
	self.shovelIcon1 = self.shovelBtn1:GetComponent(typeof(UISprite))
	self.shovelLock1 = self.shovelBtn1:NodeByName("lock").gameObject
	self.shovelBtn2 = self.failGroup:NodeByName("shovelBtn2_").gameObject
	self.shovelIcon2 = self.shovelBtn2:GetComponent(typeof(UISprite))
	self.shovelLock2_ = self.shovelBtn2:NodeByName("lock").gameObject
	self.abandonBtn_ = self.failGroup:NodeByName("abandonBtn_").gameObject
	self.resultGroup = self.middleGroup:NodeByName("resultGroup").gameObject
	self.resultWidget = self.resultGroup:GetComponent(typeof(UIWidget))
	self.resultLabel_ = self.resultGroup:ComponentByName("resultLabel_", typeof(UILabel))
	self.previewBtn2_ = self.resultGroup:NodeByName("previewBtn2_").gameObject
	self.previewBtnSprite2 = self.previewBtn2_:GetComponent(typeof(UISprite))
	self.previewBtnLabel2 = self.resultGroup:ComponentByName("previewBtn2_/awardLabel_", typeof(UILabel))
	self.previewEffect2 = self.previewBtn2_:NodeByName("effect_").gameObject
	self.previewEffect3 = self.previewBtn2_:NodeByName("effect2_").gameObject
	self.shovelGroup = self.resultGroup:NodeByName("shovelGroup").gameObject
	self.res_shovelBtn1 = self.shovelGroup:NodeByName("shovelBtn1_").gameObject
	self.res_shovelIcon1 = self.res_shovelBtn1:GetComponent(typeof(UISprite))
	self.res_shovelLock1 = self.res_shovelBtn1:NodeByName("lock").gameObject
	self.res_shovelBtn2 = self.shovelGroup:NodeByName("shovelBtn2_").gameObject
	self.res_shovelIcon2 = self.res_shovelBtn2:GetComponent(typeof(UISprite))
	self.res_shovelLock2 = self.res_shovelBtn2:NodeByName("lock").gameObject
	self.res_shovelLabel_ = self.shovelGroup:ComponentByName("tipsLabel_", typeof(UILabel))
	self.bgGroup = winTrans:NodeByName("bgGroup")
	self.bottomGroup = winTrans:NodeByName("bottomGroup").gameObject
	self.forceLabel_ = self.bottomGroup:ComponentByName("forceLabel", typeof(UILabel))
	self.groupBuffLabel = self.bottomGroup:ComponentByName("groupBuffLabel", typeof(UILabel))
	self.groupBuffNode = self.bottomGroup:NodeByName("groupBuffNode").gameObject
	self.buffGroup = self.bottomGroup:NodeByName("buffGroup").gameObject
	self.buffNode1 = self.bottomGroup:NodeByName("buffGroup/buffNode1").gameObject
	self.buffNode2 = self.bottomGroup:NodeByName("buffGroup/buffNode2").gameObject
	self.buffNode3 = self.bottomGroup:NodeByName("buffGroup/buffNode3").gameObject
	self.buffNode4 = self.bottomGroup:NodeByName("buffGroup/buffNode4").gameObject
	self.frontGroup = self.bottomGroup:NodeByName("frontGroup").gameObject
	self.frontLabel_ = self.frontGroup:ComponentByName("front_label", typeof(UILabel))
	self.container1 = self.frontGroup:NodeByName("container_1").gameObject
	self.container2 = self.frontGroup:NodeByName("container_2").gameObject
	self.backGroup = self.bottomGroup:NodeByName("backGroup").gameObject
	self.backLabel_ = self.backGroup:ComponentByName("back_label", typeof(UILabel))
	self.container3 = self.backGroup:NodeByName("container_3").gameObject
	self.container4 = self.backGroup:NodeByName("container_4").gameObject
	self.container5 = self.backGroup:NodeByName("container_5").gameObject
	self.container6 = self.backGroup:NodeByName("container_6").gameObject
	self.battleBtn_ = self.bottomGroup:NodeByName("battleBtn_").gameObject
	self.battleBtnLabel_ = self.battleBtn_:ComponentByName("button_label", typeof(UILabel))
	self.recordBtn_ = self.bottomGroup:NodeByName("recordBtn_").gameObject
	self.backpackBtn_ = self.bottomGroup:NodeByName("backpackBtn_").gameObject
	self.backpackBtnRedPoint = self.backpackBtn_:NodeByName("redPoint").gameObject
	self.testGroup = self.bottomGroup:NodeByName("testGroup").gameObject
	self.testLabel_ = self.testGroup:ComponentByName("testLabel_", typeof(UILabel))
	self.mask_ = winTrans:NodeByName("mask_").gameObject
end

function FairArenaExploreWindow:initUIComponent()
	xyd.setUISpriteAsync(self.textImg_, nil, "fair_arena_text01_" .. xyd.Global.lang, nil, , true)

	self.endLabel_.text = __("FAIR_ARENA_END_TIME_1")
	self.winLabel_.text = __("FAIR_ARENA_SUCCESS")
	self.failLabel_.text = __("FAIR_ARENA_FAILURE")
	self.resultLabel_.text = __("FAIR_ARENA_DESC_END")
	self.res_shovelLabel_.text = __("FAIR_ARENA_NOTES_REVIVE")
	self.groupBuffLabel.text = __("FAIR_ARENA_GROUP_BUFF")
	self.frontLabel_.text = __("FRONT_ROW")
	self.backLabel_.text = __("BACK_ROW")
	self.testLabel_.text = __("FAIR_ARENA_DEMO_ABBR")
	self.tipsLabel2_.text = __("FAIR_ARENA_DESC_FIGHT")
	self.battleBtnLabel_.text = __("FAIR_ARENA_FIGHT_PREPARE")
	self.rankBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("FAIR_ARENA_RANK")
	self.awardBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("FAIR_ARENA_AWARD_PREVIEW")
	self.collectionBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("FAIR_ARENA_COLLECTION")
	self.recordBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("REOCRD")
	self.backpackBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("FAIR_ARENA_BACKPACK")
	self.abandonBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("FAIR_ARENA_GIVEUP")

	for i = 1, 3 do
		self["cardBtn_" .. i]:GetComponent(typeof(UILabel)).text = __("GUILD_TEXT21")
	end

	for i = 1, 6 do
		self["heroIcon" .. i] = HeroIcon.new(self["container" .. i])

		self["heroIcon" .. i]:SetActive(false)
	end

	self.windowTop = WindowTop.new(self.topGroup, self.name_, 10, nil, function ()
		if #self.select_partners > 0 or self.select_equips or self.select_buffs then
			self:reqSelect()
		end

		xyd.WindowManager:get():closeWindow("fair_arena_explore_window")
	end)
	local cost_id = tonumber(xyd.tables.miscTable:split2num("fair_arena_ticket_item", "value", "#")[1])
	local items = {
		{
			id = cost_id,
			callback = function ()
				if not self.activityData then
					self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FAIR_ARENA)
				end

				if self.activityData:getEndTime() - xyd.getServerTime() <= xyd.DAY_TIME then
					xyd.alertTips(__("FAIR_ARENA_GET_HOE_SHOW_TIME_NO"))
				else
					xyd.WindowManager.get():openWindow("fair_arena_get_hoe_window")
				end
			end
		},
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	self.windowTop:setItem(items)

	self.shovelLockSp = xyd.Spine.new(self.res_shovelLock2)

	self.shovelLockSp:setInfo("fair_arena_unlock", function ()
		self.shovelLockSp:play("animation", 0)
		self.shovelLockSp:SetLocalScale(0.4, 0.4, 1)
		self.shovelLockSp:SetLocalPosition(0, -32, 0)
	end)

	self.pEffect1 = xyd.Spine.new(self.previewEffect)

	self.pEffect1:setInfo("fair_arena_gift_idle", function ()
		self.pEffect1:SetLocalScale(0.6, 0.6, 1)
		self.pEffect1:play("texiao02", 0)
	end)

	self.pEffect2 = xyd.Spine.new(self.previewEffect2)

	self.pEffect2:setInfo("fair_arena_gift_idle", function ()
		self.pEffect2:play("texiao01", 0)
	end)

	self.widgets = {
		self.cardWidget,
		self.prepareWidget,
		self.resultWidget
	}
end

function FairArenaExploreWindow:register()
	FairArenaExploreWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.update))
	self.eventProxy_:addEventListener(xyd.event.FAIR_ARENA_SELECT, handler(self, self.onSelect))
	self.eventProxy_:addEventListener(xyd.event.FAIR_ARENA_EXPLORE, handler(self, self.onOperate))
	self.eventProxy_:addEventListener(xyd.event.FAIR_ARENA_BATTLE, handler(self, self.update))
	self.eventProxy_:addEventListener(xyd.event.FAIR_ARENA_RESET, handler(self, self.onReset))

	UIEventListener.Get(self.awardIcon_.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("fair_arena_award_preview_window", {
			stage = self.data.explore_stage
		})
	end)
	UIEventListener.Get(self.rankBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("fair_arena_rank_window")
	end)
	UIEventListener.Get(self.awardBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("fair_arena_award_window")
	end)
	UIEventListener.Get(self.collectionBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("fair_arena_collection_window", {
			select = 1
		})
	end)
	UIEventListener.Get(self.helpBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "FAIR_ARENA_HELP2"
		})
	end)

	for i = 1, 3 do
		UIEventListener.Get(self["cardBtn_" .. i]).onClick = handler(self, function ()
			self:onClickSelect(i)
		end)
	end

	UIEventListener.Get(self.swithBtn_).onClick = handler(self, self.onSwitch)
	UIEventListener.Get(self.previewBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("fair_arena_award_preview_window", {
			stage = self.data.explore_stage + 1
		})
	end)

	for i = 1, 2 do
		UIEventListener.Get(self["shovelBtn" .. i]).onClick = function ()
			self:onClickShovel(i)
		end

		UIEventListener.Get(self["res_shovelBtn" .. i]).onClick = handler(self, self.onClickShovel)
	end

	UIEventListener.Get(self.abandonBtn_).onClick = handler(self, self.onAbandon)
	UIEventListener.Get(self.previewBtn2_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("fair_arena_award_preview_window", {
			stage = self.data.explore_stage
		})
	end)
	UIEventListener.Get(self.groupBuffNode).onClick = handler(self, function ()
		local needPartners = {}

		for i in pairs(self.partners) do
			table.insert(needPartners, self.ownPartners[self.partners[i]])
		end

		local actBuffID = xyd.models.fairArena:getActBuffID(needPartners)

		xyd.WindowManager.get():openWindow("fair_arena_buff_preview_window", {
			actBuffID = actBuffID
		})
	end)

	for i = 1, 4 do
		UIEventListener.Get(self["buffNode" .. i]).onClick = handler(self, function ()
			xyd.alertTips(__("FAIR_ARENA_TIPS_BUFF_UNLOCK", BuffTipsLev[i]))
		end)
	end

	UIEventListener.Get(self.recordBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("fair_arena_video_window")
	end)
	UIEventListener.Get(self.backpackBtn_).onClick = handler(self, self.onBackpack)
	UIEventListener.Get(self.battleBtn_).onClick = handler(self, self.onBattle)
end

function FairArenaExploreWindow:update()
	self:updateData()

	if not self:checkIsEnd() then
		self:updateLayout()
		self:updateBottomGroup()
		self:updateRedMark()
	else
		local des = __("FAIR_ARENA_DESC_SETTLE")

		if self.type == 2 then
			des = __("FAIR_ARENA_DESC_SETTLE_DEMO")
		end

		xyd.alertConfirm(des, function ()
			xyd.WindowManager.get():openWindow("fair_arena_entry_window", {}, function ()
				xyd.WindowManager.get():closeWindow("fair_arena_explore_window")
			end)
		end)
	end

	self:checkShowEquipRedPoint()
end

function FairArenaExploreWindow:updateData()
	self.data = xyd.models.fairArena:getArenaInfo()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FAIR_ARENA)
	self.ownPartners = xyd.models.fairArena:getPartners() or {}
	self.type = self.data.explore_type
	self.box_partners = self.data.box_partners or {}
	self.box_equips = self.data.box_equips or {}
	self.box_buffs = self.data.box_buffs or {}
end

function FairArenaExploreWindow:updateLayout()
	if not self.countDown then
		self.countDown = CountDown.new(self.timeLabel_)
	end

	self.countDown:setInfo({
		duration = self.activityData:getEndTime() - xyd.getServerTime() - xyd.TimePeriod.DAY_TIME
	})
	self.timeLayout:Reposition()

	if self.type == 2 then
		self.testGroup:SetActive(true)
	end

	self.previewEffect:SetActive(false)
	self.previewEffect2:SetActive(false)

	self.animCallback = nil

	if self:updateCardGroup() then
		if self.data.is_fail == 0 and self.data.explore_stage < 11 then
			self:updatePreGroup()
		else
			self:updateResGroup()
		end
	end

	self:palyAnimation()
	self:updateAwardBox()
end

function FairArenaExploreWindow:palyAnimation()
	local function setter1(value)
		self.widgets[self.wid1].alpha = value
	end

	local function setter2(value)
		self.widgets[self.wid2].alpha = value
	end

	if not self.middleBgSp then
		self.middleBgSp = xyd.Spine.new(self.middleBg_)

		self.middleBgSp:setInfo("fair_arena_information", function ()
			xyd.SoundManager.get():playSound(xyd.SoundID.PAPER_UNFOLD)
			self.middleBgSp:play("switch", 1, nil, function ()
				self.widgets[self.wid1]:SetActive(true)
				self.animCallback()
				self.middleBgSp:play("idle", 0)

				self.wid2 = nil

				self.previewEffect:SetActive(true)
				self.previewEffect2:SetActive(true)
			end)

			local seq = self:getSequence()

			seq:Insert(0.3333333333333333, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.16666666666666666))
		end)

		self.notFirst = true
	elseif self.wid2 then
		self.middleBgSp:play("switch2", 1, nil, function ()
			xyd.SoundManager.get():playSound(xyd.SoundID.PAPER_UNFOLD)
			self.middleBgSp:play("switch", 1, nil, function ()
				self.middleBgSp:play("idle", 0)

				self.wid2 = nil

				self.previewEffect:SetActive(true)
				self.previewEffect2:SetActive(true)
			end)
			self.widgets[self.wid1]:SetActive(true)

			local seq = self:getSequence()

			seq:Insert(0.3333333333333333, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.16666666666666666))
		end)

		local seq = self:getSequence()

		__TRACE("確實走了這裡，透明度更改")
		seq:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 1, 0, 0.3333333333333333))
		seq:AppendCallback(function ()
			print("從這返回的")
			self.animCallback()
		end)
	else
		self.middleBgSp:play("idle", 0)

		if self.animCallback then
			self.animCallback()
		end
	end

	for i = 1, 3 do
		if i ~= self.wid1 then
			self.widgets[i]:SetActive(false)
		end
	end
end

function FairArenaExploreWindow:updateCardGroup()
	self.wid1 = 1

	if self.data.explore_stage > 1 or self.data.fail_times == 0 then
		self.swithBtn_:SetActive(true)
	else
		self.swithBtn_:SetActive(false)
	end

	if #self.box_partners > 0 then
		function self.animCallback()
			self:updatePartnerSelect()

			self.tipsLabel1_.text = __("FAIR_ARENA_DESC_SELECT_PARTNER")
		end

		if not self.notFirst and not self.partnerFlag then
			self.partnerFlag = true
			self.wid2 = 1
		end
	elseif #self.box_equips > 0 then
		function self.animCallback()
			self:updateEquipSelect()

			self.tipsLabel1_.text = __("FAIR_ARENA_DESC_SELECT_EQUIP")
		end

		if not self.notFirst and not self.equipFlag then
			self.equipFlag = true
			self.wid2 = 1
		end
	elseif #self.box_buffs > 0 then
		function self.animCallback()
			self:updateBuffSelect()

			self.tipsLabel1_.text = __("FAIR_ARENA_DESC_SELECT_BUFF")
		end

		self:updateBuffSelect()

		if not self.notFirst and not self.buffFlag then
			self.buffFlag = true
			self.wid2 = 1
		end
	elseif #self.select_partners > 0 or self.select_equips or self.select_buffs then
		self.middleMask_:SetActive(true)
		self:reqSelect()
	else
		self.wid2 = 1

		return true
	end
end

function FairArenaExploreWindow:updatePreGroup()
	self.wid1 = 2

	function self.animCallback()
		self.battleBtnLabel_.text = __("FAIR_ARENA_FIGHT_PREPARE")

		self:updateShovelGroup()
	end
end

function FairArenaExploreWindow:updateResGroup()
	self.wid1 = 3

	function self.animCallback()
		self.battleBtnLabel_.text = __("FAIR_ARENA_SETTLE")

		self:updateShovelGroup()
	end
end

function FairArenaExploreWindow:updateShovelGroup()
	local fail_times = self.data.fail_times
	local is_fail = self.data.is_fail

	if is_fail == 0 and fail_times > 0 then
		xyd.setUISpriteAsync(self.shovelIcon1, nil, "fair_arena_explore_icon2")
		xyd.setUISpriteAsync(self.res_shovelIcon1, nil, "fair_arena_explore_icon2")
		xyd.setUISpriteAsync(self.shovelIcon2, nil, "fair_arena_explore_icon3")
		xyd.setUISpriteAsync(self.res_shovelIcon2, nil, "fair_arena_explore_icon3")
		self.shovelLock2_:SetActive(true)
		self.res_shovelLabel_:SetActive(true)
		self.res_shovelLock2:SetActive(true)
	elseif is_fail > 0 and fail_times > 0 then
		xyd.setUISpriteAsync(self.shovelIcon1, nil, "fair_arena_explore_icon1")
		xyd.setUISpriteAsync(self.res_shovelIcon1, nil, "fair_arena_explore_icon1")
		xyd.setUISpriteAsync(self.shovelIcon2, nil, "fair_arena_explore_icon3")
		xyd.setUISpriteAsync(self.res_shovelIcon2, nil, "fair_arena_explore_icon3")
		self.shovelLock2_:SetActive(true)
		self.res_shovelLabel_:SetActive(true)
		self.res_shovelLock2:SetActive(true)
	elseif is_fail == 0 and fail_times == 0 then
		xyd.setUISpriteAsync(self.shovelIcon1, nil, "fair_arena_explore_icon1")
		xyd.setUISpriteAsync(self.res_shovelIcon1, nil, "fair_arena_explore_icon1")
		xyd.setUISpriteAsync(self.shovelIcon2, nil, "fair_arena_explore_icon3")
		xyd.setUISpriteAsync(self.res_shovelIcon2, nil, "fair_arena_explore_icon3")
		self.shovelLock2_:SetActive(false)
		self.res_shovelLock2:SetActive(false)
		self.res_shovelLabel_:SetActive(false)
	else
		xyd.setUISpriteAsync(self.shovelIcon1, nil, "fair_arena_explore_icon1")
		xyd.setUISpriteAsync(self.res_shovelIcon1, nil, "fair_arena_explore_icon1")
		xyd.setUISpriteAsync(self.shovelIcon2, nil, "fair_arena_explore_icon1")
		xyd.setUISpriteAsync(self.res_shovelIcon2, nil, "fair_arena_explore_icon1")
		self.shovelLock2_:SetActive(false)
		self.res_shovelLock2:SetActive(false)
		self.res_shovelLabel_:SetActive(false)
	end
end

function FairArenaExploreWindow:updateAwardBox()
	local stage = self.data.explore_stage
	local level = stage - 1
	local style1 = xyd.tables.activityFairArenaLevelTable:getStyle(stage)
	local style2 = xyd.tables.activityFairArenaLevelTable:getStyle(stage + 1)

	if stage == 11 then
		style2 = style1
	end

	xyd.setUISpriteAsync(self.awardIcon_, nil, "fair_arena_awardbox_icon" .. style1)
	xyd.setUISpriteAsync(self.previewBtnSprite, nil, "fair_arena_awardbox_icon" .. style2)
	xyd.setUISpriteAsync(self.previewBtnSprite2, nil, "fair_arena_awardbox_icon" .. style1)

	self.awardIconLabel_.text = __("FAIR_ARENA_TITLE_GIFT", level)
	self.previewBtnLabel1.text = __("FAIR_ARENA_TITLE_GIFT", level + 1)
	self.previewBtnLabel2.text = __("FAIR_ARENA_TITLE_GIFT", level)
end

function FairArenaExploreWindow:updatePartnerSelect()
	self.selectType = 1
	local box_selects = xyd.split(self.box_partners[1], "|", true)

	for i = 1, 3 do
		NGUITools.DestroyChildren(self["cardIconNode" .. i].transform)
		self["cardIconNode" .. i]:SetActive(true)
		xyd.getItemIcon({
			isShowSelected = false,
			uiRoot = self["cardIconNode" .. i],
			itemID = PartnerBoxTable:getPartnerID(box_selects[i]),
			lev = PartnerBoxTable:getLv(box_selects[i]),
			grade = PartnerBoxTable:getGrade(box_selects[i]),
			equips = PartnerBoxTable:getEquips(box_selects[i]),
			callback = function ()
				xyd.WindowManager.get():openWindow("fair_arena_partner_info_window", {
					tableID = box_selects[i]
				})
			end
		})
	end
end

function FairArenaExploreWindow:updateEquipSelect()
	self.selectType = 2
	local box_selects = self.box_equips

	for i = 1, 3 do
		NGUITools.DestroyChildren(self["cardIconNode" .. i].transform)
		self["cardIconNode" .. i]:SetActive(true)
		xyd.getItemIcon({
			num = 1,
			uiRoot = self["cardIconNode" .. i],
			itemID = ArtifactBoxTable:getEquipID(box_selects[i])
		})
	end
end

function FairArenaExploreWindow:updateBuffSelect()
	self.selectType = 3
	local box_selects = self.box_buffs

	for i = 1, 3 do
		NGUITools.DestroyChildren(self["cardIconNode" .. i].transform)
		self["cardIconNode" .. i]:SetActive(true)

		local id = box_selects[i]
		local icon = GroupBuffIcon.new(self["cardIconNode" .. i])

		icon:SetLocalScale(1.542857142857143, 1.542857142857143, 1)
		icon:setInfo(id, true, xyd.GroupBuffIconType.FAIR_ARENA)

		UIEventListener.Get(icon.go).onSelect = function (go, isSelect)
			if isSelect then
				self:onClcikBuffNode(id, 200, true)
			else
				self:clearBuffTips()
			end
		end
	end
end

function FairArenaExploreWindow:updateBottomGroup()
	self:updatePartnerGroup()
	self:updateBuffGroup()
end

function FairArenaExploreWindow:updatePartnerGroup()
	self.partners = {}
	local nowPartnerList = xyd.models.fairArena:readStorageFormation()
	nowPartnerList = nowPartnerList or {
		1,
		2,
		3,
		4,
		5,
		6
	}

	for pos, partner_id in ipairs(nowPartnerList) do
		local p = self.ownPartners[partner_id]
		local icon = self["heroIcon" .. pos]

		if p then
			icon:SetActive(true)
			icon:setInfo({
				scale = 0.8981481481481481,
				isShowSelected = false,
				itemID = p:getTableID(),
				lev = p:getLevel(),
				grade = p:getGrade(),
				equips = p:getEquipment(),
				callback = function ()
					xyd.WindowManager.get():openWindow("fair_arena_partner_info_window", {
						partnerID = p:getPartnerID(),
						list = self:getPList()
					})
				end
			})

			self.partners[pos] = partner_id
		else
			icon:SetActive(false)
		end
	end

	self:updateForceNum()
end

function FairArenaExploreWindow:updateBuffGroup()
	self.buffs = {}

	for i = 1, 4 do
		NGUITools.DestroyChildren(self["buffNode" .. i].transform)
	end

	local buffs = self.data.buffs

	for i = 1, #buffs do
		local icon = GroupBuffIcon.new(self["buffNode" .. i])

		icon:SetLocalScale(0.5915492957746479, 0.6, 1)
		icon:setInfo(buffs[i], true, xyd.GroupBuffIconType.FAIR_ARENA)

		UIEventListener.Get(icon.go).onSelect = function (go, isSelect)
			if isSelect then
				self:onClcikBuffNode(buffs[i], -170, true)
			else
				self:clearBuffTips()
			end
		end

		xyd.setTouchEnable(self["buffNode" .. i], false)

		self.buffs[i] = buffs[i]
	end

	self:updateGroupBuff()
end

function FairArenaExploreWindow:onClickSelect(index)
	self.middleMask_:SetActive(true)

	local pos = self:getDesPos(self.selectType, index)
	local seq = self:getSequence()
	local scale = 1
	local callback = nil

	if self.selectType == 1 then
		if pos[3] < 7 then
			scale = 0.8981481481481481
		else
			scale = 0
		end

		function callback()
			local tableID = xyd.split(self.box_partners[1], "|", true)[index]

			if pos[3] < 7 then
				local p = Partner.new()

				p:populate({
					isHeroBook = true,
					table_id = PartnerBoxTable:getPartnerID(tableID),
					lev = PartnerBoxTable:getLv(tableID),
					grade = PartnerBoxTable:getGrade(tableID),
					equips = PartnerBoxTable:getEquips(tableID),
					partner_id = #self.ownPartners + 1
				})

				p.box_table_id = tableID

				table.insert(self.ownPartners, p)

				local icon = self["heroIcon" .. pos[3]]

				icon:SetActive(true)
				icon:setInfo({
					scale = 0.8981481481481481,
					isShowSelected = false,
					itemID = PartnerBoxTable:getPartnerID(tableID),
					lev = PartnerBoxTable:getLv(tableID),
					grade = PartnerBoxTable:getGrade(tableID),
					equips = PartnerBoxTable:getEquips(tableID),
					callback = function ()
						xyd.WindowManager.get():openWindow("fair_arena_partner_info_window", {
							partnerID = p:getPartnerID(),
							list = self:getPList()
						})
					end
				})

				if pos[3] < 7 then
					self.partners[pos[3]] = p:getPartnerID()

					self:updateForceNum()
					self:updateGroupBuff()
				end
			end

			table.remove(self.box_partners, 1)
			table.insert(self.select_partners, index)
		end
	elseif self.selectType == 2 then
		scale = 0

		function callback()
			self.box_equips = {}
			self.select_equips = index
		end
	elseif self.selectType == 3 then
		scale = 0.39

		function callback()
			local ind = pos[3] - 7
			local id = self.box_buffs[index]
			local icon = GroupBuffIcon.new(self["buffNode" .. ind])

			icon:SetLocalScale(0.5915492957746479, 0.6, 1)
			icon:setInfo(id, true, xyd.GroupBuffIconType.FAIR_ARENA)

			UIEventListener.Get(icon.go).onSelect = function (go, isSelect)
				if isSelect then
					self:onClcikBuffNode(id, -170, true)
				else
					self:clearBuffTips()
				end
			end

			xyd.setTouchEnable(self["buffNode" .. ind], false)

			self.box_buffs = {}
			self.select_buffs = index
			self.buffs[ind] = id
		end
	end

	seq:Insert(0, self["cardIconNode" .. index].transform:DOLocalMove(Vector3(pos[1], pos[2], 0), 0.4)):Insert(0.15, self["cardIconNode" .. index].transform:DOScale(Vector3(scale, scale, 1), 0.25)):InsertCallback(0.4, callback)
	self:waitForTime(0.4, function ()
		self["cardIconNode" .. index]:SetActive(false)
		self["cardIconNode" .. index]:SetLocalPosition(0, 20, 0)
		self["cardIconNode" .. index]:SetLocalScale(1, 1, 1)
		self:updateLayout()
		self.middleMask_:SetActive(false)
	end)
end

function FairArenaExploreWindow:reqSelect(notClear)
	__TRACE("從哪過來的=======")

	if self.select_equips and self.select_equips > 0 then
		local isCanShowFirstEquipRedPoint = xyd.db.misc:getValue("is_can_show_first_equip_red_point")

		if isCanShowFirstEquipRedPoint and isCanShowFirstEquipRedPoint == "1" then
			FairArena:checkGetNewEquip()
		end
	end

	if #self.select_partners > 0 or self.select_equips or self.select_buffs then
		FairArena:reqSelect(self.select_partners, self.select_equips, self.select_buffs)

		self.select_partners = {}
		self.select_equips = nil
		self.select_buffs = nil
	end

	if not notClear then
		self.selectType = 0
	end
end

function FairArenaExploreWindow:onSelect(event)
	if self.is_reset then
		xyd.WindowManager.get():openWindow("fair_arena_reset_window", {
			type = self.selectType
		})

		self.is_reset = false
	elseif self.is_backpack then
		xyd.WindowManager.get():openWindow("fair_arena_backpack_window")

		self.is_backpack = false
	end

	self.selectType = 0

	self:updateData()
	self:updateLayout()
	self.middleMask_:SetActive(false)
end

function FairArenaExploreWindow:onSwitch()
	if #self.select_partners > 0 or self.select_equips or self.select_buffs then
		self.is_reset = true

		self:reqSelect(true)
	else
		xyd.WindowManager.get():openWindow("fair_arena_reset_window", {
			type = self.selectType
		})
	end
end

function FairArenaExploreWindow:onBackpack()
	local function openFun()
		if #self.select_partners > 0 or self.select_equips or self.select_buffs then
			self.is_backpack = true

			self:reqSelect(true)
		else
			xyd.WindowManager.get():openWindow("fair_arena_backpack_window")
		end
	end

	local isCanShowFirstEquipRedPoint = xyd.db.misc:getValue("is_can_show_first_equip_red_point")
	local timeStamp = xyd.db.misc:getValue("fair_arena_open_back_pack_time_stamp")
	timeStamp = timeStamp and tonumber(timeStamp)

	if isCanShowFirstEquipRedPoint and isCanShowFirstEquipRedPoint == "2" and (not timeStamp or timeStamp < self.activityData:startTime() or self.activityData:getEndTime() < timeStamp) then
		xyd.openWindow("gamble_tips_window", {
			type = "fair_arena_open_back_pack",
			text = __("FAIR_ARENA_OPEN_BACK_PACK_TIPS"),
			btnYesText = __("SURE"),
			labelNeverText = __("FAIR_ARENA_OPEN_BACK_PACK_TIPS2")
		})
	end

	openFun()
end

function FairArenaExploreWindow:onOperate(event)
	local data = event.data
	local operate = data.operate

	if operate == xyd.FairArenaType.REVIVE then
		self.wid2 = 3
		self.partnerFlag = false
		self.equipFlag = false
		self.buffFlag = false

		self:update()
	elseif operate == xyd.FairArenaType.COMPLETE then
		local level = data.info.explore_stage
		local awards = xyd.tables.activityFairArenaLevelTable:getAwards(level)
		local items = {}

		for i = 1, #awards do
			table.insert(items, {
				item_id = awards[i][1],
				item_num = awards[i][2]
			})
		end

		local function callback()
			xyd.WindowManager.get():openWindow("gamble_rewards_window", {
				wnd_type = 2,
				data = items,
				callback = function ()
					xyd.WindowManager.get():openWindow("fair_arena_entry_window", {}, function ()
						xyd.WindowManager.get():closeWindow("fair_arena_explore_window")
					end)
				end
			})
		end

		xyd.models.fairArena:saveLocalformation({})

		if self.type == 2 then
			xyd.WindowManager.get():openWindow("fair_arena_entry_window", {}, function ()
				xyd.WindowManager.get():closeWindow("fair_arena_explore_window")
			end)
		elseif not self.isAbandon then
			self.mask_:SetActive(true)
			NGUITools.DestroyChildren(self.previewEffect2.transform)

			self.pEffect3 = xyd.Spine.new(self.previewEffect3)

			self.pEffect3:setInfo("fair_arena_gift_open", function ()
				self.pEffect3:play("texiao01", 1, nil, function ()
					callback()
				end)
			end)
		else
			callback()
		end
	end
end

function FairArenaExploreWindow:onReset()
	self.wid2 = 1

	self:update()
end

function FairArenaExploreWindow:onBattle()
	if self.selectType and self.selectType > 0 then
		xyd.alertTips(__("FAIR_ARENA_TIPS_NEED_SELECT"))

		return
	end

	if self.data.is_fail == 0 then
		xyd.WindowManager.get():openWindow("fair_arena_enemy_formation_window", {
			info = self.data.enemy_infos
		})
	else
		if self.data.is_fail > 0 and self.data.fail_times > 0 and self.data.explore_stage < 11 then
			local cost = xyd.tables.miscTable:split2num("fair_arena_explore_replay_price", "value", "#")

			xyd.openWindow("fair_arena_alert_window", {
				alertType = xyd.AlertType.YES_NO,
				message = __("FAIR_ARENA_TIPS_REVIVE_UNLOCK" .. self.type, cost[2]),
				confirmText = __("FAIR_ARENA_TIPS_REVIVE_YES"),
				closeText = __("FAIR_ARENA_TIPS_REVIVE_NO"),
				callback = function (yes)
					if yes then
						local hasNum = xyd.models.backpack:getItemNumByID(cost[1])

						if self.type == 1 and hasNum < cost[2] then
							xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

							return
						end

						xyd.models.fairArena:reqExplore(xyd.FairArenaType.REVIVE)
					else
						xyd.models.fairArena:reqExplore(xyd.FairArenaType.COMPLETE)
					end
				end
			})

			return
		end

		xyd.models.fairArena:reqExplore(xyd.FairArenaType.COMPLETE)
	end
end

function FairArenaExploreWindow:onClickShovel(index)
	if self.data.is_fail == 0 then
		if index and index == 2 then
			xyd.alertTips(__("FAIR_ARENA_TIPS_REVIVE_2"))
		else
			xyd.alertTips(__("FAIR_ARENA_TIPS_REVIVE"))
		end
	else
		if self.data.is_fail > 0 and self.data.fail_times > 0 and self.data.explore_stage < 11 then
			local cost = xyd.tables.miscTable:split2num("fair_arena_explore_replay_price", "value", "#")

			xyd.openWindow("fair_arena_alert_window", {
				alertType = xyd.AlertType.YES_NO,
				message = __("FAIR_ARENA_TIPS_REVIVE_UNLOCK" .. self.type, cost[2]),
				callback = function (yes)
					if yes then
						local hasNum = xyd.models.backpack:getItemNumByID(cost[1])

						if self.type == 1 and hasNum < cost[2] then
							xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

							return
						end

						xyd.models.fairArena:reqExplore(xyd.FairArenaType.REVIVE)
					end
				end
			})

			return
		end

		if self.data.explore_stage < 11 then
			xyd.alertTips(__("FAIR_ARENA_TIPS_REVIVE_LIMIT"))
		else
			xyd.alertTips(__("FAIR_ARENA_TIPS_REVIVE_UNLOCK3"))
		end
	end
end

function FairArenaExploreWindow:onAbandon()
	xyd.openWindow("fair_arena_alert_window", {
		alertType = xyd.AlertType.YES_NO,
		message = __("FAIR_ARENA_TIPS_END"),
		callback = function (yes)
			if yes then
				self.isAbandon = true

				xyd.models.fairArena:reqExplore(xyd.FairArenaType.COMPLETE)
			end
		end
	})
end

function FairArenaExploreWindow:getDesPos(type, index)
	local index2 = self:getDesPosIndex(type)
	local x = 0
	local y = 0

	if index2 <= 2 then
		x = self["container" .. index2].transform.localPosition.x + self.frontGroup.transform.localPosition.x
		y = self["container" .. index2].transform.localPosition.y + self.frontGroup.transform.localPosition.y
	elseif index2 < 7 then
		x = self["container" .. index2].transform.localPosition.x + self.backGroup.transform.localPosition.x
		y = self["container" .. index2].transform.localPosition.y + self.backGroup.transform.localPosition.y
	elseif index2 == 7 then
		x = self.backpackBtn_.transform.localPosition.x
		y = self.backpackBtn_.transform.localPosition.y
	elseif index2 > 7 then
		local tmpInd = index2 - 7
		x = self["buffNode" .. tmpInd].transform.localPosition.x + self.buffGroup.transform.localPosition.x
		y = self["buffNode" .. tmpInd].transform.localPosition.y + self.buffGroup.transform.localPosition.y
	end

	x = x + self.bottomGroup.transform.localPosition.x - self.cardGroup.transform.localPosition.x - self.middleGroup.transform.localPosition.x
	y = y + self.bottomGroup.transform.localPosition.y - self.cardGroup.transform.localPosition.y - self.middleGroup.transform.localPosition.y
	x = x - self["card" .. index].transform.localPosition.x
	y = y - self["card" .. index].transform.localPosition.y

	return {
		x,
		y,
		index2
	}
end

function FairArenaExploreWindow:getDesPosIndex(type)
	if type == 1 then
		for i = 1, 6 do
			if not self.partners[i] then
				return i
			end
		end

		return 7
	elseif type == 2 then
		return 7
	elseif type == 3 then
		for i = 1, 4 do
			if not self.buffs[i] then
				return 7 + i
			end
		end
	end
end

function FairArenaExploreWindow:updateForceNum()
	local power = 0

	for _, id in pairs(self.partners) do
		local p = self.ownPartners[id]

		if p then
			power = power + p:getPower()
		end
	end

	self.forceLabel_.text = power
	local formation = {
		partners = self.partners
	}

	xyd.models.fairArena:saveLocalformation(formation)
end

function FairArenaExploreWindow:updateGroupBuff()
	xyd.setTouchEnable(self.groupBuffNode, true)

	if #self.partners < 6 then
		NGUITools.DestroyChildren(self.groupBuffNode.transform)

		return
	end

	dump(self.partners, "测试错误")

	local needPartners = {}

	for i in pairs(self.partners) do
		table.insert(needPartners, self.ownPartners[self.partners[i]])
	end

	local actBuffID = xyd.models.fairArena:getActBuffID(needPartners)

	if actBuffID > 0 then
		if not self.groupBuff then
			self.groupBuff = GroupBuffIcon.new(self.groupBuffNode)

			self.groupBuff:SetLocalScale(0.9142857142857143, 0.9142857142857143, 1)
		end

		self.groupBuff:setEffectScale(0.95)
		self.groupBuff:setSelectImg("fair_arena_buff_select_bg", true)
		self.groupBuff:setInfo(actBuffID, true)
	else
		NGUITools.DestroyChildren(self.groupBuffNode.transform)
	end
end

function FairArenaExploreWindow:onClcikBuffNode(buffID, contenty, isFairType)
	local params = {
		buffID = buffID,
		contenty = contenty
	}

	if isFairType then
		params.type = xyd.GroupBuffIconType.FAIR_ARENA
	end

	local win = xyd.getWindow("group_buff_detail_window")

	if win then
		win:update(params)
	else
		xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
	end
end

function FairArenaExploreWindow:clearBuffTips()
	xyd.closeWindow("group_buff_detail_window")
end

function FairArenaExploreWindow:updateRedMark()
	xyd.models.redMark:setMark(xyd.RedMarkType.FAIR_ARENA, self.activityData:getRedMarkState())
end

function FairArenaExploreWindow:checkIsEnd()
	if xyd.TimePeriod.DAY_TIME < self.activityData:getEndTime() - xyd.getServerTime() then
		return false
	end

	return true
end

function FairArenaExploreWindow:getPList()
	local list = {}
	local i = 1

	for _, id in pairs(self.partners) do
		list[i] = id
		i = i + 1
	end

	return list
end

function FairArenaExploreWindow:getWindowTop()
	return self.windowTop
end

function FairArenaExploreWindow:resizeToParent()
	local height = self.window_:GetComponent(typeof(UIPanel)).height

	self.bgGroup:Y(-310 - (height - 1280) * 0.4)
	self.middleGroup:Y(120 - (height - 1280) * 0.3)
end

function FairArenaExploreWindow:checkShowEquipRedPoint()
	print("进来了红点检查逻辑")

	if self.type and (self.type == xyd.FairArenaType.NORMAL or self.type == xyd.FairArenaType.TEST) then
		local isCanShowFirstEquipRedPoint = xyd.db.misc:getValue("is_can_show_first_equip_red_point")

		print("isCanShowFirstEquipRedPoint:", isCanShowFirstEquipRedPoint, " ", type(isCanShowFirstEquipRedPoint))

		if isCanShowFirstEquipRedPoint ~= nil and isCanShowFirstEquipRedPoint == "2" then
			self.backpackBtnRedPoint.gameObject:SetActive(true)
		else
			self.backpackBtnRedPoint.gameObject:SetActive(false)
		end
	end
end

return FairArenaExploreWindow
