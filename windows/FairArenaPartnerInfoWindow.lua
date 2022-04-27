local BaseWindow = import(".BaseWindow")
local FairArenaPartnerInfoWindow = class("FairArenaPartnerInfoWindow", BaseWindow)
local SkillIcon = import("app.components.SkillIcon")
local HeroIcon = import("app.components.HeroIcon")
local ItemIcon = import("app.components.ItemIcon")
local Partner = import("app.models.Partner")
local AttrLabel = import("app.components.AttrLabel")
local PartnerBoxTable = xyd.tables.activityFairArenaBoxPartnerTable
local FairArena = xyd.models.fairArena

function FairArenaPartnerInfoWindow:ctor(name, params)
	FairArenaPartnerInfoWindow.super.ctor(self, name, params)

	self.tableID = params.tableID or 0
	self.partnerID = params.partnerID or 0
	self.partner = params.partner
	self.isCollection = params.isCollection
	self.list = params.list or {}

	if self.tableID > 0 then
		self.partner = Partner.new()

		self.partner:populate({
			isHeroBook = true,
			table_id = PartnerBoxTable:getPartnerID(self.tableID),
			lev = PartnerBoxTable:getLv(self.tableID),
			grade = PartnerBoxTable:getGrade(self.tableID),
			equips = PartnerBoxTable:getEquips(self.tableID)
		})
	elseif self.partnerID > 0 then
		self.partner = xyd.models.fairArena:getPartnerByID(self.partnerID)
		self.isOwn = true
	end

	self.skillIcons = {}
end

function FairArenaPartnerInfoWindow:getUIComponent()
	local winTrans = self.window_.transform:NodeByName("groupAction")
	self.winTrans_ = winTrans
	self.avatarGroup = winTrans:NodeByName("avatarGroup").gameObject
	self.nameLabel_ = winTrans:ComponentByName("nameLabel_", typeof(UILabel))
	self.powerLabel_ = winTrans:ComponentByName("forceGroup/powerLabel_", typeof(UILabel))
	self.artifactIconBg_ = winTrans:NodeByName("artifactGroup/iconBg_").gameObject
	self.effectNode = winTrans:ComponentByName("artifactGroup/effectNode", typeof(UITexture)).gameObject
	self.artifactIcon_ = winTrans:NodeByName("artifactGroup/artifactIcon_").gameObject
	self.artifactTextLabel_ = winTrans:ComponentByName("artifactGroup/artifactTextLabel_", typeof(UILabel))
	self.jobIcon_ = winTrans:ComponentByName("jobGroup/jobIcon_", typeof(UISprite))
	self.jobLabel_ = winTrans:ComponentByName("jobGroup/jobLabel_", typeof(UILabel))
	self.jobTextLabel_ = winTrans:ComponentByName("jobGroup/jobTextLabel_", typeof(UILabel))
	self.dataBtn_ = winTrans:NodeByName("dataBtn_").gameObject
	self.modelGroup = winTrans:NodeByName("modelGroup").gameObject
	self.hpLabel_ = winTrans:ComponentByName("attrGroup/hpLabel_", typeof(UILabel))
	self.atklLabel_ = winTrans:ComponentByName("attrGroup/atklLabel_", typeof(UILabel))
	self.defLabel_ = winTrans:ComponentByName("attrGroup/defLabel_", typeof(UILabel))
	self.spdLabel_ = winTrans:ComponentByName("attrGroup/spdLabel_", typeof(UILabel))
	self.detailBtn_ = winTrans:NodeByName("attrGroup/detailBtn_").gameObject
	self.groupAllAttrShow = winTrans:NodeByName("attrGroup/groupAllAttrShow").gameObject
	self.groupAllAttr = self.groupAllAttrShow:NodeByName("groupAllAttr").gameObject
	self.skillGroup = winTrans:NodeByName("skill/skillGroup").gameObject
	self.skillDesc = winTrans:NodeByName("skill/skillDesc").gameObject
	self.leftArr = winTrans:NodeByName("leftArr").gameObject
	self.rightArr = winTrans:NodeByName("rightArr").gameObject
end

function FairArenaPartnerInfoWindow:initWindow()
	FairArenaPartnerInfoWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function FairArenaPartnerInfoWindow:initUIComponent()
	local attrs = self.partner:getBattleAttrs()
	self.nameLabel_.text = self.partner:getName()
	self.powerLabel_.text = self.partner:getPower()
	self.artifactTextLabel_.text = __("ARTIFACT")
	self.jobTextLabel_.text = __("PARTNER_INFO_JOB")
	self.jobLabel_.text = __("JOB_" .. tostring(self.partner:getJob()))
	self.hpLabel_.text = ": " .. tostring(math.floor(attrs.hp))
	self.atklLabel_.text = ": " .. tostring(math.floor(attrs.atk))
	self.defLabel_.text = ": " .. tostring(math.floor(attrs.arm))
	self.spdLabel_.text = ": " .. tostring(math.floor(attrs.spd))

	xyd.setUISpriteAsync(self.jobIcon_, nil, "job_icon" .. self.partner:getJob())
	self:setAvatar()
	self:setArtifact()
	self:setModel()
	self:setAttrLabel()
	self:setSkillItems()

	if self.isOwn then
		self.partners = FairArena:getPartners()
	elseif #self.list == 0 then
		self.leftArr:SetActive(false)
		self.rightArr:SetActive(false)
	end
end

function FairArenaPartnerInfoWindow:setAvatar()
	if not self.avatar then
		self.avatar = HeroIcon.new(self.avatarGroup)
	end

	local info = self.partner:getInfo()
	info.noClick = true

	self.avatar:setInfo(info)
end

function FairArenaPartnerInfoWindow:setArtifact()
	self.equipID = self.partner:getEquipment()[6] or 0

	if self.isOwn then
		local artifacts = xyd.models.fairArena:getEquips()

		self:applyPlusEffect(self.equipID == 0 and #artifacts > 0)
	end

	if self.equipID > 0 then
		if not self.artifactIcon then
			self.artifactIcon = ItemIcon.new(self.artifactIcon_)
		end

		self.artifactIcon:SetActive(true)
		self.artifactIcon:setInfo({
			noClickSelected = true,
			scale = 0.7037037037037037,
			itemID = self.equipID,
			callback = function ()
				self:onClickEquip(self.equipID)
			end
		})
	elseif self.artifactIcon then
		self.artifactIcon:SetActive(false)
	end
end

function FairArenaPartnerInfoWindow:setModel()
	local modelID = xyd.tables.partnerTable:getModelID(self.partner:getTableID())
	local name = xyd.tables.modelTable:getModelName(modelID)
	local scale = xyd.tables.modelTable:getScale(modelID)

	NGUITools.DestroyChildren(self.modelGroup.transform)

	self.model = xyd.Spine.new(self.modelGroup)

	self.model:setInfo(name, function ()
		if self.modelGroup then
			self.model:SetLocalScale(scale, scale, 1)
			self.model:play("idle", 0)
		end
	end, true)
end

function FairArenaPartnerInfoWindow:setAttrLabel()
	local attrs = self.partner:getBattleAttrs()

	NGUITools.DestroyChildren(self.groupAllAttr.transform)

	local bt = xyd.tables.dBuffTable

	for _, key in pairs(xyd.AttrSuffix) do
		local value = attrs[key] or 0
		local str = tostring(math.floor(value))

		if bt:isShowPercent(key) then
			local factor = bt:getFactor(key)
			value = string.format("%.1f", value * 100 / bt:getFactor(key))
			str = tostring(value) .. "%"
		end

		local params = {
			string.upper(key),
			str
		}
		local label = AttrLabel.new(self.groupAllAttr, "large", params)

		label:setValue(params)
	end

	self.groupAllAttrShow:SetActive(false)
end

function FairArenaPartnerInfoWindow:setSkillItems()
	local awake = self.partner:getAwake()
	local skill_ids = nil

	if awake > 0 then
		skill_ids = self.partner:getAwakeSkill(awake)
	else
		skill_ids = self.partner:getSkillIDs()
	end

	local skills = self.partner:getExSkills()
	local exSkills = nil

	if skills and next(skills) ~= nil then
		exSkills = skills
	else
		exSkills = {
			0,
			0,
			0,
			0
		}
	end

	for key = 1, #skill_ids do
		local needGrade = self.partner:getPasTier(key - 1)
		local unlocked = not needGrade or needGrade <= self.partner:getGrade()
		local level = exSkills[key]

		if level and level > 0 then
			skill_ids[key] = xyd.tables.partnerExSkillTable:getExID(skill_ids[key])[level]
		end

		if not self.skillIcons[key] then
			local icon = SkillIcon.new(self.skillGroup)

			table.insert(self.skillIcons, icon)
		end

		self.skillIcons[key]:SetActive(true)
		self.skillIcons[key]:setInfo(skill_ids[key], {
			unlocked = unlocked,
			unlockGrade = needGrade,
			callback = function ()
			end
		})

		UIEventListener.Get(self.skillIcons[key].go).onPress = function (go, isPressed)
			if isPressed == true then
				self.skillIcons[key]:showTips(true, self.skillDesc, true, nil, , function ()
					if self.skillIcons[key]:getDescHeight() >= 800 then
						self.winTrans_.transform:Y(-300)
					end
				end)
			else
				self.winTrans_.transform:Y(0)
				self:clearSkillTips()
			end
		end
	end

	for i = #skill_ids + 1, #self.skillIcons do
		self.skillIcons[i]:SetActive(false)
	end

	self.skillGroup:GetComponent(typeof(UILayout)):Reposition()
end

function FairArenaPartnerInfoWindow:register()
	FairArenaPartnerInfoWindow.super.register(self)

	UIEventListener.Get(self.detailBtn_).onSelect = function (go, isSelected)
		self.groupAllAttrShow:SetActive(not self.groupAllAttrShow.activeSelf)

		if self.groupAllAttrShow.activeSelf then
			self.groupAllAttr:GetComponent(typeof(UITable)):Reposition()
		end
	end

	UIEventListener.Get(self.dataBtn_).onClick = function ()
		local curId = 0
		local tableID = self.partner:getTableID()

		if not xyd.tables.partnerTable:checkIfTaiWu(tableID) then
			curId = 2
		end

		xyd.WindowManager.get():openWindow("partner_data_station_window", {
			partner_table_id = tableID,
			table_id = self.partner:getCommentID(),
			curId = curId
		})
	end

	UIEventListener.Get(self.artifactIconBg_.gameObject).onClick = function ()
		if not self.isOwn then
			return
		end

		xyd.WindowManager.get():openWindow("fair_arena_choose_equip_window", {
			partnerID = self.partner:getPartnerID()
		})
	end

	UIEventListener.Get(self.leftArr).onClick = function ()
		self:onNextPartner(-1)
	end

	UIEventListener.Get(self.rightArr).onClick = function ()
		self:onNextPartner(1)
	end

	self.eventProxy_:addEventListener(xyd.event.FAIR_ARENA_EQUIP, handler(self, function ()
		self.partner = xyd.models.fairArena:getPartnerByID(self.partnerID)

		self:initUIComponent()
	end))
end

function FairArenaPartnerInfoWindow:onNextPartner(dir)
	self.groupAllAttrShow:SetActive(false)

	if self.isCollection then
		if #self.list == 0 then
			return
		end

		local id = self.partner.box_id
		local next_id = 0

		for i, p in ipairs(self.list) do
			if p.box_id == id then
				next_id = i + dir

				break
			end
		end

		if next_id > #self.list then
			next_id = 1
		elseif next_id == 0 then
			next_id = #self.list
		end

		self.partner = self.list[next_id]
		self.partnerID = self.partner:getPartnerID()

		self:initUIComponent()
	elseif self.list then
		local list = self.list
		local index = xyd.arrayIndexOf(list, self.partner:getPartnerID())
		local next = index + dir

		if #list > 1 then
			if next > #list then
				next = 1
			elseif next == 0 then
				next = #list
			end

			self.partner = self.partners[list[next]]
			self.partnerID = self.partner:getPartnerID()

			self:initUIComponent()
		end
	end
end

function FairArenaPartnerInfoWindow:clearSkillTips()
	for _, icon in ipairs(self.skillIcons) do
		icon:showTips(false, self.skillDesc)
	end
end

function FairArenaPartnerInfoWindow:applyPlusEffect(isShow)
	if isShow then
		if not self.artifactEffect then
			self.artifactEffect = xyd.Spine.new(self.effectNode.gameObject)

			self.artifactEffect:setInfo("jiahao", function ()
				self.artifactEffect:SetLocalScale(0.6, 0.6, 1)
				self.artifactEffect:SetLocalPosition(21, -18, 0)
				self.artifactEffect:play("texiao01", 0)
			end)
		else
			self.artifactEffect:play("texiao01", 0)
		end
	elseif self.artifactEffect then
		self.artifactEffect:stop()
		self.artifactEffect:SetActive(false)
	end
end

function FairArenaPartnerInfoWindow:onClickEquip(itemID)
	local params = {}

	if self.isOwn then
		params = {
			btnLayout = 4,
			equipedOn = self.partner:getInfo(),
			equipedPartner = self.partner,
			itemID = itemID,
			rightLabel = __("REPLACE"),
			rightColor = xyd.ButtonBgColorType.blue_btn_65_65,
			rightCallback = function ()
				xyd.WindowManager:get():openWindow("fair_arena_choose_equip_window", {
					partnerID = self.partner:getPartnerID()
				})
				xyd.WindowManager:get():closeWindow("item_tips_window")
			end,
			leftLabel = __("REMOVE"),
			leftColor = xyd.ButtonBgColorType.red_btn_65_65,
			leftCallback = function ()
				xyd.models.fairArena:reqEquip(self.partner:getPartnerID(), 0)
				xyd.WindowManager:get():closeWindow("item_tips_window")
			end
		}
	else
		params = {
			itemID = itemID
		}
	end

	xyd.WindowManager:get():openWindow("item_tips_window", params)
end

return FairArenaPartnerInfoWindow
