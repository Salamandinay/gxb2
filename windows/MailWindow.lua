local MailWindow = class("MailWindow", import(".BaseWindow"))
local MailItemClass = class("MailItem")
local MailItem = class("MailItem", import("app.components.BaseComponent"))
local mailModel = xyd.models.mail

function MailWindow:ctor(name, params)
	MailWindow.super.ctor(self, name, params)

	self.mails_ = {}
	self.btnType_ = 0
	self.needTips_ = false
	self.index_ = 0

	self:trackAction()
end

function MailWindow:trackAction()
	local event = {
		tostring(xyd.getServerTime() * 1000),
		[2.0] = "110",
		[3.0] = "1",
		[4] = self:winName()
	}

	xyd.models.mail:trackAction(event)
end

function MailWindow:initWindow()
	MailWindow.super.initWindow(self)

	self.content_ = self.window_:ComponentByName("groupAction", typeof(UISprite))
	local contentTrans = self.content_.transform
	self.btnMask = contentTrans:NodeByName("btnMask").gameObject
	self.closeBtn = contentTrans:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.btnSystem_ = contentTrans:ComponentByName("btnSystem", typeof(UISprite))
	self.btnSystemImg_ = contentTrans:ComponentByName("btnSystem/imgMail", typeof(UISprite))
	self.btnSystemRed_ = contentTrans:ComponentByName("btnSystem/redPoint", typeof(UISprite)).gameObject
	self.btnFriend_ = contentTrans:ComponentByName("btnFriend", typeof(UISprite))
	self.btnFriendImg_ = contentTrans:ComponentByName("btnFriend/imgMail", typeof(UISprite))
	self.btnFriendRed_ = contentTrans:ComponentByName("btnFriend/redPoint", typeof(UISprite)).gameObject
	self.btnGM_ = contentTrans:ComponentByName("btnGM", typeof(UISprite))
	self.btnGMImg_ = contentTrans:ComponentByName("btnGM/imgMail", typeof(UISprite))
	self.btnGMRed_ = contentTrans:ComponentByName("btnGM/redPoint", typeof(UISprite)).gameObject
	self.btnCliamAll_ = contentTrans:ComponentByName("btnCliamAll", typeof(UISprite)).gameObject
	self.labelCliamAll_ = contentTrans:ComponentByName("btnCliamAll/label", typeof(UILabel))
	self.btnDeleteAll_ = contentTrans:ComponentByName("btnDeleteAll", typeof(UISprite)).gameObject
	self.groupNone_ = contentTrans:NodeByName("groupNone").gameObject
	self.labelNoneTips_ = contentTrans:ComponentByName("groupNone/labelNoneTips", typeof(UILabel))
	self.scrollView_ = contentTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.content_ = contentTrans:ComponentByName("scrollView/grid", typeof(MultiRowWrapContent))
	local MailItemRoot = contentTrans:NodeByName("scrollView/itemRoot").gameObject
	self.itemFloatRoot_ = contentTrans:NodeByName("itemFloatRoot").gameObject
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.content_, MailItemRoot, MailItemClass, self)
	self.numGroup = contentTrans:NodeByName("numGroup").gameObject
	self.numLabel = self.numGroup:ComponentByName("label", typeof(UILabel))
end

function MailWindow:updateBtnState()
	if mailModel:getlastPush() == "System" then
		self.btnCliamAll_:SetActive(true)
	else
		self.btnCliamAll_:SetActive(false)
	end
end

function MailWindow:playOpenAnimation(callback)
	local function afterAction()
		self:layout()
		callback()
	end

	MailWindow.super.playOpenAnimation(self, afterAction)
end

function MailWindow:onNewMail(event)
	local funID = event.data.function_id

	if funID == xyd.FunctionID.MAIL then
		xyd.models.mail:requireMailList()
	end
end

function MailWindow:onMailListData()
	self:setMailList()
	self:setMailBtn()
	self.btnMask:SetActive(false)
end

function MailWindow:layout()
	self:setLayout()
	self:registerEvent()

	if not mailModel:preRequireMailList() then
		self.btnMask:SetActive(true)
		self:setMailList()
		self:setMailBtn()
	end

	self.btnMask:SetActive(false)
	self:updateBtnState()
end

function MailWindow:registerEvent()
	if self.closeBtn then
		UIEventListener.Get(self.closeBtn).onClick = function ()
			self:onClickCloseButton()
		end
	end

	UIEventListener.Get(self.btnCliamAll_).onClick = handler(self, self.claimAllRequest)
	UIEventListener.Get(self.btnFriend_.gameObject).onClick = handler(self, self.onFriendMail)
	UIEventListener.Get(self.btnSystem_.gameObject).onClick = handler(self, self.onSystemMail)
	UIEventListener.Get(self.btnGM_.gameObject).onClick = handler(self, self.onGMMail)
	UIEventListener.Get(self.btnDeleteAll_.gameObject).onClick = handler(self, self.deleteAllUselessMail)
	UIEventListener.Get(self.numGroup).onClick = handler(self, function ()
		xyd.showToast(__("MAIL_NUM_DES"))
	end)

	if self.eventProxy_ then
		self.eventProxy_:addEventListener(xyd.event.GET_MAIL_GIFT, handler(self, self.onMailReward))
		self.eventProxy_:addEventListener(xyd.event.DELETE_MAIL, handler(self, self.onMailDelete))
		self.eventProxy_:addEventListener(xyd.event.READ_MAIL, handler(self, self.onMailRead))
		self.eventProxy_:addEventListener(xyd.event.MAIL_LIST, handler(self, self.onMailListData))
		self.eventProxy_:addEventListener(xyd.event.RED_POINT, handler(self, self.onNewMail))
	end
end

function MailWindow:onFriendMail()
	mailModel:setlastPush("Friend")
	self:setMailBtn()
	self:setMailList()
	self.btnCliamAll_:SetActive(false)
end

function MailWindow:onSystemMail()
	mailModel:setlastPush("System")
	self:setMailBtn()
	self:setMailList()
	self.btnCliamAll_:SetActive(true)
end

function MailWindow:onGMMail()
	mailModel:setlastPush("GM")
	self:setMailBtn()
	self:setMailList()
	self.btnCliamAll_:SetActive(false)
end

function MailWindow:setLayout()
	self.labelNoneTips_.text = __("NO_EMAIL")
	self.labelCliamAll_.text = __("MAIL_TEXT01")
end

function MailWindow:setMailBtn()
	local str = mailModel:getlastPush()

	if str == "System" then
		self.btnSystemRed_:SetActive(false)
		xyd.setUISpriteAsync(self.btnSystem_, nil, "mail_label02", nil, )
		xyd.setUISpriteAsync(self.btnSystemImg_, nil, "mail_sys01", nil, )
		xyd.setUISpriteAsync(self.btnFriend_, nil, "mail_label01", nil, )
		xyd.setUISpriteAsync(self.btnFriendImg_, nil, "mail_friend02", nil, )
		xyd.setUISpriteAsync(self.btnGM_, nil, "mail_label01", nil, )
		xyd.setUISpriteAsync(self.btnGMImg_, nil, "mail_gm02", nil, )
		self:updateClaimBtn()
	elseif str == "Friend" then
		xyd.setUISpriteAsync(self.btnSystem_, nil, "mail_label01", nil, )
		xyd.setUISpriteAsync(self.btnSystemImg_, nil, "mail_sys02", nil, )
		xyd.setUISpriteAsync(self.btnFriend_, nil, "mail_label02", nil, )
		xyd.setUISpriteAsync(self.btnFriendImg_, nil, "mail_friend01", nil, )
		xyd.setUISpriteAsync(self.btnGM_, nil, "mail_label01", nil, )
		xyd.setUISpriteAsync(self.btnGMImg_, nil, "mail_gm02", nil, )
	else
		xyd.setUISpriteAsync(self.btnSystem_, nil, "mail_label01", nil, )
		xyd.setUISpriteAsync(self.btnSystemImg_, nil, "mail_sys02", nil, )
		xyd.setUISpriteAsync(self.btnFriend_, nil, "mail_label01", nil, )
		xyd.setUISpriteAsync(self.btnFriendImg_, nil, "mail_friend02", nil, )
		xyd.setUISpriteAsync(self.btnGM_, nil, "mail_label02", nil, )
		xyd.setUISpriteAsync(self.btnGMImg_, nil, "mail_gm01", nil, )
	end
end

function MailWindow:setRedMark()
	local redStateF = xyd.models.redMark:getRedState(xyd.RedMarkType.MAIL_FRIEND)
	local redStateS = xyd.models.redMark:getRedState(xyd.RedMarkType.MAIL_SYSTEM)
	local redStateG = xyd.models.redMark:getRedState(xyd.RedMarkType.MAIL_GM)

	self.btnFriendRed_:SetActive(redStateF)
	self.btnSystemRed_:SetActive(redStateS)
	self.btnGMRed_:SetActive(redStateG)

	local str = mailModel:getlastPush()

	if str == "System" then
		self.btnSystemRed_:SetActive(false)
	elseif str == "Friend" then
		self.btnFriendRed_:SetActive(false)
	else
		self.btnGMRed_:SetActive(false)
	end
end

function MailWindow:setMailList(keepPosition)
	local list = nil
	local str = mailModel:getlastPush()

	if str == "System" then
		list = mailModel:getmailSystem()

		self:updateClaimBtn()
	elseif str == "Friend" then
		list = mailModel:getMailFriend()
	else
		list = mailModel:getmailGM()
	end

	self:setRedMark()
	self:setDataGroup(list, keepPosition)
	self.groupNone_:SetActive(#list == 0)

	local numTotal = #mailModel:getmailSystem() + #mailModel:getMailFriend() + #mailModel:getmailGM()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.YEARS_SUMMARY)

	if activityData and activityData:isOpen() then
		numTotal = numTotal - 1
	end

	self.numLabel.text = numTotal .. "/" .. xyd.tables.miscTable:getVal("mail_limit")
end

function MailWindow:setDataGroup(list, keepPosition)
	self.multiWrap_:setInfos(list, {
		keepPosition = keepPosition
	})
end

function MailWindow:updateClaimBtn()
	local unread = 0
	local unclimed = 0

	for _, mailId in ipairs(mailModel:getmailSystem()) do
		local mail = mailModel:getMails()[mailId]

		if mail.attach and #mail.attach > 0 and mail.is_gifted == 0 then
			unclimed = unclimed + 1
		elseif mail.is_read == 0 then
			unread = unread + 1
		end
	end

	if unclimed > 0 then
		self.btnType_ = 0
	elseif unread > 0 then
		self.btnType_ = 1
	end

	self:setClaimBtn()
end

function MailWindow:setClaimBtn()
	if self.btnType_ == 0 then
		self.labelCliamAll_.text = __("MAIL_TEXT01")
	elseif self.btnType_ == 1 then
		self.labelCliamAll_.text = __("MAIL_TEXT05")
	end
end

function MailWindow:claimAllRequest()
	if mailModel:getlastPush() == "System" then
		if self.btnType_ == 0 then
			if not mailModel:requireRewards("sys") then
				xyd.showToast(__("MAIL_TIPS"))
			end
		elseif self.btnType_ == 1 then
			if not mailModel:requireRead("sys") then
				xyd.showToast(__("MAIL_TIPS01"))
			end

			self.needTips = true
		end
	end
end

function MailWindow:deleteAllUselessMail()
	local mailsToDelete = self:getMailsToDelete()

	if #mailsToDelete == 0 then
		xyd.showToast(__("NO_USELESS_MAIL"))

		return
	end

	xyd.WindowManager:get():openWindow("alert_window", {
		alertType = xyd.AlertType.YES_NO,
		message = __("USELESS_MAIL_ALL_DELETE_TEXT"),
		callback = function (flag)
			if not flag then
				return
			end

			mailModel:requireDelete(mailsToDelete)
		end
	})
end

function MailWindow:getMailsToDelete()
	local mails = nil

	if mailModel:getlastPush() == "System" then
		mails = mailModel:getmailSystem()
	elseif mailModel:getlastPush() == "GM" then
		mails = mailModel:getmailGM()
	else
		mails = mailModel:getMailFriend()
	end

	local toDelete = {}

	for _, id in ipairs(mails) do
		local mail = mailModel:getMails()[id]

		if mail.is_gifted == 1 or (not mail.attach or #mail.attach == 0) and mail.is_read == 1 and mail.mail_id ~= 99999 then
			table.insert(toDelete, id)
		end
	end

	return toDelete
end

function MailWindow:onMailRead()
	if not self.window_ then
		return
	end

	if self.needTips then
		self.needTips = false

		xyd.showToast(__("MAIL_TEXT06"))
	end

	self:setMailList(true)
end

function MailWindow:onMailReward(event)
	local datas = event.data.mail_ids
	local items = {}
	local skin_ids = {}

	for _, id in ipairs(datas) do
		local mail = mailModel:getMails()[id]

		if mail and mail.attach and #mail.attach > 0 then
			for _, item in ipairs(mail.attach) do
				local itemInfo = {
					hideText = true,
					item_id = item.item_id,
					item_num = item.item_num
				}

				if xyd.tables.itemTable:getType(item.item_id) == xyd.ItemType.SKIN then
					table.insert(skin_ids, item.item_id)
				end

				table.insert(items, itemInfo)
			end
		end
	end

	if #skin_ids > 0 then
		xyd.onGetNewPartnersOrSkins({
			destory_res = false,
			skins = skin_ids,
			callback = function ()
				xyd.alertItems(items)
			end
		})
	else
		xyd.alertItems(items)
	end

	self:setMailList(true)
end

function MailWindow:onMailDelete()
	self:setMailList(true)
end

function MailWindow:willClose()
	MailWindow.super.willClose(self)

	if self.eventProxy_ then
		self.eventProxy_:removeAllEventListeners()
	end
end

function MailWindow:setGroupNone(statue)
	self.groupNone_:SetActive(statue)
end

function MailWindow:iosTestChangeUI()
	xyd.setUISprite(self.btnCliamAll_:GetComponent(typeof(UISprite)), nil, "blue_btn_65_65_ios_test")
end

function MailItemClass:ctor(go, parent)
	self.uiRoot_ = go
	self.parent_ = parent
	self.MailItem_ = MailItem.new(self.uiRoot_, self.parent_)
end

function MailItemClass:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)
	self.MailItem_:setInfo(info, self.parent_)
end

function MailItemClass:getGameObject()
	return self.uiRoot_
end

function MailItem:ctor(parentGo, parent)
	self.parent_ = parent

	MailItem.super.ctor(self, parentGo)
end

function MailItem:initUI()
	MailItem.super.initUI(self)

	local itemTrans = self.go.transform
	self.dragBg_ = itemTrans:GetComponent(typeof(UIDragScrollView))
	self.bg_select_mail = itemTrans:ComponentByName("groupBg/bg_select_mail", typeof(UISprite))
	self.bg_gray_mail = itemTrans:ComponentByName("groupBg/bg_gray_mail", typeof(UISprite))
	self.bg_new_mail = itemTrans:ComponentByName("groupBg/bg_new_mail", typeof(UISprite))
	self.groupGift = itemTrans:NodeByName("groupGift").gameObject
	self.mail_icon = itemTrans:ComponentByName("groupGift/mail_icon", typeof(UISprite))
	self.mail_icon_gift = itemTrans:ComponentByName("groupGift/mail_icon_gift", typeof(UISprite))
	self.label_title = itemTrans:ComponentByName("label_title", typeof(UILabel))
	self.label_name = itemTrans:ComponentByName("label_name", typeof(UILabel))
	self.label_data = itemTrans:ComponentByName("label_data", typeof(UILabel))
	self.imgLine = itemTrans:ComponentByName("imgLine", typeof(UISprite))
	self.dragBg_.scrollView = self.parent_.scrollView_
end

function MailItem.getPrefabPath()
	return "Prefabs/Components/mail_item"
end

function MailItem:setInfo(info)
	self.info_ = info
	self.mail_ = mailModel:getMails()[self.info_]

	if not self.state_ or self.state_ ~= (#self.mail_.attach == 0) then
		self.state_ = #self.mail_.attach == 0

		self.mail_icon.gameObject:SetActive(self.state_)
		self.mail_icon_gift.gameObject:SetActive(not self.state_)
	end

	if self.mail_.created_time then
		self:setMailTime()
	end

	if self.mail_.mail_id ~= 99999 then
		xyd.setUISpriteAsync(self.bg_select_mail, nil, "mail_text01_" .. xyd.Global.lang, nil, , true)
		xyd.setUISpriteAsync(self.bg_gray_mail, nil, "mail_text02_" .. xyd.Global.lang, nil, , true)
		xyd.setUISpriteAsync(self.bg_new_mail, nil, "mail_icon05", nil, , true)
		xyd.setUISpriteAsync(self.go.transform:ComponentByName("groupGift/mailGiftBg", typeof(UISprite)), nil, "mail_gift_bg")
		xyd.setUISpriteAsync(self.mail_gift_bg, nil, "mail_icon01")
		self.groupGift.gameObject:SetActive(true)
		self.imgLine.gameObject:SetActive(true)
	else
		xyd.setUISpriteAsync(self.bg_gray_mail, nil, "activity_year_summary_mail_bg2_" .. xyd.Global.lang, nil, , true)
		xyd.setUISpriteAsync(self.bg_new_mail, nil, "activity_year_summary_mail_bg", nil, , true)
		self.groupGift.gameObject:SetActive(false)
		self.imgLine.gameObject:SetActive(false)
	end

	if self.mail_.mail_type == xyd.MailType.SYSTEM and self.mail_.mail_id == 99999 then
		self.mailTableID = 189

		self.label_name:SetActive(false)

		self.label_title.text = __("ANNUAL3_REVIEW_MAIL_TITLE")

		self.label_title.transform:Y(28)
	elseif self.mail_.mail_type == xyd.MailType.SYSTEM then
		self.mailTableID = xyd.split(self.mail_.content, "#&|")[1]
		self.label_title.text = xyd.tables.mailTextTable:getTitle(self.mailTableID)

		self.label_name:SetActive(false)
	elseif self.mail_.mail_type == xyd.MailType.FRIEND then
		self.label_title.text = __("MAIL_SENDER")

		self.label_name:SetActive(true)

		self.label_name.text = self.mail_.sender
	else
		self.label_title.text = self.mail_.title

		self.label_name:SetActive(false)

		if self.mail_.mail_type == xyd.MailType.WEDDING then
			local mailId = xyd.split(self.mail_.content, "#&|")[1]
			self.label_title.text = xyd.tables.mailTextTable:getTitle(mailId)
		end
	end

	UIEventListener.Get(self.go).onClick = function ()
		if self.mail_.mail_id == 99999 then
			xyd.WindowManager:get():openWindow("activity_year_summary_window")
			xyd.db.misc:setValue({
				value = 1,
				key = "years_summary_mail_read"
			})
			xyd.models.mail:onMailRead({
				data = {
					mail_ids = {
						99999
					}
				}
			})

			local win = xyd.WindowManager.get():getWindow("mail_window")

			if win then
				win:setMailList(true)
			end
		else
			xyd.WindowManager:get():openWindow("mail_detail_window", self.mail_)
		end
	end

	self:setState()
end

function MailItem:setMailTime()
	if self.mail_.mail_type == xyd.MailType.FRIEND then
		self.label_data.text = xyd.getDisplayTime(self.mail_.created_time, xyd.TimestampStrType.DATE)
	else
		local lastTime = xyd.tables.miscTable:getVal("mail_last_time")
		local duration = self.mail_.created_time + lastTime - xyd.getServerTime()

		if duration < 0 then
			duration = 0
		end

		if duration <= 7 * xyd.DAY and self.mail_.mail_type == xyd.MailType.SYSTEM then
			self.label_data.text = __("MAIL_TIME_LIMIT", xyd.getRoughDisplayTime(duration))
		else
			self.label_data.text = xyd.getDisplayTime(self.mail_.created_time, xyd.TimestampStrType.DATE)
		end
	end
end

function MailItem:setState()
	if self.mail_.mail_id ~= 99999 then
		if tonumber(self.mailTableID) == xyd.MailContent.IMPORTANT then
			xyd.setUISpriteAsync(self.bg_new_mail, nil, "important_mail_icon_4")
		else
			xyd.setUISpriteAsync(self.bg_new_mail, nil, "mail_icon05")
		end
	end

	if self.mail_.mail_type == xyd.MailType.WEDDING then
		self:setWeddingState()
	else
		self:setCommonState()
	end

	if not self.currentState or self.currentState ~= self.stateBefore then
		self.stateBefore = self.currentState

		self.bg_select_mail.gameObject:SetActive(self.currentState == "select_mail")
		self.bg_gray_mail.gameObject:SetActive(self.currentState == "gray_mail")
		self.bg_new_mail:SetActive(self.currentState == "new_email")
	end
end

function MailItem:setCommonState()
	if self.mail_.is_read == 0 then
		self.currentState = "new_email"

		xyd.applyOrigin(self.mail_icon_gift)
		xyd.applyOrigin(self.mail_icon)
		xyd.setUISpriteAsync(self.mail_icon, nil, "mail_icon08")
		xyd.setUISpriteAsync(self.mail_icon_gift, nil, "mail_icon01")
		xyd.setUISpriteAsync(self.imgLine, nil, "mail_divide_line")

		self.label_title.color = Color.New2(1432789759)
		self.label_title.effectColor = Color.New2(4294967295.0)
		self.label_name.color = Color.New2(1432789759)
		self.label_name.effectColor = Color.New2(4294967295.0)

		if tonumber(self.mailTableID) == xyd.MailContent.IMPORTANT then
			xyd.setUISpriteAsync(self.mail_icon, nil, "important_mail_icon_1")
		end
	elseif self.mail_.is_gifted == 0 and #self.mail_.attach > 0 then
		self.currentState = "select_mail"

		xyd.applyOrigin(self.mail_icon_gift)
		xyd.applyOrigin(self.mail_icon)
		xyd.setUISpriteAsync(self.mail_icon, nil, "mail_icon08")
		xyd.setUISpriteAsync(self.mail_icon_gift, nil, "mail_icon01")
		xyd.setUISpriteAsync(self.imgLine, nil, "mail_divide_line")

		self.label_title.color = Color.New2(1432789759)
		self.label_title.effectColor = Color.New2(4294967295.0)
		self.label_name.color = Color.New2(1432789759)
		self.label_name.effectColor = Color.New2(4294967295.0)
	elseif self.mail_.mail_id == 99999 and self.mail_.is_read == 1 then
		self.currentState = "gray_mail"
		self.label_title.color = Color.New2(1819045119)
		self.label_title.effectColor = Color.New2(3991793151.0)
		self.label_name.color = Color.New2(1819045119)
		self.label_name.effectColor = Color.New2(3991793151.0)

		xyd.setUISpriteAsync(self.imgLine, nil, "mail_line_grey")
		xyd.setUISpriteAsync(self.mail_icon, nil, "mail_icon09")
	else
		self.currentState = "gray_mail"
		self.label_title.color = Color.New2(1819045119)
		self.label_title.effectColor = Color.New2(3991793151.0)
		self.label_name.color = Color.New2(1819045119)
		self.label_name.effectColor = Color.New2(3991793151.0)

		xyd.setUISpriteAsync(self.imgLine, nil, "mail_line_grey")

		if self.mail_.is_read == 1 and #self.mail_.attach == 0 then
			xyd.applyGrey(self.mail_icon)
			xyd.setUISpriteAsync(self.mail_icon, nil, "mail_icon09")

			if tonumber(self.mailTableID) == xyd.MailContent.IMPORTANT then
				xyd.setUISpriteAsync(self.mail_icon, nil, "important_mail_icon_2")
			end
		end

		if self.mail_.is_gifted == 1 and #self.mail_.attach > 0 then
			xyd.applyGrey(self.mail_icon_gift)
			xyd.setUISpriteAsync(self.mail_icon_gift, nil, "mail_icon02")
		else
			xyd.applyOrigin(self.mail_icon_gift)
			xyd.setUISpriteAsync(self.mail_icon_gift, nil, "mail_icon01")
		end
	end
end

function MailItem:setWeddingState()
	if self.mail_.is_read == 0 then
		self.currentState = "new_email"

		xyd.applyOrigin(self.mail_icon_gift)
		xyd.applyOrigin(self.mail_icon)
		xyd.setUISpriteAsync(self.mail_icon, nil, "mail_icon10")
		xyd.setUISpriteAsync(self.mail_icon_gift, nil, "mail_icon01")
		xyd.setUISpriteAsync(self.imgLine, nil, "mail_divide_line")

		self.label_title.color = Color.New2(1432789759)
		self.label_title.effectColor = Color.New2(4294967295.0)
		self.label_name.color = Color.New2(1432789759)
		self.label_name.effectColor = Color.New2(4294967295.0)
	elseif not xyd.db.misc:getValue("mail_wedding_" .. self.mail_.mail_id) then
		self.currentState = "select_mail"

		xyd.applyOrigin(self.mail_icon_gift)
		xyd.applyOrigin(self.mail_icon)
		xyd.setUISpriteAsync(self.mail_icon, nil, "mail_icon11")
		xyd.setUISpriteAsync(self.mail_icon_gift, nil, "mail_icon01")
		xyd.setUISpriteAsync(self.imgLine, nil, "mail_divide_line")

		self.label_title.color = Color.New2(1432789759)
		self.label_title.effectColor = Color.New2(4294967295.0)
		self.label_name.color = Color.New2(1432789759)
		self.label_name.effectColor = Color.New2(4294967295.0)
	else
		self.currentState = "gray_mail"
		self.label_title.color = Color.New2(1819045119)
		self.label_title.effectColor = Color.New2(3991793151.0)
		self.label_name.color = Color.New2(1819045119)
		self.label_name.effectColor = Color.New2(3991793151.0)

		xyd.setUISpriteAsync(self.mail_icon, nil, "mail_icon12")
		xyd.setUISpriteAsync(self.imgLine, nil, "mail_line_grey")
	end
end

return MailWindow
