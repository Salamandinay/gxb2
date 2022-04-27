local BaseWindow = import(".BaseWindow")
local ActivityDriftSelectWindow = class("ActivityDriftSelectWindow", BaseWindow)
local cjson = require("cjson")

function ActivityDriftSelectWindow:ctor(parentGO, params)
	BaseWindow.ctor(self, parentGO, params)

	self.isDouble = params.isDouble
	self.select = 0
	self.select1 = 0
	self.select2 = 0
end

function ActivityDriftSelectWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:layout()
	self:register()
end

function ActivityDriftSelectWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupMain = winTrans:NodeByName("groupMain").gameObject
	self.bg = winTrans:NodeByName("bg").gameObject
	self.rudder = groupMain:NodeByName("rudder").gameObject
	self.rudder1 = groupMain:NodeByName("rudder1").gameObject
	self.rudder2 = groupMain:NodeByName("rudder2").gameObject
	self.btn = groupMain:NodeByName("btn").gameObject
	self.btnLabel = self.btn:ComponentByName("label", typeof(UILabel))
	self.label = groupMain:NodeByName("label").gameObject
	self.rudderMask = self.rudder:NodeByName("mask").gameObject

	for i = 1, 6 do
		self["select_" .. i] = self.rudder:NodeByName("select" .. i).gameObject
		self["selected_" .. i] = self["select_" .. i]:NodeByName("selected").gameObject
	end

	self.rudderMask1 = self.rudder1:NodeByName("mask").gameObject

	for i = 1, 6 do
		self["select1_" .. i] = self.rudder1:NodeByName("select" .. i).gameObject
		self["selected1_" .. i] = self["select1_" .. i]:NodeByName("selected").gameObject
	end

	self.rudderMask2 = self.rudder2:NodeByName("mask").gameObject

	for i = 1, 6 do
		self["select2_" .. i] = self.rudder2:NodeByName("select" .. i).gameObject
		self["selected2_" .. i] = self["select2_" .. i]:NodeByName("selected").gameObject
	end
end

function ActivityDriftSelectWindow:layout()
	dump(self.isDouble)

	if self.isDouble then
		self.rudder:SetActive(false)
		self.rudder1:SetActive(true)
		self.rudder2:SetActive(true)
	else
		self.rudder:SetActive(true)
		self.rudder1:SetActive(false)
		self.rudder2:SetActive(false)
	end
end

function ActivityDriftSelectWindow:register()
	for i = 1, 6 do
		UIEventListener.Get(self["select_" .. i]).onClick = handler(self, function ()
			if self.select == 0 then
				self.select = i

				self["selected_" .. self.select]:SetActive(true)
				self.rudderMask:SetActive(true)

				self.rudderMask.transform.localEulerAngles = Vector3(0, 0, 60 - self.select * 60)
			elseif self.select == i then
				self["selected_" .. self.select]:SetActive(false)

				self.select = 0

				self.rudderMask:SetActive(false)
			else
				self["selected_" .. self.select]:SetActive(false)

				self.select = i

				self["selected_" .. self.select]:SetActive(true)

				self.rudderMask.transform.localEulerAngles = Vector3(0, 0, 60 - self.select * 60)
			end
		end)
	end

	UIEventListener.Get(self.bg).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.window_.name)
	end)
	UIEventListener.Get(self.btn).onClick = handler(self, function ()
		local seletNum = self.isDouble and self.select1 + self.select2 or self.select

		if not self.isDouble or self.select1 > 0 or self.select2 > 0 then
			if self.select > 0 then
				local data = cjson.encode({
					type = 2,
					steps = seletNum
				})
				local msg = messages_pb.get_activity_award_req()
				msg.activity_id = xyd.ActivityID.LAFULI_DRIFT
				msg.params = data

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
				xyd.WindowManager.get():closeWindow(self.window_.name)
			end
		end
	end)
end

return ActivityDriftSelectWindow
