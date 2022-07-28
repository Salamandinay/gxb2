local PetEvolutionWindow = class("PetEvolutionWindow", import(".BaseWindow"))
local ResItem = import("app.components.ResItem")
local PasSkillItem = class("PasSkillItem")
local exUnlockLv = tonumber(xyd.tables.miscTable:getVal("pet_exskill_open_level"))
local petSlot = xyd.models.petSlot
local petTable = xyd.tables.petTable
local attrToIndex = {
	spd = 3,
	sklP = 4,
	hp = 1,
	atk = 2
}

function PetEvolutionWindow:ctor(name, params)
	PetEvolutionWindow.super.ctor(self, name, params)

	self.petID = params.petID
	self.pet_ = petSlot:getPetByID(self.petID)
	self.maxLev = xyd.tables.petTable:getMaxExLev(self.petID)
	self.petLv = params.petLv
	self.petType = params.petType
	self.fakeLev_ = 0
	self.fakeUseRes = {}
end

function PetEvolutionWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:updateContent()
	self:register()
end

function PetEvolutionWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bgImg = groupAction:ComponentByName("bg", typeof(UISprite))
	self.labelWinTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.helpBtn = groupAction:NodeByName("helpBtn").gameObject
	self.resItemGroup = groupAction:NodeByName("resItemGroup").gameObject
	self.reSetBtn = groupAction:NodeByName("reSetBtn").gameObject
	local groupMiddle = groupAction:NodeByName("groupMiddle").gameObject
	self.groupMiddle = groupMiddle
	local groupSkill = groupMiddle:NodeByName("groupSkill").gameObject
	self.skillImg = groupSkill:ComponentByName("skillImg", typeof(UISprite))
	self.labelSkill = groupSkill:ComponentByName("labelSkill", typeof(UILabel))
	self.labelSkillLv = groupSkill:ComponentByName("labelSkillLv", typeof(UILabel))
	self.effectCon = groupSkill:NodeByName("effectCon").gameObject
	local groupAttr = groupMiddle:NodeByName("groupAttr").gameObject
	self.groupAttrList = {}

	for i = 1, 4 do
		local attr = groupAttr:NodeByName("attr_" .. tostring(i)).gameObject
		local labelName = attr:ComponentByName("attrGroup/labelName", typeof(UILabel))
		local labelNum = attr:ComponentByName("labelNum", typeof(UILabel))

		table.insert(self.groupAttrList, {
			labelName = labelName,
			labelNum = labelNum
		})
	end

	self.scroller = groupMiddle:ComponentByName("scroller", typeof(UIScrollView))
	self.groupContent = self.scroller:NodeByName("groupContent").gameObject
	self.labelItem = groupMiddle:NodeByName("labelItem").gameObject

	self.labelItem:SetActive(false)

	local groupBottom = groupAction:NodeByName("groupBottom").gameObject
	self.groupBottom = groupBottom
	self.groupCost = groupBottom:NodeByName("groupCost").gameObject

	for i = 1, 3 do
		self["labelCost" .. i] = self.groupCost:ComponentByName("labelCost" .. i, typeof(UILabel))
	end

	self.labelTips = groupBottom:ComponentByName("labelTips", typeof(UILabel))
	self.btnLevelUp = groupBottom:NodeByName("btnLevelUp").gameObject
	self.labelLevelUp = self.btnLevelUp:ComponentByName("labelLevelUp", typeof(UILabel))
	self.entranceLabel = groupAction:ComponentByName("entranceLabel", typeof(UILabel))
	self.imgMax = groupBottom:ComponentByName("imgMax", typeof(UISprite))
end

function PetEvolutionWindow:layout()
	xyd.setUISpriteAsync(self.skillImg, nil, "pet_exskill_" .. self.petID)

	self.labelSkill.text = xyd.tables.petTextTable:getExName(self.petID)

	for key, value in pairs(attrToIndex) do
		self.groupAttrList[value].labelName.text = __(string.upper(key))
	end

	self.resItemList = {}
	local win = xyd.WindowManager.get():getWindow("choose_pet_window")

	if win then
		local function callback()
			xyd.alert(xyd.AlertType.TIPS, __("IS_IN_BATTLE_FORMATION"))
		end

		self:addResItem({
			{
				hidePlus = true,
				show_tips = true,
				hideBg = false,
				tableId = xyd.ItemID.MANA,
				callback = callback
			},
			{
				hidePlus = true,
				show_tips = true,
				hideBg = false,
				tableId = xyd.ItemID.PET_SKILL_EXP,
				callback = callback
			},
			{
				hidePlus = true,
				show_tips = true,
				hideBg = false,
				tableId = xyd.ItemID.PET_CRYSTAL,
				callback = callback
			}
		})
	else
		self:addResItem({
			{
				hideBg = false,
				show_tips = true,
				hidePlus = true,
				tableId = xyd.ItemID.MANA
			},
			{
				hideBg = false,
				show_tips = true,
				hidePlus = true,
				tableId = xyd.ItemID.PET_SKILL_EXP
			},
			{
				hideBg = false,
				show_tips = true,
				hidePlus = true,
				tableId = xyd.ItemID.PET_CRYSTAL
			}
		})
	end

	local resItem = self.resItemList[3]

	resItem.resIconImg:SetLeftAnchor(resItem.bgImg.gameObject, 0, 13)
	resItem.resIconImg:SetRightAnchor(resItem.bgImg.gameObject, 0, 43)
	resItem.resIconImg:SetTopAnchor(resItem.bgImg.gameObject, 1, 5)
	resItem.resIconImg:SetBottomAnchor(resItem.bgImg.gameObject, 0, 1)
	self:waitForFrame(1, function ()
		self.resItemGroup:GetComponent(typeof(UILayout)):Reposition()
	end)

	local pasSkills = petTable:getPetSkills(self.petID)
	self.pasSkillsUnlockLv = petTable:getPetSkillsUnlockLv(self.petID)
	self.pasSkillItemList = {}

	for i = 1, #pasSkills do
		local item = NGUITools.AddChild(self.groupContent, self.labelItem)
		local pasSkillItem = PasSkillItem.new(item, {
			skillID = pasSkills[i],
			unLockLv = tonumber(self.pasSkillsUnlockLv[i])
		})

		table.insert(self.pasSkillItemList, pasSkillItem)
	end

	self.groupContent:GetComponent(typeof(UILayout)):Reposition()
	self.scroller:ResetPosition()

	if self.petType and self.petType == xyd.PetFormationType.ENTRANCE_TEST then
		self.groupBottom:SetActive(false)
		self.resItemGroup:SetActive(false)
		self.groupMiddle.transform:Y(78)

		self.bgImg.height = 794

		self.bgImg.transform:Y(50)

		self.entranceLabel.text = __("ENTRANCE_TEST_PET_EXSKILL")
	end
end

function PetEvolutionWindow:updateContent()
	local exLv = self:getLev()
	local exSkillTableID = xyd.tables.petTable:getExSkillID(self.petID) + exLv - 1

	self.reSetBtn:SetActive(exLv > 1)

	if self.petType == xyd.PetFormationType.ENTRANCE_TEST then
		self.reSetBtn:SetActive(false)
	end

	if exLv == 0 then
		self.labelSkillLv.text = __("PET_EXSKILL_TEXT_01", 1) .. "/" .. self.maxLev
		self.labelLevelUp.text = __("UNLOCK_TEXT")

		if self.petLv < exUnlockLv then
			xyd.setTouchEnable(self.btnLevelUp, false)
			xyd.applyGrey(self.btnLevelUp:GetComponent(typeof(UISprite)))
			self.labelLevelUp:ApplyGrey()

			self.labelTips.text = __("PET_EXSKILL_TIPS_02", exUnlockLv)
		end

		local cost = xyd.split2(xyd.tables.miscTable:getVal("pet_exlevel_unlock_cost"), {
			"|",
			"#"
		}, true)

		self:setCost(cost)

		exSkillTableID = exSkillTableID + 1
	else
		self.labelSkillLv.text = __("PET_EXSKILL_TEXT_01", exLv) .. "/" .. self.maxLev

		if exLv < self.maxLev then
			self.labelLevelUp.text = __("LEV_UP")
			local cost = xyd.tables.petExskillTable:getCost(exSkillTableID)

			self:setCost(cost)
		else
			self.btnLevelUp:SetActive(false)
			self.groupCost:SetActive(false)
			xyd.setUISpriteAsync(self.imgMax, nil, "pet_skill_max_" .. tostring(xyd.Global.lang), function ()
				self.imgMax:MakePixelPerfect()
			end)
		end
	end

	local effects = xyd.tables.petExskillTable:getEffects(exSkillTableID)

	for i = 1, #effects do
		local buff = effects[i][1]
		local bt = xyd.tables.dBuffTable
		local value = effects[i][2]

		if bt:isShowPercent(buff) then
			local factor = tonumber(bt:getFactor(buff))
			value = string.format("%.1f", value * 100 / tonumber(bt:getFactor(buff)))
			value = value .. "%"
		end

		self.groupAttrList[attrToIndex[buff]].labelNum.text = "+" .. value
	end

	for _, item in ipairs(self.pasSkillItemList) do
		item:setTextGrey(exLv)
	end

	self:updateFakeRes()
end

function PetEvolutionWindow:updateFakeRes()
	if next(self.fakeUseRes) == nil then
		return
	end

	for i = 1, #self.resItemList do
		local item = self.resItemList[i]
		local num = xyd.models.backpack:getItemNumByID(item:getItemID())

		item:setItemNum(num - (self.fakeUseRes[item:getItemID()] or 0))
	end

	local wnd = xyd.WindowManager.get():getWindow("pet_detail_window")
	local top = wnd.windowTop
	local itemList = top:getResItemList()
	local i = 1

	while i <= #itemList do
		local item = itemList[i]
		local num = xyd.models.backpack:getItemNumByID(item:getItemID())

		item:setItemNum(num - (self.fakeUseRes[item:getItemID()] or 0))

		i = i + 1
	end
end

function PetEvolutionWindow:addResItem(params)
	for _, data in ipairs(params) do
		local item = ResItem.new(self.resItemGroup)

		item:setInfo(data)

		item.bgImg.width = 180

		table.insert(self.resItemList, item)
	end
end

function PetEvolutionWindow:setCost(costList)
	for i = 1, 3 do
		local cost = costList[i]
		self["labelCost" .. i].text = xyd.getRoughDisplayNumber(tonumber(cost[2]))
		self["costItemID" .. i] = cost[1]

		if cost[2] > xyd.models.backpack:getItemNumByID(cost[1]) - (self.fakeUseRes[cost[1]] or 0) then
			self["labelCost" .. i].color = Color.New2(3422556671.0)
			self["costEnough" .. i] = false
		else
			self["labelCost" .. i].color = Color.New2(960513791)
			self["costEnough" .. i] = true
		end
	end
end

function PetEvolutionWindow:register()
	PetEvolutionWindow.super.register(self)

	local function callback(self, isPressed)
		local longTouchFunc = nil

		function longTouchFunc()
			if self.levUpLongTouchFlag == true then
				if not self:levUpTouch() then
					self:clearLongTouch()

					return
				end

				self:waitForTime(0.2, function ()
					if not self then
						return
					end

					longTouchFunc()
				end, "levUpLongTouchClick")
			end
		end

		if isPressed then
			self.levUpLongTouchFlag = true

			self:waitForTime(0.5, function ()
				if not self then
					return
				end

				if self.levUpLongTouchFlag then
					longTouchFunc()
				end
			end, "levUpLongTouch")
		elseif isPressed ~= nil then
			self:clearLongTouch()
			self:levUpTouch()
		end
	end

	xyd.setDarkenBtnBehavior(self.btnLevelUp, self, callback, callback)

	UIEventListener.Get(self.reSetBtn).onClick = function ()
		self:reqLevUp()
		xyd.alert(xyd.AlertType.YES_NO, __("PET_CORE_RESTORE_TIPS"), function (yes)
			if yes then
				xyd.models.petSlot:reqResetExLevel(self.petID)
			end
		end)
	end

	self.eventProxy_:addEventListener(xyd.event.RESET_PET_EXLEVEL, function (event)
		self:updateContent()

		local items = event.data.restore_items

		xyd.models.itemFloatModel:pushNewItems(items)
	end)
	self.eventProxy_:addEventListener(xyd.event.ACTIVE_PET_EXLEVEL, function (event)
		self:updateContent()
	end)
	self.eventProxy_:addEventListener(xyd.event.UPGRADE_PET_EXLEVEL, function (event)
		self.fakeUseRes = {}
	end)
end

function PetEvolutionWindow:clearLongTouch()
	self.levUpLongTouchFlag = false

	if XYDCo.IsWaitCoroutine("levUpLongTouch") then
		XYDCo.StopWait("levUpLongTouch")
	end

	if XYDCo.IsWaitCoroutine("levUpLongTouchClick") then
		XYDCo.StopWait("levUpLongTouchClick")
	end
end

function PetEvolutionWindow:getLev()
	if self.petType == xyd.PetFormationType.ENTRANCE_TEST then
		local entranceActivityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)

		return xyd.tables.activityEntranceTestRankTable:getPetExskill(entranceActivityData:getLevel())
	end

	return self.pet_:getExLv() + self.fakeLev_
end

function PetEvolutionWindow:levUpTouch()
	for i = 1, 3 do
		if not self["costEnough" .. i] then
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self["costItemID" .. i])))
			self:reqLevUp()

			return false
		end
	end

	self.fakeLev_ = self.fakeLev_ + 1
	local lev = self:getLev()

	if lev == 1 then
		self.fakeLev_ = 0

		petSlot:actviePetExlevel(self.petID)

		return false
	else
		self:fakeLevUp()

		if lev == self.maxLev then
			self:reqLevUp()

			return false
		end

		return true
	end
end

function PetEvolutionWindow:fakeLevUp()
	local exLv = self:getLev()
	local exSkillTableID = xyd.tables.petTable:getExSkillID(self.petID) + exLv - 2
	local costList = xyd.tables.petExskillTable:getCost(exSkillTableID)

	for _, cost in ipairs(costList) do
		if not self.fakeUseRes[cost[1]] then
			self.fakeUseRes[cost[1]] = 0
		end

		self.fakeUseRes[cost[1]] = self.fakeUseRes[cost[1]] + cost[2]
	end

	self:updateContent()
	self:playLevUpAction()
end

function PetEvolutionWindow:playLevUpAction()
	if self.shengjiEffect_ ~= nil and self.isPlayUpSkinEffect ~= nil and self.isPlayUpSkinEffect == true then
		return
	end

	if self.shengjiEffect_ == nil then
		self.shengjiEffect_ = xyd.Spine.new(self.effectCon)
		self.isPlayUpSkinEffect = true

		self.shengjiEffect_:setInfo("ui_pet_skill_up", handler(self, function ()
			self.shengjiEffect_:play("texiao01", 1, 1, function ()
				self.shengjiEffect_:SetActive(false)

				self.isPlayUpSkinEffect = false
			end)
			self.shengjiEffect_:SetLocalScale(0.8, 0.8, 0.8)
		end))
	else
		self.isPlayUpSkinEffect = true

		self.shengjiEffect_:SetActive(true)
		self.shengjiEffect_:play("texiao01", 1, 1, function ()
			self.shengjiEffect_:SetActive(false)

			self.isPlayUpSkinEffect = false
		end)
	end
end

function PetEvolutionWindow:reqLevUp()
	if self.fakeLev_ > 0 then
		petSlot:upgradePetExlevel(self.petID, self.fakeLev_)

		self.fakeLev_ = 0
	end
end

function PetEvolutionWindow:close()
	self:reqLevUp()
	PetEvolutionWindow.super.close(self)
end

function PasSkillItem:ctor(go, params)
	self.go = go
	self.skillID = params.skillID
	self.unLockLv = params.unLockLv

	self:getUIComponent()
	self:setText()
end

function PasSkillItem:getUIComponent()
	self.labelLv = self.go:ComponentByName("labelLv", typeof(UILabel))
	self.labelDesc = self.go:ComponentByName("labelDesc", typeof(UILabel))
end

function PasSkillItem:setText()
	self.labelLv.text = __("PET_EXSKILL_TEXT_01", self.unLockLv)
	self.labelDesc.text = xyd.tables.skillTextTable:getDesc(self.skillID)
	self.go:GetComponent(typeof(UIWidget)).height = self.labelDesc.height + 3
end

function PasSkillItem:setTextGrey(lv)
	if self.unLockLv <= lv then
		self.labelLv.color = Color.New2(1634703871)
		self.labelDesc.color = Color.New2(1549556991)
	else
		self.labelLv.color = Color.New2(2812982015.0)
		self.labelDesc.color = Color.New2(2694881535.0)
	end
end

return PetEvolutionWindow
