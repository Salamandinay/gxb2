local SettingUpInfoWindow = class("SettingUpInfoWindow", import(".BaseWindow"))
local SettingUpInfoItem = class("SettingUpInfoItem", import("app.components.BaseComponent"))
local SettingUpGroupBuffItem = class("SettingUpGroupBuffItem", import("app.components.BaseComponent"))
local SettingUpGroupBuffSortItem = class("SettingUpGroupBuffSortItem", import("app.components.BaseComponent"))
local SettingUpGroupBuffSortIconItem = class("SettingUpGroupBuffSortIconItem", import("app.components.CopyComponent"))
local GroupBuffIcon = import("app.components.GroupBuffIcon")

function SettingUpInfoWindow:ctor(name, params)
	SettingUpInfoWindow.super.ctor(self, name, params)

	self.curIndex_ = 1
	self.tapType = {
		FAQ = 2,
		HELP = 1
	}
	self.btnIDs_ = {
		"btnHelp_",
		"btnFAQ_"
	}
	self.FAQItems_ = {}
	self.helpItems_ = {}
	self.scrollPos_ = {}
end

function SettingUpInfoWindow:initWindow()
	SettingUpInfoWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.labelTitle_ = winTrans:ComponentByName("content/groupTop/labelHelpTitle", typeof(UILabel))
	self.btnClose = winTrans:ComponentByName("content/groupTop/closeBtn", typeof(UISprite)).gameObject
	self.scrollViewHelp_ = winTrans:ComponentByName("content/scrollViewHelp", typeof(UIScrollView))
	self.panel_ = self.scrollViewHelp_:GetComponent(typeof(UIPanel))
	self.tableHelp_ = winTrans:ComponentByName("content/scrollViewHelp/listTableHelp", typeof(UITable))
	self.scrollViewFAQ_ = winTrans:ComponentByName("content/scrollViewFAQ", typeof(UIScrollView))
	self.tableFAQ_ = winTrans:ComponentByName("content/scrollViewFAQ/listTableFAQ", typeof(UITable))
	self.dragBg_ = winTrans:ComponentByName("content/midImg", typeof(UIDragScrollView))
	self.nav_ = winTrans:NodeByName("content/groupNav").gameObject

	self:layout()

	UIEventListener.Get(self.btnClose).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function SettingUpInfoWindow:playOpenAnimation(callback)
	SettingUpInfoWindow.super.playOpenAnimation(self, function ()
		self.tab = import("app.common.ui.CommonTabBar").new(self.nav_, 2, function (index)
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
			self:updateShow(index)
		end)

		self.tab:setTexts({
			__("SETTING_UP_HELP"),
			"FAQ"
		})
		self:updateShow(1)

		if callback then
			callback()
		end
	end)
end

function SettingUpInfoWindow:layout()
	self.labelTitle_.text = __("SETTING_UP_HELP")
end

function SettingUpInfoWindow:updateShow(index)
	if index then
		self.curIndex_ = index
	end

	if self.curIndex_ == self.tapType.HELP then
		self.scrollViewHelp_.gameObject:SetActive(true)
		self.scrollViewFAQ_.gameObject:SetActive(false)

		self.dragBg_.scrollView = self.scrollViewHelp_

		self:initHelp()
	elseif self.curIndex_ == self.tapType.FAQ then
		self.scrollViewHelp_.gameObject:SetActive(false)
		self.scrollViewFAQ_.gameObject:SetActive(true)

		self.dragBg_.scrollView = self.scrollViewFAQ_

		self:initFAQ()
	end
end

function SettingUpInfoWindow:initHelp()
	local strIDs = xyd.tables.settingTable:getStrIDsbyType(1)

	table.sort(strIDs, function (a, b)
		return tonumber(a) < tonumber(b)
	end)

	local widget = self.tableHelp_:GetComponent(typeof(UIWidget))
	widget.alpha = 0

	for idx, id in ipairs(strIDs) do
		if not self.helpItems_[idx] then
			local item = SettingUpInfoItem.new(self.tableHelp_.gameObject)

			item:setInfos({
				id = id,
				index = idx,
				obj = self,
				table = self.tableHelp_,
				scrollView = self.scrollViewHelp_,
				long = #strIDs
			})
			table.insert(self.helpItems_, item)
		end
	end

	XYDCo.WaitForFrame(1, function ()
		if self.tableHelp_ == nil then
			return
		end

		widget.alpha = 1

		self.tableHelp_:Reposition()
		self.scrollViewHelp_:ResetPosition()

		self.scrollPos_[self.tapType.HELP] = self.scrollViewHelp_.transform.localPosition
	end, nil)
end

function SettingUpInfoWindow:initFAQ()
	local strIDs = xyd.tables.settingTable:getStrIDsbyType(2)

	table.sort(strIDs, function (a, b)
		return tonumber(a) < tonumber(b)
	end)

	for idx, id in ipairs(strIDs) do
		if not self.FAQItems_[idx] then
			local item = SettingUpInfoItem.new(self.tableFAQ_.gameObject)

			item:setInfos({
				id = id,
				index = idx,
				obj = self,
				table = self.tableFAQ_,
				scrollView = self.scrollViewFAQ_,
				long = #strIDs
			})
			table.insert(self.FAQItems_, item)
		end
	end

	XYDCo.WaitForFrame(1, function ()
		self.tableFAQ_:Reposition()
		self.scrollViewFAQ_:ResetPosition()

		self.scrollPos_[self.tapType.FAQ] = self.scrollViewFAQ_.transform.localPosition
	end, nil)
end

function SettingUpInfoWindow:playHideItem()
	local itemList = nil

	if self.curIndex_ == self.tapType.HELP then
		itemList = self.helpItems_
	else
		itemList = self.FAQItems_
	end

	for idx, item in ipairs(itemList) do
		if item:isShow() then
			item:playHide(true)

			break
		end
	end
end

function SettingUpInfoWindow:updateScroll(index, t)
end

function SettingUpInfoItem:ctor(parentGo)
	SettingUpInfoItem.super.ctor(self, parentGo)

	local itemTrans = self.go.transform
	self.groupTitleBg_ = itemTrans:NodeByName("groupTitle/img").gameObject
	self.dragBg_ = self.groupTitleBg_:GetComponent(typeof(UIDragScrollView))
	self.groupDialog_ = itemTrans:NodeByName("groupDialog").gameObject
	self.labelTitle_ = itemTrans:ComponentByName("groupTitle/labelTitle", typeof(UILabel))
	self.imgArr_ = itemTrans:ComponentByName("groupTitle/imgArr", typeof(UISprite))
	self.titleIcon_ = itemTrans:ComponentByName("groupTitle/icon", typeof(UISprite))
	self.dialogImg_ = itemTrans:ComponentByName("groupDialog/img", typeof(UISprite))
	self.dialogGrid_ = itemTrans:NodeByName("groupDialog/img/scrollView/grid")
	self.lineItem_ = itemTrans:NodeByName("groupDialog/img/lineItem").gameObject

	self.lineItem_:SetActive(false)
end

function SettingUpInfoItem:getPrefabPath()
	return "Prefabs/Components/setting_up_info_item"
end

function SettingUpInfoItem:setInfos(params)
	self.id_ = params.id
	self.index_ = params.index
	self.obj_ = params.obj
	self.table_ = params.table
	self.scrollView_ = params.scrollView
	self.dragBg_.scrollView = params.scrollView
	self.long_ = params.long

	self:layout()
	self:registerEvent()
end

function SettingUpInfoItem:layout()
	self.labelTitle_.text = xyd.tables.settingTable:getTitle(self.id_)
	self.dialogImg_.transform.localScale = Vector3(1, 0, 1)
end

function SettingUpInfoItem:createDialog()
	local type_ = xyd.tables.settingTable:getType(self.id_)
	local text_ = xyd.tables.settingTable:getText(self.id_)

	if tonumber(self.id_) == xyd.HELP_SETTING_UP_ID.GROUP_BUFF then
		self:initGroupBuffLayer()
	elseif type_ == 1 then
		self:initHelp(text_)
	else
		self:initFAQ(text_)
	end

	self.dialogImg_.transform.localScale = Vector3(1, 0, 1)
end

function SettingUpInfoItem:destroyDialog()
	NGUITools.DestroyChildren(self.dialogGrid_.transform)
end

function SettingUpInfoItem:initGroupBuffLayer()
	self.buffItems = {}
	local totalHeight = 0
	local buffIds = xyd.tables.groupBuffTable:getIds()

	for i = 1, #buffIds do
		local item = SettingUpGroupBuffItem.new(self.dialogGrid_.gameObject)

		item:setInfos({
			id = i
		})
		item:SetLocalPosition(0, -totalHeight - 58, 0)

		totalHeight = totalHeight + 135 + item.desLabel_.height + item.additionHight

		table.insert(self.buffItems, item)
	end

	self.sortItem = SettingUpGroupBuffSortItem.new(self.dialogGrid_.gameObject)

	self.sortItem:setInfos()
	self.sortItem:SetLocalPosition(0, -totalHeight - 30, 0)

	totalHeight = totalHeight + self.sortItem:getHeight()
	self.dialogImg_.height = totalHeight - 40
	self.all = self.long_ * 92 + totalHeight + 40 - 622
end

function SettingUpInfoItem:initHelp(text)
	local strs = xyd.split(text, "||")
	local totalHeight = 0

	for _, str in ipairs(strs) do
		local str2 = xyd.split(str, "|")
		local itemNew = NGUITools.AddChild(self.dialogGrid_.gameObject, self.lineItem_)

		itemNew:SetActive(true)

		itemNew.transform.localPosition = Vector3(0, -totalHeight, 0)
		local label = itemNew:ComponentByName("lable", typeof(UILabel))
		local imgIcon = itemNew:ComponentByName("imgIcon", typeof(UISprite))

		imgIcon.gameObject:SetActive(false)

		if not string.find(str2[1], "_png") then
			self:setLabelInfo(label, {
				c = 1549556991,
				s = 22,
				x = 16,
				t = str2[1]
			})

			label.width = 604
			label.transform.localPosition = Vector3(-294, 0, 0)
			totalHeight = totalHeight + label.height + 10
		else
			local split_list = xyd.split(str2[1], "@")
			local src_list = xyd.split(split_list[1], "#")

			imgIcon.gameObject:SetActive(false)

			local cur_x = 20

			for _, source in ipairs(src_list) do
				local go = NGUITools.AddChild(itemNew, imgIcon.gameObject)
				local goImg = go:GetComponent(typeof(UISprite))

				go:SetActive(true)

				go.transform.localPosition = Vector3(-310 + cur_x, -10, 0)
				cur_x = cur_x + 24

				xyd.setUISpriteAsync(goImg, nil, source, nil, )
			end

			self:setLabelInfo(label, {
				c = 1549556991,
				s = 22,
				t = "-" .. split_list[2],
				x = cur_x + 4
			})

			label.width = 620 - cur_x
			label.transform.localPosition = Vector3(-310 + cur_x + 4, 0, 0)
			totalHeight = totalHeight + label.height + 10

			if xyd.Global.lang == "fr_fr" then
				label.overflowMethod = UILabel.Overflow.ShrinkContent
			end
		end

		local goLine1 = NGUITools.AddChild(itemNew, imgIcon.gameObject)
		local goLine1Img = goLine1:GetComponent(typeof(UISprite))

		xyd.setUISpriteAsync(goLine1Img, nil, "setting_up_help_icon_2", nil, )

		goLine1Img.transform.localScale = Vector3(0.5, 0.5, 0.5)

		goLine1:SetLocalPosition(-310, -10, 0)

		local itemNew2 = NGUITools.AddChild(self.dialogGrid_.gameObject, self.lineItem_)

		itemNew2:SetActive(true)

		itemNew2.transform.localPosition = Vector3(0, -totalHeight, 0)
		local label2 = itemNew2:ComponentByName("lable", typeof(UILabel))

		self:setLabelInfo(label2, {
			c = 1549556991,
			s = 22,
			t = str2[2]
		})

		totalHeight = totalHeight + label2.height + 20
	end

	self.dialogImg_.height = totalHeight + 40
	self.all = self.long_ * 92 + totalHeight + 40 - 622
end

function SettingUpInfoItem:initFAQ(text)
	local strs = xyd.split(text, "|")
	local totalHeight = 0

	for _, str in ipairs(strs) do
		local itemNew = NGUITools.AddChild(self.dialogGrid_.gameObject, self.lineItem_)

		itemNew:SetActive(true)

		local label = itemNew:ComponentByName("lable", typeof(UILabel))

		self:setLabelInfo(label, {
			c = 1549556991,
			s = 22,
			t = str
		})

		itemNew.transform.localPosition = Vector3(0, -totalHeight, 0)
		totalHeight = totalHeight + label.height + 10
	end

	self.dialogImg_.height = totalHeight + 40
	self.all = self.long_ * 92 + totalHeight + 40 - 622
end

function SettingUpInfoItem:setLabelInfo(label, params)
	if params.w then
		label.width = params.w
	end

	if params.h then
		label.height = params.h
	end

	if params.s then
		label.fontSize = params.s
	end

	if params.c then
		label.color = Color.New2(params.c)
	end

	if params.t then
		label.text = params.t
	end

	if params.b then
		label.fontStyle = UnityEngine.FontStyle.Bold
	else
		label.fontStyle = UnityEngine.FontStyle.Normal
	end

	if params.p then
		label.pivot = UIWidget.Pivot[params.p]
	end

	if params.ec then
		label.effectStyle = UILabel.Effect.Outline
		label.effectDistance = Vector2(1, 1)
		label.effectColor = Color.New2(params.ec)
	end
end

function SettingUpInfoItem:registerEvent()
	UIEventListener.Get(self.groupTitleBg_.gameObject).onClick = handler(self, self.onClick)
end

function SettingUpInfoItem:onClick()
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	if self.isShow_ then
		self:playHide()
	else
		self.obj_:playHideItem()
		self:createDialog()

		self.isShow_ = true

		self.dialogImg_:SetLocalScale(1, 1, 1)

		self.dialogImg_.alpha = 0

		self.dialogImg_:SetActive(true)
		self.table_:Reposition()
		self.dialogImg_:SetLocalScale(1, 0, 1)

		self.dialogImg_.alpha = 1
		local action = DG.Tweening.DOTween.Sequence()
		self.imgArr_.transform.localEulerAngles = Vector3(0, 0, 0)

		if tonumber(self.id_) == xyd.HELP_SETTING_UP_ID.GROUP_BUFF then
			for i = 1, #self.buffItems do
				self.buffItems[i]:reposition()
			end
		end

		action:Insert(0, self.dialogImg_.transform:DOScale(Vector3(1, 1, 1), 0.1))
		action:AppendCallback(function ()
			self.table_:Reposition()
			XYDCo.WaitForFrame(1, function ()
				self.table_:Reposition()
				self.scrollView_:SetDragAmount(0, math.min(1, (self.index_ - 1) * 92 / self.all), false)
			end, nil)
		end)
	end
end

function SettingUpInfoItem:isShow()
	return self.isShow_
end

function SettingUpInfoItem:playHide(noAction, callback)
	if not self.isShow_ then
		return
	end

	self:destroyDialog()

	self.imgArr_.transform.localEulerAngles = Vector3(0, 0, 90)

	if noAction then
		self.isShow_ = false
		self.dialogImg_.transform.localScale = Vector3(1, 0, 1)

		self.table_:Reposition()
	else
		local action = DG.Tweening.DOTween.Sequence()

		action:Insert(0, self.dialogImg_.transform:DOScale(Vector3(1, 0, 1), 0.1))
		action:AppendCallback(function ()
			self.dialogImg_:SetActive(false)

			self.isShow_ = false

			XYDCo.WaitForFrame(1, function ()
				self.table_:Reposition()

				if callback then
					callback()
				end
			end, nil)
		end)
	end
end

function SettingUpGroupBuffItem:ctor(parentGo)
	SettingUpGroupBuffItem.super.ctor(self, parentGo)

	local go = self.go
	self.buffIconNode = go:NodeByName("groupTitle_/buffIconNode").gameObject
	self.nameLabel_ = go:ComponentByName("groupTitle_/nameLabel_", typeof(UILabel))
	self.bottomGroup = go:NodeByName("bottomGroup").gameObject
	self.desLabel_ = self.bottomGroup:ComponentByName("desLabel_", typeof(UILabel))
	self.attrGroup = self.bottomGroup:NodeByName("attrGroup").gameObject
	self.attrGroupTable = self.attrGroup:GetComponent(typeof(UITable))
	self.additionHight = 0
end

function SettingUpGroupBuffItem:getPrefabPath()
	return "Prefabs/Components/setting_up_group_buff_item"
end

function SettingUpGroupBuffItem:setInfos(params)
	self.id_ = params.id

	self:layout()
end

function SettingUpGroupBuffItem:layout()
	self.desLabel_.text = xyd.tables.groupBuffTextTable:getDesc(self.id_)
	self.nameLabel_.text = xyd.tables.groupBuffTextTable:getName(self.id_)
	local buffIcon = GroupBuffIcon.new(self.buffIconNode)

	buffIcon:setInfo(self.id_, true)

	local addStr = "+ "
	local effectShowData = xyd.split(xyd.tables.groupBuffTable:getEffectShow(self.id_), "|")

	if self.id_ == xyd.GROUP_7_BUFF then
		effectShowData = xyd.split(xyd.tables.groupBuffTable:getEffectShow(self.id_), "@")
		addStr = "+"
		self.attrGroupTable.enabled = false
		self.additionHight = 120
	end

	local poses = xyd.tables.groupBuffTable:getEffectStands(self.id_)

	for i = 1, #effectShowData do
		local labelAttr = self.attrGroup:ComponentByName("labelAttr" .. i, typeof(UILabel))
		local labelAttrNum = self.attrGroup:ComponentByName("labelAttrNum" .. i, typeof(UILabel))

		if effectShowData[i] then
			local effectData = xyd.split(effectShowData[i], "#")
			local effectName = effectData[1]
			local effectNum = tonumber(effectData[2])
			local pos_label = self:getPosDesc(poses[i])

			if pos_label ~= "" then
				labelAttr.text = __("POSITION_DESC", pos_label, xyd.tables.dBuffTable:getDesc(effectName))
			else
				labelAttr.text = xyd.tables.dBuffTable:getDesc(effectName)
			end

			local factor = tonumber(xyd.tables.dBuffTable:getFactor(effectName) or 1)

			if factor <= 0 then
				factor = 1
			end

			if xyd.tables.dBuffTable:isShowPercent(effectName) then
				labelAttrNum.text = addStr .. effectNum / factor * 100 .. "%"
			else
				labelAttrNum.text = addStr .. effectNum
			end

			if self.id_ == xyd.GROUP_7_BUFF then
				labelAttrNum.text = labelAttr.text .. labelAttrNum.text
				labelAttr.text = __("GROUP_7_BUFF_TIP", i)

				labelAttr.gameObject:X(19)
				labelAttrNum.gameObject:X(610 - labelAttrNum.width)

				labelAttr.color = Color.New2(11731199)
				labelAttrNum.color = Color.New2(472325119)
			end
		end
	end
end

function SettingUpGroupBuffItem:getPosDesc(pos)
	if not pos then
		return ""
	end

	local result = ""
	local poses = xyd.split(pos, "|", true)

	if #poses == 6 then
		-- Nothing
	elseif #poses == 2 and poses[1] == 1 and poses[2] == 2 then
		result = __("HEAD_POS1")
	else
		result = __("BACK_POS1")
	end

	return result
end

function SettingUpGroupBuffItem:reposition()
	self:waitForFrame(1, function ()
		if self.id_ ~= xyd.GROUP_7_BUFF then
			self.attrGroup:GetComponent(typeof(UITable)):Reposition()
		end

		self.bottomGroup:GetComponent(typeof(UILayout)):Reposition()
	end)
end

function SettingUpGroupBuffSortItem:ctor(parentGo)
	SettingUpGroupBuffSortItem.super.ctor(self, parentGo)

	local go = self.go
	self.nameLabel_ = go:ComponentByName("groupTitle_/nameLabel_", typeof(UILabel))
	self.bottomGroup = go:NodeByName("bottomGroup").gameObject
	self.buffGroup = self.bottomGroup:NodeByName("buffGroup").gameObject
	self.buffGroupGrid = self.buffGroup:GetComponent(typeof(UIGrid))
	self.item = self.bottomGroup:NodeByName("item").gameObject
	self.additionHight = 0
	self.items = {}
end

function SettingUpGroupBuffSortItem:getPrefabPath()
	return "Prefabs/Components/setting_up_group_buff_sort_item"
end

function SettingUpGroupBuffSortItem:setInfos()
	self:layout()
end

function SettingUpGroupBuffSortItem:layout()
	self.nameLabel_.text = __("SETING_GROUP_BUFF_RANK")

	self.buffGroup:Y(-16 - (self.nameLabel_.height - self.nameLabel_.fontSize))

	local buffIds = xyd.tables.groupBuffTable:getIds()
	local datas = {}

	for i = 1, #buffIds do
		local rank = xyd.tables.groupBuffTable:getRank(i)

		if rank and rank > 0 then
			table.insert(datas, {
				id = i,
				rank = rank
			})
		end
	end

	dump(datas)
	table.sort(datas, function (a, b)
		if a.rank ~= b.rank then
			return a.rank < b.rank
		else
			return a.id < b.id
		end
	end)

	for i = 1, #datas do
		if not self.items[i] then
			local tmp = NGUITools.AddChild(self.buffGroupGrid.gameObject, self.item.gameObject)
			local item = SettingUpGroupBuffSortIconItem.new(tmp, self)
			self.items[i] = item
		end

		datas[i].index = i

		self.items[i]:setInfo(datas[i])
	end

	self.buffGroupGrid:Reposition()
end

function SettingUpGroupBuffSortItem:reposition()
	self:waitForFrame(1, function ()
		self.buffGroupGrid:Reposition()
	end)
end

function SettingUpGroupBuffSortItem:getHeight()
	return self.go:GetComponent(typeof(UIWidget)).height + 74 * math.ceil(#self.items / 2) - 74 + self.nameLabel_.height - self.nameLabel_.fontSize
end

function SettingUpGroupBuffSortIconItem:ctor(go, parent)
	SettingUpGroupBuffSortIconItem.super.ctor(self, go, parent)

	self.parent = parent

	self:initUI()
end

function SettingUpGroupBuffSortIconItem:initUI()
	self.icon = self.go:ComponentByName("icon", typeof(UISprite))
	self.labelName = self.go:ComponentByName("labelName", typeof(UILabel))
	self.labelIndex = self.go:ComponentByName("labelIndex", typeof(UILabel))
end

function SettingUpGroupBuffSortIconItem:setInfo(data)
	self.data = data
	self.id = self.data.id
	self.rank = self.data.rank
	self.labelIndex.text = self.data.index
	self.labelName.text = xyd.tables.groupBuffTextTable:getName(self.id)

	if not self.buffIcon then
		self.buffIcon = GroupBuffIcon.new(self.icon.gameObject)
	end

	self.buffIcon:setInfo(self.id, true)
end

function SettingUpGroupBuffSortIconItem:getGameObject()
	return self.go
end

return SettingUpInfoWindow
