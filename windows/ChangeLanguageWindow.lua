local BaseWindow = import(".BaseWindow")
local ChangeLanguageWindow = class("ChangeLanguageWindow", BaseWindow)
local ChangeLanguageItem = class("ChangeLanguageItem", import("app.components.CopyComponent"))
local PlayerLanguageTable = xyd.tables.playerLanguageTable

function ChangeLanguageWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function ChangeLanguageWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initDatas()
	self:register()
end

function ChangeLanguageWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.scroller = groupAction:NodeByName("scroller").gameObject
	self.groupMain_ = self.scroller:NodeByName("groupMain_").gameObject
	self.item = groupAction:NodeByName("item").gameObject
end

function ChangeLanguageWindow:layout()
	self.labelTitle_.text = __("CHANGE_LANGUAGE_WINDOW")
end

function ChangeLanguageWindow:initDatas()
	local ids = PlayerLanguageTable:getShowIDs()

	for _, id in ipairs(ids) do
		local timeStamp = PlayerLanguageTable:getTimeStamp(id)

		if not timeStamp or timeStamp < xyd.getServerTime() then
			local go = NGUITools.AddChild(self.groupMain_, self.item)
			local item = ChangeLanguageItem.new(go)

			item:setInfo(id)
		end
	end
end

function ChangeLanguageItem:ctor(go)
	ChangeLanguageItem.super.ctor(self, go)

	self.id_ = -1
end

function ChangeLanguageItem:setInfo(id)
	self.id_ = id

	self:layout()
end

function ChangeLanguageItem:initUI()
	self.select = self.go:NodeByName("select").gameObject
	self.labelName_ = self.go:ComponentByName("labelName_", typeof(UILabel))
end

function ChangeLanguageItem:layout()
	self.labelName_.text = PlayerLanguageTable:getTrueName(self.id_)
	local curID = PlayerLanguageTable:getIDByName(xyd.Global.lang)

	if curID and tonumber(curID) == tonumber(self.id_) then
		self.select:SetActive(true)
		xyd.setTouchEnable(self.go, false)
	else
		self.select:SetActive(false)

		UIEventListener.Get(self.go).onClick = handler(self, self.onSelect)
	end
end

function ChangeLanguageItem:onSelect()
	xyd.models.settingUp:changeLanguage(self.id_)
end

return ChangeLanguageWindow
