local ActivityMonthlyHikeSkillWindow = class("ActivityMonthlyHikeSkillWindow", import(".BaseWindow"))
local SkillIcon = class("SkillIcon", import("app.components.CopyComponent"))

function ActivityMonthlyHikeSkillWindow:ctor(name, params)
	ActivityMonthlyHikeSkillWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.MONTHLY_HIKE)
	self.skillInfo_ = self.activityData:getActivityInfo()
	self.skillPoint_ = self.activityData.detail.skill_point
	self.skillIconList_ = {}
	self.partLockItem_ = {}
end

function ActivityMonthlyHikeSkillWindow:initWindow()
	ActivityMonthlyHikeSkillWindow.super.initWindow(self)

	self.skillIconList = {}

	self:getUIComponent()

	self.btnSureLabel.text = __("SURE")
	self.btnCloseLabel.text = __("ACTIVITY_MONTHLY_TEXT005")
	self.titleLabel.text = __("ACTIVITY_MONTHLY_HIKE_SKILL_WINDOW")
	self.skillTips.text = __("ACTIVITY_MONTHLY_TEXT008")

	self:layout()
	self:register()
end

function ActivityMonthlyHikeSkillWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.helpBtn_ = winTrans:NodeByName("helpBtn").gameObject
	self.titleLabel = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.labelTips = winTrans:ComponentByName("labelTips", typeof(UILabel))
	self.skillNumLabel = winTrans:ComponentByName("skillCost/label", typeof(UILabel))
	self.skillTips = winTrans:ComponentByName("skillCost/labelTips", typeof(UILabel))
	self.exchangeBtn = winTrans:NodeByName("skillCost/exchangeBtn").gameObject
	self.scrollView = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid = winTrans:ComponentByName("scrollView/layout", typeof(UILayout))
	self.skillPart = winTrans:NodeByName("skillPart").gameObject
	self.skillGroup = winTrans:NodeByName("skillGroup").gameObject
	self.skillIcon = winTrans:NodeByName("skillIcon").gameObject
	self.btnSure = winTrans:NodeByName("btnSure").gameObject
	self.btnSureLabel = winTrans:ComponentByName("btnSure/label", typeof(UILabel))
	self.btnClose = winTrans:NodeByName("btnClose").gameObject
	self.btnCloseLabel = winTrans:ComponentByName("btnClose/label", typeof(UILabel))
end

function ActivityMonthlyHikeSkillWindow:register()
	ActivityMonthlyHikeSkillWindow.super.register(self)

	UIEventListener.Get(self.btnClose).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnSure).onClick = function ()
		self:changeSkillLev()
	end

	UIEventListener.Get(self.exchangeBtn).onClick = handler(self, self.onTouchRefresh)

	self.eventProxy_:addEventListener(xyd.event.BOSS_NEW_ADD_SKILLS, handler(self, self.onSkillAdd))
	self.eventProxy_:addEventListener(xyd.event.BOSS_NEW_RESET_SKILLS, handler(self, self.onSkillChange))

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		local params = {
			key = "ACTIVITY_MONTHLY_HIKE_SKILL_HELP"
		}

		xyd.WindowManager.get():openWindow("help_window", params)
	end
end

function ActivityMonthlyHikeSkillWindow:onTouchRefresh()
	local canReset = false

	for id, icon in ipairs(self.skillIconList_) do
		if icon:getNowLev() > 0 then
			canReset = true

			break
		end
	end

	if not canReset then
		xyd.alertTips(__("ACTIVITY_MONTHLY_HIKE_SKILL_3"))

		return
	end

	local canFree = self.activityData:getCanFreeReset()

	local function yesFunction(yes)
		if not yes then
			return
		end

		local msg = messages_pb.boss_new_reset_skills_req()
		msg.activity_id = xyd.ActivityID.MONTHLY_HIKE

		xyd.Backend.get():request(xyd.mid.BOSS_NEW_RESET_SKILLS, msg)
	end

	if canFree then
		xyd.alertYesNo(__("ACTIVITY_MONTHLY_HIKE_SKILL_1"), function (yes)
			yesFunction(yes)
		end)
	else
		local setTime = xyd.db.misc:getValue("monthly_hike_time_stamp")

		if setTime and xyd.isSameDay(tonumber(setTime), xyd.getServerTime()) then
			yesFunction(true)
		else
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "monthly_hike",
				wndType = self.curWindowType_,
				callback = function ()
					yesFunction(true)
				end
			})
		end
	end
end

function ActivityMonthlyHikeSkillWindow:onSkillAdd()
	xyd.alertTips(__("ACTIVITY_MONTHLY_HIKE_SKILL_4"))

	self.skillPoint_ = self.activityData.detail.skill_point
	self.skillInfo_ = self.activityData:getActivityInfo()

	self:updateSkillIcons(true)
	self:updateSkillNum()
end

function ActivityMonthlyHikeSkillWindow:onSkillChange()
	xyd.alertTips(__("ACTIVITY_MONTHLY_HIKE_SKILL_5"))

	self.skillPoint_ = self.activityData.detail.skill_point
	self.skillInfo_ = self.activityData:getActivityInfo()

	self:updateSkillIcons(true)
	self:updateSkillNum()
	self:updateLockPart()
end

function ActivityMonthlyHikeSkillWindow:layout()
	local lists = xyd.tables.activityMonthlySkillTable:getIDsByArea()

	for index, list in ipairs(lists) do
		local skillIconPos = {}
		local newPart = NGUITools.AddChild(self.grid.gameObject, self.skillPart)

		newPart:SetActive(true)

		local bgwidgt = newPart:GetComponent(typeof(UIWidget))
		local bgImg = newPart:ComponentByName("bgImg", typeof(UISprite))

		xyd.setUISpriteAsync(bgImg, nil, "monthly_skill_bg" .. index)

		local grid = newPart:ComponentByName("skillGrid", typeof(UIGrid))
		local gridNum = self:getGridNum(list)
		bgImg.height = 2 + 181 * gridNum
		bgwidgt.height = 2 + 181 * gridNum
		local startGrid = xyd.tables.activityMonthlySkillTable:getPos(list[1])[1]

		if index > 1 then
			local lockGroup = newPart:NodeByName("lockGroup").gameObject

			lockGroup:SetActive(true)

			local lockLabel = newPart:ComponentByName("lockGroup/labelNum", typeof(UILabel))
			local lockImg1 = newPart:ComponentByName("lockGroup/lockImg", typeof(UISprite))
			local lockImg2 = newPart:ComponentByName("lockGroup/lockImg2", typeof(UISprite))

			table.insert(self.partLockItem_, {
				id = index,
				lockImg1 = lockImg1,
				lockImg2 = lockImg2,
				lockLabel = lockLabel
			})
		end

		if index >= 2 then
			grid.transform:Y(-100)
		end

		for i = 1, gridNum do
			skillIconPos[i] = {}
			local skillGroup = NGUITools.AddChild(grid.gameObject, self.skillGroup)

			for j = 1, 3 do
				skillIconPos[i][j] = skillGroup:NodeByName("skillPos" .. j).gameObject
			end
		end

		for index, id in ipairs(list) do
			local pos = xyd.tables.activityMonthlySkillTable:getPos(id)
			local posRoot = skillIconPos[pos[1] - startGrid + 1][pos[2]]
			local iconRoot = NGUITools.AddChild(posRoot, self.skillIcon)

			iconRoot:SetActive(true)

			self.skillIconList_[id] = SkillIcon.new(iconRoot, self)

			self.skillIconList_[id]:setInfo(self.skillInfo_[id], id)
		end
	end

	self.grid:Reposition()
	self.scrollView:ResetPosition()
	self:updateSkillNum()
	self:updateLockPart()
end

function ActivityMonthlyHikeSkillWindow:updateLockPart()
	for _, part in ipairs(self.partLockItem_) do
		local area_id = part.id
		local area_limit_list = xyd.split(xyd.tables.miscTable:getVal("activity_monthly_skill_limit"), "|", true)
		local limitNum = area_limit_list[area_id]
		local hasAddNum = self:getTotalNumBefroeArea(area_id)

		if limitNum <= hasAddNum then
			hasAddNum = limitNum

			xyd.setUISpriteAsync(part.lockImg1, nil, "monthly_skill_lock_img1")
			xyd.setUISpriteAsync(part.lockImg2, nil, "monthly_skill_lock_img1")

			part.lockLabel.text = hasAddNum .. "/" .. limitNum
		else
			part.lockLabel.text = "[c][CC0011]" .. hasAddNum .. "[-][/c]" .. "/" .. limitNum

			xyd.setUISpriteAsync(part.lockImg1, nil, "monthly_skill_lock_img2")
			xyd.setUISpriteAsync(part.lockImg2, nil, "monthly_skill_lock_img2")
		end
	end
end

function ActivityMonthlyHikeSkillWindow:getGridNum(list)
	local maxGrid = 1
	local startGrid = xyd.tables.activityMonthlySkillTable:getPos(list[1])[1]

	for _, id in ipairs(list) do
		local pos = xyd.tables.activityMonthlySkillTable:getPos(id)

		if maxGrid < pos[1] then
			maxGrid = pos[1]
		end
	end

	return maxGrid - startGrid + 1
end

function ActivityMonthlyHikeSkillWindow:checkSkillCanAdd(id)
	local area_id = xyd.tables.activityMonthlySkillTable:getSkillArea(id)
	local area_limit_list = xyd.split(xyd.tables.miscTable:getVal("activity_monthly_skill_limit"), "|", true)
	local limitNum = area_limit_list[area_id]
	local totalNum = self:getTotalNumBefroeArea(area_id)

	if totalNum < limitNum then
		return false
	end

	local limitSkill = xyd.tables.activityMonthlySkillTable:getLimit(id)

	for _, limitInfo in ipairs(limitSkill) do
		local skill_id = limitInfo[1]

		if self.skillIconList_[skill_id] and self.skillIconList_[skill_id]:getLev() < limitInfo[2] then
			return false
		elseif not self.skillIconList_[skill_id] and self.skillInfo_[skill_id] < limitInfo[2] then
			return false
		end
	end

	return true
end

function ActivityMonthlyHikeSkillWindow:getTotalNumBefroeArea(area_id)
	local lists = xyd.tables.activityMonthlySkillTable:getIDsByArea()
	local num = 0

	for index, list in ipairs(lists) do
		if index < area_id then
			for _, id in ipairs(list) do
				if self.skillIconList_[id] then
					num = self.skillIconList_[id]:getLev() + num
				else
					num = self.skillInfo_[id] + num
				end
			end
		end
	end

	return num
end

function ActivityMonthlyHikeSkillWindow:changeSkillLev()
	self.changeList_ = {}

	for id, icon in ipairs(self.skillIconList_) do
		if icon:getAddLev() > 0 then
			table.insert(self.changeList_, {
				id = id,
				num = icon:getAddLev()
			})
		end
	end

	table.sort(self.changeList_, function (a, b)
		local areaA = xyd.tables.activityMonthlySkillTable:getSkillArea(a.id)
		local areaB = xyd.tables.activityMonthlySkillTable:getSkillArea(b.id)

		if areaA < areaB then
			return true
		else
			return a.id < b.id
		end
	end)

	local timeStamp = xyd.db.misc:getValue("monthly_hike_skill_time_stamp")

	local function changeFunction()
		local msg = messages_pb.boss_new_add_skills_req()
		msg.activity_id = xyd.ActivityID.MONTHLY_HIKE

		for _, skillInfo in ipairs(self.changeList_) do
			local add_skill = messages_pb.boss_new_skills()
			add_skill.id = skillInfo.id
			add_skill.num = skillInfo.num

			table.insert(msg.skills, add_skill)
		end

		xyd.Backend:get():request(xyd.mid.BOSS_NEW_ADD_SKILLS, msg)
	end

	if #self.changeList_ > 0 then
		if not timeStamp or not xyd.isSameDay(timeStamp, xyd.getServerTime()) then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "monthly_hike_skill",
				text = __("ACTIVITY_MONTHLY_TEXT004"),
				callback = changeFunction
			})
		else
			changeFunction()
		end
	else
		self:close()
	end
end

function ActivityMonthlyHikeSkillWindow:updateSkillIcons(addToZero)
	local lists = xyd.tables.activityMonthlySkillTable:getIDsByArea()

	for index, list in ipairs(lists) do
		for index, id in ipairs(list) do
			if self.skillIconList_[id] then
				self.skillIconList_[id]:updateSkillIcon(self.skillInfo_[id], xyd.checkCondition(addToZero, 0, nil))
			end
		end
	end
end

function ActivityMonthlyHikeSkillWindow:updateSkillInfo(changeLev)
	if self.skillPoint_ - changeLev >= 0 then
		self.skillPoint_ = self.skillPoint_ - changeLev

		self:updateSkillNum()

		return true
	else
		return false
	end
end

function ActivityMonthlyHikeSkillWindow:updateSkillNum()
	self.skillNumLabel.text = self.skillPoint_
end

function SkillIcon:ctor(go, parent)
	self.parent_ = parent
	self.addLev = 0

	SkillIcon.super.ctor(self, go)
end

function SkillIcon:initUI()
	local goTrans = self.go.transform
	self.skillIconImg = goTrans:ComponentByName("icon", typeof(UISprite))
	self.leftBtn = goTrans:ComponentByName("leftBtn", typeof(UISprite))
	self.rightBtn = goTrans:ComponentByName("rightBtn", typeof(UISprite))
	self.lineImg = goTrans:ComponentByName("lineImg", typeof(UISprite))
	self.levBg = goTrans:ComponentByName("levGroup", typeof(UISprite))
	self.levLabel = goTrans:ComponentByName("levGroup/levLabel", typeof(UILabel))
	self.lockGroup = goTrans:NodeByName("lockImg").gameObject
	self.lockLabel = goTrans:ComponentByName("lockImg/label", typeof(UILabel))

	UIEventListener.Get(self.leftBtn.gameObject).onClick = function ()
		self:changeAddLev(-1)
	end

	UIEventListener.Get(self.rightBtn.gameObject).onClick = function ()
		self:changeAddLev(1)
	end

	UIEventListener.Get(self.rightBtn.gameObject).onPress = handler(self, self.rightBtnLongPress)
	UIEventListener.Get(self.leftBtn.gameObject).onPress = handler(self, self.leftBtnLongPress)

	UIEventListener.Get(self.go).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_monthly_hike_skill_detail_window", {
			skill_id = self.id_,
			icon_item = self,
			lev = self.lev_
		})
	end
end

function SkillIcon:rightBtnLongPress(go, isPressed)
	local longTouchFunc = nil

	function longTouchFunc()
		if self.levUpLongTouchFlag == true then
			self:changeAddLev(1)
			self:waitForTime(0.1, function ()
				if not self or not go or go.activeSelf == false and self.levUpLongTouchFlag then
					return
				end

				longTouchFunc()
			end, "levUpLongTouch")
		end
	end

	if isPressed then
		self.levUpLongTouchFlag = true

		self:waitForTime(0.3, function ()
			if not self then
				return
			end

			if self.levUpLongTouchFlag then
				longTouchFunc()
			end
		end, "levUpLongTouch")
	else
		XYDCo.StopWait("levUpLongTouch")

		self.levUpLongTouchFlag = false
	end
end

function SkillIcon:leftBtnLongPress(go, isPressed)
	local longTouchFunc = nil

	function longTouchFunc()
		if self.levDownLongTouchFlag == true then
			self:changeAddLev(-1)
			self:waitForTime(0.1, function ()
				if not self or not go or go.activeSelf == false and self.levDownLongTouchFlag then
					return
				end

				longTouchFunc()
			end, "levDownLongTouch")
		end
	end

	if isPressed then
		self.levDownLongTouchFlag = true

		self:waitForTime(0.3, function ()
			if not self then
				return
			end

			if self.levDownLongTouchFlag then
				longTouchFunc()
			end
		end, "levDownLongTouch")
	else
		XYDCo.StopWait("levDownLongTouch")

		self.levDownLongTouchFlag = false
	end
end

function SkillIcon:setInfo(skill_lev, id)
	self.id_ = id
	self.lev_ = skill_lev or 0
	local iconName = xyd.tables.activityMonthlySkillTable:getIconImg(self.id_)

	xyd.setUISpriteAsync(self.skillIconImg, nil, iconName)
	self:updateLine()
	self:updateLevLabel()
end

function SkillIcon:updateSkillIcon(skill_lev, add_lev)
	if skill_lev then
		self.lev_ = skill_lev
	end

	if add_lev then
		self.addLev = add_lev
	end

	if not self:checkCanAdd() then
		self.parent_.skillPoint_ = self.parent_.skillPoint_ + self.addLev

		self.parent_:updateSkillNum()

		self.addLev = 0
	end

	self:updateLine()
	self:updateLevLabel()
end

function SkillIcon:changeAddLev(lev)
	local maxLev = xyd.tables.activityMonthlySkillTable:getLevMax(self.id_)

	if self.addLev + lev + self.lev_ < 0 then
		XYDCo.StopWait("levDownLongTouch")

		self.levDownLongTouchFlag = false

		return
	elseif maxLev < self.addLev + lev + self.lev_ then
		XYDCo.StopWait("levUpLongTouch")

		self.levUpLongTouchFlag = false

		return
	end

	if not self:checkCanAdd() then
		return
	end

	if self.parent_:updateSkillInfo(lev) then
		self.addLev = self.addLev + lev

		self:updateLevLabel()
		self:updateLine()
		self.parent_:updateLockPart()
		self.parent_:updateSkillIcons(false)
	end
end

function SkillIcon:getSkillLev()
	return self.lev_ + self.addLev
end

function SkillIcon:getAddLev()
	return self.addLev
end

function SkillIcon:updateLevLabel()
	local maxLev = xyd.tables.activityMonthlySkillTable:getLevMax(self.id_)
	local levNow = self.lev_

	if self.addLev > 0 then
		self.levLabel.text = levNow .. "([c][3FFF2C]+" .. self.addLev .. "[-][/c])/" .. maxLev
		self.levBg.width = 88
	else
		self.levLabel.text = levNow .. "/" .. maxLev
		self.levBg.width = 78
	end
end

function SkillIcon:checkCanAdd()
	return self.parent_:checkSkillCanAdd(self.id_)
end

function SkillIcon:updateLine()
	local followIDs = xyd.tables.activityMonthlySkillTable:getFollowID(self.id_)

	if not followIDs[1] or followIDs[1] < 0 then
		self.lineImg.gameObject:SetActive(false)
		self.lockGroup:SetActive(false)
	elseif followIDs[1] and followIDs[1] > 0 and not followIDs[2] then
		local limits = xyd.tables.activityMonthlySkillTable:getLimit(followIDs[1])

		if #limits <= 1 then
			self.lineImg.gameObject:SetActive(true)

			if self.id_ == limits[1][1] and limits[1][2] <= self:getSkillLev() then
				xyd.setUISpriteAsync(self.lineImg, nil, "monthly_skill_line_1_1")
				self.lockGroup:SetActive(false)
			else
				xyd.setUISpriteAsync(self.lineImg, nil, "monthly_skill_line_1_2")
				self.lockGroup:SetActive(true)
			end

			self.lineImg.transform:X(-4)
			self.lineImg.transform:Y(-45)

			self.lineImg.width = 8
			self.lineImg.height = 90

			self.lockGroup.transform:Y(-84)
			self.lockGroup.transform:X(0)
		else
			local pos = xyd.tables.activityMonthlySkillTable:getPos(followIDs[1])

			self.lineImg.gameObject:SetActive(true)

			local fangxiang = 1

			if xyd.tables.activityMonthlySkillTable:getPos(self.id_)[2] < pos[2] then
				fangxiang = -1
			end

			if self.id_ == limits[1][1] and limits[1][2] <= self:getSkillLev() or self.id_ == limits[2][1] and limits[2][2] <= self:getSkillLev() then
				xyd.setUISpriteAsync(self.lineImg, nil, "monthly_skill_line_4_1")

				self.lineImg.depth = 5

				self.lockGroup:SetActive(false)
			else
				xyd.setUISpriteAsync(self.lineImg, nil, "monthly_skill_line_4_2")

				self.lineImg.depth = 6

				self.lockGroup:SetActive(true)
			end

			self.lineImg.transform.localScale = Vector3(fangxiang, 1, 1)

			self.lineImg.transform:X(-230.5 * fangxiang)
			self.lineImg.transform:Y(-45)

			self.lineImg.width = 234
			self.lineImg.height = 90

			self.lockGroup.transform:Y(-91)
			self.lockGroup.transform:X(-fangxiang * 110)
		end
	elseif followIDs[1] and followIDs[1] > 0 and followIDs[2] and followIDs[2] > 0 then
		self.lineImg.width = 476
		self.lineImg.height = 90
		self.lineImg.transform.localScale = Vector3(1, -1, 1)

		self.lineImg.transform:X(-234)
		self.lineImg.transform:Y(-125)

		if self.parent_:checkSkillCanAdd(followIDs[1]) then
			xyd.setUISpriteAsync(self.lineImg, nil, "monthly_skill_line_3_1")
			self.lockGroup:SetActive(false)
		else
			xyd.setUISpriteAsync(self.lineImg, nil, "monthly_skill_line_3_2")
			self.lockGroup:SetActive(true)
		end

		self.lockGroup.transform:Y(-80)
		self.lockGroup.transform:X(0)
	end

	local unlockLev = 0
	local limits = xyd.tables.activityMonthlySkillTable:getLimit(followIDs[1])

	if limits and followIDs[1] then
		for _, lock_info in ipairs(limits) do
			if lock_info[1] == self.id_ then
				unlockLev = lock_info[2]

				break
			end
		end
	end

	self.lockLabel.text = __("ACTIVITY_LAFULI_DRIFT_LV", unlockLev)

	self:updateBtn()
end

function SkillIcon:updateBtn()
	local showBtn = false

	if self:checkCanAdd() then
		self.leftBtn.gameObject:SetActive(true)
		self.rightBtn.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.levBg, nil, "monthly_stage_bg_xx")
	else
		self.leftBtn.gameObject:SetActive(false)
		self.rightBtn.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.levBg, nil, "monthly_stage_bg_xx_black")
	end

	local maxLev = xyd.tables.activityMonthlySkillTable:getLevMax(self.id_)

	if self.addLev == 0 then
		self.leftBtn.color = Color.New2(255)
		self.leftBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	else
		self.leftBtn.color = Color.New2(4294967295.0)
		self.leftBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end

	if maxLev <= self:getSkillLev() then
		self.rightBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		self.rightBtn.color = Color.New2(255)
	else
		self.rightBtn.color = Color.New2(4294967295.0)
		self.rightBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end
end

function SkillIcon:getAddLev()
	return self.addLev
end

function SkillIcon:getLev()
	return self.addLev + self.lev_
end

function SkillIcon:getNowLev()
	return self.lev_
end

return ActivityMonthlyHikeSkillWindow
