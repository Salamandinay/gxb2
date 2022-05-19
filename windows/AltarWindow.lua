local BaseWindow = import(".BaseWindow")
local AltarWindow = class("AltarWindow", BaseWindow)
local CommonTabBar = import("app.common.ui.CommonTabBar")
local slotModel = xyd.models.slot
local OldSize = {
	w = 720,
	h = 1280
}
local MaxSelected = 12
local AltarItem = class("AltarItem")

function AltarItem:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.heroIcon_ = import("app.components.HeroIcon").new(self.uiRoot_)
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
		is_vowed = self.partner_.is_vowed,
		dragScrollView = self.parent_.heroSelectScrollView_,
		callback = function ()
			local flag = self.heroIcon_.choose
			local partnerNum = slotModel:getPartnerNum()

			if not flag and #self.parent_.selPartnerIDs_ >= partnerNum - 1 then
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
				xyd.showToast(__("POTENTIALITY_BACK_ALTAR_TIP"))

				return
			elseif self.partner_:getGroup() == xyd.PartnerGroup.TIANYI then
				xyd.showToast(__("GROUP_ALTAR_NO_TIPS", __("GROUP_" .. xyd.PartnerGroup.TIANYI)))

				return
			end

			self.parent_:selectHero(info, flag, self.heroIcon_)
		end
	}

	self.heroIcon_:setInfo(params)

	self.heroIcon_.choose = self.parent_:isSelect(self.partnerId_)

	if self.partner_:isLockFlag() or xyd.tables.partnerTable:checkPuppetPartner(self.partner_:getTableID()) or self.partner_:getGroup() == xyd.PartnerGroup.TIANYI then
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

function AltarItem:setShowActive(canShow)
	self.uiRoot_.gameObject:SetActive(canShow)
end

function AltarItem:refresh()
	for _, data in ipairs(self.parent_.selPartnerIDs_) do
		local partnerID = data.partnerID

		if partnerID and self.partneId_ == partnerID then
			self.heroIcon_.choose = true
		end
	end
end

function AltarItem:getGameObject()
	return self.uiRoot_
end

local BackItem = class("BackItem")

function BackItem:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.heroIcon_ = import("app.components.HeroIcon").new(self.uiRoot_)
end

function BackItem:update(index, realIndex, info)
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
		is_vowed = self.partner_.is_vowed,
		dragScrollView = self.parent_.heroSelectScrollView_back,
		callback = function ()
			local partnerNum = slotModel:getPartnerNum()

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
				xyd.showToast(__("ALTAR_INFO_3"))

				return
			elseif self.partner_:getGroup() == xyd.PartnerGroup.TIANYI then
				xyd.showToast(__("GROUP_ALTAR_BACK_NO_TIPS", __("GROUP_" .. xyd.PartnerGroup.TIANYI)))

				return
			end

			self.parent_:selectHero_back(info, self.heroIcon_)
		end
	}

	self.heroIcon_:setInfo(params)

	if self.parent_.selectrdPartnerID_back ~= nil and self.parent_.selectrdPartnerID_back == self.partnerId_ then
		self.heroIcon_.choose = true
	else
		self.heroIcon_.choose = false
	end

	if self.partner_:isLockFlag() or xyd.tables.partnerTable:checkPuppetPartner(self.partner_:getTableID()) or self.partner_:getGroup() == xyd.PartnerGroup.TIANYI then
		self.heroIcon_:setLock(true)
	else
		self.heroIcon_:setLockImgVisible(false)
	end
end

function BackItem:getHeroIcon()
	return self.heroIcon_
end

function BackItem:getPartnerId()
	return self.partnerId_
end

function BackItem:setShowActive(canShow)
	self.uiRoot_.gameObject:SetActive(canShow)
end

function BackItem:refresh()
	if partnerID and self.parent_.selectrdPartnerID_back and self.parent_.selectrdPartnerID_back == partnerID then
		self.heroIcon_.choose = true
	end
end

function BackItem:getGameObject()
	return self.uiRoot_
end

function AltarWindow:ctor(name, params)
	AltarWindow.super.ctor(self, name, params)

	self.chooseStar_ = 0
	self.chooseGroup_ = 0
	self.selPartnerIDs_ = {}
	self.selectHeroList_ = {}
	self.hasCreatIdx_ = {}
	self.chooseStar_back = 0
	self.chooseGroup_back = 0
	self.selPartnerID_back = 0
	self.selectHero_back = nil
end

function AltarWindow:initWindow()
	AltarWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	local topPos = winTrans:ComponentByName("topPos", typeof(UIWidget))
	local helpBtn = winTrans:ComponentByName("aniPos/topBtnPos/helfBtn", typeof(UISprite))
	local shopBtn = winTrans:ComponentByName("aniPos/topBtnPos/shopBtn", typeof(UISprite))
	self.topBtnPos = winTrans:NodeByName("aniPos/topBtnPos")
	self.topTrans = winTrans:NodeByName("aniPos/topPos")
	self.heroGroup = winTrans:NodeByName("aniPos/heroGroup")
	local aniPos = winTrans:Find("aniPos").transform
	self.aniPos = aniPos
	self.nav = winTrans:NodeByName("nav").gameObject
	self.backTab = winTrans:NodeByName("backTab").gameObject
	self.previewPart = self.backTab:ComponentByName("previewPart", typeof(UISprite))
	self.previewLabel = self.previewPart:ComponentByName("previewLabel", typeof(UILabel))
	self.previewScrollView = self.previewPart:ComponentByName("scrollView", typeof(UIScrollView))
	self.previewGrid = self.previewScrollView:ComponentByName("grid", typeof(UIGrid))
	self.heroGroup_back = self.backTab:NodeByName("heroGroup").gameObject
	self.previewPart = self.backTab:NodeByName("previewPart").gameObject
	self.heroIconBg = self.previewPart:ComponentByName("bg_", typeof(UISprite))
	self.backBtn = self.previewPart:NodeByName("backBtn").gameObject
	self.backBtnNumLabel = self.backBtn:ComponentByName("icon/numLabel", typeof(UILabel))
	self.partnerNumLabel_back = self.heroGroup_back:ComponentByName("labelNum", typeof(UILabel))
	self.backBtnLabel = self.backBtn:ComponentByName("labelDesc", typeof(UILabel))
	self.previewHeroIcon = self.previewPart:NodeByName("previewHeroIcon").gameObject
	self.tabBar = CommonTabBar.new(self.nav, 2, function (index)
		self.tabIndex = index

		if index == 1 then
			self:showTab(index)
		elseif index == 2 then
			self:showTab(index)
		end
	end, nil, , 24)
	self.nav:ComponentByName("tab_1/label", typeof(UILabel)).text = __("ALTAR_TITLE")
	self.nav:ComponentByName("tab_2/label", typeof(UILabel)).text = __("POTENTIALITY_BACK_TITLE")

	self:initTopGroup(topPos)

	UIEventListener.Get(shopBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow("altar_window")
		xyd.WindowManager.get():openWindow("shop_window", {
			shopType = xyd.ShopType.SHOP_HERO,
			closeCallBack = function ()
				xyd.WindowManager.get():openWindow("altar_window", {})
			end
		})
	end

	UIEventListener.Get(helpBtn.gameObject).onClick = function ()
		if self.tabIndex == 1 then
			xyd.WindowManager.get():openWindow("help_window", {
				key = "ALTAR_WINDOW_HELP"
			})
		else
			xyd.WindowManager.get():openWindow("help_window", {
				key = "POTENTIALITY_BACK_WINDOW_HELP"
			})
		end
	end

	self:registerEvent()
end

function AltarWindow:showTab(index)
	if index == 1 then
		self:clearChooseHero(false)
		self:waitForFrame(1, function ()
			self.backTab:SetActive(false)
			self.topTrans:SetActive(true)
			self.aniPos:NodeByName("btnPos").gameObject:SetActive(true)
			self.aniPos:NodeByName("heroGroup").gameObject:SetActive(true)

			self.sortPartner_ = slotModel:getPartnersByStar()

			self:updateDataGroup()
			self.heroSelectScrollView_:ResetPosition()
			self:updateText()
		end)
	else
		self.backTab:SetActive(true)
		self.topTrans:SetActive(false)
		self.aniPos:NodeByName("btnPos").gameObject:SetActive(false)
		self.aniPos:NodeByName("heroGroup").gameObject:SetActive(false)

		if self.selectrdPartnerID_back then
			self:selectHero_back(self.selectrdPartnerID_back, self.selectedPartnerIcon_back)
		end

		self.sortPartner_back = self:getPartnersByStar()

		self:updateSort_back()
		self:updateDataGroup_back()
		self.previewScrollView:ResetPosition()
		self:updateText_back()
	end
end

function AltarWindow:playOpenAnimation(callback)
	self:initPos()
	self:initTopPart()
	self:initBottomPart()
	self:initButtonPart()
	self:initBackTab()
	self:playStarAnimation()

	if callback then
		self:setWndComplete()
		self:waitForFrame(2, function ()
			self.choosePart_.transform:Y(self.window_.transform:NodeByName("aniPos/heroGroup/chooseBtn").localPosition.y + 150)
		end)
		callback()
	end
end

function AltarWindow:initBackTab()
	local width = self.window_:GetComponent(typeof(UIPanel)).width

	if not self.previewItemIcons then
		self.previewItemIcons = {}
		local params = {
			noClick = false,
			scale = 0.8981481481481481,
			itemID = xyd.ItemID.MANA,
			dragScrollView = self.previewScrollView,
			uiRoot = self.previewGrid.gameObject
		}

		for i = 1, 10 do
			self.previewItemIcons[i] = xyd.getItemIcon(params)
		end
	end

	if not self.previewHeroIcons then
		self.previewHeroIcons = {}
		local params = {
			tableID = 561001,
			scale = 0.8981481481481481,
			uiRoot = self.previewGrid.gameObject
		}

		for i = 1, 10 do
			self.previewHeroIcons[i] = xyd.getHeroIcon(params)
		end
	end

	for i = 1, #self.previewItemIcons do
		self.previewItemIcons[i]:getIconRoot():SetActive(false)
	end

	for i = 1, #self.previewHeroIcons do
		if self.previewHeroIcons[i] ~= nil then
			self.previewHeroIcons[i]:getIconRoot():SetActive(false)
		end
	end

	UIEventListener.Get(self.backBtn.gameObject).onClick = handler(self, self.onClickBack)
	self.previewLabel.text = __("ALTAR_INFO_4")

	xyd.setUISpriteAsync(self.heroIconBg, nil, "altar_icon_hw_hui")

	local heroTrans = self.window_.transform:Find("backTab/heroGroup").transform
	local heroRoot = heroTrans:Find("heroRoot").gameObject
	local partnerNumDesc = heroTrans:ComponentByName("labelDesc", typeof(UILabel))
	self.heroWarpContent_back = heroTrans:ComponentByName("scrollView/grid", typeof(MultiRowWrapContent))
	self.heroSelectScrollView_back = heroTrans:ComponentByName("scrollView", typeof(UIScrollView))
	partnerNumDesc.text = __("ALTAR_HERO_NUM_TEXT")

	self.partnerNumLabel_back:X(partnerNumDesc.width + 9 + partnerNumDesc:X())

	self.sortPartner_back = self:getPartnersByStar()
	self.multiWrap_back = require("app.common.ui.FixedMultiWrapContent").new(self.heroSelectScrollView_back, self.heroWarpContent_back, heroRoot, BackItem, self)

	self:updateDataGroup_back()
	self:waitForFrame(1, function ()
		self.heroSelectScrollView_back:ResetPosition()
	end)
	self:updateText_back()

	self.backBtnLabel.text = __("POTENTIALITY_BACK")

	self:initFilter_back()
end

function AltarWindow:initPos()
	local width = self.window_:GetComponent(typeof(UIPanel)).width

	self.topBtnPos:X(-width / 2 - 340)
	self.topTrans:X(-width / 2 - 340)
	self.heroGroup:X(width / 2 + 340)

	local allHeight = self.window_:GetComponent(typeof(UIPanel)).height
	local heightDis = allHeight - 1280
	local dis = 178
	self.heroGroup:GetComponent(typeof(UISprite)).height = 492 + heightDis / dis * 177

	self.heroGroup:Y(-179)

	self.heroGroup_back:GetComponent(typeof(UISprite)).height = 422 + heightDis / dis * 177

	self.heroGroup_back:Y(-212)
end

function AltarWindow:playStarAnimation()
	local seq = self:getSequence()
	local yTop = self.topBtnPos.localPosition.y
	local yHeroGroup = self.heroGroup.localPosition.y

	seq:Insert(0, self.topBtnPos:DOLocalMove(Vector3(55, yTop, 0), 0.3))
	seq:Insert(0.3, self.topBtnPos:DOLocalMove(Vector3(5, yTop, 0), 0.27))
	seq:Insert(0, self.topTrans:DOLocalMove(Vector3(55, yTop, 0), 0.3))
	seq:Insert(0.3, self.topTrans:DOLocalMove(Vector3(5, yTop, 0), 0.27))
	seq:Insert(0, self.heroGroup:DOLocalMove(Vector3(-55, -179, 0), 0.3))
	seq:Insert(0.3, self.heroGroup:DOLocalMove(Vector3(5, -179, 0), 0.27))
end

function AltarWindow:CheckOldExplorePartner(partner_id)
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.EXPLORE_OLD_CAMPUS_PVE)

	if not activityData then
		return false
	end

	local partnerList = activityData.detail.used_partners

	if partnerList[tostring(partner_id)] and partnerList[tostring(partner_id)] > 0 then
		return true
	else
		return false
	end
end

function AltarWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.DECOMPOSE_PARTNERS, handler(self, self.decomposeCallback))
	self.eventProxy_:addEventListener(xyd.event.ROLLBACK_PARTNER, function (event)
		self:onGetBackMsg(event)
	end)
end

function AltarWindow:onGetBackMsg(event)
	local data = xyd.decodeProtoBuf(event.data)
	local ViwedPartnerID = nil
	local infos = {}

	for i = 1, #data.partners do
		local item = {
			item_num = 1,
			item_id = data.partners[i].table_id,
			awake = data.partners[i].awake,
			partner_id = data.partners[i].partner_id,
			is_vowed = data.partners[i].is_vowed
		}

		if data.partners[i].is_vowed == 1 then
			ViwedPartnerID = data.partners[i].table_id
		end

		table.insert(infos, item)
	end

	local tmpData = {}
	local starData = {}

	for _, item in ipairs(infos) do
		local itemID = item.item_id
		local partner = slotModel:getPartner(item.partner_id)

		if tmpData[itemID] == nil then
			tmpData[itemID] = 0
		end

		starData[itemID] = partner:getStar()
		tmpData[itemID] = tmpData[item.item_id] + item.item_num
	end

	local datas = {}

	for k, v in pairs(tmpData) do
		table.insert(datas, {
			item_id = tonumber(k),
			item_num = v,
			star = starData[k]
		})
	end

	if ViwedPartnerID ~= nil then
		local viwedPartner = {}

		for i = 1, #datas do
			if datas[i].item_id == ViwedPartnerID then
				if datas[i].item_num > 1 then
					datas[i].item_num = datas[i].item_num - 1

					table.insert(datas, {
						item_num = 1,
						is_vowed = 1,
						item_id = datas[i].item_id,
						star = datas[i].star
					})
				else
					datas[i].is_vowed = 1
				end
			end
		end
	end

	local params = {
		heroShowNum = true,
		items = datas
	}

	xyd.WindowManager.get():openWindow("alert_item_window", params)

	local realData = {}

	for i = 1, #data.items do
		if tonumber(data.items[i].item_num) > 0 then
			table.insert(realData, data.items[i])
		end
	end

	xyd.models.itemFloatModel:pushNewItems(realData)

	if self.selectrdPartner_back then
		self.selectrdPartner_back:getIconRoot():SetActive(false)
	end

	if self.selectedPartnerIcon_back then
		self.selectedPartnerIcon_back.choose = false
		self.selectedPartnerIcon_back.selected = false
	end

	self.selectrdPartnerID_back = nil
	self.sortPartner_back = self:getPartnersByStar()

	self:updateSort_back()
	self:updateDataGroup_back()
	self:resetBackTabState()
	self.previewScrollView:ResetPosition()
end

function AltarWindow:onClickBack()
	if self.selectrdPartnerID_back == nil or self.selectrdPartnerID_back == 0 then
		return
	end

	local partner = slotModel:getPartner(self.selectrdPartnerID_back)
	local star = partner:getStar()

	local function callback_1()
		xyd.alertYesNo(__("POTENTIALITY_BACK_TEXT03"), function (yes)
			if not yes then
				return
			end

			if partner:getLevel() == 1 then
				xyd.showToast(__("ALTAR_INFO_1"))

				return
			end

			local cost = xyd.tables.partnerReturnRule2Table:getCost(star)

			if cost ~= nil and cost ~= 0 then
				if cost[1] == 0 then
					-- Nothing
				elseif xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
					xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(cost[1])))

					return
				end
			end

			local can_summon = xyd.models.slot:getCanSummonNum()
			local will_summon = self.willAddHeroNum

			if can_summon < will_summon then
				xyd.openWindow("partner_slot_increase_window", {
					descText = __("POTENTIALITY_BACK_TEXT04")
				})

				return
			end

			local msg = messages_pb.rollback_partner_req()
			msg.partner_id = partner:getPartnerID()

			xyd.Backend.get():request(xyd.mid.ROLLBACK_PARTNER, msg)
		end)
	end

	local function callback_2()
		if partner:getLevel() == 1 then
			xyd.showToast(__("ALTAR_INFO_1"))

			return
		end

		local cost = xyd.tables.partnerReturnRule2Table:getCost(star)

		if cost ~= nil and cost ~= 0 then
			if cost[1] == 0 then
				-- Nothing
			elseif xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(cost[1])))

				return
			end
		end

		local can_summon = xyd.models.slot:getCanSummonNum()
		local will_summon = self.willAddHeroNum

		if can_summon < will_summon then
			xyd.openWindow("partner_slot_increase_window")

			return
		end

		local msg = messages_pb.rollback_partner_req()
		msg.partner_id = partner:getPartnerID()

		xyd.Backend.get():request(xyd.mid.ROLLBACK_PARTNER, msg)
	end

	if star <= 5 then
		if partner:isLockFlag() then
			if xyd.checkLast(partner) then
				xyd.showToast(__("UNLOCK_FAILED"))
			elseif xyd.checkDateLock(partner) then
				xyd.showToast(__("DATE_LOCK_FAIL"))
			elseif xyd.checkHouseLock(partner) then
				xyd.showToast(__("HOUSE_LOCK_FAIL"))
			else
				local timeStamp = xyd.db.misc:getValue("back_partner_time_stamp")

				if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
					xyd.WindowManager.get():openWindow("gamble_tips_window", {
						type = "back_partner",
						callback = function ()
							callback_2()
						end,
						text = __("ALTAR_INFO_2")
					})

					return
				else
					callback_2()
				end
			end

			return
		else
			local timeStamp = xyd.db.misc:getValue("back_partner_time_stamp")

			if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
				xyd.WindowManager.get():openWindow("gamble_tips_window", {
					type = "back_partner",
					callback = function ()
						callback_2()
					end,
					text = __("ALTAR_INFO_2")
				})

				return
			else
				callback_2()
			end
		end

		return
	end

	if partner:isLockFlag() then
		if xyd.checkLast(partner) then
			xyd.showToast(__("UNLOCK_FAILED"))
		elseif xyd.checkDateLock(partner) then
			xyd.showToast(__("DATE_LOCK_FAIL"))
		elseif xyd.checkHouseLock(partner) then
			xyd.showToast(__("HOUSE_LOCK_FAIL"))
		else
			local str = nil
			str = __("IF_UNLOCK_HERO_3")

			xyd.alertYesNo(str, function (yes_no)
				if yes_no then
					local succeed = xyd.partnerUnlock(partner)

					if succeed then
						callback_1()
					else
						xyd.showToast(__("UNLOCK_FAILED"))
					end
				end
			end)
		end

		return
	else
		callback_1()
	end
end

function AltarWindow:initTopGroup(topPos)
	self.windowTop = import("app.components.WindowTop").new(topPos.gameObject, self.name_)
	local items = {
		{
			hidePlus = true,
			id = xyd.ItemID.GRADE_STONE
		},
		{
			hidePlus = true,
			id = xyd.ItemID.PARTNER_EXP
		}
	}

	self.windowTop:setItem(items)
end

function AltarWindow:initTopPart()
	self.chooseHeroList_ = {}
	local topTrans = self.window_.transform:Find("aniPos/topPos").transform
	local topLable = topTrans:ComponentByName("topLable/topTitle", typeof(UILabel))
	self.chooseGrid_ = topTrans:ComponentByName("choosePart/grid", typeof(UIGrid))
	local tempItem = topTrans:ComponentByName("choosePart/tempItem", typeof(UIWidget))
	local btnDetail = topTrans:ComponentByName("choosePart/detailBtn", typeof(UISprite))

	tempItem.gameObject:SetActive(false)

	topLable.text = __("ALTAR_TITLE")
	UIEventListener.Get(btnDetail.gameObject).onClick = handler(self, self.onClickBtnDatail)

	for i = 1, MaxSelected do
		local chooseItemPart = NGUITools.AddChild(self.chooseGrid_.gameObject, tempItem.gameObject)

		chooseItemPart.gameObject:SetActive(true)

		local iconRoot = chooseItemPart.transform:ComponentByName("heroIcon", typeof(UIWidget)).gameObject
		local bg = chooseItemPart.transform:ComponentByName("nooneBg", typeof(UISprite))

		if xyd.isIosTest() then
			xyd.setUISprite(bg, nil, "icon_none_ios_test")
			chooseItemPart:NodeByName("icon_add1"):SetActive(false)
		end

		table.insert(self.chooseHeroList_, {
			flag = false,
			root = iconRoot,
			bg = bg
		})
	end

	self.chooseGrid_:Reposition()
end

function AltarWindow:initBottomPart()
	local heroTrans = self.window_.transform:Find("aniPos/heroGroup").transform
	self.heroTrans = heroTrans
	local partnerNumDesc = heroTrans:ComponentByName("labelDesc", typeof(UILabel))
	self.partnerNumLabel_ = heroTrans:ComponentByName("labelNum", typeof(UILabel))
	partnerNumDesc.text = __("ALTAR_HERO_NUM_TEXT")

	self.partnerNumLabel_:X(partnerNumDesc.width + 9 + partnerNumDesc:X())
	self:initHeroGroup()
	self:initFilter()
	self:updateText()
end

function AltarWindow:updateText()
	self.partnerNumLabel_.text = slotModel:getPartnerNum() - #self.selPartnerIDs_ .. "/" .. slotModel:getSlotNum()
end

function AltarWindow:updateText_back()
	local number = slotModel:getPartnerNum()

	if self.selectrdPartnerID_back then
		number = number - 1
	end

	self.partnerNumLabel_back.text = number .. "/" .. slotModel:getSlotNum()
end

function AltarWindow:initFilter()
	local chooseBtn = self.window_.transform:ComponentByName("aniPos/heroGroup/chooseBtn", typeof(UISprite))
	local chooseBtnLabel = self.window_.transform:ComponentByName("aniPos/heroGroup/chooseBtn/btnTitle", typeof(UILabel))
	self.chooseBtnTap_ = self.window_.transform:ComponentByName("aniPos/heroGroup/chooseBtn/tap", typeof(UISprite))
	self.choosePart_ = self.window_.transform:Find("aniPos/heroGroup/topSeletPart")
	chooseBtnLabel.text = __("ALTAR_FILTER_TEXT")

	if xyd.Global.lang == "fr_fr" then
		chooseBtnLabel.fontSize = 16
	end

	if self.showSortPart_ then
		self.chooseBtnTap_.transform.localScale = Vector3(1, 1, 1)
		self.choosePart_.transform.localScale = Vector3(1, 1, 1)
	else
		self.chooseBtnTap_.transform.localScale = Vector3(1, -1, 1)
		self.choosePart_.transform.localScale = Vector3(1, 0, 1)
	end

	self:initChoosePart()

	UIEventListener.Get(chooseBtn.gameObject).onClick = function ()
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
end

function AltarWindow:initFilter_back()
	local chooseBtn = self.window_.transform:ComponentByName("backTab/heroGroup/chooseBtn", typeof(UISprite))
	local chooseBtnLabel = self.window_.transform:ComponentByName("backTab/heroGroup/chooseBtn/btnTitle", typeof(UILabel))
	self.chooseBtnTap_back = self.window_.transform:ComponentByName("backTab/heroGroup/chooseBtn/tap", typeof(UISprite))
	self.choosePart_back = self.window_.transform:Find("backTab/heroGroup/topSeletPart")

	self.choosePart_back.transform:Y(self.choosePart_.transform.localPosition.y)

	chooseBtnLabel.text = __("ALTAR_FILTER_TEXT")

	if xyd.Global.lang == "fr_fr" then
		chooseBtnLabel.fontSize = 16
	end

	if self.showSortPart_back then
		self.chooseBtnTap_back.transform.localScale = Vector3(1, 1, 1)
		self.choosePart_back.transform.localScale = Vector3(1, 1, 1)
	else
		self.chooseBtnTap_back.transform.localScale = Vector3(1, -1, 1)
		self.choosePart_back.transform.localScale = Vector3(1, 0, 1)
	end

	self:initChoosePart_back()

	UIEventListener.Get(chooseBtn.gameObject).onClick = function ()
		if self.showSortPart_back then
			self.showSortPart_back = nil
		else
			self.showSortPart_back = true
		end

		if self.showSortPart_back then
			self.chooseBtnTap_back.transform.localScale = Vector3(1, 1, 1)
			self.choosePart_back.transform.localScale = Vector3(1, 1, 1)
		else
			self.chooseBtnTap_back.transform.localScale = Vector3(1, -1, 1)
			self.choosePart_back.transform.localScale = Vector3(1, 0, 1)
		end
	end
end

function AltarWindow:initChoosePart()
	self.starBgList_ = {}
	self.groupBgList_ = {}
	local gridOfGroup = self.choosePart_.transform:ComponentByName("gridOfGroup", typeof(UIGrid))
	local gridOfStar = self.choosePart_.transform:ComponentByName("gridOfStar", typeof(UIGrid))
	local tempGroup = self.choosePart_.transform:ComponentByName("itemGroup", typeof(UISprite))
	local tempStar = self.choosePart_.transform:Find("itemStar")
	local maskBg = self.choosePart_.transform:ComponentByName("maskBg", typeof(UIWidget))

	tempStar.gameObject:SetActive(false)
	tempGroup.gameObject:SetActive(false)

	for i = 1, 5 do
		local starItem = NGUITools.AddChild(gridOfStar.gameObject, tempStar.gameObject)

		starItem.gameObject:SetActive(true)

		local starIcon = starItem.transform:ComponentByName("btnIcon", typeof(UISprite))

		xyd.setUISpriteAsync(starIcon, nil, "star0" .. i, nil, )

		local starBg = starItem.transform:ComponentByName("btnBg", typeof(UISprite))

		table.insert(self.starBgList_, starBg)

		if xyd.isIosTest() then
			xyd.setUISpriteAsync(starIcon, nil, "star0" .. i .. "_ios_test", nil, )
			xyd.setUISpriteAsync(starItem:ComponentByName("bg", typeof(UISprite)), nil, "star_bg_ios_test")

			starItem:ComponentByName("bg", typeof(UISprite)).depth = 11
		end

		starBg.gameObject:SetActive(self.chooseStar_ == i)

		UIEventListener.Get(starIcon.gameObject).onClick = function ()
			if self.chooseStar_ ~= i then
				self.chooseStar_ = i
			else
				self.chooseStar_ = 0
			end

			self:updateSort()
			self:updateDataGroup()
		end
	end

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

	UIEventListener.Get(maskBg.gameObject).onClick = function ()
		self.showSortPart_ = nil
		self.chooseBtnTap_.transform.localScale = Vector3(1, -1, 1)
		self.choosePart_.transform.localScale = Vector3(1, 0, 1)
	end
end

function AltarWindow:initChoosePart_back()
	self.starBgList_back = {}
	self.groupBgList_back = {}
	local gridOfGroup = self.choosePart_back.transform:ComponentByName("gridOfGroup", typeof(UIGrid))
	local gridOfStar = self.choosePart_back.transform:ComponentByName("gridOfStar", typeof(UIGrid))
	local gridOfStar2 = self.choosePart_back.transform:ComponentByName("gridOfStar2", typeof(UIGrid))
	local tempGroup = self.choosePart_back.transform:ComponentByName("itemGroup", typeof(UISprite))
	local tempStar = self.choosePart_back.transform:Find("itemStar")
	local maskBg = self.choosePart_back.transform:ComponentByName("maskBg", typeof(UIWidget))

	tempStar.gameObject:SetActive(false)
	tempGroup.gameObject:SetActive(false)

	for i = 1, 10 do
		local starItem = nil

		if i <= 5 then
			starItem = NGUITools.AddChild(gridOfStar.gameObject, tempStar.gameObject)
		else
			starItem = NGUITools.AddChild(gridOfStar2.gameObject, tempStar.gameObject)
		end

		starItem.gameObject:SetActive(true)

		local starIcon = starItem.transform:ComponentByName("btnIcon", typeof(UISprite))

		if i <= 5 then
			xyd.setUISpriteAsync(starIcon, nil, "star0" .. i, nil, )
		elseif i == 6 then
			starItem.gameObject:SetActive(false)
		elseif i <= 9 then
			xyd.setUISpriteAsync(starIcon, nil, "star_red_" .. i, nil, )
		elseif i == 10 then
			xyd.setUISpriteAsync(starIcon, nil, "star_orange", nil, )
		end

		local starBg = starItem.transform:ComponentByName("btnBg", typeof(UISprite))

		table.insert(self.starBgList_back, starBg)
		starBg.gameObject:SetActive(self.chooseStar_back == i)

		UIEventListener.Get(starIcon.gameObject).onClick = function ()
			if self.chooseStar_back ~= i then
				self.chooseStar_back = i
			else
				self.chooseStar_back = 0
			end

			self:updateSort_back()
			self:updateDataGroup_back()
		end
	end

	for i = 1, 6 do
		local itemGroup = NGUITools.AddChild(gridOfGroup.gameObject, tempGroup.gameObject)

		itemGroup:SetActive(true)

		local iconGroup = itemGroup.transform:ComponentByName("groupIcon", typeof(UISprite))

		xyd.setUISpriteAsync(iconGroup, nil, "img_group" .. i, nil, )

		local selectBg = itemGroup.transform:ComponentByName("groupChosen", typeof(UISprite))

		selectBg.gameObject:SetActive(false)

		UIEventListener.Get(iconGroup.gameObject).onClick = function ()
			if self.chooseGroup_back ~= i then
				self.chooseGroup_back = i
			else
				self.chooseGroup_back = 0
			end

			self:updateSort_back()
			self:updateDataGroup_back()
		end

		table.insert(self.groupBgList_back, selectBg)
	end

	UIEventListener.Get(maskBg.gameObject).onClick = function ()
		self.showSortPart_back = nil
		self.chooseBtnTap_back.transform.localScale = Vector3(1, -1, 1)
		self.choosePart_back.transform.localScale = Vector3(1, 0, 1)
	end
end

function AltarWindow:updateSort()
	for idx, bg in ipairs(self.groupBgList_) do
		bg.gameObject:SetActive(self.chooseGroup_ == idx)
	end

	for idx, bg in ipairs(self.starBgList_) do
		bg.gameObject:SetActive(self.chooseStar_ == idx)
	end
end

function AltarWindow:updateSort_back()
	for idx, bg in ipairs(self.groupBgList_back) do
		bg.gameObject:SetActive(self.chooseGroup_back == idx)
	end

	for idx, bg in ipairs(self.starBgList_back) do
		bg.gameObject:SetActive(self.chooseStar_back == idx)
	end
end

function AltarWindow:initHeroGroup()
	local heroTrans = self.window_.transform:Find("aniPos/heroGroup").transform
	local heroRoot = heroTrans:Find("heroRoot").gameObject
	self.heroWarpContent_ = heroTrans:ComponentByName("scrollView/grid", typeof(MultiRowWrapContent))
	self.heroSelectScrollView_ = heroTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.sortPartner_ = slotModel:getPartnersByStar()
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.heroSelectScrollView_, self.heroWarpContent_, heroRoot, AltarItem, self)

	self:updateDataGroup()
	self:waitForFrame(1, function ()
		self.heroSelectScrollView_:ResetPosition()
	end)
end

function AltarWindow:updateDataGroup()
	local key = self.chooseStar_ .. "_" .. self.chooseGroup_
	local partnerData = self.sortPartner_[key]

	self.multiWrap_:setInfos(partnerData, {})
end

function AltarWindow:updateDataGroup_back()
	local key = self.chooseStar_back .. "_" .. self.chooseGroup_back
	local partnerData = self.sortPartner_back[key]

	if self.chooseStar_back == 10 then
		partnerData = {}

		for i = 10, 15 do
			key = i .. "_" .. self.chooseGroup_back
			local data = self.sortPartner_back[key]

			for j = 1, #data do
				table.insert(partnerData, data[j])
			end
		end
	end

	local realdata = {}

	for i = 1, #partnerData do
		local partnerID = partnerData[i]
		local partner = slotModel:getPartner(partnerID)
		local star = partner:getStar()
		local flag = star ~= 6
		flag = flag and not xyd.tables.partnerTable:checkPuppetPartner(partner:getTableID())
		flag = flag and partner:getLevel() ~= 1

		if flag then
			table.insert(realdata, partnerData[i])
		end
	end

	self.multiWrap_back:setInfos(realdata, {})
end

function AltarWindow:getPartnersByStar()
	local data = slotModel:getPartnersByStar()
	local partners = data["0_0"]
	local result = {}

	for key, value in pairs(data) do
		result[key] = {}

		for i = 1, #value do
			table.insert(result[key], value[i])
		end
	end

	for i = #partners, 1, -1 do
		local id = partners[i]
		local p = slotModel:getPartner(id)

		if p:isLockFlag() and p.star > 5 then
			local flag = true

			for i = 1, #result[tostring(p.star) .. "_" .. tostring(p:getGroup())] do
				if result[tostring(p.star) .. "_" .. tostring(p:getGroup())] == id then
					flag = false
				end
			end

			if flag == true then
				table.insert(result[tostring(p.star) .. "_" .. tostring(p:getGroup())], id)
				table.insert(result[tostring(p.star) .. "_0"], id)
			end
		end
	end

	return result
end

function AltarWindow:decomposeCallback(event)
	local smartWin = xyd.getWindow("smart_altar_window")

	if smartWin then
		self.sortPartner_ = slotModel:getPartnersByStar()

		self:updateDataGroup()
		self.heroSelectScrollView_:ResetPosition()
		self:clearChooseHero(false)
		self:updateText()

		return
	end

	local items = event.data.items

	if #items > 0 then
		xyd.alertItems(items)
	end

	xyd.models.advertiseComplete:achieve(xyd.ACHIEVEMENT_TYPE.DECOMPOSE_HERO, #self.selPartnerIDs_)
	self:clearChooseHero(true)

	self.sortPartner_ = slotModel:getPartnersByStar()

	self:updateDataGroup()
	self.heroSelectScrollView_:ResetPosition()
end

function AltarWindow:clearChooseHero(isDisassemble)
	for _, data in ipairs(self.selPartnerIDs_) do
		local copyIcon = data.heroIcon
		local iconRoot = copyIcon:getIconRoot()

		UnityEngine.Object.Destroy(iconRoot)

		local partnerID = data.partnerID

		if isDisassemble then
			local effect = self.hasCreatIdx_[data.idx]

			if effect then
				effect:SetActive(true)
				effect:play("texiao1", 1, 1, function ()
					effect:SetActive(false)
				end)
			end
		end

		local heroIcon = self:getHeroIconByPartnerID(partnerID)

		if heroIcon then
			heroIcon.choose = false
		end

		self.selectHeroList_[partnerID] = false
	end

	for _, data in ipairs(self.chooseHeroList_) do
		data.flag = false
		data.partnerID = nil
	end

	self.selPartnerIDs_ = {}
end

function AltarWindow:initButtonPart()
	local btnTrans = self.window_.transform:Find("aniPos/btnPos").transform
	local btnSmart = btnTrans:ComponentByName("btnSmart", typeof(UISprite))
	local btnAutoSmart = btnTrans:ComponentByName("btnAutoSmart", typeof(UISprite))
	local btnDisassemble = btnTrans:ComponentByName("btnDisassemble", typeof(UISprite))
	local labelAutoSmart = btnTrans:ComponentByName("btnAutoSmart/labelDesc", typeof(UILabel))
	local labelSmart = btnTrans:ComponentByName("btnSmart/labelDesc", typeof(UILabel))
	local labelDisassemble = btnTrans:ComponentByName("btnDisassemble/labelDesc", typeof(UILabel))
	labelSmart.text = __("ALTAR_SMART_TEXT")
	labelAutoSmart.text = __("ALTAR_AUTO_TEXT")
	labelDisassemble.text = __("ALTAR_DECOMPOSE_TEXT")
	UIEventListener.Get(btnSmart.gameObject).onClick = handler(self, self.smartPutIn)
	UIEventListener.Get(btnAutoSmart.gameObject).onClick = handler(self, self.autoSmartPutIn)
	UIEventListener.Get(btnDisassemble.gameObject).onClick = handler(self, self.sendDisassembleRequest)

	if xyd.Global.lang == "fr_fr" then
		labelAutoSmart.width = 140
	end

	self.btnDisassemble_ = btnDisassemble
end

function AltarWindow:onClickBtnDatail()
	local decomposeItems = {}
	local baseItems = {}
	local treasureItems = {}

	for _, data in ipairs(self.selPartnerIDs_) do
		local partnerID = data.partnerID
		local partner = slotModel:getPartner(partnerID)
		local res = partner:getDecompose()
		local equipItems = res[3]

		for _, v in ipairs(equipItems) do
			table.insert(decomposeItems, v)
		end

		for _, v in ipairs(res[2]) do
			table.insert(treasureItems, v)
		end

		baseItems[xyd.ItemID.PARTNER_EXP] = (baseItems[xyd.ItemID.PARTNER_EXP] or 0) + (res[1][xyd.ItemID.PARTNER_EXP] or 0)
		baseItems[xyd.ItemID.GRADE_STONE] = (baseItems[xyd.ItemID.GRADE_STONE] or 0) + (res[1][xyd.ItemID.GRADE_STONE] or 0)
		baseItems[xyd.ItemID.SOUL_STONE] = (baseItems[xyd.ItemID.SOUL_STONE] or 0) + (res[1][xyd.ItemID.SOUL_STONE] or 0)
		baseItems[xyd.ItemID.SKILL_RESONATE_LIGHT_STONE] = (baseItems[xyd.ItemID.SKILL_RESONATE_LIGHT_STONE] or 0) + (res[1][xyd.ItemID.SKILL_RESONATE_LIGHT_STONE] or 0)
		baseItems[xyd.ItemID.SKILL_RESONATE_DARK_STONE] = (baseItems[xyd.ItemID.SKILL_RESONATE_DARK_STONE] or 0) + (res[1][xyd.ItemID.SKILL_RESONATE_DARK_STONE] or 0)
	end

	for _, v in ipairs(treasureItems) do
		table.insert(decomposeItems, v)
	end

	if baseItems[xyd.ItemID.PARTNER_EXP] and baseItems[xyd.ItemID.PARTNER_EXP] > 0 then
		table.insert(decomposeItems, {
			item_id = xyd.ItemID.PARTNER_EXP,
			item_num = baseItems[xyd.ItemID.PARTNER_EXP]
		})
	end

	if baseItems[xyd.ItemID.GRADE_STONE] and baseItems[xyd.ItemID.GRADE_STONE] > 0 then
		table.insert(decomposeItems, {
			item_id = xyd.ItemID.GRADE_STONE,
			item_num = baseItems[xyd.ItemID.GRADE_STONE]
		})
	end

	if baseItems[xyd.ItemID.GRADE_STONE] and baseItems[xyd.ItemID.SOUL_STONE] > 0 then
		table.insert(decomposeItems, {
			item_id = xyd.ItemID.SOUL_STONE,
			item_num = baseItems[xyd.ItemID.SOUL_STONE]
		})
	end

	if baseItems[xyd.ItemID.SKILL_RESONATE_LIGHT_STONE] and baseItems[xyd.ItemID.SKILL_RESONATE_LIGHT_STONE] > 0 then
		table.insert(decomposeItems, {
			item_id = xyd.ItemID.SKILL_RESONATE_LIGHT_STONE,
			item_num = baseItems[xyd.ItemID.SKILL_RESONATE_LIGHT_STONE]
		})
	end

	if baseItems[xyd.ItemID.SKILL_RESONATE_DARK_STONE] and baseItems[xyd.ItemID.SKILL_RESONATE_DARK_STONE] > 0 then
		table.insert(decomposeItems, {
			item_id = xyd.ItemID.SKILL_RESONATE_DARK_STONE,
			item_num = baseItems[xyd.ItemID.SKILL_RESONATE_DARK_STONE]
		})
	end

	xyd.alertItems(decomposeItems, nil, __("ALTAR_PREVIEW_TEXT"))
end

function AltarWindow:selectHero(partnerID, iconChoose, heroIcon, smart)
	if not heroIcon then
		heroIcon = self:getHeroIconByPartnerID(partnerID)

		if heroIcon then
			iconChoose = heroIcon.choose or self.selectHeroList_[partnerID]
		else
			iconChoose = self.selectHeroList_[partnerID]
		end
	end

	if not iconChoose then
		local emptyRoot, idx = self:getEmptyGroup()

		if not emptyRoot then
			return
		else
			local function addHeroIcon()
				local partner = slotModel:getPartner(partnerID)
				local tableID = partner:getTableID()
				local copyHero = import("app.components.HeroIcon").new(emptyRoot.root)
				local effect = xyd.Spine.new(emptyRoot.root)
				local params = {
					tableID = tableID,
					star = partner:getStar(),
					is_vowed = partner.is_vowed,
					skin_id = partner.skin_id,
					callback = function ()
						if not heroIcon then
							heroIcon = self:getHeroIconByPartnerID(partnerID)
						end

						if heroIcon then
							heroIcon.choose = false
							heroIcon.selected = false
						end

						emptyRoot.flag = false
						emptyRoot.partnerID = nil

						UnityEngine.Object.Destroy(copyHero:getIconRoot())
						self:deleteSelectPartner(partnerID)

						self.selectHeroList_[partnerID] = false

						self:updateText()
					end
				}

				copyHero:setInfo(params)

				if not self.hasCreatIdx_[idx] then
					effect:setInfo("fx_ui_fenjie", function ()
						effect:SetLocalPosition(0, 0, 0)
						effect:SetLocalScale(1, 1, 1)
						effect:setRenderTarget(emptyRoot.bg, 1)
						effect:SetActive(false)
					end)

					self.hasCreatIdx_[idx] = effect
				end

				if heroIcon then
					heroIcon.choose = true
					heroIcon.selected = false
				end

				emptyRoot.flag = true
				emptyRoot.partnerID = partnerID

				table.insert(self.selPartnerIDs_, {
					partnerID = partnerID,
					heroIcon = copyHero,
					emptyRoot = emptyRoot,
					idx = idx
				})

				self.selectHeroList_[partnerID] = true
			end

			local CheckOldExplorePartner = self:CheckOldExplorePartner(partnerID)

			if CheckOldExplorePartner then
				xyd.alertYesNo(__("ACTIVITY_EXPLORE_CAMPUS_TEAM_SELL_TIPS"), function (yes_no)
					if yes_no then
						addHeroIcon()
					end
				end, nil, , , __("BATTLE_FORMATION_WIN"))
			else
				addHeroIcon()
			end
		end
	else
		if smart then
			return
		end

		for _, data in ipairs(self.chooseHeroList_) do
			if data.partnerID and data.partnerID == partnerID then
				data.partnerID = nil
				data.flag = false
			end
		end

		local copyHero = self:getCopyHeroIconByPartnerID(partnerID)

		if copyHero then
			copyHero.choose = false
			copyHero.selected = false
			heroIcon.choose = false
			heroIcon.selected = false

			UnityEngine.Object.Destroy(copyHero:getIconRoot())
		end

		self.selectHeroList_[partnerID] = false

		self:deleteSelectPartner(partnerID)
	end

	self:updateText()
end

function AltarWindow:selectHero_back(partnerID, heroIcon)
	if self.selectrdPartnerID_back ~= nil then
		if self.selectrdPartnerID_back == partnerID then
			if self.selectrdPartner_back then
				heroIcon.choose = false
				heroIcon.selected = false
				self.selectedPartnerIcon_back = nil

				self.selectrdPartner_back:getIconRoot():SetActive(false)

				self.selectrdPartnerID_back = nil
			end
		else
			local partner = slotModel:getPartner(partnerID)
			local tableID = partner:getTableID()
			local params = {
				scale = 0.9259259259259259,
				tableID = tableID,
				lev = partner:getLevel(),
				star = partner:getStar(),
				skin_id = partner.skin_id,
				is_vowed = partner.is_vowed
			}
			self.selectedPartnerIcon_back.choose = false
			self.selectedPartnerIcon_back.selected = false
			self.selectedPartnerIcon_back = heroIcon
			self.selectedPartnerIcon_back.choose = true
			self.selectedPartnerIcon_back.selected = true

			if self.selectrdPartner_back then
				self.selectrdPartner_back:getIconRoot():SetActive(true)

				function params.callback()
					self:selectHero_back(self.selectrdPartnerID_back, self.selectedPartnerIcon_back)
				end

				self.selectrdPartner_back:setInfo(params)
			end

			self.selectrdPartnerID_back = partnerID
		end
	else
		local partner = slotModel:getPartner(partnerID)
		local tableID = partner:getTableID()
		local params = {
			scale = 0.9259259259259259,
			tableID = tableID,
			lev = partner:getLevel(),
			star = partner:getStar(),
			skin_id = partner.skin_id,
			is_vowed = partner.is_vowed,
			callback = function ()
				self:selectHero_back(self.selectrdPartnerID_back, self.selectedPartnerIcon_back)
			end
		}
		self.selectedPartnerIcon_back = heroIcon
		self.selectedPartnerIcon_back.choose = true
		self.selectedPartnerIcon_back.selected = true

		if self.selectrdPartner_back then
			self.selectrdPartner_back:getIconRoot():SetActive(true)
			self.selectrdPartner_back:setInfo(params)
		else
			params.uiRoot = self.previewHeroIcon:NodeByName("heroIcon").gameObject
			self.selectrdPartner_back = xyd.getHeroIcon(params)

			self.selectrdPartner_back:getIconRoot():SetActive(true)

			params.uiRoot = nil

			self.selectrdPartner_back:setInfo(params)
		end

		self.selectrdPartnerID_back = partnerID
	end

	self:updateText_back()

	if self.selectrdPartnerID_back == nil then
		self:resetBackTabState()

		return
	end

	local partner = slotModel:getPartner(partnerID)
	local star = partner:getStar()
	local group = partner:getGroup()

	for i = 1, #self.previewItemIcons do
		self.previewItemIcons[i]:getIconRoot():SetActive(false)
	end

	for i = 1, #self.previewHeroIcons do
		if self.previewHeroIcons[i] ~= nil then
			self.previewHeroIcons[i]:getIconRoot():SetActive(false)
		end
	end

	local partners = nil
	partners, self.willAddHeroNum = xyd.tables.partnerReturnRule2Table:getReturnPartner(partnerID)

	if partners and partners[1] and partners[1].table_id then
		for i = 1, #partners do
			local params = {
				heroShowNum = true,
				scale = 0.8981481481481481,
				noClick = false,
				itemID = partners[i].table_id,
				num = partners[i].num,
				dragScrollView = self.previewScrollView,
				is_vowed = partners[i].is_vowed
			}
			local star = xyd.tables.partnerTable:getStar(partners[i].table_id)

			if star == 6 then
				local data = xyd.tables.partnerReturnRule2Table:getReturnPartnerInfo(self.selectrdPartnerID_back)

				for _, v in ipairs(data) do
					if v[1][1] and v[1][1] == partners[i].table_id and v[2][2] and v[2][2] > 0 then
						star = star + v[2][2]
					end
				end

				params.star = star
			end

			if self.previewHeroIcons[i] == nil then
				params.uiRoot = self.previewGrid.gameObject
				self.previewHeroIcons[i] = xyd.getItemIcon(params)
				params.uiRoot = nil

				function params.callback()
					self:selectHero_back(self.selectrdPartnerID_back, self.selectedPartnerIcon_back)
				end

				self.selectrdPartner_back:getIconRoot():SetActive(true)
				self.selectrdPartner_back:setInfo(params)
			else
				self.previewHeroIcons[i]:getIconRoot():SetActive(true)
				self.previewHeroIcons[i]:setInfo(params)
			end
		end
	end

	local items = {}
	local items = xyd.tables.partnerReturnRule2Table:getAllItems(partnerID)

	for i = 1, #items do
		local params = {
			scale = 0.8981481481481481,
			noClick = false,
			itemID = items[i][1],
			num = items[i][2],
			dragScrollView = self.previewScrollView
		}

		if items[i][1] == xyd.ItemID.MAGIC_DUST then
			local crystal = xyd.tables.partnerReturnRule2Table:getCrystalByPartnerID(partnerID)

			if crystal and crystal == 1 then
				params.num = math.ceil(params.num * (1 - xyd.models.dress:getBuffTypeAttr(xyd.DressBuffAttrType.CRYSTAL_KNIFE)))
			end
		end

		if self.previewItemIcons[i] == nil then
			params.uiRoot = self.previewGrid.gameObject
			self.previewItemIcons[i] = xyd.getItemIcon(params)
		else
			self.previewItemIcons[i]:getIconRoot():SetActive(true)
			self.previewItemIcons[i]:setInfo(params)
		end

		if xyd.tables.itemTable:lightEffect(items[i][1]) ~= 1 then
			self.previewItemIcons[i]:setEffect(false)
		else
			self.previewItemIcons[i]:setEffect(true)
		end
	end

	self.previewGrid:Reposition()

	if star <= 5 then
		xyd.setUISpriteAsync(self.heroIconBg, nil, "altar_icon_hw_lan")
	elseif star <= 9 then
		xyd.setUISpriteAsync(self.heroIconBg, nil, "altar_icon_hw_lv")
	elseif star <= 15 then
		xyd.setUISpriteAsync(self.heroIconBg, nil, "altar_icon_hw_huang")
	end

	local needIcon = self.backBtn:ComponentByName("icon", typeof(UISprite))
	local needIconNum = self.backBtn:ComponentByName("icon/numLabel", typeof(UILabel))
	local backBtnLabel = self.backBtn:ComponentByName("labelDesc", typeof(UILabel))
	local cost = xyd.tables.partnerReturnRule2Table:getCost(star)

	if cost == nil or cost == 0 or cost[1] == 0 then
		needIcon:SetActive(false)
		backBtnLabel:X(0)
	else
		xyd.setUISpriteAsync(needIcon, nil, "icon_" .. cost[1])

		needIconNum.text = cost[2]

		needIcon:SetActive(true)
		backBtnLabel:X(51)
	end

	self.previewScrollView:ResetPosition()
end

function AltarWindow:resetBackTabState()
	if self.selectrdPartnerID_back == nil then
		for i = 1, #self.previewItemIcons do
			self.previewItemIcons[i]:getIconRoot():SetActive(false)
		end

		for i = 1, #self.previewHeroIcons do
			if self.previewHeroIcons[i] ~= nil then
				self.previewHeroIcons[i]:getIconRoot():SetActive(false)
			end
		end

		xyd.setUISpriteAsync(self.heroIconBg, nil, "altar_icon_hw_hui")

		local needIcon = self.backBtn:ComponentByName("icon", typeof(UISprite))
		local needIconNum = self.backBtn:ComponentByName("icon/numLabel", typeof(UILabel))
		local backBtnLabel = self.backBtn:ComponentByName("labelDesc", typeof(UILabel))

		needIcon:SetActive(false)
		backBtnLabel:X(0)
		self:updateText_back()
	end
end

function AltarWindow:getCopyHeroIconByPartnerID(partnerID)
	for _, data in ipairs(self.selPartnerIDs_) do
		if data.partnerID == partnerID then
			return data.heroIcon
		end
	end

	return nil
end

function AltarWindow:deleteSelectPartner(partnerID)
	for idx, data in ipairs(self.selPartnerIDs_) do
		if data.partnerID == partnerID then
			table.remove(self.selPartnerIDs_, idx)
		end
	end
end

function AltarWindow:getHeroIconByPartnerID(partnerID)
	local items = self.multiWrap_:getItems()

	for _, heroItem in ipairs(items) do
		if heroItem:getPartnerId() == partnerID then
			return heroItem:getHeroIcon()
		end
	end
end

function AltarWindow:smartPutIn()
	self.multiWrap_:resetScrollView()

	local key = self.chooseStar_ .. "_" .. self.chooseGroup_
	local sortPartners = slotModel:getPartnersByStar()
	local items = sortPartners[key]
	local index = 1

	while #self.selPartnerIDs_ < MaxSelected and #self.selPartnerIDs_ < #sortPartners["0_0"] - 1 do
		local partnerID = items[index]

		if not partnerID then
			break
		end

		local partner = slotModel:getPartner(partnerID)

		if not self:isPartnerLock(partner) and not xyd.tables.partnerTable:checkPuppetPartner(partner:getTableID()) then
			self:selectHero(partnerID, nil, , true)
		end

		index = index + 1
	end
end

function AltarWindow:autoSmartPutIn()
	xyd.openWindow("smart_altar_window")
end

function AltarWindow:sendDisassembleRequest()
	if #self.selPartnerIDs_ <= 0 or self:isInGuide() then
		return
	end

	if not self:has4StarPartner() then
		local msg = messages_pb.decompose_partners_req()

		for _, data in ipairs(self.selPartnerIDs_) do
			table.insert(msg.partner_ids, data.partnerID)
		end

		xyd.Backend.get():request(xyd.mid.DECOMPOSE_PARTNERS, msg)
	else
		local params = {
			alertType = xyd.AlertType.YES_NO,
			message = __("ALTAR_DECOMPOSE_TIP"),
			callback = function (yes)
				if yes then
					local star6Num = self:get6StarPartnerNum()

					xyd.models.slot:checkDecomposeInvalid()

					local decomposeNum = xyd.models.slot.decomposeTimes

					if tonumber(xyd.tables.miscTable:getVal("altar_6up_day_limit")) < decomposeNum + star6Num then
						xyd.showToast(__("ALTAR_6UP_LIMIT"))

						return
					end

					xyd.models.slot.decomposeTimes = decomposeNum + star6Num
					local msg = messages_pb.decompose_partners_req()

					for _, data in ipairs(self.selPartnerIDs_) do
						table.insert(msg.partner_ids, data.partnerID)
					end

					xyd.Backend.get():request(xyd.mid.DECOMPOSE_PARTNERS, msg)
				end
			end
		}

		xyd.WindowManager.get():openWindow("alert_window", params)
	end
end

function AltarWindow:get6StarPartnerNum()
	local star6Num = 0
	local model = xyd.models.slot

	for _, id in ipairs(self.selPartnerIDs_) do
		local p = model:getPartner(id.partnerID)

		if p:getStar() >= 6 then
			star6Num = star6Num + 1
		end
	end

	return star6Num
end

function AltarWindow:isPartnerLock(partner)
	local lockFlags = partner:getLockFlags()

	for idx, i in pairs(lockFlags) do
		if i ~= 0 then
			return true
		end
	end

	return false
end

function AltarWindow:has4StarPartner()
	for _, data in ipairs(self.selPartnerIDs_) do
		local partner = slotModel:getPartner(data.partnerID)

		if partner:getStar() >= 4 then
			return true
		end
	end

	return false
end

function AltarWindow:getEmptyGroup()
	for idx, data in ipairs(self.chooseHeroList_) do
		if not data.flag then
			data.flag = true

			return data, idx
		end
	end
end

function AltarWindow:isInGuide()
	return false
end

function AltarWindow:isSelect(partnerID)
	return self.selectHeroList_[partnerID]
end

function AltarWindow:willClose()
	AltarWindow.super.willClose(self)
end

function AltarWindow:iosTestChangeUI()
	local winTrans = self.window_

	winTrans:ComponentByName("bgTop", typeof(UISprite)):SetActive(false)
	winTrans:ComponentByName("bgdown", typeof(UISprite)):SetActive(false)

	local iosBG = NGUITools.AddChild(winTrans, "iosBG"):AddComponent(typeof(UITexture))
	iosBG.height = winTrans:GetComponent(typeof(UIPanel)).height
	iosBG.width = winTrans:GetComponent(typeof(UIPanel)).width

	xyd.setUITexture(iosBG, "Textures/texture_ios/bg_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("aniPos/topBtnPos/helfBtn", typeof(UISprite)), "help_2_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("aniPos/topPos/topLable/bg", typeof(UISprite)), "altar_title_bg_ios_test")

	winTrans:ComponentByName("aniPos/topPos/topLable/bg", typeof(UISprite)).type = UIBasicSprite.Type.Sliced

	winTrans:ComponentByName("aniPos/topPos/topLable/bgLeft", typeof(UISprite)):SetActive(false)
	winTrans:ComponentByName("aniPos/topPos/topLable/bgRight", typeof(UISprite)):SetActive(false)
	xyd.iosSetUISprite(winTrans:ComponentByName("aniPos/topPos/choosePart", typeof(UISprite)), "9gongge23_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("aniPos/heroGroup", typeof(UISprite)), "9gongge23_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("aniPos/heroGroup/chooseBtn", typeof(UISprite)), "white_btn_60_60_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("aniPos/btnPos/btnAutoSmart", typeof(UISprite)), "white_btn70_70_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("aniPos/btnPos/btnSmart", typeof(UISprite)), "white_btn70_70_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("aniPos/btnPos/btnDisassemble", typeof(UISprite)), "blue_btn70_70_ios_test")
	xyd.setUISprite(winTrans:ComponentByName("aniPos/topBtnPos/shopBtn", typeof(UISprite)), nil, "shop_ios_test")
	xyd.setUISprite(winTrans:ComponentByName("aniPos/topPos/choosePart/detailBtn", typeof(UISprite)), nil, "btn_preview_ios_test")

	winTrans:ComponentByName("aniPos/btnPos/btnAutoSmart/labelDesc", typeof(UILabel)).color = Color.New2(4294967295.0)
	winTrans:ComponentByName("aniPos/btnPos/btnAutoSmart/labelDesc", typeof(UILabel)).effectStyle = UILabel.Effect.None
	winTrans:ComponentByName("aniPos/btnPos/btnSmart/labelDesc", typeof(UILabel)).color = Color.New2(4294967295.0)
	winTrans:ComponentByName("aniPos/btnPos/btnSmart/labelDesc", typeof(UILabel)).effectStyle = UILabel.Effect.None
	winTrans:ComponentByName("aniPos/heroGroup/labelDesc", typeof(UILabel)).color = Color.New2(4294967295.0)
	winTrans:ComponentByName("aniPos/heroGroup/labelNum", typeof(UILabel)).color = Color.New2(4294967295.0)
	winTrans:ComponentByName("aniPos/heroGroup/chooseBtn/btnTitle", typeof(UILabel)).color = Color.New2(4294967295.0)

	xyd.setUISprite(winTrans:ComponentByName("aniPos/heroGroup/topSeletPart/bg", typeof(UISprite)), nil, "bg_tips_ios_test")
end

return AltarWindow
