local BaseWindow = import(".BaseWindow")
local GalaxyStartWindow = class("GalaxyStartWindow", BaseWindow)

function GalaxyStartWindow:ctor(name, params)
	GalaxyStartWindow.super.ctor(self, name, params)
end

function GalaxyStartWindow:getUIComponent()
	local trans = self.window_.transform
	local groupMain = trans:NodeByName("groupAction").gameObject
	self.labelTitle = groupMain:ComponentByName("labelTitle_", typeof(UILabel))
	self.content_ = groupMain:NodeByName("content_").gameObject
	self.closeBtn = groupMain:NodeByName("closeBtn").gameObject
	self.group1 = self.content_:NodeByName("group1").gameObject
	self.groupDes1 = self.group1:NodeByName("groupDes1").gameObject
	self.labelDes1 = self.groupDes1:ComponentByName("labelDes1", typeof(UILabel))
	self.labelTitle1 = self.groupDes1:ComponentByName("labelTitle1", typeof(UILabel))
	self.redPoint1 = self.group1:ComponentByName("redPoint", typeof(UISprite))
	self.group2 = self.content_:NodeByName("group2").gameObject
	self.groupDes2 = self.group2:NodeByName("groupDes2").gameObject
	self.labelDes2 = self.groupDes2:ComponentByName("labelDes2", typeof(UILabel))
	self.labelTitle2 = self.groupDes2:ComponentByName("labelTitle2", typeof(UILabel))
	self.redPoint2 = self.group2:ComponentByName("redPoint", typeof(UISprite))
	self.timeGroup = self.group2:NodeByName("timeGroup").gameObject
	self.timeGroupLayout = self.group2:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = self.timeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.labelWillFinish = self.group2:ComponentByName("labelWillFinish", typeof(UILabel))
	local isShow = false

	self.redPoint1:SetActive(isShow)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.GALAXY_TRIP,
		xyd.RedMarkType.GALAXY_TRIP_MAP_CAN_GET_POINT
	}, self.redPoint2)
end

function GalaxyStartWindow:initWindow()
	GalaxyStartWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function GalaxyStartWindow:layout()
	self.labelDes1.text = __("GALAXY_TRIP_TEXT02")
	self.labelTitle1.text = __("GALAXY_TRIP_TEXT73")
	self.labelDes2.text = __("GALAXY_TRIP_TEXT03")
	self.labelTitle2.text = __("GALAXY_TRIP_TEXT04")
	self.labelTitle.text = __("GALAXY_TRIP_TEXT72")
	self.countdown = import("app.components.CountDown").new(self.timeLabel_)
	local leftTime = xyd.models.galaxyTrip:getLeftTime()
	local startTime = xyd.models.galaxyTrip:getStartTime()

	if startTime < xyd.getServerTime() and xyd.getServerTime() < startTime + 600 then
		self.countdown:setInfo({
			duration = startTime + 600 - xyd.getServerTime(),
			callback = function ()
				self.countdown:setInfo({
					duration = xyd.models.galaxyTrip:getLeftTime(),
					callback = function ()
					end
				})
			end
		})
	else
		self.countdown:setInfo({
			duration = leftTime,
			callback = function ()
			end
		})
	end

	if leftTime <= 2 * xyd.DAY_TIME and xyd.DAY_TIME < leftTime and leftTime > 0 then
		self.labelWillFinish.text = __("SCHOOL_PRACTICE_FINISH")

		self.labelWillFinish:SetActive(true)

		local action = self:getSequence()
		local transform = self.labelWillFinish.gameObject.transform
		local position = transform.localPosition
		local x = position.x
		local y = position.y

		action:Append(transform:DOScale(Vector3(1.2, 1.2, 1.2), 0.5))
		action:Append(transform:DOScale(Vector3(1, 1, 1), 0.5))
		action:Append(transform:DOScale(Vector3(1.2, 1.2, 1.2), 0.5))
		action:Append(transform:DOScale(Vector3(1, 1, 1), 0.5))
		action:SetLoops(-1)
	end

	if xyd.Global.lang == "fr_fr" then
		self.endLabel_.transform:SetSiblingIndex(0)

		self.labelDes1.fontSize = 16
		self.labelDes2.fontSize = 16
	end

	if xyd.Global.lang == "de_de" then
		self.labelTitle1.fontSize = 28
		self.labelTitle2.fontSize = 28
	end

	self.timeGroupLayout:Reposition()

	local mainInfo = xyd.models.galaxyTrip:getMainInfo()

	if not mainInfo then
		xyd.models.galaxyTrip:sendGalaxyTripGetMainBack()
	end
end

function GalaxyStartWindow:registerEvent()
	GalaxyStartWindow.super.register(self)

	local winNames = {
		"starry_altar_window",
		"galaxy_trip_main_window"
	}
	local funIDs = {
		xyd.FunctionID.STARRY_ALTAR,
		xyd.FunctionID.GALAXY_TRIP
	}

	self.eventProxy_:addEventListener(xyd.event.GALAXY_TRIP_GET_MAIN_INFO, function ()
		local leftTime = xyd.models.galaxyTrip:getLeftTime()

		if leftTime <= 2 * xyd.DAY_TIME and leftTime > 0 then
			self.labelWillFinish.text = __("SCHOOL_PRACTICE_FINISH")

			self.labelWillFinish:SetActive(true)

			local action = self:getSequence()
			local transform = self.labelWillFinish.gameObject.transform
			local position = transform.localPosition
			local x = position.x
			local y = position.y

			action:Append(transform:DOScale(Vector3(1.2, 1.2, 1.2), 0.5))
			action:Append(transform:DOScale(Vector3(1, 1, 1), 0.5))
			action:Append(transform:DOScale(Vector3(1.2, 1.2, 1.2), 0.5))
			action:Append(transform:DOScale(Vector3(1, 1, 1), 0.5))
			action:SetLoops(-1)
		else
			self.labelWillFinish:SetActive(false)
		end

		self.countdown:setCountDownTime(leftTime)
		self.timeGroupLayout:Reposition()
	end)

	for i = 1, 2 do
		UIEventListener.Get(self["group" .. tostring(i)]).onClick = function ()
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

			local winName = winNames[i]

			if winName == "galaxy_trip_main_window" then
				local startTime = xyd.models.galaxyTrip:getGalaxyTripGetMainStartTime()

				if xyd.getServerTime() - startTime < 600 or xyd.models.galaxyTrip:getLeftTime() <= 0 then
					xyd.alertTips(__("GALAXY_TRIP_TIPS_15"))

					return
				end
			end

			xyd.WindowManager:get():openWindow(winName, {}, function ()
				xyd.WindowManager.get():closeWindow(self.name_, nil, , true)
			end)
		end
	end
end

return GalaxyStartWindow
