local BaseWindow = import(".BaseWindow")
local SoulEquipAutoChoooseWindow = class("SoulEquipAutoChoooseWindow", BaseWindow)

function SoulEquipAutoChoooseWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.equip = params.equip
	self.onlyMaterial = true
	self.starArr = {
		[1.0] = 1,
		[2.0] = 1
	}
	self.TargetLevel = self.equip:getLevel() + 1
end

function SoulEquipAutoChoooseWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function SoulEquipAutoChoooseWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.baseGroup = self.groupAction:NodeByName("baseGroup").gameObject
	self.labelWindowTitle = self.baseGroup:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = self.baseGroup:NodeByName("closeBtn").gameObject
	self.typeGroup = self.groupAction:NodeByName("typeGroup").gameObject
	self.labelTitle1 = self.typeGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.bg = self.labelTitle1:ComponentByName("bg", typeof(UISprite))
	self.tabMaterial = self.typeGroup:NodeByName("tabMaterial").gameObject
	self.labelTabMaterial = self.tabMaterial:ComponentByName("label", typeof(UILabel))
	self.tabChosenMaterial = self.tabMaterial:ComponentByName("chosen", typeof(UISprite))
	self.tabAll = self.typeGroup:NodeByName("tabAll").gameObject
	self.labelTabAll = self.tabAll:ComponentByName("label", typeof(UILabel))
	self.tabChosenAll = self.tabAll:ComponentByName("chosen", typeof(UISprite))
	self.starGroup = self.groupAction:NodeByName("starGroup").gameObject
	self.labelTitle2 = self.starGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.btnContent = self.starGroup:NodeByName("btnContent").gameObject
	self.btnContentLayout = self.starGroup:ComponentByName("btnContent", typeof(UILayout))

	for i = 1, 6 do
		self["star" .. i] = self.btnContent:NodeByName("star" .. i).gameObject
		self["btnStar" .. i] = self["star" .. i]:NodeByName("btnIcon").gameObject
		self["chosen" .. i] = self["star" .. i]:ComponentByName("chosen", typeof(UISprite))
	end

	self.levelGroup = self.groupAction:NodeByName("levelGroup").gameObject
	self.labelTitle3 = self.levelGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.numPos = self.levelGroup:NodeByName("numPos").gameObject
	self.btnSure = self.groupAction:NodeByName("btnSure").gameObject
	self.labelSure = self.btnSure:ComponentByName("labelSure", typeof(UILabel))
end

function SoulEquipAutoChoooseWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.tabMaterial).onClick = function ()
		self.tabChosenAll:SetActive(false)
		self.tabChosenMaterial:SetActive(true)

		self.onlyMaterial = true
	end

	UIEventListener.Get(self.tabAll).onClick = function ()
		self.tabChosenAll:SetActive(true)
		self.tabChosenMaterial:SetActive(false)

		self.onlyMaterial = false
	end

	for i = 1, 6 do
		UIEventListener.Get(self["btnStar" .. i]).onClick = function ()
			if self.starArr[i] then
				self.starArr[i] = nil
			else
				self.starArr[i] = 1
			end

			self:updateStarGroup()
		end
	end

	UIEventListener.Get(self.btnSure).onClick = function ()
		local wnd = xyd.WindowManager.get():getWindow("soul_equip2_strengthen_window")

		if wnd then
			wnd:autoSelect(self.onlyMaterial, self.starArr, self.TargetLevel)
		end

		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function SoulEquipAutoChoooseWindow:updateStarGroup()
	for i = 1, 6 do
		if self.starArr[i] then
			self["chosen" .. i]:SetActive(true)
		else
			self["chosen" .. i]:SetActive(false)
		end
	end
end

function SoulEquipAutoChoooseWindow:layout()
	self.labelWindowTitle.text = __("SOUL_EQUIP_TEXT62")
	self.labelTitle1.text = __("SOUL_EQUIP_TEXT63")
	self.labelTitle2.text = __("SOUL_EQUIP_TEXT66")
	self.labelTitle3.text = __("SOUL_EQUIP_TEXT67")
	self.labelSure.text = __("SOUL_EQUIP_TEXT68")
	self.labelTabMaterial.text = __("SOUL_EQUIP_TEXT64")
	self.labelTabAll.text = __("SOUL_EQUIP_TEXT65")

	local function callback(num)
		self.TargetLevel = num
	end

	local SelectNum = import("app.components.SelectNum")
	self.selectNum_ = SelectNum.new(self.numPos, "default")

	self.selectNum_:setInfo({
		maxNum = self.equip:getMaxLevel(),
		minNum = self.equip:getLevel() + 1,
		curNum = self.equip:getLevel() + 1,
		callback = callback
	})
	self.selectNum_:setFontSize(26, 26)
	self.selectNum_:setKeyboardPos(0, -180)
	self.selectNum_:setMaxNum(self.equip:getMaxLevel())
	self.selectNum_:setCurNum(self.equip:getLevel() + 1)
	self.selectNum_:changeCurNum()
	self.selectNum_:setSelectBGSize(200, 40)
	self:updateStarGroup()
	self.tabChosenAll:SetActive(not self.onlyMaterial)
	self.tabChosenMaterial:SetActive(self.onlyMaterial)
end

return SoulEquipAutoChoooseWindow
