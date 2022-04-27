local BaseWindow = import(".BaseWindow")
local GuildChangeLanguageWindow = class("GuildChangeLanguageWindow", BaseWindow)
local GuildChangeLanguageItem = class("GuildChangeLanguageItem", import("app.components.CopyComponent"))

function GuildChangeLanguageWindow:ctor(name, params)
	self.items_ = {}

	BaseWindow.ctor(self, name, params)

	self.callback = params.callback
	self.cur_lang = params.language or xyd.tables.playerLanguageTable:getIDByName(xyd.Global.lang)
end

function GuildChangeLanguageWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
end

function GuildChangeLanguageWindow:getUIComponent()
	local go = self.window_
	self.labelTitle_ = go:ComponentByName("e:Group/labelTitle_", typeof(UILabel))
	self.closeBtn = go:NodeByName("e:Group/closeBtn").gameObject
	self.scrollView = go:ComponentByName("e:Group/e:Group/scrollView", typeof(UIScrollView))
	self.groupMain_ = self.scrollView:NodeByName("groupMain_").gameObject
	self.cloneItem = go:NodeByName("cloneItem").gameObject

	self.cloneItem:SetActive(false)
end

function GuildChangeLanguageWindow:initUIComponent()
	self.labelTitle_.text = __("GUILD_CHANGE_LANGUAGE_WINDOW")
	local ids = xyd.tables.playerLanguageTable:getShowIDs()

	for _, id in ipairs(ids) do
		local go = NGUITools.AddChild(self.groupMain_, self.cloneItem)
		local item = GuildChangeLanguageItem.new(go, id, self.cur_lang)

		item:addParentDepth()
		table.insert(self.items_, item)
	end

	self.groupMain_:GetComponent(typeof(UILayout)):Reposition()
	self:setCloseBtn(self.closeBtn)
end

function GuildChangeLanguageWindow:onSelect(id)
	self.cur_lang = id

	if self.callback then
		self.callback(self.cur_lang)

		self.callback = nil
	end

	self:close()
end

function GuildChangeLanguageWindow:excuteCallback(isCloseAll)
	if isCloseAll then
		return
	end

	if self.callback then
		self:callback(self.cur_lang)
	end
end

function GuildChangeLanguageItem:ctor(go, id, def_lang)
	self.go = go
	self.id_ = id
	self.def_lang_ = def_lang

	self:getUIComponent()
	self:initUIComponent()
end

function GuildChangeLanguageItem:getUIComponent()
	local go = self.go
	self.labelName_ = go:ComponentByName("labelName_", typeof(UILabel))
	self.toggle = go:GetComponent(typeof(UIToggle))
end

function GuildChangeLanguageItem:initUIComponent()
	self.labelName_.text = xyd.tables.playerLanguageTable:getTrueName(self.id_)
	local curID = self.def_lang_

	if curID and tonumber(curID) == tonumber(self.id_) then
		self:update(self.id_)
	else
		XYDUtils.AddEventDelegate(self.toggle.onChange, function ()
			if self.toggle.value ~= true then
				return
			end

			self:onSelect()
		end)
	end
end

function GuildChangeLanguageItem:update(id)
	self.toggle.value = id == self.id_

	if id == self.id_ then
		self:select()
	else
		self:unSelect()
	end
end

function GuildChangeLanguageItem:onSelect()
	local win = xyd.WindowManager.get():getWindow("guild_change_language_window")

	if not win then
		return
	end

	win:onSelect(self.id_)
	xyd.showToast(__("GUILD_LANGUAGE_CHANGED_TIP"))
end

function GuildChangeLanguageItem:select()
	self:SetEnabled(false)
end

function GuildChangeLanguageItem:unSelect()
	self:SetEnabled(true)
end

function GuildChangeLanguageItem:SetEnabled(bool)
	if bool then
		local widget = self.go:GetComponent(typeof(UIWidget))

		if not widget then
			return
		end

		local boxCollider = self.go:GetComponent(typeof(UnityEngine.BoxCollider))

		if not boxCollider then
			boxCollider = self.go:AddComponent(typeof(UnityEngine.BoxCollider))
			boxCollider.size = Vector3(widget.width, widget.height, 0)
		end

		boxCollider.enabled = true
	else
		local boxCollider = self.go:GetComponent(typeof(UnityEngine.BoxCollider))

		if boxCollider then
			boxCollider.enabled = false
		end
	end
end

return GuildChangeLanguageWindow
