local BaseModel = import(".BaseModel")
local DeviceNotify = class("DeviceNotify", BaseModel)
local cjson = require("cjson")
local PlayerPrefs = UnityEngine.PlayerPrefs
local redMarkData = nil
local NotifyNode = class("NotifyNode")

function NotifyNode:ctor()
	self.id_ = 0
	self.message_ = ""
	self.title_ = ""
	self.time_ = 0
	self.deepLinkID_ = 0
end

function NotifyNode:setValues(id, title, message, time, deepLinkID, frontendParams, imgUrl)
	self.id_ = id
	self.message_ = message or ""
	self.time_ = time
	self.title_ = title or ""
	self.subText_ = ""
	self.deepLinkID_ = deepLinkID or 0
	self.frontendParams_ = frontendParams or {}
	self.frontendParams_.ID = self.deepLinkID_
	self.imgUrl_ = imgUrl
end

function NotifyNode:setMessage(message)
	self.message_ = message or ""
end

function NotifyNode:getFrontendParamsStr()
	return cjson.encode(self.frontendParams_)
end

function NotifyNode:getDeepLinkID()
	return self.deepLinkID_
end

function NotifyNode:getTime()
	return self.time_
end

function NotifyNode:setTime(value)
	self.time_ = value
end

function NotifyNode:toString()
	return string.format("%d:%d", self.deepLinkID_, self.time_)
end

function NotifyNode:isTimeInTheWeeHours()
	local tmp = os.date("*t", self.time_)

	return tmp.hour <= 8
end

function NotifyNode:changeTimeIfNeed()
	local tmp = os.date("*t", self.time_)

	if tmp.hour <= 8 then
		tmp.hour = tmp.hour + 8
	end

	self.time_ = os.time(tmp)
end

function DeviceNotify:ctor()
	DeviceNotify.super.ctor(self)

	self.notifyTime = {}
	self.includeList = {}
	self.openNotifyList = {}
	self.notifyNodes_ = {}
end

function DeviceNotify:init()
	dump("===============DeviceNotify === init")

	if self.isInit_ then
		return
	end

	self.isInit_ = true
	self.notifyInterface_ = XYDNotification.Instance
	self.notifyInterface_.onAppPause = handler(self, self.onAppPause)

	dump("===============DeviceNotify === init  success")
end

function DeviceNotify:onRegister()
	DeviceNotify.super.onRegister(self)
	self:registerEvent(xyd.event.DEVICE_NOTIFY_INFO, self.onDeviceNotifyInfo, self)
	self:registerEvent(xyd.event.CLOSE_MESSAGE_PUSH, self.onDeviceNotifyInfo, self)
	self:registerEvent(xyd.event.OPEN_MESSAGE_PUSH, self.onDeviceNotifyInfo, self)
end

function DeviceNotify:onDeviceNotifyInfo(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	local data = event.data.pushes
	local totalIds = xyd.tables.deviceNotifyCategoryTable:getIDs()
	self.includeList = {}

	for i = 1, #totalIds do
		local id = totalIds[i]
		local index = xyd.arrayIndexOf(data, id)
		self.openNotifyList[id] = xyd.checkCondition(index >= 0, true, false)

		if self.openNotifyList[id] then
			local include = xyd.tables.deviceNotifyCategoryTable:getInclude(id)

			for j = 1, #include do
				table.insert(self.includeList, include[j])
			end
		end
	end

	self:refreshNotify()
end

function DeviceNotify:switchDeviceNotify(id, isOpen)
	self.openNotifyList[id] = isOpen

	if not isOpen then
		local msg = messages_pb.close_message_push_req()
		msg.message_type = id

		xyd.Backend.get():request(xyd.mid.CLOSE_MESSAGE_PUSH, msg)
	else
		local msg = messages_pb.open_message_push_req()
		msg.message_type = id

		xyd.Backend.get():request(xyd.mid.OPEN_MESSAGE_PUSH, msg)
	end
end

function DeviceNotify:refreshNotify()
	if not xyd.Global.isLoadingFinish then
		return
	end

	LocalNotification.CancelAllNotifications()
	xyd.SdkManager:get():clearAllNotify()

	for id, _ in pairs(self.notifyTime) do
		local index = xyd.arrayIndexOf(self.includeList, id)

		if index > 0 then
			self:setFrontedPush(tonumber(id))
		end
	end
end

function DeviceNotify:setNotifyTime(id, time)
	self.notifyTime[id] = time

	dump(self.includeList)
	dump(self.notifyTime)
	self:refreshNotify()
end

function DeviceNotify:setFrontedPush(id)
	local open_id = xyd.tables.deviceNotifyCategoryTable:getOpenID(id)

	if not self:isOpen(open_id) then
		return
	end

	local time = self.notifyTime[id] - xyd:getServerTime()

	if time <= 0 then
		if self.notifyNodes_[id] then
			self.notifyNodes_[id]:setTime(0)
		end

		return
	end

	if not self:checkNotifyState(id) then
		if self.notifyNodes_[id] then
			self.notifyNodes_[id]:setTime(0)
		end

		return
	end

	local title = xyd.tables.deviceNotifyTextTable:getTitle(id)
	local content = xyd.tables.deviceNotifyTextTable:getContent(id)
	local goto_ = xyd.tables.deviceNotifyTable:getGotoID(id)
	time = self:getDisturbPushTime(id)

	self:addOrUpdateNotifyNode(id, title, content, time, goto_)
end

function DeviceNotify:isOpen(id)
	return self.openNotifyList[id]
end

function DeviceNotify:getDisturbPushTime(id)
	if not self.disturb then
		return self.notifyTime[id] - xyd.getServerTime()
	end

	local timeDesc = os:date("*t", self.notifyTime[id])

	if timeDesc.hour < 8 then
		local delay = (7 - timeDesc.hour) * 3600 + (59 - timeDesc.min) * 60 + 60 - timeDesc.sec

		return self.notifyTime[id] - xyd.getServerTime() + delay
	end

	return self.notifyTime[id] - xyd.getServerTime()
end

function DeviceNotify:checkNotifyState(id)
	if id == xyd.DEVICE_NOTIFY.MISSION then
		local updateTime = xyd:getUpdateTime()

		if xyd:getUpdateTime() < self:getDisturbPushTime(id) then
			return false
		end
	end

	return true
end

function DeviceNotify:isRedMarkUp(id)
	if not redMarkData then
		local localData = xyd.models.settingUp:getValue("red_mark_setting")

		if localData then
			redMarkData = cjson.decode(localData)
		else
			redMarkData = {}
		end

		xyd.models.redMark:initMarkSwitchArr(redMarkData)
	end

	if redMarkData[id] then
		local value = redMarkData[id]

		if value == -1 then
			return false
		else
			return true
		end
	else
		redMarkData[id] = 1

		return true
	end
end

function DeviceNotify:setRedMark(id, status)
	local value = status == true and 1 or -1
	redMarkData[id] = value

	xyd.models.redMark:updateSwitchArr(id, value)
	xyd.models.settingUp:setValue(redMarkData)
end

function DeviceNotify:onAppPause(pause, fromLogin)
	dump("===============DeviceNotify === onAppPause")
	dump(pause)
	xyd.SdkManager.get():setServerNotification(pause)

	if pause then
		self:makeAndSendNotify()

		self.lastIntentMsg_ = nil
	else
		xyd.Global.backGameTime = os.time()
		local intentMsg = xyd.SdkManager.get():popLocalIntentMsg()

		if self.lastIntentMsg_ ~= nil then
			intentMsg = self.lastIntentMsg_
			self.lastIntentMsg_ = nil
		end

		if self.isDeleteOrdering_ then
			self.isDeleteOrdering_ = false
			local win = xyd.WindowManager.get():getWindow("delete_account_window")
			local win2 = xyd.WindowManager.get():getWindow("delete_warning_window")

			if win then
				win:setGrey()
			end

			if win2 then
				win2:close()
			end

			xyd.alertTips(__("DELETE_ACCOUNT_TEXT07"))
		end

		if self.isDeleteOrdering2_ then
			self.isDeleteOrdering2_ = false

			xyd.alertTips(__("DELETE_ACCOUNT_TEXT13"))
		end

		__TRACE("NotifyManager receive intentMsg", intentMsg)
		XYDCo.WaitForFrame(10, function ()
			if intentMsg ~= nil and #intentMsg > 0 then
				local status, obj = pcall(cjson.decode, intentMsg)

				if status and obj.ID ~= nil then
					if not xyd.GuideController.get():isGuideComplete() or not xyd.HAS_ENTER_MAIN_SCENE then
						print("主界面尚未生成不能跳转")

						return
					else
						self:doDeepLink(obj)
					end
				end
			end
		end, nil)
		LocalNotification.CancelAllNotifications()
		xyd.SdkManager.get():clearAllNotify()
	end
end

function DeviceNotify:addOrUpdateNotifyNode(id, title, message, time, deepLinkID)
	local notify = self.notifyNodes_[id] or NotifyNode.new()

	notify:setValues(id, title, message, time, deepLinkID)
	dump(notify)

	self.notifyNodes_[id] = notify
end

function DeviceNotify:sendIOSNotification(delay, title, notify, isRepeat)
	isRepeat = isRepeat and 1 or 0
	local tb = {
		delay = delay,
		title = title,
		message = notify.message_,
		frontendParams = notify:getFrontendParamsStr(),
		identifier = "" .. notify.id_,
		is_repeat = isRepeat
	}
	local status, jsonStr = pcall(cjson.encode, tb)

	if status then
		xyd.SdkManager.get():addImgNotify(jsonStr)
	else
		__TRACE("error addImgNotify", notify.deepLinkID_)
	end
end

function DeviceNotify:makeAndSendNotify()
	dump("===============DeviceNotify makeAndSendNotify ===")

	local saveStr = ""
	local saveStr2 = ""
	local color = Color.New(0.792156862745098, 0.2980392156862745, 0.054901960784313725, 1)

	dump(self.notifyNodes_)

	for _, notify in pairs(self.notifyNodes_) do
		local delay = notify.time_
		local subText = notify.subText_

		if delay > 0 then
			local index = xyd.arrayIndexOf(self.includeList, notify.id_)

			if index > 0 then
				LocalNotification.SendNotification(notify.id_, delay, notify.title_, notify.message_, subText, color, "", notify:getFrontendParamsStr(), "", "")

				saveStr = saveStr .. notify.id_
				saveStr2 = saveStr2 .. notify:toString()

				__TRACE("notify: ", notify.deepLinkID_, delay, subText, notify.message_, notify.id_, notify.title_, "", "", notify.androidImg_)
			end
		end
	end

	dump(saveStr)
	dump(saveStr2)

	if saveStr ~= "" then
		PlayerPrefs.SetString("__notify_ids__", saveStr)
		__TRACE("notify saveStr", saveStr)
	end

	if saveStr2 ~= "" then
		PlayerPrefs.SetString("__notify_record__", saveStr2)
		__TRACE("notify saveStr2", saveStr2)
	end
end

function DeviceNotify:preGuideDeepLink()
	local intentMsg = xyd.SdkManager.get():popLocalIntentMsg()

	if intentMsg ~= nil and #intentMsg > 0 then
		local status, obj = pcall(cjson.decode, intentMsg)

		if status then
			if obj.ID ~= nil then
				self:doPreGuideDeepLink(obj)
			else
				self.lastIntentMsg_ = intentMsg
			end
		end
	end
end

function DeviceNotify:doDeepLink(obj)
	print("doDeepLink record", obj.ID, obj.url)

	if not obj.ID or obj.ID == "" then
		xyd.showToast("error no msg")

		return
	end

	local getWayID = tonumber(obj.ID)
	local lev = xyd.tables.getWayTable:getLvLimit(getWayID)
	local function_id = xyd.tables.getWayTable:getFunctionId(getWayID)

	if not xyd.checkFunctionOpen(function_id, true) then
		print("推送跳转等级不足 " .. lev)

		return
	end

	if xyd.WindowManager.get():isOpen("guide_window") then
		print("引导过程中推送不能跳转 ")

		return
	end

	local windows = xyd.tables.getWayTable:getGoWindow(getWayID)
	local winParams = xyd.tables.getWayTable:getGoParam(getWayID)

	for i = 1, #windows do
		local windowName = windows[i]

		xyd.WindowManager.get():openWindow(windowName, winParams[i])
	end
end

function DeviceNotify:checkOpenMsg(intentMsg)
	__TRACE("NotifyManager receive intentMsg", intentMsg)
	XYDCo.WaitForFrame(10, function ()
		if intentMsg ~= nil and #intentMsg > 0 then
			local status, obj = pcall(cjson.decode, intentMsg)

			if status and obj.ID ~= nil then
				if not xyd.GuideController.get():isGuideComplete() or not xyd.HAS_ENTER_MAIN_SCENE then
					print("主界面尚未生成不能跳转")

					return
				else
					self:doDeepLink(obj)
				end
			end
		end
	end, nil)
	LocalNotification.CancelAllNotifications()
	xyd.SdkManager.get():clearAllNotify()
end

function DeviceNotify:setDeleteMark()
	self.isDeleteOrdering_ = true
end

function DeviceNotify:setDeleteMark2()
	self.isDeleteOrdering2_ = true
end

return DeviceNotify
