local ChatBlackItem = class("ChatBlackItem")
local PlayerIcon = import("app.components.PlayerIcon")

function ChatBlackItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	xyd.setDragScrollView(go, parent.scrollView)
	self:initUI()
	self:registerEvent()
end

function ChatBlackItem:initUI()
	self.labelName_ = self.go:ComponentByName("labelName_", typeof(UILabel))
	self.labelLev_ = self.go:ComponentByName("groupLev/labelLev_", typeof(UILabel))
	self.btnCancel_ = self.go:NodeByName("btnCancel_").gameObject
	local playerIconNode = self.go:NodeByName("playerIcon_").gameObject
	self.playerIcon_ = PlayerIcon.new(playerIconNode)
end

function ChatBlackItem:getGameObject()
	return self.go
end

function ChatBlackItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self:updateInfo()
end

function ChatBlackItem:updateInfo()
	self.labelLev_.text = self.data.lev
	self.labelName_.text = self.data.player_name
	self.btnCancel_:ComponentByName("button_label", typeof(UILabel)).text = __("CHAT_UNSHIELD")

	self.playerIcon_:setInfo({
		avatarID = self.data.avatar_id,
		avatar_frame_id = self.data.avatar_frame_id,
		callback = function ()
			xyd.WindowManager:get():openWindow("arena_formation_window", {
				not_show_private_chat = true,
				add_friend = false,
				show_close_btn = true,
				is_robot = false,
				player_id = self.data.player_id
			})
		end
	})
	self.playerIcon_:AddUIDragScrollView()
end

function ChatBlackItem:registerEvent()
	UIEventListener.Get(self.btnCancel_).onClick = handler(self, self.onCancel)
end

function ChatBlackItem:onCancel()
	xyd.models.chat:removeBlackList(self.data.player_id)
	xyd.models.chat:popBlackList(self.data.player_id)

	local win = xyd.WindowManager:get():getWindow("chat_black_list_window")

	if win then
		win:updateList()
	end
end

local ChatBlackListWindow = class("ChatBlackListWindow", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function ChatBlackListWindow:ctor(name, params)
	ChatBlackListWindow.super.ctor(self, name, params)
end

function ChatBlackListWindow:initWindow()
	ChatBlackListWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function ChatBlackListWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.closeBtn = winTrans:NodeByName("groupAction/closeBtn").gameObject
	self.labelTitle_ = winTrans:ComponentByName("groupAction/labelTitle_", typeof(UILabel))
	local scrollView = winTrans:ComponentByName("groupAction/scroller_", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("groupItems_", typeof(UIWrapContent))
	local item = scrollView:NodeByName("item").gameObject
	self.wrapContent_ = FixedWrapContent.new(scrollView, wrapContent, item, ChatBlackItem, self)
end

function ChatBlackListWindow:updateList()
	local tmpBlackList = xyd.models.chat:getAllBlack()

	dump(tmpBlackList)

	local datas = {}

	for _, item in pairs(tmpBlackList) do
		table.insert(datas, item)
	end

	self.wrapContent_:setInfos(datas, {})
end

function ChatBlackListWindow:layout()
	self.labelTitle_.text = __("CHAT_CONFIG_0")

	self:updateList()
end

return ChatBlackListWindow
