local BaseWindow = import(".BaseWindow")
local HelpWindow = class("HelpWindow", BaseWindow)

function HelpWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.callback = nil
	self.strList_ = {}
	self.titleName = ""
	self.isFlow = false

	if params.key then
		self.key = string.upper(params.key)
	end

	self.strList_ = params.str_list or {}
	self.titleName = params.title or ""
	self.isFlow = params.isFlow
	self.myFontSize = params.myFontSize
	self.isEast = params.isEast

	if params.values then
		self.values = params.values
	end
end

function HelpWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.content = winTrans:NodeByName("content").gameObject
	self.ListContainer = self.content:NodeByName("listScroller/ListContainer").gameObject
	self.ListContainerTable = self.ListContainer:GetComponent(typeof(UITable))
	self.listLabel = self.ListContainer:NodeByName("label").gameObject

	if xyd.Global.lang == "ko_kr" then
		self.listLabel:GetComponent(typeof(UILabel)).considerEast = false
	end

	self.labelHelpTitle = self.content:ComponentByName("labelHelpTitle", typeof(UILabel))
	self.closeBtn = self.content:NodeByName("closeBtn").gameObject
end

function HelpWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initLayOut()
	self:register()
end

function HelpWindow:register()
	HelpWindow.super.register(self)
end

function HelpWindow:initLayOut()
	self.labelHelpTitle.text = __(self:winName())

	if self.titleName ~= "" then
		self.labelHelpTitle.text = self.titleName
	end

	if self.myFontSize then
		self.listLabel:GetComponent(typeof(UILabel)).fontSize = self.myFontSize
	end

	if self.isEast ~= nil then
		self.listLabel:GetComponent(typeof(UILabel)).considerEast = self.isEast
	end

	local str_list = ""

	if self.values then
		str_list = xyd.split(xyd.tables.translationTable:translate(self.key, unpack(self.values)), "|")
	else
		str_list = xyd.split(xyd.tables.translationTable:translate(self.key), "|")
	end

	if #self.strList_ > 0 then
		str_list = self.strList_
	end

	if not str_list or #str_list <= 0 then
		return
	end

	for _, str in ipairs(str_list) do
		local labelObj = NGUITools.AddChild(self.ListContainer, self.listLabel)
		local label = labelObj:GetComponent(typeof(UILabel))
		label.text = str
	end

	self.ListContainerTable:Reposition()
end

function HelpWindow:willClose()
	BaseWindow.willClose(self)
end

return HelpWindow
