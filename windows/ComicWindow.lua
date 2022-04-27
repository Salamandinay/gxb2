local BaseWindow = import(".BaseWindow")
local BaseComponent = import("app.components.BaseComponent")
local ComicWindow = class("ComicWindow", BaseWindow)
local ComicItem = class("ComicItem", BaseComponent)
local ComicComment = class("ComicComment", BaseComponent)
local ComicCommentItem = class("ComicCommentItem", BaseComponent)

function ComicWindow:ctor(name, params)
	ComicWindow.super.ctor(self, name, params)

	self.lock_ = {}
	self.navList_ = {}
	self.comicItemList_ = {}
	self.comicCommentList_ = {}
	self.loadNotCompleteNum_ = 0
	self.isContent_ = false
	self.curPage_ = 1
end

function ComicWindow:initWindow()
	ComicWindow.super.initWindow(self)

	self.windowTop = import("app.components.WindowTop").new(self.window_, self.name_, 3, nil, function ()
		if self.isContent_ then
			self.isContent_ = false

			self:layout()

			self.lock_ = {}

			self.windowTop:setCloseBtnState(true)
		else
			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)

	local winTrans = self.window_.transform
	self.groupContent_ = winTrans:NodeByName("content").gameObject
	local contentTrans = self.groupContent_.transform
	self.groupBottom_ = contentTrans:ComponentByName("groupBottom_", typeof(UIWidget))
	self.groupDetail_ = contentTrans:NodeByName("groupDetail_").gameObject
	self.groupList_ = contentTrans:NodeByName("groupList_").gameObject
	self.groupNewest_ = contentTrans:ComponentByName("groupList_/e:Image/groupNewest_", typeof(UIWidget))
	self.imgWordNew_ = contentTrans:ComponentByName("groupList_/e:Image/groupNewest_/imgWord_", typeof(UISprite))
	self.newImg_ = contentTrans:ComponentByName("groupList_/e:Image/groupNewest_/imgNewestTexture", typeof(UITexture))
	self.groupComicItem_ = contentTrans:ComponentByName("groupList_/e:Group/groupMain_", typeof(UIGrid))
	self.contentScrollView_ = contentTrans:ComponentByName("groupDetail_/scrollerContent_", typeof(UIScrollView))

	xyd.setUISpriteAsync(self.imgWordNew_, nil, "comic_word_" .. xyd.Global.lang)

	function self.contentScrollView_.onDragStarted()
		self:onDragStarted()
	end

	function self.contentScrollView_.onDragFinished()
		self:onDragFinished()
	end

	self.contentGrid_ = contentTrans:ComponentByName("groupDetail_/scrollerContent_/groupContent_", typeof(UIGrid))
	self.imgCircleNewest_ = contentTrans:ComponentByName("groupList_/e:Image/groupNewest_/groupPreLoadNewest_/imgCircleNewest_", typeof(UISprite))
	self.groupPreLoadNewest_ = contentTrans:ComponentByName("groupList_/e:Image/groupNewest_/groupPreLoadNewest_", typeof(UIWidget))
	self.groupLoadingEffect_ = contentTrans:NodeByName("groupDetail_/groupLoadingEffect_/root").gameObject

	for i = 1, 7 do
		local tableBtn = contentTrans:NodeByName("groupBottom_/tab_" .. i).gameObject
		local uiButton = tableBtn:GetComponent(typeof(UIButton))
		local tableLabel = tableBtn:ComponentByName("label", typeof(UILabel))
		local tableImg = tableBtn:ComponentByName("img", typeof(UISprite)).gameObject
		local bgChosen = tableBtn:ComponentByName("chosen", typeof(UISprite)).gameObject
		local bgUnChosen = tableBtn:ComponentByName("unchosen", typeof(UISprite)).gameObject
		local mask = nil

		if i == 3 or i == 4 or i == 5 then
			mask = tableBtn:ComponentByName("mask", typeof(UISprite))
		else
			mask = tableBtn:ComponentByName("mask", typeof(UIWidget))
		end

		mask.gameObject:SetActive(false)

		UIEventListener.Get(tableBtn).onClick = function ()
			self:onBtnTouch(i)
		end

		self.navList_[i] = {
			btn = uiButton,
			label = tableLabel,
			img = tableImg,
			bgChosen = bgChosen,
			bgUnChosen = bgUnChosen,
			mask = mask
		}
	end

	self:calculateTotal()
	self:initNewestImg()
	self:layout()
	self:registerEvent()
	XYDCo.WaitForFrame(2, handler(self, self.startAnimation), nil)
end

function ComicWindow:startAnimation()
	if tolua.isnull(self.groupContent_) then
		return
	end

	self.groupContent_:SetActive(true)

	local sequene = self:getSequence()
	local transform = self.groupContent_.transform

	transform:SetLocalPosition(-1000, 0, 0)
	sequene:Append(transform:DOLocalMoveX(50, 0.3))
	sequene:Append(transform:DOLocalMoveX(0, 0.27))
	sequene:AppendCallback(function ()
		sequene:Kill(false)

		sequene = nil
	end)
end

function ComicWindow:calculateTotal()
	local ids = xyd.tables.comicTable:getIDs()
	local curTime = xyd.getServerTime()
	local count = 0

	for _, id in ipairs(ids) do
		if xyd.tables.comicTable:getPublishTime(id) <= curTime then
			count = count + 1
		end
	end

	self.comicNum_ = count or 1
	self.pageNum = math.ceil(self.comicNum_ / 9)
	self.curPage_ = self.pageNum
end

function ComicWindow:initNewestImg()
	local function action()
		if not self.imgCircleNewest_ then
			self.timerNewestLoad_:Stop()

			self.timerNewestLoad_ = nil
		else
			local angles = self.imgCircleNewest_.transform.localEulerAngles + Vector3(0, 0, 5)
			self.imgCircleNewest_.transform.localEulerAngles = angles
		end
	end

	self.groupPreLoadNewest_.gameObject:SetActive(true)

	self.timerNewestLoad_ = FrameTimer.New(action, 1, -1, false)

	self.timerNewestLoad_:Start()

	local loadPath = xyd.tables.comicTable:getBanner(self.comicNum_)

	self:loadImgByUrl(loadPath, self.newImg_, function ()
		local wnd = xyd.WindowManager:get():getWindow("comic_window")

		if wnd then
			self.groupPreLoadNewest_.gameObject:SetActive(false)
			self.timerNewestLoad_:Stop()

			self.timerNewestLoad_ = nil
			self.hasLoadNewImg_ = true
		end
	end)
end

function ComicWindow:layout()
	if not self.isContent_ then
		self.groupList_.gameObject:SetActive(true)
		self.groupDetail_.gameObject:SetActive(false)
		self.groupBottom_.gameObject:SetActive(true)
		self.contentGrid_.gameObject:SetActive(false)
		self:updateList()
	else
		self.groupList_.gameObject:SetActive(false)
		self.groupDetail_.gameObject:SetActive(true)
		self.groupBottom_.gameObject:SetActive(false)
		self.contentGrid_.gameObject:SetActive(true)
		self:firstUpdateContent()
	end

	self:updateBtn()
end

function ComicWindow:touchPoint()
	local msg = messages_pb.log_partner_data_touch_req()
	msg.touch_id = xyd.DaDian.DRESS_SUMMON

	xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
end

function ComicWindow:updateBtn()
	local total = math.ceil(self.comicNum_ / 9)
	local total_chapter = self.comicNum_

	if self.isContent_ == false then
		if total >= 3 then
			if self.curPage_ == 1 then
				self.navList_[3].label.text = "3"
				self.navList_[4].label.text = "2"
				self.navList_[5].label.text = "1"

				self:setBtnState(5)
				self:setDark({
					6,
					7
				})
				self:setEnable({
					1,
					2
				})
			elseif self.curPage_ == total then
				self:setBtnState(3)

				self.navList_[3].label.text = tostring(self.curPage_)
				self.navList_[4].label.text = tostring(self.curPage_ - 1)
				self.navList_[5].label.text = tostring(self.curPage_ - 2)

				self:setEnable({
					6,
					7
				})
				self:setDark({
					1,
					2
				})
			else
				self:setBtnState(4)

				self.navList_[3].label.text = tostring(self.curPage_ + 1)
				self.navList_[4].label.text = tostring(self.curPage_)
				self.navList_[5].label.text = tostring(self.curPage_ - 1)

				self:setEnable({
					1,
					2,
					6,
					7
				})
				self:setDark({})
			end
		elseif total == 2 then
			self.navList_[3].label.text = "3"
			self.navList_[4].label.text = "2"
			self.navList_[5].label.text = "1"

			if self.curPage_ == 1 then
				self:setEnable({
					1,
					2
				})
				self:setDark({
					6,
					7
				})
				self:setBtnState(5)
			elseif self.curPage_ == 2 then
				self:setEnable({
					6,
					7
				})
				self:setDark({
					1,
					2
				})
				self:setBtnState(4)
			end
		else
			self.navList_[3].label.text = "3"
			self.navList_[4].label.text = "2"
			self.navList_[5].label.text = "1"

			self:setEnable({})
			self:setDark({
				1,
				2,
				6,
				7
			})
			self:setBtnState(5)
		end
	end
end

function ComicWindow:setBtnState(index)
	for i = 3, 5 do
		self.navList_[i].bgChosen:SetActive(index == i)
		self.navList_[i].bgUnChosen:SetActive(index ~= i)
	end
end

function ComicWindow:setEnable(params)
	for _, idx in ipairs(params) do
		local nav = self.navList_[idx]

		if nav.btn then
			nav.btn:SetEnabled(true)
		end

		nav.mask.gameObject:SetActive(false)
	end
end

function ComicWindow:setDark(params)
	self.navList_[1].btn:SetEnabled(true)
	self.navList_[2].btn:SetEnabled(true)
	self.navList_[7].btn:SetEnabled(true)
	self.navList_[6].btn:SetEnabled(true)

	for _, idx in ipairs(params) do
		local nav = self.navList_[idx]

		if nav.btn then
			nav.btn:SetEnabled(false)
		end

		nav.mask.gameObject:SetActive(true)
	end
end

function ComicWindow:registerEvent()
	UIEventListener.Get(self.newImg_.gameObject).onClick = handler(self, self.toNewest)
end

function ComicWindow:onBtnTouch(idx)
	if not self.isContent_ then
		local total = math.ceil(self.comicNum_ / 9)
		local curPage = self.curPage_
		local switch = {
			function ()
				curPage = total
			end,
			function ()
				curPage = self.curPage_ + 1
			end,
			function ()
				curPage = tonumber(self.navList_[3].label.text)
			end,
			function ()
				curPage = tonumber(self.navList_[4].label.text)
			end,
			function ()
				curPage = tonumber(self.navList_[5].label.text)
			end,
			function ()
				curPage = self.curPage_ - 1
			end,
			function ()
				curPage = 1
			end
		}

		switch[idx]()

		self.curPage_ = curPage

		if total < self.curPage_ then
			xyd.alertTips(__("NEW_FUNCTION_TIP"))

			self.curPage_ = total

			return
		end

		self:updateList()
	end

	self:updateBtn()
end

function ComicWindow:updateList()
	local startChapter = self.comicNum_ - (self.pageNum - self.curPage_) * 9
	local endChapter = nil

	if startChapter > 9 then
		endChapter = startChapter - 8
	else
		endChapter = 1
	end

	for i = 0, 8 do
		local id = startChapter - i
		local item = self.comicItemList_[i + 1]

		if not item then
			item = ComicItem.new(self.groupComicItem_.gameObject, self)
			self.comicItemList_[i + 1] = item
		end

		item:setInfo(id)
	end

	self.groupComicItem_:Reposition()
end

function ComicWindow:toNewest()
	if not self.hasLoadNewImg_ then
		return
	end

	self.isContent_ = true
	self.curTopChapter = self.comicNum_
	self.curLastChapter = self.comicNum_

	self:layout()
	self:touchPoint()
end

function ComicWindow:firstUpdateContent()
	for _, comment in ipairs(self.comicCommentList_) do
		comment:remove()
	end

	self.downNum_ = 0

	for i = self.curTopChapter, self.curLastChapter do
		self:loadImg(i)
	end

	self.contentGrid_:Reposition()
	self.contentScrollView_:ResetPosition()
	self:saveChapter()
end

function ComicWindow:onDragStarted()
	self.startScrollPos_ = self.contentScrollView_.transform.localPosition.y
end

function ComicWindow:onDragFinished()
	self.endScorllPos_ = self.contentScrollView_.transform.localPosition.y

	if self.endScorllPos_ - self.startScrollPos_ > 340 or self.endScorllPos_ - self.startScrollPos_ < -340 then
		if self.endScorllPos_ >= 1081 + 2200 * (self.downNum_ - 1) then
			if self.comicNum_ < self.curLastChapter + 1 then
				xyd.alertTips(__("COMIC_ALREADY_LAST"))

				return
			elseif self.loadNotCompleteNum_ == 0 then
				local startChapter = self.curLastChapter + 1

				for i = startChapter, startChapter + 2 do
					if i <= self.comicNum_ then
						self:loadImg(i, false, nil, function ()
							self.curLastChapter = self.curLastChapter + 1
						end)
					end
				end
			end
		end

		if self.endScorllPos_ <= -250 then
			if self.curTopChapter == 1 then
				xyd.alertTips(__("COMIC_ALREADY_FIRST"))

				return
			elseif self.loadNotCompleteNum_ == 0 then
				local startChapter = self.curTopChapter - 1

				if startChapter >= 1 then
					self:loadImg(startChapter, true, nil, function ()
						self.curTopChapter = self.curTopChapter - 1

						XYDCo.WaitForFrame(1, function ()
							self.contentScrollView_:SetDragAmount(0, 0, false)
						end, nil)
					end)
				end
			end
		end
	end
end

function ComicWindow:findNumInTable(table, num)
	for idx, info in ipairs(table) do
		if info == num then
			return idx
		end
	end

	return nil
end

function ComicWindow:loadImg(id, up, uiTexture, callback)
	local effect = xyd.Spine.new(self.groupLoadingEffect_)

	effect:setInfo("loading", function ()
		effect:SetLocalScale(1.19, 1.19, 1.19)
		effect:play("idle", 0, 1)
	end)
	self.groupLoadingEffect_:SetActive(true)

	self.loadNotCompleteNum_ = self.loadNotCompleteNum_ + 1
	local pathName = xyd.tables.comicTable:getUrl(id)

	if tolua.isnull(self.contentGrid_) then
		return
	end

	local comment = ComicComment.new(self.contentGrid_.gameObject, self)

	comment:setInfo(id, id == self.comicNum_)

	if up then
		comment:SetSiblingIndex(0)
	end

	self.downNum_ = self.downNum_ + 1

	self.contentGrid_:Reposition()
	table.insert(self.comicCommentList_, comment)

	uiTexture = uiTexture or comment:getUITexture()

	self:loadImgByUrl(pathName, uiTexture, function ()
		self.loadNotCompleteNum_ = self.loadNotCompleteNum_ - 1

		if self.loadNotCompleteNum_ == 0 then
			effect:stop()

			if not tolua.isnull(self.groupLoadingEffect_) then
				self.groupLoadingEffect_:SetActive(false)
				NGUITools.DestroyChildren(self.groupLoadingEffect_.transform)
			end
		end

		if callback then
			callback()
		end
	end)
end

function ComicWindow:saveChapter()
	local tmpChapter = tonumber(xyd.db.misc:getValue("comic" .. tostring(xyd.Global.playerID)))

	if not tmpChapter or tonumber(tmpChapter) < self.curLastChapter then
		xyd.db.misc:addOrUpdate({
			key = "comic" .. tostring(xyd.Global.playerID),
			value = self.curLastChapter
		})

		tmpChapter = self.curLastChapter
	end

	if tonumber(tmpChapter) == self.comicNum_ or not xyd.checkFunctionOpen(xyd.FunctionID.COMIC, true) then
		xyd.models.redMark:setMark(xyd.RedMarkType.COMIC, false)
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.COMIC, true)
	end
end

function ComicWindow:loadImgByUrl(url, uiTexture, callback)
	if XYDUtils.IsTest() then
		url = "http://192.168.2.45:9595/images/img_zh.png"
	end

	if uiTexture then
		xyd.setTextureByURL(url, uiTexture, uiTexture.width, uiTexture.height, callback)
	else
		xyd.setTextureByURL(url, uiTexture, nil, , callback)
	end
end

function ComicWindow:willClose()
	ComicWindow.super.willClose(self)

	if self.timerNewestLoad_ then
		self.timerNewestLoad_:Stop()

		self.timerNewestLoad_ = nil
	end
end

function ComicItem:ctor(parentGo, parent)
	ComicItem.super.ctor(self, parentGo)

	self.parent_ = parent
	local itemTrans = self.go.transform
	self.imgTexture_ = itemTrans:ComponentByName("imgTexture", typeof(UITexture))
	self.labelTitle_ = itemTrans:ComponentByName("labelWord_", typeof(UILabel))
	self.groupPreLoadNewest_ = itemTrans:ComponentByName("groupPreLoadNewest_", typeof(UIWidget)).gameObject
	self.imgCircleNewest_ = itemTrans:ComponentByName("groupPreLoadNewest_/imgCircleNewest_", typeof(UISprite))
	self.imgRedMark_ = itemTrans:ComponentByName("imgRedMark", typeof(UISprite))
	self.imgBg = itemTrans:ComponentByName("imgBg", typeof(UISprite))
	self.loadCnt = 0
	UIEventListener.Get(self.imgTexture_.gameObject).onClick = handler(self, self.onTouch)

	xyd.setUISpriteAsync(self.imgBg, nil, "comic_frame")
end

function ComicItem:getPrefabPath()
	return "Prefabs/Components/comic_item"
end

function ComicItem:setInfo(id)
	self.id_ = id

	if self.id_ > 0 then
		self.go:SetActive(true)
		self:layout()
	else
		self.go:SetActive(false)
	end
end

function ComicItem:layout()
	local total = xyd.models.comic:getComicNum()
	self.labelTitle_.text = __(xyd.tables.comicTextTable:getChapterName(self.id_))
	local tmpChapter = tonumber(xyd.db.misc:getValue("comic" .. tostring(xyd.Global.playerID)))

	if tmpChapter == nil then
		tmpChapter = 0
	end

	if self.id_ == total and tmpChapter < total then
		self.imgRedMark_.gameObject:SetActive(true)
	else
		self.imgRedMark_.gameObject:SetActive(false)
	end

	local function action()
		if not self.groupPreLoadNewest_.activeSelf then
			self.timerLoad_:Stop()
		else
			local angles = self.imgCircleNewest_.transform.localEulerAngles + Vector3(0, 0, -5)
			self.imgCircleNewest_.transform.localEulerAngles = angles
		end
	end

	self.groupPreLoadNewest_.gameObject:SetActive(true)

	if not self.timerLoad_ then
		self.timerLoad_ = FrameTimer.New(action, 1, -1, false)
	end

	table.insert(self.timers_, self.timerLoad_)
	self.timerLoad_:Start()

	self.loadCnt = self.loadCnt + 1

	self.parent_:loadImgByUrl(xyd.tables.comicTable:getBanner(self.id_), self.imgTexture_, function ()
		self.loadCnt = self.loadCnt - 1

		if self.loadCnt ~= 0 then
			return
		end

		local wnd = xyd.WindowManager:get():getWindow("comic_window")

		if wnd then
			self.groupPreLoadNewest_.gameObject:SetActive(false)
			self.timerLoad_:Stop()
		end
	end)
end

function ComicItem:onTouch()
	self.imgRedMark_.gameObject:SetActive(false)

	if self.parent_ and not tolua.isnull(self.parent_.window_) then
		self.parent_.isContent_ = true
		self.parent_.curTopChapter = self.id_

		if self.parent_.comicNum_ < self.id_ + 2 then
			self.parent_.curLastChapter = self.parent_.comicNum_
		else
			self.parent_.curLastChapter = self.id_ + 2
		end
	end

	self.parent_:layout()
	self.parent_:touchPoint()
end

function ComicComment:ctor(parentGo, parent)
	self.parent_ = parent

	ComicComment.super.ctor(self, parentGo)

	self.comic_ = xyd.models.comic
	self.itemList_ = {}
end

function ComicComment.getPrefabPath()
	return "Prefabs/Components/comic_comment"
end

function ComicComment:initUI()
	local itemTrans = self.go.transform
	self.comicTexture_ = itemTrans:ComponentByName("comicTexture", typeof(UITexture))
	local dragScrollView = self.comicTexture_:GetComponent(typeof(UIDragScrollView))
	dragScrollView.scrollView = self.parent_.contentScrollView_
	self.titleLabel_ = itemTrans:ComponentByName("content/titleLabel", typeof(UILabel))
	self.itemGroup_ = itemTrans:ComponentByName("content/infoGroup/itemGroup", typeof(UIWidget))
	self.noneGroup_ = itemTrans:NodeByName("content/noneGroup").gameObject
	self.noneLabel_ = itemTrans:ComponentByName("content/noneGroup/noneLabel", typeof(UILabel))
	self.textInputGroup_ = itemTrans:NodeByName("content/textInputGroup")
	self.sendBtn_ = itemTrans:ComponentByName("content/textInputGroup/sendBtn", typeof(UISprite))
	self.avatorImg_ = itemTrans:ComponentByName("content/textInputGroup/groupAvator/avatorImg", typeof(UISprite))
	self.imgLine_ = itemTrans:ComponentByName("content/e:rect_down", typeof(UISprite))
	self.moreCommentLabel_ = itemTrans:ComponentByName("content/moreCommentLabel", typeof(UILabel))
	self.textInput_ = itemTrans:ComponentByName("content/textInputGroup/textEdit_", typeof(UILabel))
	self.textBefore_ = itemTrans:ComponentByName("content/textInputGroup/textEditBefore", typeof(UILabel))
	self.textBefore_.text = __("COMIC_WAIT_TO_ADD_COMMENT")

	xyd.addTextInput(self.textInput_, {
		max_line = 3,
		type = xyd.TextInputArea.InputSingleLine,
		textBack = __("COMIC_WAIT_TO_ADD_COMMENT"),
		textBackLabel = self.textBefore_
	})

	UIEventListener.Get(self.sendBtn_.gameObject).onClick = function ()
		self:onSend()
	end

	UIEventListener.Get(self.moreCommentLabel_.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("comic_comment_window", {
			chapter_id = self.chapterID_
		})
	end

	self:registerEvent()
end

function ComicComment:SetPosition(position)
	self.go.transform.localPosition = position
end

function ComicComment:getUITexture()
	return self.comicTexture_
end

function ComicComment:setInfo(info, lineVisible)
	self.chapterID_ = info
	self.go.name = "chapter" .. info
	self.lineVisible_ = lineVisible
	local data = self.comic_:getCommentsData(self.chapterID_)

	if data then
		self:initItems()
	end

	UIEventListener.Get(self.comicTexture_.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("comic_detail_window", {
			alpha = 1,
			url = xyd.tables.comicTable:getUrl(self.chapterID_),
			chapter_id = self.chapterID_
		})
	end

	if XYDUtils.IsTest() then
		xyd.setTextureByURL("http://192.168.2.45:9595/images/img_zh.png", self.comicTexture_, self.comicTexture_.width, self.comicTexture_.height, function ()
		end)
	end

	xyd.setTextureByURL(xyd.tables.comicTable:getUrl(self.chapterID_), self.comicTexture_, self.comicTexture_.width, self.comicTexture_.height)
	self:setText()
	self:setAvatar()

	if not data then
		self.comic_:reqCommentsData(self.chapterID_)
	end
end

function ComicComment:registerEvent()
	self.eventProxy_ = self.eventProxyInner_

	self.eventProxy_:addEventListener(xyd.event.GET_COMMENTS, handler(self, self.initItems))
	self.eventProxy_:addEventListener(xyd.event.COMMENT, handler(self, self.onComment))
	self.eventProxy_:addEventListener(xyd.event.LIKE_COMMENT, handler(self, self.initItems))
end

function ComicComment:onSend()
	local msg = tostring(self.textInput_.text)

	if not self:checkMsg(msg) then
		return
	end

	self.textInput_.text = ""

	self.comic_:reqComment(self.chapterID_, msg)
end

function ComicComment:setText()
	self.titleLabel_.text = __("COMIC_HOT_COMMENTS")
	self.noneLabel_.text = __("COMIC_NO_COMMENTS")
	self.moreCommentLabel_.text = __("COMIC_MORE_COMMENTS")
end

function ComicComment:onComment()
	xyd.showToast(__("COMIC_COMMENT_SUCCESSFULLY_SEND"))
	self:initItems()
end

function ComicComment:initItems()
	if not self.itemGroup_ or not self.itemGroup_.gameObject then
		return
	end

	local comments = self.comic_:getHotComment(self.chapterID_)

	if not comments or not comments.avatar_id then
		self.itemGroup_.gameObject:SetActive(false)
		self.moreCommentLabel_.gameObject:SetActive(false)
		self.noneGroup_.gameObject:SetActive(true)

		return
	else
		self.itemGroup_.gameObject:SetActive(true)
		self.moreCommentLabel_.gameObject:SetActive(true)
		self.noneGroup_.gameObject:SetActive(false)
	end

	local contentItem = nil

	if not self.itemList_[1] then
		contentItem = ComicCommentItem.new(self.itemGroup_.gameObject)
	else
		contentItem = self.itemList_[1]
	end

	contentItem:setInfo(comments)

	self.itemList_[1] = contentItem
end

function ComicComment:checkMsg(msg)
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

function ComicComment:setAvatar()
	local avatarID = xyd.models.selfPlayer:getAvatarID()

	if avatarID and avatarID > 0 then
		local avatarIcon = xyd.getItemIconName(avatarID, true)

		xyd.setUISpriteAsync(self.avatorImg_, nil, tostring(avatarIcon), nil, true)
		self.avatorImg_.gameObject:SetActive(true)
	else
		self.avatorImg_.gameObject:SetActive(false)
	end
end

function ComicComment:remove()
	self.eventProxy_:removeAllEventListeners()
	NGUITools.Destroy(self.go)
end

function ComicComment:SetSiblingIndex(to)
	self.go.transform:SetSiblingIndex(to)
end

function ComicCommentItem:ctor(parentGo)
	ComicCommentItem.super.ctor(self, parentGo)

	self.comic_ = xyd.models.comic
end

function ComicCommentItem.getPrefabPath()
	return "Prefabs/Components/comic_comment_item"
end

function ComicCommentItem:setInfo(data)
	self.avatarID_ = data.avatar_id
	self.created_time = data.created_time
	self.msg_ = data.msg
	self.playerName_ = data.player_name
	self.server_ = data.server_id
	self.commentID_ = data.comment_id
	self.chapterID_ = data.chapter_id

	self:layout()
end

function ComicCommentItem:registerEvent()
	UIEventListener.Get(self.likeTouchGroup_).onClick = handler(self, self.touchLike)

	UIEventListener.Get(self.touchGroup_).onClick = function ()
		xyd.WindowManager.get():openWindow("comic_comment_window", {
			chapter_id = self.chapterID_
		})
	end
end

function ComicCommentItem:initUI()
	local itemTrans = self.go.transform
	self.nameLabel_ = itemTrans:ComponentByName("groupAvator/avatorNameLabel", typeof(UILabel))
	self.avatorImg_ = itemTrans:ComponentByName("groupAvator/avatorImg", typeof(UISprite))
	self.contentMsg_ = itemTrans:ComponentByName("contentLable", typeof(UILabel))
	self.touchGroup_ = self.contentMsg_.gameObject
	self.serverIdLabel_ = itemTrans:ComponentByName("groupSeverInfo/serverId", typeof(UILabel))
	self.likeLable_ = itemTrans:ComponentByName("groupLike/likeLable", typeof(UILabel))
	self.imgLike_ = itemTrans:ComponentByName("groupLike/imgLike", typeof(UISprite))
	self.likeTouchGroup_ = itemTrans:ComponentByName("groupLike/touchImg", typeof(UIWidget)).gameObject
	self.timeLabel_ = itemTrans:ComponentByName("timeLabel", typeof(UILabel))

	self:registerEvent()
end

function ComicCommentItem:layout()
	self.serverIdLabel_.text = xyd.getServerNumber(self.server_)
	self.nameLabel_.text = xyd.getRoughDisplayName(self.playerName_, 17)
	self.contentMsg_.text = self.msg_
	self.timeLabel_.text = self:setTime()

	self:setLikeCount()
	self:setAvatar()
end

function ComicCommentItem:setTime()
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

function ComicCommentItem:setLikeCount()
	self.likeLable_.text = self.comic_:getCommentLikeCount(self.chapterID_, self.commentID_)
	local flag = self.comic_:isLikeComment(self.chapterID_, self.commentID_)

	xyd.setUISprite(self.imgLike_, nil, "comic_comment_like" .. flag, nil, true)
end

function ComicCommentItem:touchLike()
	self.comic_:reqLikeComment(self.chapterID_, self.commentID_)
end

function ComicCommentItem:setAvatar()
	local avatarID = self.avatarID_

	if avatarID and avatarID > 0 then
		local avatarIcon = xyd.getItemIconName(avatarID, true)

		xyd.setUISpriteAsync(self.avatorImg_, nil, tostring(avatarIcon), nil, true)
		self.avatorImg_.gameObject:SetActive(true)
	else
		self.avatorImg_.gameObject:SetActive(false)
	end
end

return ComicWindow
