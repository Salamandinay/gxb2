local BaseWindow = import("app.windows.BaseWindow")
local ActivityAllStarsPrayHerosWindow = class("ActivityAllStarsPrayHerosWindow", BaseWindow)
local Partner = import("app.models.Partner")
local HeroIcon = import("app.components.HeroIcon")
local ActivityAllStarsPrayHerosItem = class("ActivityAllStarsPrayHerosItem", import("app.components.CopyComponent"))

function ActivityAllStarsPrayHerosWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.SlotModel = xyd.models.slot
	self.copyIconList_ = {}
	self.isIconMoving = false
	self.ifMove = false
	self.battlePartnerList = {}
	self.nowPartnerList = {}
	self.canClose = true
	self.isFirst = false
	self.sendIds = {}
	self.enterAlreadyHeros = {}
	self.skinName = "ActivityAllStarsPrayHerosSkin"
	self.selectGroup = params.selectGroup or 1
	self.enterAlreadyHeros = params.alreadyHeros
	self.canClose = params.canClose
	self.partnerContainerArr = {}
	self.partnerContainerObjArr = {}

	self.eventProxy_:addEventListener(xyd.event.CHANGE_PRAY_AWARD, function (event)
		local isOk = event.data.result

		if isOk == "OK" then
			xyd.EventDispatcher.inner():dispatchEvent({
				name = xyd.event.CHANGE_PRAY_AWARD_2,
				params = {
					sendIds = self.sendIds
				}
			})
			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end)
end

function ActivityAllStarsPrayHerosWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:createChildren()
	self:getPartnerData()
	self:initListShow()
	self:initBtns()
	self:checkIfMove()
end

function ActivityAllStarsPrayHerosWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:ComponentByName("groupAction", typeof(UIWidget))
	self.labelWinTitle0 = groupAction:ComponentByName("labelWinTitle0", typeof(UILabel))
	self.closeBtn0 = groupAction:ComponentByName("closeBtn0", typeof(UISprite))
	self.partnerScroller0 = groupAction:ComponentByName("partnerScroller0", typeof(UIScrollView))
	self.partnerScroller0_uipanel = groupAction:ComponentByName("partnerScroller0", typeof(UIPanel))
	self.partnerScroller0_uipanel.depth = self.partnerScroller0_uipanel.depth + 2
	self.partnerContainer = groupAction:NodeByName("partnerScroller0/partnerContainer").gameObject
	self.backGroup0 = groupAction:NodeByName("backGroup0").gameObject
	self.backGroup0_uipanel = groupAction:ComponentByName("backGroup0", typeof(UIPanel))
	self.backGroup0_uipanel.depth = self.partnerScroller0_uipanel.depth + 1

	for i = 0, 4 do
		self["container_" .. i] = groupAction:NodeByName("backGroup0/container_" .. tostring(i)).gameObject
	end

	self.okBtn = groupAction:ComponentByName("okBtn", typeof(UISprite))
	self.okBtn_button_label = groupAction:ComponentByName("okBtn/button_label", typeof(UILabel))
	self.okBtn_button_icon = groupAction:ComponentByName("okBtn/button_icon", typeof(UISprite))
	self.okBtn_button_num = groupAction:ComponentByName("okBtn/button_num", typeof(UILabel))
end

function ActivityAllStarsPrayHerosWindow:createChildren()
	self.labelWinTitle0.text = __("ACTIVITY_PRAY_SELECT")
	local data = xyd.tables.miscTable:split2Cost("activity_pray_select_price", "value", "#")

	xyd.setUISpriteAsync(self.okBtn_button_icon, nil, "icon_" .. data[1], nil, )

	self.okBtn_button_num.text = data[2]
	local index = 0

	for i in ipairs(self.enterAlreadyHeros) do
		if self.enterAlreadyHeros[i] ~= nil then
			index = index + 1
		end
	end

	if index ~= 5 then
		self.isFirst = true
		self.okBtn_button_label.text = __("ACTIVITY_PRAY_CONFIRM")

		self.okBtn_button_icon:SetActive(false)
		self.okBtn_button_num:SetActive(false)
		self.okBtn_button_label:SetLocalPosition(0, 0, 0)
	else
		self.okBtn_button_label.text = __("ACTIVITY_PRAY_CHANGE")

		self.okBtn_button_icon:SetActive(true)
		self.okBtn_button_num:SetActive(true)
		self.okBtn_button_label:SetLocalPosition(20, 0, 0)
	end
end

function ActivityAllStarsPrayHerosWindow:initBtns()
	UIEventListener.Get(self.closeBtn0.gameObject).onClick = handler(self, self.clickCloseBtn2)
	UIEventListener.Get(self.okBtn.gameObject).onClick = handler(self, self.onClickOkBtn)
end

function ActivityAllStarsPrayHerosWindow:close(callback, skipAnimation)
	if self.goOnCloseBtn2 ~= nil and self.goOnCloseBtn2 == true then
		return
	end

	self:clickCloseBtn()
end

function ActivityAllStarsPrayHerosWindow:clickCloseBtn()
	if self.canClose == true then
		xyd.WindowManager.get():closeWindow(self.name_)
	else
		self:onClickOkBtn()
	end
end

function ActivityAllStarsPrayHerosWindow:clickCloseBtn2()
	self.goOnCloseBtn2 = true

	if self.canClose == false then
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.CHANGE_PRAY_BACK,
			params = {
				sendIds = self.sendIds
			}
		})
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

function ActivityAllStarsPrayHerosWindow:onClickOkBtn()
	local heroList = {}
	local listKey = {}

	for posId, v in ipairs(self.battlePartnerList) do
		local partnerIcon = self.battlePartnerList[posId]

		if partnerIcon then
			local partnerInfo = partnerIcon:getPartnerInfo()

			table.insert(heroList, partnerInfo.tableID)

			if listKey[partnerInfo.tableID] then
				return
			end

			listKey[partnerInfo.tableID] = true
		end
	end

	if #heroList == 5 then
		local list = xyd.tables.activityPrayPartnerTable:getPartnerIds(self.selectGroup)
		self.sendIds = {}

		for i = 1, 5 do
			for j in pairs(list) do
				if list[j] == heroList[i] then
					table.insert(self.sendIds, tonumber(j))

					break
				end
			end
		end

		local data = xyd.tables.miscTable:split2Cost("activity_pray_select_price", "value", "#")
		local crystal = xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)

		if not self.isFirst and crystal < data[2] then
			xyd.WindowManager.get():openWindow("alert_window", {
				alertType = xyd.AlertType.CONFIRM,
				message = __("CRYSTAL_NOT_ENOUGH"),
				callback = function (yes)
					xyd.WindowManager.get():closeWindow("academy_assessment_buy_window")
					xyd.WindowManager.get():openWindow("vip_window")
				end,
				confirmText = __("BUY")
			})

			return
		end

		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ALL_STARS_PRAY)
		local got_awards = activityData.detail.benches[self.selectGroup].got_awards
		local sameIndex = 0
		local ifGrey = false

		for i in ipairs(self.enterAlreadyHeros) do
			if listKey[list[self.enterAlreadyHeros[i]]] then
				sameIndex = sameIndex + 1
			end

			if got_awards and xyd.arrayIndexOf(got_awards, self.enterAlreadyHeros[i]) ~= -1 then
				ifGrey = true
			end
		end

		if ifGrey then
			xyd.WindowManager.get():openWindow("alert_window", {
				alertType = xyd.AlertType.YES_NO,
				message = __("ACTIVITY_PRAY_CONFIRM_BUY"),
				callback = function (yes)
					if not yes then
						return
					end

					local msg = messages_pb:change_pray_award_req()
					msg.activity_id = xyd.ActivityID.ALL_STARS_PRAY
					msg.bench_id = self.selectGroup

					for i in ipairs(self.sendIds) do
						table.insert(msg.ids, tonumber(self.sendIds[i]))
					end

					xyd.Backend.get():request(xyd.mid.CHANGE_PRAY_AWARD, msg)
				end
			})
		elseif sameIndex >= 5 then
			xyd.showToast(__("ACTIVITY_PRAY_NO_CHANGE"))
		elseif self.isFirst then
			xyd.WindowManager.get():openWindow("all_stars_pray_alert_window", {
				alertType = xyd.AlertType.YES_NO,
				message = __("ACTIVITY_PRAY_CONFIRM_ALERT"),
				callback = function (yes)
					if not yes then
						return
					end

					local msg = messages_pb.change_pray_award_req()
					msg.activity_id = xyd.ActivityID.ALL_STARS_PRAY
					msg.bench_id = self.selectGroup

					for i in ipairs(self.sendIds) do
						table.insert(msg.ids, tonumber(self.sendIds[i]))
					end

					xyd.Backend.get():request(xyd.mid.CHANGE_PRAY_AWARD, msg)
				end
			})
		else
			xyd.WindowManager.get():openWindow("alert_window", {
				alertType = xyd.AlertType.YES_NO,
				message = __("ACTIVITY_PRAY_CONFIRM_BUY"),
				callback = function (yes)
					if not yes then
						return
					end

					local msg = messages_pb:change_pray_award_req()
					msg.activity_id = xyd.ActivityID.ALL_STARS_PRAY
					msg.bench_id = self.selectGroup

					for i in ipairs(self.sendIds) do
						table.insert(msg.ids, tonumber(self.sendIds[i]))
					end

					xyd.Backend.get():request(xyd.mid.CHANGE_PRAY_AWARD, msg)
				end
			})
		end
	else
		xyd.WindowManager.get():openWindow("alert_window", {
			alertType = xyd.AlertType.TIPS,
			message = __("ACTIVITY_PRAY_TIPS02")
		})
	end
end

function ActivityAllStarsPrayHerosWindow:initListShow()
	local partnerDataList = self.needList

	for i in ipairs(partnerDataList) do
		local tmp = NGUITools.AddChild(self.partnerContainer.gameObject, self.container_0)

		table.insert(self.partnerContainerObjArr, tmp)

		local item = ActivityAllStarsPrayHerosItem.new(tmp, partnerDataList[i], i)

		table.insert(self.partnerContainerArr, item)
	end
end

function ActivityAllStarsPrayHerosWindow:checkIfMove()
	if math.ceil(#self.needList / 5) <= 2 then
		self.partnerScroller0.enabled = false
	end
end

function ActivityAllStarsPrayHerosWindow:getPartnerData()
	local list = xyd.tables.activityPrayPartnerTable:getPartnerIds(self.selectGroup)
	self.needList = {}
	local selectKeys = {}

	for i in ipairs(self.enterAlreadyHeros) do
		selectKeys[self.enterAlreadyHeros[i]] = true
		self.nowPartnerList[i] = list[self.enterAlreadyHeros[i]]
	end

	for i in ipairs(list) do
		local np = Partner.new()

		np:populate({
			tableID = list[i]
		})

		local isS = self:isSelected(list[i], self.nowPartnerList, false)
		local data = {
			callbackFunc = function (heroIcon, isChoose, needAnimation, posId)
				self:onClickheroIcon(heroIcon, isChoose, needAnimation, posId)
				xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
			end,
			partnerInfo = np:getInfo(),
			isSelected = isS
		}

		table.insert(self.needList, data)
	end

	for i in pairs(self.nowPartnerList) do
		if self.nowPartnerList[i] ~= nil then
			local np = Partner.new()

			np:populate({
				tableID = self.nowPartnerList[i]
			})

			local heroIcon = HeroIcon.new(self["container_" .. tostring(i - 1)])
			local partnerInfo = np:getInfo()
			partnerInfo.noClick = true
			partnerInfo.lev = 1

			heroIcon:setInfo(partnerInfo)
			self:onClickheroIcon(heroIcon, false, false, i - 1)
		end
	end
end

function ActivityAllStarsPrayHerosWindow:isSelected(cPartnerId, Plist, isDel)
	if #Plist > 0 then
		local res = false

		for i in pairs(Plist) do
			local partnerId = Plist[i]

			if partnerId == cPartnerId then
				res = true

				if isDel then
					table.remove(Plist, i)
				end

				break
			end
		end

		return res
	else
		return false
	end
end

function ActivityAllStarsPrayHerosWindow:clickChooseHeroIcon(heroIcon)
	local selectIcon = nil

	for k, icon in ipairs(self.copyIconList_) do
		if icon:getPartnerInfo().tableID == heroIcon:getPartnerInfo().tableID then
			selectIcon = icon

			break
		end
	end

	if selectIcon then
		self:unSelectHero(selectIcon)
	end
end

function ActivityAllStarsPrayHerosWindow:unSelectHero(copyIcon)
	local index = xyd.arrayIndexOf(self.copyIconList_, copyIcon)

	if index > -1 then
		table.remove(self.copyIconList_, index)
	end

	local partnerInfo = copyIcon:getPartnerInfo()

	copyIcon:setNoClick(true)

	local originalIcon, battleHeroIcon, battleHeroIconObj, moveToTarget = nil

	for id in pairs(self.partnerContainerArr) do
		local fIcon = self.partnerContainerArr[id]
		local hIcon = fIcon:getHeroIcon()
		local pInfo = hIcon:getPartnerInfo()

		if tonumber(partnerInfo.tableID) == tonumber(pInfo.tableID) then
			originalIcon = hIcon
			battleHeroIcon = fIcon
			battleHeroIconObj = self.partnerContainerObjArr[id]
			moveToTarget = self.partnerContainerArr[id]:getHeroIcon()
			moveToTarget.choose = false
		end
	end

	local afFunc = nil

	function afFunc()
		if battleHeroIconObj then
			battleHeroIconObj.transform:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		end

		local copyIconInfo = copyIcon:getPartnerInfo()
		local posId = copyIconInfo.posId

		NGUITools.DestroyChildren(self["container_" .. copyIconInfo.posId].transform)

		self.battlePartnerList[posId + 1] = nil
		self.nowPartnerList[posId + 1] = nil

		self:delLocalPartnerList(partnerInfo.partnerID)
	end

	local nowVectoryPos = moveToTarget:getIconRoot().transform.position
	self["testMove2_" .. copyIcon:getPartnerInfo().posId] = DG.Tweening.DOTween.Sequence()

	self["testMove2_" .. copyIcon:getPartnerInfo().posId]:Append(copyIcon:getIconRoot().transform:DOMove(nowVectoryPos, 0.2))
	self["testMove2_" .. copyIcon:getPartnerInfo().posId]:AppendCallback(function ()
		if self["testMove1_" .. copyIcon:getPartnerInfo().posId] then
			self["testMove1_" .. copyIcon:getPartnerInfo().posId]:Kill(true)
		end

		afFunc()

		if self["testMove2_" .. copyIcon:getPartnerInfo().posId] then
			self["testMove2_" .. copyIcon:getPartnerInfo().posId]:Kill(true)
		end
	end)
end

function ActivityAllStarsPrayHerosWindow:delLocalPartnerList(partnerID)
	if #self.nowPartnerList <= 0 then
		return
	end

	for id in pairs(self.nowPartnerList) do
		local localPartnerID = tonumber(self.nowPartnerList[id])

		if tonumber(partnerID) == localPartnerID then
			table.remove(self.nowPartnerList, tonumber(id))

			break
		end
	end
end

function ActivityAllStarsPrayHerosWindow:getTargetLocal(targetObj, container)
	local targetGlobalPos = targetObj:localToGlobal()
	local targetContainerPos = container:globalToLocal(targetGlobalPos.x, targetGlobalPos.y)

	return targetContainerPos
end

function ActivityAllStarsPrayHerosWindow:isPartnerSelected(partnerID)
	local isSelected = false
	local sPosId = -1

	for posId, v in ipairs(self.battlePartnerList) do
		local heroIcon = self.battlePartnerList[posId]

		if heroIcon then
			local partnerInfo = heroIcon:getPartnerInfo()

			if partnerID == partnerInfo.tableID then
				isSelected = true
				sPosId = tonumber(posId)

				break
			end
		end
	end

	return {
		isSelected = isSelected,
		posId = sPosId
	}
end

function ActivityAllStarsPrayHerosWindow:onClickheroIcon(heroIcon, isChoose, needAnimation, posId)
	if posId == nil then
		posId = 0
	end

	if isChoose then
		heroIcon.choose = false

		self:clickChooseHeroIcon(heroIcon)

		return
	end

	posId = tonumber(posId)

	if posId == 0 or not posId then
		posId = 0

		while posId < 5 do
			if not self.battlePartnerList[posId + 1] or self.battlePartnerList[posId + 1] == nil then
				break
			end

			posId = posId + 1
		end
	end

	if posId >= 5 then
		return
	end

	heroIcon.choose = true
	local partnerInfo = heroIcon:getPartnerInfo()
	local container = self["container_" .. tostring(posId)]

	NGUITools.DestroyChildren(container.transform)

	local tmpIcon = HeroIcon.new(container)

	tmpIcon:setInfo(partnerInfo)

	partnerInfo.originalIcon = heroIcon
	partnerInfo.posId = posId

	table.insert(self.copyIconList_, tmpIcon)

	self.battlePartnerList[posId + 1] = tmpIcon
	self.nowPartnerList[posId + 1] = partnerInfo.partnerID
	tmpIcon:getIconRoot().transform:AddComponent(typeof(UnityEngine.BoxCollider)).size = Vector2(108, 108)
	UIEventListener.Get(tmpIcon:getIconRoot().gameObject).onClick = handler(self, function (event)
		self:iconTapHandler(tmpIcon)
	end)

	if needAnimation == true then
		local zeroVectoryPos = tmpIcon:getIconRoot().transform.position
		tmpIcon:getIconRoot().transform.position = heroIcon:getIconRoot().transform.position
		self["testMove1_" .. posId] = DG.Tweening.DOTween.Sequence()
		self.isAnimation_ = true

		self["testMove1_" .. posId]:Append(tmpIcon:getIconRoot().transform:DOMove(zeroVectoryPos, 0.2))
		self["testMove1_" .. posId]:AppendCallback(function ()
			self.isAnimation_ = false
		end)
	end
end

function ActivityAllStarsPrayHerosWindow:updateForceNum()
	local power = 0
	local ____TS_array = self.battlePartnerList

	for ____TS_index = 1, #____TS_array do
		local i = ____TS_array[____TS_index]
		local partnerIcon = self.battlePartnerList[i + 1]

		if partnerIcon then
			local partnerInfo = partnerIcon:getPartnerInfo()
		end
	end
end

function ActivityAllStarsPrayHerosWindow:iconTapHandler(copyIcon)
	self:iconTapFun(copyIcon)
end

function ActivityAllStarsPrayHerosWindow:iconTapFun(targer)
	xyd.SoundManager.get():playSound("2038")
	self:unSelectHero(targer)
end

function ActivityAllStarsPrayHerosWindow:checkMove(point)
	local l = math.sqrt(math.pow(self.moveStartPoint.x - point.x, 2) + math.pow(self.moveStartPoint.y - point.y, 2))

	if l > 50 then
		return true
	else
		return false
	end
end

function ActivityAllStarsPrayHerosItem:ctor(goItem, data, index)
	self.goItem_ = goItem
	local transGo = goItem.transform
	self.itemIndex = index
	self.ifMove = false

	NGUITools.DestroyChildren(self.goItem_.transform)
	self.goItem_:AddComponent(typeof(UIDragScrollView))

	self.heroIcon_ = HeroIcon.new(goItem)
	transGo:GetComponent(typeof(UIWidget)).height = 133
	transGo:AddComponent(typeof(UnityEngine.BoxCollider)).size = Vector2(108, 108)
	self.data = data

	self:init(data)
	self:createChildren()
end

function ActivityAllStarsPrayHerosItem:init(data)
	data.partnerInfo.noClick = true
	data.partnerInfo.lev = 1

	self.heroIcon_:setInfo(data.partnerInfo)

	local win_ = xyd.WindowManager.get():getWindow("activity_all_stars_pray_heros_window")
	local params = win_:isPartnerSelected(data.partnerInfo.tableID)
	local isChoose = params.isSelected
	self.heroIcon_.choose = isChoose
	self.goItem_.gameObject.name = "ActivityAllStarsPrayHerosItem" .. tostring(self.itemIndex)
end

function ActivityAllStarsPrayHerosItem:createChildren()
	UIEventListener.Get(self.goItem_.gameObject).onClick = handler(self, self.onTouch)

	UIEventListener.Get(self.goItem_.gameObject).onLongPress = function ()
		self:showPartnerDetail(self.data.partnerInfo)
	end
end

function ActivityAllStarsPrayHerosItem:showPartnerDetail(partnerInfo)
	if xyd.GuideController.get():isPlayGuide() then
		return
	end

	if not partnerInfo then
		return
	end

	local params = {
		partners = {
			{
				table_id = partnerInfo.tableID
			}
		},
		table_id = partnerInfo.tableID
	}
	local wndName = "guide_detail_window"

	xyd.openWindow(wndName, params)
end

function ActivityAllStarsPrayHerosItem:dataChanged()
	self:init(self.data)
end

function ActivityAllStarsPrayHerosItem:getHeroIcon()
	return self.heroIcon_
end

function ActivityAllStarsPrayHerosItem:onTouch()
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
	self.data.callbackFunc(self.heroIcon_, self.heroIcon_.choose, true)
end

function ActivityAllStarsPrayHerosItem:onTouchBegin(e)
	self.moveStartPoint = self.stage:globalToLocal(e.localX, e.localY)
	self.ifMove = false

	self.stage:addEventListener(egret.TouchEvent.TOUCH_MOVE, self.onTouchMove, self)
	self.stage:addEventListener(egret.TouchEvent.TOUCH_END, self.onTouchEnd, self)
	self.stage:addEventListener(egret.TouchEvent.TOUCH_RELEASE_OUTSIDE, self.onTouchEnd, self)
end

function ActivityAllStarsPrayHerosItem:onTouchMove(event)
	local targetContainerPos = self.stage:globalToLocal(event.localX, event.localY)

	if not self:checkMove(targetContainerPos) then
		return
	end

	self.ifMove = true
end

function ActivityAllStarsPrayHerosItem:onTouchEnd(event)
	self.stage:removeEventListener(egret.TouchEvent.TOUCH_MOVE, self.onTouchMove, self)
	self.stage:removeEventListener(egret.TouchEvent.TOUCH_END, self.onTouchEnd, self)
	self.stage:removeEventListener(egret.TouchEvent.TOUCH_RELEASE_OUTSIDE, self.onTouchEnd, self)

	if self.touchTimer_ and self.touchTimer_.running then
		self.touchTimer_:stop()
	end
end

function ActivityAllStarsPrayHerosItem:checkMove(point)
	if not self.moveStartPoint then
		return
	end

	local l = math.sqrt(math.pow(self.moveStartPoint.x - point.x, 2) + math.pow(self.moveStartPoint.y - point.y, 2))

	if l > 5 then
		return true
	else
		return false
	end
end

function ActivityAllStarsPrayHerosItem:onGCTimer()
	if self.touchTimer_ then
		if self.touchTimer_.running then
			self.touchTimer_:stop()
		end

		self.touchTimer_ = nil
	end
end

return ActivityAllStarsPrayHerosWindow
