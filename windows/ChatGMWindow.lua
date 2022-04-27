local ChatWindow = import(".ChatWindow")
local MiscTable = xyd.tables.miscTable
local ChatGMWindow = class("ChatGMWindow", ChatWindow)

function ChatGMWindow:ctor(name, params)
	ChatWindow.ctor(self, name, params)

	self.curSelect_ = 3
end

function ChatGMWindow:getUIComponent()
	ChatWindow.getUIComponent(self)
	self.groupTop:SetActive(false)

	self.imgListBg.height = 764

	self.imgListBg:SetLocalPosition(0, 10, 0)
	self.btnRecord:Y(332)
end

function ChatGMWindow:initWindow()
	ChatWindow.initWindow(self)
	self.chat_:getTalkList()
end

function ChatGMWindow:addTitle()
	if self.labelWinTitle then
		self.labelWinTitle.text = __(self:winName())

		if self.chat_:getGmInfo() then
			self.labelWinTitle.text = __("GM_NAME_ONLY")
		end
	end
end

function ChatGMWindow:checkShowImgBtn()
	local limitLev = MiscTable:getVal("gm_image_open_lv") or 0

	if xyd.Global.playerLev < tonumber(limitLev) then
		return false
	end

	return true
end

function ChatGMWindow:registerEvent()
	ChatGMWindow.super.registerEvent(self)
	self.eventProxy_:addEventListener(xyd.event.GM_REPLY, handler(self, self.onTalkWithGm))
	self.eventProxy_:addEventListener(xyd.event.TALK_WITH_GM, handler(self, self.onTalkWithGm))
	self:waitForTime(1, function ()
		self.chat_:addAutoGMReply()
	end)
end

function ChatGMWindow:onTalkWithGm(event)
	if self.curSelect_ == xyd.MsgType.GM then
		self.chat_:setGmRedMark(false)

		local data = event.data

		if data.talker_id ~= xyd.Global.playerID and data.id ~= 1 then
			if self.chat_:getGmInfo() and (not data.channel or data.channel and data.channel ~= "exclusive") then
				return
			end

			if not self.chat_:getGmInfo() and data.channel and data.channel == "exclusive" then
				return
			end
		end

		self.chatPage_:addNewMsg(data)
	else
		self.chat_:setRedMark(xyd.RedMarkType.GM_CHAT, true)
	end
end

function ChatWindow:onSendImgTouch()
	if not self.chat_:checkCanUpLoad() then
		local limit = MiscTable:getVal("gm_image_limit") or 0

		xyd.alert(xyd.AlertType.TIPS, __("GM_UPLOAD_MAX_COUNT", limit))

		return
	end

	if self.curSelect_ == xyd.MsgType.GM then
		if UNITY_EDITOR then
			xyd.EventDispatcher.inner():dispatchEvent({
				name = xyd.event.SDK_PICK_UP_IMG,
				params = {
					opCode = 27,
					height = 1024,
					width = 657,
					path = "Pictures/aidehua_photo01.png"
				}
			})
		else
			xyd.SdkManager.get():getImageFromAlbum()
		end
	end
end

function ChatGMWindow:setSelect()
	self.curSelect_ = xyd.MsgType.GM

	self.chat_:setRedMark(self:getMsgTypeBySelect(self.curSelect_), false)
end

return ChatGMWindow
