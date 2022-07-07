local ActivityData = import("app.models.ActivityData")
local json = require("cjson")
local Activity4BirthdayMusicData = class("Activity4BirthdayMusicData", ActivityData, true)

function Activity4BirthdayMusicData:ctor(params)
	self.checkItemId = xyd.tables.miscTable:split2num("activity_4birthday_gamble_cost", "value", "#")[1]
	self.checkItemNeedNum = xyd.tables.miscTable:split2num("activity_4birthday_gamble_cost", "value", "#")[2]
	self.checkBackpackItemNum = xyd.models.backpack:getItemNumByID(self.checkItemId)

	ActivityData.ctor(self, params)
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChangeBack))
end

function Activity4BirthdayMusicData:onItemChangeBack(event)
	for i = 1, #event.data.items do
		local itemId = event.data.items[i].item_id

		if itemId == self.checkItemId then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_4BIRTHDAY_MUSIC, function ()
				self.checkBackpackItemNum = xyd.models.backpack:getItemNumByID(self.checkItemId)
			end)

			break
		end
	end
end

function Activity4BirthdayMusicData:getUpdateTime()
	return self:getEndTime()
end

function Activity4BirthdayMusicData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_4BIRTHDAY_MUSIC, false)

		return false
	end

	local clickShowViewBtnTime = xyd.db.misc:getValue("activity_4birthday_music_click_showview_btn_time")

	if not clickShowViewBtnTime then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_4BIRTHDAY_MUSIC, true)

		return true
	else
		clickShowViewBtnTime = tonumber(clickShowViewBtnTime)

		if clickShowViewBtnTime < self:startTime() or self:getEndTime() < clickShowViewBtnTime then
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_4BIRTHDAY_MUSIC, true)

			return true
		end
	end

	if self.checkItemNeedNum <= self.checkBackpackItemNum then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_4BIRTHDAY_MUSIC, true)

		return true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_4BIRTHDAY_MUSIC, false)

	return false
end

function Activity4BirthdayMusicData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_4BIRTHDAY_MUSIC then
		return
	end

	local data = xyd.decodeProtoBuf(data)
	local info = json.decode(data.detail)

	dump(info, "data_back_305=----------------")

	local type = info.type

	if type == xyd.Activity4BirthdayMusicReqType.CHOICE then
		self.detail.awards = info.awards

		self:updateInfoWithData()
	elseif type == xyd.Activity4BirthdayMusicReqType.GET_AWARD then
		local function setSearchInfoGetFun(index)
			local countIndex = 0

			for i, infos in pairs(self.dataGetChoiceYesAwards.choiceIds) do
				for j in pairs(infos) do
					countIndex = countIndex + 1

					if countIndex == index then
						infos[j].isGet = 1

						return
					end
				end
			end
		end

		for i, index in pairs(info.indexs) do
			setSearchInfoGetFun(index)
		end

		local allGetNum = 0

		for i, infos in pairs(self.dataGetChoiceYesAwards.choiceIds) do
			for j in pairs(infos) do
				if infos[j].isGet == 1 then
					allGetNum = allGetNum + 1
				end
			end
		end

		if allGetNum == 10 then
			self.detail.awards = {}

			self:updateEmptyData()
			xyd.db.misc:setValue({
				key = "activity_4birthday_get_choice_award",
				value = json.encode(self.dataGetChoiceYesAwards)
			})
		end
	end
end

function Activity4BirthdayMusicData:getChoiceAwards()
	if not self.dataGetChoiceYesAwards then
		self:updateEmptyData()

		if self.detail.awards and #self.detail.awards ~= 0 then
			self:updateInfoWithData()
		end
	end

	if self.detail.awards and #self.detail.awards ~= 0 then
		return self.dataGetChoiceYesAwards.choiceIds
	end

	local dataGetChoiceYesAwards = xyd.db.misc:getValue("activity_4birthday_get_choice_award")

	if dataGetChoiceYesAwards then
		dataGetChoiceYesAwards = json.decode(dataGetChoiceYesAwards)

		if not dataGetChoiceYesAwards.saveTime then
			dataGetChoiceYesAwards = nil
		else
			local saveTime = tonumber(dataGetChoiceYesAwards.saveTime)

			if saveTime < self:startTime() or self:getEndTime() < saveTime then
				dataGetChoiceYesAwards = nil
			end
		end

		if dataGetChoiceYesAwards and (not dataGetChoiceYesAwards.choiceIds or #dataGetChoiceYesAwards.choiceIds == 0) then
			dataGetChoiceYesAwards = nil
		end
	end

	if dataGetChoiceYesAwards then
		self.dataGetChoiceYesAwards = dataGetChoiceYesAwards

		for i, infos in pairs(self.dataGetChoiceYesAwards.choiceIds) do
			for j in pairs(infos) do
				infos[j].isGet = nil
			end
		end
	end

	return self.dataGetChoiceYesAwards.choiceIds
end

function Activity4BirthdayMusicData:updateEmptyData()
	self.dataGetChoiceYesAwards = {
		choiceIds = {}
	}
	local awardLevelArr = xyd.tables.miscTable:split2num("activity_4birthday_gamble_type_num", "value", "|")

	for i, num in pairs(awardLevelArr) do
		if not self.dataGetChoiceYesAwards.choiceIds[i] then
			self.dataGetChoiceYesAwards.choiceIds[i] = {}
		end

		for j = 1, num do
			table.insert(self.dataGetChoiceYesAwards.choiceIds[i], {
				index = 0,
				sort = 0
			})
		end
	end
end

function Activity4BirthdayMusicData:updateInfoWithData()
	if self.detail.awards and #self.detail.awards ~= 0 then
		local awardLevelArr = xyd.tables.miscTable:split2num("activity_4birthday_gamble_type_num", "value", "|")

		for i, info in pairs(self.detail.awards) do
			local infoArr = xyd.splitToNumber(info, "#")
			local order = xyd.tables.activity4birthdayGambleTable:getType(infoArr[1])
			local sort = xyd.tables.activity4birthdayGambleTable:getSort(infoArr[1])
			local setIndex = i

			if order == 2 then
				setIndex = setIndex - awardLevelArr[1]
			elseif order == 3 then
				setIndex = setIndex - awardLevelArr[1] - awardLevelArr[2]
			end

			self.dataGetChoiceYesAwards.choiceIds[order][setIndex].sort = sort
			self.dataGetChoiceYesAwards.choiceIds[order][setIndex].index = infoArr[2]

			if infoArr[3] and infoArr[3] == 1 then
				self.dataGetChoiceYesAwards.choiceIds[order][setIndex].isGet = infoArr[3]
			end
		end
	end
end

function Activity4BirthdayMusicData:saveChoiceAwards(infos)
	dump(infos, "test")

	self.dataGetChoiceYesAwards.choiceIds = infos
	self.dataGetChoiceYesAwards.saveTime = xyd.getServerTime()

	xyd.db.misc:setValue({
		key = "activity_4birthday_get_choice_award",
		value = json.encode(self.dataGetChoiceYesAwards)
	})
	self:sendChoiceAwardsReq()
end

function Activity4BirthdayMusicData:sendChoiceAwardsReq()
	local num = 10

	for i, info in pairs(self.dataGetChoiceYesAwards.choiceIds) do
		for j, littleInfo in pairs(info) do
			if littleInfo.sort == 0 or littleInfo.index == 0 then
				num = 0
			end
		end
	end

	local ids = {}
	local indexs = {}

	if num >= 10 then
		for i, info in pairs(self.dataGetChoiceYesAwards.choiceIds) do
			for j, littleInfo in pairs(info) do
				local id = xyd.tables.activity4birthdayGambleTable:getIdWithIndex(i, littleInfo.sort)

				table.insert(ids, id)
				table.insert(indexs, littleInfo.index)
			end
		end

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_4BIRTHDAY_MUSIC, json.encode({
			type = xyd.Activity4BirthdayMusicReqType.CHOICE,
			ids = ids,
			indexs = indexs
		}))
	end
end

function Activity4BirthdayMusicData:getIsLocalRoundStart()
	if self.detail.awards and #self.detail.awards > 0 then
		return true
	end

	return false
end

return Activity4BirthdayMusicData
