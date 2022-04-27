local BaseWindow = import(".BaseWindow")
local DatesWindow = class("DatesWindow", BaseWindow)
local DatesWindowItem = class("DatesWindowItem", import("app.common.ui.FixedMultiWrapContentItem"))
local DatesSoundButton = class("DatesSoundButton", import("app.common.ui.FixedWrapContentItem"))
local PartnerNameTag = import("app.components.PartnerNameTag")
local ParnterImg = import("app.components.PartnerImg")
local PartnerTable = xyd.tables.partnerTable
local MiscTable = xyd.tables.miscTable
local PartnerAchievementTable = xyd.tables.partnerAchievementTable
local SoundManager = xyd.SoundManager.get()
local DatesTable = xyd.tables.datesTable

function DatesWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.slideXY = {
		x = 0,
		y = 0
	}
	self.SLIDEHEIGHT = 807
	self.loveEffect = {}
	self.timeouts = {}
	self.enterType = params.enterType or 0
	local partnerID = self:checkEnter() or params.partner_id
	self.slot = xyd.models.slot
	self.achievement = xyd.models.achievement
	self.backpack = xyd.models.backpack
	self.partner = self.slot:getPartner(partnerID)
	self.tableID = self.partner:getTableID()
	self.voiceBtns = {}
	self.chosenGroup = params.chosenGroup
	self.isNoBack = params.no_back
	self.isBackToBackpack = params.isBackToBackpack
	self.item_id = params.item_id

	if params.sort_key then
		local list = {}
		local options = self.slot:getSortedPartners()[params.sort_key]

		for i = 1, #options do
			local partner = self.slot:getPartner(options[i])

			if partner and not PartnerTable:checkPuppetPartner(partner:getTableID()) then
				table.insert(list, options[i])
			end
		end

		self.currentSortedPartners = list
	else
		self.currentSortedPartners = {
			partnerID
		}
	end

	self.currentIdx = xyd.arrayIndexOf(self.currentSortedPartners, partnerID)
end

function DatesWindow:checkEnter()
	if self.enterType == xyd.DatesEnterType.LOVE_POINT_MAX then
		local sortedPartners = xyd.models.slot:getSortedPartners()[tostring(xyd.partnerSortType.LOVE_POINT) .. "_0"]

		return sortedPartners[1]
	end

	return false
end

function DatesWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initTopGroup()
	self:initLayout()
	self:registerEvent()
	self:initData()
	self:setPledgeLayout()

	if self.slot:isRequireMaxLovePoint(self.tableID, self.partner) then
		self.slot:reqMaxLovePoint(self.tableID)
	end
end

function DatesWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupBg = winTrans:ComponentByName("groupBg", typeof(UISprite))
	self.groupBgTex = winTrans:ComponentByName("groupBgTex", typeof(UITexture))
	self.groupImg = winTrans:NodeByName("groupImg").gameObject
	local top = winTrans:NodeByName("top").gameObject
	self.tabGift = top:NodeByName("tabGift").gameObject
	self.tabVoice = top:NodeByName("tabVoice").gameObject
	self.btnHelp = top:NodeByName("btnHelp").gameObject
	local bottom = winTrans:NodeByName("bottom").gameObject
	self.bubble = winTrans:NodeByName("bubble").gameObject
	self.tips = self.bubble:ComponentByName("tips", typeof(UILabel))
	self.bubbleBg = self.bubble:ComponentByName("bubbleBg", typeof(UISprite))
	self.groupName = top:NodeByName("groupName").gameObject
	self.cvInfoGroup = top:NodeByName("cvInfoGroup").gameObject
	self.cvNameLabel = self.cvInfoGroup:ComponentByName("cvNameLabel", typeof(UILabel))
	self.btns = bottom:NodeByName("btns").gameObject
	self.btnComment = self.btns:NodeByName("btnComment").gameObject
	self.btnData = self.btns:NodeByName("btnData").gameObject
	self.btnDates = self.btns:NodeByName("btnDates").gameObject
	self.content = winTrans:NodeByName("content").gameObject
	self.groupGifts = self.content:NodeByName("groupGifts").gameObject
	self.giftTop = self.groupGifts:NodeByName("giftTop").gameObject
	self.imgloveIcon = self.giftTop:ComponentByName("imgloveIcon", typeof(UISprite))
	self.labelLovePoint = self.imgloveIcon:ComponentByName("labelLovePoint", typeof(UILabel))
	self.groupPledgeEffect = self.giftTop:ComponentByName("groupPledgeEffect", typeof(UISprite))
	self.groupUpEffect = self.giftTop:ComponentByName("groupUpEffect", typeof(UISprite))
	self.labelText01 = self.giftTop:ComponentByName("labelText01", typeof(UILabel))
	self.labelTabGift = self.tabGift:ComponentByName("unSelected/labelTabGift", typeof(UILabel))
	self.labelTabVoice = self.tabVoice:ComponentByName("unSelected/labelTabVoice", typeof(UILabel))
	self.textImgGift = self.tabGift:ComponentByName("selected/textImgGift", typeof(UISprite))
	self.textImgVoice = self.tabVoice:ComponentByName("selected/textImgVoice", typeof(UISprite))
	local giftBtns = self.groupGifts:NodeByName("giftBtns").gameObject
	self.btnGiftbag = giftBtns:NodeByName("btnGiftbag").gameObject
	self.btnGiftbagNumLabel = self.btnGiftbag:ComponentByName("icon/label", typeof(UILabel))
	self.btnGift = giftBtns:NodeByName("btnGift").gameObject
	self.dataRedMark = self.btnData:NodeByName("redpoint").gameObject
	self.btnDataLabel = self.btnData:ComponentByName("button_label", typeof(UILabel))
	self.storyRedMark = self.btnDates:NodeByName("redpoint").gameObject
	self.mainAni = winTrans:GetComponent(typeof(UnityEngine.Animation))
	self.mainAniEvent = winTrans:GetComponent(typeof(LuaAnimationEvent))
	local scrollView = self.groupGifts:ComponentByName("scroller", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("dataGroupItems", typeof(MultiRowWrapContent))
	local item = scrollView:NodeByName("item").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(scrollView, wrapContent, item, DatesWindowItem, self)
	self.groupVoice = self.content:NodeByName("groupVoice").gameObject
	local scrollerVoice = self.groupVoice:ComponentByName("scrollerVoice", typeof(UIScrollView))
	local wrapContentVoice = scrollerVoice:ComponentByName("voiceList", typeof(UIWrapContent))
	local itemVoice = scrollerVoice:NodeByName("item").gameObject
	self.voiceWrapContent_ = require("app.common.ui.FixedWrapContent").new(scrollerVoice, wrapContentVoice, itemVoice, DatesSoundButton, self)

	for i = 1, 5 do
		self["imgLove" .. i] = self.giftTop:ComponentByName("groupGiftLove/img" .. i, typeof(UISprite))
		self["imgLovePoint" .. i] = self.giftTop:ComponentByName("groupGiftLove/img" .. i .. "/imgLovePoint" .. i, typeof(UISprite))
	end

	self.partnerNameTag = PartnerNameTag.new(self.groupName, true)
	self.partnerImg = ParnterImg.new(self.groupImg)
end

function DatesWindow:initData()
	local data = self.achievement:getPartnerAchievement(self.partner:getTableID())

	if MiscTable:getNumber("love_point_max_base", "value") <= self.partner:getLovePoint() and data and PartnerAchievementTable:getLastID(data.table_id) == 0 and data.is_complete and data.is_reward == 0 and (data.table_id > 35 or data.table_id < 26) then
		self:partnerStory()
	end
end

function DatesWindow:registerEvent()
	UIEventListener.Get(self.btnData).onClick = function ()
		xyd.WindowManager.get():openWindow("dates_data_window", {
			tableID = self.partner:getTableID(),
			partner_id = self.partner:getPartnerID()
		}, function ()
			self:updateRedMark2()
		end)
	end

	UIEventListener.Get(self.btnDates).onClick = function ()
		local tableID = self.partner:getTableID()
		local ids = PartnerTable:getAchievementIDs(tableID)

		if #ids == 0 then
			return xyd.showToast(__("DATES_TEXT17"))
		end

		self.isOpenWindow = true

		self.achievement:loadPartnerAchievement()
	end

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager.get():openWindow("img_guide_window", {
			wndname = "dates_window",
			type = 2
		})
	end

	UIEventListener.Get(self.tabVoice).onClick = function ()
		self:updateTap(2)
		self:setVoiceDisplay()
		self:initVoiceDisplay()
		SoundManager:playSound(xyd.SoundID.TAB)
	end

	UIEventListener.Get(self.tabGift).onClick = function ()
		self:updateTap(1)
		self:setGiftsDisplay()
		SoundManager:playSound(xyd.SoundID.TAB)
	end

	UIEventListener.Get(self.btnGift).onClick = function ()
		xyd.WindowManager.get():openWindow("dates_gifts_window")
	end

	UIEventListener.Get(self.groupImg).onClick = function ()
		self:onTouchShake()
		self:onclickPartnerImg()
	end

	UIEventListener.Get(self.imgloveIcon.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("dates_pledge_window", {
			canReplayPledgeAnimation = true,
			is_date = true,
			partner_id = self.partner:getPartnerID()
		})
	end

	UIEventListener.Get(self.btnGiftbag).onClick = function ()
		local num = self.backpack:getItemNumByID(xyd.ItemID.DATES_GIFTBAG)

		if num > 0 then
			local params = {
				itemID = xyd.ItemID.DATES_GIFTBAG,
				itemNum = num,
				wndType = xyd.ItemTipsWndType.BACKPACK
			}

			xyd.WindowManager.get():openWindow("item_tips_window", params)
		else
			xyd.showToast(__("DATES_TEXT22"))
		end
	end

	UIEventListener.Get(self.btnComment).onClick = function ()
		xyd.WindowManager.get():openWindow("partner_data_station_window", {
			curId = 2,
			partner_table_id = self.partner:getTableID(),
			table_id = self.partner:getCommentID()
		})
		xyd.models.partnerDataStation:reqTouchId(2)
	end

	UIEventListener.Get(self.groupImg).onDragStart = function ()
		self:onTouchBegin()
	end

	UIEventListener.Get(self.groupImg).onDrag = function (go, delta)
		self:onTouchMove(delta)
	end

	UIEventListener.Get(self.groupImg).onDragEnd = function (go)
		self:onTouchEnd()
	end

	function self.mainAniEvent.callback(eventName)
		if eventName == "openComplete" then
			self:setWndComplete()
		end
	end

	self.eventProxy_:addEventListener(xyd.event.SEND_GIFT, handler(self, self.onSendGifts))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemsChange))
	self.eventProxy_:addEventListener(xyd.event.LOAD_PARTNER_ACHIEVEMENT, handler(self, self.onPartnerAchievement))
	self.eventProxy_:addEventListener(xyd.event.COMPLETE_PARTNER_ACHIEVEMENT, handler(self, self.updateRedMark))
	self.eventProxy_:addEventListener(xyd.event.VOW, handler(self, self.onPartnerVow))
	self.eventProxy_:addEventListener(xyd.event.GET_MAX_LOVE_POINT, handler(self, self.updateFavoriteItem))
end

function DatesWindow:updateTap(index)
	if self.curTapIndex_ == index then
		return
	end

	self.curTapIndex_ = index
	local giftSelect = self.tabGift:NodeByName("selected").gameObject
	local giftUnSelect = self.tabGift:NodeByName("unSelected").gameObject
	local voiceSelect = self.tabVoice:NodeByName("selected").gameObject
	local voiceUnSelect = self.tabVoice:NodeByName("unSelected").gameObject
	local flag = true

	if index == 2 then
		flag = false
	end

	giftSelect:SetActive(flag)
	giftUnSelect:SetActive(not flag)
	voiceSelect:SetActive(not flag)
	voiceUnSelect:SetActive(flag)
	xyd.setTouchEnable(self.tabGift, not flag)
	xyd.setTouchEnable(self.tabVoice, flag)
end

function DatesWindow:initTopGroup()
	self.windowTop = require("app.components.WindowTop").new(self.window_, self.name_, 11, true, function ()
		if self.isNoBack then
			xyd.closeWindow(self.name_)

			local win_ = xyd.getWindow("partner_detail_window")

			if win_ then
				win_:updateLoveIcon()
			end
		elseif self.enterType == xyd.DatesEnterType.LOVE_POINT_MAX then
			xyd.WindowManager.get():closeWindow(self.name_)
		else
			xyd.WindowManager.get():openWindow("dates_list_window", {
				chosenGroup = self.chosenGroup,
				isBackToBackpack = self.isBackToBackpack,
				item_id = self.item_id
			}, function ()
				xyd.WindowManager.get():closeWindow(self.name_)
			end)
		end
	end)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function DatesWindow:initLayout()
	self.labelText01.text = __("DATES_TEXT01")
	self.labelTabGift.text = __("DATES_TEXT03")
	self.labelTabVoice.text = __("DATES_TEXT04")

	xyd.setBtnLabel(self.btnGift, {
		text = __("DATES_TEXT02")
	})
	xyd.setUISpriteAsync(self.textImgGift, nil, "dates_text04_" .. xyd.lang, function ()
		self.textImgGift:MakePixelPerfect()
	end)
	xyd.setUISpriteAsync(self.textImgVoice, nil, "dates_text05_" .. xyd.lang, function ()
		self.textImgVoice:MakePixelPerfect()
	end)
	xyd.setBtnLabel(self.btnData, {
		text = __("DATES_TEXT05")
	})
	xyd.setBtnLabel(self.btnDates, {
		text = __("DATES_TEXT06")
	})
	xyd.setBtnLabel(self.btnComment, {
		text = __("DATES_TEXT21")
	})

	if xyd.Global.lang == "fr_fr" then
		self.btnComment:ComponentByName("button_label", typeof(UILabel)).width = 100

		self.btnComment:ComponentByName("button_label", typeof(UILabel)):X(30)
	end

	if xyd.Global.lang == "de_de" then
		self.btnComment:ComponentByName("button_label", typeof(UILabel)):X(30)
	end

	if xyd.Global.lang == "zh_tw" then
		self.btnComment:ComponentByName("button_label", typeof(UILabel)):X(25)
	end

	xyd.setBtnLabel(self.btnGiftbag, {
		text = __("OPEN")
	})

	self.btnGiftbag:ComponentByName("icon/label", typeof(UILabel)).text = self.backpack:getItemNumByID(xyd.ItemID.DATES_GIFTBAG)

	self:updateNormal()
	self:initGiftsDisplay()
	self:initVoiceDisplay()
	self:setGiftsDisplay()
	self:updateRedMark()

	if self.isBackToBackpack then
		local item_id = self.item_id
		local item_num = xyd.models.backpack:getItemNumByID(self.item_id)

		if item_num > 0 then
			if self:isMaxLovePoint() then
				xyd.showToast(__("DATES_TEXT19"))
			else
				xyd.WindowManager.get():openWindow("dates_gifts_send_window", {
					item_id = item_id,
					item_num = item_num
				})
			end
		end
	end

	if xyd.Global.lang == "ja_jp" then
		self.btnDataLabel.height = 48
	end
end

function DatesWindow:updateNormal()
	self.labelLovePoint.text = math.floor(self.partner:getLovePoint() / 100)
	local max = xyd.checkCondition(self.partner:isVowed(), MiscTable:getNumber("love_point_max_grow", "value"), MiscTable:getNumber("love_point_max_base", "value"))
	local lovePoint = max <= self.partner:getLovePoint() and 100 or self.partner:getLovePoint() % 100

	for i = 1, 5 do
		self["imgLovePoint" .. i]:SetActive(lovePoint >= i * 20)
	end

	local ids = PartnerTable:getAchievementIDs(self.partner:getTableID())

	self.btnDates:SetActive(#ids > 0)

	local name = self.partner:getCVName()

	if name ~= "undefined" and name and name ~= "" then
		self.cvInfoGroup:SetActive(true)

		local cvLabel = self.cvInfoGroup:ComponentByName("cvLabel", typeof(UILabel))
		self.cvNameLabel.text = __("CV") .. name

		if xyd.Global.lang == "fr_fr" then
			self.cvNameLabel.text = __("CV") .. " " .. name
		end
	else
		self.cvInfoGroup:SetActive(false)
	end

	self.partnerNameTag:setInfo(self.partner)

	local icon = ""

	if self.partner:isVowed() then
		icon = MiscTable:getVal("love_point_icon_vow")
	else
		icon = DatesTable:getIcon(self.partner:getLovePoint())
	end

	xyd.setUISpriteAsync(self.imgloveIcon, nil, icon)
end

function DatesWindow:setVoiceDisplay()
	self.groupVoice:SetActive(true)
	self.groupGifts:SetActive(false)
end

function DatesWindow:setGiftsDisplay()
	self.groupGifts:SetActive(true)
	self.groupVoice:SetActive(false)
end

function DatesWindow:initVoiceDisplay()
	local tableID = self.partner:getTableID()
	local skinID = self.partner:getSkinID()
	local soundList = PartnerTable:getDialogList(tonumber(tableID))
	local skinIndex = PartnerTable:getSkinIndex(tableID, skinID)
	local data = {}
	local typeList = {}
	local lovePointIndex = 0

	for i = 1, #soundList do
		local id = soundList[i]
		local isSkin = false
		local exchangeSoundID = xyd.tables.partnerDialogTable:getSkinSound(id, skinIndex)

		if skinIndex and tonumber(skinIndex) > 0 and exchangeSoundID and tonumber(exchangeSoundID) > 0 then
			id = exchangeSoundID
			isSkin = true
		end

		if id and tonumber(id) > 0 then
			local soundID = xyd.tables.partnerDialogTable:getSoundTableId(id)
			local type_ = xyd.tables.partnerDialogTable:getSoundType(id)

			if not typeList[type_] then
				typeList[type_] = 1
			else
				typeList[type_] = typeList[type_] + 1
			end

			if type_ == xyd.PartnerToSoundTableKey.love_point_sound then
				lovePointIndex = lovePointIndex + 1
			end

			local dialog = xyd.tables.partnerDialogTextTable:getText(soundID)

			if soundID and soundID ~= "" and tonumber(dialog) ~= -1 then
				local params = {
					sound = soundID,
					wnd = self,
					index = i,
					label = xyd.tables.partnerDialogTypeTextTable:getText(type_, typeList[type_]),
					isSkin = isSkin
				}

				if type_ == xyd.PartnerToSoundTableKey.vow_sound then
					if self.partner:isVowed() then
						table.insert(data, params)
					end
				elseif type_ == xyd.PartnerToSoundTableKey.love_point_sound then
					local unLockPoint = MiscTable:split2num("partner_data_lev", "value", "|")
					local maxLovePoint = self.slot:getMaxLovePoint(self.tableID)

					if maxLovePoint and unLockPoint[lovePointIndex] <= maxLovePoint then
						table.insert(data, params)
					end
				else
					table.insert(data, params)
				end
			end
		end
	end

	dump(data)
	self.voiceWrapContent_:setInfos(data, {})
end

function DatesWindow:onClickVoiceBtn(btn, soundID)
	if self.currentSoundBtn then
		self.currentSoundBtn:stopSound()
	end

	self.currentSoundBtn = btn

	self:playDialog(soundID)
end

function DatesWindow:initGiftsDisplay(isUpdate)
	local giftIDs = MiscTable:split2num("love_gift_item_num", "value", "|")
	local datas = {}

	for i = 1, giftIDs[2] do
		local itemID = giftIDs[1] + i - 1
		local num = self.backpack:getItemNumByID(itemID)

		if num > 0 then
			local data = {
				itemID = itemID,
				num = num,
				isLove = self:checkIsFavorite(itemID)
			}

			table.insert(datas, data)
		end
	end

	local params = {}

	if isUpdate then
		params.keepPosition = true
	end

	self.multiWrap_:setInfos(datas, params)
end

function DatesWindow:checkIsFavorite(itemId)
	local loveGiftList = PartnerTable:getGiftsLike(self.tableID)
	local unLockPoint = MiscTable:split2num("partner_data_lev", "value", "|")[1]
	local maxLovePoint = self.slot:getMaxLovePoint(self.tableID)

	if maxLovePoint == nil or maxLovePoint < unLockPoint then
		return false
	end

	for i = 1, #loveGiftList do
		if itemId == loveGiftList[i] then
			return true
		end
	end

	return false
end

function DatesWindow:updateFavoriteItem(event)
	self:initGiftsDisplay(true)
	self:updateRedMark2()
end

function DatesWindow:playDialog(soundID)
	if self.timer then
		XYDCo.StopWait(self.timer)

		self.timer = nil
	end

	if self.isPlaySound then
		SoundManager:stopSound(self.currentDialog.sound)

		self.isPlaySound = false
	end

	self.bubble:SetActive(true)

	local dialog = xyd.tables.partnerDialogTextTable:getText(soundID)
	self.isPlaySound = true
	self.tips.text = dialog
	self.currentDialog = {
		sound = soundID,
		dialog = dialog
	}
end

function DatesWindow:playGiftsDialog(type)
	if self.timer then
		XYDCo.StopWait(self.timer)

		self.timer = nil
	end

	if self.isPlaySound and self.currentDialog then
		SoundManager:stopSound(self.currentDialog.sound)

		self.isPlaySound = false
	end

	local tableID = self.partner:getTableID()
	local dialog = PartnerTable:getGiftDialog(tableID, type, self.partner:getSkinID())
	local str = dialog.dialog
	self.isPlaySound = true
	self.tips.text = str

	self.bubble:SetActive(true)
	SoundManager:playSound(dialog.sound)

	self.currentDialog = dialog

	if DEBUG then
		print("==========> play send gift sound: " .. tostring(dialog.sound))
	end

	self.timer = "play_sound_time_key" .. type

	self:waitForTime(dialog.time, function ()
		self.isPlaySound = false

		self.bubble:SetActive(false)
	end, self.timer)
end

function DatesWindow:stopDialog(index)
	self.isPlaySound = false

	self.bubble:SetActive(false)
end

function DatesWindow:nextPartner()
	if self.currentIdx >= #self.currentSortedPartners then
		return
	end

	self.currentIdx = self.currentIdx + 1
	local partnerID = self.currentSortedPartners[self.currentIdx]
	self.partner = self.slot:getPartner(partnerID)
	local data = self.achievement:getPartnerAchievement(self.partner:getTableID())

	self:initData()

	self.tableID = self.partner:getTableID()

	self:onSwitchPartner()
	self.slot:reqMaxLovePoint(self.tableID)
end

function DatesWindow:lastPartner()
	if self.currentIdx <= 1 then
		return
	end

	self.currentIdx = self.currentIdx - 1
	local partnerID = self.currentSortedPartners[self.currentIdx]
	self.partner = self.slot:getPartner(partnerID)
	self.tableID = self.partner:getTableID()

	self:initData()
	self:onSwitchPartner()
	self.slot:reqMaxLovePoint(self.tableID)
end

function DatesWindow:updateLayout()
	self:updateNormal()
	self:initVoiceDisplay()
	self:updateRedMark()
	self:setPledgeLayout()
	self:initGiftsDisplay(true)
end

function DatesWindow:onSwitchPartner()
	if self.timer then
		XYDCo.StopWait(self.timer)

		self.timer = nil
	end

	for i = 1, #self.timeouts do
		XYDCo.StopWait(self.timeouts[i])
	end

	self.timeouts = {}

	if self.loveUpEffect then
		self.loveUpEffect:stop()
		self.loveUpEffect:SetActive(false)
	end

	for i = 1, 5 do
		if self.loveEffect[i] then
			self.loveEffect[i]:stop()
			self.loveEffect[i]:SetActive(false)
		end
	end

	if self.currentSoundBtn then
		self.currentSoundBtn:stopSound()

		self.currentSoundBtn = nil
	end

	if self.currentDialog and self.currentDialog.sound then
		SoundManager:stopSound(self.currentDialog.sound)
	end

	self.isPlaySound = false

	self.bubble:SetActive(false)
	self:onclickPartnerImg()
	self:updateLayout()
	self:updateBg()
	self:playSwitchAnimation()
	SoundManager:playSound(xyd.SoundID.SWITCH_PAGE)
end

function DatesWindow:playSwitchAnimation()
	self.mainAni:Play("switchAni")
end

function DatesWindow:playOpenAnimation(callback)
	self:onclickPartnerImg()
	self.bubble:SetActive(false)
	self:updateBg()
	self.mainAni:Play("openAni")
	callback()
end

function DatesWindow:updateBg(voice)
	if voice == nil then
		voice = true
	end

	local res = "college_scene" .. self.partner:getGroup()

	if self.curBgPath_ ~= res then
		self.curBgPath_ = res

		xyd.setUISpriteAsync(self.groupBg, nil, "college_scene" .. self.partner:getGroup() .. "_mini")
		xyd.setUITextureByNameAsync(self.groupBgTex, res, false)
	end

	local showID = self.partner:getShowID()
	showID = showID or self.partner:getTableID()

	if self.partnerImg:getItemID() == showID then
		return
	end

	self.lockBubbleVisible = true

	if self.pMoveSequence then
		self.pMoveSequence:Kill()

		self.pMoveSequence = nil
	end

	if self.gClickSequence then
		self.gClickSequence:Kill()

		self.gClickSequence = nil
	end

	self.partnerImg:setImg()
	self.partnerImg:setImg({
		showResLoading = true,
		windowName = self.name,
		itemID = showID
	}, function ()
		self:waitForTime(0.3, function ()
			self.lockBubbleVisible = false

			if not self.window_ or tolua.isnull(self.window_) then
				return
			end

			if voice then
				self:onclickPartnerImg()
				self:bigPicMove()
			end
		end, "play_click_voice")
	end)

	local xy = xyd.tables.partnerPictureTable:getPartnerPicXY(showID)
	local scale = xyd.tables.partnerPictureTable:getPartnerPicScale(showID)

	self.partnerImg:SetLocalPosition(xy.x - 120, -xy.y, 0)
	self.partnerImg:SetLocalScale(scale * 0.9, scale * 0.9, 1)
end

function DatesWindow:willClose()
	BaseWindow.willClose(self)
	self:partnerStopMove()

	local wnd = xyd.WindowManager.get():getWindow("res_loading_window")

	if wnd then
		xyd.WindowManager.get():closeWindow("res_loading_window")
	end

	if self.currentDialog and self.currentDialog.sound then
		SoundManager:stopSound(self.currentDialog.sound)
	end

	if self.timer then
		XYDCo.StopWait(self.timer)

		self.timer = nil
	end
end

function DatesWindow:sendDatesGifts(itemID, itemNum)
	local max = MiscTable:getNumber("love_point_max_grow", "value")

	if max <= self.partner:getLovePoint() then
		xyd.showToast(__("DATES_TEXT19"))

		return
	end

	self.backpack:sendDatesGifts(itemID, itemNum, self.partner:getPartnerID())
end

function DatesWindow:isMaxLovePoint()
	local max0 = MiscTable:getNumber("love_point_max_base", "value")
	local max1 = MiscTable:getNumber("love_point_max_grow", "value")

	if self.partner:isVowed() then
		return max1 <= self.partner:getLovePoint()
	else
		return max0 <= self.partner:getLovePoint()
	end
end

function DatesWindow:onSendGifts(event)
	local data = event.data
	local partner_id = data.partner_id

	PartnerTable:getGiftsLike(self.partner:getTableID())

	local likes = PartnerTable:getGiftsLike(self.partner:getTableID())
	local disLikes = PartnerTable:getGiftsDislike(self.partner:getTableID())
	local itemID = data.item_id
	local index1 = xyd.arrayIndexOf(likes, itemID)
	local index2 = xyd.arrayIndexOf(disLikes, itemID)
	local delta = 0
	local points = MiscTable:split2num("love_gift_point", "value", "|")

	if index1 > -1 then
		delta = points[3] * data.item_num
	elseif index2 > -1 then
		delta = points[1] * data.item_num
	else
		delta = points[2] * data.item_num
	end

	if index2 <= -1 then
		local effect = xyd.Spine.new(self.groupUpEffect.gameObject)

		effect:setInfo("givepresent", function ()
			effect:SetLocalPosition(0.68, 0.68, 1)
			effect:SetLocalPosition(-200, 0, 0)
			effect:play("texiao01", 1, 1, function ()
				effect:destroy()
			end)
		end)
	end

	if MiscTable:getNumber("love_point_max_base", "value") <= self.partner:getLovePoint() or index1 > -1 then
		self:partnerStory()
	end

	self:initEffect()
	self:playLoveEffect(delta)

	if index1 > -1 then
		self:playGiftsDialog(3)

		return
	end

	if index2 > -1 then
		self:playGiftsDialog(1)

		return
	end

	self:playGiftsDialog(2)

	local win2 = xyd.WindowManager.get():getWindow("partner_detail_window")

	if not win2 then
		xyd.models.slot:sortPartners()
	else
		xyd.models.slot:setNeedSort(true)
	end

	self:updateFavoriteItem()
end

function DatesWindow:initEffect()
	if self.loveUpEffect then
		return
	end

	for i = 1, 5 do
		local effect = xyd.Spine.new(self["imgLove" .. i].gameObject)

		effect:setInfo("love_point_heart", function ()
			effect:setRenderTarget(self["imgLove" .. i], 1)
		end)

		self.loveEffect[i] = effect
	end

	self.loveUpEffect = xyd.Spine.new(self.groupUpEffect.gameObject)

	self.loveUpEffect:setInfo("love_point_up")
end

function DatesWindow:getMaxPoint()
	local max = xyd.checkCondition(self.partner:isVowed(), MiscTable:getNumber("love_point_max_grow", "value"), MiscTable:getNumber("love_point_max_base", "value"))

	return max
end

function DatesWindow:playLoveEffect(delta)
	local before = self.partner:getLovePoint() - delta
	local start = math.floor(before % 100 / 20) + 1
	local end__ = math.floor(self.partner:getLovePoint() % 100 / 20)
	local start_i = {}
	local end_i = {}

	if self.partner:getLovePoint() / 100 >= math.floor(before / 100) + 1 then
		for i = start, 5 do
			table.insert(start_i, i)
		end

		for i = 1, end__ do
			table.insert(end_i, i)
		end
	else
		for i = start, end__ do
			table.insert(start_i, i)
		end
	end

	local max = self:getMaxPoint()

	for j = 1, #start_i do
		local i = start_i[j]

		local function callback()
			self.loveEffect[i]:SetActive(true)

			local function callback2()
				self.loveEffect[i]:SetActive(false)
				self["imgLovePoint" .. tostring(i)]:SetActive(true)

				if i == 5 then
					self.loveUpEffect:SetActive(true)

					local function callback3()
						self:setPledgeLayout()
						self.loveUpEffect:SetActive(false)

						local lovePath = ""

						if self.partner:isVowed() then
							lovePath = MiscTable:getVal("love_point_icon_vow")
						else
							lovePath = DatesTable:getIcon(self.partner:getLovePoint())
						end

						xyd.setUISpriteAsync(self.imgloveIcon, nil, lovePath)

						self.labelLovePoint.text = math.floor(self.partner:getLovePoint() / 100)

						if max <= self.partner:getLovePoint() then
							for t = 1, 5 do
								self["imgLovePoint" .. tostring(t)]:SetActive(true)
							end
						else
							for m = 1, 5 do
								self["imgLovePoint" .. m]:SetActive(false)
							end

							for x = 1, #end_i do
								local y = end_i[x]
								local t3 = "dates_love_effect_t3" .. y

								self:waitForTime(0.3 * x, function ()
									self.loveEffect[y]:SetActive(true)
									self.loveEffect[y]:play("texiao01", 1, 1, function ()
										self.loveEffect[y]:SetActive(false)
										self["imgLovePoint" .. y]:SetActive(true)
									end, true)
								end, t3)
								table.insert(self.timeouts, t3)
							end
						end
					end

					self.loveUpEffect:play("texiao01", 1, 1, callback3, true)
				end
			end

			self.loveEffect[i]:play("texiao01", 1, 1, callback2, true)
		end

		local t2 = "dates_love_effect" .. i

		self:waitForTime(0.3 * j, callback, t2)
		table.insert(self.timeouts, t2)
	end
end

function DatesWindow:onItemsChange(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	local datas = event.data.items
	local isUpdateItems = false

	for i = 1, #datas do
		local data = datas[i]

		if xyd.tables.itemTable:getType(data.item_id) == xyd.ItemType.DATES_GIFT then
			isUpdateItems = true
		elseif data.item_id == xyd.ItemID.DATES_GIFTBAG then
			self.btnGiftbagNumLabel.text = self.backpack:getItemNumByID(xyd.ItemID.DATES_GIFTBAG)
		end
	end

	if isUpdateItems then
		self:initGiftsDisplay(true)
	end
end

function DatesWindow:onItems(event)
	local items = event.data.items

	if #items > 0 then
		xyd.alertItems(items)
	end
end

function DatesWindow:onclickPartnerImg()
	if self.groupVoice.activeSelf then
		return
	end

	if self.bubble.activeSelf then
		return
	end

	if self.isPlaySound then
		return
	end

	if self.lockBubbleVisible then
		return
	end

	if self.timer then
		XYDCo.StopWait(self.timer)

		self.timer = nil
	end

	self.bubble:SetActive(true)

	local clickSoundNum = xyd.tables.partnerTable:getClickSoundNum(self.tableID, self.partner:getSkinId())
	local rand = math.floor(math.random() * clickSoundNum + 0.5) + 1
	local index = xyd.checkCondition(clickSoundNum < rand, rand - clickSoundNum, rand)
	local dialogInfo = PartnerTable:getClickDialogInfo(self.tableID, index, self.partner:getSkinId(), self.partner:getLovePoint())
	self.isPlaySound = true
	self.tips.text = dialogInfo.dialog

	SoundManager:playSound(dialogInfo.sound)

	if not dialogInfo.time then
		dialogInfo.time = 5
	end

	self.timer = "play_sound_time_key" .. index

	self:waitForTime(dialogInfo.time, function ()
		self.isPlaySound = false

		self.bubble:SetActive(false)
	end, self.timer)

	self.currentDialog = dialogInfo
end

function DatesWindow:onTouchShake()
	if self.isGroupShake then
		return
	end

	self.isGroupShake = true

	if self.gClickSequence then
		self.gClickSequence:Pause()
		self.gClickSequence:Kill()

		self.gClickSequence = nil
	end

	local transform = self.groupImg.transform
	local posY = transform.localPosition.y
	self.gClickSequence = DG.Tweening.DOTween.Sequence():OnComplete(function ()
		self.isGroupShake = false
	end)

	self.gClickSequence:Append(transform:DOLocalMoveY(posY + 10, 0.1)):Append(transform:DOLocalMoveY(posY - 10, 0.1)):Append(transform:DOLocalMoveY(posY, 0.1))
end

function DatesWindow:bigPicMove()
	local showID = self.partner:getShowID()
	showID = showID or self.partner:getTableID()

	if xyd.tables.partnerPictureTable:getDragonBone(showID) > 0 then
		return
	end

	if not self.pMoveSequence then
		local transform = self.partnerImg:getGameObject().transform
		local posY = transform.localPosition.y - 10
		self.pMoveSequence = DG.Tweening.DOTween.Sequence()

		self.pMoveSequence:SetLoops(-1)
		self.pMoveSequence:Append(transform:DOLocalMoveY(posY - 10, 3)):Append(transform:DOLocalMoveY(posY + 10, 3))
	end

	if not self.bubbleAction then
		local transform = self.bubble.transform
		local posY = transform.localPosition.y - 10
		self.bubbleAction = DG.Tweening.DOTween.Sequence()

		self.bubbleAction:SetLoops(-1)
		self.bubbleAction:Append(transform:DOLocalMoveY(posY - 10, 3)):Append(transform:DOLocalMoveY(posY + 10, 3))
	end
end

function DatesWindow:partnerStopMove()
	if self.pMoveSequence then
		self.pMoveSequence:Pause()
		self.pMoveSequence:Kill()

		self.pMoveSequence = nil
	end

	if self.bubbleAction then
		self.bubbleAction:Pause()
		self.bubbleAction:Kill()

		self.bubbleAction = nil
	end

	if self.gClickSequence then
		self.gClickSequence:Pause()
		self.gClickSequence:Kill()

		self.gClickSequence = nil
	end
end

function DatesWindow:onPartnerAchievement()
	if not self.isOpenWindow then
		self:updateRedMark()

		return
	end

	self.isOpenWindow = false
	local tableID = self.partner:getTableID()
	local ids = PartnerTable:getAchievementIDs(tableID)
	local data = self.achievement:getPartnerAchievement(tableID)

	if #ids == 0 then
		return xyd.showToast(__("DATES_TEXT17"))
	end

	if data.table_id == ids[1] and data.is_reward == 0 then
		return xyd.showToast(__("DATES_TEXT16"))
	end

	xyd.WindowManager.get():closeWindow("res_loading_window")
	xyd.WindowManager.get():openWindow("dates_story_window", {
		tableID = self.partner:getTableID()
	})
	self:stopAllSounds()
	self:updateRedMark()
end

function DatesWindow:updateRedMark()
	local data = self.achievement:getPartnerAchievement(self.partner:getTableID())
	local ids = PartnerTable:getAchievementIDs(self.partner:getTableID())
	local isRed = #ids > 0 and data and PartnerAchievementTable:getLastID(data.table_id) ~= 0 and data.is_complete and not data.is_reward

	self.storyRedMark:SetActive(isRed)
	self:updateRedMark2()
end

function DatesWindow:updateRedMark2()
	local isRed2 = false
	local maxLovePoint = xyd.models.slot:getMaxLovePoint(self.tableID) or 0
	local dataIDs = xyd.tables.partnerTable:getDataID(self.tableID)
	local key = xyd.tables.partnerTable:getShowIds(self.tableID)[1]
	local lastIndex = xyd.db.misc:getValue("partner_data_unlock_point_index" .. key) or 0
	lastIndex = tonumber(lastIndex)

	if lastIndex < 4 then
		local limits = xyd.tables.miscTable:split2num("partner_data_lev", "value", "|")

		for i = lastIndex + 1, #limits do
			if limits[i] <= maxLovePoint and dataIDs[i] then
				isRed2 = true

				break
			end
		end
	end

	self.dataRedMark:SetActive(isRed2)
end

function DatesWindow:onTouchBegin(event)
	self.isPartnerImgClick = true
end

function DatesWindow:onTouchMove(delta)
	self.slideXY = {
		x = self.slideXY.x + delta.x,
		y = self.slideXY.y + delta.y
	}
end

function DatesWindow:onTouchEnd()
	if math.abs(self.slideXY.y) < math.abs(self.slideXY.x) and math.abs(self.slideXY.x) > 50 then
		self.isPartnerImgClick = false

		if self.slideXY.x < 0 and self.currentIdx < #self.currentSortedPartners then
			self:nextPartner()
		elseif self.slideXY.x > 0 and self.currentIdx > 1 then
			self:lastPartner()
		end
	end

	self.slideXY = {
		x = 0,
		y = 0
	}
end

function DatesWindow:partnerStory()
	local p = self.partner
	local tableID = p:getTableID()
	local data = self.achievement:getPartnerAchievement(tableID)

	if not data then
		return
	end

	local ids = PartnerTable:getAchievementIDs(tableID)

	if #ids == 0 then
		return
	end

	if data.table_id == ids[1] and data.is_reward == 0 then
		local plotID = PartnerAchievementTable:getPlotID(data.table_id)

		xyd.WindowManager.get():openWindow("story_window", {
			story_id = plotID,
			story_type = xyd.StoryType.PARTNER,
			achievement_id = data.table_id,
			callback = function (isSkip)
				self.achievement:completePartnerAchievement(data.table_id)
				xyd.WindowManager.get():openWindow("dates_story_window", {
					tableID = tableID
				})
			end
		})
	end
end

function DatesWindow:onPartnerVow(event)
	local data = event.data.partner_info

	if data.partner_id ~= self.partner:getPartnerID() then
		return
	end

	local max = MiscTable:getNumber("love_point_max_grow", "value")
	local lovePoint = max <= self.partner:getLovePoint() and 100 or self.partner:getLovePoint() % 100

	for i = 1, 5 do
		self["imgLovePoint" .. tostring(i)]:SetActive(lovePoint >= i * 20)
	end

	xyd.setUISpriteAsync(self.imgloveIcon, nil, MiscTable:getVal("love_point_icon_vow"))
	self:stopAllSounds()
	self:setPledgeLayout()
end

function DatesWindow:stopAllSounds()
	if self.currentSoundBtn then
		self.currentSoundBtn:stopSound()

		self.currentSoundBtn = nil
	end

	if self.currentDialog and self.currentDialog.sound then
		SoundManager:stopSound(self.currentDialog.sound)
	end

	self.isPlaySound = false

	self.bubble:SetActive(false)

	if self.timer then
		XYDCo.StopWait(self.timer)

		self.timer = nil
	end
end

function DatesWindow:setPledgeLayout()
	if not self.partner:isVowed() and MiscTable:getNumber("love_point_max_base", "value") <= self.partner:getLovePoint() then
		if not self.dbPledge or not self.dbPledge:isValid() then
			self.dbPledge = xyd.Spine.new(self.groupPledgeEffect.gameObject)

			self.dbPledge:setInfo("love_point_vow", function ()
				self.dbPledge:play("texiao01", 0)
				self.groupPledgeEffect:SetActive(true)
			end)
		else
			self.dbPledge:play("texiao01", 0)
			self.groupPledgeEffect:SetActive(true)
		end
	else
		if self.dbPledge then
			self.dbPledge:stop()
		end

		self.groupPledgeEffect:SetActive(false)
	end
end

local SoundTable = xyd.tables.soundTable

function DatesSoundButton:ctor(go, parent)
	DatesSoundButton.super.ctor(self, go, parent)
end

function DatesSoundButton:initUI()
	self.label_ = self.go:ComponentByName("button_label", typeof(UILabel))
	self.bg_ = self.go:ComponentByName("bg", typeof(UISprite))

	for i = 1, 4 do
		self["icon" .. i] = self.go:NodeByName("icon" .. i).gameObject
	end
end

function DatesSoundButton:registerEvent()
	UIEventListener.Get(self.go).onClick = function ()
		if self.wnd_ then
			self.wnd_:onClickVoiceBtn(self, self.playSoundID)
		end

		self:onTAP()
	end
end

function DatesSoundButton:updateInfo()
	self.wnd_ = self.data.wnd
	self.playSoundID = self.data.sound
	self.index = self.data.index
	self.isSkin = self.data.isSkin
	self.label_.text = self.data.label

	if self.isSkin then
		xyd.setUISpriteAsync(self.bg_, nil, "dates_voice_btn_pink")
		self.icon4.gameObject:SetActive(true)
	else
		xyd.setUISpriteAsync(self.bg_, nil, "prop_btn_mid")
		self.icon4.gameObject:SetActive(false)
	end
end

function DatesSoundButton:dispose()
	self:stopSound()
end

function DatesSoundButton:reset(sound, index)
	self:stopSound()

	self.visible = true
	self.playSoundID = sound
	self.index = index
	self.includeInLayout = true
end

function DatesSoundButton:hide()
	self.visible = false
	self.includeInLayout = false

	self:stopSound()
end

function DatesSoundButton:onTAP()
	if self.isPlaying then
		return
	end

	self.displayIndex = 3
	self.isPlaying = true
	local asset = SoundTable:getRes(self.playSoundID)

	if asset == "" then
		xyd.showToast(__("DATES_SOUND_TIPS"))

		return
	else
		SoundManager:playSound(self.playSoundID)
	end

	local length = SoundTable:getLength(self.playSoundID)

	if length > 0 then
		self.interval = Timer.New(handler(self, self.displayHandler), 1, length)

		self.interval:Start()

		self.timer = "dates_single_voice"

		XYDCo.WaitForTime(length, function ()
			if self.interval ~= nil then
				self.interval:Stop()
			end

			self.interval = nil

			self.icon1:SetActive(true)
			self.icon2:SetActive(true)
			self.icon3:SetActive(true)
			self.wnd_:stopDialog(self.index)

			self.isPlaying = false
			self.timer = nil
		end, self.timer)
	end
end

function DatesSoundButton:displayHandler()
	if self.displayIndex >= 3 then
		self.displayIndex = 0
	end

	self.displayIndex = self.displayIndex + 1

	self.icon1:SetActive(true)
	self.icon2:SetActive(self.displayIndex >= 2)
	self.icon3:SetActive(self.displayIndex >= 3)
end

function DatesSoundButton:stopSound()
	if self.interval ~= nil then
		self.interval:Stop()

		self.interval = nil

		self.icon1:SetActive(true)
		self.icon2:SetActive(true)
		self.icon3:SetActive(true)
	end

	if self.isPlaying then
		SoundManager:stopSound(self.playSoundID)

		self.isPlaying = false

		XYDCo.StopWait(self.timer)

		if self.wnd then
			self.wnd:stopDialog(self.index)
		end

		self.timer = nil
	end
end

local ItemIcon = import("app.components.ItemIcon")

function DatesWindowItem:ctor(go, parent)
	DatesWindowItem.super.ctor(self, go, parent)
end

function DatesWindowItem:initUI()
	self.itemIcon = ItemIcon.new(self.go)
	self.fav = self.go:NodeByName("favoutite")
end

function DatesWindowItem:setDragScrollView()
	self.itemIcon:setDragScrollView(self.parent.scrollView)
end

function DatesWindowItem:updateInfo()
	local itemID = self.data.itemID
	local num = self.data.num

	self.itemIcon:setInfo({
		scale = 86 / xyd.DEFAULT_ITEM_SIZE,
		itemID = itemID,
		num = num,
		wndType = xyd.ItemTipsWndType.DATES
	})
	self.fav:SetActive(self.data.isLove)
end

return DatesWindow
