local ActivityData = import("app.models.ActivityData")
local ActivityYearsSummary = class("ActivityYearsSummary", ActivityData, true)

function ActivityYearsSummary:setData(params)
	ActivityYearsSummary.super.setData(self, params)
end

function ActivityYearsSummary:checkReadState()
	local isReadData = xyd.db.misc:getValue("years_summary_mail_read")

	if not isReadData or tonumber(isReadData) ~= 1 then
		xyd.models.redMark:setMark(xyd.RedMarkType.MAIL, true)
	end
end

return ActivityYearsSummary
