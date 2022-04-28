local BaseWindow = import(".BaseWindow")
local GambleTipsWindow = class("GambleTipsWindow", BaseWindow)
local OldSize = {
	w = 720,
	h = 1280
}
local GambleConfigTable = xyd.tables.gambleConfigTable

function GambleTipsWindow:ctor(name, params)
	GambleTipsWindow.super.ctor(self, name, params)

	self.callback_ = params.callback
	self.wndType_ = params.wndType
	self.type = params.type
	self.text = params.text
	self.labelNeverText = params.labelNeverText or __("GAMBLE_REFRESH_NOT_SHOW_TODAY")
	self.btnNoText_ = params.btnNoText_ or __("NO")
	self.btnYesText_ = params.btnYesText or __("YES")
	self.cancelSelect = params.cancelSelect
	self.hideGroupChoose = params.hideGroupChoose
	self.helpParams = params.helpParams
	self.closeCallback = params.closeCallback
	self.closeFun = params.closeFun
	self.hasSelect_ = false
	self.tipsTextY = params.tipsTextY
	self.tipsHeight = params.tipsHeight
	self.tipsWidth = params.tipsWidth
	self.tipsSpacingY = params.tipsSpacingY
	self.selectCallback = params.selectCallback
	self.groupChooseY = params.groupChooseY
	self.isHideNoBtn = params.isHideNoBtn
end

function GambleTipsWindow:initWindow()
	GambleTipsWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.content_ = winTrans:ComponentByName("content", typeof(UISprite))
	self.labelTitle_ = winTrans:ComponentByName("content/labelTitle", typeof(UILabel))
	self.labelDesc_ = winTrans:ComponentByName("content/labelDesc", typeof(UILabel))
	self.groupChoose = winTrans:NodeByName("content/groupChoose").gameObject
	self.groupChoose_UILayout = winTrans:ComponentByName("content/groupChoose", typeof(UILayout))
	self.labelNever_ = winTrans:ComponentByName("content/groupChoose/labelNever", typeof(UILabel))
	self.btnNo_ = winTrans:ComponentByName("content/btnNo", typeof(UISprite))
	self.btnNoLabel_ = winTrans:ComponentByName("content/btnNo/labelDesc", typeof(UILabel))
	self.btnYes_ = winTrans:ComponentByName("content/btnYes", typeof(UISprite))
	self.btnYesLabel_ = winTrans:ComponentByName("content/btnYes/labelDesc", typeof(UILabel))
	self.img_ = winTrans:ComponentByName("content/groupChoose/img", typeof(UISprite))
	self.imgSelect_ = winTrans:ComponentByName("content/groupChoose/img/imgSelect", typeof(UISprite))
	self.selectMask_ = winTrans:NodeByName("content/selectMask_").gameObject
	self.btnClose_ = winTrans:ComponentByName("content/btnClose", typeof(UISprite))
	self.maskBg_ = winTrans:ComponentByName("maskbg", typeof(UIWidget))
	self.btnHelp_ = winTrans:NodeByName("content/btnHelp").gameObject

	self.imgSelect_.gameObject:SetActive(false)

	local activeHeight = xyd.WindowManager.get():getActiveHeight()
	local activeWidth = xyd.WindowManager.get():getActiveWidth()
	local contentTrans = self.content_.transform
	contentTrans.localPosition = Vector3(0, contentTrans.localPosition.y * activeHeight / OldSize.h, 0)

	self:layout()
	self:register()
end

function GambleTipsWindow:register()
	GambleTipsWindow.super.register(self)
end

function GambleTipsWindow:layout()
	self.labelTitle_.text = __("TIPS")

	if self.type == "gamble" then
		local cost = GambleConfigTable:getRefresh(self.wndType_)[2]
		self.labelDesc_.text = __("GAMBLE_REFRESH_CONFIRM", cost)
	elseif self.type == "summon" then
		self.labelDesc_.text = self.text
	elseif self.type == "midas" then
		self.labelDesc_.text = self.text
	elseif self.type == "full_order_grade_up" then
		self.labelDesc_.text = __("ONE_KEY_UPGRADE_HINT")
	elseif self.type == "dummy_exchange" then
		self.labelDesc_.text = __("CONFIRM_BUY")
	elseif self.type == "entrance_test" then
		self.labelDesc_.text = __("ENTRANCE_TEST_PARTNER_NOT_READY")
	elseif self.type == "monthly_hike" then
		self.labelDesc_.text = __("ACTIVITY_MONTHLY_HIKE_SKILL_2")

		if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
			self.labelDesc_.width = 560
			self.labelDesc_.height = 100

			self.labelDesc_.transform:Y(55)
		end
	elseif self.type == "fair_arena_open_back_pack" then
		self.labelDesc_.transform:Y(50)

		self.labelDesc_.text = self.text

		self.btnNo_.gameObject:SetActive(false)
		self.btnYes_.gameObject:X(0)
		self.groupChoose.gameObject:Y(-31)
		self.selectMask_.gameObject:Y(-31)
	else
		self.labelDesc_.text = self.text
	end

	if self.isHideNoBtn then
		self.btnNo_.gameObject:SetActive(false)
		self.btnYes_.gameObject:X(0)
	end

	if self.groupChooseY then
		self.groupChoose.gameObject:Y(self.groupChooseY)
		self.selectMask_.gameObject:Y(self.groupChooseY)
	end

	self.labelNever_.text = self.labelNeverText

	if self.type == "study_question_1" or self.type == "study_question_2" or self.type == "study_question_3" or self.type == "study_question_4" then
		self.labelNever_.text = __("COMMON_NOT_SHOW")

		if xyd.Global.lang == "de_de" then
			self.labelDesc_.width = 560
		end
	end

	self.groupChoose_UILayout:Reposition()

	if self.tipsTextY then
		self.labelDesc_.gameObject:Y(self.tipsTextY)
	end

	if self.tipsHeight then
		self.labelDesc_.height = self.tipsHeight
	end

	if self.tipsWidth then
		self.labelDesc_.width = self.tipsWidth
	end

	if self.tipsSpacingY then
		self.labelDesc_.spacingY = self.tipsSpacingY
	end

	if self.cancelSelect then
		self.img_:SetActive(false)
		self.selectMask_:SetActive(false)
		self.groupChoose:GetComponent(typeof(UILayout)):Reposition()
	end

	if self.hideGroupChoose then
		self.groupChoose:SetActive(false)
		self.labelDesc_:Y(25)

		self.labelDesc_.height = 170
	end

	if self.helpParams then
		self.btnHelp_:SetActive(true)

		UIEventListener.Get(self.btnHelp_).onClick = function ()
			xyd.openWindow("help_window2", self.helpParams)
		end
	end

	self.btnNoLabel_.text = self.btnNoText_
	self.btnYesLabel_.text = self.btnYesText_
end

function GambleTipsWindow:register()
	UIEventListener.Get(self.selectMask_).onClick = handler(self, self.onSelect)

	UIEventListener.Get(self.btnNo_.gameObject).onClick = function ()
		if self.closeCallback then
			self.closeCallback()
		end

		if self.closeFun then
			self.closeFun()
		end

		if self.hasSelect_ and self.type == "secretTreasureHunt_dice" then
			xyd.db.misc:setValue({
				value = false,
				key = self.type .. "_result"
			})
		end

		xyd.closeWindow("gamble_tips_window")
	end

	UIEventListener.Get(self.btnClose_.gameObject).onClick = function ()
		if self.closeFun then
			self.closeFun()
		end

		xyd.closeWindow("gamble_tips_window")
	end

	UIEventListener.Get(self.maskBg_.gameObject).onClick = function ()
		if self.closeFun then
			self.closeFun()
		end

		xyd.closeWindow("gamble_tips_window")
	end

	UIEventListener.Get(self.btnYes_.gameObject).onClick = function ()
		if self.callback_ then
			self.callback_()
		end

		if self.hasSelect_ then
			xyd.db.misc:setValue({
				key = self.type .. "_time_stamp",
				value = xyd.getServerTime()
			})

			if self.type == "secretTreasureHunt_dice" then
				xyd.db.misc:setValue({
					value = true,
					key = self.type .. "_result"
				})
			end
		end

		if self.selectCallback then
			self.selectCallback(self.hasSelect_)
		end

		xyd.closeWindow("gamble_tips_window")
	end
end

function GambleTipsWindow:onSelect()
	self.imgSelect_.gameObject:SetActive(not self.hasSelect_)

	self.hasSelect_ = not self.hasSelect_
end

function GambleTipsWindow:onClickEscBack()
	if self.params_.isNoESC then
		return
	end

	GambleTipsWindow.super.onClickEscBack(self)
end

return GambleTipsWindow
