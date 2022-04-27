local BaseWindow = import(".BaseWindow")
local cjson = require("cjson")
local NetworkDoctorWindow = class("NetworkDoctorWindow", BaseWindow)

function NetworkDoctorWindow:ctor(name, params)
	NetworkDoctorWindow.super.ctor(self, name, params)

	self.skinName = "NetworkDoctorSkin"
end

function NetworkDoctorWindow:initWindow()
	NetworkDoctorWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function NetworkDoctorWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupAction = trans:NodeByName("groupAction").gameObject
	self.labelTitle_ = self.groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.group1_ = self.groupAction:NodeByName("group1_").gameObject
	self.labelText1_ = self.group1_:ComponentByName("labelText1_", typeof(UILabel))
	self.btnDoctor_ = self.group1_:NodeByName("btnDoctor_").gameObject
	self.btnDoctorLabel = self.btnDoctor_:ComponentByName("button_label", typeof(UILabel))
	self.group2_ = self.groupAction:NodeByName("group2_").gameObject
	self.imgCircle_ = self.group2_:ComponentByName("imgCircle_", typeof(UISprite))
	self.labelText2_ = self.group2_:ComponentByName("labelText2_", typeof(UILabel))
	self.group3_ = self.groupAction:NodeByName("group3_").gameObject
	self.labelText3_ = self.group3_:ComponentByName("labelText3_", typeof(UILabel))
	self.labelText4_ = self.group3_:ComponentByName("labelText4_", typeof(UILabel))
	self.labelText5_ = self.group3_:ComponentByName("labelText5_", typeof(UILabel))
	self.labelText6_ = self.group3_:ComponentByName("labelText6_", typeof(UILabel))
	self.btnSure_ = self.group3_:NodeByName("btnSure_").gameObject
	self.btnSureLabel = self.btnSure_:ComponentByName("button_label", typeof(UILabel))
	self.group4_ = self.groupAction:NodeByName("group4_").gameObject
	self.labelText7_ = self.group4_:ComponentByName("labelText7_", typeof(UILabel))
	self.btnTryAgain_ = self.group4_:NodeByName("btnTryAgain_").gameObject
	self.btnTryAgainLabel = self.btnTryAgain_:ComponentByName("button_label", typeof(UILabel))
	self.btnNextTime_ = self.group4_:NodeByName("btnNextTime_").gameObject
	self.btnNextTimeLabel = self.btnNextTime_:ComponentByName("button_label", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
end

function NetworkDoctorWindow:layout()
	self.labelTitle_.text = __("SETTING_UP_DOCTOR")
	self.btnDoctorLabel.text = __("SETTING_UP_DOCTOR")
	self.btnSureLabel.text = __("SURE")
	self.btnTryAgainLabel.text = __("TRY_AGAIN")
	self.btnNextTimeLabel.text = __("NEXT_TIME")
	self.labelText1_.text = __("NETWORK_DOCTOR_TEXT01")
	self.labelText2_.text = __("NETWORK_DOCTOR_TEXT02")
	self.labelText3_.text = __("NETWORK_DOCTOR_TEXT03")
	self.labelText6_.text = __("NETWORK_DOCTOR_TEXT06")
	self.labelText7_.text = __("NETWORK_DOCTOR_TEXT07")
end

function NetworkDoctorWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.btnDoctor_).onClick = function ()
		self.group1_:SetActive(false)
		self:onDoctor()
	end

	UIEventListener.Get(self.btnSure_).onClick = function ()
		xyd.closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnNextTime_).onClick = function ()
		xyd.closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnTryAgain_).onClick = function ()
		self.group4_:SetActive(false)
		self:onDoctor()
	end

	self.eventProxy_:addEventListener(xyd.event.SDK_PING_RES, handler(self, self.onSdkEvent))
end

function NetworkDoctorWindow:playCircleAction(flag)
	self.group2_:SetActive(flag)
end

function NetworkDoctorWindow:onDoctor()
	self:playCircleAction(true)

	local urls = xyd.getPingUrls()

	dump(urls)
	xyd.SdkManager.get():getPingRes(urls, true)
end

function NetworkDoctorWindow:onSdkEvent(event)
	self:playCircleAction(false)

	local params = event.params
	local pingResults = params.params

	if pingResults then
		local showResult = cjson.decode(pingResults[2])

		self.group3_:SetActive(true)

		self.labelText4_.text = __("NETWORK_DOCTOR_TEXT04", showResult.delay)
		self.labelText5_.text = __("NETWORK_DOCTOR_TEXT05", showResult.loss_rate)
		local msg = messages_pb.record_ping_req()

		for _, str in ipairs(pingResults) do
			local item = messages_pb.ping_result()
			item.client_time = xyd.getServerTime()
			local result = cjson.decode(str)
			item.loss_rate = tonumber(result.loss_rate)
			item.delay = tonumber(result.delay)
			item.target_ip = result.target_ip

			table.insert(msg.log_list, item)
		end

		xyd.Backend.get():request(xyd.mid.RECORD_PING, msg)
	else
		self.group4_:SetActive(true)
	end
end

return NetworkDoctorWindow
