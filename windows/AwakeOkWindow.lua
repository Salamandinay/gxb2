local BaseWindow = import(".BaseWindow")
local AwakeOkWindow = class("AwakeOkWindow", BaseWindow)
local AwakeAttrChangeItem = class("AwakeAttrChangeItem", import("app.components.BaseComponent"))
local SkillIcon = import("app.components.SkillIcon")
local HeroIcon = import("app.components.HeroIcon")

function AwakeOkWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.targetList = {}
	self.params = params
	self.changedAttr = params.attrParams
	self.partner_ = params.partner
	self.isShenxue = params.isShenxue or 0
	self.changedAttrItem = {}
end

function AwakeOkWindow:getAwakeAttrChangeItem()
	return AwakeAttrChangeItem
end

function AwakeOkWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.mainGroup_ = winTrans:ComponentByName("main", typeof(UIWidget))
	self.maskTouch_ = winTrans:NodeByName("maskTouch").gameObject
	self.winBg_ = winTrans:ComponentByName("main/content/e:Image", typeof(UISprite))
	local content = self.window_:NodeByName("main/content").gameObject
	self.heroChange = content:NodeByName("heroChange").gameObject
	local heroBeforeContainer = self.heroChange:NodeByName("heroBefore").gameObject
	self.heroBefore = HeroIcon.new(heroBeforeContainer)
	local heroAfterContainer = self.heroChange:NodeByName("heroAfter").gameObject
	self.heroAfter = HeroIcon.new(heroAfterContainer)
	self.labelAttr = content:NodeByName("labelAttr").gameObject
	self.attrUp = self.labelAttr:ComponentByName("attrUp", typeof(UILabel))
	self.attrChange = content:NodeByName("attrChange").gameObject
	self.labelSkill = content:NodeByName("labelSkill").gameObject
	self.skillUp = self.labelSkill:ComponentByName("skillUp", typeof(UILabel))
	self.skillGroup = content:NodeByName("skillGroup").gameObject
	self.skillBefore = self.skillGroup:NodeByName("skillBefore").gameObject
	self.skillBeforeLine1 = self.skillBefore:NodeByName("line1").gameObject
	self.skillBeforeLine2 = self.skillBefore:NodeByName("line2").gameObject
	self.skillAfter = self.skillGroup:NodeByName("skillAfter").gameObject
	self.skillAfterLine1 = self.skillAfter:NodeByName("line1").gameObject
	self.skillAfterLine2 = self.skillAfter:NodeByName("line2").gameObject
	self.skillItem = self.skillGroup:NodeByName("skillItem").gameObject
	local top = winTrans:NodeByName("main/top").gameObject
	self.labelTitle = top:ComponentByName("labelTitle", typeof(UILabel))
	self.skillDesc = winTrans:NodeByName("skillDesc").gameObject
end

function AwakeOkWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	self.labelTitle.text = __("AWAKE_UP")
	self.skillUp.text = __("SKILL_UP")
	self.attrUp.text = __("ATTR_UP2")
	local awake = self.partner_:getAwake()

	if self.params.formerPartner then
		self.heroBefore:setInfo({
			tableID = self.params.formerPartner:getTableID(),
			star = self.params.formerPartner:getStar(),
			lev = self.params.formerPartner:getLevel()
		})
	else
		self.heroBefore:setInfo({
			tableID = self.partner_:getTableID(),
			star = self.partner_:getStar() - 1,
			lev = self.partner_:getLevel()
		})
	end

	self.heroAfter:setInfo({
		tableID = self.partner_:getTableID(),
		star = self.partner_:getStar(),
		lev = self.partner_:getLevel()
	})

	for i = 1, #self.changedAttr do
		local item = self:initAttrItem(self.changedAttr[i])

		table.insert(self.changedAttrItem, item)
	end

	if self.isShenxue == 0 then
		NGUITools.DestroyChildren(self.skillBeforeLine1.transform)
		NGUITools.DestroyChildren(self.skillBeforeLine2.transform)
		NGUITools.DestroyChildren(self.skillAfterLine1.transform)
		NGUITools.DestroyChildren(self.skillAfterLine2.transform)

		local skillNum = #self.params.skillOldList

		for i = 1, math.min(2, skillNum) do
			local skillItem = NGUITools.AddChild(self.skillBeforeLine1, self.skillItem)
			skillItem:GetComponent(typeof(UIWidget)).depth = 250 + i * 10
			self["oldSkill" .. i] = SkillIcon.new(skillItem)

			self["oldSkill" .. i]:setInfo(self.params.skillOldList[i], {
				showLev = true,
				showGroup = self.skillDesc,
				callback = function ()
					self:showSkillTips(self["oldSkill" .. i])
				end
			})
		end

		for i = 3, skillNum do
			local skillItem = NGUITools.AddChild(self.skillBeforeLine2, self.skillItem)
			skillItem:GetComponent(typeof(UIWidget)).depth = 250 + i * 10
			self["oldSkill" .. i] = SkillIcon.new(skillItem)

			self["oldSkill" .. i]:setInfo(self.params.skillOldList[i], {
				showLev = true,
				showGroup = self.skillDesc,
				callback = function ()
					self:showSkillTips(self["oldSkill" .. i])
				end
			})
		end

		skillNum = #self.params.skillNewList

		for i = 1, math.min(2, skillNum) do
			local skillItem = NGUITools.AddChild(self.skillAfterLine1, self.skillItem)
			skillItem:GetComponent(typeof(UIWidget)).depth = 250 + i * 10
			self["newSkill" .. i] = SkillIcon.new(skillItem)

			self["newSkill" .. i]:setInfo(self.params.skillNewList[i], {
				showLev = true,
				showGroup = self.skillDesc,
				callback = function ()
					self:showSkillTips(self["newSkill" .. i])
				end
			})
		end

		for i = 3, skillNum do
			local skillItem = NGUITools.AddChild(self.skillAfterLine2, self.skillItem)
			skillItem:GetComponent(typeof(UIWidget)).depth = 250 + i * 10
			self["newSkill" .. i] = SkillIcon.new(skillItem)

			self["newSkill" .. i]:setInfo(self.params.skillNewList[i], {
				showLev = true,
				showGroup = self.skillDesc,
				callback = function ()
					self:showSkillTips(self["newSkill" .. i])
				end
			})
		end

		self.skillBeforeLine1:GetComponent(typeof(UILayout)):Reposition()
		self.skillBeforeLine2:GetComponent(typeof(UILayout)):Reposition()
		self.skillAfterLine1:GetComponent(typeof(UILayout)):Reposition()
		self.skillAfterLine2:GetComponent(typeof(UILayout)):Reposition()

		if skillNum == 4 then
			self.skillBefore:X(-21)
			self.skillAfter:X(-21)
		else
			self.skillBefore:X(0)
			self.skillAfter:X(0)
		end

		if skillNum < 3 then
			self.skillBeforeLine1:Y(2)
			self.skillAfterLine1:Y(2)
		else
			self.skillBeforeLine1:Y(15)
			self.skillAfterLine1:Y(15)
		end
	elseif self.isShenxue == 1 then
		self.skillGroup:SetActive(false)
		self.labelSkill:SetActive(false)
	end

	self:registerSkillDesc()
end

function AwakeOkWindow:registerSkillDesc()
	local skillNum = 0

	if self.params.skillOldList then
		skillNum = #self.params.skillOldList
	end

	for i = 1, skillNum do
		UIEventListener.Get(self["oldSkill" .. i].go).onSelect = function (go, isSelect)
			if isSelect == false then
				self:cancelSkillTips()
			end
		end
	end

	if self.params.skillNewList then
		skillNum = #self.params.skillNewList
	end

	for i = 1, skillNum do
		UIEventListener.Get(self["newSkill" .. i].go).onSelect = function (go, isSelect)
			if isSelect == false then
				self:cancelSkillTips()
			end
		end
	end
end

function AwakeOkWindow:showSkillTips(icon)
	self:cancelSkillTips()

	if not icon then
		return
	end

	self.showSkillIcon = icon

	icon:showTips(true, icon.showGroup, true)
end

function AwakeOkWindow:cancelSkillTips()
	if self.showSkillIcon then
		self.showSkillIcon:showTips(false, self.showSkillIcon.showGroup)
	end
end

function AwakeOkWindow:willClose()
	BaseWindow.willClose(self)

	local function func()
		local win = xyd.WindowManager.get():getWindow("partner_detail_window")

		if win then
			local partner = win:getCurPartner()
			local dialog = xyd.tables.partnerTable:getAwakeDialogInfo(partner:getTableID(), partner:getSkinID())

			if self.isShenxue == 1 then
				dialog = xyd.tables.partnerTable:getShenXueDialogInfo(partner:getTableID(), partner:getSkinID())
			end

			win:playSound(dialog)
		end
	end

	local items = self.params.items

	xyd.models.itemFloatModel:pushNewItems(items)
	func()
end

function AwakeOkWindow:playOpenAnimation(callback)
	AwakeOkWindow.super.playOpenAnimation(self, function ()
		if callback then
			callback()
		end

		self.maskTouch_:SetActive(true)

		local heroChange = self.heroChange:GetComponent(typeof(UIWidget))
		local labelAttr = self.labelAttr:GetComponent(typeof(UIWidget))
		local skillGroup = self.skillGroup:GetComponent(typeof(UIWidget))
		local labelSkill = self.labelSkill:GetComponent(typeof(UIWidget))
		local mainGroup = self.mainGroup_
		heroChange.alpha = 0
		labelAttr.alpha = 0

		if self.isShenxue == 0 then
			skillGroup.alpha = 0
			labelSkill.alpha = 0
		end

		mainGroup.alpha = 0.5

		mainGroup:SetLocalScale(0.5, 0.5, 0.5)

		local sequence = self:getSequence()

		local function setter(value)
			mainGroup.alpha = value
		end

		sequence:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 1, 0.13))
		sequence:Insert(0, mainGroup.transform:DOScale(Vector3(1.1, 1.1, 1.1), 0.13))
		sequence:Insert(0.13, mainGroup.transform:DOScale(Vector3(0.97, 0.97, 0.97), 0.13))
		sequence:Insert(0.26, mainGroup.transform:DOScale(Vector3(1, 1, 1), 0.16))

		self.winBg_.alpha = 0

		local function setter1(value)
			self.winBg_.alpha = value
		end

		sequence:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, 1, 0.1))
		self:setTimeout(function ()
			local sequence2 = self:getSequence(function ()
				self.maskTouch_:SetActive(false)
			end)

			local function setter2(value)
				heroChange.alpha = value
			end

			local function setter3(value)
				labelAttr.alpha = value
			end

			sequence2:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0, 1, 0.1))
			sequence2:Insert(0, heroChange.transform:DOScale(Vector3(1.1, 1.1, 1.1), 0.1))
			sequence2:Insert(0.1, heroChange.transform:DOScale(Vector3(0.97, 0.97, 0.97), 0.1))
			sequence2:Insert(0.2, heroChange.transform:DOScale(Vector3(1, 1, 1), 0.1))
			sequence2:Insert(0.1, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 0, 1, 0.1))

			for i = 1, #self.changedAttrItem do
				self:setTimeout(function ()
					self.changedAttrItem[i]:playAnimation()
				end, nil, 200 + 100 * i)
			end

			if self.isShenxue == 0 then
				local function setter4(value)
					labelSkill.alpha = value
				end

				local function setter5(value)
					skillGroup.alpha = value
				end

				sequence2:Insert(0.7, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter4), 0, 1, 0.1))
				sequence2:Insert(0.7, skillGroup.transform:DOScale(Vector3(1.1, 1.1, 1.1), 0.1))
				sequence2:Insert(0.8, skillGroup.transform:DOScale(Vector3(0.97, 0.97, 0.97), 0.1))
				sequence2:Insert(0.9, skillGroup.transform:DOScale(Vector3(1, 1, 1), 0.1))
				sequence2:Insert(0.7, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter5), 0, 1, 0.1))
			else
				sequence2:Insert(0.7, skillGroup.transform:DOScale(Vector3(1, 1, 1), 0.1))
			end
		end, nil, 450)
		xyd.SoundManager.get():playSound(xyd.SoundID.HERO_STAR_UP)
	end)
end

function AwakeOkWindow:initAttrItem(params)
	return AwakeAttrChangeItem.new(self.attrChange, params)
end

function AwakeOkWindow:attrAction(g)
	local label1 = g:getChildByName("desc_")
	local label2 = g:getChildByName("attrBefore")
	local label3 = g:getChildByName("attrAfter")
	local arrow = g:getChildByName("arrow")
	local pos = arrow.transform.localPosition
	arrow.transform.localPosition = Vector3(pos.x - 10, pos.y, pos.z)
	local action = self:getSequence()

	local function setter1(value)
		label1.alpha = value
	end

	local function setter2(value)
		label2.alpha = value
	end

	local function setter3(value)
		label3.alpha = value
	end

	local function setter4(value)
		arrow.alpha = value
	end

	action:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0.01, 1, 0.1))
	action:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0.01, 1, 0.1))
	action:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 0.01, 1, 0.1))
	action:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter4), 0.5, 1, 0.13))
	action:Insert(0, arrow.transform:DOLocalMove(Vector3(pos.x + 10, pos.y, pos.z), 0.13))
	action:Insert(0.13, arrow.transform:DOLocalMove(Vector3(pos.x, pos.y, pos.z), 0.07))
end

function AwakeAttrChangeItem:ctor(parentGo, params)
	AwakeAttrChangeItem.super.ctor(self, parentGo)

	self.params = params

	self:initParams()
end

function AwakeAttrChangeItem:getPrefabPath()
	return "Prefabs/Components/awake_attr_change"
end

function AwakeAttrChangeItem:initUI()
	AwakeAttrChangeItem.super.initUI(self)

	self.go:GetComponent(typeof(UIWidget)).alpha = 0
	self.descBg = self.go:NodeByName("descBg").gameObject
	self.desc_ = self.go:ComponentByName("desc_", typeof(UILabel))
	self.attrBefore = self.go:ComponentByName("attrBefore", typeof(UILabel))
	self.attrAfter = self.go:ComponentByName("attrAfter", typeof(UILabel))
	self.arrow = self.go:ComponentByName("arrow", typeof(UISprite))
end

function AwakeAttrChangeItem:initParams()
	self.desc_.text = __(string.upper(self.params[1]))
	self.attrBefore.text = self.params[2]
	self.attrAfter.text = self.params[3]
end

function AwakeAttrChangeItem:playAnimation()
	local label1 = self.desc_
	local label2 = self.attrBefore
	local label3 = self.attrAfter
	local arrow = self.arrow
	self.go:GetComponent(typeof(UIWidget)).alpha = 1
	local pos = arrow.transform.localPosition
	arrow.transform.localPosition = Vector3(pos.x - 10, pos.y, pos.z)
	local action = self:getSequence()

	local function setter1(value)
		label1.alpha = value
	end

	local function setter2(value)
		label2.alpha = value
	end

	local function setter3(value)
		label3.alpha = value
	end

	local function setter4(value)
		arrow.alpha = value
	end

	local function setter5(value)
		self.descBg:GetComponent(typeof(UISprite)).alpha = value
	end

	action:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0.01, 1, 0.1))
	action:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0.01, 1, 0.1))
	action:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 0.01, 1, 0.1))
	action:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter4), 0.5, 1, 0.13))
	action:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter5), 0.01, 1, 0.1))
	action:Insert(0, arrow.transform:DOLocalMove(Vector3(pos.x + 10, pos.y, pos.z), 0.13))
	action:Insert(0.13, arrow.transform:DOLocalMove(Vector3(pos.x, pos.y, pos.z), 0.07))
end

return AwakeOkWindow
