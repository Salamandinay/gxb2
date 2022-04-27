local HeroIconWithHP = class("HeroIconWithHP", import("app.components.HeroIcon"))
local FormationItemWithHP = class("FormationItemWithHP")
local PartnerFilter = import("app.components.PartnerFilter")

function HeroIconWithHP:initUI()
	HeroIconWithHP.super.initUI(self)

	self.progress = self:getPartExample("progress")
end

function FormationItemWithHP:ctor(go, parent)
	self.parent_ = parent
	self.uiRoot_ = go
	self.win_ = self.parent_
	self.progressBar = nil
end

function FormationItemWithHP:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)

	if not self.heroIcon_ then
		self.heroIcon_ = HeroIconWithHP.new(self.uiRoot_, self.parent_.partnerRenderPanel)
	end

	self.partner_ = info.partnerInfo
	self.callbackFunc = info.callbackFunc
	self.partnerId_ = self.partner_.partner_id or self.partner_.partnerID
	self.partner_.noClickSelected = true
	self.partner_.callback = handler(self, self.onClick)
	self.partner_.dragScrollView = self.parent_.partnerScrollView
	self.partner_.is_vowed = self.partner_.is_vowed
	self.partner_.noClick = false

	self.heroIcon_:setInfo(self.partner_)

	self.hp = info.partnerInfo.status.hp
	self.heroIcon_.progress.value = self.hp / 100
	self.isShow_ = info.isShowHp

	if self.isShow_ then
		self.heroIcon_:setNoClick(true)
	end

	if self.hp <= 0 then
		xyd.applyChildrenGrey(self.uiRoot_)
	else
		xyd.applyChildrenOrigin(self.uiRoot_)
	end

	self:updateSelectState()
end

function FormationItemWithHP:updateSelectState()
	local isSelect = self.parent_:isSelect(self.partnerId_)

	self:setIsChoose(isSelect)
end

function FormationItemWithHP:setIsChoose(status)
	self.isSelected = status

	if self.heroIcon_ then
		self.heroIcon_:setChoose(status)
	end
end

function FormationItemWithHP:getGameObject()
	return self.uiRoot_
end

function FormationItemWithHP:onClick()
	if self.isShow_ then
		return
	end

	if self.isSelected then
		self.parent_:setSelect(0)
		self:setIsChoose(false)
	else
		self.parent_:setSelect(self.partnerId_)
		self:setIsChoose(true)
	end
end

local ShrineHurdleSelectPartnerWindow = class("ShrineHurdleSelectPartnerWindow", import(".BaseWindow"))

function ShrineHurdleSelectPartnerWindow:ctor(name, params)
	ShrineHurdleSelectPartnerWindow.super.ctor(self, name, params)

	self.isShowHp_ = params.is_show
	self.selectPartner_ = 0
end

function ShrineHurdleSelectPartnerWindow:isSelect(partner_id)
	if self.selectPartner_ == partner_id then
		return true
	else
		return false
	end
end

function ShrineHurdleSelectPartnerWindow:initWindow()
	self:getUIComponent()

	local params = {
		isCanUnSelected = 1,
		chosenGroup = 0,
		scale = 1,
		gap = 20,
		callback = handler(self, function (self, group)
			self:initHeroList(group)
		end),
		width = self.fliter_:GetComponent(typeof(UIWidget)).width
	}
	local partnerFilter = PartnerFilter.new(self.fliter_.gameObject, params)
	self.partnerFilter = partnerFilter

	if not self.isShowHp_ then
		self.partnerFilter:SetActive(false)
		self.sureBtn_:SetActive(true)
	else
		self.partnerFilter:SetActive(true)
		self.sureBtn_:SetActive(false)
	end

	self:initHeroList()

	self.sureBtnLabel_.text = __("SURE")
	self.labelTitle_.text = __("SPRING_FESTIVAL_TEXT01")

	if self.isShowHp_ then
		self.labelTitle_.text = __("SHRINE_HURDLE_TEXT38")
	end
end

function ShrineHurdleSelectPartnerWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.labelTitle_ = winTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.sureBtn_ = winTrans:NodeByName("sureBtn").gameObject
	self.sureBtnLabel_ = winTrans:ComponentByName("sureBtn/button_label", typeof(UILabel))
	self.heroRoot_ = winTrans:NodeByName("heroRoot").gameObject
	self.partnerScrollView = winTrans:ComponentByName("scroller", typeof(UIScrollView))
	self.fliter_ = winTrans:NodeByName("fliter").gameObject
	self.partnerListWarpContent_ = winTrans:ComponentByName("scroller/itemGroup", typeof(MultiRowWrapContent))
	self.partnerMultiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.partnerScrollView, self.partnerListWarpContent_, self.heroRoot_, FormationItemWithHP, self)

	UIEventListener.Get(self.sureBtn_).onClick = function ()
		if not self.selectPartner_ or self.selectPartner_ <= 0 then
			xyd.alertTips(__("SHENXUE_NOT_SELECT_YET"))

			return
		end

		local partnerInfo = xyd.models.shrineHurdleModel:getPartner(self.selectPartner_)

		print("partnerInfo.status.hp ", partnerInfo.status.hp)

		if partnerInfo.status.hp >= 80 then
			xyd.alertYesNo(__("SHRINE_HURDLE_TEXT37"), function (yes_no)
				if yes_no then
					xyd.models.shrineHurdleModel:challengeSelectPartner(self.selectPartner_)

					local win = xyd.WindowManager.get():getWindow("shrine_hurdle_choose_buff_window")

					if win then
						win.canClose_ = true

						win:close()
					end

					self:close()
				end
			end)
		else
			xyd.models.shrineHurdleModel:challengeSelectPartner(self.selectPartner_)

			local win = xyd.WindowManager.get():getWindow("shrine_hurdle_choose_buff_window")

			if win then
				win.canClose_ = true

				win:close()
			end

			self:close()
		end
	end
end

function ShrineHurdleSelectPartnerWindow:initHeroList(groupID)
	groupID = groupID or 0
	local partnerList = xyd.models.shrineHurdleModel:getPartners()
	local partnerDataList = {}
	self.power = 0

	for partnerId, partnerInfo in ipairs(partnerList) do
		if partnerId ~= 0 then
			partnerInfo.noClick = true
			partnerInfo.skin_id = partnerInfo.equips[7]
			partnerInfo.star = xyd.tables.partnerTable:getStar(partnerInfo.table_id) + partnerInfo.awake
			local pGroupID = xyd.tables.partnerTable:getGroup(partnerInfo.table_id)
			local isS = self:isSelect(partnerId)
			local data = {
				partnerInfo = partnerInfo,
				isSelected = isS,
				isShowHp = self.isShowHp_
			}

			if groupID == 0 or pGroupID == groupID then
				table.insert(partnerDataList, data)
			end
		end
	end

	if not self.isShowHp_ then
		table.sort(partnerDataList, function (a, b)
			local hpA = a.partnerInfo.status.hp
			local hpB = b.partnerInfo.status.hp

			return hpA < hpB
		end)
	else
		table.sort(partnerDataList, function (a, b)
			local lva = a.partnerInfo.lv
			local lvb = b.partnerInfo.lv
			local table_id_a = a.partnerInfo.table_id
			local table_id_b = b.partnerInfo.table_id

			return lva * 10000000 + table_id_a > lvb * 10000000 + table_id_b
		end)
	end

	self.partnerMultiWrap_:setInfos(partnerDataList, {})

	return partnerDataList
end

function ShrineHurdleSelectPartnerWindow:setSelect(partner_id)
	self.selectPartner_ = partner_id
	local items = self.partnerMultiWrap_:getItems()

	for _, item in ipairs(items) do
		item:updateSelectState()
	end
end

return ShrineHurdleSelectPartnerWindow
