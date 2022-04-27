local ActivityContent = import(".ActivityContent")
local ActivityBeachPuzzle = class("ActivityBeachPuzzle", ActivityContent)
local TempAwardItem = class("TempAwardItem", import("app.components.CopyComponent"))
local CardItem = class("CardItem", import("app.components.CopyComponent"))
local lineStartPointV = {
	-25,
	25
}
local lineStartPointH = {
	-20,
	15
}
local cItemPos = {
	{
		0,
		0,
		0
	},
	{
		0,
		0,
		1
	},
	{
		0,
		32,
		0
	},
	{
		0,
		8,
		1
	},
	{
		-8,
		0,
		1
	},
	{
		-16,
		0,
		1
	},
	{
		-16,
		0,
		0
	},
	{
		-24,
		0,
		1
	},
	{
		-16,
		8,
		1
	},
	{
		-8,
		16,
		1
	},
	{
		0,
		24,
		1
	},
	{
		0,
		56,
		0
	},
	{
		0,
		32,
		1
	},
	{
		-16,
		16,
		1
	},
	{
		-8,
		24,
		1
	},
	{
		-32,
		0,
		1
	},
	{
		-32,
		0,
		0
	},
	{
		-40,
		0,
		1
	},
	{
		-24,
		16,
		1
	},
	{
		-16,
		24,
		1
	},
	{
		0,
		40,
		1
	},
	{
		0,
		72,
		0
	},
	{
		0,
		48,
		1
	},
	{
		-24,
		24,
		1
	},
	{
		-48,
		0,
		1
	},
	{
		-48,
		0,
		0
	},
	{
		-56,
		0,
		1
	},
	{
		-40,
		16,
		1
	},
	{
		-24,
		32,
		1
	},
	{
		-16,
		40,
		1
	},
	{
		0,
		56,
		1
	},
	{
		0,
		88,
		0
	},
	{
		0,
		64,
		1
	},
	{
		-16,
		48,
		1
	},
	{
		-32,
		32,
		1
	},
	{
		-48,
		16,
		1
	},
	{
		-64,
		0,
		1
	},
	{
		-64,
		0,
		0
	},
	{
		-64,
		8,
		1
	},
	{
		-48,
		24,
		1
	},
	{
		-32,
		40,
		1
	},
	{
		-24,
		48,
		1
	},
	{
		-8,
		64,
		1
	},
	{
		0,
		114,
		-1
	},
	{
		-16,
		64,
		1
	},
	{
		-32,
		48,
		1
	},
	{
		-48,
		32,
		1
	},
	{
		-64,
		16,
		1
	},
	{
		-32,
		64,
		1
	},
	{
		-48,
		48,
		1
	},
	{
		-64,
		32,
		1
	},
	{
		-64,
		64,
		1
	}
}
local AntiCItemPos = {
	{
		0,
		0
	},
	{
		-96,
		0
	},
	{
		0,
		96
	},
	{
		0,
		192
	},
	{
		-96,
		96
	},
	{
		-192,
		96
	},
	{
		-96,
		192
	},
	{
		0,
		288
	},
	{
		-96,
		288
	},
	{
		-192,
		192
	},
	{
		-288,
		96
	},
	{
		-384,
		96
	},
	{
		-288,
		192
	},
	{
		-192,
		288
	},
	{
		-96,
		384
	},
	{
		-96,
		480
	},
	{
		-192,
		384
	},
	{
		-288,
		288
	},
	{
		-384,
		192
	},
	{
		-480,
		96
	},
	{
		-576,
		96
	},
	{
		-480,
		192
	},
	{
		-384,
		288
	},
	{
		-288,
		384
	},
	{
		-192,
		480
	},
	{
		-96,
		576
	},
	{
		-96,
		672
	},
	{
		-192,
		576
	},
	{
		-288,
		480
	},
	{
		-384,
		384
	},
	{
		-480,
		288
	},
	{
		-576,
		192
	},
	{
		-672,
		96
	},
	{
		-768,
		96
	},
	{
		-672,
		192
	},
	{
		-576,
		288
	},
	{
		-480,
		384
	},
	{
		-384,
		480
	},
	{
		-288,
		576
	},
	{
		-192,
		672
	},
	{
		-96,
		768
	},
	{
		-192,
		768
	},
	{
		-288,
		672
	},
	{
		-384,
		576
	},
	{
		-480,
		480
	},
	{
		-576,
		384
	},
	{
		-672,
		288
	},
	{
		-768,
		192
	},
	{
		-768,
		288
	},
	{
		-672,
		384
	},
	{
		-576,
		480
	},
	{
		-480,
		576
	},
	{
		-384,
		672
	},
	{
		-288,
		768
	},
	{
		-384,
		768
	},
	{
		-480,
		672
	},
	{
		-576,
		576
	},
	{
		-672,
		480
	},
	{
		-768,
		384
	},
	{
		-480,
		768
	},
	{
		-576,
		672
	},
	{
		-672,
		576
	},
	{
		-768,
		480
	},
	{
		-768,
		576
	},
	{
		-672,
		672
	},
	{
		-576,
		768
	},
	{
		-672,
		768
	},
	{
		-768,
		672
	},
	{
		-768,
		768
	}
}

function CardItem:ctor(go, parent)
	self.parent_ = parent

	CardItem.super.ctor(self, go)
end

function CardItem:initUI()
	local goTrans = self.go.transform
	self.iconImg = goTrans:ComponentByName("cardImg/itemIcon", typeof(UISprite))
	self.iconNum = goTrans:ComponentByName("cardImg/itemNum", typeof(UILabel))
	self.iconRoot_ = goTrans:NodeByName("cardImg/iconRoot")
	self.img3 = goTrans:ComponentByName("img3", typeof(UIWidget))
	self.cardImg = goTrans:ComponentByName("cardImg", typeof(UIWidget))
	UIEventListener.Get(self.iconImg.gameObject).onClick = handler(self, self.onClickCard)
end

function CardItem:setInfo(params)
	local itemID = params.id
	local itemNum = params.num
	self.info_ = params
	local iconName = xyd.tables.itemTable:getIcon(itemID)
	local type_ = xyd.tables.itemTable:getType(itemID)

	NGUITools.DestroyChildren(self.iconRoot_)

	self.iconNum.text = itemNum

	if type_ == xyd.ItemType.HERO_RANDOM_DEBRIS then
		self.heroIcon_ = xyd.getItemIcon({
			noClick = true,
			uiRoot = self.iconRoot_.gameObject,
			itemID = itemID
		})
		self.heroIcon_.num = nil
	end

	xyd.setUISpriteAsync(self.iconImg, nil, iconName)
end

function CardItem:onClickCard()
	if self.info_.id and tonumber(self.info_.id) > 0 then
		local params = {
			notShowGetWayBtn = true,
			show_has_num = true,
			itemID = self.info_.id,
			itemNum = self.info_.num,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end
end

function CardItem:setPos(x, y)
	self.go.transform:X(x)
	self.go.transform:Y(y)
end

function CardItem:awardAnim()
	self.parent_.animCount_ = self.parent_.animCount_ + 1
	local seq = self:getSequence(function ()
		self.go:SetActive(false)

		self.parent_.animCount_ = self.parent_.animCount_ - 1

		self.parent_.btnMask:SetActive(false)
		xyd.itemFloat({
			{
				item_id = self.info_.id,
				item_num = self.info_.num
			}
		})
		self.img3.transform:SetLocalScale(1, 1, 1)

		self.img3.alpha = 1
		self.cardImg.alpha = 1

		self.cardImg.transform:SetLocalScale(1, 1, 1)
		self.cardImg.transform:SetLocalPosition(0, -40, 0)

		self.cardImg.transform.localEulerAngles = Vector3(0, 0, 0)
	end)
	local imgTrans = self.cardImg.transform

	local function setter1(value)
		imgTrans.localEulerAngles = Vector3(0, 0, value)
	end

	local function setter2(value)
		self.cardImg.alpha = value
	end

	local function setter3(value)
		self.img3.alpha = value
	end

	seq:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 0, -5, 0.1))
	seq:Insert(0, imgTrans:DOScale(Vector3(0.88, 1.13, 1), 0.06666666666666667))
	seq:Insert(0.1, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), -5, 1, 0.1))
	seq:Insert(0.06666666666666667, imgTrans:DOScale(Vector3(0.97, 1.04, 1), 0.1))
	seq:Insert(0.16666666666666666, imgTrans:DOScale(Vector3(0.81, 1.16, 1), 0.06666666666666667))
	seq:Insert(0.23333333333333334, imgTrans:DOScale(Vector3(0.96, 1.02, 1), 0.1))
	seq:Insert(0.3333333333333333, imgTrans:DOScale(Vector3(0.72, 1.31, 1), 0.06666666666666667))
	seq:Insert(0.4, imgTrans:DOScale(Vector3(0.87, 0.96, 1), 0.1))
	seq:Insert(0.5, imgTrans:DOScale(Vector3(0.9, 0.9, 1), 0.16666666666666666))
	seq:Insert(0.2, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 1, -7, 0.1))
	seq:Insert(0.3, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), -7, 1.5, 0.1))
	seq:Insert(0.4, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), 1.5, -32, 0.26666666666666666))
	seq:Insert(0.4666666666666667, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter2), 1, 0, 0.2))
	seq:Insert(0.4, imgTrans:DOLocalMove(Vector3(34, 21.6, 0), 0.1))
	seq:Insert(0.5, imgTrans:DOLocalMove(Vector3(40, 26.5, 0), 0.16666666666666666))
	seq:Insert(0, self.img3.transform:DOScale(Vector3(0.92, 0.92, 1), 0.4))
	seq:Insert(0.4, self.img3.transform:DOScale(Vector3(0.5, 0.5, 1), 0.6666666666666666))
	seq:Insert(0.4666666666666667, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter3), 1, 0, 0.2))
end

function TempAwardItem:ctor(go, parent)
	self.parent_ = parent

	TempAwardItem.super.ctor(self, go)
end

function TempAwardItem:initUI()
	self.iconRoot_ = self.go:ComponentByName("iconRoot", typeof(UIWidget))
	self.lockImg_ = self.go:NodeByName("lockImg").gameObject
end

function TempAwardItem:update(_, _, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	if not info.canShow then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data = info
	self.isLock = self.data.isLock
	self.isSelect = self.data.isSelect
	self.itemID = self.data.itemID
	self.itemNum = self.data.itemNum

	self:setIcon()
end

function TempAwardItem:setIcon()
	local params = {
		notShowGetWayBtn = true,
		scale = 0.8981481481481481,
		itemID = self.itemID,
		num = self.itemNum,
		uiRoot = self.iconRoot_.gameObject,
		dragScrollView = self.parent_.scrollView_
	}

	if not self.icon_ then
		self.icon_ = xyd.getItemIcon(params)
	else
		local iconType = self.icon_:getIconType()
		local type_ = xyd.tables.itemTable:getType(self.itemID)

		if type_ ~= xyd.ItemType.HERO_DEBRIS and type_ ~= xyd.ItemType.HERO and type_ ~= xyd.ItemType.HERO_RANDOM_DEBRIS and type_ ~= xyd.ItemType.SKIN then
			if iconType == "item_icon" then
				self.icon_:setInfo(params)
			else
				NGUITools.DestroyChildren(self.iconRoot_.transform)

				self.icon_ = xyd.getItemIcon(params)
			end
		elseif iconType ~= "item_icon" then
			self.icon_:setInfo(params)
		else
			NGUITools.DestroyChildren(self.iconRoot_.transform)

			self.icon_ = xyd.getItemIcon(params)
		end
	end

	self.lockImg_:SetActive(self.isLock)
	self.icon_:setChoose(self.isSelect)
end

function ActivityBeachPuzzle:ctor(parentGO, params)
	self.lineGroup_ = {}
	self.zonesAwardItem_ = {}
	self.addList_ = {}
	self.antiAddList_ = {}
	self.animCount_ = 0

	ActivityBeachPuzzle.super.ctor(self, parentGO, params)
	dump(self.activityData.detail, "self.activityData.detail")
end

function ActivityBeachPuzzle:getPrefabPath()
	return "Prefabs/Windows/activity/activity_beach_puzzle"
end

function ActivityBeachPuzzle:initUI()
	ActivityBeachPuzzle.super.initUI(self)
	self:getUIComponent()
	self:updatePos()
	self:layout()
end

function ActivityBeachPuzzle:updatePos()
	local realHeight = xyd.Global.getRealHeight()

	self.itemGroup_.transform:Y(-84 - 0.11235955056179775 * (realHeight - 1280))
	self.itemGroup2_.transform:Y(-145 - 0.11235955056179775 * (realHeight - 1280))
	self.imgGroup_.transform:Y(-872 - 0.11235955056179775 * (realHeight - 1280))
	self.imgGroup2_.transform:Y(-872 - 0.11235955056179775 * (realHeight - 1280))
	self.partnerImg_.transform:Y(-847 - 0.11235955056179775 * (realHeight - 1280))
	self.partnerImg2_.transform:Y(-847 - 0.11235955056179775 * (realHeight - 1280))
	self.groupAwards_:Y(-442 - 0.11235955056179775 * (realHeight - 1280))
end

function ActivityBeachPuzzle:getUIComponent()
	local goTrans = self.go.transform
	self.bgImg_ = goTrans:NodeByName("bgImg").gameObject
	self.logoImg_ = goTrans:ComponentByName("logo", typeof(UISprite))
	self.itemGroup_ = goTrans:NodeByName("itemGroup")
	self.itemGroup2_ = goTrans:NodeByName("itemGroup2")
	self.labelNum_ = goTrans:ComponentByName("itemGroup/labelNum", typeof(UILabel))
	self.btnGet_ = goTrans:NodeByName("itemGroup/btnGet").gameObject
	self.labelNum2_ = goTrans:ComponentByName("itemGroup2/labelNum", typeof(UILabel))
	self.btnGet2_ = goTrans:NodeByName("itemGroup2/btnGet").gameObject
	self.btnHelp_ = goTrans:NodeByName("btnHelp").gameObject
	self.btnAward_ = goTrans:NodeByName("btnAward").gameObject
	local groupAwards = goTrans:NodeByName("groupAwards")
	self.groupAwards_ = groupAwards
	self.scrollView_ = groupAwards:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = groupAwards:ComponentByName("scrollView/grid", typeof(MultiRowWrapContent))
	self.itemRoot_ = groupAwards:NodeByName("itemRoot").gameObject
	self.btnPuzzle = goTrans:NodeByName("btnPuzzle").gameObject
	self.btnMask = goTrans:NodeByName("btnPuzzle/mask").gameObject
	self.btnPuzzleRed = goTrans:NodeByName("btnPuzzle/redPoint").gameObject
	self.costIcon_ = goTrans:NodeByName("btnPuzzle/icon").gameObject
	self.costNum_ = goTrans:ComponentByName("btnPuzzle/labelNum", typeof(UILabel))
	self.btnPuzzleLabel_ = goTrans:ComponentByName("btnPuzzle/labelDesc", typeof(UILabel))
	self.plusItem_ = goTrans:NodeByName("plusItem").gameObject
	self.cPlusItem_ = goTrans:NodeByName("cPlusItem").gameObject
	self.hcItem_ = goTrans:NodeByName("hcItem").gameObject
	self.cItem_ = goTrans:NodeByName("cItem").gameObject
	self.lineItemW = goTrans:NodeByName("lineItemW").gameObject
	self.lineItemH = goTrans:NodeByName("lineItemH").gameObject
	self.plusItemTotal_ = goTrans:NodeByName("imgGroup/plusItemTotal").gameObject
	self.plusItemTotal2_ = goTrans:NodeByName("partnerImg2/plusItemTotal").gameObject

	for i = 1, 24 do
		self["cardPoint" .. i] = goTrans:NodeByName("imgGroup/groupShadens/cardItem (" .. i - 1 .. ")").gameObject
	end

	self.effectNode_ = goTrans:NodeByName("imgGroup/effectNode").gameObject
	self.flashEffectNode_ = goTrans:NodeByName("imgGroup/effectNode2").gameObject
	self.imgGroup_ = goTrans:NodeByName("imgGroup").gameObject
	self.imgGroup2_ = goTrans:NodeByName("imgGroup2").gameObject
	self.partnerImg_ = goTrans:ComponentByName("partnerImg", typeof(UITexture))
	self.partnerImg2_ = goTrans:ComponentByName("partnerImg2", typeof(UITexture))
	self.awardCard_ = goTrans:NodeByName("awardCard").gameObject

	self.awardCard_:SetActive(false)
end

function ActivityBeachPuzzle:updateTexture()
	local textureName = xyd.tables.activityBeachPuzzleTable:getBgName(self.beach_id_)

	xyd.setUITextureByNameAsync(self.partnerImg_, textureName)
	xyd.setUITextureByNameAsync(self.partnerImg2_, textureName)
end

function ActivityBeachPuzzle:onRegister()
	UIEventListener.Get(self.btnPuzzle).onClick = handler(self, self.onClickBtn)

	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateItemNum))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.OPEN_NEW_BEACH_PUZZLE, handler(self, self.onOpenNewBeach))

	UIEventListener.Get(self.btnHelp_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_BEACH_PUZZLE_HELP"
		})
	end

	UIEventListener.Get(self.btnGet_).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.BEACH_ISLAND_ITEM,
			activityData = self.activityData
		})
	end

	UIEventListener.Get(self.btnGet2_).onClick = function ()
		local params = xyd.tables.activityTable:getWindowParams(xyd.ActivityID.ACTIVITY_BEACH_SUMMER)
		local testParams = nil

		if params ~= nil then
			testParams = params.activity_ids
		end

		xyd.WindowManager.get():closeWindow("activity_window", function ()
			xyd.openWindow("activity_window", {
				activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_BEACH_SUMMER),
				onlyShowList = testParams,
				select = xyd.ActivityID.ACTIVITY_BEACH_SHOP
			})
		end)
	end

	UIEventListener.Get(self.btnAward_).onClick = function ()
		xyd.openWindow("activity_beach_puzzle_award_preview_window", {
			round = self.beach_id_ - 1
		})
	end
end

function ActivityBeachPuzzle:layout()
	self.beach_id_ = self.activityData.detail.beach_id or 1
	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, self.itemRoot_, TempAwardItem, self)
	local cost = xyd.tables.miscTable:split2num("activity_beach_puzzle_cost", "value", "#")
	self.costNum_.text = "x" .. cost[2]

	xyd.setUISpriteAsync(self.logoImg_, nil, "activity_beach_puzzle_logo_" .. xyd.Global.lang)
	xyd.setUITextureByNameAsync(self.imgGroup_:GetComponent(typeof(UITexture)), "activity_beach_puzzle_mask")
	self:initItems()
	self:updateLine()
	self:updateItemNum()
	self:updateArea()
	self:initAreaAwardItems()
	self:updateBtnState()
	self:updateTexture()
	self:waitForFrame(1, function ()
		self:jumpToItem()
	end)
end

function ActivityBeachPuzzle:updateBtnState()
	if self:checkGoNext() then
		self.costIcon_:SetActive(false)
		self.costNum_.gameObject:SetActive(false)

		self.btnPuzzleLabel_.text = __("ACTIVITY_BEACH_PUZZLE_TEXT02")

		self.btnPuzzleLabel_.transform:Y(10)
		self.btnPuzzleLabel_.transform:X(5)
	else
		self.costIcon_:SetActive(true)
		self.costNum_.gameObject:SetActive(true)

		self.btnPuzzleLabel_.text = __("ACTIVITY_BEACH_PUZZLE_TEXT01")

		self.btnPuzzleLabel_.transform:X(8)
		self.btnPuzzleLabel_.transform:Y(-55)
	end

	self.btnPuzzleRed:SetActive(self.activityData:getRedMarkState())
end

function ActivityBeachPuzzle:onOpenNewBeach()
	self.beach_id_ = self.activityData.detail.beach_id or 1

	self:goNextPuzzle(function ()
		self:initItems(true)
		self:initAreaAwardItems()
		self:updateLine()
		self:updateBtnState()
		self:waitForFrame(1, function ()
			self.scrollView_:ResetPosition()
			self:waitForFrame(1, function ()
				self:jumpToItem()
			end)
			self.btnMask:SetActive(false)
		end)
		self:updateTexture()
	end)
end

function ActivityBeachPuzzle:initAreaAwardItems()
	local awards = xyd.tables.activityBeachPuzzleTable:getAwards(self.beach_id_)
	local zones = xyd.tables.activityBeachPuzzleTable:getArea(self.beach_id_)
	local zonesNum = #zones
	local awarded_zones = self.activityData.detail.awarded_zones or {}

	for _, id in ipairs(awarded_zones) do
		zones[id] = nil
	end

	for i = 1, zonesNum do
		if zones[i] and not self.zonesAwardItem_[i] then
			local x, y = self:getCardPos(zones[i])
			local newItemRoot = NGUITools.AddChild(self.imgGroup_, self.awardCard_)

			newItemRoot:SetActive(true)

			self.zonesAwardItem_[i] = CardItem.new(newItemRoot, self)

			self.zonesAwardItem_[i]:setInfo({
				id = awards[i][1],
				num = awards[i][2]
			})
			self.zonesAwardItem_[i]:setPos(x, y)
		elseif zones[i] and self.zonesAwardItem_[i] then
			local x, y = self:getCardPos(zones[i])

			self.zonesAwardItem_[i]:SetActive(true)
			self.zonesAwardItem_[i]:setInfo({
				id = awards[i][1],
				num = awards[i][2]
			})
			self.zonesAwardItem_[i]:setPos(x, y)
		elseif self.zonesAwardItem_[i] and not zones[i] then
			self.zonesAwardItem_[i]:SetActive(false)
		end
	end
end

function ActivityBeachPuzzle:onGetAward(event)
	local detail = require("cjson").decode(event.data.detail)
	local item = detail.item

	xyd.models.itemFloatModel:pushNewItems({
		item
	})

	local unlock_areas, unlock_zones = self.activityData:getNewUnlockData()

	if #unlock_zones <= 0 and #unlock_areas > 0 then
		for _, area_id in ipairs(unlock_areas) do
			self:playCritalAni(area_id)
		end
	elseif #unlock_zones > 0 and #unlock_areas > 0 then
		for _, area_id in ipairs(unlock_areas) do
			self:playCritalAni(area_id, function ()
				for index2, zone_id in ipairs(unlock_zones) do
					self.btnMask:SetActive(true)
					self:unlockZoneAni(zone_id, function ()
						if self:checkGoNext() then
							local locked_areas = {}

							for i = 1, 24 do
								if xyd.arrayIndexOf(self.activityData.detail.areas, i) <= 0 then
									table.insert(locked_areas, i)
								end
							end

							if #locked_areas == 0 then
								self:playFlashEffect()
								self.plusItemTotal_:SetActive(true)

								local finalAward = xyd.tables.activityBeachPuzzleTable:getFinalAward(self.beach_id_)

								xyd.itemFloat({
									{
										item_id = finalAward[1],
										item_num = finalAward[2]
									}
								})
								self:initItems(true)
							else
								for num, area_id in ipairs(locked_areas) do
									self:playCritalAni(area_id, function ()
										if num == #locked_areas then
											self:playFlashEffect()
											self.plusItemTotal_:SetActive(true)

											local finalAward = xyd.tables.activityBeachPuzzleTable:getFinalAward(self.beach_id_)

											xyd.itemFloat({
												{
													item_id = finalAward[1],
													item_num = finalAward[2]
												}
											})
											self:initItems(true)
										end
									end)
								end
							end
						end
					end)
				end
			end)
		end
	end

	self:updateBtnState()
end

function ActivityBeachPuzzle:onClickBtn()
	if self.animCount_ and self.animCount_ <= 0 then
		if self:checkGoNext() then
			local msg = messages_pb:open_new_beach_puzzle_req()
			msg.activity_id = xyd.ActivityID.ACTIVITY_BEACH_PUZZLE

			xyd.Backend.get():request(xyd.mid.OPEN_NEW_BEACH_PUZZLE, msg)
		else
			local cost = xyd.tables.miscTable:split2num("activity_beach_puzzle_cost", "value", "#")

			if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
				xyd.alertTips(__("SPIRIT_NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))
			else
				xyd.models.activity:reqAward(xyd.ActivityID.ACTIVITY_BEACH_PUZZLE)
			end
		end
	end
end

function ActivityBeachPuzzle:checkGoNext()
	local awardParts = self.activityData.detail.awarded_zones
	local linePos = xyd.tables.activityBeachPuzzleTable:getLinePos(self.beach_id_)
	local partNum = #linePos

	if #awardParts == #linePos then
		return true
	end

	return false
end

function ActivityBeachPuzzle:getCardPos(zones)
	local startID = zones[1]
	local endID = zones[#zones]
	local endX = -((24 - endID) % 4) * 116 - 20
	local endY = math.modf((24 - endID) / 4) * 120 + 21.3
	local startX = -((24 - startID) % 4 + 1) * 116 - 20
	local startY = (math.modf((24 - startID) / 4) + 1) * 120 + 21.3

	return (startX + endX) / 2, (startY + endY) / 2
end

function ActivityBeachPuzzle:updateLine()
	local linePos = xyd.tables.activityBeachPuzzleTable:getLinePos(self.beach_id_)
	local partNum = #linePos
	local awardParts = self.activityData.detail.awarded_zones

	for _, partID in ipairs(awardParts) do
		if linePos[partID] then
			linePos[partID] = nil
		end
	end

	for i = 1, partNum do
		if linePos[i] then
			if self.lineGroup_[i] then
				for _, line in ipairs(self.lineGroup_[i]) do
					NGUITools.Destroy(line.gameObject)
				end
			end

			local startX = -math.fmod(linePos[i][2] - 1, 5) * 116 - 20
			local startY = math.modf(linePos[i][2] / 5) * 120 + 21.3
			local height = (math.modf(linePos[i][1] / 5) - math.modf(linePos[i][2] / 5)) * 120
			local width = (linePos[i][3] - linePos[i][2]) * 116
			local newHLine1 = NGUITools.AddChild(self.imgGroup_, self.lineItemH)
			local newHLine2 = NGUITools.AddChild(self.imgGroup_, self.lineItemH)
			local newHLine1Widgt = newHLine1:GetComponent(typeof(UIWidget))
			local newHLine2Widgt = newHLine2:GetComponent(typeof(UIWidget))
			newHLine1Widgt.width = height
			newHLine2Widgt.width = height

			newHLine1.transform:X(startX)
			newHLine1.transform:Y(startY)

			newHLine1.transform.localEulerAngles = Vector3(0, 0, -90)
			newHLine2.transform.localEulerAngles = Vector3(0, 0, -90)

			newHLine2.transform:X(startX - width)
			newHLine2.transform:Y(startY)

			local newWLine1 = NGUITools.AddChild(self.imgGroup_, self.lineItemW)
			local newWLine2 = NGUITools.AddChild(self.imgGroup_, self.lineItemW)
			local newWLine1Widgt = newWLine1:GetComponent(typeof(UIWidget))
			local newWLine2Widgt = newWLine2:GetComponent(typeof(UIWidget))
			newWLine1Widgt.width = width
			newWLine2Widgt.width = width

			newWLine1.transform:X(startX)
			newWLine1.transform:Y(startY)
			newWLine2.transform:X(startX)
			newWLine2.transform:Y(startY + height)

			self.lineGroup_[i] = {
				newWLine1Widgt,
				newHLine2Widgt,
				newHLine1Widgt,
				newWLine2Widgt
			}
		elseif self.lineGroup_[i] then
			for _, line in ipairs(self.lineGroup_[i]) do
				NGUITools.Destroy(line.gameObject)
			end
		end
	end
end

function ActivityBeachPuzzle:playFlashEffect(callbcak)
	local params = {
		Complete = function ()
			if callbcak then
				callbcak()
			end
		end
	}

	if not self.FlashEffect_ then
		self.FlashEffect_ = xyd.Spine.new(self.flashEffectNode_)

		self.FlashEffect_:setInfo("activity_beach_puzzle_flash", function ()
			self.FlashEffect_:SetLocalPosition(-139, 497)
			self.FlashEffect_:playWithEvent("texia01", 1, 1, params)
		end)
	else
		self.FlashEffect_:playWithEvent("texia01", 1, 1, params)
	end
end

function ActivityBeachPuzzle:unlockZoneAni(zone_id, callback)
	local linePos = xyd.tables.activityBeachPuzzleTable:getLinePos(self.beach_id_)[zone_id]
	local startX = -math.fmod(linePos[1] - 1, 5) * 116 - 20
	local startY = math.modf(linePos[1] / 5) * 120 + 21.3

	if not self.lightEffect_ then
		self.lightEffect_ = xyd.Spine.new(self.effectNode_)

		self.lightEffect_:setInfo("activity_beach_puzzle_line", function ()
			self.effectNode_.transform:X(startX)
			self.effectNode_.transform:Y(startY)
			self.lightEffect_:SetLocalScale(1, 1.6, 1)
			self.lightEffect_:setLocalEulerAngles(0, 0, -90)
			self.lightEffect_:play("texiao01", 0, 1)
			self:showEffect(zone_id, callback)
		end)
	else
		self.effectNode_.transform:X(startX)
		self.effectNode_.transform:Y(startY)
		self.lightEffect_:setLocalEulerAngles(0, 0, -90)
		self.lightEffect_:SetActive(true)
		self:showEffect(zone_id, callback)
	end
end

function ActivityBeachPuzzle:showEffect(zone_id, callback)
	self.animCount_ = self.animCount_ + 1
	local linePos = xyd.tables.activityBeachPuzzleTable:getLinePos(self.beach_id_)[zone_id]
	local startX = -math.fmod(linePos[1] - 1, 5) * 116 - 20
	local startY = math.modf(linePos[1] / 5) * 120 + 21.3
	local moveNum1 = (linePos[1] - linePos[2]) / 5
	local targetPos1 = Vector3(startX, startY - moveNum1 * 120, 0)
	local moveNum2 = linePos[3] - linePos[2]
	local targetPos2 = Vector3(startX - moveNum2 * 116, startY - moveNum1 * 120, 0)
	local targetPos3 = Vector3(startX - moveNum2 * 116, startY, 0)
	local targetPos4 = Vector3(startX, startY, 0)
	local nodeTrans = self.effectNode_.transform
	local seqEffect = self:getSequence(function ()
		self.animCount_ = self.animCount_ - 1

		self.lightEffect_:SetActive(false)

		for _, line in ipairs(self.lineGroup_[zone_id]) do
			if line then
				line.gameObject.transform:SetActive(false)
			end
		end

		if self.zonesAwardItem_[zone_id] then
			self.zonesAwardItem_[zone_id]:awardAnim()
		end

		if callback then
			callback()
		end
	end)

	local function setter1(value)
		self.lightEffect_:setLocalEulerAngles(0, 0, value)
	end

	local timeFeet = 0.1

	seqEffect:Insert(0, nodeTrans:DOLocalMove(targetPos1, timeFeet * moveNum1):SetEase(DG.Tweening.Ease.Linear))
	seqEffect:Insert(timeFeet * moveNum1 - 0.05, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), -90, -180, 0.05))
	seqEffect:Insert(timeFeet * moveNum1, nodeTrans:DOLocalMove(targetPos2, timeFeet * moveNum2):SetEase(DG.Tweening.Ease.Linear))
	seqEffect:Insert(timeFeet * (moveNum1 + moveNum2) - 0.05, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), -180, -270, 0.05))
	seqEffect:Insert(timeFeet * (moveNum1 + moveNum2), nodeTrans:DOLocalMove(targetPos3, timeFeet * moveNum1):SetEase(DG.Tweening.Ease.Linear))
	seqEffect:Insert(timeFeet * (2 * moveNum1 + moveNum2) - 0.05, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter1), -270, -360, 0.05))
	seqEffect:Insert(timeFeet * (2 * moveNum1 + moveNum2), nodeTrans:DOLocalMove(targetPos4, timeFeet * moveNum2):SetEase(DG.Tweening.Ease.Linear))
end

function ActivityBeachPuzzle:initItems(keepPosition)
	local ids = xyd.tables.activityBeachPuzzleTable:getIDs()
	local infos = {}

	for index, id in ipairs(ids) do
		local params = {
			isLock = self.beach_id_ < index,
			isSelect = index < self.beach_id_ or index == self.beach_id_ and self:checkGoNext(),
			itemID = xyd.tables.activityBeachPuzzleTable:getFinalAward(id)[1],
			itemNum = xyd.tables.activityBeachPuzzleTable:getFinalAward(id)[2],
			canShow = xyd.tables.activityBeachPuzzleTable:getIsRepeat(id) ~= 1 or self.beach_id_ >= id - 1
		}

		table.insert(infos, params)
	end

	self.infos_ = infos

	self.multiWrap_:setInfos(self.infos_, {
		keepPosition = keepPosition
	})
end

function ActivityBeachPuzzle:jumpToItem()
	local ids = xyd.tables.activityBeachPuzzleTable:getIDs()

	if self.beach_id_ < 3 then
		return
	else
		local jumpId = self.beach_id_

		if self.beach_id_ > #ids - 2 then
			jumpId = #ids - 2
		end

		self.multiWrap_:jumpToIndex(jumpId)
	end
end

function ActivityBeachPuzzle:updateItemNum()
	self.labelNum_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.BEACH_ISLAND_ITEM)
	self.labelNum2_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.BEACH_SKIN_CARD)
	local win = xyd.WindowManager.get():getWindow("activity_window")

	if win then
		win:updateTitleRedMark()
	end
end

function ActivityBeachPuzzle:playCritalAni(area_id, callback)
	self.addList_[area_id] = {}
	self.animCount_ = self.animCount_ + 1
	local i = 1

	while i <= #cItemPos do
		local index = i

		self:waitForFrame((index + 1) / 3, function ()
			self:addItemPos(index, area_id)
			self:addItemPos(index + 1, area_id)
			self:addItemPos(index + 2, area_id)
		end)

		i = i + 3
	end

	self:waitForFrame((#cItemPos + 6) / 3, function ()
		local aniItem = self["cardPoint" .. area_id]
		local item = NGUITools.AddChild(aniItem, self.plusItem_)

		item.transform:X(0)
		item.transform:Y(0)
		item:SetActive(true)

		self.addList_[area_id][#cItemPos + 1] = item
		self.animCount_ = self.animCount_ - 1

		if callback then
			callback()
		end

		self:waitForFrame(5, function ()
			for i = 1, #cItemPos do
				local item = self.addList_[area_id][i]

				if item then
					NGUITools.Destroy(item)

					self.addList_[area_id][i] = nil
				end
			end
		end)
	end)
end

function ActivityBeachPuzzle:addItemPos(index, area_id)
	local pos = cItemPos[index]

	if not pos then
		return
	end

	local aniItem = self["cardPoint" .. area_id]
	local itemNew = nil

	if pos[3] == 0 then
		itemNew = NGUITools.AddChild(aniItem, self.hcItem_)
	elseif pos[3] == 1 then
		itemNew = NGUITools.AddChild(aniItem, self.cItem_)
	else
		itemNew = NGUITools.AddChild(aniItem, self.hcItem_)
		itemNew.transform.localEulerAngles = Vector3(0, 0, 90)
	end

	itemNew:X(pos[1])
	itemNew:Y(pos[2])
	itemNew:SetActive(true)

	self.addList_[area_id][index] = itemNew
end

function ActivityBeachPuzzle:addItemFinal(area_id)
	local aniItem = self["cardPoint" .. area_id]
	local item = NGUITools.AddChild(aniItem, self.plusItem_)

	item.transform:X(0)
	item.transform:Y(0)
	item:SetActive(true)

	if not self.addList_[area_id] then
		self.addList_[area_id] = {}
	end

	table.insert(self.addList_[area_id], item)
end

function ActivityBeachPuzzle:destoryAllAddItem()
	for index, list in pairs(self.addList_) do
		for _, item in pairs(list) do
			NGUITools.Destroy(item)
		end
	end

	for _, item in pairs(self.antiAddList_) do
		NGUITools.Destroy(item)
	end

	self.addList_ = {}
	self.antiAddList_ = {}
end

function ActivityBeachPuzzle:goNextPuzzle(callback)
	self.plusItemTotal2_:SetActive(false)
	self.plusItemTotal_:SetActive(false)
	self.partnerImg2_:SetActive(true)
	self.imgGroup2_:SetActive(true)

	self.animCount_ = self.animCount_ + 1

	self:waitForFrame(1, function ()
		self:destoryAllAddItem()
		self:playAntiCritalAni(callback)
	end)
end

function ActivityBeachPuzzle:playAntiCritalAni(callback)
	local i = 1

	while i <= #AntiCItemPos do
		local index = i

		self:waitForFrame((index + 1) / 2, function ()
			self:addAntiItemPos(index)
			self:addAntiItemPos(index + 1)
		end)

		i = i + 2
	end

	self:waitForFrame((#AntiCItemPos + 6) / 2, function ()
		self.animCount_ = self.animCount_ - 1

		self.plusItemTotal2_:SetActive(true)

		if callback then
			callback()
		end

		self:waitForFrame(1, function ()
			self.partnerImg2_:SetActive(false)
			self.imgGroup2_:SetActive(false)
		end)
	end)
end

function ActivityBeachPuzzle:addAntiItemPos(index)
	local pos = AntiCItemPos[index]

	if not pos or not pos[1] or not pos[2] then
		return
	end

	local itemNew = NGUITools.AddChild(self.partnerImg2_.gameObject, self.cPlusItem_)

	itemNew:X(pos[1])
	itemNew:Y(pos[2])
	itemNew:SetActive(true)

	self.antiAddList_[index] = itemNew
end

function ActivityBeachPuzzle:updateArea()
	local index = 0

	for _, area_id in ipairs(self.activityData.detail.areas) do
		index = index + 1

		self:addItemFinal(area_id)
	end

	if self:checkGoNext() then
		self.plusItemTotal_:SetActive(true)
	end
end

return ActivityBeachPuzzle
