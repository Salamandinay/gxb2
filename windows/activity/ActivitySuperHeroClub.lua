local Hero_Club_Item = class("Hero_Club_Item", import("app.components.CopyComponent"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local json = require("cjson")

function Hero_Club_Item:ctor(go, heroClub)
	Hero_Club_Item.super.ctor(self, go)

	self.heroClub = heroClub

	self:setDragScrollView(heroClub.scroller_ScrollView)
	self:getUIComponent()
end

function Hero_Club_Item:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.id = info.itemID

	self:initUIComponent()
end

function Hero_Club_Item:getUIComponent()
	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UISprite))
	self.imgReward = go:NodeByName("imgReward")
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.imgReward = go:ComponentByName("imgReward", typeof(UISprite))
	self.labelTime = go:ComponentByName("labelTime", typeof(UILabel))
end

function Hero_Club_Item:initUIComponent()
	NGUITools.DestroyChildren(self.groupIcon.transform)

	local icon = xyd.getItemIcon({
		not_show_ways = true,
		num = 0,
		uiRoot = self.groupIcon,
		itemID = self.id
	})

	icon:AddUIDragScrollView()
	self.imgBg:SetActive(false)
	self.imgReward:SetActive(false)
	self.labelTime:SetActive(false)
end

local ActivityContent = import(".ActivityContent")
local ActivitySuperHeroClub = class("ActivitySuperHeroClub", ActivityContent)

function ActivitySuperHeroClub:ctor(parentGO, params)
	ActivitySuperHeroClub.super.ctor(self, parentGO, params)

	self.askReqNum = 0

	self:getUIComponent()
	self:initData()
	self:initUIComponet()
	self:AddRegisterEvent()

	local round = self.nowRound
	local newIds = xyd.tables.activityPartnerJackpotTable:getNewIds(round)

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.SUPER_HERO_CLUB, function ()
		xyd.db.misc:setValue({
			key = "partner_jackpot_records",
			value = json.encode(newIds)
		})
	end)
end

function ActivitySuperHeroClub:getPrefabPath()
	return "Prefabs/Windows/activity/super_hero_club"
end

function ActivitySuperHeroClub:initUIComponet()
	self:layout()
	self:initUITexture()
end

function ActivitySuperHeroClub:getUIComponent()
	local go = self.go
	self.hero_item = go:NodeByName("hero_item").gameObject
	self.bg = go:ComponentByName("bg", typeof(UITexture))
	self.heroNode = go:NodeByName("heroNode")
	self.heroImg = self.heroNode:ComponentByName("heroImg", typeof(UITexture))
	self.titleImg = go:ComponentByName("titleImg", typeof(UISprite))
	self.preBtn = go:ComponentByName("preBtn", typeof(UITexture))
	self.preBtn_button_label = self.preBtn:ComponentByName("button_label", typeof(UILabel))
	self.preBtn_button_label.color = Color.New2(1130479615)
	self.preBtn_button_label.effectColor = Color.New2(4294967295.0)
	self.helpBtn0 = go:NodeByName("helpBtn0").gameObject
	self.desNode = go:NodeByName("desNode").gameObject
	self.scroller = self.desNode:NodeByName("scroller").gameObject
	self.scroller_ScrollView = self.desNode:ComponentByName("scroller", typeof(UIScrollView))
	self.scroller_uiPanel = self.desNode:ComponentByName("scroller", typeof(UIPanel))
	self.itemsGroup_ = self.scroller:NodeByName("itemsGroup_").gameObject
	local wrapContent = self.itemsGroup_:GetComponent(typeof(MultiRowWrapContent))
	self.ImageBgBehind = self.desNode:ComponentByName("ImageBgBehind", typeof(UITexture))
	self.ImageBgFront = self.desNode:ComponentByName("ImageBgFront", typeof(UITexture))
	self.unitNode = self.desNode:NodeByName("unitNode").gameObject
	self.iconBg = self.unitNode:ComponentByName("iconBg", typeof(UITexture))
	self.allUnitText = self.unitNode:ComponentByName("allUnitText", typeof(UILabel))
	self.okBtn = self.desNode:ComponentByName("okBtn", typeof(UITexture))
	self.okBtn_button_label = self.okBtn:ComponentByName("button_label", typeof(UILabel))
	self.okBtn_button_label.color = Color.New2(2975269119.0)
	self.okBtn_button_label.effectColor = Color.New2(4294967295.0)
	self.skipBtn = self.desNode:NodeByName("skipBtn").gameObject
	self.skipBtn_selectImg = self.skipBtn:ComponentByName("selectImg", typeof(UISprite))
	self.skipBtn_button_label = self.skipBtn:ComponentByName("button_label", typeof(UILabel))
	self.tipWords = self.desNode:ComponentByName("tipWords", typeof(UILabel))
	self.timeWords0 = self.desNode:ComponentByName("timeWords0", typeof(UILabel))
	self.timeWords1 = self.desNode:ComponentByName("timeWords1", typeof(UILabel))
	self.timeText = self.desNode:ComponentByName("timeText", typeof(UILabel))
	self.spinCon = self.go:NodeByName("spinCon/root").gameObject
	self.wrapContent = FixedMultiWrapContent.new(self.scroller_ScrollView, wrapContent, self.hero_item, Hero_Club_Item, self)
end

function ActivitySuperHeroClub:initUITexture()
	local res_prefix = "Textures/activity_web/super_hero_club/"
	local text_res_prefix = "Textures/activity_text_web/"

	xyd.setUITextureAsync(self.bg, res_prefix .. "super_hero_club_bg", function ()
	end)
	xyd.setUISpriteAsync(self.titleImg, nil, "super_hero_club_logo_" .. tostring(xyd.Global.lang), nil, , true)
	xyd.setUITextureAsync(self.preBtn, res_prefix .. "super_hero_club_pre_btn", function ()
	end)
	xyd.setUITextureAsync(self.ImageBgBehind, res_prefix .. "super_hero_club_message_bg", function ()
	end)
	xyd.setUITextureAsync(self.ImageBgFront, res_prefix .. "super_hero_club_avatar_bg", function ()
	end)
	xyd.setUITextureAsync(self.iconBg, res_prefix .. "super_hero_club_money_bg", function ()
	end)
	xyd.setUITextureAsync(self.okBtn, res_prefix .. "super_hero_club_yellow_btn", function ()
	end)
end

function ActivitySuperHeroClub:layout()
	self.tipWords.text = __("ACTIVITY_PARTNER_JACKPOT_TEXT01")
	self.timeWords0.text = __("ACTIVITY_PARTNER_JACKPOT_END1")
	self.timeWords1.text = __("ACTIVITY_PARTNER_JACKPOT_END2")

	if xyd.Global.lang == "en_en" then
		self.timeWords1:SetActive(false)
	end

	self.preBtn_button_label.text = __("ACTIVITY_PARTNER_JACKPOT_PREVIEW")
	local costArr = xyd.tables.miscTable:split2Cost("partner_jackpot_cost", "value", "#")
	self.okBtn_button_label.text = costArr[2]

	self:updateMoneyShow()

	self.timer_ = Timer.New(handler(self, self.updateTimeLabel), 1, -1, false)

	self.timer_:Start()
	self:updateTimeLabel()

	self.skipBtn_button_label.text = __("SKIP_ANIMATION")

	self:freshSkipBtnState()
end

function ActivitySuperHeroClub:updateMoneyShow()
	local costArr = xyd.tables.miscTable:split2Cost("partner_jackpot_cost", "value", "#")
	self.allUnitText.text = tostring(xyd.models.backpack:getItemNumByID(costArr[1]))
end

function ActivitySuperHeroClub:euiComplete()
	ActivityContent.euiComplete(self)
	self:initData()
	self:layout()
end

function ActivitySuperHeroClub:AddRegisterEvent()
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, function (_, event)
		local id = event.data.act_info.activity_id

		if id ~= self.id then
			return
		end

		self:initData()
	end))

	UIEventListener.Get(self.preBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_super_hero_club_pre_window", {
			nowRound = self.nowRound
		})
	end)
	UIEventListener.Get(self.unitNode.gameObject).onClick = handler(self, function ()
		local costArr = xyd.tables.miscTable:split2Cost("partner_jackpot_cost", "value", "#")
		local params = {
			show_has_num = true,
			itemID = tonumber(costArr[1]),
			itemNum = tonumber(xyd.models.backpack:getItemNumByID(costArr[1])),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end)
	UIEventListener.Get(self.helpBtn0.gameObject).onClick = handler(self, function ()
		local params = {
			key = "ACTIVITY_PARTNER_JACKPOT_HELP"
		}

		xyd.WindowManager.get():openWindow("help_window", params)
	end)
	UIEventListener.Get(self.okBtn.gameObject).onClick = handler(self, self.checkCanBuy)
	UIEventListener.Get(self.skipBtn).onClick = handler(self, self.onClickSkip)

	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateMoneyShow))

	self.summonEffect_ = xyd.Spine.new(self.spinCon)

	self.summonEffect_:setInfo("fx_huizhang", function ()
		self.summonEffect_:SetLocalScale(1, 1, 1)
		self.summonEffect_:setRenderTarget(self.spinCon:GetComponent(typeof(UISprite)), 1)
	end)
	self.spinCon:SetActive(false)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, function (_, event)
		if event.data.activity_id ~= xyd.ActivityID.SUPER_HERO_CLUB then
			return
		end

		local detail = json.decode(event.data.detail)
		local cur_award_ = detail.items

		self.spinCon:SetActive(true)

		if self.skipState and self.skipState == "1" then
			self.spinCon:SetActive(false)
			xyd.WindowManager.get():openWindow("summon_result_window", {
				oldBaodiEnergy = 0,
				progressValue = 0,
				type = 6,
				items = {
					{
						item_num = 1,
						item_id = cur_award_[1].table_id
					}
				}
			})
		else
			self.summonEffect_:play("texiao01", 1, 1, function ()
				self.spinCon:SetActive(false)
				self:playGetAward(cur_award_[1].table_id)
			end, false)
		end

		local partnerInfos = detail.items

		if not partnerInfos then
			return
		end

		xyd.models.slot:addPartners(partnerInfos)
	end))
end

function ActivitySuperHeroClub:onActivityInfoById(event)
	local id = event.data.act_info.activity_id

	if id ~= self.id then
		return
	end

	self:initData()
end

function ActivitySuperHeroClub:playGetAward(playerId)
	xyd.onGetNewPartnersOrSkins({
		show_res_after_skip = true,
		destory_res = false,
		partners = {
			playerId
		},
		callback = function ()
		end
	}, {})
end

function ActivitySuperHeroClub:checkCanBuy()
	local canSummonNum = xyd.models.slot:getCanSummonNum()

	if canSummonNum == 0 then
		xyd.openWindow("partner_slot_increase_window")

		return false
	end

	local costArr = xyd.tables.miscTable:split2Cost("partner_jackpot_cost", "value", "#")

	if xyd.models.backpack:getItemNumByID(costArr[1]) < costArr[2] then
		xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(costArr[1])))
	else
		local params = {
			num = 1
		}
		local msg = messages_pb.get_activity_award_req()
		msg.activity_id = self.activityData.id
		msg.params = json.encode(params)

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
	end
end

function ActivitySuperHeroClub:freshSkipBtnState()
	local state = xyd.db.misc:getValue("super_hero_club_skip")

	if state and state == "1" then
		xyd.setUISpriteAsync(self.skipBtn_selectImg, nil, "setting_up_pick")
	else
		xyd.setUISpriteAsync(self.skipBtn_selectImg, nil, "setting_up_unpick")
	end

	self.skipState = state
end

function ActivitySuperHeroClub:onClickSkip()
	local state = xyd.db.misc:getValue("super_hero_club_skip")

	if state and state == "1" then
		xyd.db.misc:setValue({
			value = "0",
			key = "super_hero_club_skip"
		})
	else
		xyd.db.misc:setValue({
			value = "1",
			key = "super_hero_club_skip"
		})
	end

	self:freshSkipBtnState()
end

function ActivitySuperHeroClub:updateTimeLabel()
	local theTime = self:getRetTime()

	if self:getRetTime() < 0 then
		if self.askReqNum >= 60 then
			self.askReqNum = 0
		end

		if self.askReqNum == 0 then
			xyd.models.activity:reqActivityByID(self.id)
		end

		self.askReqNum = self.askReqNum + 1
		self.timeText.text = self:getTimeStr(0)
	else
		if self.timeText then
			self.timeText.text = xyd.secondsToString(self:getRetTime())
		end

		self.askReqNum = 0
	end

	if self.roundEndTime ~= self.activityData.detail.round_end_time then
		self:initData()
	end
end

function ActivitySuperHeroClub:getTimeStr(time)
	local s = time % 60
	local m = math.floor((time - s) / 60) % 60
	local h = math.floor(time / 3600)
	local str = tostring(h) .. ":"

	if m < 10 then
		str = tostring(str) .. "0"
	end

	str = tostring(str) .. tostring(m) .. ":"

	if s < 10 then
		str = tostring(str) .. "0"
	end

	str = tostring(str) .. tostring(s)

	return str
end

function ActivitySuperHeroClub:getRetTime()
	return self.roundEndTime - xyd:getServerTime()
end

function ActivitySuperHeroClub:dispose()
	self.timer_:Stop()
	ActivitySuperHeroClub.super.dispose(self)
end

function ActivitySuperHeroClub:initData()
	if self.activityData == nil then
		return
	end

	self.roundEndTime = self.activityData.detail.round_end_time
	self.nowRound = self.activityData.detail.round_id
	local ids = xyd.tables.activityPartnerJackpotTable:getPartnerIds(self.nowRound)
	local scale = xyd.tables.activityPartnerJackpotTable:getPartnerScale(self.nowRound)
	local xy = xyd.tables.activityPartnerJackpotTable:getPartnerXY(self.nowRound)
	local firstImg = -1
	local datas = {}

	for id, _ in pairs(ids) do
		local itemData = {
			not_show_ways = true,
			num = 0,
			itemID = ids[id]
		}

		table.insert(datas, itemData)

		if firstImg < 0 then
			firstImg = ids[id]
		end
	end

	self.wrapContent:setInfos(datas, {})

	local res_prefix = "Textures/partner_picture_web/"

	xyd.setUITextureAsync(self.heroImg, res_prefix .. "partner_picture_" .. tostring(firstImg), function ()
		self.heroImg:MakePixelPerfect()
		self.heroImg:SetLocalScale(scale[1], scale[2], 1)
		self.heroImg:SetLocalPosition(xy[1], xy[2], 0)
	end)
end

local BaseComponent = import("app.components.BaseComponent")
local ActivitySuperHeroClubPreItem = class("ActivitySuperHeroClubPreItem", BaseComponent)

function ActivitySuperHeroClubPreItem:ctor(parentGo, id, index)
	ActivitySuperHeroClubPreItem.super.ctor(self, parentGo)

	self.ifMove = false
	self.skinName = "ActivitySuperHeroClubPreItemSkin"
	self.roundNum = index
	self.itemIndex = math.abs(id)
	local ids = xyd.tables.activityPartnerJackpotTable:get():getPartnerIds(self.itemIndex)
	self.height = 68 + math.ceil(#ids / 5) * 104 + (math.ceil(#ids / 5) - 1) * 17

	self:getUIComponent()
	self:initUIComponent()
	self:initIcons()
end

function ActivitySuperHeroClubPreItem:getUIComponent()
	local go = self.go
	self.go_uiPanel = go:GetComponent(typeof(UIPanel))
	self.img = go:ComponentByName("img", typeof(UITexture))
	self.img_widget = go:ComponentByName("img", typeof(UIWidget))
	self.typeIcon = go:ComponentByName("typeIcon", typeof(UITexture))
	self.typeName = go:ComponentByName("typeName", typeof(UILabel))
	self.roundDes = go:ComponentByName("roundDes", typeof(UILabel))
	self.hero_item = go:NodeByName("hero_item").gameObject
	self.iconsNode = go:NodeByName("iconsNode").gameObject
end

function ActivitySuperHeroClubPreItem:initUIComponent()
	local res_prefix = "Textures/activity_web/super_hero_club/"

	xyd.setUITextureAsync(self.img, res_prefix .. "super_hero_club_pre_item_bg", function ()
	end)
	xyd.setUITextureAsync(self.typeIcon, res_prefix .. "super_hero_club_type_" .. tostring(self.itemIndex), function ()
	end)

	self.typeName.text = xyd.tables.activityPartnerJackpotTextTable:getDesc(self.itemIndex)
	self.roundDes.text = __("ACTIVITY_PARTNER_JACKPOT_POOL0" .. tostring(self.roundNum))
end

function ActivitySuperHeroClubPreItem:getPrefabPath()
	return "Prefabs/Windows/activity/super_hero_club_item"
end

function ActivitySuperHeroClubPreItem:initIcons()
	local ids = xyd.tables.activityPartnerJackpotTable:getPartnerIds(self.itemIndex)
	local imgHeight = 68 + math.ceil(#ids / 5) * 104 + (math.ceil(#ids / 5) - 1) * 17

	self.img_widget:SetRect(0, 0, 636, imgHeight)

	self.img_widget.transform.localPosition = Vector3(0, 0, 0)

	self.go_uiPanel:SetRect(self.go.transform.localPosition.x, -(imgHeight + 29 - 200) / 2.1, 636, imgHeight + 29)

	local datas = {}

	for id, _ in pairs(ids) do
		local littleGroupIcon = NGUITools.AddChild(self.iconsNode, self.hero_item)
		local groupIcon = littleGroupIcon:NodeByName("groupIcon").gameObject
		local imgBg = littleGroupIcon:NodeByName("imgBg")
		local labelTime = littleGroupIcon:NodeByName("labelTime")
		local imgReward = littleGroupIcon:NodeByName("imgReward").gameObject

		imgBg:SetActive(false)
		labelTime:SetActive(false)
		imgReward:SetActive(false)
		NGUITools.DestroyChildren(groupIcon.transform)

		local hero_icon = xyd.getItemIcon({
			not_show_ways = true,
			uiRoot = groupIcon,
			itemID = ids[id]
		})

		hero_icon:setDragScrollView()
		self.iconsNode:SetLocalPosition(-241, -107, 0)
	end
end

function ActivitySuperHeroClubPreItem:createChildren()
	ActivitySuperHeroClubPreItem.____super.createChildren(self)
	self:initIcons()
end

function ActivitySuperHeroClub:getPreItem()
	return ActivitySuperHeroClubPreItem
end

return ActivitySuperHeroClub
