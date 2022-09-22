local ChatWindow = class("ChatWindow", import(".BaseWindow"))
local ChatPage = import("app.components.ChatPage")
local PrivatePage = import("app.components.PrivatePage")
local ChatEmotionItem = import("app.components.ChatEmotionItem")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ChatPrivateItem = import("app.components.ChatPrivateItem")
local MiscTable = xyd.tables.miscTable
local FunctionTable = xyd.tables.functionTable
local FilterWordTable = xyd.tables.filterWordTable
local RedMark = xyd.models.redMark

function ChatWindow:ctor(name, params)
	ChatWindow.super.ctor(self, name, params)

	self.oldText_ = ""
	self.msgs_ = {}
	self.chatPageList_ = {}
	self.curSelect_ = xyd.MsgType.NORMAL
	self.maxHeight_ = 0
	self.viewHeight = 0
	self.oldRecords = {}
	self.isDetail = false
	self.ifArenaOpen = false

	if params and params.is_detail then
		self.isDetail = params.is_detail
	end

	if params and params.to_player_id then
		self.toPlayerId = params.to_player_id
	end

	if params and params.privateParams then
		self.privateParams = params.privateParams
	end

	self.chat_ = xyd.models.chat
	self.backpack_ = xyd.models.backpack
	self.guildModel_ = xyd.models.guild
	self.selfPlayer = xyd.models.selfPlayer
end

function ChatWindow:initWindow()
	ChatWindow.super.initWindow(self)
	self:getUIComponent()
	self:setRedMark()
	self:setSelect()
	self:layout()
	self:initConfig()
	self:initCollection()
	self:initDataGroup()
	self:updateTap()
	self:registerEvent()
	self:updatePlayerList()
	self:checkShowRecord()
	self:initBlackList()
end

function ChatWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.groupAction_ = groupAction
	self.allBg = groupAction:ComponentByName("e:Image", typeof(UISprite))
	self.mainList_ = groupAction:NodeByName("mainList").gameObject
	self.labelWinTitle = groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.imgListBg = groupAction:ComponentByName("imgListBg", typeof(UIWidget))
	self.groupTop = groupAction:NodeByName("groupTop").gameObject
	self.btnTop1 = groupAction:NodeByName("groupTop/btnTop1").gameObject
	self.btnTop13 = groupAction:NodeByName("groupTop/btnTop13").gameObject
	self.btnTop10 = groupAction:NodeByName("groupTop/btnTop10").gameObject
	self.btnTop7 = groupAction:NodeByName("groupTop/btnTop7").gameObject
	self.btnTop8 = groupAction:NodeByName("groupTop/btnTop8").gameObject
	self.topPanel = groupAction:NodeByName("topPanel").gameObject
	self.btnDown_ = self.topPanel:NodeByName("btnDown_").gameObject
	self.btnRecord = self.topPanel:NodeByName("btnRecord").gameObject
	self.groupNone_ = groupAction:NodeByName("groupNone_").gameObject
	self.labelNone_ = self.groupNone_:ComponentByName("labelNone_", typeof(UILabel))
	self.groupBottom = groupAction:NodeByName("groupBottom").gameObject
	self.btnConfig_ = self.groupBottom:NodeByName("btnConfig_").gameObject
	self.btnSendImg = self.groupBottom:NodeByName("btnSendImg").gameObject
	self.btnSend_ = self.groupBottom:NodeByName("btnSend_").gameObject
	self.btnEmo_ = self.groupBottom:NodeByName("btnEmo_").gameObject
	self.textEdit_ = self.groupBottom:ComponentByName("e:Group/textEdit_", typeof(UILabel))
	self.textBack_ = self.groupBottom:ComponentByName("e:Group/textBack_", typeof(UILabel))
	self.groupEmotion = groupAction:NodeByName("groupEmotion").gameObject
	self.imgConfigMask_1 = self.groupEmotion:NodeByName("imgConfigMask_1").gameObject
	self.groupConfig_ = groupAction:NodeByName("groupConfig_").gameObject
	self.imgConfigMask_ = self.groupConfig_:NodeByName("imgConfigMask_").gameObject
	self.guildOnlineGroup = groupAction:NodeByName("guildOnlineGroup").gameObject
	self.guildOnlineGroupBg = self.guildOnlineGroup:ComponentByName("e:Image", typeof(UISprite))
	self.onlineLabel = self.guildOnlineGroup:ComponentByName("onlineLabel", typeof(UILabel))
	self.groupPrivate = groupAction:NodeByName("groupPrivate").gameObject
	self.groupDetail = self.groupPrivate:NodeByName("groupDetail").gameObject
	self.groupMove = self.groupDetail:NodeByName("groupMove").gameObject
	self.groupWarning = self.groupDetail:NodeByName("groupWarning").gameObject
	self.groupBottom0 = self.groupDetail:NodeByName("groupBottom0").gameObject
	self.btnConfig1 = self.groupBottom0:NodeByName("btnConfig1").gameObject
	self.btnSend1 = self.groupBottom0:NodeByName("btnSend1").gameObject
	self.btnEmo1 = self.groupBottom0:NodeByName("btnEmo1").gameObject
	self.textEdit1 = self.groupBottom0:ComponentByName("e:Group/textEdit1", typeof(UILabel))
	self.groupWarningClick = self.groupWarning:NodeByName("e:Group").gameObject
	self.labelWarning_ = self.groupWarning:ComponentByName("e:Group/labelWarning_", typeof(UILabel))
	self.btnBack = self.groupDetail:NodeByName("groupTop/btnBack").gameObject
	self.btnDelete = self.groupDetail:NodeByName("groupTop/delBtn").gameObject
	self.labelPrivateName_ = self.groupDetail:ComponentByName("groupTop/groupTopMid/labelPrivateName_", typeof(UILabel))
	self.groupVip_ = self.groupDetail:ComponentByName("groupTop/groupTopMid/groupVip_", typeof(UIWidget))
	self.groupTopMidLayout = self.groupDetail:ComponentByName("groupTop/groupTopMid", typeof(UILayout))
	self.groupPlayerType_ = self.groupDetail:NodeByName("groupTop/groupTopMid/groupPlayerType_").gameObject
	self.labelPlayerType_ = self.groupPlayerType_:ComponentByName("labelPlayerType_", typeof(UILabel))
	self.groupPrivateServer = self.groupDetail:NodeByName("groupTop/groupTopMid/groupPrivateServer").gameObject
	self.labelServer = self.groupPrivateServer:ComponentByName("labelServer", typeof(UILabel))
	self.scrollerPrivateList = self.groupPrivate:ComponentByName("scrollerPrivateList", typeof(UIScrollView))
	self.mainContent = groupAction:NodeByName("mainContent").gameObject

	self.mainContent:SetActive(false)

	self.scroller_uiPanel = self.mainContent:ComponentByName("scroller", typeof(UIPanel))

	xyd.addTextInput(self.textEdit_, {
		type = xyd.TextInputArea.InputSingleLine
	})
	xyd.addTextInput(self.textEdit1, {
		type = xyd.TextInputArea.InputSingleLine
	})
end

function ChatWindow:initBlackList()
	self.chat_:getBlackList()
end

function ChatWindow:getScrollerUiPanel()
	return self.chatPage_:getUIpanel()
end

function ChatWindow:setRedMark()
	if self.btnTop1 then
		RedMark:setMarkImg(xyd.RedMarkType.CHAT, self.btnTop1:NodeByName("redIcon").gameObject)
	end

	if self.btnTop13 then
		RedMark:setMarkImg(xyd.RedMarkType.LOCAL_CHAT, self.btnTop13:NodeByName("redIcon").gameObject)
	end

	if self.btnTop10 then
		RedMark:setMarkImg(xyd.RedMarkType.CROSS_CHAT, self.btnTop10:NodeByName("redIcon").gameObject)
	end

	if self.btnTop7 then
		if self.guildModel_.guildID < 0 then
			RedMark:setMarkImg(xyd.RedMarkType.RECRUIT_CHAT, self.btnTop7:NodeByName("redIcon").gameObject)
		else
			RedMark:setMarkImg(xyd.RedMarkType.GUILD_CHAT, self.btnTop7:NodeByName("redIcon").gameObject)
		end
	end

	if self.btnTop8 then
		RedMark:setMarkImg(xyd.RedMarkType.PRIVATE_CHAT, self.btnTop8:NodeByName("redIcon").gameObject)
	end
end

function ChatWindow:layout()
	self.labelWarning_.text = __("PRIVACY_WARNING_TEXT04")
	self.btnSend_:ComponentByName("button_label", typeof(UILabel)).text = __("SEND")
	self.btnSend1:ComponentByName("button_label", typeof(UILabel)).text = __("SEND")
	self.labelNone_.text = __("NO_PRIVATE_MESSAGE")
	self.oldText_ = self.chat_:getLastWord()
	self.textEdit_.text = self.oldText_

	if self.curSelect_ == xyd.MsgType.PRIVATE then
		self.textEdit_.text = ""
	end

	for i = 1, 13 do
		self.oldRecords[i] = self.chat_:getRecord(i)
		local btn = self["btnTop" .. tostring(i)]

		if btn then
			local label = btn:ComponentByName("button_label", typeof(UILabel))
			label.text = __("CHAT_TAP_" .. tostring(i))

			if i == 7 and self.guildModel_.guildID > 0 then
				label.text = __("CHAT_TAP_6")
			end
		end
	end
end

function ChatWindow:initEmotion()
	self.chatEmotion_ = ChatEmotionItem.new(self.groupEmotion)

	self.chatEmotion_:setInfo()
end

function ChatWindow:solveMultiLang()
	if xyd.Global.lang == "en_en" then
		self.btnRecord.labelDisplay.x = 45
	end
end

function ChatWindow:getCurSelect()
	return self.curSelect_
end

function ChatWindow:initCollection()
	for i = 1, 3 do
		local msgs = self.chat_:getMsgsByTypeWithFilter(i)
		self.msgs_[i] = msgs
	end
end

function ChatWindow:initDataGroup()
	local msgType = self:getMsgTypeBySelect(self.curSelect_)

	if not self.chatPageList_[self.curSelect_] then
		local newGameObject = NGUITools.AddChild(self.mainList_.gameObject, self.mainContent.gameObject)

		newGameObject:SetActive(true)

		self.chatPageList_[self.curSelect_] = ChatPage.new(newGameObject, self)
		self.chatPage_ = self.chatPageList_[self.curSelect_]

		if msgType == xyd.MsgType.GUILD and xyd.models.guild.guildID > 0 then
			self.guildOnlineGroup:SetActive(true)
			self:getScrollerUiPanel():GetComponent(typeof(UIRect)):SetTopAnchor(self.guildOnlineGroupBg.gameObject, 0, -10)

			self.onlineLabel.text = __("GUILD_CHAT_ONLINE_TEXT", xyd.models.guild:getOnlineCount())
		end

		self.chatPage_:setInfoType(msgType)
		self.chatPage_:init()
	else
		self.chatPage_ = self.chatPageList_[self.curSelect_]

		if msgType == xyd.MsgType.GUILD and xyd.models.guild.guildID > 0 then
			self.guildOnlineGroup:SetActive(true)
			self:getScrollerUiPanel():GetComponent(typeof(UIRect)):SetTopAnchor(self.guildOnlineGroupBg.gameObject, 0, -10)

			self.onlineLabel.text = __("GUILD_CHAT_ONLINE_TEXT", xyd.models.guild:getOnlineCount())
		end

		self.chatPage_:setInfoType(msgType)
	end

	for _, item in pairs(self.chatPageList_) do
		if item.infoType_ ~= msgType then
			item.go_:SetActive(false)
		else
			item.go_:SetActive(true)
		end
	end
end

function ChatWindow:updateDataGroup()
	local msgType = self:getMsgTypeBySelect(self.curSelect_)

	if not self.chatPageList_[self.curSelect_] then
		local newGameObject = NGUITools.AddChild(self.mainList_.gameObject, self.mainContent.gameObject)

		newGameObject:SetActive(true)

		self.chatPageList_[self.curSelect_] = ChatPage.new(newGameObject, self)
		self.chatPage_ = self.chatPageList_[self.curSelect_]

		if msgType == xyd.MsgType.GUILD and xyd.models.guild.guildID > 0 then
			self.guildOnlineGroup:SetActive(true)
			self:getScrollerUiPanel():GetComponent(typeof(UIRect)):SetTopAnchor(self.guildOnlineGroupBg.gameObject, 0, -10)

			self.onlineLabel.text = __("GUILD_CHAT_ONLINE_TEXT", xyd.models.guild:getOnlineCount())
		end

		self.chatPage_:setInfoType(msgType)
		self.chatPage_:init()
	else
		self.chatPage_ = self.chatPageList_[self.curSelect_]

		if msgType == xyd.MsgType.GUILD and xyd.models.guild.guildID > 0 then
			self.guildOnlineGroup:SetActive(true)
			self:getScrollerUiPanel():GetComponent(typeof(UIRect)):SetTopAnchor(self.guildOnlineGroupBg.gameObject, 0, -10)

			self.onlineLabel.text = __("GUILD_CHAT_ONLINE_TEXT", xyd.models.guild:getOnlineCount())
		end

		self.chatPage_:setInfoType(msgType)
	end

	for _, item in pairs(self.chatPageList_) do
		if item.infoType_ ~= msgType then
			item.go_:SetActive(false)
		else
			item.go_:SetActive(true)
		end
	end
end

function ChatWindow:initPrivatePage()
	if not self.privatePage_ then
		self.privatePage_ = PrivatePage.new(self.groupMove, self)
	end
end

function ChatWindow:setEmotionVisible()
	self.groupEmotion.visible = false
end

function ChatWindow:changeData(isTouchTap)
	if isTouchTap == nil then
		isTouchTap = false
	end

	if self.curSelect_ == xyd.MsgType.PRIVATE then
		if self.ifArenaOpen == true then
			self.ifArenaOpen = false

			return
		end

		if self.groupPrivate.activeSelf == true then
			self.chat_:getPlayerMessages(self.toPlayerId)
		else
			self:updatePlayerList()
		end

		return
	end

	self:updateDataGroup()

	if self.curSelect_ == xyd.MsgType.GM then
		XYDCo.WaitForFrame(1, function ()
			self.chat_:addAutoGMReply()
		end, nil)
	end
end

function ChatWindow:updateTap()
	for i = 1, 13 do
		local params = {
			color = 960513791,
			strokeColor = 4294967295.0
		}
		local btn = self["btnTop" .. tostring(i)]

		if btn and self.curSelect_ == i then
			btn:GetComponent(typeof(UIButton)):SetEnabled(false)

			params = {
				color = 4294967295.0,
				strokeColor = 1012112383
			}

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

function ChatWindow:checkShowImgBtn()
	local limitLev = MiscTable:getVal("gm_image_open_lv") or 0

	if xyd.Global.playerLev < tonumber(limitLev) then
		return false
	end

	if self.curSelect_ == xyd.MsgType.GM then
		return true
	end

	return false
end

function ChatWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.btnSend_).onClick = handler(self, self.onSend)

	for i = 1, 13 do
		local btn = self["btnTop" .. tostring(i)]

		if btn then
			UIEventListener.Get(btn).onClick = function ()
				self:onTopTouch(i)
			end
		end
	end

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnConfig_).onClick = handler(self, self.onShowConfig)
	UIEventListener.Get(self.imgConfigMask_).onClick = handler(self, self.onHideConfig)
	UIEventListener.Get(self.imgConfigMask_1).onClick = handler(self, self.onHideEmotion)
	UIEventListener.Get(self.btnDown_).onClick = handler(self, self.onDownTouch)
	UIEventListener.Get(self.btnRecord).onClick = handler(self, self.onRecordTouch)
	UIEventListener.Get(self.btnEmo_).onClick = handler(self, self.onEmo)
	UIEventListener.Get(self.btnBack).onClick = handler(self, self.onBack)
	UIEventListener.Get(self.btnConfig1).onClick = handler(self, self.onShowConfig)
	UIEventListener.Get(self.btnSendImg).onClick = handler(self, self.onSendImgTouch)
	UIEventListener.Get(self.btnEmo1).onClick = handler(self, self.onEmo)
	UIEventListener.Get(self.btnSend1).onClick = handler(self, self.onSend)
	UIEventListener.Get(self.groupWarningClick).onClick = handler(self, self.onWarning)

	self.eventProxy_:addEventListener(xyd.event.CHAT_MESSAGE, handler(self, self.onMessage))
	self.eventProxy_:addEventListener(xyd.event.GUILD_APPLY, handler(self, self.onGuildApply))
	self.eventProxy_:addEventListener(xyd.event.GET_PLAYER_MESSAGES, handler(self, self.onPrivateDetail))
	self.eventProxy_:addEventListener(xyd.event.UNIFORM_ERROR, handler(self, self.onError))
	self.eventProxy_:addEventListener(xyd.event.ERROR_MESSAGE, handler(self, self.onErrorMessage))
	self.eventProxy_:addEventListener(xyd.event.ARENA_GET_ENEMY_INFO, handler(self, self.onGetInfo))
	self.eventProxy_:addEventListener(xyd.event.PRIVATE_MESSAGE, handler(self, self.onPrivateMessage))
	self.eventProxy_:addEventListener(xyd.event.CHAT_WITH_PLAYER, handler(self, self.onSendPrivateRes))
	self.eventProxy_:addEventListener(xyd.event.SEND_CROSS_MESSAGE, handler(self, self.onSendCrossMessages))
	self.eventProxy_:addEventListener(xyd.event.REPORT_MESSAGE, handler(self, self.onReportMessage))
	self.eventProxy_:addEventListener(xyd.event.SDK_PICK_UP_IMG, handler(self, self.onSDKPickImg))
	self.eventProxy_:addEventListener(xyd.event.REMOVE_CHAT_PLAYER, handler(self, self.updatePlayerList))
	self.eventProxy_:addEventListener(xyd.event.COPY_PLAYER_NAME, handler(self, self.onCopyPlayerName))
	self.eventProxy_:addEventListener(xyd.event.GET_INFO_BY_GUILD_ID, function (self, event)
		local win = xyd.WindowManager.get():getWindow("arena_formation_window")

		if win then
			return
		end

		xyd.WindowManager.get():openWindow("guild_apply_detail_window", {
			data = event.data.guild_info
		})
	end, self)

	UIEventListener.Get(self.btnDelete).onClick = handler(self, self.onDelete)
end

function ChatWindow:onWarning()
	xyd.WindowManager:get():openWindow("privacy_warning_window")
end

function ChatWindow:onDelete()
	xyd.alertYesNo(__("DELETE_CHAT_FOR_SURE"), function (yes_no)
		if yes_no then
			xyd.models.chat:deleteChatMsg(self.privateParams.player_id)
			self:onBack()
		end
	end)
end

function ChatWindow:onCopyPlayerName(event)
	local text = event.data.text or ""
	local type = self:getMsgTypeBySelect(self.curSelect_)

	if type == xyd.MsgType.RECRUIT or type == xyd.MsgType.PRIVATE then
		return
	end

	self.textEdit_.text = self.textEdit_.text .. "@" .. text
end

function ChatWindow:onHideEmotion()
	self.groupEmotion:SetActive(false)
end

function ChatWindow:onEmo()
	local v = not self.groupEmotion.activeSelf

	self.groupEmotion:SetActive(v)

	if not self.chatEmotion_ then
		self:initEmotion()
	end
end

function ChatWindow:onTopTouch(index)
	local lastIndex = self.curSelect_
	self.curSelect_ = index

	self:updateBottomShow(index)
	self.btnDown_:SetActive(false)
	self:updateTap()
	self:checkShowRecord()

	if self.curSelect_ ~= xyd.MsgType.PRIVATE then
		self.groupPrivate:SetActive(false)
		self.groupDetail:SetActive(false)
		self.mainContent:SetActive(true)
		self:changeData(true)
	else
		for _, item in pairs(self.chatPageList_) do
			item.go_:SetActive(false)
		end
	end

	self:waitForFrame(1, function ()
		self:updateRect(index)
	end)

	self.chat_.lastSelect = index

	if index == xyd.MsgType.PRIVATE then
		return
	end

	if index == xyd.MsgType.GM then
		self.chat_:setGmRedMark(false)
	else
		self.chat_:setRedMark(self:getMsgTypeBySelect(index), false)
	end
end

function ChatWindow:updateRect(index)
	if index ~= xyd.MsgType.PRIVATE then
		self.groupNone_:SetActive(false)

		self.imgListBg.height = 693

		self.imgListBg:SetLocalPosition(0, -15, 0)
	end

	if index == xyd.MsgType.PRIVATE then
		self:updatePlayerList()

		if self.isDetail == true then
			self.chat_:getPlayerMessages(self.toPlayerId)
		end

		self.imgListBg.height = 764

		self.imgListBg:SetLocalPosition(0, -51, 0)
	end

	local w = self:getScrollerUiPanel():GetComponent(typeof(UIRect))

	if index == xyd.MsgType.RECRUIT and self.guildModel_.guildID <= 0 then
		if not xyd.checkFunctionOpen(xyd.FunctionID.GUILD) then
			return
		end

		xyd.alert(xyd.AlertType.YES_NO, __("GUILD_TEXT08"), function (yes_no)
			if not yes_no then
				return
			end

			xyd.WindowManager:get():openWindow("guild_join_window")
		end)
		self.guildOnlineGroup:SetActive(false)
		w:SetTopAnchor(self.imgListBg.gameObject, 1, -4)
	elseif index == xyd.MsgType.RECRUIT and self.guildModel_.guildID > 0 then
		if self.curSelect_ == xyd.MsgType.RECRUIT then
			self.guildOnlineGroup:SetActive(true)
			w:SetTopAnchor(self.imgListBg.gameObject, 1, -64)
		end

		self.onlineLabel.text = __("GUILD_CHAT_ONLINE_TEXT", xyd.models.guild:getOnlineCount())
	else
		self.guildOnlineGroup:SetActive(false)
		w:SetTopAnchor(self.imgListBg.gameObject, 1, -4)
	end
end

function ChatWindow:updateBottomShow(index)
	if index == xyd.MsgType.PRIVATE and self.isDetail == false then
		self.groupBottom:SetActive(false)
	elseif index == xyd.MsgType.PRIVATE and self.isDetail == true then
		self.groupBottom:SetActive(false)
	elseif index == xyd.MsgType.RECRUIT then
		if self.guildModel_.guildID > 0 then
			self.groupBottom:SetActive(true)
		else
			self.groupBottom:SetActive(false)
		end
	else
		self.groupBottom:SetActive(true)
	end
end

function ChatWindow:initPlayerList()
	local scrollView = self.scrollerPrivateList
	local wrapContent = scrollView:ComponentByName("itemList", typeof(UIWrapContent))
	local item = scrollView:NodeByName("private_list_item").gameObject
	self.privateListWrapContent_ = FixedWrapContent.new(scrollView, wrapContent, item, ChatPrivateItem, self)
end

function ChatWindow:updatePlayerList()
	if self.curSelect_ == xyd.MsgType.PRIVATE and self.groupDetail.activeSelf == false then
		self.groupPrivate:SetActive(true)

		if not self.notSetPos0 then
			self.scrollerPrivateList:X(0)
		end

		self.mainContent:SetActive(false)
		self:updateBottomShow(self.curSelect_)

		if not self.privateListWrapContent_ then
			self:initPlayerList()
		end

		local tmpList = self.chat_:getPrivateList()

		if tmpList == nil then
			return
		end

		if #tmpList == 0 then
			self.groupNone_:SetActive(true)
		else
			self.groupNone_:SetActive(false)
		end

		self.chat_.redNum = 0
		local list = {}

		for i = 1, #tmpList do
			if not self.chat_:isInBlackList(tmpList[i].player_id) and not self.chat_:checkIsSuperFilterWord(tmpList[i].chat_msg.sender_id, tmpList[i].chat_msg.content) then
				table.insert(list, tmpList[i])
			end
		end

		self.privateListWrapContent_:setInfos(list, {})

		self.imgListBg.height = 764

		self.imgListBg:SetLocalPosition(0, -51, 0)

		self.notSetPos0 = false
	end
end

function ChatWindow:onSendPrivateRes(event)
	local isEmo = string.find(event.data.content, "#emotion")
	local isGif = string.find(event.data.content, "#gif")

	if not isEmo and not isGif then
		self.textEdit1.text = ""
	end

	if self.curSelect_ == xyd.MsgType.PRIVATE and self.groupDetail.activeSelf == true then
		local tmpMsg = event.data
		local selfParams = {
			avatar_id = self.selfPlayer:getAvatarID(),
			avatar_frame_id = self.selfPlayer:getAvatarFrameID(),
			sender_lev = xyd.Global.playerLev,
			time = xyd:getServerTime(),
			sender_id = xyd.Global.playerID,
			content = tmpMsg.content,
			type = xyd.MsgType.PRIVATE
		}

		self.privatePage_:addNewMsg(selfParams)
	end
end

function ChatWindow:onSendCrossMessages(event)
end

function ChatWindow:setPlyaerListPos(posx)
	self.scrollerPrivateList:X(posx)
end

function ChatWindow:onPrivateDetail(event)
	if self.reqIngEnemyInfo then
		self.tempPrivateDetailEvent = event

		return
	end

	self.tempPrivateDetailEvent = nil
	local tmpList = event.data.messages
	local modelList = xyd.models.chat:getPrivateList()

	if self.privateParams == nil then
		xyd.models.arena:reqEnemyInfo(self.toPlayerId)
		self.chat_:getPlayerMessages(self.toPlayerId)

		return
	end

	local isFirstInit = false

	if not self.privatePage_ then
		self:initPrivatePage()

		isFirstInit = true
	end

	self.groupDetail:SetActive(true)
	self.scrollerPrivateList:X(10000)

	if self.privateServerID and self.privateServerID ~= self.selfPlayer:getServerID() then
		self.groupPrivateServer:SetActive(true)

		self.labelServer.text = xyd.getServerNumber(self.privateServerID)
	else
		self.groupPrivateServer:SetActive(false)
	end

	self.labelPrivateName_.text = "[b]" .. self.privateParams.player_name
	local tmpNpInfo = event.data.np_info
	local tmpPlayerType = tmpNpInfo.player_type
	local tmpVip = tmpNpInfo.vip
	local tmpShowVip = tmpNpInfo.show_vip
	local chatPrivateList = {}
	local maxTime = 0

	for i = 1, #tmpList do
		if not self.chat_:checkIsSuperFilterWord(tmpList[i].sender_id, tmpList[i].content) then
			local item = nil
			local otherParams = {
				content = "",
				time = 0,
				avatar_id = self.privateParams.avatar_id,
				avatar_frame_id = self.privateParams.avatar_frame_id,
				sender_lev = self.privateParams.lev,
				sender_id = self.privateParams.player_id
			}
			local selfParams = {
				content = "",
				time = 0,
				avatar_id = self.selfPlayer:getAvatarID(),
				avatar_frame_id = self.selfPlayer:getAvatarFrameID(),
				sender_lev = xyd.Global.playerLev,
				sender_id = xyd.Global.playerID
			}

			if tmpList[i].time and maxTime < tmpList[i].time then
				maxTime = tmpList[i].time
			end

			if tmpList[i].sender_id == xyd.Global.playerID then
				selfParams.time = tmpList[i].time
				selfParams.content = tmpList[i].content
				item = selfParams
			else
				otherParams.time = tmpList[i].time
				otherParams.content = tmpList[i].content
				item = otherParams
			end

			if item then
				item.type = xyd.MsgType.PRIVATE
				item.hashCode = i

				table.insert(chatPrivateList, item)
			end
		end
	end

	for i = 1, #modelList do
		if modelList[i].player_id == self.privateParams.player_id and maxTime < modelList[i].chat_msg.time then
			local item = {
				avatar_id = self.selfPlayer:getAvatarID(),
				avatar_frame_id = self.selfPlayer:getAvatarFrameID(),
				sender_lev = xyd.Global.playerLev,
				time = modelList[i].chat_msg.time,
				sender_id = xyd.Global.playerID,
				content = modelList[i].chat_msg.content,
				type = xyd.MsgType.PRIVATE,
				hashCode = i
			}

			table.insert(chatPrivateList, item)
		end
	end

	chatPrivateList = self.chat_:sortMsgByTime(chatPrivateList)

	if next(chatPrivateList) then
		xyd.db.chat:setValue({
			key = "private" .. tostring(self.privateParams.player_id),
			value = chatPrivateList[#chatPrivateList].time
		})
	end

	self.isDetail = false

	self.privatePage_:setInfo(chatPrivateList)

	if isFirstInit then
		self.privatePage_:init()
	else
		self.privatePage_:refreshAll()
	end

	self:initIcons(self.groupVip_, tmpShowVip, tmpVip)
	self.groupTopMidLayout:Reposition()
end

function ChatWindow:initIcons(parent, tmpShowVip, tmpVip)
	NGUITools.DestroyChildren(parent.transform)

	local parentWidget = parent
	parent = parent.gameObject

	parent:SetActive(false)

	if tmpShowVip == 1 and tmpVip > 0 then
		parent:SetActive(true)

		local group = NGUITools.AddChild(parent, "group")
		local wd = group:AddComponent(typeof(UIWidget))
		local img = NGUITools.AddChild(group, "img")
		local sp = img:AddComponent(typeof(UISprite))

		xyd.setUISpriteAsync(sp, nil, "vip_icon", function ()
			sp:MakePixelPerfect()
		end)

		sp.depth = parentWidget.depth + 10
		wd.height = sp.height
		wd.width = sp.width
		wd.depth = parentWidget.depth + 10
		local group2 = NGUITools.AddChild(parent, "group2")
		local wd2 = group2:AddComponent(typeof(UIWidget))
		wd2.height = 20
		wd2.width = 36 + 12 * tostring(math.floor(tmpVip / 10))
		wd2.depth = parentWidget.depth + 10
		local ly2 = group2:AddComponent(typeof(UILayout))
		ly2.gap = Vector2(-2, 0)

		ly2:Reposition()

		local img2 = NGUITools.AddChild(group2, "img2")
		local sp2 = img2:AddComponent(typeof(UISprite))

		xyd.setUISpriteAsync(sp2, nil, "vip_text_abbr", function ()
			sp2:MakePixelPerfect()
		end)

		sp2.depth = parentWidget.depth + 10

		if tmpVip >= 10 then
			local vip1 = NGUITools.AddChild(group2, "vip1"):AddComponent(typeof(UISprite))

			xyd.setUISpriteAsync(vip1, nil, "player_vip_num_" .. tostring(math.floor(tmpVip / 10)), function ()
				vip1:MakePixelPerfect()
			end)

			vip1.depth = parentWidget.depth + 10
			local vip2 = NGUITools.AddChild(group2, "vip2"):AddComponent(typeof(UISprite))

			xyd.setUISpriteAsync(vip2, nil, "player_vip_num_" .. tostring(tmpVip % 10), function ()
				vip2:MakePixelPerfect()
			end)

			vip2.depth = parentWidget.depth + 10
		else
			local vip = NGUITools.AddChild(group2, "vip"):AddComponent(typeof(UISprite))

			xyd.setUISpriteAsync(vip, nil, "player_vip_num_" .. tostring(tmpVip), function ()
				vip:MakePixelPerfect()
			end)

			vip.depth = parentWidget.depth + 10
		end

		parent:GetComponent(typeof(UIWidget)).width = wd.width + wd2.width
		parent:GetComponent(typeof(UILayout)).gap = Vector2(2, 0)

		parent:GetComponent(typeof(UILayout)):Reposition()
	end
end

function ChatWindow:onPrivateMessage(event)
	if self.curSelect_ == xyd.MsgType.PRIVATE and self.groupDetail.activeSelf == true and self.privateParams.player_id == event.data.sender_id then
		local tmpMsg = event.data
		local otherParams = {
			avatar_id = self.privateParams.avatar_id,
			sender_lev = self.privateParams.lev,
			time = tmpMsg.time,
			sender_id = self.privateParams.player_id,
			content = tmpMsg.content,
			type = xyd.MsgType.PRIVATE
		}

		self.privatePage_:addNewMsg(otherParams)
		xyd.db.chat:setValue({
			key = "private" .. tostring(self.privateParams.player_id),
			value = tmpMsg.time
		})
		self.chat_:recordDialog(tmpMsg.content)
	elseif self.curSelect_ == xyd.MsgType.PRIVATE and self.groupDetail.activeSelf == false then
		self.chat_:updatePlayerList()
	end
end

function ChatWindow:onGetInfo(event)
	self.privateParams = event.data
	self.reqIngEnemyInfo = false

	if self.tempPrivateDetailEvent then
		self:onPrivateDetail(self.tempPrivateDetailEvent)
	end
end

function ChatWindow:onError(event)
	if event.data.error_mid == xyd.mid.CHAT_WITH_PLAYER and event.data.error_code ~= xyd.ErrorCode.CHAT_HAS_BEEN_BANNED then
		xyd.alert(xyd.AlertType.TIPS, __("CHAT_HAS_BEEN_SHIELDED"))
	end
end

function ChatWindow:onErrorMessage(event)
	if event.data.error_mid == xyd.mid.CHAT_WITH_PLAYER and event.data.error_code == xyd.ErrorCode.PRIVATE_IN_BLACKLIST then
		self.chat_:showFakeMsg()
	end
end

function ChatWindow:onBack()
	self.isDetail = false

	self.groupDetail:SetActive(false)
	self.scrollerPrivateList:X(0)
	self:updatePlayerList()
end

function ChatWindow:checkShowRecord()
	local type = self:getMsgTypeBySelect(self.curSelect_)
	local record = self.oldRecords[type] or 1

	if record < 0 or type == xyd.MsgType.PRIVATE then
		self.btnRecord:SetActive(false)

		return
	end

	local msgs = self.chat_:getMsgsByTypeWithFilter(type)
	local num = #msgs

	if record >= num - 7 then
		self.oldRecords[type] = -1

		self.chat_:setRecord(type)
		self.btnRecord:SetActive(false)

		return
	end

	self.btnRecord:SetActive(true)

	self.btnRecord:ComponentByName("button_label", typeof(UILabel)).text = __("CHAT_RECORD_NUM", num - record)

	if self.name_ == "chat_gm_window" then
		self.btnRecord:SetActive(false)
	end
end

function ChatWindow:onRecordTouch()
	self.btnRecord:SetActive(false)

	local type_ = self:getMsgTypeBySelect(self.curSelect_)
	local record = self.oldRecords[type_] or -1

	if record < 0 then
		return
	end

	self:hideRecordBtn()
	self:onScrollChange()
	self.chatPage_:scrollToItemByInfoID(record)
end

function ChatWindow:updateUnreadStatus(id)
	local type = self:getMsgTypeBySelect(self.curSelect_)
	local record = self.oldRecords[type] or -1

	if record > -1 and id <= record then
		self:hideRecordBtn()
	end
end

function ChatWindow:onScrollChange()
	local flag = self.chatPage_:checkShowDown()

	if self.btnDown_ and not tolua.isnull(self.btnDown_.gameObject) then
		self.btnDown_:SetActive(flag)

		if self.curSelect_ == xyd.MsgType.PRIVATE then
			self.btnDown_:SetActive(false)
		end
	end
end

function ChatWindow:hideRecordBtn()
	local type = self:getMsgTypeBySelect(self.curSelect_)

	self.btnRecord:SetActive(false)

	self.oldRecords[type] = -1

	self.chat_:setRecord(type)
end

function ChatWindow:onMessage(event)
	local type = event.data.type

	if self.chat_:checkMsgFilter(event.data) then
		return
	end

	if self.chat_:getConfigByIndex(xyd.ChatConfig.SHOW_WORLD) == 0 and xyd.MsgType2Index[type] == xyd.MsgType2Index[xyd.MsgType.NORMAL] then
		return
	end

	if self.chat_:getConfigByIndex(xyd.ChatConfig.SHOW_GUILD) == 0 and type == xyd.MsgType.GUILD then
		return
	end

	if self.chat_:getConfigByIndex(xyd.ChatConfig.SHOW_RECRUIT) == 0 and type == xyd.MsgType.RECRUIT then
		return
	end

	if self.chat_:getConfigByIndex(xyd.ChatConfig.SHOW_CROSS) == 0 and type == xyd.MsgType.CROSS_CHAT then
		return
	end

	if self.chat_:getConfigByIndex(xyd.ChatConfig.SHOW_LOCAL) == 0 and type == xyd.MsgType.LOCAL_CHAT then
		return
	end

	local msgType = self:getMsgTypeBySelect(self.curSelect_)

	if xyd.MsgType2Index[msgType] == xyd.MsgType2Index[type] then
		local data = event.data

		self.chatPage_:addNewMsg(data)

		if tonumber(data.sender_id) == tonumber(xyd.models.selfPlayer.playerID_) and self.btnDown_.gameObject.activeSelf then
			self:waitForFrame(1, function ()
				self:onDownTouch()
			end)
		end
	else
		local otherChat = self.chatPageList_[self:getMsgTypeBySelect(type)]
		local data = event.data

		if otherChat then
			otherChat:addNewMsg(data)
			self:waitForFrame(3, function ()
				otherChat:refreshAll()
			end)
		end
	end

	if msgType == type then
		self.chat_:setRecord(msgType)
		self.chat_:setRedMark(type, false)
	end
end

function ChatWindow:onTalkWithGm(event)
	if self.curSelect_ == xyd.MsgType.GM then
		local data = event.data
		data.type = xyd.MsgType.GM

		self:scrollGroup(data)
		self.chat_:setGmRedMark(false)
	else
		self.chat_:setRedMark(xyd.RedMarkType.GM_CHAT, true)
	end
end

function ChatWindow:onSend()
	if self:checkIsGm() then
		return
	end

	local type = self:getMsgTypeBySelect(self.curSelect_)

	if type ~= xyd.MsgType.GUILD and type ~= xyd.MsgType.GM and not xyd.checkFunctionOpen(xyd.FunctionID.CHAT, true) then
		xyd.showToast(__("CHAT_LIMIT_TEXT01"))

		return
	end

	if not self:checkValid(type) then
		return
	end

	if type == xyd.MsgType.GUILD then
		self.chat_:sendGuildMsg(self.textEdit_.text, type)
	elseif type == xyd.MsgType.GM then
		self.chat_:talkWithGM(self.textEdit_.text)
	elseif type == xyd.MsgType.PRIVATE then
		if self.chat_:isInBlackList(self.toPlayerId) == true then
			xyd.alert(xyd.AlertType.TIPS, __("CHAT_HAS_SHIELD"))

			return
		else
			self.chat_:sendPrivateMsg(self.textEdit1.text, self.toPlayerId)
		end
	elseif type == xyd.MsgType.CROSS_CHAT then
		self.chat_:sendCrossMsg(self.textEdit_.text, type)
	elseif type == xyd.MsgType.LOCAL_CHAT then
		self.chat_:sendLocalMsg(self.textEdit_.text, type)
	elseif type == xyd.MsgType.ARCTIC_EXPEDITION_ASSEMBLE then
		self.chat_:sendArcticMsg(self.textEdit_.text, type)
	elseif type == xyd.MsgType.ARCTIC_EXPEDITION_SYS then
		return
	else
		self.chat_:sendServerMsg(self.textEdit_.text, type)
	end

	if type ~= xyd.MsgType.PRIVATE then
		self.textEdit_.text = ""
	end

	self.oldText_ = ""
end

function ChatWindow:checkIsGm()
	local text = self.textEdit_.text or ""
	local index = string.find(text, "#gm")

	if index then
		local gmStr = string.sub(text, 5)

		if #gmStr > 0 then
			xyd.models.gMcommand:request(gmStr)
		end

		return true
	end

	return false
end

function ChatWindow:checkValid(type)
	local msg = xyd.trim(self.textEdit_.text)
	local len = xyd.getStrLength(msg)
	local flag = true
	local tips = ""
	local lev = tonumber(MiscTable:getVal("talk_level"))
	local cd = tonumber(MiscTable:getVal("talk_cd"))
	local guildCD = tonumber(MiscTable:getVal("talk_guild_cd"))
	local maxLen = tonumber(MiscTable:getVal("qa_content_length"))
	local curCd = xyd.getServerTime() - self.chat_:getLastTalk(type)

	if type == xyd.MsgType.PRIVATE and self.groupPrivate.activeSelf == true then
		msg = xyd.trim(self.textEdit1.text)
		len = xyd.getStrLength(msg)
	elseif type == xyd.MsgType.RECRUIT and self.guildModel_.guildID <= 0 then
		flag = false
		tips = __("HOUSE_TEXT_54")
	end

	if len <= 0 then
		flag = false
		tips = __("CHAT_NO_NULL")
	elseif FilterWordTable:isInWords(msg) then
		self.textEdit_.text = FilterWordTable:illegalReplace(self.textEdit_.text)
	elseif self.chat_:getConfigByIndex(xyd.ChatConfig.SHOW_GUILD) == 0 and type == xyd.MsgType.GUILD then
		flag = false
		tips = __("GUILD_TEXT09")
	elseif self.chat_:getConfigByIndex(xyd.ChatConfig.SHOW_WORLD) == 0 and type == xyd.MsgType.NORMAL then
		flag = false
		tips = __("CHAT_HIDE_WORLD")
	elseif self.chat_:getConfigByIndex(xyd.ChatConfig.SHOW_CROSS) == 0 and type == xyd.MsgType.CROSS_CHAT then
		flag = false
		tips = __("CHAT_HIDE_CROSS")
	elseif self.chat_:getConfigByIndex(xyd.ChatConfig.SHOW_LOCAL) == 0 and type == xyd.MsgType.LOCAL_CHAT then
		flag = false
		tips = __("CHAT_HIDE_LOCAL")
	elseif self.backpack_:getLev() < tonumber(lev) and (type == xyd.MsgType.NORMAL or type == xyd.MsgType.PRIVATE) then
		flag = false
		tips = __("CHAT_LIMIT_LEV", lev)
	elseif cd - curCd > 0 and (type == xyd.MsgType.NORMAL or type == xyd.MsgType.CROSS_CHAT or type == xyd.MsgType.LOCAL_CHAT) then
		flag = false
		tips = __("CHAT_LIMIT_TIME", cd - curCd)
	elseif guildCD - curCd > 0 and type == xyd.MsgType.GUILD then
		flag = false
		tips = __("CHAT_LIMIT_TIME", guildCD - curCd)
	elseif maxLen < len then
		flag = false
		tips = __("CHAT_TO_LONG")
	elseif self.chat_:checkIsGif(msg) then
		flag = false
		tips = __("CHAT_HAS_BLACK_WORD")
	end

	if tips ~= "" then
		xyd.alert(xyd.AlertType.TIPS, tips)
	end

	return flag
end

function ChatWindow:initConfig()
	local imgBg = self.groupConfig_:ComponentByName("imgbg", typeof(UISprite))
	local curMaxLen = 0

	for i = 1, 8 do
		local group = self.groupConfig_:NodeByName("group/group" .. i).gameObject

		group:ComponentByName("imgSelect" .. i, typeof(UISprite)):SetActive(self.chat_:getConfigByIndex(i) == 0)

		local label = group:ComponentByName("labelDesc" .. i, typeof(UILabel))
		label.text = __("CHAT_CONFIG_" .. tostring(i))

		UIEventListener.Get(group).onClick = function ()
			self:onConfigSelectTouch(i)
		end

		if curMaxLen < label.width then
			curMaxLen = label.width
		end

		local boxCollider = group:GetComponent(typeof(UnityEngine.BoxCollider))
		boxCollider.size = Vector3(label.width + 42, 28, 0)
		boxCollider.center = Vector3((label.width + 42) / 2 - 14, 0, 0)
	end

	local blackBtn = self.groupConfig_:NodeByName("blackBtn").gameObject
	blackBtn:ComponentByName("button_label", typeof(UILabel)).text = __("CHAT_CONFIG_0")

	UIEventListener.Get(blackBtn).onClick = function ()
		self:onHideConfig()
		xyd.WindowManager:get():openWindow("chat_black_list_window")
	end

	self.groupConfig_:SetActive(false)

	imgBg.width = curMaxLen + 76

	dump(imgBg.width)
	self.groupConfig_:SetLocalPosition(imgBg.width / 2 - 323, -184, 0)
	self.imgConfigMask_:SetLocalPosition(323 - imgBg.width / 2, 184, 0)
end

function ChatWindow:onHideConfig()
	self.groupConfig_:SetActive(false)
end

function ChatWindow:onShowConfig()
	self.groupConfig_:SetActive(true)
end

function ChatWindow:onConfigSelectTouch(index)
	local group = self.groupConfig_:NodeByName("group/group" .. index).gameObject
	local img = group:ComponentByName("imgSelect" .. index, typeof(UISprite))
	local isActive = not img.gameObject.activeSelf

	img:SetActive(isActive)
	self.chat_:saveConfig(index, xyd.checkCondition(isActive, 0, 1))

	if index == 5 then
		if isActive then
			self.chat_:showVip(0)
		else
			self.chat_:showVip(1)
		end
	end
end

function ChatWindow:onSDKPickImg(event)
	xyd.WindowManager.get():openWindow("upload_img_window", event.params)
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
					height = 230,
					width = 712,
					path = "Pictures/achieve_top_bg.png"
				}
			})
		else
			xyd.SdkManager.get():getImageFromAlbum()
		end
	end
end

function ChatWindow:readFileComplete(result, size)
end

function ChatWindow:onDownTouch()
	self.btnDown_:SetActive(false)
	self.chatPage_:scrollToBottom()
end

function ChatWindow:onGuildApply()
	xyd.showToast(__("GUILD_TEXT64"))
end

function ChatWindow:setSelect()
	local redMark = RedMark

	if redMark:getRedState(xyd.RedMarkType.PRIVATE_CHAT) == true then
		self.curSelect_ = xyd.MsgType.PRIVATE
	elseif redMark:getRedState(xyd.RedMarkType.GUILD_CHAT) == true and self.guildModel_.guildID > 0 or redMark:getRedState(xyd.RedMarkType.RECRUIT_CHAT) and self.guildModel_.guildID < 0 then
		self.curSelect_ = xyd.MsgType.RECRUIT
	elseif redMark:getRedState(xyd.RedMarkType.CHAT) == true then
		self.curSelect_ = xyd.MsgType.NORMAL
	elseif redMark:getRedState(xyd.RedMarkType.CROSS_CHAT) == true then
		self.curSelect_ = xyd.MsgType.CROSS_CHAT
	elseif redMark:getRedState(xyd.RedMarkType.LOCAL_CHAT) == true then
		self.curSelect_ = xyd.MsgType.LOCAL_CHAT
	else
		self.curSelect_ = self.chat_.lastSelect
	end

	if (xyd.lang == "ja_jp" or xyd.lang == "fr_fr" or xyd.lang == "ko_kr") and self.curSelect_ == xyd.MsgType.NORMAL then
		self.curSelect_ = xyd.MsgType.LOCAL_CHAT
	end

	if self.curSelect_ ~= xyd.MsgType.NORMAL then
		self.chat_:setRedMark(self:getMsgTypeBySelect(xyd.MsgType.NORMAL), false)
	end

	if self.curSelect_ == xyd.MsgType.RECRUIT then
		self:updateBottomShow(self.curSelect_)
	end

	self.chat_:setRedMark(self:getMsgTypeBySelect(self.curSelect_), false)
end

function ChatWindow:getMsgTypeBySelect(select)
	if select == xyd.MsgType.RECRUIT and self.guildModel_.guildID > 0 then
		select = xyd.MsgType.GUILD
	end

	return select
end

function ChatWindow:setWarningVisible(to_player_id)
	if self.chat_:getBlockWarning(to_player_id) then
		self.groupWarning:SetActive(false)
	else
		self.groupWarning:SetActive(true)
	end
end

function ChatWindow:updateReportItem(newReportItem, timeData)
	if self.reportItem and (not self.reportItem.reportBtn or timeData ~= self.reportItem.reportBtn.timeData_) then
		self.reportItem:removeReportBtn()

		self.reportItem = nil
	end

	if newReportItem then
		self.reportItem = newReportItem
	end
end

function ChatWindow:onReportMessage()
	if self.reportItem then
		self.reportItem:removeReportBtn()

		self.reportItem = nil
	end
end

function ChatWindow:willClose()
	for _, item in pairs(self.chatPageList_) do
		item.isDisposed_ = true

		NGUITools.Destroy(item.go_)

		item = nil
	end

	ChatWindow.super.willClose(self)
end

function ChatWindow:specialShowGuildLabFromGuildNewWar()
	self.groupTop.gameObject:SetActive(false)

	self.allBg.height = 840

	self.allBg:Y(-30)
	self.closeBtn:Y(365)
	self.labelWinTitle:Y(365)
end

return ChatWindow
