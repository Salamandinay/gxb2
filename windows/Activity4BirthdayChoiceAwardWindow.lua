local Activity4BirthdayChoiceAwardWindow = class("Activity4BirthdayChoiceAwardWindow", import(".BaseWindow"))
local ShowIconItem = class("ShowIconItem", import("app.components.CopyComponent"))
local CommonTabBar = require("app.common.ui.CommonTabBar")
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")

function Activity4BirthdayChoiceAwardWindow:ctor(name, params)
	Activity4BirthdayChoiceAwardWindow.super.ctor(self, name, params)

	self.enterOrderIndex = params.enterOrderIndex
	self.enterId = params.enterId
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_4BIRTHDAY_MUSIC)
end

function Activity4BirthdayChoiceAwardWindow:initWindow()
	self:getUIComponent()
	Activity4BirthdayChoiceAwardWindow.super.initWindow(self)
	self:reSize()
	self:registerEvent()
	self:layout()
end

function Activity4BirthdayChoiceAwardWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bigNav = self.groupAction:NodeByName("bigNav").gameObject
	self.smallNav = self.groupAction:NodeByName("smallNav").gameObject

	for i = 1, 4 do
		self["tab_" .. i] = self.smallNav:NodeByName("tab_" .. i).gameObject
		self["unchosen" .. i] = self["tab_" .. i]:ComponentByName("unchosen", typeof(UISprite))
		self["chosen" .. i] = self["tab_" .. i]:ComponentByName("chosen", typeof(UISprite))
		self["label" .. i] = self["tab_" .. i]:ComponentByName("label", typeof(UILabel))
	end

	self.scrollView = self.groupAction:NodeByName("scrollView").gameObject
	self.scrollViewUIScrollView = self.groupAction:ComponentByName("scrollView", typeof(UIScrollView))
	self.wrapContentUIWrapContent = self.scrollView:ComponentByName("wrap_content", typeof(UIWrapContent))
	self.showItem = self.groupAction:NodeByName("showItem").gameObject
	self.wrapContent = FixedMultiWrapContent.new(self.scrollViewUIScrollView, self.wrapContentUIWrapContent, self.showItem, ShowIconItem, self)
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.upCon1 = self.upCon:NodeByName("upCon1").gameObject
	self.upConBg1 = self.upCon1:ComponentByName("upConBg1", typeof(UITexture))

	for i = 1, 6 do
		self["upConPos1_" .. i] = self.upConBg1:NodeByName("upConPos1_" .. i).gameObject
	end

	self.upCon2 = self.upCon:NodeByName("upCon2").gameObject
	self.upConBg2 = self.upCon2:ComponentByName("upConBg2", typeof(UITexture))

	for i = 1, 3 do
		self["upConPos2_" .. i] = self.upConBg2:NodeByName("upConPos2_" .. i).gameObject
	end

	self.upCon3 = self.upCon:NodeByName("upCon3").gameObject
	self.upConBg3 = self.upCon3:ComponentByName("upConBg3", typeof(UITexture))
	self["upConPos3_" .. 1] = self.upConBg3:NodeByName("upConPos3_" .. 1).gameObject
	self.downGroupCon = self.groupAction:NodeByName("downGroupCon").gameObject
	self.downGroupLine = self.downGroupCon:ComponentByName("downGroupLine", typeof(UISprite))
end

function Activity4BirthdayChoiceAwardWindow:reSize()
end

function Activity4BirthdayChoiceAwardWindow:registerEvent()
end

function Activity4BirthdayChoiceAwardWindow:layout()
	if not self.choicesInfos then
		self.choicesInfos = xyd.cloneTable(self.activityData:getChoiceAwards())
	end

	self:initSmallNav()
	self:initBigNav()
end

function Activity4BirthdayChoiceAwardWindow:initBigNav()
	local labelStates = {
		chosen = {
			color = Color.New2(4278124287.0),
			effectColor = Color.New2(2318428671.0)
		},
		unchosen = {
			color = Color.New2(960513791),
			effectColor = Color.New2(4243908351.0)
		}
	}
	self.BigTab = CommonTabBar.new(self.bigNav.gameObject, 3, function (index)
		self:updateBigNav(index)
	end, nil, labelStates)
	local texts = {
		__("ACTIVITY_4BIRTHDAY_GAMBLE_AWARD01"),
		__("ACTIVITY_4BIRTHDAY_GAMBLE_AWARD02"),
		__("ACTIVITY_4BIRTHDAY_GAMBLE_AWARD03")
	}

	self.BigTab:setTexts(texts)
	self.BigTab:setTabActive(self.enterOrderIndex, true, false)
end

function Activity4BirthdayChoiceAwardWindow:updateBigNav(index)
	print("big nav index ：", index)

	self.orderIndex = index
	local sorts = xyd.tables.activity4birthdayGambleTable:getTypeWithSorts(index)
	local allWidth = 588
	local sigleWidth = allWidth / #sorts

	for i = 1, 4 do
		local navIndex = xyd.arrayIndexOf(sorts, i)

		if navIndex > 0 then
			self["unchosen" .. i].width = sigleWidth
			self["chosen" .. i].width = sigleWidth
			self["label" .. i].width = sigleWidth - 16

			if navIndex == 1 then
				xyd.setUISpriteAsync(self["unchosen" .. i], nil, "nav_btn_white_left")
				xyd.setUISpriteAsync(self["chosen" .. i], nil, "nav_btn_blue_left")
			elseif navIndex == #sorts then
				xyd.setUISpriteAsync(self["unchosen" .. i], nil, "nav_btn_white_right")
				xyd.setUISpriteAsync(self["chosen" .. i], nil, "nav_btn_blue_right")
			else
				xyd.setUISpriteAsync(self["unchosen" .. i], nil, "nav_btn_white_mid")
				xyd.setUISpriteAsync(self["chosen" .. i], nil, "nav_btn_blue_mid")
			end

			if #sorts == 1 then
				self["tab_" .. i]:X(0)
			elseif #sorts == 2 then
				if navIndex == 1 then
					self["tab_" .. i]:X(-sigleWidth / 2)
				elseif navIndex == 2 then
					self["tab_" .. i]:X(sigleWidth / 2)
				end
			elseif #sorts == 3 then
				if navIndex == 1 then
					self["tab_" .. i]:X(-sigleWidth)
				elseif navIndex == 2 then
					self["tab_" .. i]:X(0)
				elseif navIndex == 3 then
					self["tab_" .. i]:X(sigleWidth)
				end
			elseif #sorts == 4 then
				if navIndex == 1 then
					self["tab_" .. i]:X(-sigleWidth * 1.5)
				elseif navIndex == 2 then
					self["tab_" .. i]:X(-sigleWidth * 0.5)
				elseif navIndex == 3 then
					self["tab_" .. i]:X(sigleWidth * 0.5)
				elseif navIndex == 4 then
					self["tab_" .. i]:X(sigleWidth * 1.5)
				end
			end
		else
			self["tab_" .. i].gameObject:X(-1000)
		end
	end

	self.smallTab:clearChoose()
	self.smallTab:onClickBtn(sorts[1])
	self:updateSmallNav(sorts[1])
	self:updateUpConShow(index)
end

function Activity4BirthdayChoiceAwardWindow:initSmallNav()
	local labelStates = {
		chosen = {
			color = Color.New2(4278124287.0),
			effectColor = Color.New2(1012112383)
		},
		unchosen = {
			color = Color.New2(960513791),
			effectColor = Color.New2(4294967295.0)
		}
	}
	self.smallTab = CommonTabBar.new(self.smallNav.gameObject, 4, function (index)
		self:updateSmallNav(index)
	end, nil, labelStates)
	local texts = {
		__("ACTIVITY_4BIRTHDAY_GAMBLE_AWARD_TYPE01"),
		__("ACTIVITY_4BIRTHDAY_GAMBLE_AWARD_TYPE02"),
		__("ACTIVITY_4BIRTHDAY_GAMBLE_AWARD_TYPE03"),
		__("ACTIVITY_4BIRTHDAY_GAMBLE_AWARD_TYPE04")
	}

	self.smallTab:setTexts(texts)

	local sorts = xyd.tables.activity4birthdayGambleTable:getTypeWithSorts(self.enterOrderIndex)

	self.smallTab:setTabActive(sorts[1], true, false)
end

function Activity4BirthdayChoiceAwardWindow:updateSmallNav(index)
	print("small nav index ：", index)

	self.sortIndex = index
	self.curPartnerIndex = 0

	if not self.partnerFilter then
		local params = {
			isCanUnSelected = 1,
			scale = 1,
			gap = 13,
			callback = handler(self, function (self, group)
				self:updateSelectGroup(group)
			end),
			width = self.downGroupCon:GetComponent(typeof(UIWidget)).width,
			chosenGroup = self.curPartnerIndex
		}
		self.partnerFilter = import("app.components.PartnerFilter").new(self.downGroupCon.gameObject, params)

		self.partnerFilter:getGameObject():Y(-470)
		self.partnerFilter:hideGroup(xyd.PartnerGroup.TIANYI)
	end

	self.partnerFilter:updateChooseGroup(0)

	self.downGroupLine.alpha = 0.02

	if index == xyd.Activity4BirthdayMusicSortType.SKIN or index == xyd.Activity4BirthdayMusicSortType.PARTNER then
		self.downGroupLine.gameObject:Y(-426.1)
	else
		self.downGroupLine.gameObject:Y(-470.8)
	end

	self:waitForFrame(1, function ()
		self.wrapContent:setInfos(self:getInfos().award, {})
		self.scrollViewUIScrollView:ResetPosition()

		if index == xyd.Activity4BirthdayMusicSortType.SKIN or index == xyd.Activity4BirthdayMusicSortType.PARTNER then
			self.partnerFilter:getGameObject():SetActive(true)
		else
			self.partnerFilter:getGameObject():SetActive(false)
		end

		self.downGroupLine.alpha = 1
	end)
end

function Activity4BirthdayChoiceAwardWindow:getInfos()
	print(self.orderIndex, "test1")
	print(self.sortIndex, "test2")

	return xyd.tables.activity4birthdayGambleTable:getInfos(self.orderIndex, self.sortIndex)
end

function Activity4BirthdayChoiceAwardWindow:updateSelectGroup(index)
	self.curPartnerIndex = index

	self.wrapContent:setInfos(xyd.tables.activity4birthdayGambleTable:getSortPartnerGroupArr(self.orderIndex, self.sortIndex, self.curPartnerIndex).award, {})
	self.scrollViewUIScrollView:ResetPosition()
end

function Activity4BirthdayChoiceAwardWindow:updateUpConShow(index)
	for i = 1, 3 do
		if i == index then
			self["upCon" .. i]:SetActive(true)
		else
			self["upCon" .. i]:SetActive(false)
		end
	end

	for i, choiceIndexInfo in pairs(self.choicesInfos[index]) do
		if not self.showTweenIconArr then
			self.showTweenIconArr = {}
		end

		if not self.showTweenIconArr[index] then
			self.showTweenIconArr[index] = {}
		end

		if choiceIndexInfo.sort == 0 then
			if self.showTweenIconArr[index][i] then
				self.showTweenIconArr[index][i]:SetActive(false)
			end
		else
			local award = xyd.tables.activity4birthdayGambleTable:getInfos(index, choiceIndexInfo.sort).award[choiceIndexInfo.index].item
			local params = {
				noClickSelected = true,
				scale = 1,
				uiRoot = self["upConPos" .. index .. "_" .. i],
				itemID = award[1],
				num = award[2],
				callback = function ()
					if choiceIndexInfo.isGet and choiceIndexInfo.isGet == 1 then
						local params = {
							itemID = award[1]
						}

						xyd.WindowManager.get():openWindow("item_tips_window", params)

						return
					end

					self:showTweenFun(nil, false, nil, i)
				end,
				longPressCallBackFun = function ()
					local params = {
						itemID = award[1]
					}

					xyd.WindowManager.get():openWindow("item_tips_window", params)
				end
			}

			if not self.showTweenIconArr[index][i] then
				self.showTweenIconArr[index][i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
			else
				self.showTweenIconArr[index][i]:setInfo(params)
			end

			self.showTweenIconArr[index][i]:getGameObject():SetLocalScale(0.76, 0.76, 1)
			self.showTweenIconArr[index][i]:SetActive(true)

			if choiceIndexInfo.isGet and choiceIndexInfo.isGet == 1 then
				self.showTweenIconArr[index][i]:setChoose(true)
			end
		end
	end
end

function Activity4BirthdayChoiceAwardWindow:getFlyPos(sort, index)
	if sort and index then
		for i, info in pairs(self.choicesInfos[self.orderIndex]) do
			if info.sort == sort and info.index == index then
				return i
			end
		end

		return 0
	end

	for i, info in pairs(self.choicesInfos[self.orderIndex]) do
		if info.sort == 0 then
			return i
		end
	end

	return 0
end

function Activity4BirthdayChoiceAwardWindow:showTweenFun(info, isShow, position, pos)
	if self.showTweenSequence then
		self.showTweenSequence:Kill(true)

		self.showTweenSequence = nil
	end

	if isShow then
		if self.showTweenIconArr[self.orderIndex][pos] then
			self.showTweenIconArr[self.orderIndex][pos]:getGameObject():SetActive(true)
		end

		self.choicesInfos[self.orderIndex][pos].sort = self.sortIndex
		self.choicesInfos[self.orderIndex][pos].index = info.index
	else
		if self.showTweenIconArr[self.orderIndex][pos] then
			self.showTweenIconArr[self.orderIndex][pos]:getGameObject():SetActive(false)
		end

		local oldSort = self.choicesInfos[self.orderIndex][pos].sort
		local oldIndex = self.choicesInfos[self.orderIndex][pos].index
		self.choicesInfos[self.orderIndex][pos].sort = 0
		self.choicesInfos[self.orderIndex][pos].index = 0
		local items = self.wrapContent:getItems()

		for i in pairs(items) do
			if items[i]:getSort() == oldSort and items[i]:getIndex() == oldIndex then
				items[i]:checkChoose()
			end
		end

		return
	end

	local params = {
		noClickSelected = true,
		itemID = info.item[1],
		num = info.item[2],
		uiRoot = self["upConPos" .. self.orderIndex .. "_" .. pos],
		callback = function ()
			self:showTweenFun(nil, false, nil, pos)
		end,
		longPressCallBackFun = function ()
			local params = {
				itemID = info.item[1]
			}

			xyd.WindowManager.get():openWindow("item_tips_window", params)
		end
	}

	if not self.showTweenIconArr[self.orderIndex][pos] then
		self.showTweenIconArr[self.orderIndex][pos] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	else
		self.showTweenIconArr[self.orderIndex][pos]:setInfo(params)
	end

	local posold = self["upConPos" .. self.orderIndex .. "_" .. pos].gameObject.transform:InverseTransformPoint(position)

	self.showTweenIconArr[self.orderIndex][pos]:getGameObject():SetLocalScale(1, 1, 1)
	self.showTweenIconArr[self.orderIndex][pos]:getGameObject():SetLocalPosition(posold.x, posold.y, posold.z)

	local oldLoaclPosition = self.showTweenIconArr[self.orderIndex][pos]:getGameObject().transform.localPosition

	self.showTweenIconArr[self.orderIndex][pos]:getGameObject():SetLocalPosition(oldLoaclPosition.x + (0 - oldLoaclPosition.x) * 0.2, oldLoaclPosition.y + (0 - oldLoaclPosition.y) * 0.2, posold.z)

	local function setter1(value)
		local x = oldLoaclPosition.x + (0 - oldLoaclPosition.x) * value
		local y = oldLoaclPosition.y + (0 - oldLoaclPosition.y) * value

		self.showTweenIconArr[self.orderIndex][pos]:getGameObject():SetLocalPosition(x, y, 1)

		local scale = 1 + -0.24 * value

		self.showTweenIconArr[self.orderIndex][pos]:getGameObject():SetLocalScale(scale, scale, 1)
	end

	local tween = self:getSequence()

	tween:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0.2, 1, 0.15))
	tween:AppendCallback(function ()
		if tween then
			tween:Kill(true)
		end

		self.showTweenIconArr[self.orderIndex][pos]:getGameObject():SetLocalPosition(0, 0, 1)
		self.showTweenIconArr[self.orderIndex][pos]:getGameObject():SetLocalScale(0.76, 0.76, 1)

		self.showTweenSequence = nil
	end)

	self.showTweenSequence = tween
end

function Activity4BirthdayChoiceAwardWindow:willClose()
	if self.activityData:getIsLocalRoundStart() then
		local isTipsEmptyToBefor = false

		for i, infos in pairs(self.choicesInfos) do
			for j in pairs(infos) do
				if infos[j].sort == 0 or infos[j].index == 0 then
					isTipsEmptyToBefor = true
					infos[j].sort = self.activityData:getChoiceAwards()[i][j].sort
					infos[j].index = self.activityData:getChoiceAwards()[i][j].index
				end
			end
		end

		if isTipsEmptyToBefor then
			xyd.alertTips(__("ACTIVITY_4BIRTHDAY_GAMBLE_TIPS07"))
		end
	end

	local isSame = true

	for i, infos in pairs(self.choicesInfos) do
		for j in pairs(infos) do
			if infos[j].sort ~= self.activityData:getChoiceAwards()[i][j].sort or infos[j].index ~= self.activityData:getChoiceAwards()[i][j].index then
				isSame = false

				break
			end
		end
	end

	print("isSame:", isSame)

	local num = 0

	for i, info in pairs(self.choicesInfos) do
		for j, littleInfo in pairs(info) do
			if littleInfo.sort > 0 and littleInfo.index > 0 then
				num = num + 1
			end
		end
	end

	if not isSame then
		self.activityData:saveChoiceAwards(self.choicesInfos)

		if num < 10 then
			local activityWd = xyd.WindowManager.get():getWindow("activity_window")

			if activityWd then
				local curContent = activityWd:getCurContent()

				if curContent:getActivityContentID() == xyd.ActivityID.ACTIVITY_4BIRTHDAY_MUSIC then
					curContent:updateAllShow()
				end
			end
		end
	elseif num >= 10 then
		self.activityData:checkSpecialSaveChoiceAwards(self.choicesInfos)
	end

	Activity4BirthdayChoiceAwardWindow.super.willClose(self)
end

function ShowIconItem:ctor(goItem, parent)
	self.goItem_ = goItem
	self.parent = parent

	ShowIconItem.super.ctor(self, goItem)
end

function ShowIconItem:getUIComponent()
	self.itemCon = self.go:NodeByName("itemCon").gameObject
	self.isHasImg = self.itemCon:ComponentByName("isHasImg", typeof(UISprite))
end

function ShowIconItem:initUI()
	self:getUIComponent()
	xyd.setUISpriteAsync(self.isHasImg, nil, "activity_4birthday_musci_bg_yhd_" .. xyd.Global.lang, nil, , true)
end

function ShowIconItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.data = info
	self.itemId = info.item[1]
	self.itemNum = info.item[2]
	self.index = info.index
	self.sort = info.sort
	local params = {
		isAddUIDragScrollView = true,
		noClickSelected = true,
		scale = 1,
		uiRoot = self.itemCon.gameObject,
		itemID = self.itemId,
		num = self.itemNum,
		callback = handler(self, self.onTouch),
		longPressCallBackFun = handler(self, self.onTouchLong)
	}

	if not self.icon then
		self.icon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	else
		self.icon:setInfo(params)
	end

	self:checkChoose()
	self.isHasImg:SetActive(false)

	if self.sort == xyd.Activity4BirthdayMusicSortType.SKIN and xyd.models.slot:getSkinTotalNum(self.itemId) > 0 then
		self.isHasImg:SetActive(true)
	end
end

function ShowIconItem:onTouch()
	local pos = self.parent:getFlyPos(self.data.sort, self.data.index)

	if pos == 0 then
		pos = self.parent:getFlyPos()

		if pos ~= 0 then
			self.parent:showTweenFun(self.data, true, self.icon:getGameObject().transform.position, pos)
			self:updateItemChoose(true)
		else
			xyd.alertTips(__("ACTIVITY_4BIRTHDAY_GAMBLE_TIPS03"))
		end
	else
		local isGet = self.parent.choicesInfos[self.parent.orderIndex][pos].isGet

		if isGet and isGet == 1 then
			xyd.alertTips(__("ACTIVITY_4BIRTHDAY_GAMBLE_TIPS06"))

			return
		end

		self.parent:showTweenFun(self.data, false, nil, pos)
		self:updateItemChoose(false)
	end
end

function ShowIconItem:updateItemChoose(state)
	self.icon:setChoose(state)
end

function ShowIconItem:checkChoose()
	local pos = self.parent:getFlyPos(self.data.sort, self.data.index)

	if pos ~= 0 then
		self:updateItemChoose(true)
	else
		self:updateItemChoose(false)
	end
end

function ShowIconItem:getSort()
	return self.sort
end

function ShowIconItem:getIndex()
	return self.index
end

function ShowIconItem:onTouchLong()
	local params = {
		itemID = self.itemId
	}

	xyd.WindowManager.get():openWindow("item_tips_window", params)
end

return Activity4BirthdayChoiceAwardWindow
