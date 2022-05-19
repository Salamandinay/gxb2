local PotentialitySuccessWindow = class("PotentialitySuccessWindow", import(".BaseWindow"))
local AwakeAttrChangeItem = import(".AwakeOkWindow"):getAwakeAttrChangeItem()
local PotentialAttrChangeItem = class("PotentialAttrChangeItem", AwakeAttrChangeItem)
local PotentialIcon = import("app.components.PotentialIcon")

function PotentialitySuccessWindow:ctor(name, params)
	PotentialitySuccessWindow.super.ctor(self, name, params)

	self.params_ = params
	self.changedAttr_ = params.attrParams
	self.partner_ = params.partner
end

function PotentialitySuccessWindow:playOpenAnimation(callback)
	PotentialitySuccessWindow.super.playOpenAnimation(self, function ()
		local groupAction = self.window_:ComponentByName("groupAction", typeof(UIWidget))
		groupAction.alpha = 0.5

		groupAction.gameObject.transform:SetLocalScale(0.5, 0.5, 0.5)

		local function setter(value)
			groupAction.alpha = value
		end

		local sequence = self:getSequence()

		sequence:Insert(0, groupAction.transform:DOScale(Vector3(1.1, 1.1, 1), 0.13))
		sequence:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0.5, 1, 0.13))
		sequence:Insert(0.13, groupAction.transform:DOScale(Vector3(0.97, 0.97, 0.97), 0.13))
		sequence:Insert(0.26, groupAction.transform:DOScale(Vector3(1, 1, 1), 0.16))
		self:setTimeout(function ()
			local action5 = self:getSequence()

			for idx, item in ipairs(self.attrChangeList_) do
				self:setTimeout(function ()
					item:playAnimation()
				end, self, 200 + idx * 100)
			end

			self:setTimeout(function ()
				self.groupSlot_:SetActive(true)

				local slotWidget = self.groupSlot_:GetComponent(typeof(UIWidget))
				slotWidget.alpha = 0.01

				local function setter2(value)
					slotWidget.alpha = value
				end

				sequence:Insert(0, self.groupSlot_.transform:DOScale(Vector3(1.2, 1.2, 1.2), 0.1))
				sequence:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 0.01, 1, 0.1))
				sequence:Insert(0.1, self.groupSlot_.transform:DOScale(Vector3(0.95, 0.95, 0.95), 0.1))
				sequence:Insert(0.2, self.groupSlot_.transform:DOScale(Vector3(1, 1, 1), 0.1))

				self.canClose_ = true
			end, self, 600)
		end, self, 450)
		xyd.SoundManager.get():playSound(xyd.SoundID.HERO_STAR_UP)

		if callback then
			callback()
		end
	end)
end

function PotentialitySuccessWindow:initWindow()
	PotentialitySuccessWindow.super.initWindow(self)
	self:getComponent()
	self:layoutUI()
end

function PotentialitySuccessWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.touchGroup_ = winTrans:NodeByName("touchGroup").gameObject
	self.effectGroup_ = winTrans:NodeByName("effectGroup").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.clickLabel_ = winTrans:ComponentByName("clickLabel", typeof(UILabel))
	self.starImg_ = winTrans:ComponentByName("group/starImg", typeof(UISprite))
	self.starLabel_ = winTrans:ComponentByName("group/starLabel", typeof(UILabel))
	self.attrChange_ = winTrans:NodeByName("group/attrChange").gameObject
	self.groupSlot_ = winTrans:NodeByName("groupSlot").gameObject
	self.unlockLabel = self.groupSlot_:ComponentByName("unlockLabel", typeof(UILabel))

	for i = 1, 4 do
		self["line" .. i] = self.groupSlot_:ComponentByName("line" .. i, typeof(UISprite))
	end
end

function PotentialitySuccessWindow:layoutUI()
	local star = self.partner_:getStar()
	self.starLabel_.text = tostring(star - 10)
	self.titleLabel_.text = __("POTENTIALITY_SUCCESS_TITLE")
	self.clickLabel_.text = __("POTENTIALITY_CLICK_CLOSE")
	self.unlockLabel.text = __("POTENTIALITY_UNLOCK_SLOT")

	self:initEffect()
	self:initPotentialityGroup()
	self:initSkillIconLineLayout()
	self:initAttrChange()

	UIEventListener.Get(self.touchGroup_).onClick = function ()
		if self.canClose_ then
			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end

	local str = "potentiality_star_icon"
	local group = self.partner_:getGroup()

	if group and group > 0 then
		str = xyd.checkPartnerGroupImgStr(group, str)
	end

	xyd.setUISpriteAsync(self.starImg_, nil, str, function ()
		self.starImg_:MakePixelPerfect()
	end)
end

function PotentialitySuccessWindow:initEffect()
	local effect = xyd.Spine.new(self.effectGroup_)

	effect:setInfo("fx_ui_13xing_tanchuang", function ()
		effect:play("texiao01", 1, 1, function ()
			effect:play("texiao02", 0, 1)
		end)
	end)
end

function PotentialitySuccessWindow:initSkillIconLineLayout()
	local star = self.partner_:getStar()

	for i = 1, 4 do
		if i < star - 10 then
			xyd.setUISpriteAsync(self["line" .. i], nil, "partner_potential_light_big")
		else
			xyd.setUISpriteAsync(self["line" .. i], nil, "partner_potential_dark_big")
		end
	end
end

function PotentialitySuccessWindow:initPotentialityGroup()
	local star = self.partner_:getStar()
	local skillList = self.partner_:getPotentialByOrder()
	local activeStatus = self.partner_:getActiveIndex()

	for i = 1, 5 do
		local group = self.groupSlot_:NodeByName("potentialityGroup" .. i).gameObject
		local icon = PotentialIcon.new(group)
		local params = {}
		local id = -1
		local ind = star - 10

		if i > ind then
			params.is_lock = true
			params.is_mask = true
		elseif i == ind then
			params.is_unlocking = true
		end

		params.scale = 0.73

		icon:setInfo(id, params)
	end
end

function PotentialitySuccessWindow:initAttrChange()
	self.attrChangeList_ = {}

	NGUITools.DestroyChildren(self.attrChange_.transform)

	for i = 1, #self.changedAttr_ do
		local item = PotentialAttrChangeItem.new(self.attrChange_, self.changedAttr_[i])

		table.insert(self.attrChangeList_, item)
	end
end

function PotentialitySuccessWindow:willClose()
	PotentialitySuccessWindow.super.willClose(self)

	local items = self.params_.items

	if items and #items > 0 then
		xyd.alertItems(items, nil, __("GET_ITEMS"))
	end
end

function PotentialAttrChangeItem:ctor(parentGo, params)
	PotentialAttrChangeItem.super.ctor(self, parentGo, params)

	self.desc_.alpha = 0.01
	self.attrBefore.alpha = 0.01
	self.attrAfter.alpha = 0.01
	self.arrow.alpha = 0.01
	self.descBg:GetComponent(typeof(UISprite)).alpha = 0.01
end

function PotentialAttrChangeItem:getPrefabPath()
	return "Prefabs/Components/potential_attrChange_item"
end

return PotentialitySuccessWindow
