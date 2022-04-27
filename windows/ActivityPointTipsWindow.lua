local ActivityPointTipsWindow = class("ActivityPointTipsWindow", import(".BaseWindow"))

function ActivityPointTipsWindow:ctor(name, params)
	ActivityPointTipsWindow.super.ctor(self, name, params)
end

function ActivityPointTipsWindow:initWindow()
	ActivityPointTipsWindow.super.initWindow(self)
	self:getUIComponents()
	self:initUIComponent()

	self.limitWidth = 460
end

function ActivityPointTipsWindow:getUIComponents()
	local go = self.window_
	self.winPanel = self.window_:GetComponent(typeof(UIPanel))
	self.groupMain = go:NodeByName("groupMain").gameObject
	self.groupWidget = self.groupMain:GetComponent(typeof(UIWidget))
	self.Bg_ = self.groupMain:ComponentByName("Bg_", typeof(UISprite))
	self.fgx = self.groupMain:ComponentByName("fgx", typeof(UISprite))
	self.group = self.groupMain:ComponentByName("group", typeof(UIWidget))
	self.layout = self.groupMain:ComponentByName("group", typeof(UILayout))
	self.icon = self.groupMain:ComponentByName("group/icon", typeof(UISprite))
	self.title = self.groupMain:ComponentByName("group/title", typeof(UILabel))
	self.desLabel_ = self.groupMain:ComponentByName("desLabel_", typeof(UILabel))
	self.desLabel_Achievement_Panel = self.groupMain:ComponentByName("desLabel_Achievement_Panel", typeof(UIPanel))
	self.desLabel_Achievement = self.desLabel_Achievement_Panel:ComponentByName("desLabel_Achievement", typeof(UILabel))
end

function ActivityPointTipsWindow:initUIComponent()
	self.winPanel.depth = xyd.UILayerDepth.MAX - 2
	self.desLabel_Achievement_Panel.depth = xyd.UILayerDepth.MAX - 1
	self.groupWidget.alpha = 0
end

function ActivityPointTipsWindow:setInfo(params)
	self.params = params

	if params.activityId == xyd.ActivityID.BATTLE_PASS then
		print("========================================================6")
		self.desLabel_Achievement_Panel.gameObject:SetActive(true)
		self.desLabel_.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.icon, nil, "activity_point_tip_window_icon_cj")
		xyd.setUISpriteAsync(self.Bg_, nil, "activity_point_tip_window_bg_chang")
		xyd.setUISpriteAsync(self.fgx, nil, "activity_point_tip_window_fgx")

		self.title.text = __("ACHIEVEMENT_REACHED")
		self.title.color = Color.New2(3613720831.0)

		self.group:Y(21)
		self.fgx:Y(-8)
		self.layout:Reposition()

		self.desLabel_Achievement.text = params.des
		local params1 = {
			playTextAni = true,
			showTime = 3
		}
		local width = self.desLabel_Achievement.width
		local t = (width - self.limitWidth) / 100

		if t > 3 then
			params1.showTime = t + 0.5
		end

		self:playEnterAnimation(params1)

		return
	end

	self.desLabel_Achievement_Panel.gameObject:SetActive(false)
	self.desLabel_.gameObject:SetActive(true)

	self.Bg_.width = 466

	xyd.setUISpriteAsync(self.icon, nil, xyd.tables.activityTable:getIcon(params.activityId))
	xyd.setUISpriteAsync(self.Bg_, nil, "activity_tips_window_bg")
	xyd.setUISpriteAsync(self.fgx, nil, "fgx_2")

	self.title.text = xyd.tables.tipsActivityPointTable:getTitle(params.table_id)
	self.title.color = Color.New2(1064878079)

	self.group:Y(23)
	self.fgx:Y(-5)
	self.layout:Reposition()

	self.desLabel_.text = params.des
	local params1 = {
		showTime = 1.5
	}

	self:playEnterAnimation(params1)
end

function ActivityPointTipsWindow:playEnterAnimation(params)
	local showTime = 1.5

	if params and params.showTime then
		showTime = params.showTime
	end

	local function setter(value)
		self.groupWidget.alpha = value
	end

	local action = self:getSequence()

	action:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 1, 0.5))
	action:AppendCallback(function ()
		if params and params.playTextAni then
			self:playTextAnimation()
		end

		self:waitForTime(showTime, function ()
			self:playExitAnimation()
		end)
	end)
end

function ActivityPointTipsWindow:playExitAnimation()
	local function setter(value)
		self.groupWidget.alpha = value
	end

	local action = self:getSequence()

	action:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0, 0.35))
	action:AppendCallback(function ()
		xyd.models.activityPointTips:setFlag(false)
		xyd.models.activityPointTips:nextTip()
	end)
end

function ActivityPointTipsWindow:playTextAnimation()
	local width = self.desLabel_Achievement.width

	if self.curAction_ then
		self.curAction_:Kill()

		self.curAction_ = nil
	end

	self.desLabel_Achievement:X(0)

	if self.limitWidth < width then
		self.desLabel_Achievement:X((width - self.limitWidth) / 2)

		local action = self:getSequence()
		local t = (width - self.limitWidth) / 100

		action:Append(self.desLabel_Achievement.transform:DOLocalMove(Vector3(-(width - self.limitWidth) / 2, 11, 0), t))

		self.curAction_ = action
	end
end

return ActivityPointTipsWindow
