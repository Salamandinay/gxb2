local DressMainWindow = class("DressMainWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local DressMainAchievementContent = import("app.components.DressMainAchievementContent")
local DressMainBackpackContent = import("app.components.DressMainBackpackContent")
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local SkillShowItem = class("SkillShowItem", import("app.components.CopyComponent"))
local SkillShowItem2 = class("DressItem", import("app.components.CopyComponent"))
local ItemContent = class("ItemContent", import("app.components.CopyComponent"))

function DressMainWindow:ctor(name, params)
	DressMainWindow.super.ctor(self, name, params)

	self.window_top_close_fun = params.window_top_close_fun
	self.downChangeShowQuality = -1
	self.showItemStyles = {
		0,
		0,
		0,
		0,
		0
	}
	self.isEdit = false
end

function DressMainWindow:initWindow()
	self:getUIComponent()
	self:reSize()
	self:layout()
	self:registerEvent()
	self:checkGuide()
end

function DressMainWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.imgBg = self.groupAction:ComponentByName("imgBg", typeof(UISprite))
	self.nav = self.groupAction:NodeByName("nav").gameObject
	self.tab_2 = self.nav:NodeByName("tab_2").gameObject
	self.page1 = self.groupAction:NodeByName("page1").gameObject
	self.upConWid = self.page1:ComponentByName("upCon", typeof(UIWidget))
	self.upCon = self.page1:NodeByName("upCon").gameObject
	self.posRoot = self.page1:NodeByName("upCon/posRoot").gameObject

	for i = 1, 5 do
		self["dressPos" .. i] = self.posRoot:NodeByName("dressPos" .. i).gameObject
		self["dressPosBorder" .. i] = self["dressPos" .. i]:ComponentByName("dressPosBorder" .. i, typeof(UISprite))
		self["dressPosBg" .. i] = self["dressPos" .. i]:ComponentByName("dressPosBg" .. i, typeof(UISprite))
		self["dressPosIcon" .. i] = self["dressPos" .. i]:ComponentByName("dressPosIcon" .. i, typeof(UIWidget))
		self["dressName" .. i] = self["dressPos" .. i]:ComponentByName("dressName" .. i, typeof(UILabel))
	end

	self.groupBtn = self.posRoot:NodeByName("groupBtn").gameObject
	self.groupBtnLabel = self.groupBtn:ComponentByName("groupBtnLabel", typeof(UILabel))
	self.personCon = self.posRoot:NodeByName("personCon").gameObject
	self.personBottom = self.personCon:ComponentByName("personBottom", typeof(UISprite))
	self.personEffect = self.personCon:NodeByName("personEffect").gameObject
	self.helpBtn = self.posRoot:NodeByName("helpBtn").gameObject
	self.upConBg = self.upCon:ComponentByName("upConBg", typeof(UISprite))
	self.effectTopPanel = self.posRoot:NodeByName("effectTopPanel").gameObject
	self.dressingBtn = self.effectTopPanel:NodeByName("dressingBtn").gameObject
	self.dressingBtnLabel = self.dressingBtn:ComponentByName("dressingBtnLabel", typeof(UILabel))
	self.dressingBtnLabel.text = __("DRESS_EDIT_TIPS_3")
	self.downConWid = self.page1:ComponentByName("downCon", typeof(UIWidget))
	self.downCon = self.page1:NodeByName("downCon").gameObject
	self.downCon_posRoot = self.page1:NodeByName("downCon/posRoot").gameObject
	self.line = self.downCon_posRoot:ComponentByName("line", typeof(UISprite))
	self.groupSkin = self.downCon_posRoot:NodeByName("groupSkin").gameObject
	self.changeDressBtn = self.groupSkin:NodeByName("changeDressBtn").gameObject
	self.changeDressBtnLabel = self.changeDressBtn:ComponentByName("changeDressBtnLabel", typeof(UILabel))
	self.downConBg = self.downCon:ComponentByName("downConBg", typeof(UISprite))
	self.attrText = self.downCon_posRoot:ComponentByName("attrText", typeof(UILabel))
	self.buffText = self.downCon_posRoot:ComponentByName("buffText", typeof(UILabel))
	self.tipsBtn = self.downCon_posRoot:NodeByName("tipsBtn").gameObject
	self.allBuffsBtn = self.downCon_posRoot:NodeByName("allBuffsBtn").gameObject
	self.hasBuffCon = self.downCon_posRoot:NodeByName("hasBuffCon").gameObject
	self.skillScroller = self.hasBuffCon:NodeByName("skillScroller").gameObject
	self.skillScroller_UIScrollView = self.hasBuffCon:ComponentByName("skillScroller", typeof(UIScrollView))
	self.skillScrollerCon = self.skillScroller:NodeByName("skillScrollerCon").gameObject
	self.skillScrollerCon_UIWrapContent = self.skillScroller:ComponentByName("skillScrollerCon", typeof(UIWrapContent))
	self.drag = self.hasBuffCon:NodeByName("drag").gameObject
	self.noneBuff = self.downCon_posRoot:NodeByName("noneBuff").gameObject
	self.noneImg = self.noneBuff:ComponentByName("noneImg", typeof(UISprite))
	self.noneText = self.noneBuff:ComponentByName("noneText", typeof(UILabel))
	self.skill_big_item = self.hasBuffCon:NodeByName("skill_big_item").gameObject
	self.skill_show_item = self.hasBuffCon:NodeByName("skill_show_item").gameObject
	self.skillWrapContent = FixedMultiWrapContent.new(self.skillScroller_UIScrollView, self.skillScrollerCon_UIWrapContent, self.skill_show_item, SkillShowItem2, self)
	self.downChange = self.page1:NodeByName("downChange").gameObject
	self.downTweenCon = self.downChange:NodeByName("downTweenCon").gameObject
	self.downChangeScroll = self.downTweenCon:NodeByName("downChangeScroll").gameObject
	self.bg_ = self.downChangeScroll:ComponentByName("bg_", typeof(UISprite))
	self.mainGroup = self.downChangeScroll:NodeByName("mainGroup").gameObject
	self.mainGroup_UIWidget = self.downChangeScroll:ComponentByName("mainGroup", typeof(UIWidget))
	self.bg2_ = self.mainGroup:ComponentByName("bg2_", typeof(UISprite))
	self.itemScroller = self.mainGroup:NodeByName("itemScroller").gameObject
	self.itemScroller_UIScrollView = self.mainGroup:ComponentByName("itemScroller", typeof(UIScrollView))
	self.itemGroup = self.itemScroller:NodeByName("itemGroup").gameObject
	self.itemGroup_UIWrapContent = self.itemScroller:ComponentByName("itemGroup", typeof(UIWrapContent))
	self.noneGroup = self.mainGroup:NodeByName("noneGroup").gameObject
	self.noneGroupLabel = self.noneGroup:ComponentByName("label", typeof(UILabel))
	self.leadskin_choose_item = self.downChange:NodeByName("leadskin_choose_item").gameObject
	self.changeDressSaveBtn = self.downChange:NodeByName("changeDressSaveBtn").gameObject
	self.changeDressSaveBtnLabel = self.changeDressSaveBtn:ComponentByName("changeDressSaveBtnLabel", typeof(UILabel))
	self.changeDressCancelBtn = self.downChange:NodeByName("changeDressCancelBtn").gameObject
	self.changeDressCancelBtnLabel = self.changeDressCancelBtn:ComponentByName("changeDressCancelBtnLabel", typeof(UILabel))
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.itemScroller_UIScrollView, self.itemGroup_UIWrapContent, self.leadskin_choose_item, ItemContent, self)

	self.multiWrap_:setInfos({}, {})

	self.changeDressSaveBtnLabel.text = __("SAVE")
	self.changeDressCancelBtnLabel.text = __("CANCEL_2")
	self.downChangebtnCircles = self.downTweenCon:NodeByName("downChangebtnCircles").gameObject
	self.downChangedivider = self.downChangebtnCircles:ComponentByName("downChangedivider", typeof(UISprite))
	self.downChangebtnQualityChosen = self.downChangebtnCircles:NodeByName("downChangebtnQualityChosen").gameObject

	for i = 0, 5 do
		self["downChangebtnCircle" .. i] = self.downChangebtnCircles:NodeByName("downChangebtnCircle" .. i).gameObject
	end

	self.page2 = self.groupAction:NodeByName("page2").gameObject
	self.page3 = self.groupAction:NodeByName("page3").gameObject
end

function DressMainWindow:reSize()
	self:resizePosY(self.nav.gameObject, 510, 600)
	self:resizePosY(self.upCon.gameObject, 481, 526)
	self:resizePosY(self.personCon.gameObject, -276, -323)
	self:resizePosY(self.downCon.gameObject, -30, -66)
	self:resizePosY(self.helpBtn.gameObject, -33, 11)
	self:resizePosY(self.mainGroup.gameObject, 0, -45)

	self.mainGroup_UIWidget.height = 500 + 86 * self.scale_num_contrary
end

function DressMainWindow:checkGuide()
	local isHasGoDressMainGuide = xyd.db.misc:getValue("is_has_go_dress_main_guide")

	if not isHasGoDressMainGuide or tonumber(isHasGoDressMainGuide) ~= 1 then
		local needGuideSumAttrs = xyd.tables.miscTable:getNumber("senpai_dress_guide_point", "value")
		local value_arr = xyd.models.dress:getAttrs()
		local sumAttrs = 0

		for i, value in pairs(value_arr) do
			sumAttrs = sumAttrs + value
		end

		if needGuideSumAttrs <= sumAttrs then
			xyd.db.misc:setValue({
				value = 1,
				key = "is_has_go_dress_main_guide"
			})
		else
			xyd.WindowManager:get():openWindow("common_trigger_guide_window", {
				guide_type = xyd.CommonTriggerGuideType.DRESS_MAIN_WINDOW
			})
			xyd.db.misc:setValue({
				value = 1,
				key = "is_has_go_dress_main_guide"
			})
		end
	end
end

function DressMainWindow:layout()
	self:initTop()
	self:initNav()
end

function DressMainWindow:initNav()
	self.tabBar = CommonTabBar.new(self.nav, 3, function (index)
		self:updatePage(index)
	end, nil, , 5)
	local textArr = {}

	for i = 1, 3 do
		table.insert(textArr, __("PERSON_DRESS_MAIN_" .. i))
	end

	self.tabBar:setTexts(textArr)
end

function DressMainWindow:initTop()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50, nil, function ()
		if self.window_top_close_fun then
			self.window_top_close_fun()
		end

		self:close()
	end)
	local items = {
		{
			id = xyd.ItemID.MANA
		},
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	self.windowTop:setItem(items)
end

function DressMainWindow:registerEvent()
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "PERSON_DRESS_HELP"
		})
	end)
	UIEventListener.Get(self.tipsBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "PERSON_DRESS_MAIN_HELP"
		})
	end)
	UIEventListener.Get(self.allBuffsBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("dress_buffs_show_window", {
			showBuffsSumArr = self.showBuffsSumArr
		})
	end)
	UIEventListener.Get(self.groupBtn.gameObject).onClick = handler(self, function ()
		if xyd.models.dress:isfunctionOpen() then
			xyd.WindowManager.get():openWindow("dress_suit_window")

			return
		else
			xyd.alertTips(__("NEW_FUNCTION_TIP"))
		end
	end)
	UIEventListener.Get(self.changeDressBtn.gameObject).onClick = handler(self, function ()
		self.tabBar:setTabActive(2, true)
	end)

	for i = 1, 5 do
		UIEventListener.Get(self["dressPosBorder" .. i].gameObject).onClick = function ()
			if not self.isEdit then
				self:entryEdit(i)
				xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
			elseif self.downChangeShowQuality ~= i then
				self:downChangeOnQualityBtn(i)
			end
		end
	end

	UIEventListener.Get(self.dressingBtn.gameObject).onClick = handler(self, function ()
		self:entryEdit(0)
	end)
	UIEventListener.Get(self.changeDressCancelBtn.gameObject).onClick = handler(self, function ()
		local body_styles = xyd.models.dress:getEquipedStyles()
		local isSame = true

		for i = 1, #body_styles do
			if body_styles[i] ~= self.showItemStyles[i] then
				isSame = false
			end
		end

		if isSame then
			self:setEditState(false)

			return
		end

		xyd.alert(xyd.AlertType.YES_NO, __("DRESS_EDIT_TIPS_1"), function (yes_no)
			if yes_no then
				self:setEditState(false)
				self:updateEuqip()
			end
		end)
	end)
	UIEventListener.Get(self.changeDressSaveBtn.gameObject).onClick = handler(self, function ()
		local body_styles = xyd.models.dress:getEquipedStyles()
		local isSame = true

		for i = 1, #body_styles do
			if body_styles[i] ~= self.showItemStyles[i] then
				isSame = false
			end
		end

		if isSame then
			self:setEditState(false)

			return
		end

		xyd.alert(xyd.AlertType.YES_NO, __("DRESS_EDIT_TIPS_2"), function (yes_no)
			if yes_no then
				self:setEditState(false)
				xyd.models.dress:setAllEquip(self.showItemStyles)
			end
		end)
	end)

	for k = 0, 5 do
		UIEventListener.Get(self["downChangebtnCircle" .. k]).onClick = function ()
			self:downChangeOnQualityBtn(k)
		end
	end
end

function DressMainWindow:entryEdit(index)
	if self.isDownChangeTween then
		return
	end

	self.dressingBtn.gameObject:SetActive(false)
	self:setEditState(true)
	self.downChange.gameObject:X(0)

	if not index then
		self:downChangeOnQualityBtn(self.downChangeShowQuality, true)
	else
		self:downChangeOnQualityBtn(index, true)
	end
end

function DressMainWindow:setEditState(state)
	if self.isDownChangeTween then
		return
	end

	if not self.isEdit and state then
		self.isDownChangeTween = true

		self.downTweenCon.gameObject:Y(-542)

		local seq = self:getSequence()

		seq:Append(self.downTweenCon.transform:DOLocalMove(Vector3(0, 0, 0), 0.2))
		seq:AppendCallback(function ()
			self.isEdit = state
			self.isDownChangeTween = false

			seq:Kill(false)
		end)
		self.changeDressCancelBtn.gameObject:X(-85)
		self.changeDressSaveBtn.gameObject:X(85)
	end

	if self.isEdit and not state then
		self.isDownChangeTween = true
		local seq = self:getSequence()

		seq:Append(self.downTweenCon.transform:DOLocalMove(Vector3(0, -542, 0), 0.2))
		seq:AppendCallback(function ()
			self.downChange.gameObject:X(2000)

			self.isEdit = state
			self.isDownChangeTween = false

			seq:Kill(false)
		end)
		self.dressingBtn.gameObject:SetActive(true)
		self.changeDressCancelBtn.gameObject:X(2000)
		self.changeDressSaveBtn.gameObject:X(2000)
	end
end

function DressMainWindow:updatePage(index)
	if self.tabIndex and self.tabIndex == index then
		return
	end

	self.tabIndex = index

	if index == 1 then
		if not self.firstInitPageOne then
			self:initPageOne()

			self.firstInitPageOne = true
		end

		self.page1.gameObject:SetActive(true)
		self.page2.gameObject:SetActive(false)
		self.page3.gameObject:SetActive(false)
		self:updatePageOneInfo()
	elseif index == 2 then
		if not self.firstInitPageTow then
			self:initPageTwo()

			self.firstInitPageTow = true
		else
			self:onQualityBtn(-1)
		end

		self.page1.gameObject:SetActive(false)
		self.page2.gameObject:SetActive(true)
		self.page3.gameObject:SetActive(false)
	elseif index == 3 then
		if not self.firstInitPageThree then
			self:initPageThree()

			self.firstInitPageThree = true
		end

		self.page1.gameObject:SetActive(false)
		self.page2.gameObject:SetActive(false)
		self.page3.gameObject:SetActive(true)
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.SWITCH_PAGE)
end

function DressMainWindow:updateEuqip(isOnlyShow)
	for i = 1, 5 do
		local styleId = xyd.models.dress:getEquipedStyles()[i]

		if not isOnlyShow then
			self.showItemStyles[i] = styleId
		else
			styleId = self.showItemStyles[i]
		end

		if styleId ~= 0 then
			if not self["item_" .. i] or self["item_" .. i] and self["item_" .. i]:getStyleID() ~= styleId then
				if self["item_" .. i] then
					self["item_" .. i]:setInfo({
						styleID = styleId
					})
				else
					self:addItem(i, styleId)
				end

				self["dressPosBg" .. i].gameObject:SetActive(false)

				local dress_id = xyd.tables.senpaiDressStyleTable:getDressId(styleId)
				local dress_item_name_id = xyd.tables.senpaiDressTable:getItems(dress_id)[1]
				self["dressName" .. i].text = xyd.tables.itemTable:getName(dress_item_name_id)
			end
		else
			if self["item_" .. i] then
				NGUITools.DestroyChildren(self["dressPosIcon" .. i].gameObject.transform)

				self["item_" .. i] = nil
			end

			local text_index = i + 3
			self["dressName" .. i].text = __("PERSON_DRESS_MAIN_" .. text_index)

			self["dressPosBg" .. i].gameObject:SetActive(true)
		end
	end

	dump(xyd.models.dress:getEffectEquipedStyles(), "getEffectEquipedStyles()")

	if not self.normalModel_ then
		self.normalModel_ = import("app.components.SenpaiModel").new(self.personEffect)
	end

	if not isOnlyShow then
		self.normalModel_:setModelInfo({
			ids = xyd.models.dress:getEffectEquipedStyles()
		})
	else
		self.normalModel_:setModelInfo({
			ids = self.showItemStyles
		})
	end
end

function DressMainWindow:addItem(i, styleId)
	local params = {
		uiRoot = self["dressPosIcon" .. i].gameObject,
		styleID = styleId,
		callback = function ()
			local is_can_rm = xyd.tables.senpaiDressSlotTable:getCanRm(i)
			local params = {
				state = 1,
				is_can_rm = is_can_rm,
				styleID = styleId
			}

			if self["item_" .. i] then
				params.styleID = self["item_" .. i]:getStyleID()
			end

			if self.isEdit then
				if is_can_rm == 1 then
					params.state = 1
				else
					params.state = 3
				end
			elseif is_can_rm == 1 then
				params.state = 5
			else
				params.state = 4
			end

			xyd.WindowManager.get():openWindow("leadskin_tips_window", params)
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		end
	}
	local item = xyd.getItemIcon(params, xyd.ItemIconType.DRESS_STYLE_ICON)
	local scale = 0.8244274809160306

	item:SetLocalScale(scale, scale, scale)

	self["item_" .. i] = item
end

function DressMainWindow:canBackClose()
	DressMainWindow.super.canBackClose(self)

	if self.window_top_close_fun then
		self.window_top_close_fun()
	end

	self:close()
end

function DressMainWindow:getIsEdit()
	return self.isEdit
end

function DressMainWindow:initPageOne()
	self.noneText.text = __("PERSON_DRESS_MAIN_13")

	self:updateEuqip()

	self.attrText.text = __("PERSON_DRESS_MAIN_10")
	self.buffText.text = __("PERSON_DRESS_MAIN_11")
	self.groupBtnLabel.text = __("PERSON_DRESS_MAIN_22")
	self.changeDressBtnLabel.text = __("PERSON_DRESS_MAIN_12")
	local iconClass = require("app.components.ThreeAttrComponent")
	self.attr_map = iconClass.new(self.groupSkin)
	local params = {
		max_value = xyd.models.dress:getThreeMaxValue(),
		value_arr = xyd.models.dress:getAttrs(),
		text_arr = {
			__("PERSON_DRESS_ATTR_1"),
			__("PERSON_DRESS_ATTR_2"),
			__("PERSON_DRESS_ATTR_3")
		},
		isSureRenderCompelete = function ()
			return self.page1.gameObject.activeSelf
		end
	}

	if xyd.Global.lang == "en_en" then
		params.label_name_size = 16
	end

	self.attr_map:setInfo(params)
	self.attr_map:SetLocalPosition(-2.7, -28.6, 0)
end

function DressMainWindow:updatePageOneInfo()
	local params = {
		max_value = xyd.models.dress:getThreeMaxValue(),
		value_arr = xyd.models.dress:getAttrs(),
		text_arr = {
			__("PERSON_DRESS_ATTR_1"),
			__("PERSON_DRESS_ATTR_2"),
			__("PERSON_DRESS_ATTR_3")
		}
	}

	self.attr_map:setInfo(params)

	local active_skills = xyd.models.dress:getActiveSkills()

	if #active_skills <= 0 then
		self.hasBuffCon:SetActive(false)
		self.noneBuff:SetActive(true)
	else
		self.hasBuffCon:SetActive(true)
		self.noneBuff:SetActive(false)

		if not self.skills then
			self.skills = xyd.models.dress:getActiveSkills()

			self:waitForFrame(1, function ()
				self.showBuffsSumArr = self:getBuffsInfo(self.skills)

				self.skillWrapContent:setInfos(self:getBuffsInfo(self.skills), {})
				self:waitForFrame(1, function ()
					self.skillScroller_UIScrollView:ResetPosition()
				end)
			end)
		else
			self.showBuffsSumArr = self:getBuffsInfo(xyd.models.dress:getActiveSkills())

			self.skillWrapContent:setInfos(self.showBuffsSumArr, {})
			self:waitForFrame(1, function ()
				self.skillScroller_UIScrollView:ResetPosition()
			end)
		end
	end
end

function DressMainWindow:getBuffsInfo(skills)
	local buffs_arr = {}

	for i, skill_id in pairs(skills) do
		local style_id = xyd.tables.senpaiDressSkillTable:getStyle(skill_id)
		local nums = xyd.tables.senpaiDressSkillTable:getNums(skill_id)
		local is_percent = xyd.tables.senpaiDressSkillTable:getIsPercent(skill_id)

		for i in pairs(nums) do
			if is_percent and is_percent[i] and is_percent[i] == 1 then
				nums[i] = nums[i] * 100
			end
		end

		if not buffs_arr[style_id] then
			buffs_arr[style_id] = {
				style_id = style_id,
				nums = nums,
				first_id = xyd.tables.senpaiDressSkillTable:getFirstId(skill_id)
			}
		else
			buffs_arr[style_id].nums[1] = buffs_arr[style_id].nums[1] + nums[1]
		end
	end

	local return_arr = {}

	for i in pairs(buffs_arr) do
		table.insert(return_arr, buffs_arr[i])
	end

	dump(return_arr, "bufss_show(dress_main_window)")

	return return_arr
end

function DressMainWindow:updateDownChangeScroller(pos, keepPosition)
	keepPosition = keepPosition or false
	pos = pos or 0

	if not self.areadyChnageList then
		self.areadyChnageList = {}
	end

	local dressIdList = xyd.models.dress:getHasDressIds(pos)

	if #dressIdList <= 0 then
		self.noneGroup:SetActive(true)

		self.noneGroupLabel.text = __("PERSON_DRESS_MAIN_" .. pos + 16)

		self.multiWrap_:setInfos({}, {})
	else
		self.noneGroup:SetActive(false)

		if not self.areadyChnageList[pos] then
			local downChangeList = {}

			for _, dress_id in ipairs(dressIdList) do
				local items = xyd.tables.senpaiDressTable:getItems(dress_id)
				local style_id = xyd.tables.senpaiDressTable:getStyles(dress_id)[1]
				local local_choice = xyd.models.dress:getLocalChoice(dress_id)

				if local_choice then
					local all_styles = xyd.tables.senpaiDressTable:getStyles(dress_id)

					for k in pairs(all_styles) do
						if all_styles[k] == local_choice then
							style_id = xyd.tables.senpaiDressTable:getStyles(dress_id)[k]

							break
						end
					end
				end

				table.insert(downChangeList, {
					style_id = style_id,
					dress_id = dress_id,
					name = xyd.tables.itemTable:getName(items[1])
				})
			end

			self:sortDownChangeList(downChangeList)

			self.areadyChnageList[pos] = downChangeList
		end

		self.multiWrap_:setInfos(self.areadyChnageList[pos], {
			keepPosition = keepPosition
		})

		if not keepPosition then
			self.itemScroller_UIScrollView:ResetPosition()
		end
	end
end

function DressMainWindow:sortDownChangeList(list)
	table.sort(list, function (a, b)
		local a_item = xyd.tables.senpaiDressTable:getItems(a.dress_id)[1]
		local a_qlt = xyd.tables.itemTable:getQuality(a_item)
		local b_item = xyd.tables.senpaiDressTable:getItems(b.dress_id)[1]
		local b_qlt = xyd.tables.itemTable:getQuality(b_item)

		if a_qlt ~= b_qlt then
			return b_qlt < a_qlt
		else
			return a_item < b_item
		end
	end)
end

function DressMainWindow:updateDressIconShowNum(style_id)
	if not self.isEdit then
		return
	end

	local pos = xyd.tables.senpaiDressStyleTable:getPos(style_id)

	if self.downChangeChoiceIndex and self.downChangeChoiceIndex == pos or self.downChangeChoiceIndex == 0 then
		if self.downChangeChoiceIndex == 0 then
			pos = 0
		end
	else
		return
	end

	local dress_id = xyd.tables.senpaiDressStyleTable:getDressId(style_id)

	if not self.areadyChnageList[pos] then
		return
	end

	local list = self.multiWrap_:getItems()

	for i in pairs(list) do
		if list[i]:getDressId() == dress_id then
			list[i]:setIsMustUpdate(true)

			break
		end
	end

	self.multiWrap_:setInfos(self.list, {
		keepPosition = true
	})
	self:waitForFrame(5, function ()
		for i in pairs(list) do
			if list[i]:getDressId() == dress_id then
				list[i]:setIsMustUpdate(false)

				break
			end
		end
	end)
end

function DressMainWindow:downChangeOnQualityBtn(index, isInit)
	local isPlaySoundId = true

	if self.downChangeShowQuality ~= index or index == -1 or isInit then
		if index == -1 then
			index = 0
		end

		isPlaySoundId = false
		local pos = self["downChangebtnCircle" .. index].transform.localPosition

		self.downChangebtnQualityChosen:SetLocalPosition(pos.x, pos.y, pos.z)

		self.downChangeShowQuality = index
	elseif self.downChangeShowQuality == index then
		if self.downChangeShowQuality == 0 then
			return
		else
			self:downChangeOnQualityBtn(0)

			return
		end
	end

	if isPlaySoundId then
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
	end

	self:updateDownChangeScroller(index)
end

function DressMainWindow:updateEditShowItems(styleID, pos, isEntryAppointType)
	pos = pos or 0

	if styleID ~= 0 then
		local pos = xyd.tables.senpaiDressStyleTable:getPos(styleID)
		self.showItemStyles[pos] = styleID
	elseif styleID == 0 then
		self.showItemStyles[pos] = 0
	end

	self:updateEuqip(true)

	if isEntryAppointType then
		self:entryEdit(pos)
	else
		self:updateDownChangeScroller(self.downChangeShowQuality, true)
	end
end

function DressMainWindow:updateEditShowItemsGroup(styleIDs, isEntryAppointType)
	local ids = {
		0,
		0,
		0,
		0,
		0
	}

	for i, styleID in pairs(styleIDs) do
		if styleID and styleID ~= 0 then
			local pos = xyd.tables.senpaiDressStyleTable:getPos(styleID)
			ids[pos] = styleID
		end
	end

	for i in pairs(ids) do
		self.showItemStyles[i] = ids[i]
	end

	self:updateEuqip(true)

	if isEntryAppointType then
		self:entryEdit(0)
	else
		self:updateDownChangeScroller(self.downChangeShowQuality, true)
	end
end

function DressMainWindow:getShowItemStyles()
	return self.showItemStyles
end

function DressMainWindow:initPageTwo()
	self.backContent = DressMainBackpackContent.new(self.page2, {})
end

function DressMainWindow:updateBackItems()
	self.backContent:updateBackItems()
end

function DressMainWindow:onQualityBtn(index)
	self.backContent:onQualityBtn(index)
end

function DressMainWindow:initPageThree()
	local item = DressMainAchievementContent.new(self.page3, {})
end

function SkillShowItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	SkillShowItem.super.ctor(self, go)

	self.skill_big_item = self.go
	self.bg = self.skill_big_item:ComponentByName("bg", typeof(UISprite))
	self.explainText = self.skill_big_item:ComponentByName("explainText", typeof(UILabel))
	self.tipBtn = self.skill_big_item:NodeByName("tipBtn").gameObject
	self.pointText = self.skill_big_item:ComponentByName("pointText", typeof(UILabel))
	self.explainText_test = self.skill_big_item:ComponentByName("explainText_test", typeof(UILabel))
	UIEventListener.Get(self.tipBtn.gameObject).onClick = handler(self, self.onTouchTip)
	self.isInit = false
end

function SkillShowItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.style_id = info.style_id
	self.nums = info.nums

	if info.first_id and info.first_id > 0 then
		local count_arr = xyd.models.dress:getActiveBuffDynamics()

		if count_arr[tostring(info.first_id)] then
			table.insert(self.nums, count_arr[tostring(info.first_id)])
		else
			table.insert(self.nums, 0)
		end
	end

	local str = xyd.tables.senpaiDressSkillBuffTextTable:getDesc(self.style_id, unpack(self.nums))
	self.explainText_test.text = str
	local height = self.explainText_test.height
	self.explainText_test.text = ""

	local function updateText()
		self.explainText.text = str

		if height > (self.explainText_test.fontSize + self.explainText_test.spacingY) * 2 then
			self.explainText.overflowMethod = UILabel.Overflow.ClampContent
			self.explainText.height = (self.explainText.fontSize + self.explainText.spacingY) * 2

			self.explainText.gameObject:Y(10)
			self.pointText.gameObject:SetActive(true)
		else
			self.explainText.overflowMethod = UILabel.Overflow.ResizeHeight

			self.explainText.gameObject:Y(0)
			self.pointText.gameObject:SetActive(false)
		end
	end

	if self.isInit then
		self:waitForFrame(1, function ()
			updateText()
		end)
	else
		updateText()
	end

	self.isInit = true
end

function SkillShowItem:onTouchTip()
	xyd.WindowManager.get():openWindow("dress_buff_show_window", {
		style_id = self.style_id,
		nums = self.nums
	})
end

function SkillShowItem2:ctor(go, parent)
	self.go = go
	self.parent = parent

	SkillShowItem2.super.ctor(self, go)
end

function SkillShowItem2:initUI()
	self.icon = self.go:ComponentByName("icon", typeof(UISprite))
	UIEventListener.Get(self.go.gameObject).onClick = handler(self, self.onTouchTip)
end

function SkillShowItem2:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.style_id = info.style_id
	self.nums = info.nums

	if info.first_id and info.first_id > 0 then
		local count_arr = xyd.models.dress:getActiveBuffDynamics()

		if count_arr[tostring(info.first_id)] then
			table.insert(self.nums, count_arr[tostring(info.first_id)])
		else
			table.insert(self.nums, 0)
		end
	end

	local iconName = xyd.tables.senpaiDressSkillBuffTable:getIcon(self.style_id)
	local scale = xyd.tables.senpaiDressSkillBuffTable:getScale(self.style_id)

	if not scale or scale == 0 then
		scale = 1
	end

	xyd.setUISpriteAsync(self.icon, nil, iconName, function ()
		self.icon:SetLocalScale(scale, scale, scale)
	end, nil, true)
end

function SkillShowItem2:onTouchTip()
	xyd.WindowManager.get():openWindow("dress_buff_show_window", {
		style_id = self.style_id,
		nums = self.nums
	})
end

function ItemContent:ctor(go, parent)
	self.parent_ = parent

	ItemContent.super.ctor(self, go)
end

function ItemContent:initUI()
	self.iconGroup_ = self.go:NodeByName("iconGroup").gameObject
	self.itemName_ = self.go:ComponentByName("nameLabel", typeof(UILabel))
end

function ItemContent:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	if self.style_id and info and info.style_id and self.style_id == info.style_id then
		local pos = xyd.tables.senpaiDressStyleTable:getPos(self.style_id)
		self.dress_id = xyd.tables.senpaiDressStyleTable:getDressId(self.style_id)

		if self.dress_id == xyd.tables.senpaiDressStyleTable:getDressId(self.parent_:getShowItemStyles()[pos]) then
			info.style_id = self.parent_:getShowItemStyles()[pos]
			info.isMustUpdate = true

			self.dressIcon:setChoose(true)
		else
			self.dressIcon:setChoose(false)
		end

		if not info.isMustUpdate then
			return
		end
	end

	if info and info.style_id then
		local pos = xyd.tables.senpaiDressStyleTable:getPos(info.style_id)
		local dress_id = xyd.tables.senpaiDressStyleTable:getDressId(info.style_id)

		if dress_id == xyd.tables.senpaiDressStyleTable:getDressId(self.parent_:getShowItemStyles()[pos]) then
			info.style_id = self.parent_:getShowItemStyles()[pos]
		end
	end

	self.style_id = info.style_id
	self.dress_id = xyd.tables.senpaiDressStyleTable:getDressId(self.style_id)
	local pos = xyd.tables.senpaiDressStyleTable:getPos(self.style_id)
	self.itemName_.text = info.name
	self.info = info
	local qlt_item_id = xyd.tables.senpaiDressTable:getItems(self.dress_id)[1]
	local qlt = xyd.tables.senpaiDressItemTable:getQlt(qlt_item_id)
	local params = {
		isAddUIDragScrollView = true,
		uiRoot = self.iconGroup_,
		qlt = qlt,
		styleID = info.style_id,
		callback = function ()
			if self.dress_id ~= xyd.tables.senpaiDressStyleTable:getDressId(self.parent_:getShowItemStyles()[pos]) then
				if xyd.models.dress:checkIsCollide(self.style_id, self.parent_:getShowItemStyles()) then
					xyd.models.dress:showCollideTips(function ()
						self.parent_:updateEditShowItems(self.style_id, pos)
					end)
				else
					self.parent_:updateEditShowItems(self.style_id, pos)
				end

				return
			end

			local is_can_rm = xyd.tables.senpaiDressSlotTable:getCanRm(pos)
			local params = {
				state = 1,
				is_can_rm = is_can_rm,
				styleID = info.style_id
			}

			if self.dress_id == xyd.tables.senpaiDressStyleTable:getDressId(self.parent_:getShowItemStyles()[pos]) then
				if is_can_rm == 1 then
					params.state = 1
				else
					params.state = 3
				end
			else
				params.state = 2
			end

			xyd.WindowManager.get():openWindow("leadskin_tips_window", params)
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		end
	}

	if not self.dressIcon then
		self.dressIcon = xyd.getItemIcon(params, xyd.ItemIconType.DRESS_STYLE_ICON)
	else
		self.dressIcon:setInfo(params)
	end

	if self.dress_id == xyd.tables.senpaiDressStyleTable:getDressId(self.parent_:getShowItemStyles()[pos]) then
		self.dressIcon:setChoose(true)
	else
		self.dressIcon:setChoose(false)
	end
end

function ItemContent:getDressId()
	return self.dress_id
end

function ItemContent:setIsMustUpdate(state)
	self.isMustUpdate = state
end

return DressMainWindow
