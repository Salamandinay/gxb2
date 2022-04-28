local ActivityLostSpaceEventWindow = class("ActivityLostSpaceEventWindow", import(".BaseWindow"))

function ActivityLostSpaceEventWindow:ctor(name, params)
	ActivityLostSpaceEventWindow.super.ctor(self, name, params)

	self.selectIndex_ = 1
	self.eventList_ = {}
	self.strList_ = {}
end

function ActivityLostSpaceEventWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:register()
	self:updateNav()
end

function ActivityLostSpaceEventWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.bg2 = winTrans:NodeByName("bg2").gameObject
	self.bg3 = winTrans:NodeByName("bg3").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.eventItem_ = winTrans:NodeByName("buffItem").gameObject
	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("scrollView/grid", typeof(UITable))
	self.helpList_ = winTrans:ComponentByName("helpList", typeof(UIScrollView))
	self.ListContainer = winTrans:NodeByName("helpList/ListContainer").gameObject
	self.ListContainerTable = self.ListContainer:GetComponent(typeof(UITable))
	self.listLabel = self.ListContainer:NodeByName("label").gameObject
	self.navPos_ = winTrans:NodeByName("navPos").gameObject

	for i = 1, 2 do
		self["nav" .. i] = self.navPos_:ComponentByName("nav" .. i, typeof(UISprite))
		self["navSelect" .. i] = self["nav" .. i].transform:ComponentByName("bgShow", typeof(UISprite))
		self["navLabel" .. i] = self["nav" .. i].transform:ComponentByName("label", typeof(UILabel))
		self["navLabel" .. i].text = __("ACTIVITY_LOST_SPACE_NAV" .. i)

		UIEventListener.Get(self["nav" .. i].gameObject).onClick = function ()
			self.selectIndex_ = i

			self:updateNav()
		end
	end
end

function ActivityLostSpaceEventWindow:updateNav()
	for i = 1, 2 do
		self["navSelect" .. i].gameObject:SetActive(self.selectIndex_ == i)

		if self.selectIndex_ == i then
			self["navLabel" .. i].color = Color.New2(4294967295.0)
			self["navLabel" .. i].effectColor = Color.New2(473916927)
		else
			self["navLabel" .. i].color = Color.New2(960513791)
			self["navLabel" .. i].effectColor = Color.New2(4294967295.0)
		end
	end

	if self.selectIndex_ == 1 then
		self.scrollView_.gameObject:SetActive(true)
		self.bg2:SetActive(true)
		self.helpList_.gameObject:SetActive(false)
		self.bg3:SetActive(false)
	else
		self.scrollView_.gameObject:SetActive(false)
		self.bg2:SetActive(false)
		self.helpList_.gameObject:SetActive(true)
		self.bg3:SetActive(true)
	end
end

function ActivityLostSpaceEventWindow:layout()
	self.titleLabel_.text = __("ACTIVITY_PARTNER_GALLERY_CHECK")
	local str_list = xyd.split(xyd.tables.translationTable:translate("ACTIVITY_LOST_SPACE_HELP_TEXT"), "|")

	if #self.strList_ > 0 then
		str_list = self.strList_
	end

	if str_list then
		if #str_list > 0 then
			for _, str in ipairs(str_list) do
				local labelObj = NGUITools.AddChild(self.ListContainer, self.listLabel)
				local label = labelObj:GetComponent(typeof(UILabel))
				label.text = str
			end
		end
	end

	self.ListContainerTable:Reposition()
	self.helpList_:ResetPosition()

	local ids = xyd.tables.activityLostSpaceEventTextTable:getIDs()

	for index, id in ipairs(ids) do
		local newItemRoot = NGUITools.AddChild(self.grid_.gameObject, self.eventItem_)

		newItemRoot:SetActive(true)

		local labelName = newItemRoot:ComponentByName("name", typeof(UILabel))
		local labelDesc = newItemRoot:ComponentByName("desc", typeof(UILabel))
		local icon = newItemRoot:ComponentByName("icon", typeof(UISprite))
		local bg = newItemRoot:ComponentByName("bg", typeof(UIWidget))
		labelName.text = xyd.tables.activityLostSpaceEventTable:getName(id)
		labelDesc.text = xyd.tables.activityLostSpaceEventTable:getDesc(id)
		local iconName = xyd.tables.activityLostSpaceEventTable:getIcon(id)
		bg.height = labelDesc.height - 24 + 81

		icon.transform:Y(-(bg.height - 121) / 2 - 60.5)
		xyd.setUISpriteAsync(icon, nil, iconName)
	end

	self.grid_:Reposition()
	self.scrollView_:ResetPosition()
end

function ActivityLostSpaceEventWindow:register()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end
end

return ActivityLostSpaceEventWindow
