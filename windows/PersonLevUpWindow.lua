local BaseWindow = import(".BaseWindow")
local PersonLevUpWindow = class("PersonLevUpWindow", BaseWindow)

function PersonLevUpWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.canTouch_ = false
	self.skinName = "PersonLevUpWindowSkin"
end

function PersonLevUpWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	xyd.SoundManager.get():playSound(xyd.SoundID.PLAYER_LEV_UP)

	local wnd = xyd.getWindow("guide_window")

	if wnd then
		wnd:playLevUpHide(true)
	end
end

function PersonLevUpWindow:getUIComponent()
	local winTrans = self.window_
	self.groupMain_ = winTrans:NodeByName("groupMain_").gameObject
	self.groupModel_ = self.groupMain_:ComponentByName("top/groupModel_", typeof(UITexture))
	self.labelLev_ = self.groupMain_:ComponentByName("top/labelLev_", typeof(UILabel))
	self.labelNum_ = self.groupMain_:ComponentByName("top/labelNum_", typeof(UILabel))
end

function PersonLevUpWindow:layout()
	local effect = xyd.Spine.new(self.groupModel_.gameObject)

	effect:setInfo("shengji", function ()
		effect:playWithEvent("texiao01_en_en", 1, 1, {
			Complete = function ()
				self:initAutoClose()
			end,
			hit1 = function ()
				self:playLevAction()
			end,
			hit2 = function ()
				self:playChangeLev()
			end
		})
	end)

	self.labelLev_.text = self.params_.oldLev
	local ExpPlayerTable = xyd.tables.expPlayerTable
	local reward = ExpPlayerTable:levelReward(self.params_.newLev)
	local num = 0

	for i = self.params_.oldLev + 1, self.params_.newLev do
		local reward = ExpPlayerTable:levelReward(i)
		num = num + reward[2]
	end

	self.labelNum_.text = "x" .. num

	self:adaptX()
end

function PersonLevUpWindow:adaptX()
	local screen = UnityEngine.Screen
	local top = 58
	local bottom = -58

	if xyd.Global.getMaxBgHeight() < screen.height then
		self.groupMain_:GetComponent(typeof(UIWidget)):SetTopAnchor(self.window_, 1, top)
		self.groupMain_:GetComponent(typeof(UIWidget)):SetBottomAnchor(self.window_, 0, bottom)
	elseif xyd.Global.getMaxHeight() < screen.height then
		local delta = screen.height / xyd.Global.getMaxBgHeight()

		self.groupMain_:GetComponent(typeof(UIWidget)):SetTopAnchor(self.window_, 1, top * delta)
		self.groupMain_:GetComponent(typeof(UIWidget)):SetBottomAnchor(self.window_, 0, bottom * delta)
	end
end

function PersonLevUpWindow:playLevAction()
	local lev = self.labelLev_
	local transform = self.labelLev_.transform

	transform:SetLocalScale(0.5, 0.5, 1)
	transform:SetActive(true)

	lev.alpha = 0.5
	local action2 = self:getSequence()

	action2:Append(transform:DOScale(Vector3(1.2, 1.2, 1), 0.2)):Join(xyd.getTweenAlpha(lev, 1, 0.2)):Append(transform:DOScale(Vector3(1, 1, 1), 0.1))
end

function PersonLevUpWindow:playChangeLev()
	local lev = self.labelLev_
	lev.text = self.params_.newLev
	local transform = self.labelLev_.transform

	transform:SetLocalScale(1.2, 1.2, 1)
	transform:SetActive(true)

	lev.alpha = 0.5
	local action2 = self:getSequence()

	action2:Append(transform:DOScale(Vector3(1, 1, 1), 0.2)):Join(xyd.getTweenAlpha(lev, 1, 0.2))
	self.labelNum_:SetActive(true)
end

function PersonLevUpWindow:initAutoClose()
	local key = "person_lev_up_wait_close"

	XYDCo.WaitForTime(1, function ()
		xyd.closeWindow(self.name_)
	end, key)
	self:addTimeKey(key)
end

function PersonLevUpWindow:willClose()
	BaseWindow.willClose(self)
	xyd.closeWindow("item_tips_window")

	local wnd = xyd.getWindow("guide_window")

	if wnd then
		wnd:playLevUpHide(false)
	end
end

function PersonLevUpWindow:excuteCallBack(isCloseAll)
	BaseWindow.excuteCallBack(self, isCloseAll)

	if isCloseAll then
		return
	end

	local info = xyd.models.activity:getActivity(xyd.ActivityID.LEVEL_FUND)
	local buy_times = nil

	if info and info.detail and info.detail.charges and info.detail.charges[1].buy_times then
		buy_times = info.detail.charges[1].buy_times

		if buy_times >= 1 then
			xyd.models.activity:reqActivityByID(xyd.ActivityID.LEVEL_FUND)
		end
	end
end

return PersonLevUpWindow
