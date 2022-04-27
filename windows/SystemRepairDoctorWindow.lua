local SystemRepairDoctorWindow = class("SystemRepairDoctorWindow", import(".BaseWindow"))

function SystemRepairDoctorWindow:ctor(name, params)
	SystemRepairDoctorWindow.super.ctor(self, name, params)
end

function SystemRepairDoctorWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function SystemRepairDoctorWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.bgImg = self.groupAction:ComponentByName("bgImg", typeof(UISprite))
	self.groupTop = self.groupAction:NodeByName("groupTop").gameObject
	self.labelTitle = self.groupTop:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupTop:NodeByName("closeBtn").gameObject
	self.group1 = self.groupAction:NodeByName("group1").gameObject
	self.explainLabel = self.group1:ComponentByName("explainLabel", typeof(UILabel))
	self.clickBtn = self.group1:NodeByName("clickBtn").gameObject
	self.clickBtnLabel = self.clickBtn:ComponentByName("clickBtnLabel", typeof(UILabel))
	self.group2 = self.groupAction:NodeByName("group2").gameObject
	self.imgCircle = self.group2:ComponentByName("imgCircle", typeof(UISprite))
	self.labelText2 = self.group2:ComponentByName("labelText2", typeof(UILabel))
end

function SystemRepairDoctorWindow:layout()
	self.explainLabel.text = __("GAME_REPAIR_TIPS")
	self.labelTitle.text = __("GAME_REPAIR")
	self.clickBtnLabel.text = __("GAME_REPAIR")
	self.labelText2.text = __("GAME_REPAIR_3")
end

function SystemRepairDoctorWindow:registerEvent()
	UIEventListener.Get(self.clickBtn.gameObject).onClick = handler(self, function ()
		xyd.alert(xyd.AlertType.YES_NO, __("REPAIR_TO_RESET_GAME"), function (yes_no)
			if yes_no then
				self.group1:SetActive(false)
				self.group2:SetActive(true)

				self.closeBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

				self:waitForTime(2, function ()
					xyd.MainController.get():restartGame()
				end)
			end
		end)
	end)
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

return SystemRepairDoctorWindow
