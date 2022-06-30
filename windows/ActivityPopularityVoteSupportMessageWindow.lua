local BaseWindow = import(".BaseWindow")
local ActivityPopularityVoteSupportMessageWindow = class("ActivityPopularityVoteSupportMessageWindow", BaseWindow)
local MessageItem = class("MessageItem", import("app.common.ui.FlexibleWrapContentItem"))
local Partner = import("app.models.Partner")
local PartnerCard = import("app.components.PartnerCard")
local ReportBtn = import("app.components.ReportBtn")
local LuaFlexibleWrapContent = import("app.common.ui.FlexibleWrapContent")
local cjson = require("cjson")

function ActivityPopularityVoteSupportMessageWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.params = params
	self.partnerTableID = params.tableID
	self.curPeriod = params.curPeriod
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_POPULARITY_VOTE)
	self.currentSkin = 1
end

function ActivityPopularityVoteSupportMessageWindow:initWindow()
	self:getUIComponent()
	ActivityPopularityVoteSupportMessageWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityPopularityVoteSupportMessageWindow:getUIComponent()
	self.go = self.window_.transform
	self.groupTopModel = self.go:ComponentByName("groupTopModel", typeof(UITexture))
	self.titleTexture = self.go:ComponentByName("titleTexture", typeof(UITexture))
	self.groupMain = self.go:NodeByName("groupMain").gameObject
	self.groupBottom = self.groupMain:NodeByName("groupBottom").gameObject
	self.imgBottom1 = self.groupBottom:ComponentByName("imgBottom1", typeof(UITexture))
	self.imgBottom2 = self.groupBottom:ComponentByName("imgBottom2", typeof(UISprite))
	self.closeBtn = self.groupMain:NodeByName("closeBtn").gameObject
	self.bg1 = self.groupMain:ComponentByName("bg1", typeof(UITexture))
	self.bg2 = self.groupMain:ComponentByName("bg2", typeof(UISprite))
	self.likeGroup = self.groupMain:NodeByName("likeGroup").gameObject
	self.likeIcon = self.likeGroup:ComponentByName("likeIcon", typeof(UISprite))
	self.likeLabel = self.likeGroup:ComponentByName("likeLabel", typeof(UILabel))
	self.likeNum = self.likeGroup:ComponentByName("likeNum", typeof(UILabel))
	self.titleGroup = self.groupMain:NodeByName("titleGroup").gameObject
	self.imgTitle = self.titleGroup:ComponentByName("imgTitle", typeof(UISprite))
	self.labelTitle = self.titleGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.groupMessage = self.groupMain:NodeByName("groupMessage").gameObject
	self.image2_1 = self.groupMessage:ComponentByName("image2_1", typeof(UISprite))
	self.mainContent = self.groupMessage:NodeByName("mainContent").gameObject
	self.scroller = self.mainContent:NodeByName("scroller").gameObject
	self.scrollView = self.mainContent:ComponentByName("scroller", typeof(UIScrollView))
	self.container = self.scroller:NodeByName("container").gameObject
	self.drag = self.mainContent:NodeByName("drag").gameObject
	self.item = self.mainContent:NodeByName("item").gameObject
	self.image2_2 = self.groupMessage:ComponentByName("image2_2", typeof(UISprite))
	self.labelMessageTitle = self.groupMessage:ComponentByName("labelMessageTitle", typeof(UILabel))
	self.textInputGroup = self.groupMain:NodeByName("textInputGroup").gameObject
	self.avatarImg = self.textInputGroup:ComponentByName("avatarImg", typeof(UISprite))
	self.textInputLabel = self.textInputGroup:ComponentByName("textInputLabel", typeof(UILabel))
	self.sendBtn = self.textInputGroup:NodeByName("sendBtn").gameObject
	self.imgTextInput = self.textInputGroup:ComponentByName("imgTextInput", typeof(UISprite))
	self.parnerCardGroup = self.groupMain:NodeByName("parnerCardGroup").gameObject
	self.scrollCard = self.parnerCardGroup:ComponentByName("scrollCard", typeof(UIScrollView))
	self.cardComponents = self.scrollCard:NodeByName("cardComponents").gameObject
	self.cardComponentsGrid = self.scrollCard:ComponentByName("cardComponents", typeof(UIGrid))
	self.gCardTouch = self.groupMain:NodeByName("gCardTouch").gameObject
	self.input = xyd.addTextInput(self.textInputLabel, {
		type = xyd.TextInputArea.InputSingleLine,
		getText = function ()
			if not self.isFirstOpenText then
				self.isFirstOpenText = true

				return ""
			end

			return self.textInputLabel.text
		end,
		callback = function ()
			self.textInputLabel.color = Color.New2(1179277055)
		end
	})
end

function ActivityPopularityVoteSupportMessageWindow:playOpenAnimation(callback)
	ActivityPopularityVoteSupportMessageWindow.super.playOpenAnimation(self, callback)

	local action = self:getSequence()
	self.groupMain:GetComponent(typeof(UIWidget)).alpha = 0.01

	local function setter(value)
		self.groupMain:GetComponent(typeof(UIWidget)).alpha = value
	end

	if not self.effectKaiChang then
		self.effectKaiChang = xyd.Spine.new(self.groupTopModel.gameObject)

		self.effectKaiChang:setInfo("fx_ui_direct", function ()
			xyd.setUITextureByNameAsync(self.titleTexture, "station_title_" .. xyd.Global.lang, true, function ()
				self.effectKaiChang:changeAttachment("title", self.titleTexture)
				self.effectKaiChang:setRenderTarget(self.groupTopModel:GetComponent(typeof(UIWidget)), 1)
				xyd.SoundManager.get():playSound(2142)
				self.effectKaiChang:play("fx_ui_direct_open", 1, 1, function ()
					self.effectKaiChang:SetActive(false)
				end)
				action:Insert(0.4, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0.01, 1, 0.4))
			end)
		end)
	end
end

function ActivityPopularityVoteSupportMessageWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_POPULARITY_VOTE_TEXT03")
	self.likeLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT1")
	self.textInputLabel.text = __("PARTNER_WAIT_TO_ADD_COMMENT")
	self.labelMessageTitle.text = __("PARTNER_COMMENT_ALL")

	self:updateData()

	self.likeNum.text = self.totalTicket or 0

	self:initPartnerSkin()
	self:setAvatar()
end

function ActivityPopularityVoteSupportMessageWindow:updateData()
	self.totalTicket = self.activityData:getTicketByPeriodAndPartner(self.partnerTableID, self.curPeriod)
	self.partners = {}
	self.commentID = xyd.tables.partnerTable:getCommentID(self.partnerTableID)
	local tableIDs = xyd.tables.partnerDirectTable:getTableIds(self.commentID)

	for i = 1, #tableIDs do
		local np = Partner.new()

		np:populate({
			table_id = tableIDs[i],
			star = xyd.tables.partnerTable:getStar(tableIDs[i]),
			lev = xyd.tables.partnerTable:getMaxlev(tableIDs[i])
		})
		table.insert(self.partners, np)
	end

	self.commentInfos = {}

	self.activityData:reqCommentInfos(self.partnerTableID)
end

function ActivityPopularityVoteSupportMessageWindow:updateCommentGroup()
	dump(self.commentInfos)

	if not self.commentInfos or #self.commentInfos <= 0 then
		return
	end

	if not self.commentWrapContent then
		self.commentWrapContent = LuaFlexibleWrapContent.new(self.scrollView.gameObject, MessageItem, self.item, self.container, self.scrollView, nil, self)
	end

	self.commentWrapContent:update()
	self.commentWrapContent:setDataNum(#self.commentInfos)
end

function ActivityPopularityVoteSupportMessageWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.gCardTouch).onDragStart = function ()
		self:onScrollBegin()
	end

	UIEventListener.Get(self.gCardTouch).onDrag = function (go, delta)
		self:onScrollMove(delta)
	end

	UIEventListener.Get(self.gCardTouch).onDragEnd = function ()
		self:onScrollEnd()
	end

	UIEventListener.Get(self.sendBtn.gameObject).onClick = handler(self, self.onClickBtnSend)

	self.eventProxy_:addEventListener(xyd.event.COMMENT_PARTNER, handler(self, function ()
		self:updateInputGroup()
	end))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_POPULARITY_VOTE then
			local detail = cjson.decode(data.detail)
			local type = detail.type

			if type == 4 then
				self.commentInfos = self.activityData:getCommentListByParner(self.partnerTableID)

				self:updateCommentGroup()
				self:updateInputGroup()
			elseif type == 2 then
				self.commentInfos = self.activityData:getCommentListByParner(self.partnerTableID)

				self:updateCommentGroup()
				self:updateInputGroup()
			end
		end
	end)
end

function ActivityPopularityVoteSupportMessageWindow:onScrollBegin(event)
	self.scrollX = 0
end

function ActivityPopularityVoteSupportMessageWindow:onScrollMove(delta)
	self.scrollX = self.scrollX + delta.x
end

function ActivityPopularityVoteSupportMessageWindow:onScrollEnd(event)
	if self.isMove then
		return
	end

	if self.scrollX > 10 and self.currentSkin > 1 then
		self.currentSkin = self.currentSkin - 1

		self:setSkinState(0.6)
	elseif self.scrollX < -10 and self.currentSkin < #self.partners then
		self.currentSkin = self.currentSkin + 1

		self:setSkinState(0.6)
	end
end

function ActivityPopularityVoteSupportMessageWindow:initPartnerSkin()
	self.skinCards = {}
	local dressSkinID = self.partnerTableID

	for i = 1, #self.partners do
		local card = PartnerCard.new(self.cardComponents)

		card:setInfo(self.partners[i]:getInfo())
		table.insert(self.skinCards, card)

		if self.partners[i]:getTableID() == self.partnerTableID then
			self.currentSkin = i
		end
	end

	self.cardComponents:GetComponent(typeof(UIGrid)):Reposition()
	self:setSkinState(0)
end

function ActivityPopularityVoteSupportMessageWindow:setSkinState(ease)
	if ease == nil then
		ease = 0
	end

	if self.isMove then
		return
	end

	if ease == 0 then
		local transform = self.cardComponents.transform

		self.cardComponents:SetLocalPosition(-166 * (self.currentSkin - 1), transform.localPosition.y, transform.localPosition.z)
	else
		self.isMove = true
		local action = self:getSequence()

		action:Append(self.cardComponents.transform:DOLocalMoveX(-166 * (self.currentSkin - 1), ease))
		action:AppendCallback(function ()
			action:Kill(false)

			action = nil
			self.isMove = false
		end)
	end

	for i = 1, #self.skinCards do
		local card = self.skinCards[i]

		if self.currentSkin == i then
			card:setGroupScale(1, ease)
		else
			card:setGroupScale(0.9, ease)
		end
	end
end

function ActivityPopularityVoteSupportMessageWindow:setAvatar()
	local avatarID = xyd.models.selfPlayer:getAvatarID()
	local iconType = xyd.tables.itemTable:getType(avatarID)
	local iconName = ""

	if iconType == xyd.ItemType.HERO_DEBRIS then
		local partnerCost = xyd.tables.itemTable:partnerCost(avatarID)
		iconName = xyd.tables.partnerTable:getAvatar(partnerCost[1])
	elseif iconType == xyd.ItemType.HERO then
		iconName = xyd.tables.partnerTable:getAvatar(avatarID)
	elseif iconType == xyd.ItemType.SKIN then
		iconName = xyd.tables.equipTable:getSkinAvatar(avatarID)
	else
		iconName = xyd.tables.itemTable:getIcon(avatarID)
	end

	if avatarID and avatarID > 0 then
		xyd.setUISpriteAsync(self.avatarImg, nil, iconName)
		self.avatarImg:SetActive(true)
	else
		self.avatarImg:SetActive(false)
	end
end

function ActivityPopularityVoteSupportMessageWindow:updateInputGroup()
	local selfComment = self.activityData:getSelfComment(self.partnerTableID)

	if not selfComment then
		self.haveComment = false
		self.textInputLabel.text = __("PARTNER_WAIT_TO_ADD_COMMENT")
	else
		self.haveComment = true
		self.textInputLabel:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		self.textInputLabel.text = __("ACTIVITY_POPULARITY_VOTE_TEXT06")
	end
end

function ActivityPopularityVoteSupportMessageWindow:onClickBtnSend()
	if self.haveComment then
		xyd.alertTips(__("ACTIVITY_POPULARITY_VOTE_TEXT07"))

		return
	end

	local msg = self.textInputLabel.text

	dump(msg)

	if not self.isFirstOpenText then
		msg = ""
	end

	dump(msg)

	if not self:checkMsg(msg) then
		return
	end

	self.activityData:sendSelfComment(self.partnerTableID, msg)
end

function ActivityPopularityVoteSupportMessageWindow:checkMsg(msg)
	local data = xyd.tables.miscTable:split2Cost("partner_comment_length_limit" .. "_" .. tostring(xyd.Global.lang), "value", "|")

	if not msg or xyd.getStrLength(msg) < data[1] then
		xyd.showToast(__("PARTNER_COMMENT_MSG_LESS"))

		return false
	elseif data[2] < xyd.getStrLength(msg) then
		xyd.showToast(__("PARTNER_COMMENT_MSG_LIMIT"))

		return false
	elseif xyd.tables.filterWordTable:isInWords(msg) then
		xyd.showToast(__("COMIC_COMMENT_DIRTY"))

		return false
	end

	return true
end

function ActivityPopularityVoteSupportMessageWindow:updateReportItem(newReportItem)
	if self.reportItem then
		self.reportItem:removeReportBtn()

		self.reportItem = nil
	end

	if newReportItem then
		self.reportItem = newReportItem
	end
end

function ActivityPopularityVoteSupportMessageWindow:onReportMessage()
	if self.reportItem then
		self.reportItem:removeReportBtn()

		self.reportItem = nil
	end
end

function ActivityPopularityVoteSupportMessageWindow:close(callback, skipAnimation)
	if self.isclosing then
		return
	end

	self.isclosing = true

	self.groupMain:SetActive(false)
	self.effectKaiChang:SetActive(true)
	xyd.SoundManager.get():playSound(2143)
	self.effectKaiChang:play("fx_ui_direct_close", 1, 1, function ()
		self.effectKaiChang:SetActive(false)
		NGUITools.DestroyChildren(self.groupTopModel.transform)

		self.effectKaiChang = nil

		ActivityPopularityVoteSupportMessageWindow.super.close(self, callback, skipAnimation)
	end)

	local function setter(value)
		self.effectKaiChang.alpha = value
	end

	local action = self:getSequence()

	action:Insert(0.2, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0.01, 0.6))
end

function MessageItem:ctor(go, parent, realIndex)
	MessageItem.super.ctor(self, go, parent)

	self.parent = parent
	self.realIndex = realIndex
	self.showBtnReport = false
end

function MessageItem:initUI()
	self.topGroup = self.go:NodeByName("topGroup").gameObject
	self.avatarImg = self.topGroup:ComponentByName("avatarImg", typeof(UISprite))
	self.bg = self.topGroup:ComponentByName("bg", typeof(UISprite))
	self.shader = self.topGroup:ComponentByName("shader", typeof(UISprite))
	self.likeImg = self.topGroup:ComponentByName("likeImg", typeof(UISprite))
	self.likeCountLabel = self.topGroup:ComponentByName("likeCountLabel", typeof(UILabel))
	self.serverId = self.topGroup:ComponentByName("serverId", typeof(UILabel))
	self.nameLabel = self.topGroup:ComponentByName("nameLabel", typeof(UILabel))
	self.timeLabel = self.topGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.contentLabel = self.go:ComponentByName("contentLabel", typeof(UILabel))
	self.labelHide = self.go:ComponentByName("labelHide", typeof(UILabel))
	self.bottomGroup = self.go:NodeByName("bottomGroup").gameObject
	self.btnTrans = self.bottomGroup:NodeByName("btnTrans").gameObject
	self.moreGroup_ = self.bottomGroup:NodeByName("moreGroup_").gameObject
	self.imgTop = self.go:ComponentByName("imgTop", typeof(UISprite))

	UIEventListener.Get(self.btnTrans).onClick = function ()
		self:onTranslate()
	end

	UIEventListener.Get(self.moreGroup_).onClick = function ()
		if self.reportBtn then
			self:updateMainReport()

			return
		end

		self.data.report_type = xyd.Report_Type.ACTIVITY_POPULARITY_VOTE
		self.data.partner_table_id = self.parent.partnerTableID
		local params = {
			open_type = 2,
			data = self.data,
			time = self.time
		}
		self.reportBtn = ReportBtn.new(self.moreGroup_.gameObject, params)

		self.reportBtn:SetActive(true)
		self.reportBtn:setPosition(nil, Vector3(-20, 40, 0))
		self:updateMainReport(true)
	end
end

function MessageItem:refresh()
	self.data = self.parent.commentInfos[-self.realIndex]

	if not self.data then
		self.go.gameObject:SetActive(false)

		return
	else
		self.go.gameObject:SetActive(true)
	end

	self.likeCountLabel.text = self.data.vote
	self.time = self.data.time
	self.serverId.text = xyd.getServerNumber(self.data.server_id)
	self.nameLabel.text = xyd.getRoughDisplayName(self.data.player_name, 17)

	if self.data.showTransl then
		self.contentLabel.text = self.data.msg
	elseif self.data.originalContent then
		self.contentLabel.text = self.data.originalContent
	else
		self.contentLabel.text = self.data.msg
	end

	self.labelHide.text = self.contentLabel.text
	self.timeLabel.text = self:setTime()
	self.avatar_id = self.data.avatar_id

	self:setAvatar()

	self.go:ComponentByName("", typeof(UIWidget)).height = self:getHeight()
end

function MessageItem:onTouchAward()
	self.parent:getAward()
end

function MessageItem:getHeight()
	local data = self.parent.commentInfos[-self.realIndex]

	if data and data.msg then
		if data.showTransl then
			self.labelHide.text = data.msg
		elseif data.originalContent then
			self.labelHide.text = data.originalContent
		else
			self.labelHide.text = data.msg
		end

		return self.labelHide.height + 160
	end

	return 184
end

function MessageItem:onTranslate()
	if self.data.inTransl then
		xyd.alert(xyd.AlertType.TIPS, __("CHAT_TRANSLATEING"))

		return
	end

	self.data.showTransl = not self.data.showTransl

	self:refresh()

	if self.data.showTransl then
		if not self.data.originalContent then
			self.data.inTransl = true
			self.data.originalContent = self.data.msg
			self.data.msg = xyd.models.acDFA:preTraslation(self.data.msg)

			self:refresh()
			xyd.models.partnerComment:translateFrontend(self.data, function (msg, type)
				if type == xyd.TranslateType.DOING then
					xyd.alert(xyd.AlertType.TIPS, __("CHAT_TRANSLATEING"))
				else
					if not self.contentLabel or tolua.isnull(self.contentLabel.gameObject) then
						return
					end

					self.data.inTransl = false
					self.contentLabel.text = msg.translate
					self.labelHide.text = msg.translate
					self.data.msg = xyd.checkCondition(self.data.originalContent, self.data.originalContent, self.data.msg)

					self:refresh()

					local win = xyd.getWindow("activity_popularity_vote_support_message_window")

					if win and win.commentWrapContent then
						win.commentWrapContent:refreshAll()
					end
				end
			end)
		else
			self.data.inTransl = false
			self.contentLabel.text = self.data.msg
			self.labelHide.text = self.data.msg

			self:refresh()

			local win = xyd.getWindow("activity_popularity_vote_support_message_window")

			if win and win.commentWrapContent then
				win.commentWrapContent:refreshAll()
			end
		end
	else
		self.data.msg = xyd.checkCondition(self.data.originalContent, self.data.originalContent, self.data.msg)
		self.contentLabel.text = self.data.msg
		self.labelHide.text = self.data.msg

		self:updateContent()

		local win = xyd.getWindow("activity_popularity_vote_support_message_window")

		if win and win.commentWrapContent then
			win.commentWrapContent:refreshAll()
		end
	end
end

function MessageItem:setAvatar()
	local avatarID = self.avatar_id

	if avatarID and avatarID > 0 then
		local iconName = ""
		local iconType = xyd.tables.itemTable:getType(avatarID)

		if iconType == xyd.ItemType.HERO_DEBRIS then
			local partnerCost = xyd.tables.itemTable:partnerCost(avatarID)
			iconName = xyd.tables.partnerTable:getAvatar(partnerCost[1])
		elseif iconType == xyd.ItemType.HERO then
			iconName = xyd.tables.partnerTable:getAvatar(avatarID)
		elseif iconType == xyd.ItemType.SKIN then
			iconName = xyd.tables.equipTable:getSkinAvatar(avatarID)
		else
			iconName = xyd.tables.itemTable:getIcon(avatarID)
		end

		xyd.setUISpriteAsync(self.avatarImg, nil, iconName)
		self.avatarImg:SetActive(true)
	else
		self.avatarImg:SetActive(false)
	end
end

function MessageItem:setTime()
	local timestr = xyd.getDisplayDate(self.time, false)
	local curtimestr = xyd.getDisplayDate(xyd.getServerTime(), false)
	local time_split = xyd.split(timestr, "  ")
	local cur_split = xyd.split(curtimestr, "  ")

	if cur_split[1] == time_split[1] then
		local split_ = xyd.split(time_split[2], ":")

		return split_[1] .. ":" .. split_[2]
	else
		local split_ = xyd.split(time_split[1], "-")

		return split_[2] .. "-" .. split_[3]
	end
end

function MessageItem:updateMainReport(update)
	if update then
		self.parent:updateReportItem(self, self.data.time)
	else
		self.parent:updateReportItem()
	end
end

function MessageItem:removeReportBtn()
	if self.reportBtn then
		NGUITools.Destroy(self.reportBtn:getGameObject())

		self.reportBtn = nil
	end
end

return ActivityPopularityVoteSupportMessageWindow
