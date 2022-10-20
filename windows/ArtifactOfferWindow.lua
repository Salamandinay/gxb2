local BaseWindow = import(".BaseWindow")
local ArtifactOfferWindow = class("ArtifactOfferWindow", BaseWindow)
local ItemIcon = import("app.components.ItemIcon")
local SelectNum = import("app.components.SelectNum")

function ArtifactOfferWindow:ctor(name, params)
	if params == nil then
		params = nil
	end

	self.callback = nil
	self.isBackpack = false
	self.isSmithy = false
	self.wndType_ = xyd.ItemTipsWndType.NORMAL

	ArtifactOfferWindow.super.ctor(self, name, params)

	self.backpackModel = xyd.models.backpack
	self.data = params
	self.itemID = params.itemID or 0
	self.itemNum = params.itemNum or 0
	self.itemTable = xyd.tables.itemTable
	self.curNum_ = 1

	if self.itemID then
		self.type = self.itemTable:getType(self.itemID)
	end

	if params.tipsLabelText then
		self.tipsLabelText = params.tipsLabelText
	end

	if params.maxLimitNum then
		self.maxLimitNum = params.maxLimitNum
	end

	if params.maxLimitTips then
		self.maxLimitTips = params.maxLimitTips
	end

	if params.curNumInit then
		self.curNumInit = params.curNumInit
	end

	if params.minNum then
		self.minNum = params.minNum
	end
end

function ArtifactOfferWindow:getUIComponent()
	local winTrans = self.window_.transform
	local main = winTrans:NodeByName("groupAction/main").gameObject
	self.groupMain_ = main:GetComponent(typeof(UIWidget))
	self.labelName_ = main:ComponentByName("labelName_", typeof(UILabel))
	local groupIcon_ = main:NodeByName("groupIcon_").gameObject
	self.groupIcon_ = ItemIcon.new(groupIcon_)
	self.labelType_ = main:ComponentByName("labelType_", typeof(UILabel))
	self.groupDesc_ = main:NodeByName("groupDesc_").gameObject
	self.btnBotMid_ = main:NodeByName("groupMid_/btnBotMid_").gameObject
	self.btnBotMidLabel = self.btnBotMid_:ComponentByName("button_label", typeof(UILabel))
	self.btnSummon_ = main:NodeByName("e:Group/btnSummon_").gameObject
	self.btnSummonLabel = self.btnSummon_:ComponentByName("button_label", typeof(UILabel))
	self.tipsLabel_ = main:ComponentByName("selectNum_/label", typeof(UILabel))
	local selectNum_ = main:NodeByName("selectNum_").gameObject
	self.selectNum_ = SelectNum.new(selectNum_, "minmax")
end

function ArtifactOfferWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setInfo(self.params_)
end

function ArtifactOfferWindow:layout()
	local name = self.itemTable:getName(self.itemID)
	self.labelName_.text = name

	if self.tipsLabelText then
		self.tipsLabel_.text = self.tipsLabelText
	else
		self.tipsLabel_.text = __("PUT_IN_NUM")
	end

	xyd.labelQulityColor(self.labelName_, self.itemID)

	local brief = self.itemTable:getBrief(self.itemID)

	if xyd.tables.itemTable:getType(self.itemID) == xyd.ItemType.HERO_RANDOM_DEBRIS then
		self.labelType_:SetActive(false)
	else
		self.labelType_:SetActive(true)

		self.labelType_.text = brief

		xyd.setBgColorType(self.btnBotMid_, xyd.ButtonBgColorType.white_btn_70_70)
	end

	if xyd.tables.itemTable:getType(self.itemID) == xyd.ItemType.ARTIFACT_DEBRIS then
		xyd.setBgColorType(self.btnBotMid_, xyd.ButtonBgColorType.blue_btn_70_70)
	end

	self:initIcon()
	self:initDesc()
	self:changeMainSize()

	if not self.maxLimitNum then
		self.maxNum = self.itemNum
	else
		self.maxNum = self.maxLimitNum
	end

	self.btnSummonLabel.text = __("SURE")

	self:initTextInput()
	self:registerEvent()
end

function ArtifactOfferWindow:initIcon()
	self.groupIcon_:setInfo({
		{
			noClick = true
		},
		itemID = self.itemID
	})
	self.groupIcon_:setScale(0.9)
end

function ArtifactOfferWindow:getDesc()
	local desc = ""
	local color = 4294967295.0

	if self.showBagType_ == xyd.BackpackShowType.EQUIP or self.showBagType_ == xyd.BackpackShowType.ARTIFACT or xyd.tables.itemTable:getType(self.itemID) == xyd.ItemType.CRYSTAL or self.showBagType_ == xyd.BackpackShowType.SKIN then
		desc = self.equipTable:getDesc(self.itemID)
		color = 472201471
	else
		desc = self.itemTable:getDesc(self.itemID)
		color = 1549556991
	end

	return {
		text = desc,
		color = color
	}
end

function ArtifactOfferWindow:initDesc()
	local data = self:getDesc()
	local itemSoulEquipMaterial = xyd.tables.miscTable:split2Cost("soul_equip2_sp_item", "value", "#")
	local itemSoulEquipID = itemSoulEquipMaterial[1]

	if data.text ~= "" then
		local label = xyd.getLabel({
			w = 420,
			s = 22,
			uiRoot = self.groupDesc_,
			c = data.color,
			t = data.text
		})
		label.spacingY = 5

		table.insert(self.descs_, label)
	end

	if self.itemTable:getType(self.itemID) == xyd.ItemType.DRESS_FRAGMENT then
		-- Nothing
	elseif self.itemID ~= itemSoulEquipID then
		self:showArtifactDesc()
	end

	local offY = 8

	for i = 1, #self.descs_ do
		local label = self.descs_[i]
		label.pivot = UIWidget.Pivot.TopLeft

		if i == 1 then
			label.height = label.height + 8
		end

		offY = offY + label.height + 13
	end

	self.descOffY = offY
end

function ArtifactOfferWindow:showArtifactDesc()
	local group = self.equipTable:getGroup(self.itemID)
	local job = self.equipTable:getJob(self.itemID)

	if group > 0 or job > 0 then
		local isGroup = group > 0
		local limitStr = isGroup and xyd.tables.groupTable:getName(group) or xyd.tables.jobTable:getName(job)
		local text = __("ARTIFACT_ATTR_LIMIT", limitStr)
		local label = xyd.getLabel({
			b = true,
			c = 2593823487.0,
			w = 432,
			s = 22,
			uiRoot = self.groupDesc_,
			t = text
		})

		table.insert(self.descs_, label)

		local acts = self.equipTable:getAct(self.itemID)

		for _, act in ipairs(acts) do
			local text1 = xyd.tables.dBuffTable:translationDesc(act)
			local label1 = xyd.getLabel({
				b = true,
				c = 2593823487.0,
				w = 432,
				s = 22,
				uiRoot = self.groupDesc_,
				t = text1
			})

			if self.data.equipedPartner then
				local partner = self.data.equipedPartner
				local p_group = partner:getGroup()
				local p_job = partner:getJob()
				local isFit = isGroup and group == p_group or job == p_job

				if isFit then
					label1.textColor = 2986409983.0
					label.textColor = 3613720831.0
				end
			end

			table.insert(self.descs_, label1)
		end
	end
end

function ArtifactOfferWindow:initTextInput()
	local callback = handler(self, function (self, num)
		self.curNum_ = num
	end)
	local addCallback = handler(self, function (self)
	end)
	local delCallback, maxCallback = nil

	if self.maxLimitTips ~= nil then
		maxCallback = handler(self, function (self)
			xyd.alertTips(self.maxLimitTips)
		end)
	end

	local minCallback = nil
	local params = {
		curNum = 1,
		minNum = 1,
		maxNum = self.maxNum,
		callback = callback,
		maxCallback = maxCallback
	}

	if self.curNumInit then
		params.curNum = self.curNumInit
	end

	if self.minNum then
		params.minNum = self.minNum
	end

	if self.minNum == 0 then
		params.delForceZero = true
	end

	self.selectNum_:setInfo(params)

	self.selectNum_.promptLabel.text = __("PUT_IN_NUM")
end

function ArtifactOfferWindow:registerEvent()
	UIEventListener.Get(self.btnSummon_).onClick = handler(self, self.onClickOK)
end

function ArtifactOfferWindow:onClickOK()
	if self.params_.callback then
		print(self.curNum_)

		if self.curNum_ > 0 then
			self.params_.callback(self.curNum_)
		elseif self.minNum and self.minNum == 0 then
			self.params_.callback(self.curNum_)
		end

		self:onClickCloseButton()
	end
end

function ArtifactOfferWindow:setInfo(params)
	self.data = params
	self.itemID = params.itemID or 0
	self.itemNum = params.itemNum or 0
	self.callback = params.callback
	self.smallTips_ = params.smallTips or ""
	self.wndType_ = params.wndType or xyd.ItemTipsWndType.NORMAL
	self.itemTable = xyd.tables.itemTable
	self.equipTable = xyd.tables.equipTable
	self.changeY = 0
	self.descs_ = {}
	self.groupMainCurY = 0
	self.descOffY = 0
	self.showBagType_ = self.itemTable:showInBagType(self.itemID)
	self.type_ = self.itemTable:getType(self.itemID)

	self:layout()
	self:registerEvent()
end

function ArtifactOfferWindow:changeMainSize()
	self.groupMain_.height = self.groupMain_.height + self.changeY + self.descOffY - 13
end

return ArtifactOfferWindow
