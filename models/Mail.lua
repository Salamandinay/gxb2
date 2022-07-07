local Mail = class("Mail", import(".BaseModel"))
local json = require("cjson")

function Mail:ctor()
	Mail.super.ctor(self)

	self.lastSend_ = {}
	self.unReadMails_ = {}
	self.friendLastSendTime_ = 0
	self.mails_ = {}
	self.mailFriend_ = {}
	self.mailSystem_ = {}
	self.lastPush = "System"
	self.hasNewMail = true
end

function Mail:onRegister()
	Mail.super.onRegister(self)
	self:registerEvent(xyd.event.MAIL_LIST, self.onMailList, self)
	self:registerEvent(xyd.event.GET_MAIL_GIFT, self.onMailReward, self)
	self:registerEvent(xyd.event.READ_MAIL, self.onMailRead, self)
	self:registerEvent(xyd.event.DELETE_MAIL, self.onMailDelete, self)
	self:registerEvent(xyd.event.RED_POINT, self.onRedMarkInfo, self)
end

function Mail:preRequireMailList()
	if self.hasNewMail then
		self:requireMailList()

		return true
	end

	return false
end

function Mail:requireMailList()
	print(debug.traceback())

	local msg = messages_pb.get_mail_list_req()

	xyd.Backend.get():request(xyd.mid.MAIL_LIST, msg)
end

function Mail:requireRewards(mailType)
	local msg = messages_pb.get_mail_gift_req()
	local mails = nil

	if mailType == "sys" then
		mails = self.mailSystem_
	elseif mailType == "fri" then
		mails = self.mailFriend_
	end

	for _, mailId in ipairs(mails) do
		local mail = self.mails_[mailId]

		if not mail then
			-- Nothing
		elseif mail.is_gifted == 0 and #mail.attach > 0 then
			table.insert(msg.mail_ids, mailId)
		end
	end

	if #msg.mail_ids == 0 then
		return false
	end

	xyd.Backend.get():request(xyd.mid.GET_MAIL_GIFT, msg)

	return true
end

function Mail:requireRead(mailType)
	local msg = messages_pb.get_mail_gift_req()
	local mails = nil

	if mailType == "sys" then
		mails = self.mailSystem_
	elseif mailType == "fri" then
		mails = self.mailFriend_
	end

	for _, mailId in ipairs(mails) do
		local mail = self.mails_[mailId]

		if not mail then
			-- Nothing
		else
			local mailTableId = xyd.split(mail.content, "#&|")[1]

			if mail.is_read == 0 and tonumber(mailTableId) ~= xyd.MailContent.IMPORTANT then
				table.insert(msg.mail_ids, mailId)
			end
		end
	end

	if #msg.mail_ids == 0 then
		return false
	end

	xyd.Backend.get():request(xyd.mid.READ_MAIL, msg)

	return true
end

function Mail:claimRequest(mail_id)
	local msg = messages_pb.get_mail_gift_req()

	table.insert(msg.mail_ids, mail_id)
	xyd.Backend.get():request(xyd.mid.GET_MAIL_GIFT, msg)
end

function Mail:reqReadMail(data)
	local mailList = data.mail_ids
	local msg = messages_pb.read_mail_req()

	for _, id in ipairs(mailList) do
		table.insert(msg.mail_ids, id)
	end

	xyd.Backend.get():request(xyd.mid.READ_MAIL, msg)
end

function Mail:requireDelete(mail_ids)
	xyd.SoundManager.get():playSound(2120)

	if not mail_ids or #mail_ids == 0 then
		return
	end

	local msg = messages_pb.delete_mail_req()

	for _, id in ipairs(mail_ids) do
		table.insert(msg.mail_ids, id)
	end

	xyd.Backend.get():request(xyd.mid.DELETE_MAIL, msg)
end

function Mail:onMailList(event)
	self.hasNewMail = false
	local mails = xyd.decodeProtoBuf(event.data).mails or {}
	local unReadFriend = 0
	local unReadSystem = 0
	local unReadGM = 0
	self.mails_ = {}
	self.mailGM_ = {}
	self.mailSystem_ = {}
	self.mailFriend_ = {}
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.YEARS_SUMMARY)

	if activityData and activityData:isOpen() then
		local isReadData = xyd.db.misc:getValue("years_summary_mail_read2")
		local is_read = 0

		if isReadData and tonumber(isReadData) == 1 then
			is_read = 1
		end

		local params = {
			mail_id = 99999,
			is_gifted = 0,
			content = "",
			mail_type = xyd.MailType.SYSTEM,
			is_read = is_read,
			created_time = activityData:startTime(),
			attach = {}
		}

		table.insert(mails, params)
	end

	for _, mail in pairs(mails) do
		local mail_id = mail.mail_id
		self.mails_[mail_id] = mail

		if mail.mail_type == xyd.MailType.FRIEND then
			table.insert(self.mailFriend_, mail_id)

			unReadFriend = unReadFriend + 1 - mail.is_read
		elseif mail.mail_type == xyd.MailType.SYSTEM then
			table.insert(self.mailSystem_, mail_id)

			unReadSystem = unReadSystem + 1 - mail.is_read
		else
			table.insert(self.mailGM_, mail_id)

			unReadGM = unReadGM + 1 - mail.is_read

			if mail.mail_type == xyd.MailType.WEDDING and xyd.db.misc:getValue("mail_wedding_" .. mail.mail_id) then
				self.mails_[mail_id].localWeddingData = 1
			end
		end
	end

	self:sortMail()
	xyd.models.redMark:setMark(xyd.RedMarkType.MAIL_GM, unReadGM > 0)
	xyd.models.redMark:setMark(xyd.RedMarkType.MAIL_FRIEND, unReadFriend > 0)
	xyd.models.redMark:setMark(xyd.RedMarkType.MAIL_SYSTEM, unReadSystem > 0)
	xyd.models.redMark:setMark(xyd.RedMarkType.MAIL, unReadFriend + unReadSystem + unReadGM > 0)
end

function Mail:onMailReward(event)
	local datas = event.data.mail_ids

	for _, id in ipairs(datas) do
		if self.mails_[id] then
			self.mails_[id].is_gifted = 1
			self.mails_[id].is_read = 1
		end
	end

	self:sortMail()
	self:setRedMark()
end

function Mail:onMailRead(event)
	local datas = event.data.mail_ids

	for _, id in ipairs(datas) do
		self.mails_[id].is_read = 1
	end

	self:sortMail()
	self:setRedMark()
end

function Mail:onWeddingReview(id)
	self.mails_[id].is_read = 1

	self:sortMail()
	self:setRedMark()

	local mailWindow = xyd.WindowManager.get():getWindow("mail_window")

	if mailWindow then
		mailWindow:setMailList(true)
	end
end

function Mail:onMailDelete(event)
	local data = event.data.mail_ids

	for _, id in ipairs(data) do
		local index = self.findNumInTable(self.mailSystem_, id)
		local index1 = self.findNumInTable(self.mailFriend_, id)
		local index2 = self.findNumInTable(self.mailGM_, id)

		if index > 0 then
			table.remove(self.mailSystem_, index)
		elseif index1 > 0 then
			table.remove(self.mailFriend_, index1)
		else
			table.remove(self.mailGM_, index2)
		end

		self.mails_[id] = nil
	end
end

function Mail:friendSendMail(params)
	self.friendLastSendTime_ = xyd.getServerTime()
	local msg = messages_pb.send_chat_mails_req()
	msg.title = params.title
	msg.content = params.content

	for _, id in pairs(params.to_player_ids) do
		table.insert(msg.to_player_ids, id)
	end

	xyd.Backend.get():request(xyd.mid.SEND_CHAT_MAILS, msg)
end

function Mail.findNumInTable(table, num)
	for idx, number in pairs(table) do
		if number == num then
			return idx
		end
	end

	return -1
end

function Mail:timeRemain()
	local maxTime = tonumber(xyd.tables.miscTable:getVal("mail_cd"))
	local remain_time = maxTime - (xyd.getServerTime() - self.friendLastSendTime_)

	return remain_time
end

function Mail:divideTitle(str)
	local ans = str

	for i = 1, #ans do
		if str[i] == "(" then
			ans = string.sub(str, 1, i)
		end
	end

	return ans
end

function Mail:guildSendMail(title, content)
	local ids = {}

	if not xyd.models.guild.guildID then
		return
	end

	for i = 1, #xyd.models.guild.members do
		local data = xyd.models.guild.members[i]

		table.insert(ids, data.player_id)
	end

	if #ids <= 0 then
		return
	end

	local msg = messages_pb.send_chat_mails_req()
	msg.title = title
	msg.content = content

	for _, id in ipairs(ids) do
		table.insert(msg.to_player_ids, id)
	end

	xyd.Backend.get():request(xyd.mid.SEND_CHAT_MAILS, msg)
end

function Mail:sortMail()
	table.sort(self.mailFriend_, function (i, j)
		local a = self.mails_[i]
		local b = self.mails_[j]
		local scoreA = a.is_read * 100
		local scoreB = b.is_read * 100

		if b.created_time < a.created_time then
			scoreA = scoreA + 0
			scoreB = scoreB + 1
		elseif a.created_time <= b.created_time then
			scoreA = scoreA + 1
			scoreB = scoreB + 0
		end

		if #a.attach > 0 then
			scoreA = scoreA + a.is_gifted * 10
		else
			scoreA = scoreA + a.is_read * 10
		end

		if #b.attach > 0 then
			scoreB = scoreB + b.is_gifted * 10
		else
			scoreB = scoreB + b.is_read * 10
		end

		return scoreA < scoreB
	end)
	table.sort(self.mailSystem_, function (i, j)
		local a = self.mails_[i]
		local b = self.mails_[j]
		local scoreA = a.is_read * 100
		local scoreB = b.is_read * 100

		if b.created_time < a.created_time then
			scoreA = scoreA + 0
			scoreB = scoreB + 1
		elseif a.created_time <= b.created_time then
			scoreA = scoreA + 1
			scoreB = scoreB + 0
		end

		if #a.attach > 0 then
			scoreA = scoreA + a.is_gifted * 10
		else
			scoreA = scoreA + a.is_read * 10
		end

		if #b.attach > 0 then
			scoreB = scoreB + b.is_gifted * 10
		else
			scoreB = scoreB + b.is_read * 10
		end

		local mailTableIdA = xyd.split(a.content, "#&|")[1]
		local mailTableIdB = xyd.split(b.content, "#&|")[1]

		if tonumber(mailTableIdA) == xyd.MailContent.IMPORTANT then
			scoreA = scoreA - 500
		end

		if tonumber(mailTableIdB) == xyd.MailContent.IMPORTANT then
			scoreB = scoreB - 500
		end

		if a.mail_id == 99999 then
			return true
		elseif b.mail_id == 99999 then
			return false
		else
			return scoreA < scoreB
		end
	end)
	table.sort(self.mailGM_, function (i, j)
		local a = self.mails_[i]
		local b = self.mails_[j]
		local scoreA = a.is_read * 100
		local scoreB = b.is_read * 100

		if b.created_time < a.created_time then
			scoreA = scoreA + 0
			scoreB = scoreB + 1
		elseif a.created_time <= b.created_time then
			scoreA = scoreA + 1
			scoreB = scoreB + 0
		end

		if #a.attach > 0 then
			scoreA = scoreA + a.is_gifted * 10
		else
			scoreA = scoreA + a.is_read * 10
		end

		if #b.attach > 0 then
			scoreB = scoreB + b.is_gifted * 10
		else
			scoreB = scoreB + b.is_read * 10
		end

		if a.mail_type == xyd.MailType.WEDDING and a.localWeddingData then
			scoreA = scoreA + 10
		end

		if b.mail_type == xyd.MailType.WEDDING and b.localWeddingData then
			scoreB = scoreB + 10
		end

		return scoreA < scoreB
	end)
end

function Mail:setWeddingLocalData(mail_id)
	if self.mails_[mail_id] then
		self.mails_[mail_id].localWeddingData = 1

		xyd.db.misc:setValue({
			value = 1,
			key = "mail_wedding_" .. mail_id
		})
	end
end

function Mail:setRedMark()
	local unReadFriend = 0
	local unReadSystem = 0
	local unReadGM = 0

	for _, mail in pairs(self.mails_) do
		local mail_id = mail.mail_id

		if mail.mail_type == xyd.MailType.FRIEND then
			unReadFriend = unReadFriend + 1 - mail.is_read
		elseif mail.mail_type == xyd.MailType.SYSTEM then
			unReadSystem = unReadSystem + 1 - mail.is_read
		else
			unReadGM = unReadGM + 1 - mail.is_read
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.MAIL_FRIEND, unReadFriend > 0)
	xyd.models.redMark:setMark(xyd.RedMarkType.MAIL_SYSTEM, unReadSystem > 0)
	xyd.models.redMark:setMark(xyd.RedMarkType.MAIL_GM, unReadGM > 0)
	xyd.models.redMark:setMark(xyd.RedMarkType.MAIL, unReadFriend + unReadSystem + unReadGM > 0)
end

function Mail:onRedMarkInfo(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	local funID = event.data.function_id

	if funID == xyd.FunctionID.MAIL then
		self.hasNewMail = true

		xyd.models.redMark:setMark(xyd.RedMarkType.MAIL, true)
	end
end

function Mail:getMails()
	return self.mails_
end

function Mail:getMailFriend()
	return self.mailFriend_
end

function Mail:getmailSystem()
	self.mailSystem_ = self:checkMailListTime(xyd.MailType.SYSTEM)

	return self.mailSystem_
end

function Mail:getmailGM()
	self.mailGM_ = self:checkMailListTime(xyd.MailType.GM)

	return self.mailGM_
end

function Mail:setlastPush(str)
	self.lastPush = str
end

function Mail:getlastPush()
	return self.lastPush
end

function Mail:checkMailListTime(type_)
	local checkList = {}
	local list = {}

	if type_ == xyd.MailType.SYSTEM then
		checkList = self.mailSystem_
	elseif self:checkGmType(type_) then
		checkList = self.mailGM_
	end

	for _, id in pairs(checkList) do
		local mail = self.mails_[id]

		table.insert(list, id)
	end

	return list
end

function Mail:trackAction(event)
	local str = json.encode({
		event
	})

	xyd.SdkManager.get():logEvent(str)
end

function Mail:checkGmType(type)
	if type == xyd.MailType.GM or type == xyd.MailType.WEDDING or type == xyd.MailType.NOH5 then
		return true
	end

	return false
end

return Mail
