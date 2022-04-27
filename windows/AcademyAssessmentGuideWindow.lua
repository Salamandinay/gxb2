local BaseWindow = import(".BaseWindow")
local AcademyAssessmentGuideWindow = class("AcademyAssessmentGuideWindow", BaseWindow)

function AcademyAssessmentGuideWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.isGoOn = true
	self.params = params
	self.table_ = xyd.tables.academyAssessmentGuideTable
	self.skinName = "GuildGuideWindowSkin"

	if self.params then
		self.guideIds = self.params.guideIds

		if self.params.wnd then
			self.wnd = self.params.wnd
		end

		if self.params.table then
			self.table_ = self.params.table
		end
	end

	xyd.Global.initGuideMask()
end

function AcademyAssessmentGuideWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)

	local index = self:getFirsetIndex()

	self:runGuide(index)
end

function AcademyAssessmentGuideWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupGuideMask = winTrans:NodeByName("groupGuideMask").gameObject
	self.maskImage_ = winTrans:NodeByName("maskImage_").gameObject
	self.groupDialog_ = winTrans:NodeByName("groupDialog_").gameObject
	self.groupDialog1 = self.groupDialog_:NodeByName("groupDialog1").gameObject
	self.imgDialogBg1 = self.groupDialog1:NodeByName("imgDialogBg1").gameObject
	self.labelDesc1 = self.groupDialog1:ComponentByName("labelDesc1", typeof(UILabel))
	self.imgGirl_ = self.groupDialog_:NodeByName("imgGirl_").gameObject
end

function AcademyAssessmentGuideWindow:getFirsetIndex()
	return self.guideIds[1]
end

function AcademyAssessmentGuideWindow:checkGuideId(id)
	if xyd.arrayIndexOf(self.guideIds, id) <= 0 then
		return false
	else
		return true
	end

	return true
end

function AcademyAssessmentGuideWindow:playOpenAnimation(callback)
	AcademyAssessmentGuideWindow.super.playOpenAnimation(self, callback)
	self.imgGirl_:SetActive(true)
	self.groupDialog1:SetActive(false)
	self.imgGirl_:SetLocalScale(0.83, 0.83, 0.83)

	local action = self:getSequence(function ()
		self.groupDialog1:SetActive(true)
	end)

	action:Append(self.imgGirl_.transform:DOScale(0.83, 0.3))
	action:Append(self.imgGirl_.transform:DOScale(1.1, 0.1))
	action:Append(self.imgGirl_.transform:DOScale(1, 0.1))
	action:Append(self.imgGirl_.transform:DOScale(1, 0.1))
end

function AcademyAssessmentGuideWindow:runGuide(index)
	if self.isGoOn == false then
		return
	end

	if not self:checkGuideId(index) then
		self.isGoOn = false

		xyd.WindowManager.get():closeWindow(self.name_)

		return
	end

	self.curIndex = index
	local ids = self.table_:getIDs()

	if xyd.arrayIndexOf(ids, index) < 0 then
		xyd.WindowManager.get():closeWindow(self.name_)

		return
	end

	NGUITools.DestroyChildren(self.groupGuideMask.transform)

	local iconName = self.table_:getObjID(index)
	iconName = xyd.split(iconName, "|")
	local wnd = xyd.WindowManager.get():getWindow(self.table_:getWndName(index))

	if not wnd then
		self:waitForTime(0.05, function ()
			if xyd.WindowManager.get():getWindow(self.table_:getWndName(index)) then
				self:runGuide(self.curIndex)
			end
		end)

		return
	end

	self.wnd = wnd

	if tostring(iconName[1]) == "-1" then
		self.maskImage_:SetActive(true)

		self.maskImage_:GetComponent(typeof(UIWidget)).alpha = 0.5

		self:initDialog(index, self.wnd[tostring(iconName[#iconName])])

		UIEventListener.Get(self.maskImage_.gameObject).onClick = handler(self, function ()
			NGUITools.Destroy(self.maskImage_:GetComponent(typeof(UIEventListener)))
			self:runGuide(self:getNextId())
		end)
	else
		local specialAreaMask = self:getMaskByAlpha(0.5)

		specialAreaMask:ChangeParent(self.groupGuideMask)
		self.maskImage_:SetActive(false)

		self.specialAreaMask_ = specialAreaMask
		local obj = self.wnd[tostring(iconName[#iconName])]
		local pos = self.window_.transform:InverseTransformPoint(obj.transform.position)

		self.specialAreaMask_:updateMask2({
			{
				pos = {
					x = pos.x,
					y = pos.y
				},
				icon = self.table_:getMaskIcon(index),
				iconOffset = {
					0,
					0
				}
			}
		})

		if iconName[1] == "scroller_guide" and self.wnd[tostring(iconName[1])] then
			self.wnd[tostring(iconName[1])].enabled = false
		end

		self:initDialog(index, self.wnd[tostring(iconName[#iconName])])

		for i = 2, #iconName do
			UIEventListener.Get(self.wnd[tostring(iconName[i])].gameObject).guideClick = handler(self, function ()
				if self.wnd and iconName[1] == "scroller_guide" and self.wnd[tostring(iconName[1])] then
					self.wnd[tostring(iconName[1])].enabled = true
				end

				xyd.Global.guideMask05:removeFromParent()
				self:runGuide(self:getNextId())
			end)
		end
	end
end

function AcademyAssessmentGuideWindow:getNextId()
	for i in pairs(self.guideIds) do
		if self.curIndex == self.guideIds[i] then
			if i < #self.guideIds then
				return self.guideIds[i + 1]
			else
				return -1
			end
		end
	end
end

function AcademyAssessmentGuideWindow:getMaskByAlpha(alpha)
	if alpha == 0.5 then
		return xyd.Global.guideMask05
	end

	return xyd.Global.guideMask001
end

function AcademyAssessmentGuideWindow:initDialog(index, obj)
	local desc = self.table_:getDesc(index)
	local type_ = self.table_:getDialogType(index)

	if desc and desc ~= "" then
		self.groupDialog_:SetActive(true)

		self.labelDesc1.text = desc

		if obj then
			local tmpPos = self.window_.transform:InverseTransformPoint(obj.transform.position)
			local excelPos = self.table_:getPosition(index)

			self.groupDialog_:X(tmpPos.x + excelPos[1])
			self.groupDialog_:Y(tmpPos.y + excelPos[2])
		else
			self.groupDialog_:X(0)
			self.groupDialog_:Y(0)
		end
	else
		self.groupDialog_:SetActive(false)
	end

	local sound = self.table_:getSound(index)

	if sound and sound > 0 then
		xyd.SoundManager.get():playSound(string(sound))
	end
end

function AcademyAssessmentGuideWindow:willClose(params, skipAnimation, force)
	BaseWindow.willClose(self, params, skipAnimation, force)

	local wnd = xyd.WindowManager.get():getWindow("academy_assessment_window")
	local wnd1 = xyd.WindowManager.get():getWindow("academy_assessment_detail_window")

	if wnd then
		wnd:enableScroller(true)
	end

	if wnd1 then
		wnd1:enableScroller(true)
	end
end

return AcademyAssessmentGuideWindow
