local ActivityWorldBossSweepWindow = class("ActivityWorldBossSweepWindow", import(".BaseWindow"))
local OldSize = {
	w = 720,
	h = 1280
}

function ActivityWorldBossSweepWindow:ctor(name, params)
	self.stage_id = params.stage_id

	ActivityWorldBossSweepWindow.super.ctor(self, name, params)

	self.curNum_ = 1
	self.selectState_ = tonumber(xyd.db.misc:getValue("activity_monthly_hike_sweep_next"))
end

function ActivityWorldBossSweepWindow:initWindow()
	ActivityWorldBossSweepWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function ActivityWorldBossSweepWindow:getUIComponent()
	self.content_ = self.window_:ComponentByName("groupAction", typeof(UISprite))
	local contentTrans = self.content_.transform
	local sWidth, sHeight = xyd.getScreenSize()
	local activeHeight = xyd.WindowManager.get():getActiveHeight()
	local activeWidth = xyd.WindowManager.get():getActiveWidth()

	if sHeight / sWidth <= 1.4 then
		contentTrans.localScale = Vector3(1.15, 1.15, 1.15)
		contentTrans.localPosition = Vector3(0, contentTrans.localPosition.y * 1.15, 0)
	else
		contentTrans.localScale = Vector3(activeWidth / OldSize.w, activeHeight / OldSize.h, 1)
		contentTrans.localPosition = Vector3(0, contentTrans.localPosition.y * activeHeight / OldSize.h, 0)
	end

	self.iconImg_ = contentTrans:ComponentByName("groupTili/image", typeof(UISprite))
	self.labelWinTitle_ = contentTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.labelTips_ = contentTrans:ComponentByName("labelTips_", typeof(UILabel))
	self.btnSure_ = contentTrans:ComponentByName("btnSure", typeof(UISprite)).gameObject
	self.btnSureLabel_ = contentTrans:ComponentByName("btnSure/label", typeof(UILabel))
	self.labelTili_ = contentTrans:ComponentByName("groupTili/label", typeof(UILabel))
	self.addbtn = contentTrans:ComponentByName("groupTili/addbtn", typeof(UISprite))
	self.selectNumPos_ = contentTrans:NodeByName("selectNumPos").gameObject
	self.closeBtn = contentTrans:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.descGroup = contentTrans:NodeByName("descGroup").gameObject
	self.descBg_ = contentTrans:ComponentByName("descGroup/bg", typeof(UISprite))
	self.selectImg = contentTrans:ComponentByName("descGroup/selectImg", typeof(UISprite))
	self.descLabel = contentTrans:ComponentByName("descGroup/descLabel", typeof(UILabel))
end

function ActivityWorldBossSweepWindow:layout()
	xyd.setUISpriteAsync(self.iconImg_, nil, xyd.tables.itemTable:getIcon(28), nil, )

	self.iconImg_:GetComponent(typeof(UIWidget)).width = 45
	self.iconImg_:GetComponent(typeof(UIWidget)).height = 45
	self.labelWinTitle_.text = __("WORLD_BOSS_SWEEP_TITLE")
	self.btnSureLabel_.text = __("CONFIRM")
	self.labelTips_.text = __("WORLD_BOSS_SWEEP_TIPS")
	self.descLabel.text = __("WORLD_BOSS_SWEEP_TIPS2")
	self.selectNum_ = import("app.components.SelectNum").new(self.selectNumPos_, "minmax")
	self.curNum_ = 1

	self:initTextInput()
	self.selectNum_:setKeyboardPos(0, -420)
	self.selectNum_:setMaxAndMinBtnPos(240)
	self:updateSelectImg()
end

function ActivityWorldBossSweepWindow:updateSelectImg()
	if self.selectState_ == 1 then
		xyd.setUISpriteAsync(self.selectImg, nil, "setting_up_pick")
	else
		xyd.setUISpriteAsync(self.selectImg, nil, "setting_up_unpick")
	end
end

function ActivityWorldBossSweepWindow:initTextInput()
	local max = xyd.models.backpack:getItemNumByID(28)
	self.selectNum_.inputLabel.text = "1"

	local function callback(num)
		if num > 50 then
			xyd.showToast(__("WORLD_BOSS_SWEEP_WARNING"))

			self.curNum_ = 50
		elseif max < num then
			self.curNum_ = max
		else
			self.curNum_ = num
		end

		self.selectNum_.inputLabel.text = tostring(self.curNum_)

		self.selectNum_:setCurNum(self.curNum_)

		self.labelTili_.text = tostring(max)
	end

	self.selectNum_:setInfo({
		clearNotCallback = true,
		maxNum = 50,
		minNum = 1,
		notCallback = true,
		curNum = 1,
		callback = callback,
		maxCallback = function ()
			if max >= 50 then
				xyd.showToast(__("WORLD_BOSS_SWEEP_WARNING"))
			end
		end
	})

	self.labelTili_.text = tostring(max)
end

function ActivityWorldBossSweepWindow:sureTouch()
	if self:checkCanFight() then
		local fightParams = {
			is_weep = true,
			activity_id = self.params_.activity_id,
			battleType = xyd.BattleType.WORLD_BOSS,
			num = self.curNum_,
			boss_type = self.params_.boss_type
		}

		if self.stage_id and self.stage_id > 50 then
			fightParams.stage_id = self.stage_id
		end

		xyd.WindowManager.get():openWindow("battle_formation_window", fightParams)
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivityWorldBossSweepWindow:checkCanFight()
	return true
end

function ActivityWorldBossSweepWindow:register()
	ActivityWorldBossSweepWindow.super.register(self)

	UIEventListener.Get(self.btnSure_.gameObject).onClick = handler(self, self.sureTouch)

	UIEventListener.Get(self.selectImg.gameObject).onClick = function ()
		if not self.selectState_ or self.selectState_ == 0 then
			self.selectState_ = 1
		else
			self.selectState_ = 0
		end

		xyd.db.misc:setValue({
			key = "activity_monthly_hike_sweep_next",
			value = self.selectState_
		})
		self:updateSelectImg()
	end
end

return ActivityWorldBossSweepWindow
