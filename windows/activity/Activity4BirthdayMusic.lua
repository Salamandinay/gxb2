local ActivityContent = import(".ActivityContent")
local Activity4BirthdayMusic = class("Activity4BirthdayMusic", ActivityContent)
local PaoPaoItem = class("PaoPaoItem", import("app.components.CopyComponent"))

function Activity4BirthdayMusic:ctor(parentGO, params, parent)
	Activity4BirthdayMusic.super.ctor(self, parentGO, params, parent)
end

function Activity4BirthdayMusic:getPrefabPath()
	return "Prefabs/Windows/activity/activity_4birthday_music"
end

function Activity4BirthdayMusic:initUI()
	self:getUIComponent()
	Activity4BirthdayMusic.super.initUI(self)
	self:initUIComponent()
end

function Activity4BirthdayMusic:getUIComponent()
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.logoTextImg = self.upCon:ComponentByName("logoTextImg", typeof(UISprite))
	self.helpBtn = self.upCon:NodeByName("helpBtn").gameObject
	self.awardBtn = self.upCon:NodeByName("awardBtn").gameObject
	self.awardBtnRed = self.awardBtn:NodeByName("awardBtnRed").gameObject
	self.currencyCon = self.upCon:NodeByName("currencyCon").gameObject
	self.currencyBg = self.currencyCon:ComponentByName("currencyBg", typeof(UISprite))
	self.currencyIcon = self.currencyCon:ComponentByName("currencyIcon", typeof(UISprite))
	self.currencyLabel = self.currencyCon:ComponentByName("currencyLabel", typeof(UILabel))
	self.currencyPlus = self.currencyCon:ComponentByName("currencyPlus", typeof(UISprite))
	self.rainbowImg = self.groupAction:ComponentByName("rainbowImg", typeof(UITexture))
	self.personEffectCon = self.groupAction:ComponentByName("personEffectCon", typeof(UITexture))
	self.paopaoConItem = self.groupAction:NodeByName("paopaoConItem").gameObject
	self.paopaoCon = self.groupAction:NodeByName("paopaoCon").gameObject

	for i = 1, 10 do
		self["paopaoCon" .. i] = self.paopaoCon:NodeByName("paopaoCon" .. i).gameObject
	end

	self.downBtnCon = self.groupAction:NodeByName("downBtnCon").gameObject
	self.oneBtn = self.downBtnCon:NodeByName("oneBtn").gameObject
	self.fiveBtn = self.downBtnCon:NodeByName("fiveBtn").gameObject
	self.oneBtnLabel = self.downBtnCon:ComponentByName("oneBtnLabel", typeof(UILabel))
	self.fiveBtnLabel = self.downBtnCon:ComponentByName("fiveBtnLabel", typeof(UILabel))
end

function Activity4BirthdayMusic:loadRes()
	local res = xyd.getEffectFilesByNames({
		"activity_4birthday_award01"
	})
	local allHasRes = xyd.isAllPathLoad(res)

	if allHasRes then
		return
	else
		ResCache.DownloadAssets("activity_4birthday_music", res, function (success)
			xyd.WindowManager.get():closeWindow("res_loading_window")

			if tolua.isnull(self.go) then
				return
			end
		end, function (progress)
			local loading_win = xyd.WindowManager.get():getWindow("res_loading_window")

			if progress >= 1 and not loading_win then
				return
			end

			if not loading_win then
				xyd.WindowManager.get():openWindow("res_loading_window", {})
			end

			loading_win = xyd.WindowManager.get():getWindow("res_loading_window")

			loading_win:setLoadWndName("activity_4birthday_music_load_wd")
			loading_win:setLoadProgress("activity_4birthday_music_load_wd", progress)
		end, 1)
	end
end

function Activity4BirthdayMusic:initUIComponent()
	self:loadRes()

	self.oneBtnLabel.text = __("ACTIVITY_4BIRTHDAY_GAMBLE_BUTTON01")
	self.fiveBtnLabel.text = __("ACTIVITY_4BIRTHDAY_GAMBLE_BUTTON02")

	xyd.setUISpriteAsync(self.logoTextImg, nil, "activity_4birthday_musci_logo_" .. xyd.Global.lang, nil, , true)

	self.personEffect = xyd.Spine.new(self.personEffectCon.gameObject)

	self.personEffect:setInfo("activity_4birthday_gamble", function ()
		self.personEffect:play("idle", 0)
	end)

	for i = 1, 10 do
		local tmp = NGUITools.AddChild(self["paopaoCon" .. i].gameObject, self.paopaoConItem.gameObject)
		self["paopao" .. i] = PaoPaoItem.new(tmp, self, i)
	end

	self.currencyItemArr = xyd.tables.miscTable:split2num("activity_4birthday_gamble_cost", "value", "#")

	xyd.setUISpriteAsync(self.currencyIcon, nil, xyd.tables.itemTable:getIcon(self.currencyItemArr[1]), function ()
		self.currencyIcon:SetLocalScale(0.45, 0.45, 0.45)
	end, nil, true)
	self:updateCurrencyLabel()
	self.awardBtnRed.gameObject:SetActive(false)

	local clickShowViewBtnTime = xyd.db.misc:getValue("activity_4birthday_music_click_showview_btn_time")

	if not clickShowViewBtnTime then
		self.awardBtnRed.gameObject:SetActive(true)
	else
		clickShowViewBtnTime = tonumber(clickShowViewBtnTime)

		if clickShowViewBtnTime < self.activityData:startTime() or self.activityData:getEndTime() < clickShowViewBtnTime then
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_4BIRTHDAY_MUSIC, true)
			self.awardBtnRed.gameObject:SetActive(true)
		end
	end
end

function Activity4BirthdayMusic:onRegister()
	Activity4BirthdayMusic.super.onRegister(self)

	UIEventListener.Get(self.oneBtn.gameObject).onClick = handler(self, function ()
		self:sendAward(1)
	end)
	UIEventListener.Get(self.fiveBtn.gameObject).onClick = handler(self, function ()
		self:sendAward(5)
	end)

	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateCurrencyLabel))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	local function goWayFun()
		local costArr = xyd.tables.miscTable:split2num("activity_4birthday_gamble_cost", "value", "#")

		xyd.WindowManager.get():openWindow("activity_item_getway_window", {
			itemID = costArr[1]
		})
	end

	UIEventListener.Get(self.currencyPlus.gameObject).onClick = handler(self, function ()
		goWayFun()
	end)
	UIEventListener.Get(self.currencyBg.gameObject).onClick = handler(self, function ()
		goWayFun()
	end)
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_4BIRTHDAY_GAMBLE_HELP"
		})
	end)
	UIEventListener.Get(self.awardBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_4birthday_music_award_view_window", {})

		if self.awardBtnRed.gameObject.activeSelf then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_4BIRTHDAY_MUSIC, function ()
				xyd.db.misc:setValue({
					key = "activity_4birthday_music_click_showview_btn_time",
					value = xyd.getServerTime()
				})
			end)
			self.awardBtnRed.gameObject:SetActive(false)
		end
	end)
end

function Activity4BirthdayMusic:sendAward(num)
	local choiceInfos = self.activityData:getChoiceAwards()

	for i, infos in pairs(choiceInfos) do
		for j in pairs(infos) do
			if infos[j].sort == 0 or infos[j].index == 0 then
				xyd.alertTips(__("ACTIVITY_4BIRTHDAY_GAMBLE_TIPS01"))

				return
			end
		end
	end

	if self.isPlayingEffect then
		xyd.alertTips(__("ACTIVITY_4BIRTHDAY_GAMBLE_TIPS05"))

		return
	end

	local costArr = xyd.tables.miscTable:split2num("activity_4birthday_gamble_cost", "value", "#")
	local needNum = costArr[2] * num

	if xyd.models.backpack:getItemNumByID(costArr[1]) < needNum then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(costArr[1])))

		return
	end

	local isGetNum = 0

	for i = 1, 10 do
		local isGet = self["paopao" .. i]:getIsGet()

		if isGet and isGet == 1 then
			isGetNum = isGetNum + 1
		end
	end

	local isNotGetNum = 10 - isGetNum

	if num > isNotGetNum then
		xyd.alertTips(__("ACTIVITY_4BIRTHDAY_GAMBLE_TIPS04"))

		return
	end

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_4BIRTHDAY_MUSIC, require("cjson").encode({
		type = xyd.Activity4BirthdayMusicReqType.GET_AWARD,
		num = num
	}))
end

function Activity4BirthdayMusic:onAward(event)
	local data = event.data

	if data.activity_id ~= xyd.ActivityID.ACTIVITY_4BIRTHDAY_MUSIC then
		return
	end

	local data = xyd.decodeProtoBuf(data)
	local info = require("cjson").decode(data.detail)
	local type = info.type

	if type == xyd.Activity4BirthdayMusicReqType.CHOICE then
		self:updateAllShow()
	elseif type == xyd.Activity4BirthdayMusicReqType.GET_AWARD then
		local isGetNum = 0
		self.noGetArr = {}
		self.willBoomArr = xyd.cloneTable(info.indexs)

		for i = 1, 10 do
			local isGet = self["paopao" .. i]:getIsGet()

			if isGet and isGet == 1 then
				isGetNum = isGetNum + 1
			else
				table.insert(self.noGetArr, i)
			end
		end

		self.allShineNum = 10 - isGetNum
		self.isGetAllThisTime = nil

		if self.allShineNum == #self.willBoomArr then
			self.isGetAllThisTime = true
		end

		self.emptyShineNum = self.allShineNum - #info.indexs
		self.boomShineNum = #info.indexs
		self.shineYetNum = 0
		self.isPlayingEffect = true

		self:playShineFun(info)
	end
end

function Activity4BirthdayMusic:playShineFun(info)
	self:waitForTime(0.15, function ()
		if self.shineYetNum < self.emptyShineNum then
			local randomIndex = math.ceil(math.random() * #self.noGetArr)

			self["paopao" .. self.noGetArr[randomIndex]]:showEffect(false)
			table.remove(self.noGetArr, randomIndex)

			self.shineYetNum = self.shineYetNum + 1

			self:playShineFun(info)
		else
			local randomIndex = math.ceil(math.random() * #self.willBoomArr)

			self["paopao" .. self.willBoomArr[randomIndex]]:showEffect(true)

			self.shineYetNum = self.shineYetNum + 1

			table.remove(self.willBoomArr, randomIndex)

			if self.shineYetNum < self.allShineNum then
				self:playShineFun(info)
			else
				if self.isGetAllThisTime then
					self:waitForTime(1.5, function ()
						self:updateAllShow()
					end)
				end

				self:waitForTime(1.2, function ()
					local isGetNum = 0
					local choiceInfos = self.activityData:getChoiceAwards()

					for i, infos in pairs(choiceInfos) do
						for j in pairs(infos) do
							if infos[j].isGet and infos[j].isGet == 1 then
								isGetNum = isGetNum + 1
							end
						end
					end

					local isNotGetNum = 10 - isGetNum
					local params = {
						wnd_type = 4,
						data = info.items,
						sureCallback = function ()
							print("回來了：", self.isGetAllThisTime)

							if self.isGetAllThisTime then
								self:updateAllShow()
								xyd.alertYesNo(__("ACTIVITY_4BIRTHDAY_GAMBLE_TIPS02"), function (yes_no)
									if yes_no then
										xyd.WindowManager.get():openWindow("activity_4birthday_choice_award_window", {
											enterId = 1,
											enterOrderIndex = 1
										})
									end
								end)
							end
						end
					}
					local costArr = xyd.tables.miscTable:split2num("activity_4birthday_gamble_cost", "value", "#")
					local nowHasNum = math.floor(xyd.models.backpack:getItemNumByID(costArr[1]) / costArr[2])

					if nowHasNum <= 0 or isNotGetNum >= 10 or self.isGetAllThisTime then
						params.isNeedCostBtn = false
					else
						if nowHasNum < isNotGetNum then
							isNotGetNum = nowHasNum
						end

						costArr[2] = costArr[2] * isNotGetNum
						params.cost = costArr
						params.btnLabelText = __("GACHA_LIMIT_CALL_TIMES", isNotGetNum)

						function params.buyCallback()
							self:sendAward(isNotGetNum)
							xyd.closeWindow("gamble_rewards_window")
						end
					end

					xyd.openWindow("gamble_rewards_window", params)

					self.isPlayingEffect = false
				end)
			end
		end
	end)
end

function Activity4BirthdayMusic:resizeToParent()
	Activity4BirthdayMusic.super.resizeToParent(self)
	self:resizePosY(self.upCon.gameObject, 361.3, 442)
	self:resizePosY(self.downBtnCon.gameObject, -361, -423)
	self:resizePosY(self.rainbowImg.gameObject, -18, -2)
end

function Activity4BirthdayMusic:updateCurrencyLabel()
	self.currencyLabel.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(self.currencyItemArr[1]))
end

function Activity4BirthdayMusic:updateAllShow()
	for i = 1, 10 do
		self["paopao" .. i]:updateShow()
	end
end

function PaoPaoItem:ctor(goItem, parent, index)
	self.parent = parent
	self.index = index
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_4BIRTHDAY_MUSIC)

	PaoPaoItem.super.ctor(self, goItem)
end

function PaoPaoItem:getUIComponent()
	self.paopaoImgBg = self.go:ComponentByName("paopaoImgBg", typeof(UISprite))
	self.paopaoAddBtn = self.go:NodeByName("paopaoAddBtn").gameObject
	self.paopaoItemCon = self.go:NodeByName("paopaoItemCon").gameObject
	self.paopaoIconCon = self.go:NodeByName("paopaoIconCon").gameObject
	self.paopaoIconImg = self.paopaoIconCon:ComponentByName("paopaoIconImg", typeof(UISprite))
	self.paopaoIconLabel = self.paopaoIconCon:ComponentByName("paopaoIconLabel", typeof(UILabel))
	self.paopaoImgBgUp = self.go:ComponentByName("paopaoImgBgUp", typeof(UISprite))
	self.paopaoIconSelect = self.go:ComponentByName("paopaoIconSelect", typeof(UISprite))
	self.choiceBtn = self.go:NodeByName("choiceBtn").gameObject
	self.effectCon = self.go:ComponentByName("effectCon", typeof(UITexture))
	UIEventListener.Get(self.paopaoImgBg.gameObject).onClick = handler(self, self.onTouch)
end

function PaoPaoItem:initUI()
	self:getUIComponent()

	local awardLevelArr = xyd.tables.miscTable:split2num("activity_4birthday_gamble_type_num", "value", "|")
	local idIndexArr = {}

	for i in pairs(awardLevelArr) do
		idIndexArr[i] = awardLevelArr[i]

		if i > 1 then
			for j = 1, i - 1 do
				idIndexArr[i] = idIndexArr[i] + awardLevelArr[j]
			end
		end
	end

	for i in pairs(idIndexArr) do
		if self.index <= idIndexArr[i] then
			xyd.setUISpriteAsync(self.paopaoImgBg, nil, "activity_4birthday_musci_paopao_" .. i)
			xyd.setUISpriteAsync(self.paopaoImgBgUp, nil, "activity_4birthday_musci_paopao_" .. i)

			self.orderIndex = i

			break
		end
	end

	self.littleIndex = self.index

	if self.orderIndex == 2 then
		self.littleIndex = self.index - awardLevelArr[1]
	elseif self.orderIndex == 3 then
		self.littleIndex = self.index - awardLevelArr[1] - awardLevelArr[2]
	end

	self:updateShow()
	self.go.gameObject:Y(-6)
	self:waitForTime(0.3 * self.index, function ()
		self:movePaoPao()
	end)
end

function PaoPaoItem:movePaoPao()
	if self.sequence1_ then
		self.sequence1_:Kill(false)

		self.sequence1_ = nil
	end

	if self.sequence2_ then
		self.sequence2_:Kill(false)

		self.sequence2_ = nil
	end

	self.go.gameObject:Y(-6)

	function self.playAni2_()
		if not self.sequence2_ then
			self.sequence2_ = self:getSequence()

			self.sequence2_:Insert(0, self.go.transform:DOLocalMove(Vector3(0, 6, 0), 2, false))
			self.sequence2_:Insert(1, self.go.transform:DOLocalMove(Vector3(0, -6, 0), 2, false))
			self.sequence2_:AppendCallback(function ()
				self.playAni1_()
			end)
			self.sequence2_:SetAutoKill(false)
		else
			self.sequence2_:Restart()
		end
	end

	function self.playAni1_()
		if not self.sequence1_ then
			self.sequence1_ = self:getSequence()

			self.sequence1_:Insert(0, self.go.transform:DOLocalMove(Vector3(0, 6, 0), 2, false))
			self.sequence1_:Insert(1, self.go.transform:DOLocalMove(Vector3(0, -6, 0), 2, false))
			self.sequence1_:AppendCallback(function ()
				self.playAni2_()
			end)
			self.sequence1_:SetAutoKill(false)
		else
			self.sequence1_:Restart()
		end
	end

	self.playAni1_()
end

function PaoPaoItem:updateShow()
	local choiceInfos = self.activityData:getChoiceAwards()
	local sort = choiceInfos[self.orderIndex][self.littleIndex].sort
	self.sort = sort
	local index = choiceInfos[self.orderIndex][self.littleIndex].index
	self.awardIndex = index
	self.isGet = choiceInfos[self.orderIndex][self.littleIndex].isGet

	if sort == 0 or index == 0 then
		self.paopaoIconCon.gameObject:SetActive(false)
		self.paopaoItemCon.gameObject:SetActive(false)
		self.choiceBtn.gameObject:SetActive(false)
		self.paopaoAddBtn.gameObject:SetActive(true)
		self.paopaoIconSelect.gameObject:SetActive(false)
		self.paopaoImgBgUp.gameObject:SetActive(false)
	else
		self.paopaoAddBtn.gameObject:SetActive(false)
		self.choiceBtn.gameObject:SetActive(true)

		local award = xyd.tables.activity4birthdayGambleTable:getItemWithIndex(self.orderIndex, sort, index)
		local itemType = xyd.tables.itemTable:getType(award[1])

		if itemType == xyd.ItemType.HERO_DEBRIS or itemType == xyd.ItemType.SKIN then
			self.paopaoIconCon.gameObject:SetActive(false)
			self.paopaoItemCon.gameObject:SetActive(true)

			local params = {
				noClickSelected = true,
				scale = 1,
				uiRoot = self.paopaoItemCon.gameObject,
				itemID = award[1],
				num = award[2],
				callback = handler(self, self.onTouch)
			}

			if not self.item then
				self.item = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
			else
				self.item:setInfo(params)
			end
		else
			self.paopaoIconCon.gameObject:SetActive(true)
			self.paopaoItemCon.gameObject:SetActive(false)
			xyd.setUISpriteAsync(self.paopaoIconImg, nil, xyd.tables.itemTable:getIcon(award[1]), function ()
				self.paopaoIconImg.gameObject:SetLocalScale(0.78, 0.78, 1)
			end, nil, true)

			self.paopaoIconLabel.text = xyd.getRoughDisplayNumber(award[2])
		end

		self:updateChoose()
	end
end

function PaoPaoItem:updateChoose()
	local award = xyd.tables.activity4birthdayGambleTable:getItemWithIndex(self.orderIndex, self.sort, self.awardIndex)

	if self.isGet and self.isGet == 1 then
		self.paopaoIconSelect.gameObject:SetActive(true)
		self.paopaoImgBgUp.gameObject:SetActive(true)
		self.choiceBtn.gameObject:SetActive(false)
	else
		self.paopaoIconSelect.gameObject:SetActive(false)
		self.paopaoImgBgUp.gameObject:SetActive(false)
	end
end

function PaoPaoItem:onTouch()
	if self.parent.isPlayingEffect then
		xyd.alertTips(__("ACTIVITY_4BIRTHDAY_GAMBLE_TIPS05"))

		return
	end

	if self.isGet and self.isGet == 1 then
		local choiceInfos = self.activityData:getChoiceAwards()

		if choiceInfos[self.orderIndex][self.littleIndex].index == 0 then
			return
		end

		local award = xyd.tables.activity4birthdayGambleTable:getItemWithIndex(self.orderIndex, choiceInfos[self.orderIndex][self.littleIndex].sort, choiceInfos[self.orderIndex][self.littleIndex].index)
		local params = {
			itemID = award[1]
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)

		return
	end

	xyd.WindowManager.get():openWindow("activity_4birthday_choice_award_window", {
		enterOrderIndex = self.orderIndex,
		enterId = self.index
	})
end

function PaoPaoItem:showEffect(isBoom)
	local function playFun(isBoom)
		if isBoom then
			self.effect:play("texiao01", 1, 1, function ()
				self.isGet = 1

				self:updateChoose()
				self.effect:play("texiao02", 1, 1, function ()
				end)
			end)
		else
			self.effect:play("texiao01", 1)
		end
	end

	if not self.effect then
		self.effect = xyd.Spine.new(self.effectCon.gameObject)

		self.effect:setInfo("activity_4birthday_award01", function ()
			playFun(isBoom)
		end)
	else
		playFun(isBoom)
	end
end

function PaoPaoItem:getIsGet()
	return self.isGet
end

return Activity4BirthdayMusic
