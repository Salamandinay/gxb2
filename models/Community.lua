local BaseModel = import(".BaseModel")
local Community = class("Community", BaseModel)

function Community:ctor(...)
	Community.super.ctor(self)
end

function Community:onRegister()
	Community.super.onRegister(self)
	self:registerEvent(xyd.event.GET_COMMUNITY_ACT_INFO, handler(self, self.onActInfo))
end

function Community:onActInfo(event)
	self.Community_act_list = event.data

	table.sort(self.Community_act_list, function (a, b)
		return a.order < b.order
	end)
	self:checkRedMark()
end

function Community:getActInfo()
	return self.Community_act_list
end

function Community:checkRedMark()
	if not self:checkLegal() then
		xyd.models.redMark:setMark(xyd.RedMarkType.COMMUNITY_ACTIVITY, false)

		return false
	end

	for i = 1, #self.Community_act_list do
		local data = self.Community_act_list[i]
		local timeStamp = xyd.db.misc:getValue("community_act_time_stamp" .. tostring(data.title) .. tostring(data.start_time) .. tostring(data.end_time) .. tostring(data.id))

		if not timeStamp then
			xyd.models.redMark:setMark(xyd.RedMarkType.COMMUNITY_ACTIVITY, true)

			return true
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.COMMUNITY_ACTIVITY, false)

	return false
end

function Community:checkLegal()
	for i = 1, #self.Community_act_list do
		local data = self.Community_act_list[i]

		if data.banner_url and data.start_time and data.end_time and data.title and data.content and data.url and tostring(data.banner_url) ~= "" and tostring(data.start_time) ~= "" and tostring(data.end_time) ~= "" and tostring(data.title) ~= "" and tostring(data.content) ~= "" and tostring(data.url) ~= "" then
			return true
		end
	end

	return false
end

function Community:checkDataLegal(data)
	if data.banner_url and data.start_time and data.end_time and data.title and data.content and data.url and tostring(data.banner_url) ~= "" and tostring(data.start_time) ~= "" and tostring(data.end_time) ~= "" and tostring(data.title) ~= "" and tostring(data.content) ~= "" and tostring(data.url) ~= "" then
		return true
	end

	return false
end

return Community
