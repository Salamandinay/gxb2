local Comic = class("Comic", import(".BaseModel"))

function Comic:ctor()
	Comic.super.ctor(self)

	self.commentInfo_ = {}
	self.likeCommentList_ = {}
	self.reqStatus_ = {}
	self.comment_time_ = {}
	self.comment_cnt_ = {}
end

function Comic:onRegister()
	Comic.super.onRegister(self)
	self:registerEvent(xyd.event.GET_COMMENTS, handler(self, self.onGetComments))
	self:registerEvent(xyd.event.COMMENT, handler(self, self.onComment))
	self:registerEvent(xyd.event.LIKE_COMMENT, handler(self, self.onLikeComment))
end

function Comic:onGetComments(event)
	local data = event.data
	local chapterid = nil

	if data.comments then
		if #data.comments == 0 then
			return
		end

		chapterid = data.comments[1].chapter_id
	end

	if data.banned_info then
		self.banned_info_ = data.banned_info
	end

	self.commentInfo_[chapterid] = data.comments
	self.likeCommentList_[chapterid] = data.like_ids
end

function Comic:onComment(event)
	local data = event.data
	local chapter_id = data.chapter_id
	local comment_id = data.comment_id

	table.insert(self.commentInfo_[chapter_id], data)
end

function Comic:onLikeComment(event)
	local data = event.data
	local chapter_id = data.chapter_id
	local comment_id = data.comment_id
	local like = data.like

	for _, comment in pairs(self.commentInfo_[chapter_id]) do
		if comment.comment_id == comment_id then
			comment.like = like
		end
	end

	local idx = self:findNumInTable(self.likeCommentList_[chapter_id], comment_id)

	if idx > 0 then
		table.remove(self.likeCommentList_[chapter_id], idx)
	else
		table.insert(self.likeCommentList_[chapter_id], comment_id)
	end
end

function Comic:findNumInTable(table, num)
	for idx, number in pairs(table) do
		if number == num then
			return idx
		end
	end

	return -1
end

function Comic:getComicNum()
	return self.comicNum
end

function Comic:setRedMark()
	local tmpChapter = tonumber(xyd.db.misc:getValue("comic" .. tostring(xyd.Global.playerID))) or 0

	if self.comicNum <= tmpChapter or not xyd.checkFunctionOpen(xyd.FunctionID.COMIC, true) or xyd.Global.lang == "de_de" or xyd.Global.lang == "ko_kr" then
		xyd.models.redMark:setMark(xyd.RedMarkType.COMIC, false)
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.COMIC, true)
	end
end

function Comic:calculateTotal()
	local ids = xyd.tables.comicTable:getIDs()
	local curTime = xyd.getServerTime()
	local count = 0

	for key, i in ipairs(ids) do
		if curTime < xyd.tables.comicTable:getPublishTime(tonumber(i)) then
			break
		end

		count = count + 1
	end

	self.comicNum = count or 1
end

function Comic:getCommentsData(chapterID)
	if self.commentInfo_[chapterID] or self.reqStatus_[chapterID] and xyd.getServerTime() < self.reqStatus_[chapterID] then
		return self.commentInfo_[chapterID]
	end

	return nil
end

function Comic:reqCommentsData(chapterID)
	if self:getCommentsData(chapterID) then
		return self:getCommentsData(chapterID)
	end

	self.reqStatus_[chapterID] = xyd.getServerTime() + xyd.tables.miscTable:getNumber("comic_update_time", "value")
	self.commentInfo_[chapterID] = {}
	self.likeCommentList_[chapterID] = {}
	local msg = messages_pb.get_comments_req()
	msg.chapter_id = chapterID

	xyd.Backend.get():request(xyd.mid.GET_COMMENTS, msg)

	return nil
end

function Comic:reqComment(chapterID, Msg)
	if not self:judgeCommentCD(chapterID) then
		return
	end

	local msg = messages_pb.comment_req()
	msg.chapter_id = chapterID
	msg.msg = Msg

	xyd.Backend.get():request(xyd.mid.COMMENT, msg)
end

function Comic:judgeCommentCD(chapterID)
	local cd = self:getCommentCD(chapterID)

	if self.comment_time_[chapterID] == nil or xyd.getServerTime() > self.comment_time_[chapterID] + cd then
		self.comment_time_[chapterID] = xyd.getServerTime()
		self.comment_cnt_[chapterID] = self.comment_cnt_[chapterID] + 1

		return true
	end

	local dif = self.comment_time_[chapterID] + cd - xyd.getServerTime()

	xyd.showToast(__("COMIC_COMMENT_IN_CD", dif))

	return false
end

function Comic:getCommentCD(chapterID)
	if not self.comment_time_[chapterID] then
		self.comment_cnt_[chapterID] = 0
		self.comment_time_[chapterID] = 0
	end

	if self.comment_time_[chapterID] + xyd.tables.miscTable:getNumber("comic_cancel_cd", "value") < xyd.getServerTime() then
		self.comment_cnt_[chapterID] = 0
	end

	local cnt = self.comment_cnt_[chapterID]

	if cnt == 0 then
		return 0
	end

	local cur_time = 1

	for i = 1, cnt - 1 do
		cur_time = cur_time * 2
	end

	return cur_time * xyd.tables.miscTable:getNumber("comic_comment_cd", "value")
end

function Comic:getHotComment(chapterID)
	local comments = self:getCommentsData(chapterID)

	if not comments or #comments == 0 then
		return {}
	end

	table.sort(comments, function (a, b)
		if b.like < a.like then
			return true
		elseif a.like == b.like then
			return a.created_time < b.created_time
		else
			return false
		end
	end)

	return comments[1]
end

function Comic:isLikeComment(chapterID, commentID)
	if self.likeCommentList_[chapterID] and self:findNumInTable(self.likeCommentList_[chapterID], commentID) > 0 then
		return 1
	else
		return 0
	end
end

function Comic:reqLikeComment(chapterID, commentID)
	local msg = messages_pb.like_comment_req()
	msg.chapter_id = chapterID
	msg.comment_id = commentID

	xyd.Backend.get():request(xyd.mid.LIKE_COMMENT, msg)
end

function Comic:getCommentLikeCount(chapterID, commentID)
	for i = 1, #self.commentInfo_[chapterID] do
		local data = self.commentInfo_[chapterID][i]

		if data.comment_id == commentID then
			return data.like
		end
	end

	return nil
end

function Comic:getCommentInfo(chapterID, commentID)
	for i = 1, #self.commentInfo_[chapterID] do
		local data = self.commentInfo_[chapterID][i]

		if data.comment_id == commentID then
			return data
		end
	end

	return nil
end

function Comic:updateCommentInfo(chapter_id, comment_id, data)
	for i = 1, #self.commentInfo_[chapter_id] do
		local res = self.commentInfo_[chapter_id][i]

		if res.comment_id == comment_id then
			self.commentInfo_[chapter_id][i] = data
		end
	end
end

function Comic:getCommentCount(chapter_id)
	return #self.commentInfo_[chapter_id]
end

function Comic:checkIsBanner()
	if not self.banned_info_ or not self.banned_info_.is_banned or self.banned_info_.is_banned ~= 1 then
		return false
	end

	if self.banned_info_.is_banned == 1 and xyd.getServerTime() <= self.banned_info_.end_time then
		return true
	end

	return false
end

function Comic:getBannerEndTime()
	if self.banned_info_ and self.banned_info_.end_time then
		return self.banned_info_.end_time - xyd.getServerTime()
	end

	return 0
end

return Comic
