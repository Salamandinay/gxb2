local BaseWindow = import(".BaseWindow")
local SkinTipWindow = class("SkinTipWindow", BaseWindow)
local PlayerIcon = import("app.components.PlayerIcon")
local ItemIcon = import("app.components.ItemIcon")

function SkinTipWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinID = params.skin_id
	self.tableID = params.tableID

	dump(params, "test")
end

function SkinTipWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupMain = winTrans:NodeByName("groupMain").gameObject
	self.detailBg = self.groupMain:NodeByName("detailBg").gameObject
	self.detailBgWidget = self.detailBg:GetComponent(typeof(UIWidget))
	self.groupAvatar = self.groupMain:NodeByName("groupAvatar").gameObject
	self.groupAvatarWidget = self.groupAvatar:GetComponent(typeof(UIWidget))
	self.labelName = self.groupMain:ComponentByName("labelName", typeof(UILabel))
	self.labelText01 = self.groupMain:ComponentByName("labelText01", typeof(UILabel))
	self.groupText = self.groupMain:NodeByName("groupText").gameObject
	self.labelAttr = self.groupText:ComponentByName("labelAttr", typeof(UILabel))
	self.labelAttrWidget = self.labelAttr:GetComponent(typeof(UIWidget))
	self.labelText02 = self.groupText:ComponentByName("labelText02", typeof(UILabel))
	self.labelOwn = self.groupMain:ComponentByName("labelOwn", typeof(UILabel))
end

function SkinTipWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
end

function SkinTipWindow:setLayout()
	self.labelText01.text = __("SKIN")

	if not self.skinID and not self.tableID then
		return
	end

	local type = xyd.tables.itemTable:getType(self.skinID)

	if type == xyd.ItemType.SKIN then
		local itemType = xyd.tables.itemTable:getType(self.tableID)

		if itemType == xyd.ItemType.HERO and xyd.tables.partnerTable:getGroup(self.tableID) == xyd.PartnerGroup.TIANYI then
			local partnerShowIds = xyd.tables.partnerTable:getShowIdsWithNum(self.tableID)

			if xyd.arrayIndexOf(partnerShowIds, self.skinID) > 1 then
				type = xyd.ItemType.HERO
			end
		end
	end

	if type == xyd.ItemType.SKIN then
		self.labelName.text = xyd.tables.equipTextTable:getName(self.skinID)

		xyd.labelQulityColor(self.labelName, self.skinID)

		self.labelAttr.text = xyd.tables.equipTable:getDesc(self.skinID)
		self.labelText02.text = xyd.tables.itemTable:getDesc(self.skinID)

		if self.labelText02.width >= 440 then
			self.labelText02.overflowMethod = UILabel.Overflow.ResizeHeight
			self.labelText02.width = 440
		end

		self.detailBgWidget.height = 170 + self.labelAttrWidget.height + 50 + self.labelText02.height - 22
		local avatar = xyd.getItemIcon({
			noClick = true,
			itemID = self.skinID,
			uiRoot = self.groupAvatar,
			scale = Vector3(0.9, 0.9, 1)
		})
		self.labelOwn.text = __("ITEM_HAS_NUM", xyd.models.slot:getSkinTotalNum(self.skinID))
	else
		local name = xyd.tables.partnerTable:getName(self.tableID)
		self.labelName.text = name
		local maxStar = xyd.tables.partnerTable:getStar(self.skinID and self.skinID or self.tableID)
		local tmpText = nil

		if maxStar == 5 then
			tmpText = __("SKIN_TEXT06", name)
		elseif maxStar == 6 then
			tmpText = __("SKIN_TEXT16", name)
		elseif maxStar == 10 then
			tmpText = __("SKIN_TEXT17", name)
		else
			tmpText = __("SKIN_TEXT06", name)
		end

		self.labelAttr.text = tmpText
		self.labelText02.text = ""
		self.detailBgWidget.height = 170 + self.labelAttrWidget.height + 14
		local avatar = PlayerIcon.new(self.groupAvatar)

		if not self.skinID then
			avatar:setInfo({
				avatarID = self.tableID
			})
		else
			avatar:setInfo({
				avatarID = self.skinID
			})
		end

		avatar:setScale(self.groupAvatarWidget.width / avatar.go:GetComponent(typeof(UIWidget)).width)

		self.labelOwn.text = ""

		if self.skinID then
			local itemType = xyd.tables.itemTable:getType(self.tableID)

			if itemType == xyd.ItemType.HERO and xyd.tables.partnerTable:getGroup(self.tableID) == xyd.PartnerGroup.TIANYI then
				local partnerShowIds = xyd.tables.partnerTable:getShowIdsWithNum(self.tableID)
				local index = xyd.arrayIndexOf(partnerShowIds, self.skinID)

				if index == 1 then
					self.labelAttr.text = __("SKIN_TEXT06", name)
				elseif index > 1 then
					self.labelAttr.text = xyd.tables.itemTable:getDesc(self.skinID)
				end
			end
		end
	end
end

return SkinTipWindow
