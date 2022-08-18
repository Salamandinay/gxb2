local BaseWindow = import(".BaseWindow")
local PartnerInfoWindow = class("PartnerInfoWindow", BaseWindow)
local SkillIcon = import("app.components.SkillIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local AttrLabel = import("app.components.AttrLabel")
local SinglePartnerWayItem = import("app.components.SinglePartnerWayItem")

function PartnerInfoWindow:ctor(name, params)
	function params.playOpenAnimationTweenCal(alpha)
		if self.model then
			self.model:setAlpha(alpha)
		end
	end

	function params.playCloseAnimationTweenCal(alpha)
		if self.model then
			self.model:setAlpha(alpha)
		end
	end

	BaseWindow.ctor(self, name, params)

	self.notShowWays = false
	self.isHideAttr = false
	self.isHideForce = false
	self.tableID = params.table_id or params.tableID
	self.partnerid = params.partnerid or params.partnerID or 0
	self.notShowWays = params.notShowWays
	self.isShowWays = false
	self.isHideAttr = params.isHideAttr
	self.isHideForce = params.isHideAttr
	self.isHideWays = params.noWays
	self.isEntrance = params.isEntrance
	self.showRecommoned = params.showRecommoned or false
	self.recommonedText = params.recommonedText

	if self.partnerid ~= 0 then
		local slot = xyd.models.slot
		self.partner = slot:getPartner(self.partnerid)
	elseif not params.partner then
		self.partner = Partner.new()
		local star = params.star or xyd.tables.partnerTable:getStar(self.tableID)
		local grade = params.grade ~= nil and params.grade or xyd.tables.partnerTable:getMaxGrade(self.tableID)
		local lev = params.lev or xyd.tables.partnerTable:getMaxlev(self.tableID, grade)
		local ex_skills = params.ex_skills or {
			0,
			0,
			0,
			0
		}
		local equipments = params.equipments or {
			0,
			0,
			0,
			0,
			0,
			0
		}
		local lockFlags = {}
		local awake = params.awake or 0

		self.partner:populate({
			partnerid = self.partnerid,
			table_id = self.tableID,
			star = star,
			grade = grade,
			this = self,
			lev = lev,
			equipments = equipments,
			lockFlags = lockFlags,
			awake = awake,
			ex_skills = ex_skills,
			isEntrance = self.isEntrance
		})

		self.partner.star = star
	elseif params.partner then
		self.partner = params.partner
		self.tableID = self.partner:getTableID()

		if self.partner.isMonster_ then
			self.tableID = self.partner:getHeroTableID()
		end
	end

	self.currentState = xyd.Global.lang
	self.skillIcons = {}
end

function PartnerInfoWindow:getUIComponent()
	local winTrans = self.window_.transform
	local content = winTrans:NodeByName("content").gameObject
	self.groupMain_ = content:NodeByName("groupMain_").gameObject
	self.detailBg_ = self.groupMain_:ComponentByName("detailBg", typeof(UIWidget))
	self.groupModel = self.groupMain_:NodeByName("groupModel").gameObject
	self.btnWays_ = self.groupMain_:NodeByName("btnWays_").gameObject
	self.groupForce = self.groupMain_:NodeByName("groupForce").gameObject
	self.labelBattlePower = self.groupForce:ComponentByName("labelBattlePower", typeof(UILabel))
	self.labelName = self.groupMain_:ComponentByName("labelName", typeof(UILabel))
	self.jobGroup = self.groupMain_:NodeByName("jobGroup").gameObject
	self.jobIcon = self.jobGroup:ComponentByName("jobIcon", typeof(UISprite))
	self.labelJob = self.jobGroup:ComponentByName("labelJob", typeof(UILabel))
	self.labelJobText = self.jobGroup:ComponentByName("labelJobText", typeof(UILabel))
	self.gradeGroup = self.groupMain_:NodeByName("gradeGroup").gameObject
	self.gradeItemGroup = self.gradeGroup:NodeByName("gradeItemGroup").gameObject
	self.gradeItemGrid = self.gradeItemGroup:GetComponent(typeof(UIGrid))
	self.gradeItem = self.gradeGroup:NodeByName("gradeItem").gameObject

	self.gradeItem:SetActive(false)

	self.labelGrade = self.gradeGroup:ComponentByName("labelGrade", typeof(UILabel))
	self.avatarGroup = self.groupMain_:NodeByName("avatarGroup").gameObject
	self.attr = self.groupMain_:NodeByName("attr").gameObject
	self.labelHp = self.attr:ComponentByName("labelHp", typeof(UILabel))
	self.labelAtk = self.attr:ComponentByName("labelAtk", typeof(UILabel))
	self.labelDef = self.attr:ComponentByName("labelDef", typeof(UILabel))
	self.labelSpd = self.attr:ComponentByName("labelSpd", typeof(UILabel))
	self.attrDetail = self.attr:NodeByName("attrDetail").gameObject
	self.groupAllAttrShow = self.attr:NodeByName("groupAllAttrShow").gameObject
	self.groupAllAttr = self.groupAllAttrShow:NodeByName("groupAllAttr").gameObject
	self.groupAllAttrGrid = self.groupAllAttr:GetComponent(typeof(UIGrid))
	self.skill = self.groupMain_:NodeByName("skill").gameObject
	self.skillGroup = self.skill:NodeByName("skillGroup").gameObject
	self.skillGroupGrid = self.skillGroup:GetComponent(typeof(UIGrid))
	self.skillDesc = self.skill:NodeByName("skillDesc").gameObject
	self.clickToCloseNode = self.skill:NodeByName("clickToCloseNode").gameObject
	self.groupDesc_ = content:NodeByName("groupDesc_").gameObject
	self.descBg = self.groupDesc_:NodeByName("descBg").gameObject
	self.labelDescWays_ = self.groupDesc_:ComponentByName("labelDescWays_", typeof(UILabel))
	self.wayGroup = self.groupDesc_:NodeByName("wayGroup").gameObject
	self.groupWays_ = self.wayGroup:NodeByName("groupWays_").gameObject
	self.groupWaysGrid = self.groupWays_:GetComponent(typeof(UIGrid))
	self.wayBg = self.wayGroup:ComponentByName("wayBg", typeof(UIWidget))
	self.groupAdvertise_ = content:NodeByName("groupAdvertise_").gameObject
	self.groupRecommoned = self.groupAdvertise_:NodeByName("groupRecommoned").gameObject
	self.layoutRecommoned = self.groupRecommoned:NodeByName("layout").gameObject
	self.labelRecommoned = self.layoutRecommoned:ComponentByName("labelRecommoned", typeof(UILabel))
end

function PartnerInfoWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:registerEvent()
end

function PartnerInfoWindow:registerEvent()
	UIEventListener.Get(self.attrDetail).onSelect = function (go, isSelected)
		self.groupAllAttrShow:SetActive(not self.groupAllAttrShow.activeSelf)
	end

	UIEventListener.Get(self.btnWays_).onClick = function ()
		self:getWaysTouch()
	end

	UIEventListener.Get(self.clickToCloseNode).onClick = function ()
		self:clearSkillTips()
		self.clickToCloseNode:SetActive(false)
	end
end

function PartnerInfoWindow:setLayout()
	self:setAvatar()
	self:setText()
	self:setModel()
	self:setGrade()
	self:setSkillItems()

	self.jobIcon.spriteName = "job_icon" .. tostring(self.partner:getJob())

	self:setAttrLabel()
	self.groupAllAttrShow:SetActive(false)

	local ways = xyd.tables.itemTable:getWays(self.tableID)

	if #ways <= 0 or self.notShowWays then
		self.btnWays_:SetActive(false)
	end

	if self.isHideAttr then
		self.attr:SetActive(false)

		self.detailBg_.height = 414

		self.skill.transform:Y(-100)
	end

	if self.isHideForce then
		self.groupForce:SetActive(false)
	end

	if self.isHideWays then
		self.btnWays_:SetActive(false)
	end

	if self.showRecommoned then
		self.groupRecommoned:SetActive(true)

		self.labelRecommoned.text = self.recommonedText

		self.layoutRecommoned:GetComponent(typeof(UILayout)):Reposition()
	end

	self.clickToCloseNode:SetActive(false)
	self:createWays()
	self:extraCheck()
end

function PartnerInfoWindow:setText()
	self.labelName.text = self.partner:getName()
	self.labelBattlePower.text = self.partner:getPower()
	self.labelJobText.text = __("PARTNER_INFO_JOB")
	self.labelJob.text = __("JOB_" .. tostring(self.partner:getJob()))
	self.labelGrade.text = __("PARTNER_INFO_GRADE")
	self.labelDescWays_.text = __("GET_WAYS")
	local attrs = self.partner:getBattleAttrs()
	self.labelHp.text = ": " .. tostring(math.floor(attrs.hp))
	self.labelAtk.text = ": " .. tostring(math.floor(attrs.atk))
	self.labelDef.text = ": " .. tostring(math.floor(attrs.arm))
	self.labelSpd.text = ": " .. tostring(math.floor(attrs.spd))
end

function PartnerInfoWindow:setAvatar()
	NGUITools.DestroyChildren(self.avatarGroup.transform)

	local info = self.partner:getInfo()
	info.noClick = true
	local icon = HeroIcon.new(self.avatarGroup)

	icon:setInfo(info)
end

function PartnerInfoWindow:setModel()
	local modelID = xyd.tables.partnerTable:getModelID(self.tableID)
	local name = xyd.tables.modelTable:getModelName(modelID)
	local scale = xyd.tables.modelTable:getScale(modelID)
	local model = xyd.Spine.new(self.groupModel)
	self.model = model

	model:setInfo(name, function ()
		if self.groupModel then
			model:SetLocalPosition(0, 0, 0)
			model:SetLocalScale(scale, scale, 1)
			model:setRenderTarget(self.groupModel:GetComponent(typeof(UIWidget)), 1)
			model:play("idle", 0)
		end
	end, true)
end

function PartnerInfoWindow:setGrade()
	NGUITools.DestroyChildren(self.gradeItemGroup.transform)

	local grade = self.partner:getGrade()

	for i = 1, self.partner:getMaxGrade() do
		local item = NGUITools.AddChild(self.gradeItemGroup, self.gradeItem)
		local img = item:NodeByName("img").gameObject

		if grade < i then
			img:SetActive(false)
		else
			img:SetActive(true)
		end
	end

	self.gradeItemGrid:Reposition()
end

function PartnerInfoWindow:setSkillItems()
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

	local grade = self.partner:getGrade()

	NGUITools.DestroyChildren(self.skillGroup.transform)

	for key = 1, #skill_ids do
		local needGrade = self.partner:getPasTier(key - 1)
		local icon = SkillIcon.new(self.skillGroup)
		local unlocked = not needGrade or needGrade <= self.partner:getGrade()
		local level = exSkills[key]

		if level and level > 0 then
			skill_ids[key] = xyd.tables.partnerExSkillTable:getExID(skill_ids[key])[level]
		end

		icon:setInfo(skill_ids[key], {
			unlocked = unlocked,
			unlockGrade = needGrade,
			callback = function ()
			end
		})
		icon:setScale(0.9)

		UIEventListener.Get(icon.go).onClick = function ()
			icon:showTips(true, self.skillDesc, 640)
			self.clickToCloseNode:SetActive(true)
		end

		table.insert(self.skillIcons, icon)
	end

	self.skillGroupGrid:Reposition()
end

function PartnerInfoWindow:clearSkillTips()
	for _, icon in ipairs(self.skillIcons) do
		icon:showTips(false, self.skillDesc)
	end
end

function PartnerInfoWindow:getWaysTouch()
	if self.isShowWays == true then
		self:hideWays()
	else
		self:showWays()
	end

	self.isShowWays = not self.isShowWays
end

function PartnerInfoWindow:showWays()
	local verticalCenter1 = (self.wayBg.height + 75) / 2
	local groupMainTrans = self.groupMain_.transform
	local sequence1 = DG.Tweening.DOTween.Sequence()

	sequence1:Insert(0.2, groupMainTrans:DOLocalMoveY(verticalCenter1, 0.1))
	sequence1:AppendCallback(function ()
		sequence1:Kill(false)

		sequence1 = nil
	end)

	local sequence2 = DG.Tweening.DOTween.Sequence()
	local desTransform = self.groupDesc_.transform
	local desWidget = self.groupDesc_:GetComponent(typeof(UIWidget))
	local getter, setter = xyd.getTweenAlphaGeterSeter(desWidget)

	desTransform:SetLocalScale(0.5, 0.5, 0.5)

	desWidget.alpha = 0.5

	self.groupDesc_:SetActive(true)
	sequence1:Insert(0, desTransform:DOLocalMoveY(self.desOriginY + verticalCenter1, 0))
	sequence2:Insert(0.1, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.13))
	sequence2:Insert(0.1, desTransform:DOScale(1.05, 0.13))
	sequence2:Insert(0.23, desTransform:DOScale(1, 0.2))
	sequence2:AppendCallback(function ()
		sequence2:Kill(false)

		sequence2 = nil
	end)
end

function PartnerInfoWindow:hideWays()
	local desTransform = self.groupDesc_.transform
	local sequence1 = DG.Tweening.DOTween.Sequence()
	local getter, setter = xyd.getTweenAlphaGeterSeter(self.groupDesc_:GetComponent(typeof(UIWidget)))

	sequence1:Append(desTransform:DOScale(1.05, 0.13))
	sequence1:Append(desTransform:DOScale(0.5, 0.1))
	sequence1:Join(DG.Tweening.DOTween.ToAlpha(getter, setter, 0.5, 0.1))
	sequence1:AppendCallback(function ()
		self.groupDesc_:SetActive(false)
		sequence1:Kill(false)

		sequence1 = nil
	end)

	local groupMainTrans = self.groupMain_.transform
	local sequence2 = DG.Tweening.DOTween.Sequence()

	sequence2:Insert(0.2, groupMainTrans:DOLocalMoveY(0, 0.1))
	sequence2:AppendCallback(function ()
		sequence2:Kill(false)

		sequence2 = nil
	end)
end

function PartnerInfoWindow:createWays()
	local ways = xyd.tables.itemTable:getWays(self.tableID)

	for _, way in ipairs(ways) do
		local item = SinglePartnerWayItem.new(self.groupWays_, {
			wndType = 1,
			id = way
		})
	end

	local bgHeight = #ways * 90

	if #ways == 1 then
		bgHeight = bgHeight + 5
	end

	self.wayBg.height = bgHeight

	self.groupWaysGrid:Reposition()

	self.desOriginY = self.groupDesc_.transform.localPosition.y
end

function PartnerInfoWindow:setAttrLabel()
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
end

function PartnerInfoWindow:extraCheck()
	local activity_firework_shop_wd = xyd.WindowManager.get():getWindow("activity_firework_shop_window")

	if activity_firework_shop_wd then
		self.btnWays_.gameObject:SetActive(false)

		return
	end

	local choose_partner_debris_wd = xyd.WindowManager.get():getWindow("choose_partner_debris_window")

	if choose_partner_debris_wd then
		self.btnWays_.gameObject:SetActive(false)

		return
	end

	local activity_wnd = xyd.WindowManager.get():getWindow("activity_window")

	if activity_wnd and (xyd.Global.curActivityID == 286 or xyd.Global.curActivityID == 290) then
		self.btnWays_.gameObject:SetActive(false)

		return
	end
end

function PartnerInfoWindow:willClose()
	xyd.WindowManager.get():closeWindow("activity_lasso_awards_window")
	xyd.WindowManager.get():closeWindow("activity_lasso_select_window")
end

return PartnerInfoWindow
