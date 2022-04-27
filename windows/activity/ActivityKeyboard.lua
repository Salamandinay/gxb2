local ActivityKeyboard = class("ActivityKeyboard", import(".ActivityContent"))
local ActivityKeyboardItem = class("ActivityKeyboardItem", import("app.common.ui.FixedWrapContentItem"))
local AdvanceIcon = import("app.components.AdvanceIcon")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local json = require("cjson")
local awardTable = xyd.tables.activityKeyboardTable

function ActivityKeyboard:ctor(parentGO, params)
	self.itemIcons = {}
	self.itemIcons_layers = {}
	self.itemIconDrawEffects = {}
	self.itemIconNoteEffects = {}
	self.itemIconDrawEffects_layers = {}
	self.itemIconNoteEffects_layers = {}
	self.bottomTimer = nil
	self.topTimer = nil
	self.curBottomIndex = 1
	self.curTopIndex = 1
	self.awardTime = {
		0.16,
		0.1,
		0.06,
		0.16,
		0.23,
		0.4,
		0.53,
		0.23,
		0.43
	}
	self.soundIds = {
		2052,
		2053,
		2054,
		2055,
		2056,
		2057,
		2058,
		2059,
		2060
	}
	self.iconOffset = {
		[0] = {
			{
				-222,
				6
			},
			{
				-105,
				-14
			},
			{
				15,
				-31
			},
			{
				132,
				-49
			},
			{
				252,
				-32
			}
		},
		{
			{
				-220,
				-27
			},
			{
				-99,
				-57
			},
			{
				16,
				-59
			},
			{
				135,
				-31
			},
			{
				254,
				13
			}
		}
	}
	self.numBottom = 0
	self.numTop = 0
	self.bigAwardIndex = 5
	self.awards = {}
	self.canPurchase = true
	self.maxLayer = 7
	self.layerHeight = 215
	self.initPos = 840

	ActivityKeyboard.super.ctor(self, parentGO, params)

	self.parentGO = parentGO
	self.curLayer = self.activityData:getMaxCanLayer()
	self.newLayer = self.curLayer
	self.lastBigAwards = self.activityData.detail_.senior_awards

	self:layout()
	self:registerEvent()
	xyd.db.misc:setValue({
		value = 1,
		key = "key_board_redmark"
	})
	self:waitForTime(0.5, function ()
		self:recenter(self.curLayer)
		self:playBottomNormalAnimation(1)
	end)
end

function ActivityKeyboard:getPrefabPath()
	return "Prefabs/Windows/activity/activity_keyboard"
end

function ActivityKeyboard:initUI()
	ActivityKeyboard.super.initUI(self)

	local go = self.go
	self.helpBtn = go:NodeByName("helpBtnGroup/helpBtn").gameObject
	self.imgTitle = go:ComponentByName("imgTitle", typeof(UISprite))
	local iconGroup = go:NodeByName("iconGroup").gameObject
	self.iconGroupNumLabel = iconGroup:ComponentByName("iconGroupNumLabel", typeof(UILabel))
	self.iconGroupAddBtn = iconGroup:NodeByName("iconGroupAddBtn").gameObject
	self.groupMid = go:NodeByName("groupMid").gameObject
	self.scroller = self.groupMid:ComponentByName("scroller", typeof(UIScrollView))
	self.mask = self.scroller:NodeByName("mask").gameObject
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.scrollerItem = self.scroller:NodeByName("item").gameObject
	self.drag = self.groupMid:NodeByName("drag").gameObject
	self.nextLayerImg = self.groupMid:ComponentByName("frontUIGroup/nextLayerImg", typeof(UISprite))
	self.layerIndexImg = self.groupMid:ComponentByName("frontUIGroup/nextLayerImg/layerIndexImg", typeof(UISprite))
	self.progressGroup = self.groupMid:ComponentByName("frontUIGroup/progressGroup", typeof(UISlider))
	self.imgNote = self.progressGroup:NodeByName("imgNote").gameObject
	self.groupBottom = go:NodeByName("groupBottom").gameObject

	for i = 1, 9 do
		self["bottomImg" .. i] = self.groupBottom:NodeByName("bottomImg" .. i).gameObject
		self["bottomIcon" .. i] = self.groupBottom:ComponentByName("bottomIcon" .. i, typeof(UISprite))
		self["bottomLabel" .. i] = self.groupBottom:ComponentByName("bottomLabel" .. i, typeof(UILabel))
		self["bottomImgTouch" .. i] = self.groupBottom:NodeByName("bottomImgTouch" .. i).gameObject
	end

	self.bottomIconEffect = self.groupBottom:NodeByName("bottomIconEffect").gameObject
	self.purchaseBtn = self.groupBottom:NodeByName("puchaseBtnGroup/purchaseBtn").gameObject
	self.purchaseBtnLabel = self.purchaseBtn:ComponentByName("purchaseBtnLabel", typeof(UILabel))
	self.touchField = go:NodeByName("touchField").gameObject
end

function ActivityKeyboard:layout()
	local t = xyd.tables.activityKeyboardTable
	local itemTable = xyd.tables.itemTable
	local type1 = t:getIds(1)
	local type2 = t:getIds(2)

	for i, id in ipairs(type1) do
		local award = t:getAward(id)

		if not t:isBigAward(id) then
			xyd.setUISpriteAsync(self["bottomIcon" .. i], nil, itemTable:getIcon(award[1]))

			self["bottomLabel" .. i].text = xyd.getRoughDisplayNumber(award[2])

			UIEventListener.Get(self["bottomIcon" .. i].gameObject).onClick = function ()
				local params = {
					itemID = award[1],
					itemNum = award[2],
					wndType = xyd.ItemTipsWndType.ACTIVITY
				}

				xyd.WindowManager.get():openWindow("item_tips_window", params)
			end
		end

		if t:isBigAward(id) then
			UIEventListener.Get(self["bottomIcon" .. i].gameObject).onClick = function ()
				if #self.activityData.detail.senior_awards == 0 then
					local params = {
						itemID = award[1],
						itemNum = award[2],
						wndType = xyd.ItemTipsWndType.ACTIVITY
					}

					xyd.WindowManager.get():openWindow("item_tips_window", params)
				end
			end
		end
	end

	for i, id in ipairs(type2) do
		-- Nothing
	end

	self.iconEffect = xyd.Spine.new(self.bottomIconEffect)

	self.iconEffect:setInfo("activity_keyboard_flash", function ()
		self.iconEffect:SetActive(false)
	end)
	self.touchField:SetActive(false)
	xyd.setUISpriteAsync(self.imgTitle, nil, "activity_keyboard_" .. xyd.Global.lang)

	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))

	if not self.wrapContent then
		self.wrapContent = FixedWrapContent.new(self.scroller, wrapContent, self.scrollerItem, ActivityKeyboardItem, self)

		self.wrapContent:setInfos({}, {})
	end

	return self:updateLayout()
end

function ActivityKeyboard:updateLayout(keepPosition)
	self.itemIcons = self.itemIcons_layers[self.curLayer]
	self.itemIconDrawEffects = self.itemIconDrawEffects_layers[self.curLayer]
	self.itemIconNoteEffects = self.itemIconNoteEffects_layers[self.curLayer]
	local num = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_KEYBOARD_ITEM)
	self.iconGroupNumLabel.text = num
	self.purchaseBtnLabel.text = 1
	local awards = self.activityData.detail_.awards

	for i = 1, 9 do
		if xyd.arrayIndexOf(awards, i) < 1 then
			xyd.applyGrey(self["bottomIcon" .. i])
		else
			xyd.applyOrigin(self["bottomIcon" .. i])
		end
	end

	local IDs_type1 = awardTable:getIds(1)
	local IDs_type2 = awardTable:getIds(2)
	local seniorAwards = self.activityData.detail_.senior_awards

	if #seniorAwards <= 0 then
		local award = xyd.tables.activityKeyboardTable:getAward(5)

		xyd.setUISpriteAsync(self.bottomIcon5, nil, xyd.tables.itemTable:getIcon(award[1]), function ()
			self.bottomIcon5.width = 64
			self.bottomIcon5.height = 64
			self.bottomIcon5.transform.localPosition = Vector3(0, 184, 0)
		end)

		self.bottomLabel5.text = award[2]
	else
		xyd.setUISpriteAsync(self.bottomIcon5, nil, "activity_keyboard_icon01")
	end

	local ids = awardTable:getIds()
	local datas = {}

	table.insert(datas, {
		layer = self.maxLayer
	})

	for i = 1, #ids do
		local id = i
		local layer = awardTable:getLayer(id)

		if layer and layer ~= 0 then
			if not datas[self.maxLayer - layer + 1] then
				datas[self.maxLayer - layer + 1] = {}
			end

			if not self.itemIconDrawEffects_layers[layer] then
				self.itemIconDrawEffects_layers[layer] = {}
			end

			if not self.itemIconNoteEffects_layers[layer] then
				self.itemIconNoteEffects_layers[layer] = {}
			end

			if not self.itemIcons_layers[layer] then
				self.itemIcons_layers[layer] = {}
			end

			local data = {
				tableID = id,
				layer = layer,
				award = awardTable:getAward(id)
			}
			datas[self.maxLayer - layer + 1].itemIconDrawEffects = self.itemIconDrawEffects_layers[layer]
			datas[self.maxLayer - layer + 1].itemIconNoteEffects = self.itemIconNoteEffects_layers[layer]
			datas[self.maxLayer - layer + 1].itemIcons_layers = self.itemIcons_layers[layer]
			datas[self.maxLayer - layer + 1].layer = layer

			table.insert(datas[self.maxLayer - layer + 1], data)
		end
	end

	local resourcePathes = {}
	local ids = awardTable:getIds(2)

	for i = 1, #ids do
		local tableID = ids[i]
		local itemID = awardTable:getAward(tableID)[1]
		local iconName = xyd.tables.itemTable:getIcon(itemID)
		local path = xyd.getSpritePath(iconName)

		if #resourcePathes == 0 then
			table.insert(resourcePathes, path)
		end

		for i = 1, #resourcePathes do
			if resourcePathes[i] == path then
				break
			end

			if i == #resourcePathes then
				table.insert(resourcePathes, path)
			end
		end
	end

	if xyd.isAllPathLoad(resourcePathes) then
		self.wrapContent:setInfos(datas, {
			keepPosition = keepPosition
		})

		return
	end

	ResCache.DownloadAssets("activityKeyboardRes", resourcePathes, function (success)
		local wnd = xyd.WindowManager.get():getWindow("res_loading_window")

		if wnd then
			xyd.WindowManager.get():closeWindow("res_loading_window", {})
		end

		if self.go and not tolua.isnull(self.go) then
			self.wrapContent:setInfos(datas, {
				keepPosition = keepPosition
			})
		end
	end, function (progress)
		self.name_ = "activityKeyboard"
		local wnd = xyd.WindowManager.get():getWindow("res_loading_window")

		if progress == 1 and not wnd then
			return
		end

		if not wnd then
			wnd = xyd.WindowManager.get():openWindow("res_loading_window", {})

			wnd:setLoadWndName(self.name_)
		end

		if not wnd:isCurLoading(self.name_) then
			return
		end

		local wnd = xyd.WindowManager.get():getWindow("res_loading_window")

		wnd:setLoadProgress(self.name_, progress)
	end, 1)
end

function ActivityKeyboard:resizeToParent()
	ActivityKeyboard.super.resizeToParent(self)

	self.groupMid = self.go:NodeByName("groupMid").gameObject

	self:resizePosY(self.groupMid.gameObject, 0, -100)
end

function ActivityKeyboard:registerEvent()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_KEYBOARD_HELP"
		})
	end

	UIEventListener.Get(self.iconGroupAddBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.ACTIVITY_KEYBOARD_ITEM,
			activityID = xyd.ActivityID.ACTIVITY_KEYBOARD
		})
	end

	UIEventListener.Get(self.drag).onDragStart = function ()
		self:onDragStart()
	end

	UIEventListener.Get(self.drag).onDrag = function (go, delta)
		self:onDrag(delta)
	end

	UIEventListener.Get(self.drag).onDragEnd = function (go)
		self:onDragEnd()
	end

	XYDUtils.AddEventDelegate(self.progressGroup.onChange, handler(self, self.onSliderChange))

	UIEventListener.Get(self.purchaseBtn).onClick = function ()
		if not self.canPurchase then
			return
		end

		self:recenter(self.curLayer)

		local num = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_KEYBOARD_ITEM)

		if num <= 0 then
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(xyd.ItemID.ACTIVITY_KEYBOARD_ITEM)))

			return
		end

		local function callback(flag, layer)
			if flag == true then
				if not layer then
					return
				end

				local params = require("cjson").encode({
					level = layer
				})
				local msg = messages_pb:get_activity_award_req()
				msg.params = params
				msg.activity_id = xyd.ActivityID.ACTIVITY_KEYBOARD

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
				self.mask:SetActive(true)
			end
		end

		if #self.activityData.detail.senior_awards == 0 then
			callback(true, self.curLayer)

			return
		end

		callback(true, self.curLayer)
	end

	for i = 1, 9 do
		UIEventListener.Get(self["bottomImgTouch" .. i]).onClick = function ()
			xyd.SoundManager.get():playSound(self.soundIds[i])
		end
	end

	UIEventListener.Get(self.touchField).onClick = function ()
		if self.curBottomIndex == self.bigAwardIndex and #self.lastBigAwards > 0 then
			local realIndex = self.numTop - 2 * self.activityData:getCurLayerItemsNum() + 1

			if not self["itemMask" .. realIndex] then
				return
			end
		end

		self:cleanSequence()
		self:cleanWaitForTimeKeys()
		self["bottomImg" .. self.curBottomIndex]:SetActive(false)

		self.curBottomIndex = self.resultIndex

		self.touchField:SetActive(false)
		self["bottomImg" .. self.curBottomIndex]:SetActive(true)

		if self.curBottomIndex == self.bigAwardIndex and #self.lastBigAwards > 0 then
			local realIndex = self.numTop - 2 * self.activityData:getCurLayerItemsNum() + 1
			local wrapcontentItems = self.wrapContent:getItems()

			for key, value in pairs(wrapcontentItems) do
				local itemData = value:getData()

				if itemData and itemData.layer == self.curLayer then
					local imgMaskList = value:getImgMaskList()

					for j = 1, #imgMaskList do
						self["itemMask" .. j] = imgMaskList[j]
					end
				end
			end

			self["itemMask" .. realIndex]:SetActive(false)
			self.itemIconNoteEffects[realIndex]:play("texiao01", 1, 1, function ()
				self.itemIconNoteEffects[realIndex]:SetActive(false)
				self["itemMask" .. realIndex]:SetActive(true)

				self.curBottomIndex = 1

				self:resetLightPic()

				self.lastBigAward = self.activityData.detail_.senior_awards

				xyd.itemFloat(self.awards, nil, , 5000)

				if self.activityData:getMaxCanLayer() ~= self.curLayer and self.activityData:haveNewUnlock() == true and #self.activityData.detail_.senior_awards > 0 then
					self.curLayer = self.activityData:getMaxCanLayer()

					self:recenter(self.curLayer)
				end

				if self.activityData:curLayerCanGetAward(self.curLayer) == false and #self.activityData.detail_.senior_awards > 0 then
					self.curLayer = self.activityData:getMaxCanLayer()

					self:recenter(self.curLayer)
				end

				self.mask:SetActive(false)
				self:playBottomNormalAnimation(2)
			end)

			return
		end

		local seq = self:getSequence(function ()
			xyd.itemFloat(self.awards, function ()
				if not self or self.isDispose_ then
					return
				end

				self.mask:SetActive(false)
				self:setBtnTouchEnabled(true)

				local awards1 = self.activityData.detail_.awards

				for i = 1, 9 do
					if xyd.arrayIndexOf(awards1, i) < 1 then
						xyd.applyGrey(self["bottomIcon" .. i])
					else
						xyd.applyOrigin(self["bottomIcon" .. i])
					end
				end

				if self.curBottomIndex == self.bigAwardIndex then
					self["bottomImg" .. self.curBottomIndex]:SetActive(false)

					self.curBottomIndex = 1

					self:playBottomNormalAnimation(2)
				else
					self:updateLayout(true)
					self:playBottomNormalAnimation(1)
				end
			end, nil, 5000)
		end, true)

		seq:Append(self["bottomIcon" .. self.curBottomIndex].transform:DOScale(Vector3(1.17, 1.17, 1), 0.33))
		seq:Append(self["bottomIcon" .. self.curBottomIndex].transform:DOScale(Vector3(1, 1, 1), 0.33))
	end

	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function ActivityKeyboard:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_KEYBOARD then
		return
	end

	local detail = json.decode(event.data.detail)
	local index = detail.index

	if not detail.index then
		return
	end

	self.awards = detail.items
	self.lastBigAwards = self.activityData.detail.senior_awards
	self.numBottom = index + 19 - self.curBottomIndex

	self.touchField:SetActive(true)

	self.resultIndex = index

	if xyd.tables.activityKeyboardTable:getRewardType(index) == 2 then
		self.numBottom = self.bigAwardIndex + 19 - self.curBottomIndex
		self.numTop = index + 2 * self.activityData:getCurLayerItemsNum() - self.activityData:getTableID(self.curLayer, 1)
		self.curTopIndex = 1
		self.resultIndex = self.bigAwardIndex
	end

	self.itemIconDrawEffects = self.itemIconDrawEffects_layers[self.curLayer]
	self.itemIconNoteEffects = self.itemIconNoteEffects_layers[self.curLayer]

	self:setBtnTouchEnabled(false)
	self:resetLightPic()
	self:cleanSequence()
	self:cleanWaitForTimeKeys()
	self:playBottomAwardAnimation(1)
end

function ActivityKeyboard:setBtnTouchEnabled(flag)
	self.canPurchase = flag

	xyd.setTouchEnable(self.purchaseBtn, flag)
end

function ActivityKeyboard:playBottomNormalAnimation(type)
	local t = 0.7

	if type == 2 then
		t = 0.06
	end

	self:cleanWaitForTimeKeys()

	if type == 2 then
		xyd.SoundManager.get():playSound(self.soundIds[self.curBottomIndex])
	end

	self["bottomImg" .. self.curBottomIndex]:SetActive(true)
	self:waitForTime(t, function ()
		self:waitForTime(0.03, function ()
			self.curBottomIndex = self.curBottomIndex + 1

			if self.curBottomIndex > 9 then
				self.curBottomIndex = 1

				if type == 2 then
					self:setBtnTouchEnabled(true)
					self:updateLayout(true)
					self:playBottomNormalAnimation(1)
				else
					self:playBottomNormalAnimation(1)
				end

				return
			end

			self:playBottomNormalAnimation(type)
		end)

		local index = self.curBottomIndex

		local function setter(value)
			self["bottomImg" .. index]:GetComponent(typeof(UIWidget)).alpha = value
		end

		local seq = self:getSequence(function ()
			self["bottomImg" .. index]:SetActive(false)

			self["bottomImg" .. index]:GetComponent(typeof(UIWidget)).alpha = 1
		end, true)

		seq:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0.01, 0.06))
	end)
end

function ActivityKeyboard:playBottomAwardAnimation(num)
	local t = 0.03

	if num <= 3 then
		t = self.awardTime[num]
	elseif num > self.numBottom - 5 then
		t = self.awardTime[num - self.numBottom + 8]
	end

	self:cleanWaitForTimeKeys()
	xyd.SoundManager.get():playSound(self.soundIds[self.curBottomIndex])
	self["bottomImg" .. self.curBottomIndex]:SetActive(true)
	self:waitForTime(t, function ()
		if num == self.numBottom then
			self:cleanWaitForTimeKeys()
			self:playBottomShake()

			return
		end

		self:waitForTime(0.03, function ()
			self.curBottomIndex = self.curBottomIndex + 1

			if self.curBottomIndex > 9 then
				self.curBottomIndex = 1
			end

			self:playBottomAwardAnimation(num + 1)
		end)

		local index = self.curBottomIndex

		local function setter(value)
			self["bottomImg" .. index]:GetComponent(typeof(UIWidget)).alpha = value
		end

		local seq = nil
		seq = self:getSequence(function ()
			self["bottomImg" .. index]:SetActive(false)

			self["bottomImg" .. index]:GetComponent(typeof(UIWidget)).alpha = 1
		end, true)

		seq:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0.01, 0.06))
	end)
end

function ActivityKeyboard:playBottomShake()
	self:playBottomShakeEffect(1)

	if self.curBottomIndex == self.bigAwardIndex and #self.lastBigAwards > 0 then
		self.iconEffect:SetActive(true)
		self.iconEffect:play("texiao01", 1, 1.5, function ()
			self.iconEffect:SetActive(false)
		end)
		self:waitForTime(0.9, function ()
			self:playTopEffect(1)
		end)

		return
	end

	local seq = self:getSequence(function ()
		xyd.itemFloat(self.awards, function ()
			if not self or self.isDispose_ then
				return
			end

			self:setBtnTouchEnabled(true)
			self.mask:SetActive(false)

			if self.curBottomIndex == self.bigAwardIndex then
				self["bottomImg" .. self.curBottomIndex]:SetActive(false)

				self.curBottomIndex = 1

				self:playBottomNormalAnimation(2)
			else
				self:updateLayout(true)
				self:playBottomNormalAnimation(1)
			end
		end, nil, 5000)
	end, true)

	seq:Append(self["bottomIcon" .. self.curBottomIndex].transform:DOScale(Vector3(1.17, 1.17, 1), 0.33))
	seq:Append(self["bottomIcon" .. self.curBottomIndex].transform:DOScale(Vector3(1, 1, 1), 0.33))
end

function ActivityKeyboard:playBottomShakeEffect(num)
	local seq = self:getSequence(function ()
		if num == 3 then
			self.touchField:SetActive(false)

			return
		end

		self:playBottomShakeEffect(num + 1)
	end, true)

	local function setter(value)
		self["bottomImg" .. self.curBottomIndex]:GetComponent(typeof(UIWidget)).alpha = value
	end

	seq:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0.01, 0.16))
	seq:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0.01, 1, 0.06))
end

function ActivityKeyboard:playTopEffect(type)
	local senior_awards = self.lastBigAwards
	local seq = self:getSequence(function ()
		if type == 1 then
			self:playTopAwardEffect(1)
		end
	end, true)
	local from = 1
	local to = 0.01

	if type == 2 then
		from = 0.01
		to = 1
	end

	local wrapcontentItems = self.wrapContent:getItems()

	for key, value in pairs(wrapcontentItems) do
		local itemData = value:getData()

		if itemData and itemData.layer == self.curLayer then
			local imgMaskList = value:getImgMaskList()

			for j = 1, #imgMaskList do
				self["itemMask" .. j] = imgMaskList[j]
			end
		end
	end

	for i = 1, self.activityData:getCurLayerItemsNum() do
		local function setter(value)
			self["itemMask" .. i]:GetComponent(typeof(UIWidget)).alpha = value
		end

		seq:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), from, to, 0.66))
	end

	if type == 2 then
		self.curBottomIndex = 1

		self:resetLightPic()

		self.lastBigAward = self.activityData.detail_.senior_awards

		xyd.itemFloat(self.awards, nil, , 5000)
		self.mask:SetActive(false)
		self:playBottomNormalAnimation(2)

		if self.activityData:getMaxCanLayer() ~= self.curLayer and self.activityData:haveNewUnlock() == true and #self.activityData.detail_.senior_awards > 0 then
			self.curLayer = self.activityData:getMaxCanLayer()

			self:recenter(self.curLayer)
		end

		if self.activityData:curLayerCanGetAward(self.curLayer) == false and #self.activityData.detail_.senior_awards > 0 then
			self.curLayer = self.activityData:getMaxCanLayer()

			self:recenter(self.curLayer)
		end
	end
end

function ActivityKeyboard:playTopAwardEffect(num)
	self.curTopIndex = num % self.activityData:getCurLayerItemsNum()

	if self.curTopIndex == 0 then
		self.curTopIndex = self.activityData:getCurLayerItemsNum()
	end

	local t = 0.03

	if num <= 3 then
		t = self.awardTime[num]
	elseif num > self.numTop - 5 then
		t = self.awardTime[num - self.numTop + 8]
	end

	self:cleanWaitForTimeKeys()
	self.itemIconDrawEffects[self.curTopIndex]:SetActive(true)
	self.itemIconDrawEffects[self.curTopIndex]:play("texiao01", 1, 1)
	self:waitForTime(t, function ()
		if num == self.numTop + 1 then
			self:cleanWaitForTimeKeys()
			self.itemIconNoteEffects[self.curTopIndex]:play("texiao01", 1, 1, function ()
				self.itemIconNoteEffects[self.curTopIndex]:SetActive(false)
				self:playTopEffect(2)
			end)

			return
		end

		self:waitForTime(0.03, function ()
			self.curTopIndex = self.curTopIndex + 1

			if self.activityData:getCurLayerItemsNum() < self.curTopIndex then
				self.curTopIndex = 1
			end

			self:playTopAwardEffect(num + 1)
		end)
		self.itemIconDrawEffects[self.curTopIndex]:SetActive(false)
	end)
end

function ActivityKeyboard:cleanWaitForTimeKeys()
	for i = 1, #self.waitForTimeKeys_ do
		XYDCo.StopWait(self.waitForTimeKeys_[i])
	end

	self.waitForTimeKeys_ = {}
end

function ActivityKeyboard:onSliderChange()
end

function ActivityKeyboard:cleanSequence()
	for i = 1, #self.sequences_ do
		if not tolua.isnull(self.sequences_[i]) then
			self.sequences_[i]:Pause()
			self.sequences_[i]:Kill(false)
		end
	end

	self.sequences_ = {}
end

function ActivityKeyboard:resetLightPic()
	for i = 1, 9 do
		self["bottomImg" .. i]:SetActive(false)

		self["bottomImg" .. i]:GetComponent(typeof(UIWidget)).alpha = 1
	end

	for _, effect in ipairs(self.itemIconDrawEffects) do
		effect:SetActive(false)
	end

	for _, effect in ipairs(self.itemIconNoteEffects) do
		effect:SetActive(false)
	end
end

function ActivityKeyboard:onDragStart()
	self.dragDelta = 0
	self.oldLayer = self.newLayer
end

function ActivityKeyboard:onDrag(delta)
	self.dragDelta = self.dragDelta - delta.y
end

function ActivityKeyboard:onDragEnd()
	if self.dragDelta > 0 then
		self.dragDelta = math.min(self.dragDelta, (self.maxLayer - self.oldLayer) * self.layerHeight)
		self.layerDelta = math.floor((self.dragDelta + 0.5 * self.layerHeight) / self.layerHeight)
	elseif self.dragDelta <= 0 then
		self.dragDelta = math.max(self.dragDelta, (self.oldLayer - 1) * self.layerHeight * -1)
		self.layerDelta = math.ceil((self.dragDelta - 0.5 * self.layerHeight) / self.layerHeight)
	end

	self.newLayer = self.oldLayer + self.layerDelta

	if self.newLayer >= self.maxLayer - 1 then
		self.newLayer = self.maxLayer - 2
	end

	self:recenter(self.newLayer)
end

function ActivityKeyboard:recenter(curLayer)
	if curLayer >= self.maxLayer - 1 then
		curLayer = self.maxLayer - 2
	end

	local sp = self.scroller.gameObject:GetComponent(typeof(SpringPanel))
	local initPos = self.initPos
	local dis = initPos - (curLayer - 1) * self.layerHeight
	self.newLayer = curLayer

	SpringPanel.Stop(self.scroller.gameObject)
	SpringPanel.Begin(self.scroller.gameObject, Vector3(0, dis, 0), 8)
	self:updateProgressGroup()
end

function ActivityKeyboard:updateLayerIndexGroup()
	if self.curLayer + 1 == self.maxLayer then
		self.layerIndexImg:SetActive(false)
	else
		self.layerIndexImg:SetActive(true)
	end

	if #self.activityData.detail.senior_awards == 0 then
		self.layerIndexImg:SetActive(false)
		xyd.setUISpriteAsync(self.nextLayerImg, nil, "activity_keyboard_bg_sz_wjs")

		return
	end

	xyd.setUISpriteAsync(self.layerIndexImg, nil, "activity_keyboard_bg_" .. math.min(self.curLayer + 1, self.maxLayer - 1))

	if self.curLayer + 1 == self.maxLayer or self.activityData:checkLayerIsLock(self.curLayer + 1) == true then
		xyd.setUISpriteAsync(self.nextLayerImg, nil, "activity_keyboard_bg_sz_wjs")
	else
		xyd.setUISpriteAsync(self.nextLayerImg, nil, "activity_keyboard_bg_sz_js")
	end
end

function ActivityKeyboard:updateProgressGroup()
	local position = -150 + 300 / (self.maxLayer - 3) * (self.newLayer - 1)

	self.imgNote:Y(position)
end

function ActivityKeyboard:chooseLayer(layer)
	if #self.activityData.detail.senior_awards == 0 then
		return
	end

	self.tempLayer = layer

	local function callback(flag)
		if flag == true then
			self.curLayer = self.tempLayer
			self.newLayer = self.tempLayer
			local wrapcontentItems = self.wrapContent:getItems()

			for key, value in pairs(wrapcontentItems) do
				local itemData = value:chooseLayer(self.curLayer)
			end

			self:recenter(self.curLayer)
		end
	end

	if self.activityData:checkLayerIsLock(self.tempLayer) == true then
		xyd.alertTips(__("ACTIVITY_KEYBOARD_TEXT2", self.activityData:getNeedToUnlock(self.tempLayer)))

		return
	end

	if self.activityData:curLayerCanGetAward(self.tempLayer) == false then
		xyd.alertTips(__("ACTIVITY_KEYBOARD_TEXT4"))

		return
	end

	xyd.alertYesNo(__("ACTIVITY_KEYBOARD_TEXT1"), callback, __("YES"), false, nil, , , , , )
end

function ActivityKeyboardItem:ctor(go, parent)
	ActivityKeyboardItem.super.ctor(self, go, parent)

	self.parent = parent
	self.iconList = {}
end

function ActivityKeyboardItem:initUI()
	local go = self.go

	for i = 1, 5 do
		self["group" .. i] = self.go:NodeByName("iconGroup" .. i).gameObject
		self["itemIconRoot" .. i] = self["group" .. i]:NodeByName("heroIconRoot" .. i).gameObject
		self["itemIconEffect" .. i] = self["group" .. i]:NodeByName("heroIconEffect" .. i).gameObject
		self["itemIconEffect" .. i .. "_1"] = self["group" .. i]:NodeByName("heroIconEffect" .. i .. "_1").gameObject
		self["itemMask" .. i] = self["group" .. i]:NodeByName("iconMask" .. i).gameObject
	end

	self.leftGroup = self.go:NodeByName("leftGroup").gameObject
	self.curLayerImg = self.leftGroup:ComponentByName("curLayerImg", typeof(UISprite))
	self.IndexBgImg = self.leftGroup:ComponentByName("IndexBgImg", typeof(UISprite))
	self.IndexImg = self.IndexBgImg:ComponentByName("IndexImg", typeof(UISprite))
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.imgMaskList = {}

	UIEventListener.Get(self.go).onDragStart = function ()
		self.parent:onDragStart()
	end

	UIEventListener.Get(self.go).onDrag = function (go, delta)
		self.parent:onDrag(delta)
	end

	UIEventListener.Get(self.go).onDragEnd = function (go)
		self.parent:onDragEnd()
	end

	UIEventListener.Get(self.IndexBgImg.gameObject).onClick = function ()
		if self.parent.activityData:curLayerCanGetAward(self.data.layer) == false then
			return
		end

		self.parent:chooseLayer(self.data.layer)
	end
end

function ActivityKeyboardItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		self.data = nil

		return
	end

	self.data = info

	self.go:SetActive(true)

	if self.data.layer == self.parent.maxLayer then
		for i = 1, 5 do
			self["itemIconRoot" .. i]:SetActive(false)
			self["itemIconEffect" .. i]:SetActive(false)
			self["itemIconEffect" .. i .. "_1"]:SetActive(false)
			self["itemMask" .. i]:SetActive(false)
		end

		self.bg:SetActive(false)
		self.leftGroup:SetActive(false)

		if self.iconList[1] then
			for i = 1, 5 do
				self.iconList[i]:SetActive(false)
			end
		end

		return
	else
		for i = 1, 5 do
			self["itemIconRoot" .. i]:SetActive(true)
			self["itemIconEffect" .. i]:SetActive(true)
			self["itemIconEffect" .. i .. "_1"]:SetActive(true)
			self["itemMask" .. i]:SetActive(true)
		end

		self.bg:SetActive(true)
		self.leftGroup:SetActive(true)
		xyd.setUISpriteAsync(self.bg, nil, "activity_keyboard_bg_yp_" .. self.data.layer % 2, nil, , true)

		if self.iconList[1] then
			for i = 1, 5 do
				self.iconList[i]:SetActive(true)
			end
		end
	end

	for i = 1, 5 do
		self.imgMaskList[i] = nil
	end

	local function startCallback(callbackCopyIcon)
		self.parent:onDragStart(callbackCopyIcon)
	end

	local function dragCallback(callbackCopyIcon, delta)
		self.parent:onDrag(delta)
	end

	local function endCallback(callbackCopyIcon)
		self.parent:onDragEnd(callbackCopyIcon)
	end

	self.iconNum = #self.data

	for i = 1, self.iconNum do
		local award = self.data[i].award
		local params = {
			notShowGetWayBtn = true,
			show_has_num = false,
			scale = 0.8611111111111112,
			uiRoot = self["itemIconRoot" .. i],
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.parent.scroller,
			dragCallback = {
				startCallback = startCallback,
				dragCallback = dragCallback,
				endCallback = endCallback
			}
		}

		if not self.iconList[i] then
			params.uiRoot = self["itemIconRoot" .. i]
			local icon = AdvanceIcon.new(params)

			table.insert(self.iconList, icon)
			self.iconList[i]:SetActive(true)
		else
			self.iconList[i]:SetActive(true)
			self.iconList[i]:setInfo(params)
		end

		self["group" .. i]:X(self.parent.iconOffset[self.data.layer % 2][i][1])
		self["group" .. i]:Y(self.parent.iconOffset[self.data.layer % 2][i][2])

		self.data.itemIcons_layers[i] = self.iconList[i]

		self.data.itemIcons_layers[i]:setChoose(true)

		for j = 1, #self.parent.activityData.detail.senior_awards do
			if self.parent.activityData.detail.senior_awards[j] == self.data[i].tableID then
				self.data.itemIcons_layers[i]:setChoose(false)
			end
		end

		if not self["effect1" .. i] then
			self["effect1" .. i] = xyd.Spine.new(self["itemIconEffect" .. i])

			self["effect1" .. i]:setInfo("activity_keyboard_draw", function ()
				self["effect1" .. i]:SetActive(false)
			end)
		end

		self.data.itemIconDrawEffects[i] = self["effect1" .. i]

		if not self["effect2" .. i] then
			self["effect2" .. i] = xyd.Spine.new(self["itemIconEffect" .. i .. "_1"])

			self["effect2" .. i]:setInfo("activity_keyboard_note", function ()
				self["effect2" .. i]:SetActive(false)
			end)
		end

		self.data.itemIconNoteEffects[i] = self["effect2" .. i]
		self.imgMaskList[i] = self["itemMask" .. i]
	end

	xyd.setUISpriteAsync(self.IndexImg, nil, "activity_keyboard_bg_" .. self.data.layer, nil, , true)

	if self.parent.activityData:checkLayerIsLock(self.data.layer) == true or self.parent.activityData:curLayerCanGetAward(self.data.layer) == false then
		xyd.setUISpriteAsync(self.IndexBgImg, nil, "activity_keyboard_bg_sz_wjs")
	else
		xyd.setUISpriteAsync(self.IndexBgImg, nil, "activity_keyboard_bg_sz_js")
	end

	for i = 1, #self.imgMaskList do
		self.imgMaskList[i]:SetActive(self.data.layer ~= self.parent.curLayer)
	end

	self.IndexBgImg:SetActive(self.data.layer ~= self.parent.curLayer)
	self.curLayerImg:SetActive(self.data.layer == self.parent.curLayer)

	if self.data.layer % 2 == 1 then
		self.IndexBgImg:Y(10)
	else
		self.IndexBgImg:Y(15)
	end
end

function ActivityKeyboardItem:getData()
	return self.data
end

function ActivityKeyboardItem:getImgMaskList()
	return self.imgMaskList
end

function ActivityKeyboardItem:chooseLayer(layer)
	if self.data.layer == layer or self.data.layer == self.parent.maxLayer then
		for i = 1, #self.imgMaskList do
			self.imgMaskList[i]:SetActive(false)
		end
	else
		for i = 1, #self.imgMaskList do
			self.imgMaskList[i]:SetActive(true)
		end
	end

	self.IndexBgImg:SetActive(self.data.layer ~= self.parent.curLayer)
	self.curLayerImg:SetActive(self.data.layer == self.parent.curLayer)
end

return ActivityKeyboard
