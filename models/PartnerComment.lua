local BaseModel = import(".BaseModel")
local PartnerComment = class("PartnerComment", BaseModel)
local cjson = require("cjson")

function PartnerComment:ctor()
	PartnerComment.super.ctor(self)

	self.commentInfo = {}
	self.likeCommentList = {}
	self.likePartner = {}
	self.partnerLikeNum = {}
	self.reqStatus = {}
	self.comment_time = {}
	self.comment_cnt = {}
	self.translateContent_ = {}
	self.inTranslate_ = {}
	self.translaID2Content_ = {}
	self.heightCache = {}
	self.totalHeight_ = 0
end

function PartnerComment:decodeProto(comment)
	local struct = {
		avatar_id = comment.avatar_id,
		comment_id = comment.comment_id,
		created_time = comment.created_time,
		like = comment.like,
		msg = comment.msg,
		player_id = comment.player_id,
		player_name = comment.player_name,
		server_id = comment.server_id,
		table_id = comment.table_id
	}

	return struct
end

function PartnerComment:onRegister()
	self:registerEvent(xyd.event.GET_PARTNER_COMMENTS, function (_, event)
		local data = event.data
		local tableID = data.table_id
		local comments = {}

		for _, comment in ipairs(data.comments) do
			table.insert(comments, self:decodeProto(comment))
		end

		self.commentInfo[tableID] = comments
		self.likeCommentList[tableID] = data.like_ids
		self.likePartner[tableID] = data.is_like
		self.partnerLikeNum[tableID] = data.likes

		if data.banned_info then
			self.banned_info = data.banned_info
		end
	end, self)
	self:registerEvent(xyd.event.COMMENT_PARTNER, function (_, event)
		local data = event.data
		local table_id = data.table_id
		local comment_id = data.comment_id

		table.insert(self.commentInfo[table_id], self:decodeProto(data))
	end, self)
	self:registerEvent(xyd.event.LIKE_PARTNER_COMMENT, function (_, event)
		local data = event.data
		local table_id = data.table_id
		local comment_id = data.comment_id

		self:updateCommentInfo(table_id, comment_id, data)

		if self:isLikeComment(table_id, comment_id) == 0 then
			if not self.likeCommentList[table_id] then
				self.likeCommentList[table_id] = {}
			end

			table.insert(self.likeCommentList[table_id], comment_id)
		end
	end, self)
end

function PartnerComment:updateHeight(hashCode, height)
	local oldHeight = self.heightCache[hashCode]
	local cureTotalHeight = self.totalHeight_

	if oldHeight == nil then
		self.heightCache[hashCode] = height
		cureTotalHeight = cureTotalHeight + height
	elseif oldHeight ~= height then
		self.heightCache[hashCode] = height
		cureTotalHeight = cureTotalHeight + height - oldHeight
	end

	self.totalHeight_ = cureTotalHeight
end

function PartnerComment:getTotalHeight()
	return self.totalHeight_
end

function PartnerComment:reqCommentsData(tableID)
	if self.reqStatus[tableID] and xyd.getServerTime() < self.reqStatus[tableID] then
		local data = {
			comments = self.commentInfo[tableID],
			like_ids = self.likeCommentList[tableID],
			is_like = self.likePartner[tableID],
			banned_info = self.banned_info
		}

		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.GET_PARTNER_COMMENTS,
			params = data
		})

		return
	end

	self.reqStatus[tableID] = xyd.getServerTime() + xyd.tables.miscTable:getNumber("comic_update_time", "value")
	self.commentInfo[tableID] = {}
	self.likeCommentList[tableID] = {}
	local msg = messages_pb.get_partner_comments_req()
	msg.table_id = tableID

	xyd.Backend:get():request(xyd.mid.GET_PARTNER_COMMENTS, msg)
end

function PartnerComment:getComments(tableID)
	if self.commentInfo[tableID] then
		return self.commentInfo[tableID]
	else
		return {}
	end
end

function PartnerComment:reqComment(tableID, msg)
	if not self:judgeCommentCD(tableID) then
		return
	end

	local msgs = messages_pb:comment_partner_req()
	msgs.table_id = tableID
	msgs.msg = msg

	xyd.Backend:get():request(xyd.mid.COMMENT_PARTNER, msgs)
end

function PartnerComment:judgeCommentCD(tableID)
	local cd = self:getCommentCD(tableID)

	if self.comment_time[tableID] == nil or xyd.getServerTime() > self.comment_time[tableID] + cd then
		self.comment_time[tableID] = xyd.getServerTime()
		self.comment_cnt[tableID] = self.comment_cnt[tableID] + 1

		return true
	end

	local dif = self.comment_time[tableID] + cd - xyd.getServerTime()

	xyd.showToast(__("PARTNER_COMMENT_IN_CD", dif))

	return false
end

function PartnerComment:getCommentCD(tableID)
	if self.comment_time[tableID] == nil then
		self.comment_time[tableID] = 0
	end

	if self.comment_time[tableID] + xyd.tables.miscTable:getNumber("comic_cancel_cd", "value") < xyd.getServerTime() then
		self.comment_cnt[tableID] = 0
	end

	local cnt = self.comment_cnt[tableID]

	if cnt == 0 then
		return 0
	end

	local cur_time = 1

	for i = 1, cnt - 1 do
		cur_time = cur_time * 2
	end

	return cur_time * xyd.tables.miscTable:getNumber("comic_comment_cd", "value")
end

function PartnerComment:getHotComment(tableID)
	local comments = table.clone(self.commentInfo[tableID])

	if not comments or #comments == 0 then
		return {}
	end

	table.sort(comments, function (a, b)
		if a.like ~= b.like then
			return b.like < a.like
		else
			return b.created_time < a.created_time
		end
	end)

	if #comments == 1 then
		return {
			comments[1]
		}
	else
		return {
			comments[1],
			comments[2]
		}
	end
end

function PartnerComment:getIsLike(tableID)
	if self.likePartner[tableID] then
		return self.likePartner[tableID]
	else
		return 0
	end
end

function PartnerComment:getLikeNum(tableID)
	if self.partnerLikeNum[tableID] then
		return self.partnerLikeNum[tableID]
	else
		return 0
	end
end

function PartnerComment:incrLikeNum(tableID)
	self.partnerLikeNum[tableID] = self:getLikeNum(tableID) + 1
end

function PartnerComment:isLikeComment(tableID, commentID)
	if self.likeCommentList[tableID] and xyd.arrayIndexOf(self.likeCommentList[tableID], commentID) > 0 then
		return 1
	else
		return 0
	end
end

function PartnerComment:reqLikeComment(tableID, commentID)
	local msg = messages_pb:like_partner_comment_req()
	msg.table_id = tableID
	msg.comment_id = commentID

	xyd.Backend:get():request(xyd.mid.LIKE_PARTNER_COMMENT, msg)
end

function PartnerComment:reqLikePartner(tableID)
	local msg = messages_pb:like_partner_req()
	msg.table_id = tableID

	xyd.Backend:get():request(xyd.mid.LIKE_PARTNER, msg)

	self.likePartner[tableID] = 1
end

function PartnerComment:getCommentLikeCount(tableID, commentID)
	for i = 1, #self.commentInfo[tableID] do
		local data = self.commentInfo[tableID][i]

		if data.comment_id == commentID then
			return data.like
		end
	end

	return nil
end

function PartnerComment:getCommentInfo(tableID, commentID)
	for i = 1, #self.commentInfo[tableID] do
		local data = self.commentInfo[tableID][i]

		if data.comment_id == commentID then
			return data
		end
	end

	return nil
end

function PartnerComment:updateCommentInfo(table_id, comment_id, data)
	data = self:decodeProto(data)

	for i = 1, #self.commentInfo[table_id] do
		local res = self.commentInfo[table_id][i]

		if res.comment_id == comment_id then
			self.commentInfo[table_id][i] = data

			break
		end
	end
end

function PartnerComment:getCommentCount(table_id)
	return #self.commentInfo[table_id]
end

function PartnerComment:translateFrontend(msg, callback)
	local content = msg.msg
	local translate = self:checkTranslate(content)

	if translate then
		msg.translate = translate

		return callback(msg, xyd.TranslateType.OK)
	elseif self:isInTranslate(content) then
		table.insert(self.inTranslate_[content], callback)

		return callback(msg, xyd.TranslateType.DOING)
	end

	self.inTranslate_[content] = {}

	table.insert(self.inTranslate_[content], callback)

	local msgID = tostring(xyd.Global.playerID) .. tostring(xyd.getServerTime())
	self.translaID2Content_[msgID] = msg

	xyd.TranslationManager.get():translate(msgID, content, handler(self, self.onTranslate))
end

function PartnerComment:checkTranslate(content)
	return self.translateContent_[content] or nil
end

function PartnerComment:isInTranslate(content)
	return self.inTranslate_[content]
end

function PartnerComment:onTranslate(data)
	local msg = self.translaID2Content_[data.msgID] or {}
	local content = msg.msg

	if content then
		local transl = data.transl
		self.translateContent_[content] = transl
		local callbacks = self:isInTranslate(content) or {}

		for _, callback in pairs(callbacks) do
			if callback then
				msg.translate = transl

				callback(msg, xyd.TranslateType.OK)
			end
		end

		self.inTranslate_[content] = nil
	end
end

function PartnerComment:checkIsBanner()
	if not self.banned_info or not self.banned_info.is_banned or self.banned_info.is_banned ~= 1 then
		return false
	end

	if self.banned_info.is_banned == 1 and xyd.getServerTime() <= self.banned_info.end_time then
		return true
	end

	return false
end

function PartnerComment:getBannerEndTime()
	if self.banned_info and self.banned_info.end_time then
		return self.banned_info.end_time - xyd.getServerTime()
	end

	return 0
end

return PartnerComment
