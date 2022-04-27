local ComicCommentWindow = class("ComicCommentWindow", import(".BaseWindow"))
local ComicCommentWindowComp = class("ComicCommentWindowComp")

function ComicCommentWindow:ctor(name, params)
	ComicCommentWindow.super.ctor(self, name)

	self.needOpenPrinter_ = params.needOpenPrinter
	self.chapter_id_ = params.chapter_id
	self.comic_ = xyd.models.comic

	self.eventProxy_:addEventListener(xyd.event.COMMENT, handler(self, self.onComment))
	self.eventProxy_:addEventListener(xyd.event.GET_COMMENTS, handler(self, self.onGetComment))
	self.eventProxy_:addEventListener(xyd.event.REPORT_MESSAGE, handler(self, self.updateReportItem))
end

function ComicCommentWindow:initWindow()
	ComicCommentWindow.super.initWindow(self)

	self.groupMain_ = self.window_.transform:ComponentByName("groupMain_", typeof(UIWidget))
	local mainTrans = self.groupMain_.transform
	self.closeBtn = mainTrans:ComponentByName("closeBtn", typeof(UISprite))
	self.chapterTitleLabel_ = mainTrans:ComponentByName("chapterTitleLabel", typeof(UILabel))
	self.hotCommentGroup_ = mainTrans:NodeByName("groupHotCommer/hotCommentGroup").gameObject
	self.hotCommentTitleLabel_ = mainTrans:ComponentByName("groupHotCommer/e:Rect/hotCommentTitleLabel", typeof(UILabel))
	self.commentTitleLabel_ = mainTrans:ComponentByName("groupTitleLabel/e:Rect/commentTitleLabel", typeof(UILabel))
	self.itemScroll_ = mainTrans:ComponentByName("itemScroller", typeof(UIScrollView))
	self.itemCotent_ = mainTrans:ComponentByName("itemScroller/itemGroup", typeof(MultiRowWrapContent))
	self.itemRoot_ = mainTrans:ComponentByName("itemScroller/ComicCommentWindowItem", typeof(UIWidget))

	self.itemRoot_.gameObject:SetActive(false)

	self.itemWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.itemScroll_, self.itemCotent_, self.itemRoot_.gameObject, ComicCommentWindowComp, self)
	self.avatarImg_ = mainTrans:ComponentByName("textInputGroup/e:Group/avatarImg", typeof(UISprite))
	self.sendBtn_ = mainTrans:ComponentByName("textInputGroup/sendBtn", typeof(UISprite))
	self.textEdit_ = mainTrans:ComponentByName("textInputGroup/textEdit_", typeof(UILabel))
	self.textBefore_ = mainTrans:ComponentByName("textInputGroup/textEditBefore", typeof(UILabel))
	self.textBefore_.text = __("COMIC_WAIT_TO_ADD_COMMENT")

	xyd.addTextInput(self.textEdit_, {
		type = xyd.TextInputArea.InputSingleLine,
		textBack = __("COMIC_WAIT_TO_ADD_COMMENT"),
		textBackLabel = self.textBefore_
	})

	UIEventListener.Get(self.closeBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ComicCommentWindow:playOpenAnimation(callback)
	ComicCommentWindow.super.playOpenAnimation(self, function ()
		self.data_ = self.comic_:reqCommentsData(self.chapter_id_)
		self.groupMain_.transform.localPosition = Vector3(0, -1000, 0)
		local action = DG.Tweening.DOTween.Sequence()

		action:Insert(0, self.groupMain_.transform:DOLocalMove(Vector3(0, -160, 0), 0.3))
		action:Insert(0.3, self.groupMain_.transform:DOLocalMove(Vector3(0, -110, 0), 0.27))
		action:AppendCallback(function ()
			self:setWndComplete()
		end)

		if callback then
			callback()
		end
	end)
end

function ComicCommentWindow:setWndComplete()
	if self.data_ then
		self:initAllItems()
	end

	UIEventListener.Get(self.sendBtn_.gameObject).onClick = handler(self, self.onSend)
	self.chapterTitleLabel_.text = xyd.tables.comicTextTable:getChapterName(self.chapter_id_)

	self:setAvatar()
end

function ComicCommentWindow:onSend()
	local msg = tostring(self.textEdit_.text)

	if not self:checkMsg(msg) then
		return
	end

	xyd.showToast(__("COMIC_COMMENT_SUCCESSFULLY_SEND"))
	self.comic_:reqComment(self.chapter_id_, msg)
end

function ComicCommentWindow:checkMsg(msg)
	local data = xyd.tables.miscTable:split2Cost("comic_comment_length_limit" .. "_" .. tostring(xyd.Global.lang), "value", "|")

	if not msg or xyd.getStrLength(msg) < data[1] then
		xyd.showToast(__("COMIC_COMMENT_MSG_LESS"))

		return false
	elseif data[2] < xyd.getStrLength(msg) then
		xyd.showToast(__("COMIC_COMMENT_MSG_LIMIT"))

		return false
	elseif xyd.tables.filterWordTable:isInWords(msg) then
		xyd.showToast(__("COMIC_COMMENT_DIRTY"))

		return false
	elseif self.comic_:checkIsBanner() then
		local bannerCD = self.comic_:getBannerEndTime()
		bannerCD = math.ceil(bannerCD / 60)

		xyd.showToast(__("BAN_COMMENT_TIPS", bannerCD))

		return false
	end

	return true
end

function ComicCommentWindow:onComment(event)
	local data = event.data

	if data.chapter_id ~= self.chapter_id_ then
		return
	end

	self.textEdit_.text = ""
	self.textBefore_.text = __("COMIC_WAIT_TO_ADD_COMMENT")

	self:initAllItems()
end

function ComicCommentWindow:onGetComment(event)
	local data = event.data

	if data.chapter_id ~= self.chapter_id_ then
		return
	end

	self:initAllItems()
end

function ComicCommentWindow:onLikeComment(event)
	local data = event.data

	if data.chapter_id ~= self.chapter_id_ then
		return
	end

	self:initAllItems()
end

function ComicCommentWindow:initAllItems()
	self:initHot()
	self:initCommon()
	self:updateCount()
end

function ComicCommentWindow:initHot()
	if self.hotItem_ then
		self.hotItem_:remove()

		self.hotItem_ = nil
	end

	local comment = self.comic_:getHotComment(self.chapter_id_)
	local newItemRoot = NGUITools.AddChild(self.hotCommentGroup_.gameObject, self.itemRoot_.gameObject)

	newItemRoot:SetActive(true)

	self.hotItem_ = ComicCommentWindowComp.new(newItemRoot, self)

	self.hotItem_:update(nil, , comment, true)
end

function ComicCommentWindow:initCommon()
	self.itemList_ = {}
	local comments = self.comic_:reqCommentsData(self.chapter_id_)

	table.sort(comments, function (a, b)
		if b.created_time < a.created_time then
			return true
		else
			return false
		end
	end)

	for _, comment in ipairs(comments) do
		table.insert(self.itemList_, comment)
	end

	self.itemWrap_:setInfos(self.itemList_, {})
end

function ComicCommentWindow:updateCount()
	self.hotCommentTitleLabel_.text = __("COMIC_HOT_COMMENTS")
	self.commentTitleLabel_.text = __("COMIC_COMMENT") .. "(" .. tostring(self.comic_:getCommentCount(self.chapter_id_)) .. ")"
end

function ComicCommentWindow:setAvatar()
	local avatarID = xyd.models.selfPlayer:getAvatarID()

	if avatarID and avatarID > 0 then
		local avatarIcon = xyd.getItemIconName(avatarID, true)

		xyd.setUISpriteAsync(self.avatarImg_, nil, tostring(avatarIcon), nil, true)
		self.avatarImg_.gameObject:SetActive(true)
	else
		self.avatarImg_.gameObject:SetActive(false)
	end
end

function ComicCommentWindow:updateReportItem(newReportItem)
	if self.reportItem then
		self.reportItem:removeReportBtn()

		self.reportItem = nil
	elseif newReportItem then
		self.reportItem = newReportItem
	end
end

function ComicCommentWindowComp:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.comic_ = xyd.models.comic
	local itemTrans = self.go.transform
	self.moreGroupBtn_ = itemTrans:ComponentByName("BitMapGroup_/e:Image", typeof(UISprite))
	self.serverIdLabel_ = itemTrans:ComponentByName("serverInfo/serverId", typeof(UILabel))
	self.avatarImg_ = itemTrans:ComponentByName("e:Group/avatarImg", typeof(UISprite))
	self.nameLabel_ = itemTrans:ComponentByName("nameLabel", typeof(UILabel))
	self.contentLabel_ = itemTrans:ComponentByName("contentLabel", typeof(UILabel))
	self.timeLabel_ = itemTrans:ComponentByName("timeLabel", typeof(UILabel))
	self.likeCountLabel_ = itemTrans:ComponentByName("likeCountLabel", typeof(UILabel))
	self.likeImg_ = itemTrans:ComponentByName("likeCountLabel/likeImg", typeof(UISprite))
	self.eventProxy_ = xyd.EventProxy.new(xyd.EventDispatcher.inner(), self)

	self:registerEvent()
end

function ComicCommentWindowComp:update(index, realIndex, info)
	self.info = info

	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.chapter_id = info.chapter_id
	self.comment_id = info.comment_id
	self.server_id = info.server_id
	self.player_name = info.player_name
	self.created_time = info.created_time
	self.msg = info.msg
	self.like = info.like
	self.avatar_id = info.avatar_id

	self:updateLayout()
end

function ComicCommentWindowComp:registerEvent()
	UIEventListener.Get(self.likeImg_.gameObject).onClick = function ()
		self.eventProxy_:addEventListener(xyd.event.LIKE_COMMENT, handler(self, self.updateLikeImg))
		self.comic_:reqLikeComment(self.chapter_id, self.comment_id)
	end

	UIEventListener.Get(self.moreGroupBtn_.gameObject).onClick = handler(self, self.creatReportBtn)
end

function ComicCommentWindowComp:updateLikeImg()
	self.eventProxy_:removeAllEventListeners()
	self:updateInfo()
end

function ComicCommentWindowComp:remove()
	NGUITools.Destroy(self.go)
end

function ComicCommentWindowComp:updateInfo()
	local data = self.comic_:getCommentInfo(self.chapter_id, self.comment_id)

	if not data then
		return
	end

	self.info = data
	self.server_id = data.server_id
	self.player_name = data.player_name
	self.created_time = data.created_time
	self.msg = data.msg
	self.like = data.like
	self.avatar_id = data.avatar_id

	self:updateLayout()
end

function ComicCommentWindowComp:creatReportBtn()
	self:updateMainReport()

	self.info = xyd.decodeProtoBuf(self.info)
	self.info.report_type = xyd.Report_Type.COMIC_COMMENT
	self.reportBtn = import("app.components.ReportBtn").new(self.moreGroupBtn_.gameObject, {
		open_type = 2,
		data = self.info
	})

	self.reportBtn:SetLocalPosition(-33, 35, 0)
	self:updateMainReport(true)
end

function ComicCommentWindowComp:removeReportBtn()
	if self.reportBtn then
		NGUITools.DestroyChildren(self.moreGroupBtn_.gameObject.transform)

		self.reportBtn = nil
	end
end

function ComicCommentWindowComp:updateMainReport(update)
	local wnd = self.parent

	if wnd then
		if update then
			wnd:updateReportItem(self)
		else
			wnd:updateReportItem()
		end
	end
end

function ComicCommentWindowComp:updateLayout()
	self.serverIdLabel_.text = xyd.getServerNumber(self.server_id)
	self.nameLabel_.text = xyd.getRoughDisplayName(self.player_name, 17)
	self.contentLabel_.text = self.msg
	self.timeLabel_.text = self:setTime()
	local type_ = self.comic_:isLikeComment(self.chapter_id, self.comment_id)

	xyd.setUISpriteAsync(self.likeImg_, nil, "comic_comment_like" .. type_, nil, true)

	self.likeCountLabel_.text = self.like

	self:removeReportBtn()
	self:setAvatar()
end

function ComicCommentWindowComp:setAvatar()
	local avatarID = self.avatar_id

	if avatarID and avatarID > 0 then
		local avatarIcon = xyd.getItemIconName(avatarID, true)

		xyd.setUISpriteAsync(self.avatarImg_, nil, tostring(avatarIcon), nil, true)
		self.avatarImg_.gameObject:SetActive(true)
	else
		self.avatarImg_.gameObject:SetActive(false)
	end
end

function ComicCommentWindowComp:setTime()
	local timestr = xyd.getDisplayTime(self.created_time, xyd.TimestampStrType.DATE)
	local curtimestr = xyd.getDisplayTime(xyd.getServerTime(), xyd.TimestampStrType.DATE)

	if timestr == curtimestr then
		timestr = xyd.getDisplayTime(self.created_time, xyd.TimestampStrType.TIME)
		local split_ = xyd.split(timestr, ":")

		return tostring(split_[1]) .. ":" .. tostring(split_[2])
	else
		local split_ = xyd.split(timestr, "-")

		return tostring(split_[2]) .. "-" .. tostring(split_[3])
	end
end

function ComicCommentWindowComp:getGameObject()
	return self.go
end

return ComicCommentWindow
