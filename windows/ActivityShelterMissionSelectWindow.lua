local HeroIcon = import("app.components.HeroIcon")
local PartnerIcon = class("PartnerIcon")
local PartnerTable = xyd.tables.partnerTable
local SlotModel = xyd.models.slot

function PartnerIcon:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.heroIcon = HeroIcon.new(go)

	self.heroIcon:setDragScrollView(parent.scrollView)
	xyd.setUISprite(self.heroIcon.imgLock_, nil, "lock_icon")

	self.heroIcon.width = 56
	self.heroIcon.height = 36
	self.heroIcon.imgLockSource = "lock_icon"
end

function PartnerIcon:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self.heroIcon:setInfo(info)

	local flag_choose = false
	local flag_lock = false

	if self.parent.choosePartners[info.partnerID] or info.is_shelter_choose then
		self.heroIcon:setPartValueVisible("imgChoose_", true)

		flag_choose = true
	else
		self.heroIcon:setPartValueVisible("imgChoose_", false)
	end

	if info.islock then
		self.heroIcon:setPartValueVisible("imgLock_", true)

		flag_lock = true
	else
		self.heroIcon:setPartValueVisible("imgLock_", false)
	end

	if flag_choose or flag_lock then
		self.heroIcon:setPartValueVisible("imgMask_", true)
	else
		self.heroIcon:setPartValueVisible("imgMask_", false)
	end
end

function PartnerIcon:getGameObject()
	return self.go
end

local ActivityShelterMissionSelectWindow = class("ActivityShelterMissionSelectWindow", import(".BaseWindow"))

function ActivityShelterMissionSelectWindow:ctor(name, params)
	ActivityShelterMissionSelectWindow.super.ctor(self, name, params)

	self.confirmCallback_ = nil
	self.selectCallback_ = nil
	self.allList_ = {}
	self.choosePartners = {}
	self.PartnerTable = xyd.tables.partnerTable
	self.SlotModel = xyd.models.slot
	self.params = params
	self.confirmCallback_ = params.confirmCallback
	self.selectCallback_ = params.selectCallback
	self.optionalList_ = params.optionalList or {}
	self.materialList_ = params.materialList or {}
	self.needNum_ = params.needNum
	self.itemID_ = params.itemID or 199
	self.mTableID_ = params.mTableID
	self.noDebris_ = params.noDebris

	self:sortOptionallist()
end

function ActivityShelterMissionSelectWindow:sortOptionallist()
	for i = 1, #self.optionalList_ do
		table.insert(self.allList_, self.optionalList_[i])
	end

	for i = 1, #self.materialList_ do
		table.insert(self.allList_, self.materialList_[i])
	end

	table.sort(self.allList_, function (a, b)
		local weightA = a:getLevel() + a:getTableID() * 100
		local weightB = b:getLevel() + b:getTableID() * 100

		return weightA < weightB
	end)
end

function ActivityShelterMissionSelectWindow:initWindow()
	ActivityShelterMissionSelectWindow.super.initWindow(self)
	self:getComponent()
	self:initLayOut()

	UIEventListener.Get(self.confirmBtn).onClick = handler(self, self.onClickConfirmBtn)

	if self.itemID_ % 100 == 99 then
		self.detailBtn:SetActive(false)
	else
		UIEventListener.Get(self.detailBtn).onClick = function ()
			xyd.WindowManager.get():openWindow("partner_info", {
				grade = 0,
				lev = 1,
				table_id = self.itemID_
			})
		end
	end

	UIEventListener.Get(self.content).onClick = function ()
		self:onClickConfirmBtn()
	end

	UIEventListener.Get(self.btnDebris).onClick = handler(self, self.onClickDebrisBtn)
end

function ActivityShelterMissionSelectWindow:onClickDebrisBtn()
	if self:checkHasDebris() then
		local params = {
			isShelter = true,
			mTableID = self.itemID_,
			clickId = self.id_,
			closeCallback = function ()
				if xyd.WindowManager.get():getWindow("activity_window") ~= nil then
					xyd.WindowManager.get():openWindow("activity_sheleter_mission_window", {
						id = self.params.missionID
					})
				end
			end
		}

		self:onClickConfirmBtn()
		xyd.WindowManager.get():openWindow("choose_partner_debris_window", params)
		xyd.WindowManager.get():closeWindow("activity_sheleter_mission_window")
		xyd.WindowManager.get():closeWindow(self)
	else
		xyd.showToast(__("NO_PARTNER_DEBRIS"))
	end
end

function ActivityShelterMissionSelectWindow:checkHasDebris()
	local debrisDatas = xyd.models.backpack:getCanComposeDebris()
	local debrisList = {}
	local job = xyd.tables.partnerIDRuleTable:getJob(self.itemID_)
	local group = xyd.tables.partnerIDRuleTable:getGroup(self.itemID_)
	local star = xyd.tables.partnerIDRuleTable:getStar(self.itemID_)

	if debrisDatas ~= nil and debrisDatas[group] ~= nil and debrisDatas[group][star] ~= nil then
		debrisList = debrisDatas[group][star]
	end

	if job == 0 then
		return #debrisList > 0
	end

	local resList = {}

	for i = 1, #debrisList do
		local debrisId = debrisList[i].itemID
		local partnerCost = xyd.tables.itemTable:partnerCost(debrisId)
		local partnerId = partnerCost[1]
		local partnerJob = PartnerTable:getJob(partnerId)

		if job == partnerJob then
			table.insert(resList, debrisList[i])
		end
	end

	return #resList > 0
end

function ActivityShelterMissionSelectWindow:getComponent()
	local winTrans = self.window_.transform
	self.content = winTrans:NodeByName("content").gameObject
	self.topGroup = self.content:NodeByName("topGroup").gameObject
	self.fengeImg = self.content:ComponentByName("eGroup/fengeImg", typeof(UISprite))
	self.detailBtn = self.topGroup:NodeByName("detailBtn").gameObject
	self.topGroupTable = self.topGroup:GetComponent(typeof(UITable))
	self.labelTitle = self.topGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.labelNum = self.topGroup:ComponentByName("labelNum", typeof(UILabel))
	local scrollView = self.content:ComponentByName("partnerScroller", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("partnerContainer", typeof(MultiRowWrapContent))
	local iconContainer = scrollView:NodeByName("iconContainer").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(scrollView, wrapContent, iconContainer, PartnerIcon, self)
	self.notFoundGroup = self.content:NodeByName("notFoundGroup").gameObject
	self.labelNotFound = self.notFoundGroup:ComponentByName("labelNotFound", typeof(UILabel))
	self.confirmBtn = self.content:NodeByName("confirmBtn").gameObject
	self.confirmBtnLabel = self.confirmBtn:ComponentByName("button_label", typeof(UILabel))
	self.btnDebris = self.content:NodeByName("btnDebris").gameObject
	self.btnDebrisLabel = self.btnDebris:ComponentByName("button_label", typeof(UILabel))
end

function ActivityShelterMissionSelectWindow:initLayOut()
	self.selectedNum_ = #self.materialList_
	self.fengeImg.color = Color.New(0, 0, 0, 51)
	self.confirmBtnLabel.text = __("CONFIRM")
	self.btnDebrisLabel.text = __("DEBRIS")
	self.infos = {}

	if self.noDebris_ then
		self.btnDebris:SetActive(false)
		self.confirmBtn.transform:X(0)
	end

	if #self.allList_ > 0 then
		for i = 1, #self.allList_ do
			local data = self.allList_[i]
			data.islock = false

			if data:isLockFlag() then
				data.islock = true
			end

			data.noClickSelected = true
			data.noClick = false
			data.needRedPoint = false

			function data.callback(heroIcon)
				self:onClickHeroIcon(heroIcon)
			end

			data.is_shelter_choose = false

			if self:isMaterial(data) then
				data.is_shelter_choose = true
			end

			table.insert(self.infos, data)
		end

		self.multiWrap_:setInfos(self.infos, {})

		if self.selectedNum_ == self.needNum_ then
			self.labelTitle.text = __("SHENXUE_SELECT_WINDOW")
			self.labelTitle.fontSize = 28
			self.labelTitle.color = Color.New2(810108671)
			self.labelTitle.effectColor = Color.New2(4294967295.0)
			self.labelNum.text = "(" .. tostring(self.selectedNum_) .. "/" .. tostring(self.needNum_) .. ")"
			self.labelNum.fontSize = 28
			self.labelNum.color = Color.New2(915996927)
			self.labelNum.effectColor = Color.New2(4294967295.0)
		else
			self.labelTitle.text = __("SHENXUE_SELECT_WINDOW")
			self.labelTitle.fontSize = 28
			self.labelTitle.color = Color.New2(810108671)
			self.labelTitle.effectColor = Color.New2(4294967295.0)
			self.labelNum.text = "(" .. tostring(self.selectedNum_) .. "/" .. tostring(self.needNum_) .. ")"
			self.labelNum.fontSize = 28
			self.labelNum.color = Color.New2(810108671)
			self.labelNum.effectColor = Color.New2(4294967295.0)
		end
	else
		self.labelTitle.text = __("SHENXUE_SELECT_WINDOW")
		self.labelTitle.fontSize = 28
		self.labelTitle.color = Color.New2(810108671)
		self.labelTitle.effectColor = Color.New2(4294967295.0)
		self.labelNum.text = "(" .. tostring(self.selectedNum_) .. "/" .. tostring(self.needNum_) .. ")"
		self.labelNum.fontSize = 28
		self.labelNum.color = Color.New2(810108671)
		self.labelNum.effectColor = Color.New2(4294967295.0)

		self.notFoundGroup:SetActive(true)

		self.labelNotFound.text = __("NO_PARTNER")
	end
end

function ActivityShelterMissionSelectWindow:willClose(callback, skipAnimation)
	self.confirmCallback_(self.optionalList_, self.materialList_)
	ActivityShelterMissionSelectWindow.super.willClose(self, callback, skipAnimation)
end

function ActivityShelterMissionSelectWindow:onClickHeroIcon(heroIcon)
	local pInfo = heroIcon:getPartnerInfo()
	local partner = SlotModel:getPartner(pInfo.partnerID)

	if heroIcon.lock then
		if pInfo:isLockFlag() then
			if xyd.checkLast(partner) then
				xyd.alert(xyd.AlertType.TIPS, __("UNLOCK_FAILED"))
			elseif xyd.checkDateLock(partner) then
				xyd.alert(xyd.AlertType.TIPS, __("DATE_LOCK_FAIL"))
			elseif xyd.checkHouseLock(partner) then
				xyd.alert(xyd.AlertType.TIPS, __("HOUSE_LOCK_FAIL"))
			elseif xyd.checkQuickFormation(partner) then
				xyd.showToast(__("QUICK_FORMATION_TEXT21"))
			else
				local str = nil
				str = __("IF_UNLOCK_HERO_3")

				xyd.alert(xyd.AlertType.YES_NO, str, function (yes_no)
					if yes_no then
						local succeed = xyd.partnerUnlock(partner)
						partner = xyd.models.slot:getPartner(partner:getPartnerID())

						if succeed then
							heroIcon.lock = false
						else
							xyd.alert(xyd.AlertType.TIPS, __("UNLOCK_FAILED"))
						end
					end
				end)
			end

			return
		end

		return
	end

	if heroIcon.lock then
		xyd.showLockTips(partner)

		return
	end

	if heroIcon.choose == true then
		heroIcon.choose = false
		pInfo.is_shelter_choose = false
		self.choosePartners[pInfo.partnerID] = false
		local index = 1

		for i = 1, #self.materialList_ do
			if self.materialList_[i].partnerID == pInfo.partnerID then
				index = i

				break
			end
		end

		table.insert(self.optionalList_, pInfo)
		table.remove(self.materialList_, index)

		self.selectedNum_ = self.selectedNum_ - 1
	else
		if self.needNum_ <= self.selectedNum_ then
			return
		end

		if partner:isVowed() then
			xyd.alert(xyd.AlertType.YES_NO, __("VOW_SWAP_TIPS"), function (yes_no)
				if yes_no then
					local indexof = self:FindPartnerInTable(self.optionalList_, pInfo)

					if indexof > -1 then
						table.insert(self.materialList_, pInfo)
						table.remove(self.optionalList_, indexof)
					end

					self.selectedNum = self.selectedNum + 1
					heroIcon.choose = true
					self.choosePartners[pInfo.partnerID] = true

					self.selectCallback_()
					self.updateSelectNum()
				end
			end)

			return
		end

		local indexof = self:FindPartnerInTable(self.optionalList_, pInfo)

		if indexof > -1 then
			table.insert(self.materialList_, pInfo)
			table.remove(self.optionalList_, indexof)
		end

		self.selectedNum_ = self.selectedNum_ + 1
		heroIcon.choose = true
		pInfo.is_shelter_choose = true
		self.choosePartners[pInfo.partnerID] = true
	end

	self.selectCallback_()
	self:updateSelectNum()
end

function ActivityShelterMissionSelectWindow:onClickConfirmBtn()
	xyd.WindowManager.get():closeWindow(self.name_)
end

function ActivityShelterMissionSelectWindow:isMaterial(pInfo)
	for i = 1, #self.materialList_ do
		if self.materialList_[i]:getPartnerID() == pInfo:getPartnerID() then
			return true
		end
	end

	return false
end

function ActivityShelterMissionSelectWindow:isOptional(pInfo)
	for i = 1, #self.optionalList_ do
		if self.optionalList_[i]:getPartnerID() == pInfo:getPartnerID() then
			return true
		end
	end

	return false
end

function ActivityShelterMissionSelectWindow:updateSelectNum()
	if self.selectedNum_ == self.needNum_ then
		self.labelTitle.text = __("SHENXUE_SELECT_WINDOW")
		self.labelTitle.fontSize = 28
		self.labelTitle.color = Color.New2(810108671)
		self.labelTitle.effectColor = Color.New2(4294967295.0)
		self.labelNum.text = "(" .. tostring(self.selectedNum_) .. "/" .. tostring(self.needNum_) .. ")"
		self.labelNum.fontSize = 28
		self.labelNum.color = Color.New2(915996927)
		self.labelNum.effectColor = Color.New2(4294967295.0)
	else
		self.labelTitle.text = __("SHENXUE_SELECT_WINDOW")
		self.labelTitle.fontSize = 28
		self.labelTitle.color = Color.New2(960513791)
		self.labelTitle.effectColor = Color.New2(4294967295.0)
		self.labelNum.text = "(" .. tostring(self.selectedNum_) .. "/" .. tostring(self.needNum_) .. ")"
		self.labelNum.fontSize = 28
		self.labelNum.color = Color.New2(960513791)
		self.labelNum.effectColor = Color.New2(4294967295.0)
	end

	self.topGroupTable:Reposition()
end

function ActivityShelterMissionSelectWindow:FindPartnerInTable(tabel, pInfo)
	for index, partner in ipairs(tabel) do
		if partner:getPartnerID() == pInfo:getPartnerID() then
			return index
		end
	end

	return -1
end

return ActivityShelterMissionSelectWindow
