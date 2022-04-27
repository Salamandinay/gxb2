local BaseWindow = import(".BaseWindow")
local EntranceTestPromotionWindow = class("EntranceTestPromotionWindow", BaseWindow)
local ActivityEntranceTestHelpItems = import("app.components.ActivityEntranceTestHelpItems")

function EntranceTestPromotionWindow:ctor(name, params)
	EntranceTestPromotionWindow.super.ctor(self, name, params)
end

function EntranceTestPromotionWindow:initWindow()
	self:getComponent()
	self:layout()
end

function EntranceTestPromotionWindow:getComponent()
	local goTrans = self.window_:NodeByName("groupAction")
	self.effectGroup = goTrans:NodeByName("groupEffect").gameObject
	self.contentGroup = goTrans:ComponentByName("groupContent", typeof(UIWidget))
	self.labelUnlock_ = goTrans:ComponentByName("groupContent/labelUnlock", typeof(UILabel))
	self.levelImg_ = goTrans:ComponentByName("groupContent/levelImg", typeof(UISprite))
	self.labelDesc_ = goTrans:ComponentByName("groupContent/labelDesc", typeof(UILabel))
	self.jumpBtn_ = goTrans:NodeByName("groupContent/jumpBtn").gameObject
	self.jumpBtnLabel_ = goTrans:ComponentByName("groupContent/jumpBtn/label", typeof(UILabel))
	self.tipsLabel_ = goTrans:ComponentByName("groupContent/tipsLabel", typeof(UILabel))
	self.topLabel_ = goTrans:ComponentByName("topLabel", typeof(UILabel))
	self.touchBlock = goTrans:NodeByName("touchBlock").gameObject
end

function EntranceTestPromotionWindow:layout()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	local level = self.activityData:getLevel()
	self.jumpBtnLabel_.text = __("ENTRANCE_TEST_LEVEL_UP_DESC_1")
	self.topLabel_.text = __("ENTRANCE_TEST_LEVEL_UP_DESC")
	self.labelUnlock_.text = __("ENTRANCE_TEST_LEVEL_UP")
	self.labelDesc_.text = __("WARMUP_ARENA_RANK_INFO_" .. level)

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
		self.labelDesc_.width = 520
		self.labelDesc_.spacingY = 6

		self.labelDesc_.transform:X(-240)
	elseif xyd.Global.lang == "ko_kr" and level == 2 then
		self.labelDesc_.transform:X(-140)
	elseif xyd.Global.lang == "ko_kr" and level == 4 then
		self.labelDesc_.transform:X(-80)
	elseif xyd.Global.lang == "ko_kr" and level == 3 then
		self.labelDesc_.transform:X(-200)
	end

	if xyd.Global.lang == "fr_fr" and level == 3 then
		self.labelDesc_.width = 520
		self.labelDesc_.spacingY = 5

		self.labelDesc_.transform:Y(-206)
	end

	xyd.setUISpriteAsync(self.levelImg_, nil, "entrance_test_level_" .. level, nil, , true)

	UIEventListener.Get(self.jumpBtn_).onClick = function ()
		local params = {
			battleType = xyd.BattleType.ENTRANCE_TEST_DEF,
			formation = self.activityData.detail.partners,
			mapType = xyd.MapType.ENTRANCE_TEST
		}

		xyd.WindowManager.get():openWindow("battle_formation_window", params)
		self:close()
	end

	if level == xyd.EntranceTestLevelType.R4 then
		self.tipsLabel_.text = __("LOGIN_HANGUP_TEXT04")

		self.jumpBtn_:SetActive(false)
	else
		self.tipsLabel_.gameObject:SetActive(false)
	end
end

function EntranceTestPromotionWindow:playOpenAnimation(callback)
	EntranceTestPromotionWindow.super.playOpenAnimation(self, function ()
		local effect = xyd.Spine.new(self.effectGroup)
		local seq = self:getSequence()

		seq:Insert(0, self.contentGroup.transform:DOScale(Vector3(1, 1, 1), 0.4))
		effect:setInfo("fx_ui_13xing_tanchuang", function ()
			self.topLabel_.gameObject:SetActive(true)
			effect:play("texiao01", 1, 1, function ()
				self.touchBlock:SetActive(false)
				effect:play("texiao02", 0, 1)
			end)
		end)

		if callback then
			callback()
		end
	end)
end

return EntranceTestPromotionWindow
