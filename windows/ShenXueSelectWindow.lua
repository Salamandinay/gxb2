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

	if info.lockFlag then
		self.heroIcon.lock = true
	else
		self.heroIcon:setLockImgVisible(false)
	end
end

function PartnerIcon:getGameObject()
	return self.go
end

local BaseWindow = import(".BaseWindow")
local ShenXueSelectWindow = class("ShenXueSelectWindow", BaseWindow)

function ShenXueSelectWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.confirmCallback_ = nil
	self.selectCallback_ = nil
	self.materialList_ = {}
	self.PartnerTable = xyd.tables.partnerTable
	self.SlotModel = xyd.models.slot
	self.params = params
	self.confirmCallback_ = params.confirmCallback
	self.selectCallback_ = params.selectCallback
	self.extraJudge_ = params.extraJudge
	self.optionalList_ = params.optionalList
	self.materialList_ = params.materialList
	self.hostPartner_ = params.hostPartner
	self.hideDetailBtn = params.hideDetail
	self.id_ = params.id
	self.mTableID_ = params.mTableID
	self.showBtnDebris = params.showBtnDebris

	self:sortOptionallist()

	self.choosePartners = {}
end

function ShenXueSelectWindow:sortOptionallist()
	if #self.optionalList_.pList > 0 then
		local pList = self.optionalList_.pList

		if pList[1]:getStar() == 5 then
			table.sort(pList, function (a, b)
				if a:getTableID() ~= b:getTableID() then
					local offset_a = a:getTableID() - 100000
					local offset_b = b:getTableID() - 100000

					if offset_a > 0 and offset_b > 0 or offset_a < 0 and offset_b < 0 then
						return a:getTableID() < b:getTableID()
					else
						return b:getTableID() < a:getTableID()
					end
				elseif a:getLevel() ~= b:getLevel() then
					return a:getLevel() < b:getLevel()
				elseif a:getSkinID() ~= b:getSkinID() then
					return b:getSkinID() < a:getSkinID()
				else
					return a:getLovePoint() < b:getLovePoint()
				end
			end)
		else
			table.sort(pList, function (a, b)
				if a:getTableID() ~= b:getTableID() then
					return a:getTableID() < b:getTableID()
				elseif a:getLevel() ~= b:getLevel() then
					return a:getLevel() < b:getLevel()
				elseif a:getSkinID() ~= b:getSkinID() then
					return b:getSkinID() < a:getSkinID()
				else
					return a:getLovePoint() < b:getLovePoint()
				end
			end)
		end
	end
end

function ShenXueSelectWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initDebrisBtn()
end

function ShenXueSelectWindow:initDebrisBtn()
	local showBtnDebris = true
	local star = nil

	if self.mTableID_ and tonumber(self.mTableID_) % 1000 == 999 then
		star = math.floor(tonumber(self.mTableID_) / 10000)
	elseif self.mTableID_ then
		star = xyd.tables.partnerTable:getStar(self.mTableID_)
	else
		star = 10
	end

	if star > 5 and not self.showBtnDebris then
		showBtnDebris = false
	end

	if showBtnDebris then
		self.btnDebris:SetActive(true)

		self.btnDebrisLabel.text = __("DEBRIS")

		xyd.setBgColorType(self.btnDebris, xyd.ButtonBgColorType.blue_btn_70_70)

		UIEventListener.Get(self.btnDebris).onClick = function ()
			if self:checkHasDebris() then
				local params = {
					mTableID = self.mTableID_,
					clickId = self.id_
				}

				function params.closeCallback()
					local shenxueWindow = xyd.WindowManager.get():getWindow("shenxue_window")

					if shenxueWindow and self.id_ then
						shenxueWindow.materialIds_ = {}

						shenxueWindow:initMidGroup(self.params.partnerInfo)
						shenxueWindow:onSelectContainer(self.id_)
					end
				end

				xyd.WindowManager.get():openWindow("choose_partner_debris_window", params)
				self.confirmCallback_(self.id_, self.materialList_, self.hostPartner_, self.optionalList_.pList)
				xyd.WindowManager.get():closeWindow("shenxue_select_window")
			else
				xyd.showToast(__("NO_PARTNER_DEBRIS"))
			end
		end

		self.confirmBtn.transform:X(130)
	else
		self.btnDebris:SetActive(false)
	end
end

function ShenXueSelectWindow:getUIComponent()
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

function ShenXueSelectWindow:playOpenAnimation(callback)
	BaseWindow.playOpenAnimation(self, function ()
		callback()
		self:initLayOut()

		UIEventListener.Get(self.confirmBtn).onClick = function ()
			self:onClickConfirmBtn()
		end

		UIEventListener.Get(self.detailBtn).onClick = function ()
			self:onDetail()
		end

		UIEventListener.Get(self.content).onClick = function ()
			self:onClickConfirmBtn()
		end
	end)
end

function ShenXueSelectWindow:initLayOut()
	if self.id_ == 4 or self.id_ == 3 or self.hideDetailBtn then
		self.detailBtn:SetActive(false)
	else
		self.detailBtn:SetActive(true)
	end

	self.selectedNum = 0
	self.fengeImg.color = Color.New(0, 0, 0, 51)
	self.confirmBtnLabel.text = __("CONFIRM")
	self.infos = {}

	if #(self.optionalList_.pList or {}) + #(self.materialList_ or {}) > 0 or self.hostPartner_ then
		self.notFoundGroup:SetActive(false)

		if self.id_ == 1 then
			if self.hostPartner_ then
				self.hostPartner_.needRedPoint = false
				self.hostPartner_.noClickSelected = true
				self.hostPartner_.isShowLovePoint = true

				function self.hostPartner_.callback(heroIcon)
					self:onClickheroIcon(heroIcon)
				end

				local partner = self.SlotModel:getPartner(self.hostPartner_.partnerID)
				self.hostPartner_.lockFlag = partner:isLockFlag()
				self.choosePartners[self.hostPartner_.partnerID] = true

				table.insert(self.infos, self.hostPartner_)

				self.selectedNum = self.selectedNum + 1
			end
		else
			for _, pInfo in ipairs(self.materialList_) do
				pInfo.needRedPoint = false
				pInfo.noClickSelected = true
				pInfo.isShowLovePoint = true

				function pInfo.callback(heroIcon)
					self:onClickheroIcon(heroIcon)
				end

				local partner = self.SlotModel:getPartner(pInfo.partnerID)

				if partner then
					pInfo.lockFlag = partner:isLockFlag()
					self.choosePartners[pInfo.partnerID] = true

					table.insert(self.infos, pInfo)

					self.selectedNum = self.selectedNum + 1
				end
			end
		end

		for _, pInfo in ipairs(self.optionalList_.pList) do
			pInfo.needRedPoint = false
			pInfo.noClickSelected = true
			pInfo.isShowLovePoint = true

			function pInfo.callback(heroIcon)
				self:onClickheroIcon(heroIcon)
			end

			local partner = self.SlotModel:getPartner(pInfo.partnerID)
			pInfo.lockFlag = partner:isLockFlag()

			if self:checkMaterial(pInfo, self.materialList_) and self:checkMaterial(pInfo, self.infos) then
				table.insert(self.infos, pInfo)
			end
		end

		self.multiWrap_:setInfos(self.infos, {})

		if self.selectedNum == self.optionalList_.needNum then
			self.labelTitle.text = __("SHENXUE_SELECT_WINDOW")
			self.labelTitle.fontSize = 28
			self.labelTitle.color = Color.New2(810108671)
			self.labelTitle.effectColor = Color.New2(4294967295.0)
			self.labelNum.text = "(" .. tostring(self.selectedNum) .. "/" .. tostring(self.optionalList_.needNum) .. ")"
			self.labelNum.fontSize = 28
			self.labelNum.color = Color.New2(915996927)
			self.labelNum.effectColor = Color.New2(4294967295.0)
		else
			self.labelTitle.text = __("SHENXUE_SELECT_WINDOW")
			self.labelTitle.fontSize = 28
			self.labelTitle.color = Color.New2(810108671)
			self.labelTitle.effectColor = Color.New2(4294967295.0)
			self.labelNum.text = "(" .. tostring(self.selectedNum) .. "/" .. tostring(self.optionalList_.needNum) .. ")"
			self.labelNum.fontSize = 28
			self.labelNum.color = Color.New2(810108671)
			self.labelNum.effectColor = Color.New2(4294967295.0)
		end
	else
		self.labelTitle.text = __("SHENXUE_SELECT_WINDOW")
		self.labelTitle.fontSize = 28
		self.labelTitle.color = Color.New2(810108671)
		self.labelTitle.effectColor = Color.New2(4294967295.0)
		self.labelNum.text = "(" .. tostring(self.selectedNum) .. "/" .. tostring(self.optionalList_.needNum) .. ")"
		self.labelNum.fontSize = 28
		self.labelNum.color = Color.New2(810108671)
		self.labelNum.effectColor = Color.New2(4294967295.0)

		self.notFoundGroup:SetActive(true)

		self.labelNotFound.text = __("NO_PARTNER")
	end

	self.topGroupTable:Reposition()
end

function ShenXueSelectWindow:checkMaterial(partnerInfo, checkList)
	for _, pInfo in ipairs(checkList) do
		if partnerInfo.partnerID == pInfo.partnerID then
			return false
		end
	end

	return true
end

function ShenXueSelectWindow:onClickheroIcon(heroIcon)
	local pInfo = heroIcon:getPartnerInfo()
	local partner = self.SlotModel:getPartner(pInfo.partnerID)

	if heroIcon.lock then
		if xyd.checkLast(partner) then
			xyd.alert(xyd.AlertType.TIPS, __("UNLOCK_FAILED"))
		elseif xyd.checkDateLock(partner) then
			xyd.alert(xyd.AlertType.TIPS, __("DATE_LOCK_FAIL"))
		elseif xyd.checkQuickFormation(self.partner_) then
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

	if heroIcon.choose == true then
		heroIcon.choose = false
		self.choosePartners[pInfo.partnerID] = false

		if self.id_ == 1 then
			self.hostPartner_ = nil
			self.selectedNum = self.selectedNum - 1
		else
			local index = 1

			for i = 1, #self.materialList_ do
				if self.materialList_[i].partnerID == pInfo.partnerID then
					index = i

					break
				end
			end

			table.remove(self.materialList_, index)

			self.selectedNum = self.selectedNum - 1
		end
	else
		if self.id_ == 1 then
			if self.hostPartner_ then
				return
			end

			self.hostPartner_ = pInfo
		else
			if self.optionalList_.needNum <= #self.materialList_ then
				return
			end

			if self.extraJudge_ and not self.extraJudge_(partner) then
				return
			end

			if partner:isVowed() then
				xyd.alert(xyd.AlertType.YES_NO, __("VOW_SWAP_TIPS"), function (yes_no)
					if yes_no then
						table.insert(self.materialList_, pInfo)

						self.selectedNum = self.selectedNum + 1
						heroIcon.choose = true
						self.choosePartners[pInfo.partnerID] = true

						self.selectCallback_(self.id_, pInfo, heroIcon.choose, partner)
						self:updateSelectNum()
					end
				end)

				return
			end

			table.insert(self.materialList_, pInfo)
		end

		self.selectedNum = self.selectedNum + 1
		heroIcon.choose = true
		self.choosePartners[pInfo.partnerID] = true
	end

	if self.selectedNum <= 0 then
		self.selectCallback_(self.id_, pInfo, heroIcon.choose)
	else
		self.selectCallback_(self.id_, pInfo, heroIcon.choose, partner)
	end

	self:updateSelectNum()
end

function ShenXueSelectWindow:updateSelectNum()
	if self.selectedNum == self.optionalList_.needNum then
		self.labelTitle.text = __("SHENXUE_SELECT_WINDOW")
		self.labelTitle.fontSize = 28
		self.labelTitle.color = Color.New2(810108671)
		self.labelTitle.effectColor = Color.New2(4294967295.0)
		self.labelNum.text = "(" .. tostring(self.selectedNum) .. "/" .. tostring(self.optionalList_.needNum) .. ")"
		self.labelNum.fontSize = 28
		self.labelNum.color = Color.New2(915996927)
		self.labelNum.effectColor = Color.New2(4294967295.0)
	else
		self.labelTitle.text = __("SHENXUE_SELECT_WINDOW")
		self.labelTitle.fontSize = 28
		self.labelTitle.color = Color.New2(960513791)
		self.labelTitle.effectColor = Color.New2(4294967295.0)
		self.labelNum.text = "(" .. tostring(self.selectedNum) .. "/" .. tostring(self.optionalList_.needNum) .. ")"
		self.labelNum.fontSize = 28
		self.labelNum.color = Color.New2(960513791)
		self.labelNum.effectColor = Color.New2(4294967295.0)
	end

	self.topGroupTable:Reposition()
end

function ShenXueSelectWindow:onClickConfirmBtn()
	self.confirmCallback_(self.id_, self.materialList_, self.hostPartner_, self.optionalList_.pList)
	xyd.WindowManager.get():closeWindow(self.name_)
end

function ShenXueSelectWindow:onDetail()
	xyd.WindowManager.get():openWindow("partner_info", {
		grade = 0,
		lev = 1,
		table_id = self.mTableID_
	})
end

function ShenXueSelectWindow:close(callback, skipAnimation)
	self.confirmCallback_(self.id_, self.materialList_, self.hostPartner_, self.optionalList_.pList)
	ShenXueSelectWindow.super.close(self, callback, skipAnimation)
end

function ShenXueSelectWindow:willClose()
	BaseWindow.willClose(self)
end

function ShenXueSelectWindow:checkHasDebris()
	local debrisDatas = xyd.models.backpack:getCanComposeDebris()
	local itemList = {}
	local star9HelpArr = {
		[940044.0] = 1,
		[940045.0] = 1,
		[940046.0] = 1,
		[940043.0] = 1,
		[940041.0] = 1,
		[940042.0] = 1
	}

	if tonumber(self.mTableID_) % 1000 == 999 then
		local group = math.floor(tonumber(self.mTableID_) % 10000 / 1000)
		local star = math.floor(tonumber(self.mTableID_) / 10000)
		local is9Star = false

		if star == 9 then
			star = 6
			is9Star = true
		end

		if group == 9 then
			for i = 1, xyd.GROUP_NUM do
				if debrisDatas and debrisDatas[i] and debrisDatas[i][star] then
					for key, value in pairs(debrisDatas[i][star]) do
						if is9Star and star9HelpArr[value.itemID] then
							table.insert(itemList, value)
						elseif not is9Star and not star9HelpArr[value.itemID] then
							table.insert(itemList, value)
						end
					end
				end
			end
		elseif debrisDatas and debrisDatas[group] and debrisDatas[group][star] then
			for key, value in pairs(debrisDatas[group][star]) do
				if is9Star and star9HelpArr[value.itemID] then
					table.insert(itemList, value)
				elseif not is9Star and not star9HelpArr[value.itemID] then
					table.insert(itemList, value)
				end
			end
		end
	else
		local itemID = xyd.tables.partnerTable:getPartnerShard(self.mTableID_)
		local itemNum = xyd.models.backpack:getItemNumByID(itemID)
		local cost = xyd.tables.itemTable:partnerCost(itemID)

		if cost[2] <= itemNum then
			table.insert(itemList, {
				itemID = itemID,
				itemNum = itemNum
			})
		end
	end

	if #itemList > 0 then
		return true
	else
		return false
	end
end

return ShenXueSelectWindow
