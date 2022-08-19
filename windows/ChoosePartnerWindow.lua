local HeroIcon = import("app.components.HeroIcon")
local PartnerIcon = class("PartnerIcon")

function PartnerIcon:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.heroIcon = HeroIcon.new(go)

	self.heroIcon:setDragScrollView(parent.scrollView)
end

function PartnerIcon:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self.heroIcon:setInfo(info)

	if self.parent.choosePartners[info.partnerID] then
		self.heroIcon.choose = true
	else
		self.heroIcon.choose = false
	end

	if info.lockType ~= 0 then
		self.heroIcon.lock = true
	else
		self.heroIcon:setLockImgVisible(false)
	end
end

function PartnerIcon:getGameObject()
	return self.go
end

local BaseWindow = import(".BaseWindow")
local ChoosePartnerWindow = class("ChoosePartnerWindow", BaseWindow)

function ChoosePartnerWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.selected = {}
	self.params = params
	self.this_icon = params.this_icon
	self.this_imgPlus = params.this_imgPlus
	self.this_label = params.this_label
	self.needNum = params.needNum
	self.confirmCallback = params.confirmCallback
	self.selected = params.partners or {}
	self.choosePartners = {}
	self.isShenxue = params.isShenxue and params.isShenxue or false
	self.mTableID_ = params.mTableID
	self.mTableIDList_ = params.mTableIDList
	self.id_ = params.id
	self.type_ = params.type
	self.isShowLovePoint_ = params.isShowLovePoint
	self.showBtnDebris = params.showBtnDebris
	self.showBaoxiang = params.showBaoxiang
	self.notShowGetWayBtn = params.notShowGetWayBtn

	for _, id in pairs(self.selected) do
		self.choosePartners[id] = true
	end
end

function ChoosePartnerWindow:getUIComponent()
	local winTrans = self.window_.transform
	local main = winTrans:NodeByName("main").gameObject
	self.title = main:ComponentByName("title", typeof(UILabel))
	self.backBtn = main:NodeByName("backBtn").gameObject
	self.partnerNone = main:NodeByName("partnerNone").gameObject
	self.noPartnerLabel = self.partnerNone:ComponentByName("noPartnerLabel", typeof(UILabel))
	self.btnYes = main:NodeByName("btnYes").gameObject
	self.btnYesLabel = self.btnYes:ComponentByName("button_label", typeof(UILabel))
	self.btnDebris = main:NodeByName("btnDebris").gameObject
	self.btnDebrisLabel = self.btnDebris:ComponentByName("button_label", typeof(UILabel))
	self.scrollView = main:ComponentByName("partnerScroller", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("wrapContent", typeof(MultiRowWrapContent))
	local partnerContainer = self.scrollView:NodeByName("partnerContainer").gameObject

	partnerContainer:SetActive(false)

	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView, wrapContent, partnerContainer, PartnerIcon, self)
end

function ChoosePartnerWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initDebrisBtn()

	self.title.text = __("CHOOSE_MATERIAL_PARTNER")
	self.btnYesLabel.text = __("CONFIRM")

	xyd.setBgColorType(self.btnYes, xyd.ButtonBgColorType.blue_btn_70_70)

	self.noPartnerLabel.text = __("NO_PARTNER")

	if #self.params.benchPartners <= 0 then
		self.partnerNone:SetActive(true)
	else
		self.partnerNone:SetActive(false)
	end

	self.infos = {}

	for key in pairs(self.params.benchPartners) do
		local partner = self.params.benchPartners[key]

		self:addPartnerToContainer(partner)
	end

	self.multiWrap_:setInfos(self.infos, {})
	self:registerEvent()
end

function ChoosePartnerWindow:initDebrisBtn()
	local showBtnDebris = self.showBtnDebris

	if showBtnDebris == nil then
		showBtnDebris = true
	end

	if showBtnDebris then
		self.btnDebris:SetActive(true)

		self.btnDebrisLabel.text = __("DEBRIS")

		xyd.setBgColorType(self.btnDebris, xyd.ButtonBgColorType.blue_btn_70_70)

		UIEventListener.Get(self.btnDebris).onClick = function ()
			if self:checkHasDebris() or self:checkBaoxiang() then
				local params = {
					mTableID = self.mTableID_,
					mTableIDList = self.mTableIDList_,
					clickId = self.id_,
					showBaoxiang = self.showBaoxiang,
					notShowGetWayBtn = self.notShowGetWayBtn
				}

				function params.closeCallback()
					local partnerDetailWindow = xyd.WindowManager.get():getWindow("partner_detail_window")

					if partnerDetailWindow and self.id_ then
						partnerDetailWindow:refreshShenxueMaterials()
						partnerDetailWindow:autoPutMaterial()
						partnerDetailWindow:onSelectContainer(self.id_)
					end
				end

				if not self.isShenxue then
					function params.closeCallback()
						local win = xyd.WindowManager.get():getWindow("potentiality_unlock_window")
						win = win or xyd.WindowManager.get():getWindow("partner_detail_window")

						if win then
							local params = win:getMaterial()[self.params.mTableID]

							if not params then
								return
							end

							params.this_icon = self.params.this_icon
							params.this_label = self.params.this_label
							params.this_imgPlus = self.params.this_imgPlus
							params.mTableID = self.params.mTableID

							win:updateAwakeHeroIcon()
							xyd.WindowManager.get():openWindow("choose_partner_window", params)
						end
					end
				end

				if self.params.debrisCloseCallBack then
					params.closeCallback = self.params.debrisCloseCallBack
				end

				xyd.WindowManager.get():openWindow("choose_partner_debris_window", params)
				xyd.WindowManager.get():closeWindow("choose_partner_window")
			else
				xyd.showToast(__("NO_PARTNER_DEBRIS"))
			end
		end

		self.btnYes.transform:X(120)
	else
		self.btnDebris:SetActive(false)
	end
end

function ChoosePartnerWindow:checkHasDebris()
	local debrisDatas = xyd.models.backpack:getCanComposeDebris()
	local itemList = {}
	local mTableIDList = {}

	if self.mTableIDList_ then
		mTableIDList = self.mTableIDList_
	else
		mTableIDList = {
			self.mTableID_
		}
	end

	for i = 1, #mTableIDList do
		local mTableID = mTableIDList[i]

		if tonumber(mTableID) % 1000 == 999 then
			local group = math.floor(tonumber(mTableID) % 10000 / 1000)
			local star = math.floor(tonumber(mTableID) / 10000)

			if star < 6 then
				if debrisDatas and debrisDatas[group] and debrisDatas[group][star] then
					itemList = debrisDatas[group][star]
				end
			elseif star == 6 then
				if debrisDatas and debrisDatas[group] and debrisDatas[group][6] then
					local tList = debrisDatas[group][6]

					for _, item in ipairs(tList) do
						if xyd.DogFood_Six[item.itemID] then
							table.insert(itemList, item)
						end
					end
				end
			else
				local select = nil

				if star == 9 then
					select = xyd.DogFood_Nine
				else
					select = xyd.DogFood_Ten
				end

				if debrisDatas then
					for _, list in pairs(debrisDatas) do
						local tList = list[6] or {}

						for _, item in ipairs(tList) do
							if select[item.itemID] then
								table.insert(itemList, item)
							end
						end
					end
				end
			end
		else
			local itemID = xyd.tables.partnerTable:getPartnerShard(mTableID)
			local itemNum = xyd.models.backpack:getItemNumByID(itemID)
			local cost = xyd.tables.itemTable:partnerCost(itemID)

			if cost[2] <= itemNum then
				table.insert(itemList, {
					itemID = itemID,
					itemNum = itemNum
				})
			end
		end
	end

	if #itemList > 0 then
		return true
	else
		return false
	end
end

function ChoosePartnerWindow:checkBaoxiang()
	if self.showBaoxiang then
		local baoxiangItems = xyd.models.backpack:getBaoxiangItems()
		local baoxiangRecordArr = {}
		local mTableIDList = {}

		if self.mTableIDList_ then
			mTableIDList = self.mTableIDList_
		else
			mTableIDList = {
				self.mTableID_
			}
		end

		for _, mTableID in ipairs(mTableIDList) do
			if tonumber(mTableID) % 1000 == 999 then
				local group = math.floor(tonumber(mTableID) % 10000 / 1000)
				local star = math.floor(tonumber(mTableID) / 10000)

				for _, baoxiangItem in ipairs(baoxiangItems) do
					if not baoxiangRecordArr[baoxiangItem.itemID] then
						local optionalDebrisIDs = xyd.tables.giftBoxOptionalTable:getItems(baoxiangItem.itemID)

						for __, debrisItem in ipairs(optionalDebrisIDs) do
							local partnerCost = xyd.tables.itemTable:partnerCost(debrisItem.itemID)
							local partnerTableID = partnerCost[1]
							local partnerGroup = xyd.tables.partnerTable:getGroup(partnerTableID)
							local partnerStar = xyd.tables.partnerTable:getStar(partnerTableID)

							if partnerGroup == group and partnerStar == star and not baoxiangRecordArr[baoxiangItem.itemID] then
								return true
							end
						end
					end
				end
			else
				local itemID = xyd.tables.partnerTable:getPartnerShard(mTableID)

				for _, baoxiangItem in ipairs(baoxiangItems) do
					if not baoxiangRecordArr[baoxiangItem.itemID] then
						local optionalDebrisIDs = xyd.tables.giftBoxOptionalTable:getItems(baoxiangItem.itemID)

						for __, debrisItem in ipairs(optionalDebrisIDs) do
							local partnerCost = xyd.tables.itemTable:partnerCost(debrisItem.itemID)
							local partnerTableID = partnerCost[1]
							local partnerGroup = xyd.tables.partnerTable:getGroup(partnerTableID)
							local partnerStar = xyd.tables.partnerTable:getStar(partnerTableID)

							if debrisItem.itemID == itemID and not baoxiangRecordArr[baoxiangItem.itemID] then
								return true
							end
						end
					end
				end
			end
		end
	end

	return false
end

function ChoosePartnerWindow:addPartnerToContainer(partner)
	local partnerID = partner:getPartnerID()
	local params = partner:getInfo()
	params.choose = false
	params.noClickSelected = true
	local lockType = partner:getLockType()
	params.lockType = lockType
	params.isShowLovePoint = true

	if self.isShowLovePoint_ ~= nil then
		params.isShowLovePoint = self.isShowLovePoint_
	end

	function params.callback(icon)
		local lockType = partner:getLockType()

		if lockType ~= 0 then
			if xyd.checkLast(partner) then
				xyd.showToast(__("UNLOCK_FAILED"))
			elseif xyd.checkDateLock(partner) then
				xyd.showToast(__("DATE_LOCK_FAIL"))
			elseif xyd.checkQuickFormation(partner) then
				xyd.showToast(__("QUICK_FORMATION_TEXT21"))
			elseif xyd.checkGalaxyFormation(partner) then
				xyd.showToast(__("GALAXY_TRIP_TIPS_20"))
			else
				local str = __("IF_UNLOCK_HERO_3")

				xyd.alert(xyd.AlertType.YES_NO, str, function (yes_no)
					if yes_no then
						local succeed = xyd.partnerUnlock(partner)
						partner = xyd.models.slot:getPartner(partner:getPartnerID())

						if succeed then
							icon.lock = false
						else
							xyd.showToast(__("UNLOCK_FAILED"))
						end
					end
				end)
			end

			return
		end

		local choose = self.choosePartners[partnerID]

		if not choose and (self.type_ == "ACTIVITY_PROMOTION_LADDER" or self.type_ == "ACTIVITY_FREE_REVERGE") and self.needNum <= #self.selected then
			self:clearChoose()
		end

		if #self.selected < self.needNum then
			choose = not choose or false

			if choose then
				self:addToSelected(partnerID)
			else
				self:remFromSelected(partnerID)
			end
		else
			choose = not choose or false

			if choose then
				choose = false
			else
				self:remFromSelected(partnerID)
			end
		end

		icon.choose = choose
		self.choosePartners[partnerID] = choose
	end

	table.insert(self.infos, params)
end

function ChoosePartnerWindow:clearChoose()
	self.selected = {}

	for i in pairs(self.infos) do
		if self.choosePartners[self.infos[i].partnerID] then
			self.choosePartners[self.infos[i].partnerID] = false
		end
	end

	for i in pairs(self.multiWrap_.items_) do
		if self.multiWrap_.items_[i].heroIcon and self.multiWrap_.items_[i].data then
			self.multiWrap_.items_[i].heroIcon.choose = false

			if self.multiWrap_.items_[i].data.lockType ~= 0 then
				self.multiWrap_.items_[i].heroIcon.lock = true
			else
				self.multiWrap_.items_[i].heroIcon:setLockImgVisible(false)
			end
		end
	end
end

function ChoosePartnerWindow:addToSelected(partnerID)
	table.insert(self.selected, partnerID)
end

function ChoosePartnerWindow:remFromSelected(partnerID)
	for id = #self.selected, 1, -1 do
		if partnerID == self.selected[id] then
			table.remove(self.selected, id)
		end
	end
end

function ChoosePartnerWindow:updateIcon()
	self.this_icon:updatePartnerInfo({
		partners = self.selected
	})

	local win = xyd.WindowManager:get():getWindow("potentiality_unlock_window") or xyd.WindowManager:get():getWindow("partner_detail_window")

	if win then
		win:updateAwakeHeroIcon()
	end
end

function ChoosePartnerWindow:getSelected()
	return self.selected
end

function ChoosePartnerWindow:willClose()
	if self.confirmCallback then
		self.confirmCallback()
	else
		self:updateIcon()
	end

	BaseWindow.willClose(self)
end

function ChoosePartnerWindow:registerEvent()
	UIEventListener.Get(self.backBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnYes).onClick = function ()
		self:close()
	end
end

return ChoosePartnerWindow
