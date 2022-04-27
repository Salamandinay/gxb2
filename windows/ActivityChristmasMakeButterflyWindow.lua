local ActivityChristmasMakeButterflyWindow = class("ActivityChristmasMakeButterflyWindow", import(".BaseWindow"))
local slotModel = xyd.models.slot
local AltarItem = class("AltarItem")

function AltarItem:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.heroIcon_ = import("app.components.HeroIcon").new(self.uiRoot_)

	self.uiRoot_:SetActive(false)
end

function AltarItem:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)

	self.partnerId_ = info
	self.partner_ = slotModel:getPartner(info)
	self.tableID_ = self.partner_:getTableID()
	local params = {
		noClickSelected = true,
		tableID = self.tableID_,
		lev = self.partner_:getLevel(),
		star = self.partner_:getStar(),
		skin_id = self.partner_.skin_id,
		is_vowed = self.partner_.isVowed,
		dragScrollView = self.parent_.heroSelectScrollView_,
		callback = function ()
			local flag = self.heroIcon_.choose
			local partnerNum = slotModel:getPartnerNum()

			if not flag and #self.parent_.selectList_ >= partnerNum - 1 then
				xyd.alertTips(__("ALTAR_DECOMPOSE_TIP2"))

				return
			end

			if self.partner_:isLockFlag() == true then
				if xyd.checkLast(self.partner_) then
					xyd.showToast(__("UNLOCK_FAILED"))
				elseif xyd.checkDateLock(self.partner_) then
					xyd.showToast(__("DATE_LOCK_FAIL"))
				else
					local str = __("IF_UNLOCK_HERO_3")

					xyd.alert(xyd.AlertType.YES_NO, str, function (yes_no)
						if yes_no then
							local succeed = xyd.partnerUnlock(self.partner_)
							self.partner_ = xyd.models.slot:getPartner(self.partner_:getPartnerID())

							if succeed then
								self.heroIcon_.lock = false
							else
								xyd.showToast(__("UNLOCK_FAILED"))
							end
						end
					end)
				end

				return
			elseif xyd.tables.partnerTable:checkPuppetPartner(self.partner_:getTableID()) then
				xyd.showToast(__("POTENTIALITY_BACK_ALTAR_TIPS"))

				return
			end

			self.parent_:selectHero(info, flag, self.heroIcon_)
		end
	}

	self.heroIcon_:setInfo(params)

	self.heroIcon_.choose = self.parent_:isSelect(self.partnerId_)

	if self.partner_:isLockFlag() or xyd.tables.partnerTable:checkPuppetPartner(self.partner_:getTableID()) then
		self.heroIcon_:setLock(true)
	else
		self.heroIcon_:setLockImgVisible(false)
	end
end

function AltarItem:getHeroIcon()
	return self.heroIcon_
end

function AltarItem:getPartnerId()
	return self.partnerId_
end

function AltarItem:getGameObject()
	return self.uiRoot_
end

function ActivityChristmasMakeButterflyWindow:ctor(name, params)
	ActivityChristmasMakeButterflyWindow.super.ctor(self, name, params)

	self.chooseStar_ = 0
	self.chooseGroup_ = 0
	self.selectList_ = {}
	self.selectPartnerID_ = {}
	self.partnerDatas = {}
end

function ActivityChristmasMakeButterflyWindow:initWindow()
	ActivityChristmasMakeButterflyWindow.super.initWindow()

	self.sortPartner_ = xyd.models.slot:getPartnersByStar()

	self:getUIComponent()
	self:initChoosePart()
	self:updateDataGroup()
	self.heroSelectScrollView_:ResetPosition()
	self:updateText()
	self:updateItemNum()
	self:register()
end

function ActivityChristmasMakeButterflyWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.winTitle_ = winTrans:ComponentByName("winTitle", typeof(UILabel))
	self.detailBtn_ = winTrans:NodeByName("detailBtn").gameObject
	self.costNum_ = winTrans:ComponentByName("costGroup/costNum", typeof(UILabel))
	local heroGroup = winTrans:NodeByName("heroGroup").gameObject
	local partnerNumDesc = heroGroup:ComponentByName("labelDesc", typeof(UILabel))
	self.partnerNumLabel_ = heroGroup:ComponentByName("labelNum", typeof(UILabel))
	self.chooseBtn = winTrans:ComponentByName("heroGroup/chooseBtn", typeof(UISprite))
	local chooseBtnLabel = winTrans:ComponentByName("heroGroup/chooseBtn/btnTitle", typeof(UILabel))
	self.chooseBtnTap_ = winTrans:ComponentByName("heroGroup/chooseBtn/tap", typeof(UISprite))
	self.choosePart_ = winTrans:NodeByName("heroGroup/topSeletPart").gameObject
	local heroRoot = heroGroup:NodeByName("heroRoot").gameObject
	self.heroWarpContent_ = heroGroup:ComponentByName("scrollView/grid", typeof(MultiRowWrapContent))
	self.heroSelectScrollView_ = heroGroup:ComponentByName("scrollView", typeof(UIScrollView))
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.heroSelectScrollView_, self.heroWarpContent_, heroRoot, AltarItem, self)
	self.btnMake_ = winTrans:NodeByName("btnMake").gameObject
	self.btnMakeLabel_ = winTrans:ComponentByName("btnMake/label", typeof(UILabel))
	self.btnSmart_ = winTrans:NodeByName("btnSmart").gameObject
	self.btnSmartLabel_ = winTrans:ComponentByName("btnSmart/label", typeof(UILabel))

	if self.showSortPart_ then
		self.chooseBtnTap_.transform.localScale = Vector3(1, 1, 1)
		self.choosePart_.transform.localScale = Vector3(1, 1, 1)
	else
		self.chooseBtnTap_.transform.localScale = Vector3(1, -1, 1)
		self.choosePart_.transform.localScale = Vector3(1, 0, 1)
	end

	partnerNumDesc.text = __("ALTAR_HERO_NUM_TEXT")
	chooseBtnLabel.text = __("ALTAR_FILTER_TEXT")
	self.winTitle_.text = __("ACTIVITY_DOLL_MAKE_TITLE")
	self.btnMakeLabel_.text = __("ACTIVITY_DOLL_SELECT")
	self.btnSmartLabel_.text = __("ACTIVITY_DOLL_MAKE_BUTTON")

	self.partnerNumLabel_:X(partnerNumDesc.width + 9 + partnerNumDesc:X())
end

function ActivityChristmasMakeButterflyWindow:updateItemNum()
	self.costNum_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.DUMMY_BUTTERFLY)
end

function ActivityChristmasMakeButterflyWindow:register()
	ActivityChristmasMakeButterflyWindow.super.register(self)

	UIEventListener.Get(self.chooseBtn.gameObject).onClick = function ()
		if self.showSortPart_ then
			self.showSortPart_ = nil
		else
			self.showSortPart_ = true
		end

		if self.showSortPart_ then
			self.chooseBtnTap_.transform.localScale = Vector3(1, 1, 1)
			self.choosePart_.transform.localScale = Vector3(1, 1, 1)
		else
			self.chooseBtnTap_.transform.localScale = Vector3(1, -1, 1)
			self.choosePart_.transform.localScale = Vector3(1, 0, 1)
		end
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.detailBtn_).onClick = handler(self, self.onClickBtnDatail)
	UIEventListener.Get(self.btnMake_).onClick = handler(self, self.onClickBtnMake)
	UIEventListener.Get(self.btnSmart_).onClick = handler(self, self.onClickBtnSmart)

	self.eventProxy_:addEventListener(xyd.event.ACTIVITY_CHRISTMAS_EXCHANGE, handler(self, self.onExchange))
end

function ActivityChristmasMakeButterflyWindow:onClickBtnDatail()
	local num = 0

	for i = 1, #self.selectList_ do
		local partnerInfo = xyd.models.slot:getPartner(self.selectList_[i])
		local award = xyd.tables.miscTable:split2Cost("activity_doll_" .. partnerInfo.star, "value", "#")
		num = num + award[2]
	end

	if num ~= 0 then
		xyd.alertItems({
			{
				item_id = xyd.ItemID.DUMMY_BUTTERFLY,
				item_num = num
			}
		}, nil, __("ALTAR_PREVIEW_TEXT"))
	else
		xyd.alertItems({}, nil, __("ALTAR_PREVIEW_TEXT"))
	end
end

function ActivityChristmasMakeButterflyWindow:initChoosePart()
	self.starBgList_ = {}
	self.groupBgList_ = {}
	local gridOfGroup = self.choosePart_.transform:ComponentByName("gridOfGroup", typeof(UIGrid))
	local gridOfStar = self.choosePart_.transform:ComponentByName("gridOfStar", typeof(UIGrid))
	local tempGroup = self.choosePart_.transform:ComponentByName("itemGroup", typeof(UISprite))
	local tempStar = self.choosePart_.transform:Find("itemStar")
	local maskBg = self.choosePart_.transform:ComponentByName("maskBg", typeof(UIWidget))

	tempStar.gameObject:SetActive(false)
	tempGroup.gameObject:SetActive(false)

	for i = 1, 3 do
		local starItem = NGUITools.AddChild(gridOfStar.gameObject, tempStar.gameObject)

		starItem.gameObject:SetActive(true)

		local starIcon = starItem.transform:ComponentByName("btnIcon", typeof(UISprite))

		xyd.setUISpriteAsync(starIcon, nil, "star0" .. i + 2, nil, )

		local starBg = starItem.transform:ComponentByName("btnBg", typeof(UISprite))

		table.insert(self.starBgList_, starBg)

		if xyd.isIosTest() then
			xyd.setUISpriteAsync(starIcon, nil, "star0" .. i .. "_ios_test", nil, )
			xyd.setUISpriteAsync(starItem:ComponentByName("bg", typeof(UISprite)), nil, "star_bg_ios_test")

			starItem:ComponentByName("bg", typeof(UISprite)).depth = 11
		end

		starBg.gameObject:SetActive(self.chooseStar_ == i + 2)

		UIEventListener.Get(starIcon.gameObject).onClick = function ()
			if self.chooseStar_ ~= i + 2 then
				self.chooseStar_ = i + 2
			else
				self.chooseStar_ = 0
			end

			self:updateSort()
			self:updateDataGroup()
		end
	end

	gridOfStar:Reposition()

	for i = 1, 6 do
		local itemGroup = NGUITools.AddChild(gridOfGroup.gameObject, tempGroup.gameObject)

		itemGroup:SetActive(true)

		local iconGroup = itemGroup.transform:ComponentByName("groupIcon", typeof(UISprite))

		xyd.setUISpriteAsync(iconGroup, nil, "img_group" .. i, nil, )

		if xyd.isIosTest() then
			xyd.setUISpriteAsync(iconGroup, nil, "img_group" .. i .. "_ios_test", nil, )
		end

		local selectBg = itemGroup.transform:ComponentByName("groupChosen", typeof(UISprite))

		selectBg.gameObject:SetActive(false)

		UIEventListener.Get(iconGroup.gameObject).onClick = function ()
			if self.chooseGroup_ ~= i then
				self.chooseGroup_ = i
			else
				self.chooseGroup_ = 0
			end

			self:updateSort()
			self:updateDataGroup()
		end

		table.insert(self.groupBgList_, selectBg)
	end

	gridOfGroup:Reposition()

	UIEventListener.Get(maskBg.gameObject).onClick = function ()
		self.showSortPart_ = nil
		self.chooseBtnTap_.transform.localScale = Vector3(1, -1, 1)
		self.choosePart_.transform.localScale = Vector3(1, 0, 1)
	end
end

function ActivityChristmasMakeButterflyWindow:onExchange()
	self:updateText()
	xyd.models.slot:delPartners(self.selectList_)

	self.selectList_ = {}

	self:updateDataGroup()
	self:updateItemNum()
end

function ActivityChristmasMakeButterflyWindow:updateSort()
	for idx, bg in ipairs(self.groupBgList_) do
		bg.gameObject:SetActive(self.chooseGroup_ == idx)
	end

	for idx, bg in ipairs(self.starBgList_) do
		bg.gameObject:SetActive(self.chooseStar_ == idx + 2)
	end
end

function ActivityChristmasMakeButterflyWindow:selectHero(partnerID, iconChoose, heroIcon)
	local index = xyd.arrayIndexOf(self.selectList_, partnerID)

	if not iconChoose and index < 0 then
		heroIcon.choose = true
		self.selectPartnerID_[partnerID] = true

		table.insert(self.selectList_, partnerID)
	elseif iconChoose and index > 0 then
		heroIcon.choose = false
		self.selectPartnerID_[partnerID] = false

		table.remove(self.selectList_, index)
	else
		self.selectPartnerID_[partnerID] = false
		heroIcon.choose = false
	end

	self:updateText()
end

function ActivityChristmasMakeButterflyWindow:isSelect(partnerID)
	return self.selectPartnerID_[partnerID]
end

function ActivityChristmasMakeButterflyWindow:updateDataGroup()
	local key = self.chooseStar_ .. "_" .. self.chooseGroup_
	self.partnerDatas = self:updateOptionalList(key)

	self.multiWrap_:setInfos(self.partnerDatas, {})
end

function ActivityChristmasMakeButterflyWindow:updateOptionalList(key)
	local partnerData = self.sortPartner_[key]
	local returnData = {}

	for _, partnerID in ipairs(partnerData) do
		local partnerInfo = xyd.models.slot:getPartner(partnerID)

		if partnerInfo.star > 2 then
			if partnerInfo.star > 5 then
				-- Nothing
			elseif partnerInfo.lev ~= 1 then
				-- Nothing
			elseif not xyd.tables.partnerTable:checkPuppetPartner(partnerInfo:getTableID()) then
				table.insert(returnData, partnerID)
			end
		end
	end

	return returnData
end

function ActivityChristmasMakeButterflyWindow:onClickBtnMake()
	if self.selectList_ and #self.selectList_ >= 1 then
		local tips = "ACTIVITY_FACTORY_TIPS2"

		if self:hasOver3Star() then
			tips = "ACTIVITY_DOLL_EXCHANGE_TIPS_HIGHSTAR"
		end

		xyd.alert(xyd.AlertType.YES_NO, __(tips), function (yes)
			if yes then
				local msg = messages_pb.activity_christmas_exchange_req()
				msg.activity_id = xyd.ActivityID.EXCHANGE_DUMMY

				for _, partnerID in ipairs(self.selectList_) do
					table.insert(msg.partner_ids, partnerID)
				end

				xyd.Backend.get():request(xyd.mid.ACTIVITY_CHRISTMAS_EXCHANGE, msg)
			end
		end)
	else
		xyd.alertTips(__("SHENXUE_NOT_SELECT_YET"))
	end
end

function ActivityChristmasMakeButterflyWindow:hasOver3Star()
	local flag = false

	for _, partnerID in ipairs(self.selectList_) do
		if self:checkStar(partnerID, 3) then
			flag = true

			break
		end
	end

	return flag
end

function ActivityChristmasMakeButterflyWindow:onClickBtnSmart()
	local maxNum = self:getMaxSmartNum()

	if maxNum == 0 then
		return
	end

	local function confirmCallBack(num)
		if num > 0 then
			local selectNum = 0

			for _, partnerID in ipairs(self.partnerDatas) do
				if slotModel:getPartnerNum() <= selectNum then
					break
				end

				if selectNum < num and selectNum < maxNum and not self:isSelect(partnerID) and not slotModel:getPartner(partnerID):isLockFlag() and not self:checkStar(partnerID, 3) then
					table.insert(self.selectList_, partnerID)

					self.selectPartnerID_[partnerID] = true
					selectNum = selectNum + 1
				elseif num <= selectNum or maxNum <= selectNum then
					break
				end
			end

			self:updateText()
			self.multiWrap_:setInfos(self.partnerDatas, {
				keepPosition = true
			})
		end
	end

	xyd.WindowManager.get():openWindow("ice_summer_gacha_window", {
		num = maxNum,
		callback = confirmCallBack
	})
end

function ActivityChristmasMakeButterflyWindow:getMaxSmartNum()
	local hasSelectNum = 0

	for _, partnerID in ipairs(self.partnerDatas) do
		if self.selectPartnerID_[partnerID] or self:checkStar(partnerID, 3) then
			hasSelectNum = hasSelectNum + 1
		elseif slotModel:getPartner(partnerID):isLockFlag() then
			hasSelectNum = hasSelectNum + 1
		end
	end

	if slotModel:getPartnerNum() <= #self.partnerDatas then
		return #self.partnerDatas - 1 - hasSelectNum
	else
		return #self.partnerDatas - hasSelectNum
	end
end

function ActivityChristmasMakeButterflyWindow:checkStar(partnerID, star)
	local partner = slotModel:getPartner(partnerID)

	if partner and star < partner:getStar() then
		return true
	end

	return false
end

function ActivityChristmasMakeButterflyWindow:updateText()
	self.partnerNumLabel_.text = slotModel:getPartnerNum() - #self.selectList_ .. "/" .. slotModel:getSlotNum()
end

return ActivityChristmasMakeButterflyWindow
