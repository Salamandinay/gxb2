local ShrineHurdleInfoWindow = class("ShrineHurdleInfoWindow", import(".BaseWindow"))

function ShrineHurdleInfoWindow:ctor(name, params)
	ShrineHurdleInfoWindow.super.ctor(self, name, params)

	self.type_ = params.type
	self.closeAll = params.closeAll
end

function ShrineHurdleInfoWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:initNowBuffList()
	self:checkInGuide()
	self:register()
end

function ShrineHurdleInfoWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.btnOut_ = winTrans:NodeByName("btnOut").gameObject
	self.btnOutLabel_ = self.btnOut_:ComponentByName("label", typeof(UILabel))
	self.btnGo_ = winTrans:NodeByName("btnGo").gameObject
	self.btnGoLabel_ = self.btnGo_:ComponentByName("label", typeof(UILabel))
	self.helpBtn_ = self.window_:NodeByName("helpBtn").gameObject
	self.battleInfoGroup_ = winTrans:ComponentByName("battleInfoGroup", typeof(UIScrollView))
	local infoTrans = self.battleInfoGroup_.transform
	self.buffItem_ = infoTrans:NodeByName("buffItem").gameObject
	self.totalWidgt_ = infoTrans:ComponentByName("totalWidgt", typeof(UIWidget))
	local widgtTrans = self.totalWidgt_.transform
	self.textLabel1_ = widgtTrans:ComponentByName("labelGroup1/label", typeof(UILabel))
	self.textLabel2_ = widgtTrans:ComponentByName("labelGroup2/label", typeof(UILabel))
	self.textLabel3_ = widgtTrans:ComponentByName("labelGroup3/label", typeof(UILabel))
	self.textLabel4_ = widgtTrans:ComponentByName("labelGroup4/label", typeof(UILabel))
	self.textLabel5_ = widgtTrans:ComponentByName("labelGroup5/label", typeof(UILabel))
	self.environment1_ = widgtTrans:NodeByName("environment1").gameObject
	self.environment1Widgt = self.environment1_:GetComponent(typeof(UIWidget))
	self.imgIcon1_ = self.environment1_:ComponentByName("imgIcon", typeof(UISprite))
	self.labelName1_ = self.environment1_:ComponentByName("labelName", typeof(UILabel))
	self.labelDesc1_ = self.environment1_:ComponentByName("labelDesc", typeof(UILabel))
	self.environment2_ = widgtTrans:NodeByName("environment2").gameObject
	self.environment2Widgt = self.environment2_:GetComponent(typeof(UIWidget))
	self.imgIcon2_ = self.environment2_:ComponentByName("imgIcon", typeof(UISprite))
	self.labelName2_ = self.environment2_:ComponentByName("labelName", typeof(UILabel))
	self.labelDesc2_ = self.environment2_:ComponentByName("labelDesc", typeof(UILabel))
	self.buffGroup_ = widgtTrans:ComponentByName("buffGroup", typeof(UILayout))
end

function ShrineHurdleInfoWindow:layout()
	local diff = xyd.models.shrineHurdleModel:getDiffNum()
	self.textLabel1_.text = __("SHRINE_HURDLE_TEXT03") .. " : " .. diff
	local floor_id, floor_index, floorType = xyd.models.shrineHurdleModel:getFloorInfo()
	self.floor_id = floor_id
	local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()
	local ids = xyd.tables.shrineHurdleTable:getIDs()

	if guideIndex then
		ids = {
			1,
			2,
			3,
			4,
			5
		}
	end

	self.textLabel2_.text = __("SHRINE_HURDLE_TEXT09") .. " : " .. self.floor_id .. "/" .. #ids
	self.textLabel3_.text = __("SHRINE_HURDLE_TEXT10", " " .. xyd.models.shrineHurdleModel:getScore())
	self.textLabel4_.text = __("SHRINE_HURDLE_TEXT01")
	self.textLabel5_.text = __("SHRINE_HURDLE_TEXT11")
	self.titleLabel_.text = __("SHRINE_HURDLE_TEXT08")
	self.btnOutLabel_.text = __("SHRINE_HURDLE_TEXT18")
	self.btnGoLabel_.text = __("MUSIC_GAME_TEXT7")
	local count = xyd.models.shrineHurdleModel:getCount()
	count = math.fmod(count - 1, 3) + 1
	local route_id = xyd.models.shrineHurdleModel:getRouteID()

	if not route_id or route_id <= 0 then
		route_id = xyd.models.shrineHurdleModel:getLastRouteID()
	end

	local enviroments = xyd.tables.shrineHurdleRouteTable:getEnviroment(route_id, count)

	if guideIndex then
		enviroments = {
			500000,
			500001
		}
	end

	local icon1 = xyd.tables.skillTable:getSkillIcon(enviroments[1])
	local icon2 = xyd.tables.skillTable:getSkillIcon(enviroments[2])

	xyd.setUISpriteAsync(self.imgIcon1_, nil, icon1)
	xyd.setUISpriteAsync(self.imgIcon2_, nil, icon2)

	self.labelName1_.text = xyd.tables.shrineHurdleRouteTextTable:getName(enviroments[1])
	self.labelDesc1_.text = xyd.tables.shrineHurdleRouteTextTable:getDesc(enviroments[1])
	self.labelName2_.text = xyd.tables.shrineHurdleRouteTextTable:getName(enviroments[2])
	self.labelDesc2_.text = xyd.tables.shrineHurdleRouteTextTable:getDesc(enviroments[2])

	if self.labelDesc1_.height >= 54 then
		self.environment1Widgt.height = 106 + self.labelDesc1_.height - 46
	end

	if self.labelDesc1_.height < 36 then
		self.labelDesc1_.transform:Y(-56)
	end

	if self.labelDesc2_.height < 36 then
		self.labelDesc2_.transform:Y(-56)
		self.environment2Widgt:SetAnchor(self.environment1_, 0, 0, 0, -(118 + self.labelDesc2_.height - 26), 1, 0, 0, -12)
	else
		self.environment2Widgt:SetAnchor(self.environment1_, 0, 0, 0, -(118 + self.labelDesc2_.height - 46), 1, 0, 0, -12)
	end

	if self.type_ and self.type_ == 1 then
		self.btnOut_:SetActive(false)
		self.btnGo_.transform:X(0)

		self.btnGoLabel_.text = __("FOR_SURE")
	end
end

function ShrineHurdleInfoWindow:initNowBuffList()
	local skillList = xyd.models.shrineHurdleModel:getSkillList()
	local idList = {}

	for skill_id, skill_lv in pairs(skillList) do
		table.insert(idList, tonumber(skill_id))
	end

	table.sort(idList)

	for _, id in ipairs(idList) do
		local level = skillList[tostring(id)] or skillList[tonumber(id)]
		local newItem = NGUITools.AddChild(self.buffGroup_.gameObject, self.buffItem_)

		newItem:SetActive(true)

		local icon = newItem:ComponentByName("iconImg", typeof(UISprite))
		local labelName = newItem:ComponentByName("labelName", typeof(UILabel))
		local labelDesc = newItem:ComponentByName("labelDesc", typeof(UILabel))
		local skillNum = xyd.tables.shrineHurdleBuffTable:getSkillNum(id)[level]
		local addLevText = ""

		if level ~= 1 then
			addLevText = "+" .. level - 1
		end

		local skill_icon = xyd.tables.shrineHurdleBuffTable:getSkillIcon(id)

		xyd.setUISpriteAsync(icon, nil, skill_icon)

		labelDesc.text = xyd.tables.shrineHurdleBuffTextTable:getDesc(id, skillNum)
		labelName.text = xyd.tables.shrineHurdleBuffTextTable:getTitle(id) .. addLevText
		local height = labelDesc.height

		if height >= 60 then
			newItem:GetComponent(typeof(UIWidget)).height = 106 + height - 60
		elseif height <= 20 then
			labelDesc.transform:Y(-50)
		end

		self.buffGroup_:Reposition()
	end

	self.battleInfoGroup_:ResetPosition()
end

function ShrineHurdleInfoWindow:register()
	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnGo_).onClick = function ()
		self.closeAll = false

		self:close()
	end

	UIEventListener.Get(self.btnOut_).onClick = function ()
		xyd.alertYesNo(__("SHRINE_HURDLE_TEXT23"), function (yes_no)
			if yes_no then
				xyd.models.shrineHurdleModel:endHurdle()
				self:close()
			end
		end)
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SHRINE_HURDLE_HELP"
		})
	end
end

function ShrineHurdleInfoWindow:willClose(callback)
	if self.type_ and self.type_ == 1 then
		xyd.WindowManager.get():closeWindow("shrine_hurdle_window")
		xyd.models.shrineHurdleModel:onEndHurdle()

		local win = xyd.WindowManager.get():getWindow("shrine_hurdle_entrance_window")

		if win then
			win:hideMid()
		end

		local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()

		if guideIndex and guideIndex == 10 then
			xyd.models.shrineHurdleModel:setFlag(nil, 10)
		else
			xyd.models.shrineHurdleModel:checkUnlockStory(1)
		end
	end

	ShrineHurdleInfoWindow.super.willClose(self, callback)
end

function ShrineHurdleInfoWindow:close(callback, skipAnimation)
	if self.closeAll then
		xyd.WindowManager.get():closeWindow("shrine_hurdle_choose_buff_window")
		xyd.WindowManager.get():closeWindow("shrine_hurdle_window")
	end

	if skipAnimation == nil then
		skipAnimation = false
	end

	xyd.WindowManager.get():closeWindow(self.name_, callback, skipAnimation)
	self:cleanDefaultBgClick()
end

function ShrineHurdleInfoWindow:checkInGuide()
	local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()

	if guideIndex and guideIndex == 10 then
		xyd.WindowManager:get():openWindow("common_trigger_guide_window", {
			guide_type = xyd.CommonTriggerGuideType.SHRINE_HURDLE_8
		})
	end
end

return ShrineHurdleInfoWindow
