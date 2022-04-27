local ChatWindow = import(".ChatWindow")
local MiscTable = xyd.tables.miscTable
local ArcticChatWindow = class("ArcticChatWindow", ChatWindow)
local RedMark = xyd.models.redMark
local MsgTypeList = {
	xyd.MsgType.ARCTIC_EXPEDITION_ASSEMBLE,
	xyd.MsgType.ARCTIC_EXPEDITION_SYS
}

function ArcticChatWindow:ctor(name, params)
	ArcticChatWindow.super.ctor(self, name, params)

	self.curSelect_ = xyd.MsgType.ARCTIC_EXPEDITION_ASSEMBLE
end

function ArcticChatWindow:getUIComponent()
	ArcticChatWindow.super.getUIComponent(self)

	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.groupTop2 = groupAction:NodeByName("groupTop2").gameObject
	self.btnTop25 = self.groupTop2:NodeByName("btnTop25").gameObject
	self.btnTop26 = self.groupTop2:NodeByName("btnTop26").gameObject
end

function ArcticChatWindow:setSelect()
	self.curSelect_ = xyd.MsgType.ARCTIC_EXPEDITION_ASSEMBLE

	self.chat_:setRedMark(self:getMsgTypeBySelect(self.curSelect_), false)
end

function ArcticChatWindow:setRedMark()
	RedMark:setMarkImg(xyd.RedMarkType.ARCTIC_CHAT_EXPEDITION_1, self.btnTop25:NodeByName("redIcon").gameObject)
	RedMark:setMarkImg(xyd.RedMarkType.ARCTIC_CHAT_EXPEDITION_2, self.btnTop26:NodeByName("redIcon").gameObject)
end

function ArcticChatWindow:updateTap()
	for k, v in ipairs(MsgTypeList) do
		local type_ = v
		self.oldRecords[type_] = self.chat_:getRecord(type_)
		local params = {
			strokeColor = 4294967295.0,
			color = 960513791,
			text = __("CHAT_TAP_" .. tostring(type_))
		}
		local btn = self["btnTop" .. tostring(type_)]

		if btn and self.curSelect_ == type_ then
			btn:GetComponent(typeof(UIButton)):SetEnabled(false)

			params.color = 4294967295.0
			params.strokeColor = 1012112383

			xyd.setBtnLabel(btn, params)
		elseif btn then
			btn:GetComponent(typeof(UIButton)):SetEnabled(true)
			xyd.setBtnLabel(btn, params)
		end
	end

	if self:checkShowImgBtn() then
		self.btnSendImg:SetActive(true)
		self.btnConfig_:SetActive(false)
	else
		self.btnSendImg:SetActive(false)
		self.btnConfig_:SetActive(true)
	end
end

function ArcticChatWindow:registerEvent()
	ArcticChatWindow.super.registerEvent(self)
	self.eventProxy_:addEventListener(xyd.event.EXPEDITION_CHAT_BACK, handler(self, self.onMessage))

	for k, v in ipairs(MsgTypeList) do
		local type_ = v
		local btn = self["btnTop" .. tostring(type_)]

		if btn then
			UIEventListener.Get(btn).onClick = function ()
				self:onTopTouch(type_)

				self.chat_.lastSelect = xyd.MsgType.NORMAL
			end
		end
	end
end

function ArcticChatWindow:onMessage(event)
	local msg = xyd.decodeProtoBuf(event.data)
	local eMsgId = tonumber(msg.e_msg_id) or 0

	if eMsgId == 0 then
		msg.type = xyd.MsgType.ARCTIC_EXPEDITION_NORMAL
	elseif eMsgId <= 5 then
		msg.type = xyd.MsgType.ARCTIC_EXPEDITION_SYS
	else
		msg.type = xyd.MsgType.ARCTIC_EXPEDITION_ASSEMBLE
	end

	local type_ = msg.type

	if self.chat_:checkMsgFilter(event.data) then
		return
	end

	local msgType = self:getMsgTypeBySelect(self.curSelect_)

	local function updateNowChat()
		self.chatPage_:addNewMsg(msg)

		if tonumber(msg.sender_id) == tonumber(xyd.models.selfPlayer.playerID_) and self.btnDown_.gameObject.activeSelf then
			self:waitForFrame(1, function ()
				self:onDownTouch()
			end)
		end
	end

	local function updateOtherChat(otherType)
		local otherChat = self.chatPageList_[self:getMsgTypeBySelect(otherType)]

		if otherChat then
			otherChat:addNewMsg(msg)
			self:waitForFrame(3, function ()
				otherChat:refreshAll()
			end)
		end
	end

	local channel = tonumber(msg.channel)

	if channel == 1 then
		if xyd.MsgType.ARCTIC_EXPEDITION_ASSEMBLE == self.curSelect_ then
			updateNowChat()
		else
			updateOtherChat(xyd.MsgType.ARCTIC_EXPEDITION_ASSEMBLE)
		end
	elseif channel == 2 then
		if xyd.MsgType.ARCTIC_EXPEDITION_SYS == self.curSelect_ then
			updateNowChat()
		else
			updateOtherChat(xyd.MsgType.ARCTIC_EXPEDITION_SYS)
		end
	end

	if msgType == type_ then
		self.chat_:setRecord(msgType)
		self.chat_:setRedMark(type_, false)
	end
end

return ArcticChatWindow
