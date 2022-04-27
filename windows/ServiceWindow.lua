local SettingServiceItem = class("SettingServiceItem", import("app.components.CopyComponent"))
local PlayerIcon = require("app.components.PlayerIcon")

function SettingServiceItem:ctor(go, parent)
	SettingServiceItem.super.ctor(self, go)

	self.parent = parent

	self:setDragScrollView(parent.scrollView)
	self:getUIComponent()
	self:register()
end

function SettingServiceItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data_ = info.info

	self:layout()
end

function SettingServiceItem:getUIComponent()
	local go = self.go
	self.labelRegion_ = go:ComponentByName("labelRegion_", typeof(UILabel))
	self.labelPlayerName_ = go:ComponentByName("labelPlayerName_", typeof(UILabel))
	self.imgNew_ = go:ComponentByName("imgNew_", typeof(UISprite))
	self.playerIcon_ = go:NodeByName("playerIcon_").gameObject
	self.bg1 = go:NodeByName("bg1").gameObject
	self.bg2 = go:NodeByName("bg2").gameObject
	self.pIcon = PlayerIcon.new(self.playerIcon_)
end

function SettingServiceItem:layout()
	local showServer = "T" .. tostring(self.data_.server_id)

	if self.data_.server_id > 2 then
		showServer = "S" .. tostring(self.data_.server_id - 2)
	end

	self.labelRegion_.text = showServer
	local info = xyd.models.settingUp:checkHasRole(self.data_.server_id)

	if info ~= nil then
		self.playerIcon_:SetActive(true)
		self.labelPlayerName_:SetActive(true)
		self.pIcon:setInfo({
			noClick = true,
			avatarID = info.avatar_id,
			lev = info.lev,
			avatar_frame_id = info.avatar_frame_id,
			labelNumScale = Vector3(1.2, 1.2, 1.2)
		})

		if xyd.utf8len(info.player_name) <= 12 then
			self.labelPlayerName_.text = info.player_name
		else
			self.labelPlayerName_.text = xyd.subUft8Len(info.player_name, 9) .. "..."
		end
	else
		self.playerIcon_:SetActive(false)
		self.labelPlayerName_:SetActive(false)
	end

	if self.data_.is_new then
		self.imgNew_:SetActive(true)
	else
		self.imgNew_:SetActive(false)
	end

	local curServer = self.data_.server_id == self.parent.choice_id

	if curServer then
		self.parent.lastRederItem = self
	end

	self.bg2:SetActive(curServer)
	self.bg1:SetActive(not curServer)
end

function SettingServiceItem:register()
	UIEventListener.Get(self.go).onClick = function ()
		if self.parent.isClickToChange then
			if self.data_.server_id == self.parent.default_server_id then
				return
			end

			local str = __("SWITCH_SERVER_TIP")

			xyd.alert(xyd.AlertType.YES_NO, str, function (yes_no)
				if yes_no then
					self:changeServer(self.data_.server_id)
				end
			end)
		else
			self.parent.choice_id = self.data_.server_id

			if self.parent.lastRederItem then
				self.parent.lastRederItem:changeBgChoiceState(false)
			end

			self.parent.lastRederItem = self

			self:changeBgChoiceState(true)
		end
	end
end

function SettingServiceItem:changeServer(serverID)
	xyd.EventDispatcher:inner():dispatchEvent({
		name = xyd.event.CHANGE_SERVER,
		data = {
			server_id = serverID
		}
	})
end

function SettingServiceItem:changeBgChoiceState(state)
	self.bg2:SetActive(state)
	self.bg1:SetActive(not state)
end

local BaseWindow = import(".BaseWindow")
local ServiceWindow = class("ServiceWindow", BaseWindow)
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")

function ServiceWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	if params and params.isClickToChange ~= nil then
		self.isClickToChange = params.isClickToChange
	else
		self.isClickToChange = true
	end

	self.default_server_id = xyd.models.selfPlayer:getServerID()

	if params and params.default_server_id then
		self.default_server_id = params.default_server_id
	end
end

function ServiceWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.scroller = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.groupMain_ = self.scroller:NodeByName("groupMain_").gameObject
	local wrapContent = self.groupMain_:GetComponent(typeof(MultiRowWrapContent))
	local serviceItem = groupAction:NodeByName("service_item").gameObject
	self.wrapContent = FixedMultiWrapContent.new(self.scroller, wrapContent, serviceItem, SettingServiceItem, self)
	self.closeBtn = groupAction:ComponentByName("closeBtn", typeof(UISprite)).gameObject
end

function ServiceWindow:initWindow()
	ServiceWindow.super.initWindow(self)
	self:getUIComponent()
	ServiceWindow.super.register(self)
	self:registerEvent()
	self:layout()
	xyd.models.settingUp:reqGetServerList()
end

function ServiceWindow:layout()
	self.choice_id = self.default_server_id
	self.lastRederItem = nil
	self.labelTitle_.text = __("PERSON_BTN_2")

	self:onUpdate()
end

function ServiceWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_SERVER_LIST, self.onUpdate, self)
end

function ServiceWindow:onUpdate()
	local serverInfos = xyd.models.settingUp:getServerInfos()
	local group = {}

	for _, info in ipairs(serverInfos) do
		table.insert(group, {
			info = info
		})
	end

	self.wrapContent:setInfos(group, {})
end

function ServiceWindow:willClose()
	if not self.isClickToChange and self.choice_id ~= self.default_server_id then
		local login_wd = xyd.WindowManager.get():getWindow("login_window")

		if login_wd then
			login_wd:changeServerId(self.choice_id)
		end
	end

	ServiceWindow.super.willClose(self)
end

return ServiceWindow
