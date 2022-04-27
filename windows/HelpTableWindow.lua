local BaseWindow = import(".BaseWindow")
local HelpTableWindow = class("HelpTableWindow", BaseWindow)

function HelpTableWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.callback = nil
	self.strList_ = {}
	self.titleName = ""
	self.isFlow = false
	self.skinName = "HelpWindowSkin"
	self.key = params.key
	self.strList_ = params.str_list or {}
	self.titleName = params.title or ""
	self.isFlow = params.isFlow
end

function HelpTableWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initLayOut()
	self:register()
end

function HelpTableWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.content = winTrans:NodeByName("content").gameObject
	self.ListContainer = self.content:NodeByName("listScroller/ListContainer").gameObject
	self.ListContainerTable = self.ListContainer:GetComponent(typeof(UITable))
	self.listLabel = self.ListContainer:NodeByName("label").gameObject
	self.labelHelpTitle = self.content:ComponentByName("labelHelpTitle", typeof(UILabel))
	self.closeBtn = self.content:NodeByName("closeBtn").gameObject
end

function HelpTableWindow:initLayOut()
	self.labelHelpTitle.text = __(self:winName())

	if self.titleName ~= "" then
		self.labelHelpTitle.text = self.titleName
	end

	local str = __(self.key)
	local front_index = string.find(str, "<t>")
	local end_index = string.find(str, "</t>")
	local front_str = string.sub(str, 1, front_index - 1)
	local table_str = string.sub(str, front_index + 3, end_index - 1)
	local end_str = string.sub(str, end_index + 4)

	self:createLabel(front_str)

	local row = xyd.split(table_str, "$")
	local basicDepth = self.ListContainer:GetComponent(typeof(UIWidget)).depth

	for i = 1, #row do
		local rowStr = row[i]
		local table_info = xyd.split(rowStr, "|")
		local group = NGUITools.AddChild(self.ListContainer, "group" .. i)
		local w = group:AddComponent(typeof(UIWidget))
		w.depth = basicDepth
		w.width = 2
		w.height = 2
		local layout = group:AddComponent(typeof(UILayout))
		layout.horizontalAlign = UILayout.HorizontalAlign.Left
		layout.verticalAlign = UILayout.VerticalAlign.Top

		for j = 1, #table_info do
			local data = xyd.split(table_info[j], "#")
			local limit = data[1]
			local detail = data[2]
			local label = self:createLabel(detail, limit, false, group)
		end
	end

	self:createLabel(end_str)
	self:waitForFrame(1, function ()
		self.ListContainerTable:Reposition()
	end)
end

function HelpTableWindow:createLabel(str, width, add, parentGo)
	if add == nil then
		add = true
	end

	parentGo = parentGo or self.ListContainer
	local labelStr = xyd.getLabel({
		spacingY = 4,
		c = 1583978239,
		s = 20,
		uiRoot = parentGo,
		t = str,
		w = width or 640,
		alignment = NGUIText.Alignment.Left
	})

	return labelStr
end

return HelpTableWindow
