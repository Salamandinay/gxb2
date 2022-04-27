local ActivityMonthlyHikeSkillDetailWindow = class("ActivityMonthlyHikeSkillDetailWindow", import(".BaseWindow"))
local SkillIcon = class("SkillIcon", import("app.components.CopyComponent"))

function ActivityMonthlyHikeSkillDetailWindow:ctor(name, params)
	ActivityMonthlyHikeSkillDetailWindow.super.ctor(self, name, params)

	self.id_ = params.skill_id
	self.lev_ = params.lev
	self.targertIcon_ = params.icon_item
	self.addLev_ = self.targertIcon_:getAddLev()
	self.winSkill_ = xyd.WindowManager.get():getWindow("activity_monthly_hike_skill_window")
end

function ActivityMonthlyHikeSkillDetailWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:updateSkillNum()
end

function ActivityMonthlyHikeSkillDetailWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.labelNum = winTrans:ComponentByName("skillGroup/labelNum", typeof(UILabel))
	self.nameLabel = winTrans:ComponentByName("skillIcon/nameLabel", typeof(UILabel))
	self.skillIcon = winTrans:ComponentByName("skillIcon/icon", typeof(UISprite))
	self.leftBtn = winTrans:ComponentByName("skillIcon/leftBtn", typeof(UISprite))
	self.rightBtn = winTrans:ComponentByName("skillIcon/rightBtn", typeof(UISprite))
	self.levLabel = winTrans:ComponentByName("skillIcon/levLabel", typeof(UILabel))
	self.labelDesc = winTrans:ComponentByName("labelDesc", typeof(UILabel))
	self.labelTitle = winTrans:ComponentByName("groupLev/labelTitle", typeof(UILabel))
	self.levDescItem = winTrans:NodeByName("groupLev/levDescItem").gameObject

	self.levDescItem:SetActive(false)

	self.scrollView = winTrans:ComponentByName("groupLev/scrollView", typeof(UIScrollView))
	self.grid = winTrans:ComponentByName("groupLev/scrollView/grid", typeof(UIGrid))

	UIEventListener.Get(self.leftBtn.gameObject).onClick = function ()
		self:changeAddLev(-1)
	end

	UIEventListener.Get(self.rightBtn.gameObject).onClick = function ()
		self:changeAddLev(1)
	end
end

function ActivityMonthlyHikeSkillDetailWindow:changeAddLev(lev)
	local maxLev = xyd.tables.activityMonthlySkillTable:getLevMax(self.id_)

	if self.addLev_ + lev + self.lev_ < 0 then
		return
	elseif maxLev < self.addLev_ + lev + self.lev_ then
		return
	end

	if not self:checkCanAdd(self.id_) then
		return
	end

	if self.winSkill_:updateSkillInfo(lev) then
		self.addLev_ = self.addLev_ + lev

		self:updateLevLabel()

		self.targertIcon_.addLev = self.addLev_

		self.targertIcon_:updateLevLabel()
		self:updateSkillNum()
		self.winSkill_:updateLockPart()
		self:updateLevDesc()

		local maxLev = xyd.tables.activityMonthlySkillTable:getLevMax(self.id_)

		if self.addLev_ == 0 then
			self.leftBtn.color = Color.New2(255)
			self.leftBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		else
			self.leftBtn.color = Color.New2(4294967295.0)
			self.leftBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		end

		if maxLev <= self.lev_ + self.addLev_ then
			self.rightBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
			self.rightBtn.color = Color.New2(255)
		else
			self.rightBtn.color = Color.New2(4294967295.0)
			self.rightBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		end
	end
end

function ActivityMonthlyHikeSkillDetailWindow:updateSkillNum()
	self.labelNum.text = self.winSkill_.skillPoint_
end

function ActivityMonthlyHikeSkillDetailWindow:checkCanAdd(id)
	return self.winSkill_:checkSkillCanAdd(id)
end

function ActivityMonthlyHikeSkillDetailWindow:layout()
	self.labelTitle.text = __("ACTIVITY_MONTHLY_TEXT003")
	local iconName = xyd.tables.activityMonthlySkillTable:getIconImg(self.id_)

	xyd.setUISpriteAsync(self.skillIcon, nil, iconName)

	self.nameLabel.text = xyd.tables.activityMonthlySkillTable:getSkillName(self.id_)

	if self:checkCanAdd(self.id_) then
		self.leftBtn.gameObject:SetActive(true)
		self.rightBtn.gameObject:SetActive(true)
		self.levLabel.transform:X(170)
	else
		self.leftBtn.gameObject:SetActive(false)
		self.rightBtn.gameObject:SetActive(false)
		self.levLabel.transform:X(105.5)
	end

	local maxLev = xyd.tables.activityMonthlySkillTable:getLevMax(self.id_)

	if self.addLev_ == 0 then
		self.leftBtn.color = Color.New2(255)
		self.leftBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	else
		self.leftBtn.color = Color.New2(4294967295.0)
		self.leftBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end

	if maxLev <= self.lev_ + self.addLev_ then
		self.rightBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		self.rightBtn.color = Color.New2(255)
	else
		self.rightBtn.color = Color.New2(4294967295.0)
		self.rightBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end

	self:updateLevLabel()
	self:updateDescList()
end

function ActivityMonthlyHikeSkillDetailWindow:updateLevLabel()
	local maxLev = xyd.tables.activityMonthlySkillTable:getLevMax(self.id_)
	local levNow = self.lev_

	if self.addLev_ > 0 then
		self.levLabel.text = __("ACTIVITY_MONTHLY_TEXT006", levNow .. "[c][31D229](+" .. self.addLev_ .. ")[-][/c]/" .. maxLev)
	else
		self.levLabel.text = __("ACTIVITY_MONTHLY_TEXT006", levNow .. "/" .. maxLev)
	end
end

function ActivityMonthlyHikeSkillDetailWindow:updateDescList()
	self:updateLevDesc()

	local levMax = xyd.tables.activityMonthlySkillTable:getLevMax(self.id_)

	for i = 1, levMax do
		local newItem = NGUITools.AddChild(self.grid.gameObject, self.levDescItem)

		if i == self.lev_ then
			local bg = newItem:ComponentByName("bg", typeof(UISprite))

			xyd.setUISprite(bg, nil, "9gongge31")
		end

		local levLabel = newItem:ComponentByName("levBg/label", typeof(UILabel))
		local descLabel = newItem:ComponentByName("descLabel", typeof(UILabel))
		levLabel.text = __("ACTIVITY_LAFULI_DRIFT_LV", i)
		descLabel.text = xyd.tables.activityMonthlySkillTable:getDescText(self.id_, i)

		self.grid:Reposition()
	end

	self.scrollView:ResetPosition()

	if self.lev_ > 0 then
		self:waitForFrame(1, function ()
			local moveY = 0

			if self.lev_ == 4 then
				moveY = 51
			elseif self.lev_ == 5 then
				moveY = 130
			end

			local sp = self.scrollView.gameObject:GetComponent(typeof(SpringPanel))
			local initPos = self.scrollView.transform.localPosition.y
			local dis = initPos + moveY

			sp.Begin(sp.gameObject, Vector3(0, dis, 0), 80)
		end)
	end
end

function ActivityMonthlyHikeSkillDetailWindow:updateLevDesc()
	self.labelDesc.text = xyd.tables.activityMonthlySkillTable:getDescText(self.id_, self.addLev_ + self.lev_)
end

return ActivityMonthlyHikeSkillDetailWindow
