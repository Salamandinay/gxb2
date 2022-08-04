local PotentialityBackWindow = class("PotentialityBackWindow", import(".BaseWindow"))
local PotentialityBackWindowItem = class("PotentialityBackWindowItem", import("app.components.CopyComponent"))
local HeroIcon = import("app.components.HeroIcon")
local json = require("cjson")

function PotentialityBackWindow:ctor(name, params)
	PotentialityBackWindow.super.ctor(self, name, params)

	self.partner_ = params.partner
	self.will_summon = 0
	self.item_cost_ = tonumber(xyd.tables.miscTable:split2Cost("activity_10_replace_cost", "value", "#")[2])
	self.freeActivity = params.freeActivity
end

function PotentialityBackWindow:initWindow()
	PotentialityBackWindow.super.initWindow(self)
	self:getComponent()
	self:layoutUI()
	self:register()
end

function PotentialityBackWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.materialGroup1_ = winTrans:NodeByName("materialGroup1").gameObject
	self.descLabel_ = winTrans:ComponentByName("descLabel", typeof(UILabel))
	self.backBtn_ = winTrans:NodeByName("backBtn").gameObject
	self.costIcon = self.backBtn_:ComponentByName("icon", typeof(UISprite))
	self.heroIconBg = winTrans:ComponentByName("heroIconBg", typeof(UISprite))
	self.costNumLabel = self.costIcon:ComponentByName("numLabel", typeof(UILabel))
	self.backBtnLabel_ = winTrans:ComponentByName("backBtn/label", typeof(UILabel))
	self.itemGroup_ = winTrans:ComponentByName("itemGroup", typeof(UILayout))
	self.helpBtn_ = winTrans:NodeByName("helpBtn").gameObject
	self.previewPart = winTrans:ComponentByName("previewPart", typeof(UISprite))
	self.previewScrollView = self.previewPart:ComponentByName("scrollView", typeof(UIScrollView))
	self.previewGrid = self.previewScrollView:ComponentByName("grid", typeof(UIWrapContent))
end

function PotentialityBackWindow:layoutUI()
	self.titleLabel_.text = __("POTENTIALITY_BACK_TITLE")
	self.descLabel_.text = __("POTENTIALITY_BACK_TEXT01")
	self.backBtnLabel_.text = __("POTENTIALITY_BACK_TEXT02")
	UIEventListener.Get(self.backBtn_).onClick = handler(self, self.onClickBack)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:onClickCloseButton()
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		if self.freeActivity then
			xyd.WindowManager.get():openWindow("help_window", {
				key = "ACTIVITY_FREE_REVERT_TEXT04"
			})
		else
			xyd.WindowManager.get():openWindow("help_window", {
				key = self.name_ .. "_HELP"
			})
		end
	end

	self.eventProxy_:addEventListener(xyd.event.ROLLBACK_PARTNER, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_FREE_REVERGE then
			return
		end

		xyd.WindowManager.get():closeWindow(self.name_)
	end)

	local star = self.partner_:getStar()
	local group = self.partner_:getGroup()

	if star <= 5 then
		xyd.setUISpriteAsync(self.heroIconBg, nil, "altar_icon_hw_lan")
	elseif star <= 9 then
		xyd.setUISpriteAsync(self.heroIconBg, nil, "altar_icon_hw_lv")
	elseif star <= 15 then
		xyd.setUISpriteAsync(self.heroIconBg, nil, "altar_icon_hw_huang")
	end

	local hero_icon1 = HeroIcon.new(self.materialGroup1_)
	local params = self.partner_:getInfo()

	hero_icon1:setInfo(params)

	params.noWays = true
	local needIcon = self.backBtn_:ComponentByName("icon", typeof(UISprite))
	local needIconNum = self.backBtn_:ComponentByName("icon/numLabel", typeof(UILabel))
	local backBtnLabel = self.backBtn_:ComponentByName("label", typeof(UILabel))
	local cost = xyd.tables.partnerReturnRule2Table:getCost(star)

	if cost == nil or cost == 0 or cost[1] == 0 or self.freeActivity then
		needIcon:SetActive(false)
		backBtnLabel:X(0)
	else
		xyd.setUISpriteAsync(needIcon, nil, "icon_" .. cost[1])

		needIconNum.text = cost[2]

		needIcon:SetActive(true)
		backBtnLabel:X(36)
	end

	local partnerID = self.partner_:getPartnerID()
	local partners = nil

	if self.freeActivity then
		partners, self.will_summon = xyd.tables.activityFreeRevertTable:getReturnPartnerByPartner(self.partner_)
	else
		partners, self.will_summon = xyd.tables.partnerReturnRule2Table:getReturnPartnerByPartner(self.partner_)
	end

	if not self.previewItemIcons then
		self.previewItemIcons = {}
		local params = {
			noClick = false,
			scale = 0.8981481481481481,
			itemID = xyd.ItemID.MANA,
			dragScrollView = self.previewScrollView,
			uiRoot = self.previewGrid.gameObject
		}
	end

	if not self.previewHeroIcons then
		self.previewHeroIcons = {}
		local params = {
			tableID = 561001,
			scale = 0.8981481481481481,
			uiRoot = self.previewGrid.gameObject
		}
	end

	if partners and partners[1] and partners[1].table_id then
		for i = 1, #partners do
			local params = {
				scale = 0.8981481481481481,
				notShowGetWayBtn = true,
				heroShowNum = true,
				noWays = true,
				noClick = false,
				itemID = partners[i].table_id,
				num = partners[i].num,
				dragScrollView = self.previewScrollView,
				is_vowed = partners[i].is_vowed
			}
			local star = xyd.tables.partnerTable:getStar(partners[i].table_id)

			if star == 6 then
				local data = xyd.tables.partnerReturnRule2Table:getReturnPartnerInfo(partnerID)

				if data and data[i] and data[i][1] and data[i][1][1] and data[i][1][1] == partners[i].table_id and data[i][2][2] and data[i][2][2] > 0 then
					star = star + data[i][2][2]
				end

				params.star = star
			end

			if self.previewHeroIcons[i] == nil then
				params.uiRoot = self.previewGrid.gameObject
				self.previewHeroIcons[i] = xyd.getItemIcon(params)
			else
				self.previewHeroIcons[i]:getIconRoot():SetActive(true)
				self.previewHeroIcons[i]:setInfo(params)
			end
		end
	end

	local items = {}

	if self.freeActivity then
		items = xyd.tables.activityFreeRevertTable:getAllItemsByPartner(self.partner_)
	else
		items = xyd.tables.partnerReturnRule2Table:getAllItemsByPartner(self.partner_)
	end

	for i = 1, #items do
		local params = {
			scale = 0.8981481481481481,
			notShowGetWayBtn = true,
			noWays = true,
			noClick = false,
			itemID = items[i][1],
			num = items[i][2],
			dragScrollView = self.previewScrollView
		}

		if items[i][1] == xyd.ItemID.MAGIC_DUST then
			local crystal = nil

			if self.freeActivity then
				crystal = xyd.tables.activityFreeRevertTable:getCrystalByPartner(self.partner_)
			else
				crystal = xyd.tables.partnerReturnRule2Table:getCrystalByPartner(self.partner_)
			end

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
	end
end

function PotentialityBackWindow:onClickBack()
	local level = self.partner_:getLevel()

	if level == 1 then
		xyd.alertTips(__("ALTAR_INFO_6"))

		return
	end

	local can_summon = xyd.models.slot:getCanSummonNum()
	local will_summon = self.will_summon

	print(can_summon)
	print(will_summon)

	if can_summon < will_summon - 1 then
		xyd.openWindow("partner_slot_increase_window", {
			descText = __("POTENTIALITY_BACK_TEXT04")
		})
	else
		local star = self.partner_:getStar()
		local cost = xyd.tables.partnerReturnRule2Table:getCost(star)

		if cost and cost ~= 0 and cost[1] ~= 0 and xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] and not self.freeActivity then
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(cost[1])))

			return
		end

		local function callback()
			xyd.alertYesNo(__("POTENTIALITY_BACK_TEXT03"), function (yes)
				if not yes then
					return
				end

				if self.freeActivity then
					xyd.models.slot:saveTempFreeRevergePartnerID(self.partner_:getPartnerID())

					local params = json.encode({
						partner_id = self.partner_:getPartnerID()
					})

					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_FREE_REVERGE, params)
				else
					local msg = messages_pb.rollback_partner_req()
					msg.partner_id = self.partner_:getPartnerID()

					xyd.Backend.get():request(xyd.mid.ROLLBACK_PARTNER, msg)
				end
			end)
		end

		if self.partner_:isLockFlag() then
			if xyd.checkLast(self.partner_) then
				xyd.showToast(__("UNLOCK_FAILED"))
			elseif xyd.checkDateLock(self.partner_) then
				xyd.showToast(__("DATE_LOCK_FAIL"))
			elseif xyd.checkHouseLock(self.partner_) then
				xyd.showToast(__("HOUSE_LOCK_FAIL"))
			elseif xyd.checkQuickFormation(self.partner_) then
				xyd.showToast(__("QUICK_FORMATION_TEXT21"))
			else
				local str = nil
				str = __("IF_UNLOCK_HERO_3")

				xyd.alertYesNo(str, function (yes_no)
					if yes_no then
						local succeed = xyd.partnerUnlock(self.partner_)

						if succeed then
							callback()
						else
							xyd.showToast(__("UNLOCK_FAILED"))
						end
					end
				end)
			end

			return
		else
			callback()
		end
	end
end

function PotentialityBackWindowItem:ctor(parentGo)
	PotentialityBackWindowItem.super.ctor(self, parentGo)
end

function PotentialityBackWindowItem:initUI()
	PotentialityBackWindowItem.super.initUI(self)
	self:getComponent()
end

function PotentialityBackWindowItem:getComponent()
	self.iconRoot_ = self.go:NodeByName("iconRoot").gameObject
	self.label_ = self.go:ComponentByName("label", typeof(UILabel))
end

function PotentialityBackWindowItem:setInfo(params)
	self.item_id_ = params.item_id
	self.num_ = params.num
	self.label_.text = self.num_
	local star = nil

	if xyd.tables.partnerTable:checkPuppetPartner(self.item_id_) then
		star = xyd.tables.partnerTable:getStar(self.item_id_)

		if star == 6 then
			star = 9
		end
	end

	if not self.itemIcon_ then
		self.itemIcon_ = xyd.getItemIcon({
			lev = 1,
			scale = 0.7962962962962963,
			notShowGetWayBtn = true,
			noClick = true,
			noWays = true,
			uiRoot = self.iconRoot_,
			itemID = self.item_id_,
			star = star
		})
	end
end

return PotentialityBackWindow
