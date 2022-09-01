local PotentialityUnlockWindow = class("PotentialityUnlockWindow", import(".BaseWindow"))
local HeroIcon = import("app.components.HeroIcon")
local PotentialIcon = import("app.components.PotentialIcon")

function PotentialityUnlockWindow:ctor(name, params)
	PotentialityUnlockWindow.super.ctor(self, name, params)

	self.partner_ = params.partner
end

function PotentialityUnlockWindow:initWindow()
	PotentialityUnlockWindow.super.initWindow(self)
	self:getComponent()
	self:layoutUI()
	self:initPotentialGroup()
	self:initSkillIconLineLayout()
	self:createAwakeHeroIcon()
	self:updateCostLabel()
	self:register()
end

function PotentialityUnlockWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.unlockDescLabel_ = winTrans:ComponentByName("unlockDescLabel", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.potentialityBtn_ = winTrans:NodeByName("potentialityBtn").gameObject
	self.potentialityBtnLabel_ = winTrans:ComponentByName("potentialityBtn/label", typeof(UILabel))
	self.starImg_ = winTrans:ComponentByName("starImg", typeof(UISprite))
	self.starLabel_ = winTrans:ComponentByName("starLabel", typeof(UILabel))
	self.levLimitDescLabel_ = winTrans:ComponentByName("groupArr/groupArr1/levLimitDescLabel", typeof(UILabel))
	self.levLimitLabel_ = winTrans:ComponentByName("groupArr/groupArr1/levLimitLabel", typeof(UILabel))
	self.hpDescLabel_ = winTrans:ComponentByName("groupArr/groupArr2/hpDescLabel", typeof(UILabel))
	self.hpLabel_ = winTrans:ComponentByName("groupArr/groupArr2/hpLabel", typeof(UILabel))
	self.attDescLabel_ = winTrans:ComponentByName("groupArr/groupArr3/attDescLabel", typeof(UILabel))
	self.attLabel_ = winTrans:ComponentByName("groupArr/groupArr3/attLabel", typeof(UILabel))
	self.feedIcons_ = winTrans:NodeByName("feedIcons").gameObject
	self.feedIconGroup_ = winTrans:NodeByName("feedIconGroup").gameObject
	self.potentialityGroup_ = winTrans:NodeByName("potentialityGroup").gameObject
	self.costGroup = winTrans:NodeByName("costGroup").gameObject
	self.costGroupBg = self.costGroup:ComponentByName("costGroupBg", typeof(UISprite))
	self.item1 = self.costGroup:NodeByName("item1").gameObject
	self.hasLabel1 = self.item1:ComponentByName("hasLabel", typeof(UILabel))
	self.icon1 = self.item1:ComponentByName("icon", typeof(UISprite))
	self.item2 = self.costGroup:NodeByName("item2").gameObject
	self.hasLabel2 = self.item2:ComponentByName("hasLabel", typeof(UILabel))
	self.icon2 = self.item2:ComponentByName("icon", typeof(UISprite))

	for i = 1, 4 do
		self["line" .. i] = self.potentialityGroup_:ComponentByName("line" .. i, typeof(UISprite))
	end
end

function PotentialityUnlockWindow:layoutUI()
	self.unlockDescLabel_.text = __("POTENTIALITY_UNLOCK_SLOT")
	self.potentialityBtnLabel_.text = __("POTENTIALITY_BREAK")
	self.titleLabel_.text = __("POTENTIALITY_UNLOCK_WINDOW_TITLE")
	self.levLimitDescLabel_.text = __("POTENTIALITY_LEV_LIMIT_DESC_TEXT")
	self.hpDescLabel_.text = __("POTENTIALITY_HP_DESC_TEXT")
	self.attDescLabel_.text = __("POTENTIALITY_ATT_DESC_TEXT")
	local lev_limit = xyd.tables.miscTable:split2num("hero_break_lv_cap", "value", "|")
	local star = self.partner_:getStar()
	self.levLimitLabel_.text = tostring(lev_limit[star - 9])
	local hp_att = xyd.tables.miscTable:split2num("hero_break_attr_up", "value", "|")
	self.hpLabel_.text = "+" .. math.floor(hp_att[1] * 100) .. "%"
	self.attLabel_.text = "+" .. math.floor(hp_att[2] * 100) .. "%"
	self.starLabel_.text = tostring(star - 9)
	local str = "potentiality_star_icon"
	local group = self.partner_:getGroup()

	if group and group > 0 then
		str = xyd.checkPartnerGroupImgStr(group, str)
	end

	xyd.setUISpriteAsync(self.starImg_, nil, str, nil, , true)
end

function PotentialityUnlockWindow:register()
	PotentialityUnlockWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.AWAKE_PARTNER, function ()
		local tableID = self.partner_:getTableID()
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG)

		if tableID == tonumber(xyd.split(xyd.tables.miscTable:getVal("graduate_gift_partner"), "|")[3]) and activityData and xyd.getServerTime() < activityData:getEndTime() then
			xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG)
		end

		xyd.WindowManager.get():closeWindow(self.name_)
	end)

	UIEventListener.Get(self.potentialityBtn_).onClick = handler(self, self.onclickAwakeCheck)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function PotentialityUnlockWindow:initSkillIconLineLayout()
	local star = self.partner_:getStar()

	for i = 1, 4 do
		if i < star - 10 then
			xyd.setUISpriteAsync(self["line" .. i], nil, "partner_potential_light_big")
		else
			xyd.setUISpriteAsync(self["line" .. i], nil, "partner_potential_dark_big")
		end
	end
end

function PotentialityUnlockWindow:initPotentialGroup()
	local star = self.partner_:getStar()
	local skillList = self.partner_:getPotentialByOrder()
	local activeStatus = self.partner_:getActiveIndex()

	for i = 1, 5 do
		local group = self.potentialityGroup_:NodeByName("potentialityGroup" .. i).gameObject
		local icon = PotentialIcon.new(group)
		local params = {}
		local id = -1
		local ind = star - 9

		if i > ind then
			params.is_lock = true
			params.is_mask = true
		elseif i == ind then
			params.is_mask = true
			params.is_next = true
		end

		params.scale = 0.73

		icon:setInfo(id, params)
	end
end

function PotentialityUnlockWindow:updateCostLabel()
	local cost = self.partner_:getAwakeItemCost()
	local cost1 = cost

	if self.partner_:getGroup() ~= xyd.PartnerGroup.TIANYI then
		self.item2:SetActive(false)
		self.item1:X(0)

		self.costGroupBg.width = 231
	elseif self.partner_:getGroup() == xyd.PartnerGroup.TIANYI then
		self.item2:SetActive(true)
		self.item1:X(-112.7)
		self.item2:X(124.6)

		self.costGroupBg.width = 476
		cost1 = cost[1]
		local cost2 = cost[2]

		xyd.setUISpriteAsync(self.icon2, nil, xyd.tables.itemTable:getIcon(cost2[1]), function ()
			self.icon2.gameObject:SetLocalScale(0.4, 0.4, 1)
		end, nil, true)

		local resNum = xyd.models.backpack:getItemNumByID(cost2[1])

		if resNum < cost2[2] then
			self.hasLabel2.text = cost2[2] .. "/" .. "[c][cc0011]" .. tostring(resNum) .. "[-][/c]"
		else
			self.hasLabel2.text = cost2[2] .. "/" .. "[c][5566a2]" .. tostring(resNum) .. "[-][/c]"
		end
	end

	local resNum = xyd.models.backpack:getItemNumByID(cost1[1])

	if resNum < cost1[2] then
		self.hasLabel1.text = cost1[2] .. "/" .. "[c][cc0011]" .. tostring(resNum) .. "[-][/c]"
	else
		self.hasLabel1.text = cost1[2] .. "/" .. "[c][5566a2]" .. tostring(resNum) .. "[-][/c]"
	end
end

function PotentialityUnlockWindow:createAwakeHeroIcon()
	local materials = self.partner_:getAwakeMaterial()

	self:updateMaterial()
	NGUITools.DestroyChildren(self.feedIcons_.transform)

	self.awakeHeroIcons = {}
	local flag = {}

	for _, key in pairs(materials) do
		if not flag[key] then
			flag[key] = 1
			local group = NGUITools.AddChild(self.feedIcons_, self.feedIconGroup_)

			group:SetActive(true)

			local heroIconContainer = group:NodeByName("heroIcon").gameObject
			local icon = HeroIcon.new(heroIconContainer)
			local label = group:ComponentByName("labelAwakeFeed", typeof(UILabel))
			local imgPlus = group:ComponentByName("addIcon", typeof(UISprite))

			self.material_details[key].callback = function ()
				self:onClickHeroIcon(self.material_details[key], icon, label, imgPlus, key)
			end

			icon:setInfo(self.material_details[key])
			icon:setGrey()

			local text = "0/" .. self.material_details[key].needNum
			label.text = text

			table.insert(self.awakeHeroIcons, {
				key = key,
				icon = icon,
				label = label,
				imgPlus = imgPlus
			})
		end
	end

	self:updateAwakeHeroIcon()
end

function PotentialityUnlockWindow:updateMaterial()
	local materials = self.partner_:getAwakeMaterial()

	if not materials or not next(materials) then
		return
	end

	local m_detail = {}

	for _, heroID in ipairs(materials) do
		if not m_detail[heroID] then
			m_detail[heroID] = {}
		end

		if heroID % 1000 == 999 then
			local star = xyd.tables.partnerIDRuleTable:getStar(heroID)
			local group = xyd.tables.partnerIDRuleTable:getGroup(heroID)
			local heroIcon = xyd.tables.partnerIDRuleTable:getIcon(heroID)
			local num = (m_detail[heroID].needNum or 0) + 1
			m_detail[heroID] = {
				star = star,
				group = group,
				needNum = num,
				heroIcon = heroIcon,
				partners = {}
			}
		else
			m_detail[heroID].needNum = (m_detail[heroID].needNum or 0) + 1
			m_detail[heroID].tableID = m_detail[heroID].tableID or heroID
			m_detail[heroID].partners = {}
		end

		m_detail[heroID].noClickSelected = true
		m_detail[heroID].notPlaySaoguang = true
	end

	self.material_details = m_detail
end

function PotentialityUnlockWindow:getMaterial()
	return self.material_details
end

function PotentialityUnlockWindow:onClickHeroIcon(params, this_icon, this_label, this_imgPlus, mTableID)
	params.mTableID = mTableID
	params.this_icon = this_icon
	params.this_label = this_label
	params.this_imgPlus = this_imgPlus
	params.showBaoxiang = true
	params.notShowGetWayBtn = true

	xyd.WindowManager.get():openWindow("choose_partner_window", params)
end

function PotentialityUnlockWindow:updateAwakeHeroIcon()
	self.awakeSelectedPartners = {}
	local partners = xyd.models.slot:getPartners()

	for key in pairs(self.material_details) do
		local ps = self.material_details[key].partners
		self.material_details[key].benchPartners = {}

		if ps then
			for _, partnerID in pairs(ps) do
				self.awakeSelectedPartners[partnerID] = 1

				table.insert(self.material_details[key].benchPartners, partners[partnerID])
			end
		end
	end

	for key in pairs(self.material_details) do
		if self.material_details[key].tableID then
			self:awakeAddPartnersById(self.material_details[key].tableID, self.material_details[key].benchPartners)
		else
			self:awakeAddPartnersByParams(self.material_details[key], self.material_details[key].benchPartners)
		end
	end

	for _, awakeHeroIcon in pairs(self.awakeHeroIcons) do
		local key = awakeHeroIcon.key
		local md = self.material_details[key]

		if md then
			local icon = awakeHeroIcon.icon
			local label = awakeHeroIcon.label
			local imgPlus = awakeHeroIcon.imgPlus

			if md.needNum <= #md.benchPartners then
				icon:showRedMark(true)
			else
				icon:showRedMark(false)
			end

			if md.needNum <= #md.partners then
				icon:setOrigin()

				label.color = Color.New2(2986279167.0)

				imgPlus:SetActive(false)
			else
				imgPlus:SetActive(true)

				label.color = Color.New2(4294967295.0)

				icon:setGrey()
			end

			label.text = #md.partners .. "/" .. md.needNum
			icon.selected = false
		end
	end
end

function PotentialityUnlockWindow:awakeAddPartnersById(tableID, array)
	local partners = xyd.models.slot:getPartners()

	for key in pairs(partners) do
		if partners[key]:getTableID() == tableID and self.awakeSelectedPartners[partners[key]:getPartnerID()] ~= 1 and partners[key]:getPartnerID() ~= self.partner_:getPartnerID() then
			local group = partners[key]:getGroup()

			if group == xyd.PartnerGroup.TIANYI then
				local star = partners[key]:getStar()

				if star == 10 then
					table.insert(array, partners[key])
				elseif star >= 11 and star <= 14 and self.partner_:getStar() < star then
					self.hasOtherTianYiHighSelf = true
				end
			else
				table.insert(array, partners[key])
			end
		end
	end

	table.sort(array, function (a, b)
		local weightA = a:getLevel() * 1000000 + a:getTableID()
		local weightB = b:getLevel() * 1000000 + b:getTableID()

		return weightA < weightB
	end)

	return array
end

function PotentialityUnlockWindow:awakeAddPartnersByParams(params, array)
	local partners = xyd.models.slot:getPartners()

	for key in pairs(partners) do
		if (partners[key]:getGroup() == params.group or params.group == 0) and partners[key]:getStar() == params.star and self.awakeSelectedPartners[partners[key]:getPartnerID()] ~= 1 and partners[key]:getPartnerID() ~= self.partner_:getPartnerID() and partners[key]:getGroup() ~= xyd.PartnerGroup.TIANYI then
			table.insert(array, partners[key])
		end
	end

	table.sort(array, function (a, b)
		local weightA = a:getLevel() * 1000000 + a:getTableID()
		local weightB = b:getLevel() * 1000000 + b:getTableID()

		return weightA < weightB
	end)

	return array
end

function PotentialityUnlockWindow:onclickAwakeCheck()
	if self.partner_:getGroup() == xyd.PartnerGroup.TIANYI and self.hasOtherTianYiHighSelf then
		xyd.alert(xyd.AlertType.YES_NO, __("POTENTIALITY_UNLOCK_GROUP_7_TIPS"), function (yes_no)
			if yes_no then
				self:onclickAwake()
			end
		end)
	else
		self:onclickAwake()
	end
end

function PotentialityUnlockWindow:onclickAwake()
	local can_awake = true
	local materials = {}
	local cost = self.partner_:getAwakeItemCost()

	if self.partner_:getGroup() ~= xyd.PartnerGroup.TIANYI then
		cost = cost and cost or {
			xyd.ItemID.GRADE_STONE,
			0
		}
		local resNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.GRADE_STONE)

		if resNum < cost[2] then
			xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.GRADE_STONE)))

			return
		end
	elseif self.partner_:getGroup() == xyd.PartnerGroup.TIANYI then
		for i in pairs(cost) do
			if xyd.models.backpack:getItemNumByID(cost[i][1]) < cost[i][2] then
				xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[i][1])))

				return
			end
		end
	end

	for _, heroIcon in ipairs(self.awakeHeroIcons) do
		local icon = heroIcon.icon
		local info = icon:getPartnerInfo()
		local partner_num = info.partners and #info.partners or 0

		if partner_num < info.needNum then
			can_awake = false

			break
		else
			for _, v in ipairs(info.partners) do
				table.insert(materials, v)
			end
		end
	end

	if can_awake then
		local partners = {}

		for i = 1, #materials do
			local partnerID = materials[i]
			local partner = xyd.models.slot:getPartner(partnerID)

			table.insert(partners, partner)
		end

		xyd.checkHasMarriedAndNotice(partners, function ()
			self.partner_:awakePartner(materials)
		end)
	else
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH_PARTNERS"))
	end
end

return PotentialityUnlockWindow
