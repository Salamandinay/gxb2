local ActivityResidentReturnMainWindow = class("ActivityResidentReturnMainWindow", import(".BaseWindow"))

function ActivityResidentReturnMainWindow:ctor(name, params)
	ActivityResidentReturnMainWindow.super.ctor(self, name, params)
end

function ActivityResidentReturnMainWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
	self:checkRed()
end

function ActivityResidentReturnMainWindow:checkRed()
	local localMainRedTime = xyd.db.misc:getValue("activity_resident_return_to_main_red_time")

	if not localMainRedTime or localMainRedTime and not xyd.isSameDay(tonumber(localMainRedTime), xyd.getServerTime()) then
		xyd.db.misc:setValue({
			key = "activity_resident_return_to_main_red_time",
			value = xyd.getServerTime()
		})
	end

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_RESIDENT_RETURN)

	if activityData then
		activityData:setRedMarkState()
	end
end

function ActivityResidentReturnMainWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.logoImg = self.groupAction:ComponentByName("logoImg", typeof(UISprite))
	self.centerCon = self.groupAction:NodeByName("centerCon").gameObject

	for i = 1, 5 do
		self["clickCon" .. i] = self.centerCon:ComponentByName("clickCon" .. i, typeof(UISprite))
		self["nameText" .. i] = self["clickCon" .. i]:ComponentByName("nameText" .. i, typeof(UILabel))
		self["dateText" .. i] = self["clickCon" .. i]:ComponentByName("dateText" .. i, typeof(UILabel))
		self["numText" .. i] = self["clickCon" .. i]:ComponentByName("numText" .. i, typeof(UILabel))
		self["redImg" .. i] = self["clickCon" .. i]:ComponentByName("redImg" .. i, typeof(UISprite))

		xyd.models.redMark:setMarkImg(xyd.RedMarkType["ACTIVITY_RESIDENT_RETURN_RED_" .. i], self["redImg" .. i].gameObject)
	end
end

function ActivityResidentReturnMainWindow:layout()
	xyd.setUISpriteAsync(self.logoImg, nil, "resident_return_main_logo_" .. xyd.Global.lang, nil, )

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_RESIDENT_RETURN)
	local startTime = activityData:getReturnStartTime()
	local timeDesc = os.date("*t", startTime)
	local start_month = tostring(timeDesc.month)
	local start_day = tostring(timeDesc.day)

	for i = 1, 5 do
		self["nameText" .. i].text = __("ACTIVITY_RETURN_RESIDENT_MAIN_TEXT0" .. i)

		if xyd.models.activity:isResidentReturnTimeIn() then
			local endTime = startTime + xyd.tables.miscTable:getNumber("activity_return2_time" .. i, "value")
			local timeDesc_end = os.date("*t", endTime)
			local end_month = tostring(timeDesc_end.month)
			local end_day = tostring(timeDesc_end.day)

			if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
				if #start_day == 1 then
					start_day = "0" .. start_day
				end

				if #start_month == 1 then
					start_month = "0" .. start_month
				end

				if #end_day == 1 then
					end_day = "0" .. end_day
				end

				if #end_month == 1 then
					end_month = "0" .. end_month
				end
			end

			if xyd.Global.lang == "fr_fr" then
				self["dateText" .. i].text = start_day .. "/" .. start_month .. "-" .. end_day .. "/" .. end_month
			elseif xyd.Global.lang == "de_de" then
				self["dateText" .. i].text = start_day .. "." .. start_month .. ".-" .. end_day .. "." .. end_month .. "."
			else
				self["dateText" .. i].text = start_month .. "." .. start_day .. "-" .. end_month .. "." .. end_day
			end
		else
			self["dateText" .. i].gameObject:SetActive(false)
		end
	end
end

function ActivityResidentReturnMainWindow:registerEvent()
	for i = 1, 5 do
		UIEventListener.Get(self["clickCon" .. i].gameObject).onClick = handler(self, function ()
			local returnData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_RESIDENT_RETURN)

			if returnData then
				returnData:setRedMarkState()
			end

			if not returnData or returnData:getReturnStartTime() == -1 or returnData:getReturnEndTime() == -1 or returnData:getReturnStartTime() > xyd.getServerTime() or xyd.getServerTime() >= returnData:getReturnStartTime() + xyd.tables.miscTable:getNumber("activity_return2_time" .. i, "value") then
				xyd.alertTips(__("ACTIVITY_END_YET"))

				return
			end

			xyd.MainMap.get():stopSound()

			if i == 1 then
				print("點擊了收益加倍")
				xyd.WindowManager.get():openWindow("activity_resident_return_grow_window")
				self:close()
			end

			if i == 2 then
				print("點擊了回歸助力")
				xyd.WindowManager.get():openWindow("activity_resident_return_support_window")
				self:close()
			end

			if i == 3 then
				print("點擊了特權折扣")
				xyd.WindowManager.get():openWindow("activity_return_discount_window")
				self:close()
			end

			if i == 4 then
				print("點擊了成長禮包")
				xyd.WindowManager.get():openWindow("activity_return_gift_optional_window")
				self:close()
			end

			if i == 5 then
				print("點擊了社交推薦")
				xyd.WindowManager.get():openWindow("activity_return_community_window")
				self:close()

				local localCommunityTime = xyd.db.misc:getValue("activity_resident_return_community_red_time")

				if not localCommunityTime or localCommunityTime and not xyd.isSameDay(tonumber(localCommunityTime), xyd.getServerTime()) then
					xyd.db.misc:setValue({
						key = "activity_resident_return_community_red_time",
						value = xyd.getServerTime()
					})
				end

				if returnData then
					returnData:setRedMarkState(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_5)
				end
			end

			local localTime = xyd.db.misc:getValue("resident_return_dadian_" .. i)

			if not localTime or not xyd.isSameDay(tonumber(localTime), xyd.getServerTime()) then
				local msg = messages_pb.record_activity_req()
				msg.activity_id = tonumber(xyd.ActivityID.ACTIVITY_RESIDENT_RETURN) * 100 + i

				xyd.Backend.get():request(xyd.mid.RECORD_ACTIVITY, msg)
				xyd.db.misc:setValue({
					key = "resident_return_dadian_" .. i,
					value = xyd.getServerTime()
				})
			end
		end)
	end
end

return ActivityResidentReturnMainWindow
