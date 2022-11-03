local BaseWindow = import(".BaseWindow")
local MailDetailWindow = class("MailDetailWindow", BaseWindow)
local MailContent = class("MailContent")
local cjson = require("cjson")

function MailDetailWindow:ctor(name, params)
	MailDetailWindow.super.ctor(self, name, params)

	self.mailData = params
	self.itemsData = params.attach

	self:trackAction(self:winName())

	self.frameItems = {}
end

function MailDetailWindow:trackAction(winName, ...)
	if self.mailData and xyd.models.mail:checkGmType(self.mailData.mail_type) then
		local event = {
			tostring(xyd.getServerTime() * 1000),
			[2.0] = "110",
			[3.0] = "1",
			[4] = winName,
			[5] = tostring(self.mailData.mail_id)
		}

		xyd.models.mail:trackAction(event)
	end
end

function MailDetailWindow:initWindow()
	MailDetailWindow.super.initWindow(self)

	self.content_ = self.window_:ComponentByName("content", typeof(UISprite))
	local contentTrans = self.content_.transform
	self.closeBtn = contentTrans:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.btnClaim_ = contentTrans:ComponentByName("btnClaim", typeof(UISprite)).gameObject
	self.btnClaimLabel_ = contentTrans:ComponentByName("btnClaim/label", typeof(UILabel))
	self.btnDelete_ = contentTrans:ComponentByName("btnDelete", typeof(UISprite)).gameObject
	self.btnWindowGo = contentTrans:NodeByName("btnWindowGo").gameObject
	self.btnDeleteLabel_ = contentTrans:ComponentByName("btnDelete/label", typeof(UILabel))
	self.btnDelete01_ = contentTrans:ComponentByName("btnDelete01", typeof(UISprite)).gameObject
	self.btnDelete01Label_ = contentTrans:ComponentByName("btnDelete01/label", typeof(UILabel))
	self.btnReplay_ = contentTrans:ComponentByName("btnReplay", typeof(UISprite)).gameObject
	self.btnReplayLabel_ = contentTrans:ComponentByName("btnReplay/label", typeof(UILabel))
	self.scrollview_ = contentTrans:ComponentByName("scrollview", typeof(UIScrollView))
	self.table_ = contentTrans:ComponentByName("scrollview/table", typeof(UITable))
	self.contentsRoot_ = contentTrans:ComponentByName("scrollview/table/contents", typeof(UIWidget)).gameObject
	self.groupLine_ = contentTrans:ComponentByName("scrollview/table/groupLine", typeof(UIWidget))
	self.labelLine_ = contentTrans:ComponentByName("scrollview/table/groupLine/lineLabel", typeof(UILabel))
	self.replyLabel_ = contentTrans:ComponentByName("scrollview/table/replyLabel", typeof(UILabel))
	self.btnWedding_ = contentTrans:NodeByName("btnWedding").gameObject
	self.btnWedding_label_ = self.btnWedding_:ComponentByName("label", typeof(UILabel))

	self:setLayout()
	self:register()

	if self.mailData.is_read == 0 then
		local data = {
			mail_ids = {}
		}

		table.insert(data.mail_ids, self.mailData.mail_id)
		xyd.models.mail:reqReadMail(data)
	end
end

function MailDetailWindow:register()
	MailDetailWindow.super.register(self)

	if #self.itemsData > 0 then
		UIEventListener.Get(self.btnClaim_).onClick = function ()
			xyd.models.mail:claimRequest(self.mailData.mail_id)
		end
	end

	UIEventListener.Get(self.btnDelete_).onClick = function ()
		local mail_ids = {}

		table.insert(mail_ids, self.mailData.mail_id)
		xyd.models.mail:requireDelete(mail_ids)
	end

	UIEventListener.Get(self.btnDelete01_).onClick = function ()
		local mail_ids = {}

		table.insert(mail_ids, self.mailData.mail_id)
		xyd.models.mail:requireDelete(mail_ids)
	end

	UIEventListener.Get(self.btnWedding_).onClick = function ()
		local show_id = xyd.split(self.mailData.content, "#&|", true)[3]
		local dates_pledge_window = xyd.WindowManager.get():openWindow("dates_pledge_window", {
			canReplayPledgeAnimation = true,
			is_date = true,
			partner_id = self.wedding_partner_id,
			show_id = show_id
		})

		if dates_pledge_window then
			dates_pledge_window:hide()
		end

		xyd.openWindow("dates_pledge_story_window", {
			isReplayStory = true,
			partner = xyd.models.slot:getPartner(self.wedding_partner_id),
			show_id = show_id
		})
		xyd.models.mail:setWeddingLocalData(self.mailData.mail_id)
		self.btnWedding_:SetActive(false)
		self.btnDelete_:SetActive(true)
		xyd.models.mail:onWeddingReview(self.mailData.mail_id)
		self.contentItems_:setWeddingReviewBack()
	end

	UIEventListener.Get(self.btnReplay_).onClick = handler(self, self.onMailReply)
	UIEventListener.Get(self.btnWindowGo).onClick = handler(self, self.onMailWindowGo)

	self.eventProxy_:addEventListener(xyd.event.GET_MAIL_GIFT, handler(self, self.onMailReward))
	self.eventProxy_:addEventListener(xyd.event.DELETE_MAIL, handler(self, self.onMailDelete))
end

function MailDetailWindow:setLayout()
	self.btnClaimLabel_.text = __("MAIL_TEXT02")
	self.btnDeleteLabel_.text = __("MAIL_TEXT03")
	self.btnDelete01Label_.text = __("MAIL_TEXT03")
	self.btnReplayLabel_.text = __("MAIL_TEXT04")
	self.labelLine_.text = __("MAIL_ORIGIN_TEXT")
	self.btnWedding_label_.text = __("MAIL_WEDDING_BTN")
	self.btnWindowGo:ComponentByName("label", typeof(UILabel)).text = __("MAIL_WINDOW_GO")

	if self.mailData.mail_type ~= xyd.MailType.FRIEND then
		if self.mailData.mail_type == xyd.MailType.WEDDING then
			local localWeddingData = self.mailData.localWeddingData

			if localWeddingData then
				self.btnWedding_:SetActive(false)
				self.btnDelete_:SetActive(true)
			else
				self.btnWedding_:SetActive(true)
				self.btnDelete_:SetActive(false)
			end

			self.btnClaim_:SetActive(false)
		else
			if #self.itemsData == 0 or self.mailData.is_gifted == 1 then
				self.btnClaim_:SetActive(false)
			else
				self.btnClaim_:SetActive(true)
				self.btnDelete_:SetActive(false)
			end

			self.btnReplay_:SetActive(false)
			self.btnDelete01_:SetActive(false)
			self.replyLabel_.gameObject:SetActive(false)
			self.groupLine_:SetActive(false)
		end
	else
		self.btnReplay_:SetActive(false)
		self.btnDelete01_:SetActive(false)
		self.btnClaim_:SetActive(false)
		self.btnDelete_:SetActive(true)
	end

	self.contentItems_ = MailContent.new(self.contentsRoot_, self)

	self.contentItems_:SetInfo(self.mailData)

	if self.mailData.old_content and #self.mailData.old_content > 0 then
		self.replyLabel_.text = self.mailData.old_content
	else
		self.replyLabel_:SetActive(false)
		self.groupLine_:SetActive(false)
	end

	if self.mailData.mail_type ~= xyd.MailType.FRIEND and (#self.itemsData == 0 or self.mailData.is_gifted == 1) and self.mailData.mail_type ~= xyd.MailType.WEDDING then
		self:updateBtnLayout()
	end
end

function MailDetailWindow:onMailReply()
	if xyd.Global.playerID == self.mailData.sender_id then
		xyd.showToast(__("MAIL_SEND_MYSELF"))

		return
	end

	xyd.WindowManager:get():openWindow("mail_send_window", {
		type = 2,
		player_id = self.mailData.sender_id,
		player_name = self.mailData.sender,
		oldContent = self.mailData.content
	})
	xyd.WindowManager:get():closeWindow(self)
end

function MailDetailWindow:onMailDelete(event)
	local data = event.data.mail_ids

	for _, id in ipairs(data) do
		if id == self.mailData.mail_id then
			self:onClickCloseButton()

			return
		end
	end
end

function MailDetailWindow:onMailReward(event)
	local data = event.data.mail_ids

	for _, id in ipairs(data) do
		if id == self.mailData.mail_id then
			self.btnClaim_:SetActive(false)
			self.btnDelete_:SetActive(true)
			self.contentItems_:setMailReward()
			self:updateBtnLayout()

			return
		end
	end
end

function MailDetailWindow:updateBtnLayout()
	self.btnClaim_:SetActive(false)

	if self:checkNeedWindowGo() then
		self.btnDelete_:SetActive(false)
		self.btnWindowGo:SetActive(true)
		self.btnDelete01_:SetActive(true)
	else
		self.btnDelete_:SetActive(true)
	end
end

function MailDetailWindow:checkNeedWindowGo()
	local mailTableId = xyd.split(self.mailData.content, "#&|", true)[1]
	local windowGoId = xyd.tables.mailTable:getWindowGo(mailTableId)

	if windowGoId and windowGoId > 0 then
		return true
	end

	if self.mailData.goto_type then
		return true
	end

	return false
end

function MailDetailWindow:getWindowGoId()
	local windowGoTable = xyd.tables.windowGoTable
	local mailTableId = xyd.split(self.mailData.content, "#&|", true)[1]
	local windowGoId = xyd.tables.mailTable:getWindowGo(mailTableId)

	if windowGoId and windowGoId > 0 then
		return windowGoId
	end

	if self.mailData.goto_type and self.mailData.goto_val then
		return self:mapWindowGoId(self.mailData.goto_type, self.mailData.goto_val)
	end
end

function MailDetailWindow:mapWindowGoId(type, value)
	local windowGoOperationMapTable = xyd.tables.windowGoOperationMapTable
	local ids = windowGoOperationMapTable:getIds()

	for i = 1, #ids do
		local id = ids[i]

		if windowGoOperationMapTable:getType(id) == tonumber(type) and windowGoOperationMapTable:getValue(id) == tonumber(value) then
			return id
		end
	end

	return -1
end

function MailDetailWindow:onMailWindowGo()
	local windowGoId = self:getWindowGoId()

	if not windowGoId or windowGoId < 0 then
		return
	end

	local windowGoTable = xyd.tables.windowGoTable
	local windowName = windowGoTable:getWindowName(windowGoId)
	local params = windowGoTable:getParams(windowGoId)
	local funcId = windowGoTable:getFunctionId(windowGoId)
	local activityId = windowGoTable:getActivityId(windowGoId)

	self:checkAndOpen(windowName, params, funcId, activityId)
end

function MailDetailWindow:checkAndOpen(winName, params, funID, activityId)
	if funID and funID > 0 and not xyd.checkFunctionOpen(funID) then
		return
	end

	if activityId and activityId > 0 then
		if not xyd.models.activity:isOpen(activityId) then
			xyd.showToast(__("ACTIVITY_OPEN_TEXT"))

			return
		end

		if activityId == xyd.ActivityID.KAKAOPAY then
			local msg = messages_pb.log_partner_data_touch_req()
			msg.touch_id = xyd.DaDian.KAKAOPAY_MAIL_JUMP

			xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
		end

		self:trackAction("ActivityWindow")
	end

	xyd.WindowManager.get():openWindow(winName, params)
	xyd.closeWindow(self.name_)
	xyd.closeWindow("mail_window")
end

function MailContent:ctor(itemRoot, parent)
	self.parent_ = parent
	self.go = itemRoot
	self.contentParams = {}
	self.contents = {}
	self.contents_url = {}

	self:initItem()
end

function MailContent:initItem()
	local itemTrans = self.go.transform
	self.titleGroup_ = itemTrans:ComponentByName("labelGroup", typeof(UIWidget))
	self.label_title = itemTrans:ComponentByName("labelGroup/label_title", typeof(UILabel))
	self.label_content = itemTrans:ComponentByName("labelGroup/label_content", typeof(UILabel))
	self.label_mail_type = itemTrans:ComponentByName("labelGroup/label_mail_type", typeof(UILabel))
	self.label_mail_name = itemTrans:ComponentByName("labelGroup/label_mail_name", typeof(UILabel))
	self.label_mail_time1 = itemTrans:ComponentByName("labelGroup/label_mail_time1", typeof(UILabel))
	self.label_mail_time2 = itemTrans:ComponentByName("labelGroup/label_mail_time2", typeof(UILabel))
	self.groupID = itemTrans:NodeByName("labelGroup/groupID").gameObject
	self.label_id = self.groupID:ComponentByName("label_id", typeof(UILabel))
	self.copyImg = self.groupID:NodeByName("copyImg").gameObject
	self.groupAwardTitle_ = itemTrans:ComponentByName("groupAwardTitle", typeof(UIWidget)).gameObject
	self.rewarded = itemTrans:NodeByName("groupAwardTitle/rewarded").gameObject
	self.altarLine_ = itemTrans:ComponentByName("groupAwardTitle/altarLine", typeof(UISprite)).gameObject
	self.labeAwardTitle_ = itemTrans:ComponentByName("groupAwardTitle/labeAwardTitle", typeof(UILabel))
	self.btnTranslate1_ = itemTrans:ComponentByName("labelGroup/translate1", typeof(UISprite)).gameObject
	self.groupItems_ = itemTrans:ComponentByName("groupItems", typeof(UIGrid))
	self.groupItemsRoot_ = self.groupItems_.gameObject
	self.groupItems0_ = itemTrans:ComponentByName("groupItems0", typeof(UIGrid))
	self.groupItems0Root_ = self.groupItems0_.gameObject
	local drag = self.label_content:AddComponent(typeof(UIDragScrollView))
	drag.scrollView = self.parent_.scrollview_
end

function MailContent:SetInfo(mailData)
	self.mailData = mailData
	self.itemsData = mailData.attach

	dump(self.mailData.content)

	if self.mailData.mail_type == xyd.MailType.SYSTEM then
		local arr = xyd.split(self.mailData.content, "#&|")
		self.mailTableID = tonumber(arr[1])
		local temp = {}

		for i = 2, #arr do
			table.insert(temp, arr[i])
		end

		self.contentParams = temp
	elseif self.mailData.mail_type == xyd.MailType.WEDDING then
		local arr = xyd.split(self.mailData.content, "#&|")
		self.mailTableID = tonumber(arr[1])
		self.contentParams = {
			arr[2]
		}
		local item = {
			item_id = arr[3]
		}
		self.itemsData = {
			item
		}
		self.parent_.wedding_partner_id = tonumber(arr[4])
	end

	self:setLayout()
end

function MailContent:setLayout()
	if not self.itemsData then
		local errorInfo = {
			error = "mail itemData is undefined",
			player_info = {
				player_id = xyd.Global.playerID
			}
		}
		local encodeInfo = cjson.encode(errorInfo)

		return
	end

	local Root = nil

	if #self.itemsData > 1 then
		Root = self.groupItemsRoot_

		self.groupItemsRoot_:SetActive(true)
		self.groupItems_:Reposition()
		self.groupItems0Root_:SetActive(false)
	else
		Root = self.groupItems0Root_

		self.groupItemsRoot_:SetActive(true)
		self.groupItems0_:Reposition()
		self.groupItems0Root_:SetActive(true)
	end

	if Root then
		self.frameItems = {}

		for _, itemInfo in ipairs(self.itemsData) do
			local params = {
				hideText = true,
				isShowSelected = false,
				uiRoot = Root,
				itemID = itemInfo.item_id,
				num = tonumber(itemInfo.item_num),
				dragScrollView = self.parent_.scrollview_
			}
			local type = xyd.tables.itemTable:getType(itemInfo.item_id)

			if self.mailData.mail_type == xyd.MailType.WEDDING and type == xyd.ItemType.SKIN then
				params.noClick = true
			end

			if self.mailData.is_gifted == 1 and type == xyd.ItemType.AVATAR_FRAME then
				params.isActiveFrameEffect = false
			end

			local icon = xyd.getItemIcon(params)

			if type == xyd.ItemType.AVATAR_FRAME then
				table.insert(self.frameItems, icon)
			end
		end
	end

	self.btnTranslate1_:SetActive(false)

	self.labeAwardTitle_.text = __("MAIL_AWAED_TEXT")
	local trsFlag = false

	if self.mailData.mail_type == xyd.MailType.SYSTEM then
		local dataIndex = xyd.tables.mailTable:getDateIndex(self.mailTableID)

		if not dataIndex then
			return
		end

		for i = 1, #dataIndex do
			if dataIndex[i] then
				local index = dataIndex[i]

				if self.contentParams[index] then
					self.contentParams[index] = xyd.getDisplayTime(self.contentParams[index], xyd.TimestampStrType.DATE)
				end
			end
		end

		local contentType = xyd.tables.mailTable:getContentType(self.mailTableID)

		for i = 1, #contentType do
			if #contentType[i] > 0 and self.contentParams[i] then
				local jsonName = contentType[i][1]
				local tableName = self.Json2Table(jsonName)

				if tableName then
					local val = tableName:getString(self.contentParams[i], contentType[i][2])
					self.contentParams[i] = val
				end
			end
		end

		self.label_title.text = xyd.tables.mailTextTable:getTitle(self.mailTableID)
		self.label_mail_type.text = xyd.tables.mailTextTable:getFrom(self.mailTableID)

		self.label_mail_name:SetActive(false)

		self.label_mail_time1.text = xyd.getDisplayTime(self.mailData.created_time, xyd.TimestampStrType.DATE)
		local content = xyd.tables.mailTextTable:getContent(self.mailTableID)
		content = content or ""
		local ordinals = {}

		for num in content:gmatch("{(%d+)}") do
			table.insert(ordinals, tonumber(num))
		end

		for _, num in ipairs(ordinals) do
			content = string.gsub(content, "{" .. num .. "}", self.contentParams[num] or "")
		end

		self:setLabelTextFlow(self.label_content, content)
		self.groupID:SetActive(false)
	elseif xyd.models.mail:checkGmType(self.mailData.mail_type) then
		if self.mailData.mail_type == xyd.MailType.GM or self.mailData.mail_type == xyd.MailType.NOH5 then
			self.label_title.text = __("MAIL_SYSTEM_TEXT")
			self.label_title.text = self.mailData.title
			self.label_mail_time1.text = xyd.getDisplayTime(self.mailData.created_time, xyd.TimestampStrType.DATE)

			print(self.mailData.content)

			local arr = xyd.split(self.mailData.content, "#&|")

			if arr[2] then
				self.label_mail_type.text = arr[1]

				self:setLabelTextFlow(self.label_content, arr[2])
			else
				self:setLabelTextFlow(self.label_content, self.mailData.content)
			end

			self.groupID:SetActive(false)
		elseif self.mailData.mail_type == xyd.MailType.WEDDING then
			self:refreshWedding()
			self.labeAwardTitle_:SetActive(false)
			self.groupItems0_:GetComponent(typeof(UIWidget)):SetTopAnchor(self.groupAwardTitle_, 0, -100)
			self.groupItems0_:GetComponent(typeof(UIWidget)):SetBottomAnchor(self.groupAwardTitle_, 0, -20)

			if self.mailData.localWeddingData then
				self:setWeddingReviewBack()
			end
		end
	else
		self.altarLine_:SetActive(false)

		self.label_title.text = xyd.models.mail:divideTitle(self.mailData.title)
		self.label_mail_name.text = self.mailData.sender
		self.label_mail_time2.text = xyd.getDisplayTime(self.mailData.created_time, xyd.TimestampStrType.DATE)

		self.label_mail_type:SetActive(false)

		self.label_title.text = __("MAIL_PLAYER_TEXT")

		self.groupID:SetActive(true)

		self.label_id.text = "(ID:" .. self.mailData.sender_id .. ")"

		UIEventListener.Get(self.copyImg).onClick = function ()
			xyd.SdkManager:get():copyToClipboard(tostring(self.mailData.sender_id))
			xyd.showToast(__("COPY_SELF_ID_SUCCESSFUL"))
		end

		UIEventListener.Get(self.label_id.gameObject).onClick = function ()
			xyd.SdkManager:get():copyToClipboard(tostring(self.mailData.sender_id))
			xyd.showToast(__("COPY_SELF_ID_SUCCESSFUL"))
		end

		trsFlag = true

		self.btnTranslate1_:SetActive(true)

		UIEventListener.Get(self.btnTranslate1_).onClick = function ()
			self:onTranslate()
		end

		self.label_content.text = self.mailData.content
	end

	local notShow = #self.itemsData <= 0

	self.groupAwardTitle_:SetActive(not notShow)

	if self.mailData.is_gifted == 1 then
		self.rewarded:SetActive(true)
	else
		self.rewarded:SetActive(false)
	end

	if self.mailData.is_gifted == 1 then
		self:setMailReward()
	end

	self.parent_.scrollview_:ResetPosition()
end

function MailContent:setMailReward()
	self.isShowRewardMark = false

	local function setChildrenColorGrey(go)
		for i = 1, go.transform.childCount do
			local child = go.transform:GetChild(i - 1).gameObject
			local widget = child:GetComponent(typeof(UIWidget))

			if widget then
				widget.color = Color.New2(255)
			end

			local label = child:GetComponent(typeof(UILabel))

			if label then
				widget.color = Color.New2(4294967295.0)
			end

			if child.transform.childCount > 0 then
				self.isShowRewardMark = true

				setChildrenColorGrey(child)
			end
		end

		for i in pairs(self.frameItems) do
			self.frameItems[i]:setGreyFarme(true)
		end
	end

	setChildrenColorGrey(self.groupItemsRoot_)
	setChildrenColorGrey(self.groupItems0Root_)

	if self.isShowRewardMark then
		self.rewarded:SetActive(true)
	end
end

function MailContent:setWeddingReviewBack()
	xyd.applyChildrenGrey(self.groupItemsRoot_)
	xyd.applyChildrenGrey(self.groupItems0Root_)
end

function MailContent.Json2Table(jsonName)
	local table = nil
	local switch = {
		item = function ()
			table = xyd.tables.itemTextTable
		end,
		giftbag = function ()
			table = xyd.tables.giftBagTextTable
		end,
		partner_text = function ()
			table = xyd.tables.partnerTextTable
		end,
		item_text = function ()
			table = xyd.tables.itemTextTable
		end,
		activity_text = function ()
			table = xyd.tables.activityTextTable
		end,
		group_text = function ()
			table = xyd.tables.groupTextTable
		end,
		activity_old_building_area_text = function ()
			table = xyd.tables.activityOldBuildingAreaTextTable
		end,
		activity_old_building_lou_text = function ()
		end,
		time_cloister_text = function ()
			table = xyd.tables.timeCloisterTextTable
		end,
		time_cloister_battle_rank = function ()
			table = xyd.tables.timeCloisterBattleRankTable
		end,
		arena_all_server_rank_text = function ()
			table = xyd.tables.arenaAllServerRankText
		end,
		arena_all_server_award = function ()
			table = xyd.tables.arenaAllServerAwardTable
		end,
		shrine_hurdle_route_text = function ()
			table = xyd.tables.shrineHurdleRouteTextTable
		end,
		activity_dragonboat2022_text = function ()
			table = xyd.tables.activityDragonboat2022TextTable
		end,
		activity_repair_console_mission_text = function ()
			table = xyd.tables.activityRepairConsoleMissionTextTable
		end,
		activity_blind_box_mission = function ()
			table = xyd.tables.activityBlindBoxMissionTable
		end
	}

	if switch[jsonName] then
		switch[jsonName]()
	end

	return table
end

function MailContent:setLabelTextFlow(label, val)
	local href = string.find(val, "<a href") or -1

	print("href", href)

	if href > -1 or (string.find(val, "<font") or -1) > -1 then
		local content2 = string.gsub(val, "<font color=0x(%w+)>", "[c][%1]")
		local content3 = string.gsub(content2, "</font>", "[-][/c]")
		local content4 = string.gsub(content3, "<font size=\"(%d+)\">", "[size=%1]")
		local content = string.gsub(content4, "<a href=\"([^>]+)\">", "[url=%1]")
		local content1 = string.gsub(content, "</a>", "[/u]")
		local content6 = string.gsub(content1, "<big>", "")
		local content7 = string.gsub(content6, "</big>", "")
		label.text = content7
	else
		label.text = val
	end

	if not self.boxClider_ then
		self.boxClider_ = label:GetComponent(typeof(UnityEngine.BoxCollider))
	end

	if self.boxClider_ then
		self.boxClider_.size = Vector3(label.width, label.height, 0)
	end

	UIEventListener.Get(label.gameObject).onClick = function ()
		if not self.uiCamera_ then
			self.uiCamera_ = xyd.WindowManager.get():getNgui():ComponentByName("UICamera", typeof(UICamera))
		end

		local posTable = self.uiCamera_.lastHit.point
		local url = label:GetUrlAtPosition(posTable)

		print("url       ", url)

		if url then
			local trueUrl = string.sub(url, 2, -2)

			if string.find(trueUrl, "https") then
				print("trueUrl         ", trueUrl)
				UnityEngine.Application.OpenURL(trueUrl)
			else
				UnityEngine.Application.OpenURL(url)
			end
		end
	end
end

function MailContent:onTranslate()
	if self.isTransl then
		xyd.alertTips(__("CHAT_TRANSLATEING"))

		return
	end

	if not self.showTransl then
		self.isTransl = true
		self.originalContent = self.mailData.content

		xyd.models.chat:translateFrontend(self.mailData, function (msg, type)
			if type == xyd.TranslateType.DOING then
				xyd.alertTips(__("CHAT_TRANSLATEING"))
			else
				self.isTransl = false
				self.label_content.text = msg.translate
				self.mailData.content = self.originalContent
				self.showTransl = true
			end
		end)
	else
		self.label_content.text = self.mailData.content
		self.showTransl = false
	end
end

function MailContent:refreshWedding()
	local partnerName = xyd.tables.partnerTextTable:getName(tonumber(self.contentParams[1]))
	local contentType = xyd.tables.mailTable:getContentType(self.mailTableID)

	for i = 1, #contentType do
		if #contentType[i] > 0 and self.contentParams[i] then
			local jsonName = contentType[i][1]
			local tableName = self.Json2Table(jsonName)

			if tableName then
				local val = tableName:getString(self.contentParams[i], contentType[i][2])
				self.contentParams[i] = val
			end
		end
	end

	local content = xyd.tables.mailTextTable:getContent(self.mailTableID)
	content = content or ""
	local ordinals = {}

	for num in content:gmatch("{(%d+)}") do
		table.insert(ordinals, tonumber(num))
	end

	for _, num in ipairs(ordinals) do
		content = string.gsub(content, "{" .. num .. "}", self.contentParams[num])
	end

	self:setLabelTextFlow(self.label_content, content)
	self.groupID:SetActive(false)

	self.label_mail_time1.text = xyd.getDisplayTime(self.mailData.created_time, xyd.TimestampStrType.DATE)
	self.label_title.text = xyd.tables.mailTextTable:getTitle(self.mailTableID)
	self.label_mail_type.text = xyd.tables.mailTextTable:getFrom(self.mailTableID)
end

function MailDetailWindow:iosTestChangeUI()
	xyd.setUISprite(self.btnClaim_:GetComponent(typeof(UISprite)), nil, "blue_btn_65_65_ios_test")
	xyd.setUISprite(self.btnDelete_:GetComponent(typeof(UISprite)), nil, "blue_btn_65_65_ios_test")
end

return MailDetailWindow
