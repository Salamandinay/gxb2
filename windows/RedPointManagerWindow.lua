local BaseWindow = import(".BaseWindow")
local RedPointManagerWindow = class("RedPointManagerWindow", BaseWindow)
local RedPointManagerWindowitem = class("RedPointManagerWindowitem", import("app.components.CopyComponent"))

function RedPointManagerWindow:ctor(name, params)
	RedPointManagerWindow.super.ctor(self, name, params)

	self.skinName = "RedPointManagerWindowSkin"
end

function RedPointManagerWindow:initWindow()
	RedPointManagerWindow.super.initWindow(self)
	self:getUIComponent()
	self:registerEvent()
	self:setLayout()
end

function RedPointManagerWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.groupTitle = groupAction:NodeByName("groupTitle").gameObject
	self.closeBtn = self.groupTitle:NodeByName("closeBtn").gameObject
	self.labelTitle_ = self.groupTitle:ComponentByName("labelTitle_", typeof(UILabel))
	self.groupForm = groupAction:NodeByName("groupForm").gameObject
	self.itemscroller = self.groupForm:NodeByName("itemscroller").gameObject
	self.itemsgroup = self.itemscroller:NodeByName("itemsgroup").gameObject
	self.item = self.groupForm:NodeByName("item").gameObject
end

function RedPointManagerWindow:registerEvent()
	self:register()
end

function RedPointManagerWindow:setLayout()
	self.labelTitle_.text = __("RED_MARK")
	local ids = xyd.tables.deviceRedMarkTable:getIDs()

	for _, id in pairs(ids) do
		local params = {
			id = id
		}
		local go = NGUITools.AddChild(self.itemsgroup, self.item)
		local item = RedPointManagerWindowitem.new(go, params)
	end
end

function RedPointManagerWindowitem:ctor(go, params)
	self.skinName = "RedPointManagerWindowSkin"
	self.id = params.id
	self.currentState = xyd.Global.lang

	RedPointManagerWindowitem.super.ctor(self, go)
end

function RedPointManagerWindowitem:initUI()
	self.labelname = self.go:ComponentByName("labelname", typeof(UILabel))
	self.btn = self.go:NodeByName("btn").gameObject
	self.img = self.btn:NodeByName("imgSelect").gameObject

	self:setLayout()
end

function RedPointManagerWindowitem:setLayout()
	self.labelname.text = xyd.tables.deviceRedMarkTextTable:getPushCategory(self.id)
	local isopen = xyd.models.deviceNotify:isRedMarkUp(self.id)

	self.img:SetActive(isopen)

	UIEventListener.Get(self.btn).onClick = function ()
		isopen = not isopen

		xyd.models.deviceNotify:setRedMark(self.id, isopen)
		self.img:SetActive(isopen)
		self:checkReOpen(self.id, isopen)
	end

	if xyd.Global.lang == "de_de" then
		self.labelname:X(-60)
	end
end

function RedPointManagerWindowitem:checkReOpen(redMarkId, state)
	local redMarkIds = xyd.tables.deviceRedMarkTable:getIDs()
	local redMarkTypes = xyd.tables.deviceRedMarkTable:getRedMarkTypes(redMarkId)

	xyd.models.redMark:reOpenSwitch(redMarkTypes[1], state)
end

return RedPointManagerWindow
