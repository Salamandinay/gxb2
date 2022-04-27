local CampaignFuncAlertWindow = class("CampaignFuncAlertWindow", import(".BaseWindow"))

function CampaignFuncAlertWindow:ctor(name, params)
	CampaignFuncAlertWindow.super.ctor(self, name, params)

	self.stageId = params.stageId
end

function CampaignFuncAlertWindow:initWindow()
	CampaignFuncAlertWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.mainGroup = winTrans:Find("main")
	self.requireLabel = self.mainGroup:ComponentByName("require_label", typeof(UILabel))
	self.label1 = self.mainGroup:ComponentByName("label1", typeof(UILabel))
	self.label2 = self.mainGroup:ComponentByName("label2", typeof(UILabel))
	self.icon = self.mainGroup:ComponentByName("icon", typeof(UISprite))

	self:initLayOut()
end

function CampaignFuncAlertWindow:initLayOut()
	local func = xyd.tables.stageTable:getFunctionID(self.stageId)

	if func and func ~= 0 then
		self.requireLabel.text = xyd.tables.functionTextTable:getName(func)
		self.label1.text = string.gsub(xyd.tables.functionTextTable:getDesc(func), "\\n", " ")

		xyd.setUISprite(self.icon, nil, xyd.tables.functionTable:getIcon(func))
		self.icon:MakePixelPerfect()
		self.icon:SetLocalScale(1, 1, 1)

		if func == xyd.FunctionID.OLD_SCHOOL then
			local fortId = xyd.tables.stageTable:getFortID(self.stageId)
			local text = tostring(fortId) .. "-" .. tostring(xyd.tables.stageTable:getName(self.stageId))
			self.label2.text = __("STAGE_UNLOCK_TEXT03", text)

			return
		end

		local fortId = xyd.tables.stageTable:getFortID(self.stageId)
		local text = tostring(fortId) .. "-" .. tostring(xyd.tables.stageTable:getName(self.stageId))
		self.label2.text = __("STAGE_UNLOCK_TEXT", text)
	end

	if self.stageId == xyd.tables.miscTable:getNumber("cdkey_gxb222_stage_id", "value") then
		self.requireLabel.text = __("CDKEY_TEXT01")
		self.label1.text = __("STAGE_UNLOCK_TEXT02")
		local fortId = xyd.tables.stageTable:getFortID(self.stageId)
		local text = tostring(fortId) .. "-" .. tostring(xyd.tables.stageTable:getName(self.stageId))
		self.label2.text = __("STAGE_UNLOCK_TEXT", text)

		xyd.setUISprite(self.icon, nil, xyd.tables.miscTable:getString("cdkey_gxb222_icon", "value"))
		self.icon:MakePixelPerfect()
		self.icon:SetLocalScale(1, 1, 1)
	end
end

return CampaignFuncAlertWindow
