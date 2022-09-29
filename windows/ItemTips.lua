local ItemTable = xyd.tables.itemTable
local EquipTable = xyd.tables.equipTable
local PartnerPictureTable = xyd.tables.partnerPictureTable
local PartnerTable = xyd.tables.partnerTable
local DBuffTable = xyd.tables.dBuffTable
local JobTable = xyd.tables.jobTable
local GroupTable = xyd.tables.groupTable
local GetWayEquipTable = xyd.tables.getWayEquipTable
local Backpack = xyd.models.backpack
local ActivityModel = xyd.models.activity
local Summon = xyd.models.summon
local Slot = xyd.models.slot
local HeroIcon = require("app.components.HeroIcon")
local SingleWayItem = import("app.components.SingleWayItem")
local BtnLayoutType = {
	MID_TOP = 3,
	LEFT_RIGHT = 4,
	LEFT_RIGHT_TOP = 5,
	TOP = 2,
	MID = 1,
	NONE = 0
}
local BtnType = {
	TOP = 1,
	BOT_RIGHT = 4,
	BOT_MID = 3,
	BOT_LEFT = 2
}
local ItemTips = class("ItemTips", import("app.components.BaseComponent"))

function ItemTips:ctor(parentGO, params, windowDepth)
	self.params = params
	self.itemID = params.itemID or 0
	self.type_ = ItemTable:getType(self.itemID)
	self.data = params

	ItemTips.super.ctor(self, parentGO)

	self.btnCallback = {}
	self.itemNum = params.itemNum or 0
	self.smallTips_ = params.smallTips or ""
	self.hideText = params.hideText or false
	self.wndType_ = params.wndType or xyd.ItemTipsWndType.NORMAL
	self.wndName_ = params.wndName
	self.notShowGetWayBtn = params.notShowGetWayBtn
	self.btnLayoutIndex_ = params.btnLayout or BtnLayoutType.NONE
	self.parent_item_ = params.parent_item
	self.changeY = 0
	self.descs_ = {}
	self.isShowWays = false
	self.isWaysCreate_ = false
	self.descOffY = 0
	self.ways_val = params.ways_val
	self.showBagType_ = ItemTable:showInBagType(self.itemID)
	self.ways = {}
	self.show_has_num = params.show_has_num or false
	self.is_spare_crystal = params.is_spare_crystal
	self.collectionInfo_ = params.collectionInfo
	self.windowDepth_ = windowDepth
	self.hideBtnCheck = params.hideBtnCheck
	self.quickItem_ = params.quickItem

	self:initLayout()
end

function ItemTips:getPrefabPath()
	if self.type_ == xyd.ItemType.ARTIFACT and self.data.choose_equip then
		local exSkill = EquipTable:exSkillId(self.itemID)[1]

		if exSkill and exSkill > 0 then
			return "Prefabs/Windows/item_tips_artifact"
		else
			return "Prefabs/Windows/item_tips"
		end
	else
		return "Prefabs/Windows/item_tips"
	end
end

function ItemTips:initLayout()
	self:getUIComponent()
	self:getArtiDesc()
	self:initUIComponent()
	self:registerEvent()

	if xyd.isIosTest() then
		self:iosTestChangeUI1()
	end
end

function ItemTips:getArtiDesc()
	local go = self.go
	self.groupDescPart_ = go:NodeByName("groupDesc").gameObject
	self.groupDescBg_ = go:ComponentByName("groupDesc/bg", typeof(UIWidget))
	self.groupDescName_ = self.groupDescPart_:ComponentByName("bg/scrollView/labelName", typeof(UILabel))
	self.groupDescLabel_ = self.groupDescPart_:ComponentByName("bg/scrollView/labelDesc", typeof(UILabel))

	self.groupDescPart_:SetActive(false)
end

function ItemTips:registerEvent()
	if self.btnCallback[BtnType.BOT_MID + 1] then
		xyd.setDarkenBtnBehavior(self.btnBotMid_, self, self.btnCallback[BtnType.BOT_MID + 1])
	end

	if self.btnCallback[BtnType.BOT_RIGHT + 1] then
		xyd.setDarkenBtnBehavior(self.btnBotRight_, self, self.btnCallback[BtnType.BOT_RIGHT + 1])
	end

	if self.btnCallback[BtnType.BOT_LEFT + 1] then
		xyd.setDarkenBtnBehavior(self.btnBotLeft_, self, self.btnCallback[BtnType.BOT_LEFT + 1])
	end

	if self.btnCallback[BtnType.TOP + 1] then
		xyd.setDarkenBtnBehavior(self.btnTop_, self, self.btnCallback[BtnType.TOP + 1])
		self.btnBox_:SetLocalPosition(205, -105, 0)
	end

	if self.type_ == xyd.ItemType.OPTIONAL_TREASURE_CHEST or xyd.tables.itemTable:checkJobBoxID(self.itemID) then
		xyd.setDarkenBtnBehavior(self.btnBox_, self, self.onBoxBtnOptionalTreasureChest)
	else
		xyd.setDarkenBtnBehavior(self.btnBox_, self, self.onBoxBtnNormal)
	end

	if xyd.tables.itemTable:getType(self.itemID) == xyd.ItemType.ARTIFACT and xyd.tables.equipTextTable:getSkinDesc(self.itemID) then
		xyd.setDarkenBtnBehavior(self.btnDesc_, self, self.onClickDescBtn)
	end

	if self.btnArtifactUp_ and xyd.tables.itemTable:getType(self.itemID) == xyd.ItemType.ARTIFACT then
		xyd.setDarkenBtnBehavior(self.btnArtifactUp_.gameObject, self, self.onClickBtnArtifactUp)
	end

	if self.resetBtn and self.data.resetCallBack then
		xyd.setDarkenBtnBehavior(self.resetBtn.gameObject, self, self.data.resetCallBack)
	end
end

function ItemTips:onClickBtnArtifactUp()
	local datas = xyd.models.backpack:getItems()
	local equipArtifactList = {}

	for i = 1, #datas do
		local itemID = datas[i].item_id
		local itemNum = tonumber(datas[i].item_num)

		if itemID == self.itemID then
			itemNum = itemNum - 1
		end

		if itemNum and itemNum > 0 then
			local item = {
				itemID = itemID,
				itemNum = itemNum
			}

			if xyd.ItemType.ARTIFACT == xyd.tables.itemTable:getType(itemID) then
				table.insert(equipArtifactList, item)
			end
		end
	end

	xyd.WindowManager:get():openWindow("artifact_up_window", {
		itemID = self.itemID,
		equips = equipArtifactList
	})
	xyd.WindowManager:get():closeWindow("item_tips_window")
end

function ItemTips:onClickDescBtn()
	if self.inAnimation_ then
		return
	end

	if not self.showDesc_ then
		self.showDesc_ = true

		self.groupDescBg_.transform:SetLocalScale(0, 0, 1)

		self.inAnimation_ = true
		local sequence = self:getSequence(function ()
			self.inAnimation_ = false
		end)

		self.groupDescPart_:SetActive(true)

		local height = self.groupDescLabel_.height + 80

		if height >= 412 then
			height = 412
		end

		self.groupDescBg_.height = height

		self.groupDescBg_.transform:Y(self.imgBG2.transform.localPosition.y - 5)
		sequence:Insert(0, self.groupDescBg_.transform:DOScale(Vector3(1.05, 1.05, 1.05), 0.23))
		sequence:Insert(0.23, self.groupDescBg_.transform:DOScale(Vector3(1, 1, 1), 0.2))
		sequence:Insert(0, self.go.transform:DOLocalMove(Vector3(0, height / 2 + 10, 0), 0.23))
		sequence:Insert(0.23, self.go.transform:DOLocalMove(Vector3(0, height / 2, 0), 0.2))
	else
		self.showDesc_ = false
		self.inAnimation_ = true
		local sequence = self:getSequence(function ()
			self.inAnimation_ = false
		end)

		sequence:Insert(0, self.groupDescBg_.transform:DOScale(Vector3(0, 0, 0), 0.23))
		sequence:Insert(0, self.go.transform:DOLocalMove(Vector3(0, 0, 0), 0.23))
	end
end

function ItemTips:getUIComponent()
	local go = self.go
	self.groupWays_ = go:ComponentByName("groupWays_", typeof(UIWidget))
	self.imgBG = go:ComponentByName("groupWays_/imgBG", typeof(UISprite))
	self.imgListBg_ = go:ComponentByName("groupWays_/imgListBg_", typeof(UISprite))
	self.groupWaysList_ = go:ComponentByName("groupWays_/top_left/groupWaysList_", typeof(UIWidget))
	self.labelWaysDesc_ = go:ComponentByName("groupWays_/top_left/labelWaysDesc_", typeof(UILabel))
	self.groupMain_ = go:ComponentByName("groupMain_", typeof(UIWidget))
	self.imgBG2 = go:ComponentByName("groupMain_/imgBG", typeof(UISprite))
	self.labelName_ = go:ComponentByName("groupMain_/top_left/labelName_", typeof(UILabel))
	self.labelType_ = go:ComponentByName("groupMain_/top_left/labelType_", typeof(UILabel))
	self.labelType_ = go:ComponentByName("groupMain_/top_left/labelType_", typeof(UILabel))
	self.labelSmallTips_ = go:ComponentByName("groupMain_/top_left/labelSmallTips_", typeof(UILabel))
	self.labelHasNum_ = go:ComponentByName("groupMain_/top_left/labelHasNum_", typeof(UILabel))
	self.groupIcon_ = go:ComponentByName("groupMain_/groupIcon_", typeof(UISprite))
	self.groupIcon2_ = go:ComponentByName("groupMain_/groupIcon2_", typeof(UISprite))
	self.upArrow_ = go:ComponentByName("groupMain_/upArrow_", typeof(UISprite))

	if self.type_ == xyd.ItemType.ARTIFACT and self.data.choose_equip then
		local exSkill = EquipTable:exSkillId(self.itemID)[1]

		if exSkill and exSkill > 0 then
			self.groupDesc_ = go:NodeByName("groupMain_/descScroll/groupDesc_").gameObject
			self.groupDescWidght_ = self.groupDesc_:GetComponent(typeof(UIWidget))
			self.descScroll_ = go:ComponentByName("groupMain_/descScroll", typeof(UIScrollView))
			self.descScroll_panel = self.descScroll_.transform:GetComponent(typeof(UIPanel))

			if self.windowDepth_ then
				self.descScroll_panel.depth = self.windowDepth_ + 1
			end
		else
			self.groupDesc_ = go:NodeByName("groupMain_/groupDesc_").gameObject
		end
	else
		self.groupDesc_ = go:NodeByName("groupMain_/groupDesc_").gameObject
	end

	self.btnTop_ = go:NodeByName("groupMain_/btnTop_").gameObject
	self.btnBotMid_ = go:NodeByName("groupMain_/bottom_left/btnBotMid_").gameObject
	self.btnBotMid_Widget = self.btnBotMid_:GetComponent(typeof(UIWidget))
	self.btnBotLeft_ = go:NodeByName("groupMain_/bottom_left/btnBotLeft_").gameObject
	self.btnBotRight_ = go:NodeByName("groupMain_/bottom_left/btnBotRight_").gameObject
	self.labelMid = go:ComponentByName("groupMain_/bottom_left/btnBotMid_/button_label", typeof(UILabel))
	self.labelLeft = go:ComponentByName("groupMain_/bottom_left/btnBotLeft_/button_label", typeof(UILabel))
	self.labelRight = go:ComponentByName("groupMain_/bottom_left/btnBotRight_/button_label", typeof(UILabel))
	self.baseWayItem = go:NodeByName("groupWays_/singleWayItem").gameObject
	self.btnBox_ = go:NodeByName("groupMain_/btnBox_").gameObject
	self.btnDesc_ = go:NodeByName("groupMain_/btnDesc").gameObject
	self.btnArtifactUp_ = go:NodeByName("groupMain_/btnArtifactUp")
	self.resetBtn = self.groupMain_.gameObject:NodeByName("resetBtn")

	if self.wndType_ == xyd.ItemTipsWndType.DRESS_COLLECTION then
		self.btnDressSuit_ = go:NodeByName("groupMain_/btnDressSuit_").gameObject
		self.groupColletion = self.groupMain_:NodeByName("groupColletion").gameObject
		self.gotImg = self.groupColletion:ComponentByName("gotImg", typeof(UISprite))
		self.resItem = self.groupColletion:NodeByName("resItem").gameObject
		self.labelResNum = self.resItem:ComponentByName("labelResNum", typeof(UILabel))
	end
end

function ItemTips:initUIComponent()
	self.groupWays_:SetActive(false)
	self.groupMain_:SetActive(true)
	self.baseWayItem:SetActive(false)

	local name = ItemTable:getName(self.itemID)
	self.labelName_.text = name

	if self.itemID == 20001081 then
		self.labelName_.width = 450
	end

	xyd.labelQulityColor(self.labelName_, self.itemID)
	self.labelType_:SetActive(true)

	local brief = ItemTable:getBrief(self.itemID)
	self.labelType_.text = brief

	if self.wndType_ == xyd.ItemTipsWndType.GAMBLE then
		self.labelSmallTips_.text = self.smallTips_

		self.labelSmallTips_:SetActive(true)

		self.labelSmallTips_.color = Color.New2(1549556991)
	else
		self.labelSmallTips_:SetActive(false)
	end

	if self.show_has_num and self:checkShowHasNum(self.type_) then
		local num = 0

		if self.wndType_ == xyd.ItemTipsWndType.BACKPACK and self.type_ == 3 then
			local partnerCost = ItemTable:partnerCost(self.itemID)
			local tableID = partnerCost[1]
			local group = Slot:getListByTableID(tableID)
			num = #group
		elseif self.type_ == 12 then
			local tableIDs = PartnerTable:getPartnerIdBySkinId(self.itemID)
			num = Backpack:getItemNumByID(self.itemID)

			for _, tableID in pairs(tableIDs) do
				local group = Slot:getListByTableID(tonumber(tableID))

				for _, partner in pairs(group) do
					local dressSkinID = partner:getSkinId()

					if dressSkinID == self.itemID then
						num = num + 1
					end
				end
			end

			self.labelHasNum_.text = __("ITEM_HAS_NUM", xyd.getRoughDisplayNumber(num))

			self.labelHasNum_:SetActive(true)
		elseif self.type_ == xyd.ItemType.DRESS then
			local dress_fragment_info = xyd.tables.senpaiDressItemTable:getDressShard(self.itemID)
			local dress_fragment_id = -1

			if dress_fragment_info then
				dress_fragment_id = dress_fragment_info[1]
			end

			self.labelHasNum_.width = 200
			self.labelHasNum_.height = 50
			self.labelHasNum_.gameObject:GetComponent(typeof(UIWidget)).pivot = UIWidget.Pivot.TopLeft

			self.labelHasNum_.gameObject:SetLocalPosition(153, -110, 0)

			if dress_fragment_id and dress_fragment_id > 0 then
				local dress_fragment_num = xyd.models.backpack:getItemNumByID(dress_fragment_id)
				self.labelHasNum_.text = __("DRESS_ITEM_NUM") .. " " .. dress_fragment_num
			else
				self.labelHasNum_.text = __("DRESS_ITEM_NUM") .. " 0"
			end
		else
			num = xyd.models.backpack:getItemNumByID(self.itemID)

			if self.itemID == xyd.ItemID.ENTRANCE_TEST_TICKET and self.itemNum and num == 0 then
				num = self.itemNum
			end

			self.labelHasNum_.text = __("ITEM_HAS_NUM", xyd.getRoughDisplayNumber(num))

			self.labelHasNum_:SetActive(true)
		end

		if self.itemID == xyd.ItemID.CRYSTAL then
			self.labelHasNum_.text = __("ITEM_HAS_NUM", num)
		elseif self.type_ ~= xyd.ItemType.DRESS then
			self.labelHasNum_.text = __("ITEM_HAS_NUM", xyd.getRoughDisplayNumber(num))
		end

		self.labelHasNum_:SetActive(true)

		if xyd.tables.itemTable:getType(self.itemID) == xyd.ItemType.HERO_RANDOM_DEBRIS and self.wndType_ == xyd.ItemTipsWndType.BACKPACK then
			self.labelHasNum_:SetActive(false)
		end
	end

	self:initIcon()
	self:initDesc()
	self:initButton()
	self:setMultilingualText()
	self:changeMainSize()

	if self.data.showGetWays then
		self:showWaysNoAction()
	end

	if self.wndType_ == xyd.ItemTipsWndType.DRESS_COLLECTION then
		self:showCollectionGroup()

		UIEventListener.Get(self.btnDressSuit_.gameObject).onClick = handler(self, function ()
			local office_id = xyd.tables.senpaiDressItemTable:getGroup(self.itemID)

			xyd.WindowManager.get():openWindow("dress_check_office_window", {
				showALL = true,
				office_id = office_id,
				closeCallBack = function ()
					xyd.WindowManager.get():openWindow("item_tips_window", self.params)
				end
			})
			xyd.closeWindow("item_tips_window")
		end)

		self.btnDressSuit_:SetActive(true)
	end
end

function ItemTips:checkShowHasNum(type)
	if type == 12 and self:checkNewSkin() then
		return false
	end

	local not_show_list = {
		2,
		6,
		7,
		8,
		9,
		10,
		11,
		13,
		16,
		18,
		19,
		20,
		21
	}
	local not_show_ids = {
		195
	}

	for _, value in ipairs(not_show_list) do
		if value == type then
			return false
		end
	end

	for _, value in ipairs(not_show_ids) do
		if value == self.itemID then
			return false
		end
	end

	return true
end

function ItemTips:initIcon()
	local params = {
		noClick = true,
		uiRoot = self.groupIcon_.gameObject,
		itemID = self.itemID,
		hideText = self.hideText
	}
	local icon = xyd.getItemIcon(params)

	if self.data.equipedOn then
		local icon2 = HeroIcon.new(self.groupIcon2_.gameObject)

		icon2:setInfo(self.data.equipedOn)
		self.groupIcon2_:SetActive(true)
		icon2:setScaleAsParent()
	end

	if self.data.upArrowCallback then
		self.upArrow_:SetActive(true)
		self.groupIcon2_:SetActive(false)
		xyd.setDarkenBtnBehavior(self.upArrow_.gameObject, self, self.data.upArrowCallback)
	end

	icon:setScaleAsParent()
end

function ItemTips:initButton()
	self.labelMid.text = __("ITEM_SELL")
	self.labelLeft.text = __("ITEM_DETAIL")
	self.labelRight.text = __("ITEM_SUMMON")

	if self.wndType_ == xyd.ItemTipsWndType.NORMAL then
		self:initNormalBtn()
	elseif self.wndType_ == xyd.ItemTipsWndType.BACKPACK then
		self:initBackpackBtn()
	elseif self.wndType_ == xyd.ItemTipsWndType.SMITHY then
		self:initSmithyBtn()
	elseif self.wndType_ == xyd.ItemTipsWndType.DATES then
		self:initDatesBtn()
	elseif self.wndType_ == xyd.ItemTipsWndType.ACTIVITY then
		self:initActivityBtn()
	elseif self.wndType_ == xyd.ItemTipsWndType.OPTIONAL_CHEST then
		self:initOptionalChestBtn()
	elseif self.wndType_ == xyd.ItemTipsWndType.CAMPAIGN_HANG then
		self:initCampaignHangBtn()
	end

	if xyd.getWindow("item_tips_window") and xyd.getWindow("drop_probability_window") and not self.wndType_ == xyd.ItemTipsWndType.OPTIONAL_CHEST then
		self.btnBox_:SetActive(false)

		self.btnLayoutIndex_ = 0
	end

	self:btnLayout()
end

function ItemTips:initCampaignHangBtn()
	if self.type_ == xyd.ItemType.HERO_DEBRIS or self.type_ == xyd.ItemType.HERO then
		self.labelMid.text = __("ITEM_DETAIL")
		self.btnLayoutIndex_ = BtnLayoutType.MID
		self.btnCallback[BtnType.BOT_MID + 1] = self.detailTouch
	elseif self.type_ == xyd.ItemType.SKIN then
		self.labelMid.text = __("ITEM_DETAIL")
		self.btnLayoutIndex_ = BtnLayoutType.MID
		self.btnCallback[BtnType.BOT_MID + 1] = self.skinDetailTouch
	elseif self.type_ == xyd.ItemType.DATES_RING then
		self.labelMid.text = __("VIEW_DATES_SKIN")
		self.btnLayoutIndex_ = BtnLayoutType.MID
		self.btnBotMid_:GetComponent(typeof(UISprite)).width = 270
		self.btnCallback[BtnType.BOT_MID + 1] = handler(self, function ()
			xyd.WindowManager.get():openWindow("view_dates_skin_window")
			xyd.WindowManager.get():closeWindow("item_tips_window")
		end)
	elseif self.type_ == xyd.ItemType.OPTIONAL_TREASURE_CHEST or self.type_ == xyd.ItemType.HERO_RANDOM_DEBRIS or self.type_ == xyd.ItemType.ARTIFACT_DEBRIS or self.type_ == xyd.ItemType.DRESS_DEBRIS then
		self.btnBox_:SetActive(true)
	end

	if self.data.activityTag and self.data.activityTag > 0 then
		self.btnLayoutIndex_ = BtnLayoutType.MID
		self.labelMid.text = self.type_ == xyd.ItemType.BOX and __("BACKPACK_TIP_GO_USE") or __("GO")

		self.btnCallback[BtnType.BOT_MID + 1] = function ()
			local GetWayTable = xyd.tables.getWayTable
			local getWayID = ItemTable:goWindow(self.itemID)
			local windows = GetWayTable:getGoWindow(getWayID)
			local hasWay = false
			local actId = nil

			for i = 1, #windows do
				local windowName = windows[i]
				local params = GetWayTable:getGoParam(getWayID)

				if windowName == "activity_window" then
					local activityData = xyd.models.activity:getActivity(params[i].select)

					if activityData then
						hasWay = true
						actId = params[i].select

						break
					end
				end
			end

			if hasWay then
				xyd.WindowManager.get():closeWindow("item_tips_window")
				xyd.WindowManager.get():closeWindow("campaign_stage_detail_window")
				xyd.WindowManager.get():closeWindow("campaign_hang_item_window")
				xyd.WindowManager.get():openWindow("activity_window", {
					select = actId
				})
			else
				xyd.alertTips(__("ACTIVITY_END_YET"))
			end
		end
	end
end

function ItemTips:initOptionalChestBtn()
	local ways = xyd.tables.itemTable:getWays(self.itemID)

	if #ways > 0 then
		self.btnTop_:SetActive(true)

		self.btnCallback[BtnType.TOP + 1] = self.getWayTouch
	else
		self.btnTop_:SetActive(false)
	end

	if self.type_ == xyd.ItemType.SKIN then
		self.labelMid.text = __("ITEM_DETAIL")
		self.btnLayoutIndex_ = BtnLayoutType.MID
		self.data.midColor = xyd.ButtonBgColorType.blue_btn_65_65

		if not self:checkNewSkin() then
			self.btnCallback[BtnType.BOT_MID + 1] = self.skinDetailTouch
		end
	else
		self.btnLayoutIndex_ = 0
	end
end

function ItemTips:initDatesBtn()
	if self.type_ == xyd.ItemType.DATES_GIFT then
		self.labelMid.text = __("DATES_GIFTES_TIP01")
		self.btnCallback[BtnType.BOT_MID + 1] = self.datesGiftsTouch
		self.btnLayoutIndex_ = BtnLayoutType.MID
	end
end

function ItemTips:initNormalBtn()
	if self.type_ == xyd.ItemType.HERO_DEBRIS or self.type_ == xyd.ItemType.HERO then
		self.labelMid.text = __("ITEM_DETAIL")
		self.btnLayoutIndex_ = BtnLayoutType.MID
		self.btnCallback[BtnType.BOT_MID + 1] = self.detailTouch
	elseif self.type_ == xyd.ItemType.SKIN then
		self.labelMid.text = __("ITEM_DETAIL")
		self.btnLayoutIndex_ = BtnLayoutType.MID
		self.btnCallback[BtnType.BOT_MID + 1] = self.skinDetailTouch
	elseif self.type_ == xyd.ItemType.DATES_RING then
		self.labelMid.text = __("VIEW_DATES_SKIN")
		self.btnLayoutIndex_ = BtnLayoutType.MID
		self.btnBotMid_:GetComponent(typeof(UISprite)).width = 270
		self.btnCallback[BtnType.BOT_MID + 1] = handler(self, function ()
			xyd.WindowManager.get():openWindow("view_dates_skin_window")
			xyd.WindowManager.get():closeWindow("item_tips_window")
		end)
	elseif self.type_ == xyd.ItemType.OPTIONAL_TREASURE_CHEST or self.type_ == xyd.ItemType.HERO_RANDOM_DEBRIS or self.type_ == xyd.ItemType.ARTIFACT_DEBRIS or self.type_ == xyd.ItemType.DRESS_DEBRIS then
		self.btnBox_:SetActive(true)
	elseif self.type_ == xyd.ItemType.CHIME_DEBRIS then
		self.labelMid.text = __("ITEM_DETAIL")
		self.btnLayoutIndex_ = BtnLayoutType.MID
		self.btnCallback[BtnType.BOT_MID + 1] = self.chimeDetailTouch
	end

	if self.resetBtn and self.data.resetCallBack then
		self.resetBtn.gameObject:SetActive(true)
	end

	local box_id = xyd.tables.itemTable:getDropBoxShow(self.itemID)

	if box_id ~= nil and box_id ~= 0 or self.type_ == xyd.ItemType.OPTIONAL_TREASURE_CHEST or xyd.tables.itemTable:checkJobBoxID(self.itemID) then
		self.btnBox_:SetActive(true)
	else
		self.btnBox_:SetActive(false)
	end
end

function ItemTips:initActivityBtn()
	local ways = ItemTable:getWays(self.itemID)

	if self.itemID == 195 then
		self.labelMid.text = __("GO")
		self.btnLayoutIndex_ = BtnLayoutType.MID
		self.btnBotMid_:GetComponent(typeof(UISprite)).width = 270
		self.btnCallback[BtnType.BOT_MID + 1] = handler(self, function ()
			xyd.WindowManager.get():closeWindow("activity_window")
			xyd.WindowManager.get():closeWindow("item_tips_window")
			xyd.WindowManager.get():openWindow("activity_window", {
				select = 56,
				activity_type = 7,
				activity_ids = {
					169,
					171,
					86,
					36,
					56
				}
			})
		end)

		return
	elseif self.itemID == 252 then
		self.labelMid.text = __("GO")
		self.btnLayoutIndex_ = BtnLayoutType.MID
		self.btnBotMid_:GetComponent(typeof(UISprite)).width = 270
		self.btnCallback[BtnType.BOT_MID + 1] = handler(self, function ()
			xyd.WindowManager.get():closeWindow("activity_window")
			xyd.WindowManager.get():closeWindow("item_tips_window")
			xyd.WindowManager.get():openWindow("activity_window", {
				activity_type2 = 1,
				select = 56
			})
		end)

		return
	end

	local btnLayout_ = BtnLayoutType.NONE

	print("self.type_   ", self.type_)
	print("self.itemID  ", self.itemID)

	if #ways > 0 and not self.notShowGetWayBtn then
		self.btnTop_:SetActive(true)

		self.btnCallback[BtnType.TOP + 1] = self.getWayTouch
		btnLayout_ = BtnLayoutType.TOP
	else
		self.btnTop_:SetActive(false)
	end

	if self.type_ == xyd.ItemType.SKIN then
		self.labelLeft.text = __("ITEM_DETAIL")
		self.labelRight.text = __("FORMATION_TRY_FIGHT")
		self.btnLayoutIndex_ = BtnLayoutType.LEFT_RIGHT
		self.data.rightColor = xyd.ButtonBgColorType.blue_btn_65_65
		self.data.leftColor = xyd.ButtonBgColorType.blue_btn_65_65

		if not self:checkNewSkin() then
			self.btnCallback[BtnType.BOT_LEFT + 1] = self.skinDetailTouch

			self.btnCallback[BtnType.BOT_RIGHT + 1] = function ()
				local battleId1 = xyd.tables.skinShowStageTable:getBattleId1(self.itemID)
				local battleId2 = xyd.tables.skinShowStageTable:getBattleId2(self.itemID)

				xyd.BattleController.get():frontBattleBy2BattleId(battleId1, battleId2, xyd.BattleType.SKIN_PLAY, 1)
			end
		end
	elseif self.type_ == xyd.ItemType.OPTIONAL_TREASURE_CHEST or self.type_ == xyd.ItemType.HERO_RANDOM_DEBRIS or self.type_ == xyd.ItemType.ARTIFACT_DEBRIS or self.type_ == xyd.ItemType.DRESS_DEBRIS or self.type_ == xyd.ItemType.BOX then
		local box_id = xyd.tables.itemTable:getDropBoxShow(self.itemID)

		if box_id and box_id ~= 0 or self.type_ == xyd.ItemType.OPTIONAL_TREASURE_CHEST or xyd.tables.itemTable:checkJobBoxID(self.itemID) then
			self.btnBox_:SetActive(true)
		else
			self.btnBox_:SetActive(false)

			if self.type_ == xyd.ItemType.HERO_RANDOM_DEBRIS and xyd.tables.itemTable:getGroup(self.itemID) == xyd.PartnerGroup.TIANYI then
				self.btnBox_:SetActive(true)
			end
		end
	end
end

function ItemTips:initBackpackBtn()
	local ways = ItemTable:getWays(self.itemID)
	local btnLayout_ = BtnLayoutType.NONE

	if #ways > 0 and not self.notShowGetWayBtn then
		self.btnTop_:SetActive(true)

		self.btnCallback[BtnType.TOP + 1] = self.getWayTouch
		btnLayout_ = BtnLayoutType.TOP
	else
		self.btnTop_:SetActive(false)
	end

	local box_id = xyd.tables.itemTable:getDropBoxShow(self.itemID)

	if box_id ~= nil and box_id ~= 0 or self.type_ == xyd.ItemType.OPTIONAL_TREASURE_CHEST or xyd.tables.itemTable:checkJobBoxID(self.itemID) then
		self.btnBox_:SetActive(true)
	else
		self.btnBox_:SetActive(false)

		if self.type_ == xyd.ItemType.HERO_RANDOM_DEBRIS and xyd.tables.itemTable:getGroup(self.itemID) == xyd.PartnerGroup.TIANYI then
			self.btnBox_:SetActive(true)
		end
	end

	local canSummon_ = self:canSummon()

	if self.type_ == xyd.ItemType.HERO_DEBRIS or self.type_ == xyd.ItemType.HERO_RANDOM_DEBRIS then
		local partnerCost = ItemTable:partnerCost(self.itemID)

		if partnerCost[1] == 0 then
			if canSummon_ then
				self.btnCallback[BtnType.BOT_MID + 1] = self.summonTouch
				btnLayout_ = #ways > 0 and BtnLayoutType.MID_TOP or BtnLayoutType.MID
				self.labelMid.text = __("ITEM_SUMMON")
			end
		else
			if not canSummon_ then
				self.labelRight.text = __("ITEM_SELL")
				self.data.rightColor = xyd.ButtonBgColorType.red_btn_65_65
				self.btnCallback[BtnType.BOT_RIGHT + 1] = self.sellTouch
			else
				self.btnCallback[BtnType.BOT_RIGHT + 1] = self.summonTouch
				self.data.rightColor = xyd.ButtonBgColorType.blue_btn_65_65
			end

			self.btnCallback[BtnType.BOT_LEFT + 1] = self.detailTouch
			btnLayout_ = #ways > 0 and BtnLayoutType.LEFT_RIGHT_TOP or BtnLayoutType.LEFT_RIGHT
		end
	elseif self.type_ == xyd.ItemType.ARTIFACT_DEBRIS or self.type_ == xyd.ItemType.DRESS_DEBRIS then
		if canSummon_ then
			self.labelMid.text = __("ITEM_SUMMON")
			self.btnCallback[BtnType.BOT_MID + 1] = self.summonTouch
			btnLayout_ = #ways > 0 and BtnLayoutType.MID_TOP or BtnLayoutType.MID
		end
	elseif self.type_ == xyd.ItemType.BOX or self.type_ == xyd.ItemType.CONSUMABLE_HANGUP then
		self.btnCallback[BtnType.BOT_MID + 1] = self.useTouch
		self.labelMid.text = __("USE")
		btnLayout_ = #ways > 0 and BtnLayoutType.MID_TOP or BtnLayoutType.MID
	elseif self.type_ == xyd.ItemType.DATES_GIFT then
		self.labelMid.text = __("DATES_GIFTS_TEXT02")
		btnLayout_ = BtnLayoutType.MID
		self.btnCallback[BtnType.BOT_MID + 1] = self.giftsTouch
	elseif self.type_ == xyd.ItemType.DATES_RING then
		self.labelMid.text = __("VIEW_DATES_SKIN")
		btnLayout_ = BtnLayoutType.MID
		self.btnBotMid_:GetComponent(typeof(UISprite)).width = 270
		self.btnCallback[BtnType.BOT_MID + 1] = handler(self, function ()
			xyd.WindowManager.get():openWindow("view_dates_skin_window")
			xyd.WindowManager.get():closeWindow("item_tips_window")
		end)
	elseif self.type_ == xyd.ItemType.OPTIONAL_TREASURE_CHEST then
		self.btnCallback[BtnType.BOT_MID + 1] = self.treasureTouch
		self.labelMid.text = __("USE")
		btnLayout_ = #ways > 0 and BtnLayoutType.MID_TOP or BtnLayoutType.MID
	else
		local canSell = ItemTable:isSell(self.itemID)

		if canSell then
			self.btnCallback[BtnType.BOT_MID + 1] = self.sellTouch
			self.data.midColor = xyd.ButtonBgColorType.red_btn_65_65
			btnLayout_ = #ways > 0 and BtnLayoutType.MID_TOP or BtnLayoutType.MID
		end
	end

	local GetWayTable = xyd.tables.getWayTable
	local getWayID = ItemTable:goWindow(self.itemID)
	local windowQueue = xyd.WindowManager.get().windowMainQueue_

	if getWayID and getWayID ~= 0 and windowQueue[#windowQueue].name_ == "backpack_window" and self.type_ ~= xyd.ItemType.BOX then
		local windows = GetWayTable:getGoWindow(getWayID)

		local function goFunc()
			if self:checkSpecilGetWayNotShow(getWayID) then
				return
			end

			local serverId = xyd.models.selfPlayer:getServerID()

			if serverId > 2 and (self.itemID == xyd.ItemID.STARRY_ALTAR_COIN or self.itemID == xyd.ItemID.STAR_ALTER_MISSION_COIN or self.itemID == xyd.ItemID.SKILL_RESONATE_LIGHT_STONE or self.itemID == xyd.ItemID.SKILL_RESONATE_DARK_STONE) then
				local openTime = tonumber(xyd.tables.miscTable:getVal("starry_altar_open_time"))
				local nowTime = xyd.getServerTime()

				if nowTime < openTime then
					local leftTime = xyd.getRoughDisplayTime(openTime - nowTime)

					xyd.alertTips(__("OPEN_AFTER_TIME", leftTime))

					return
				end
			end

			xyd.goWay(getWayID, function ()
				local windows = GetWayTable:getGoWindow(getWayID)

				for i = 1, #windows do
					local windowName = windows[i]

					if windowName == "summon_window" or windowName == "partner_detail_window" then
						xyd.closeWindow("backpack_window")
					end
				end
			end, function ()
				xyd.closeWindow("item_tips_window")
			end)
		end

		local hasWay = true

		for i = 1, #windows do
			local windowName = windows[i]
			local params = GetWayTable:getGoParam(getWayID)

			if windowName == "activity_window" then
				local activityData = xyd.models.activity:getActivity(params[i].select)

				if not activityData then
					hasWay = false

					break
				end
			elseif windowName == "dress_summon_window" then
				local activityData = xyd.models.activity:getActivity(params[i].select)

				if not activityData then
					hasWay = false

					break
				end
			end
		end

		if hasWay then
			if btnLayout_ == BtnLayoutType.NONE or btnLayout_ == BtnLayoutType.TOP then
				self.labelMid.text = __("BACKPACK_TIP_GO_USE")
				btnLayout_ = #ways > 0 and BtnLayoutType.MID_TOP or BtnLayoutType.MID
				self.data.midColor = xyd.ButtonBgColorType.blue_btn_65_65
				self.btnCallback[BtnType.BOT_MID + 1] = goFunc
			elseif btnLayout_ == BtnLayoutType.MID or btnLayout_ == BtnLayoutType.MID_TOP then
				self.labelRight.text = __("BACKPACK_TIP_GO_USE")
				btnLayout_ = #ways > 0 and BtnLayoutType.LEFT_RIGHT_TOP or BtnLayoutType.LEFT_RIGHT
				self.btnCallback[BtnType.BOT_RIGHT + 1] = goFunc
				self.labelLeft.text = self.labelMid.text
				self.data.rightColor = xyd.ButtonBgColorType.blue_btn_65_65
				self.btnCallback[BtnType.BOT_LEFT] = self.btnCallback[BtnType.BOT_MID]
				self.data.leftColor = self.data.midColor
			end
		end
	end

	self.btnLayoutIndex_ = btnLayout_
end

function ItemTips:checkSpecilGetWayNotShow(getWayID)
	if getWayID == 24 then
		local vip = xyd.tables.gambleConfigTable:needVip(2)
		local level = xyd.tables.gambleConfigTable:needLevel(2)[1]

		if Backpack:getVipLev() < vip[1] and Backpack:getLev() < level then
			xyd.alert(xyd.AlertType.TIPS, __("GAMBLE_DOOR_TIPS", level, vip[1]))

			return true
		end
	elseif getWayID == 85 then
		local slot = xyd.models.slot
		local currentSortedPartners_ = slot:getSortedPartners()["1_0"]
		local has10 = false

		for idx, _ in pairs(currentSortedPartners_) do
			local idx_ = currentSortedPartners_[idx]
			local p = slot:getPartner(idx_)

			if p.star >= 10 then
				has10 = true

				break
			end
		end

		if not has10 then
			xyd.showToast(__("NO_10_STAR_HERO"))
		end

		return not has10
	end

	return false
end

function ItemTips:btnLayout()
	local index = self.btnLayoutIndex_
	local changeY = 80
	self.btnCallback[BtnType.BOT_MID + 1] = self.data.midCallback or self.btnCallback[BtnType.BOT_MID + 1]
	self.btnCallback[BtnType.TOP + 1] = self.data.topCallback or self.btnCallback[BtnType.TOP + 1]
	self.btnCallback[BtnType.BOT_RIGHT + 1] = self.data.rightCallback or self.btnCallback[BtnType.BOT_RIGHT + 1]
	self.btnCallback[BtnType.BOT_LEFT + 1] = self.data.leftCallback or self.btnCallback[BtnType.BOT_LEFT + 1]
	self.labelMid.text = self.data.midLabel or self.labelMid.text
	self.labelLeft.text = self.data.leftLabel or self.labelLeft.text
	self.labelRight.text = self.data.rightLabel or self.labelRight.text

	xyd.setBgColorType(self.btnBotMid_, self.data.midColor or xyd.ButtonBgColorType.blue_btn_65_65)
	xyd.setBgColorType(self.btnBotLeft_, self.data.leftColor or xyd.ButtonBgColorType.white_btn_65_65)
	xyd.setBgColorType(self.btnBotRight_, self.data.rightColor or xyd.ButtonBgColorType.white_btn_65_65)

	if index == 1 then
		self.btnBotMid_:SetActive(true)
	elseif index == 2 then
		self.btnTop_:SetActive(true)

		changeY = 0
	elseif index == 3 then
		self.btnTop_:SetActive(true)
		self.btnBotMid_:SetActive(true)
	elseif index == 4 then
		self.btnBotLeft_:SetActive(true)
		self.btnBotRight_:SetActive(true)
	elseif index == 5 then
		self.btnTop_:SetActive(true)
		self.btnBotLeft_:SetActive(true)
		self.btnBotRight_:SetActive(true)
	else
		changeY = 0
	end

	self.changeY = self.changeY + changeY

	if (self.itemID == xyd.ItemID.LOVE_LETTER or self.itemID == xyd.ItemID.LOVE_LETTER2) and xyd.models.activity:getActivity(xyd.ActivityID.CANDY_COLLECT) == nil then
		self.btnTop_:SetActive(false)
	end

	if self.type_ == xyd.ItemType.SKIN and self:checkNewSkin() then
		local function tipFunc()
			xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_YEAR_FUND_NOTICE_TEXT02"))
		end

		self.btnCallback[BtnType.BOT_LEFT + 1] = tipFunc
		self.btnCallback[BtnType.BOT_RIGHT + 1] = tipFunc

		xyd.applyChildrenGrey(self.btnBotLeft_)
		xyd.applyChildrenGrey(self.btnBotRight_)
	end

	if xyd.tables.itemTable:getType(self.itemID) == xyd.ItemType.ARTIFACT and self.wndType_ == xyd.ItemTipsWndType.BACKPACK then
		local skinDes = xyd.tables.equipTextTable:getSkinDesc(self.itemID)

		if skinDes and tostring(skinDes) and #tostring(skinDes) > 0 then
			self.btnDesc_:SetActive(true)
		else
			self.btnDesc_:SetActive(false)
		end

		local next_itemID = xyd.tables.equipTable:getArtifactUpNext(self.itemID)

		if self.btnArtifactUp_ and next_itemID and next_itemID > 0 then
			self.btnArtifactUp_.gameObject:SetActive(true)
		end
	else
		self.btnDesc_:SetActive(false)
	end
end

function ItemTips:checkNewSkin()
	return false
end

function ItemTips:initSmithyBtn()
	self.labelMid.text = __("ITEM_WAYS")
	self.btnCallback[BtnType.BOT_MID + 1] = self.getWayTouch
	self.btnLayoutIndex_ = BtnLayoutType.MID
end

function ItemTips:canSummon()
	local partnerCost = ItemTable:partnerCost(self.itemID)

	if ItemTable:getType(self.itemID) == xyd.ItemType.ARTIFACT_DEBRIS then
		partnerCost = ItemTable:treasureCost(self.itemID)
	end

	if ItemTable:getType(self.itemID) == xyd.ItemType.DRESS_DEBRIS then
		local dress_summon_id = xyd.tables.itemTable:getSummonID(self.itemID)
		partnerCost = xyd.tables.summonDressTable:getCost(dress_summon_id)
	end

	if self.showBagType_ and partnerCost and partnerCost[2] and self.itemNum and (self.showBagType_ == xyd.BackpackShowType.DEBRIS or self.showBagType_ == xyd.BackpackShowType.CONSUMABLES) and partnerCost[2] <= self.itemNum then
		return true
	end

	return false
end

function ItemTips:getDesc()
	local desc = ""
	local color = nil

	if self.showBagType_ == xyd.BackpackShowType.EQUIP or self.showBagType_ == xyd.BackpackShowType.ARTIFACT or ItemTable:getType(self.itemID) == xyd.ItemType.CRYSTAL or self.showBagType_ == xyd.BackpackShowType.SKIN then
		desc = EquipTable:getDesc(self.itemID)
		color = 960513791
	else
		desc = ItemTable:getDesc(self.itemID)
		color = 1549556991
	end

	if ItemTable:getType(self.itemID) == xyd.ItemType.CONSUMABLE_HANGUP then
		local mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
		local max_stage = mapInfo.max_stage

		if not max_stage or max_stage < 1 then
			max_stage = 1
		end

		local goldData = xyd.split(xyd.tables.stageTable:getGold(max_stage), "#")
		local expData = xyd.split(xyd.tables.stageTable:getExpPartner(max_stage), "#")
		local num = 0

		if self.itemID == xyd.ItemID.GOLD_BAG_24 then
			num = goldData[2] * 24 * 60 * 12
		elseif self.itemID == xyd.ItemID.GOLD_BAG_8 then
			num = goldData[2] * 8 * 60 * 12
		elseif self.itemID == xyd.ItemID.EXP_BAG_24 then
			num = expData[2] * 24 * 60 * 12
		elseif self.itemID == xyd.ItemID.EXP_BAG_8 then
			num = expData[2] * 8 * 60 * 12
		end

		local descNum = xyd.getRoughDisplayNumber(num)
		desc = desc .. descNum
	end

	return {
		text = desc,
		color = color
	}
end

function ItemTips:initDesc()
	local data = self:getDesc()

	if data.text ~= "" then
		local label = xyd.getLabel({
			w = 420,
			s = 22,
			uiRoot = self.groupDesc_,
			c = data.color,
			t = data.text
		})
		label.spacingY = 5

		table.insert(self.descs_, label)
	end

	if self.showBagType_ == xyd.BackpackShowType.EQUIP then
		self:showEquipDesc()
	elseif self.showBagType_ == xyd.BackpackShowType.SKIN then
		self:showSkinDesc()
	end

	if ItemTable:getType(self.itemID) == xyd.ItemType.DRESS then
		self:showDressDesc()
	end

	self:showArtifactDesc()

	local canSell = ItemTable:isSell(self.itemID)

	if self.wndType_ == xyd.ItemTipsWndType.BACKPACK and not canSell and self:canSummon() == false then
		local label = xyd.getLabel({
			c = 4278190335.0,
			s = 22,
			uiRoot = self.groupDesc_,
			t = __("NOT_SELL")
		})
		local tmpType = ItemTable:getType(self.itemID)

		if xyd.ItemType.WEAPON <= tmpType and tmpType <= xyd.ItemType.SHOES then
			label.height = 27

			label:SetBottomAnchor(self.groupDesc_, 0, 16)
		end

		table.insert(self.descs_, label)
	end

	local offY = 8
	local i = 0

	while i < #self.descs_ do
		local label = self.descs_[i + 1]

		if label.text == __("NOT_SELL") then
			label.color = Color.New2(4278190335.0)
		end

		if i == 0 then
			label.height = label.height + 8
		end

		label.pivot = UIWidget.Pivot.TopLeft

		label:SetLocalPosition(0, -offY, 0)

		offY = offY + label.height + 13
		i = i + 1
	end

	if self.is_spare_crystal and ItemTable:getType(self.itemID) == xyd.ItemType.CRYSTAL then
		local label = xyd.getLabel({
			c = 1583978239,
			s = 22,
			uiRoot = self.groupDesc_,
			t = __("TREASURE_RESERVE_NUM")
		})

		label:SetLocalPosition(225, -offY - 25, 0)
		table.insert(self.descs_, label)

		offY = offY + label.height + 30
	end

	self.descOffY = offY
	self.groupDescName_.text = __("ARTIFACT_STORY")
	self.groupDescLabel_.text = xyd.tables.equipTextTable:getSkinDesc(self.itemID)
end

function ItemTips:showEquipDesc()
	local count = 1
	local suits = {}
	local i = 1

	while i <= 3 do
		local suit = EquipTable:getSuit(self.itemID, i)

		if #suit <= 0 then
			break
		end

		count = count + 1
		local text = DBuffTable:translationDesc(suit)
		local label = xyd.getLabel({
			c = 2593823487.0,
			w = 420,
			s = 22,
			uiRoot = self.groupDesc_,
			t = text
		})

		table.insert(suits, label)

		i = i + 1
	end

	if count > 1 then
		local suitName = EquipTable:getSuitName(self.itemID)

		if self.data.equipedPartner then
			local partner = self.data.equipedPartner
			local equips = partner:getEquipment()
			local formCount = 0
			local formEquips = EquipTable:getForm(self.itemID)
			local i = 1

			while i <= #equips do
				local j = 1

				while j <= #formEquips do
					if equips[i] ~= self.itemID and equips[i] == tonumber(formEquips[j]) then
						formCount = formCount + 1
					end

					j = j + 1
				end

				i = i + 1
			end

			local label = xyd.getLabel({
				c = 3613720831.0,
				s = 22,
				uiRoot = self.groupDesc_,
				t = tostring(suitName) .. "(" .. tostring(formCount + 1) .. "/" .. tostring(count) .. ")"
			})

			table.insert(self.descs_, label)

			local i = 0

			while i < #suits do
				if i < formCount then
					suits[i + 1].color = Color.New2(11665663)
				end

				table.insert(self.descs_, suits[i + 1])

				i = i + 1
			end
		else
			local label = xyd.getLabel({
				c = 3613720831.0,
				s = 22,
				uiRoot = self.groupDesc_,
				t = tostring(suitName) .. "(" .. tostring(count) .. ")"
			})

			table.insert(self.descs_, label)

			local i = 0

			while i < #suits do
				table.insert(self.descs_, suits[i + 1])

				i = i + 1
			end
		end
	end
end

function ItemTips:showArtifactDesc()
	local group = EquipTable:getGroup(self.itemID)
	local job = EquipTable:getJob(self.itemID)
	local exSkill = EquipTable:exSkillId(self.itemID)[1]

	if group and group > 0 or job and job > 0 then
		local isGroup = group and group > 0
		local limitStr = nil

		if isGroup then
			limitStr = isGroup and GroupTable:getName(group)
		else
			limitStr = JobTable:getName(job)
		end

		local text = __("ARTIFACT_ATTR_LIMIT", limitStr)
		local label = xyd.getLabel({
			c = 2593823487.0,
			w = 432,
			s = 22,
			uiRoot = self.groupDesc_,
			t = text
		})

		table.insert(self.descs_, label)

		local acts = EquipTable:getAct(self.itemID)

		for k, act in ipairs(acts) do
			local text1 = DBuffTable:translationDesc(act)
			local label1 = xyd.getLabel({
				c = 2593823487.0,
				w = 432,
				s = 22,
				uiRoot = self.groupDesc_,
				t = text1
			})

			if self.data.equipedPartner then
				local partner = self.data.equipedPartner
				local p_group = partner:getGroup()
				local p_job = partner:getJob()
				local isFit = isGroup and function ()
					return group == p_group
				end or function ()
					return job == p_job
				end()

				if isFit then
					label1.color = Color.New2(11665663)
					label.color = Color.New2(3613720831.0)
				end
			end

			table.insert(self.descs_, label1)
		end

		local suitName = EquipTable:getSuitName(self.itemID)

		if #suitName > 0 then
			local formEquips = EquipTable:getForm(self.itemID)
			local text3 = suitName .. "(" .. #formEquips .. ")"
			local formCount = 0

			if self.data.equipedPartner then
				local partner = self.data.equipedPartner
				local equips = partner:getEquipment()

				for i = 1, #formEquips do
					for j = 1, #equips do
						if equips[j] == tonumber(formEquips[i]) then
							formCount = formCount + 1

							break
						end
					end
				end

				text3 = suitName .. "(" .. formCount .. "/" .. #formEquips .. ")"
			end

			local label3 = xyd.getLabel({
				s = 22,
				c = 3613720831.0,
				uiRoot = self.groupDesc_,
				t = text3
			})
			label3.overflowMethod = UILabel.Overflow.ResizeFreely

			label3:ProcessText()
			table.insert(self.descs_, label3)

			local check_button = NGUITools.AddChild(label3.gameObject, "check_button")
			local sprite = check_button:AddComponent(typeof(UISprite))
			local boxCollider = check_button:AddComponent(typeof(UnityEngine.BoxCollider))
			boxCollider.size = Vector3(40, 40, 0)
			sprite.width = 40
			sprite.height = 40
			sprite.depth = label3.depth

			sprite:X(label3.width + 25)
			sprite:Y(-11)

			local text2, label2 = nil
			local suitSkills = EquipTable:getSuitSkills(self.itemID)
			local skillIndex = 1

			if not self.data.equipedPartner then
				text2 = __("EQUIP_LEVELUP_TEXT_9")
				label2 = xyd.getLabel({
					c = 2593823487.0,
					w = 432,
					s = 22,
					uiRoot = self.groupDesc_,
					t = text2
				})

				xyd.setUISpriteAsync(sprite, nil, "check_white_btn")
			else
				if self.data.equipedPartner:getSkillIndex() > 0 then
					skillIndex = self.data.equipedPartner:getSkillIndex()
				end

				text2 = xyd.tables.skillTable:getDesc(suitSkills[skillIndex])
				label2 = xyd.getLabel({
					c = 960513791,
					w = 432,
					s = 22,
					uiRoot = self.groupDesc_,
					t = text2
				})

				xyd.setUISpriteAsync(sprite, nil, "switch_btn")

				local partner = self.data.equipedPartner
				local p_job = partner:getJob()
				local suitJob = xyd.tables.equipTable:getJob(self.itemID)

				if p_job ~= suitJob then
					xyd.setTouchEnable(check_button)
					xyd.applyGrey(sprite)

					label2.color = Color.New2(2593823487.0)
					label3.color = Color.New2(2593823487.0)
					label2.text = __("EQUIP_LEVELUP_TEXT_9")
				end
			end

			if self.hideBtnCheck then
				check_button:SetActive(false)
			end

			table.insert(self.descs_, label2)

			UIEventListener.Get(check_button).onClick = function ()
				if self.data.levelUp then
					xyd.WindowManager.get():openWindow("suit_skill_preview_window", {
						skill_list = suitSkills,
						levelUp = self.data.levelUp
					})
				elseif self.quickItem_ then
					xyd.WindowManager.get():openWindow("suit_skill_detail_window", {
						partner_id = self.data.equipedPartner and self.data.equipedPartner:getPartnerID(),
						skill_list = suitSkills,
						enough = formCount == 4,
						skillIndex = skillIndex,
						partner = self.data.equipedPartner,
						quickItem = self.quickItem_
					})
				else
					xyd.WindowManager.get():openWindow("suit_skill_detail_window", {
						partner_id = self.data.equipedPartner and self.data.equipedPartner:getPartnerID() or nil,
						skill_list = suitSkills,
						enough = formCount == 4,
						skillIndex = skillIndex,
						fakeSkill = self.data.fakeSkill,
						partner = self.data.fakePartner
					})
				end
			end
		end
	end

	if exSkill and exSkill > 0 then
		local skillName = xyd.tables.skillTextTable:getName(exSkill)
		local skillDesc = xyd.tables.skillTextTable:getDesc(exSkill)
		local labelName = xyd.getLabel({
			c = 1196856575,
			w = 432,
			s = 22,
			uiRoot = self.groupDesc_,
			t = skillName
		})

		table.insert(self.descs_, labelName)

		local labelDesc = xyd.getLabel({
			c = 1196856575,
			w = 432,
			s = 20,
			uiRoot = self.groupDesc_,
			t = skillDesc
		})

		table.insert(self.descs_, labelDesc)
	end
end

function ItemTips:showSkinDesc()
	local desc = ItemTable:getDesc(self.itemID)
	local color = 3613720831.0
	local label = xyd.getLabel({
		w = 432,
		s = 22,
		uiRoot = self.groupDesc_,
		t = desc,
		c = color
	})

	table.insert(self.descs_, label)
end

function ItemTips:showDressDesc()
	for i = 1, 3 do
		local attr = xyd.tables.senpaiDressItemTable["getBase" .. i](xyd.tables.senpaiDressItemTable, self.itemID)

		if attr and attr ~= 0 then
			local desc = "+" .. attr .. " " .. __("PERSON_DRESS_ATTR_" .. i)
			local color = 960513791
			local label = xyd.getLabel({
				w = 432,
				s = 22,
				uiRoot = self.groupDesc_,
				t = desc,
				c = color
			})

			table.insert(self.descs_, label)
		end
	end

	local after_skillIds = xyd.tables.senpaiDressItemTable:getSkillIds(self.itemID)

	if after_skillIds and #after_skillIds > 0 then
		local desc = xyd.tables.senpaiDressSkillTextTable:getDesc(after_skillIds[#after_skillIds])
		local color = 960513791
		local label = xyd.getLabel({
			w = 432,
			s = 22,
			uiRoot = self.groupDesc_,
			t = desc,
			c = color
		})

		table.insert(self.descs_, label)
	end

	local group_id = xyd.tables.senpaiDressItemTable:getGroup(self.itemID)

	if group_id and group_id ~= 0 then
		local group_item_dress_ids = xyd.tables.senpaiDressGroupTable:getUnit(group_id)
		local group_desc = xyd.tables.senpaiDressGroupTextTable:getName(group_id) .. "(" .. #group_item_dress_ids .. ")"
		local has_num = 0

		for i in pairs(group_item_dress_ids) do
			if #xyd.models.dress:getHasStyles(group_item_dress_ids[i]) > 0 then
				has_num = has_num + 1
			end
		end

		if self.wndType_ == xyd.ItemTipsWndType.DRESS_BACKPACK then
			group_desc = xyd.tables.senpaiDressGroupTextTable:getName(group_id) .. "(" .. has_num .. "/" .. #group_item_dress_ids .. ")"
		end

		local color = 3613720831.0
		local group_label = xyd.getLabel({
			w = 432,
			s = 22,
			uiRoot = self.groupDesc_,
			t = group_desc,
			c = color
		})

		table.insert(self.descs_, group_label)

		local items = xyd.models.dress:getGroupItems(group_id)
		local group_skills = xyd.tables.senpaiDressGroupTable:getSkills(group_id)
		local search_stars = xyd.tables.senpaiDressGroupTable:getUnlockStars(group_id)
		local star = 0
		local index = 1

		if self.wndType_ == xyd.ItemTipsWndType.DRESS_COLLECTION then
			index = #group_skills
		else
			for i in pairs(items) do
				if items[i] ~= 0 then
					star = star + xyd.tables.senpaiDressItemTable:getStar(items[i])
				end
			end

			if search_stars then
				for i, search_star in pairs(search_stars) do
					if search_star <= star then
						index = i
					else
						break
					end
				end
			end
		end

		if search_stars and group_skills and #group_skills > 0 then
			local group_skill_desc = xyd.tables.senpaiDressSkillTextTable:getDesc(group_skills[index])
			local color = 960513791

			if has_num < #group_item_dress_ids then
				color = 2593823487.0
			end

			if self.wndType_ ~= xyd.ItemTipsWndType.DRESS_BACKPACK then
				color = 2593823487.0
			end

			local group_skill_label = xyd.getLabel({
				w = 432,
				s = 22,
				uiRoot = self.groupDesc_,
				t = group_skill_desc,
				c = color
			})

			table.insert(self.descs_, group_skill_label)
		end
	end
end

function ItemTips:changeMainSize()
	local exSkill = EquipTable:exSkillId(self.itemID)
	local showArtifactDesc = false

	if exSkill and exSkill[1] and exSkill[1] > 0 then
		showArtifactDesc = true
	end

	if not self.data.choose_equip or self.type_ ~= xyd.ItemType.ARTIFACT or not showArtifactDesc then
		self.groupMain_.height = self.groupMain_.height + self.changeY + self.descOffY - 13

		self.groupMain_:SetLocalPosition(0, self.groupMain_.height / 2, 0)
	elseif self.data.choose_equip and showArtifactDesc then
		if self.descOffY > 250 then
			self.groupMain_.height = 530 + self.changeY
			self.groupDescWidght_.height = self.descOffY

			self.groupMain_:SetLocalPosition(0, self.groupMain_.height / 2, 0)
			self.descScroll_panel:SetAnchor(self.groupMain_.gameObject, 0, 4, 1, -483, 1, -4, 1, -183)
		elseif self.descOffY > 200 then
			self.groupMain_.height = 480 + self.changeY
			self.groupDescWidght_.height = self.descOffY

			self.groupMain_:SetLocalPosition(0, self.groupMain_.height / 2, 0)
			self.descScroll_panel:SetAnchor(self.groupMain_.gameObject, 0, 4, 1, -433, 1, -4, 1, -183)
		else
			self.groupMain_.height = 430 + self.changeY
			self.groupDescWidght_.height = self.descOffY

			self.groupMain_:SetLocalPosition(0, self.groupMain_.height / 2, 0)
			self.descScroll_panel:SetAnchor(self.groupMain_.gameObject, 0, 4, 1, -383, 1, -4, 1, -183)
		end

		self:waitForFrame(1, function ()
			self.descScroll_:ResetPosition()
		end)
	end
end

function ItemTips:btnBottomTouch()
	if self.isSmithy then
		if self.isShowWays then
			self:hideWays()
		else
			self:showWays()
		end

		self.isShowWays = not self.isShowWays

		return
	end
end

function ItemTips:getWayTouch()
	local ways = {}
	local tips = ""

	if self.wndType_ == xyd.ItemTipsWndType.BACKPACK or self.wndType_ == xyd.ItemTipsWndType.ACTIVITY then
		ways = ItemTable:getWays(self.itemID)
		tips = __("NO_WAY")
	elseif self.wndType_ == xyd.ItemTipsWndType.SMITHY then
		ways = GetWayEquipTable:getStagesByEuqipID(self.itemID, Backpack:getLev())
		tips = __("EQUIP_NO_WAY")
	end

	if #ways <= 0 then
		xyd.alertTips(tips)

		return
	end

	if self.isShowWays then
		self:hideWays()
	else
		self:showWays()
	end

	self.isShowWays = not self.isShowWays
end

function ItemTips:detailTouch()
	local partnerCost = ItemTable:partnerCost(self.itemID)
	local tableID = self.itemID

	if #partnerCost > 0 then
		tableID = partnerCost[1]
	end

	local collection = {
		{
			table_id = tableID
		}
	}
	local params = {
		partners = collection,
		table_id = tableID
	}

	xyd.WindowManager.get():openWindow("guide_detail_window", params, function ()
		xyd.WindowManager.get():closeWindowsOnLayer(6)
	end)
end

function ItemTips:chimeDetailTouch()
	if not xyd.checkFunctionOpen(xyd.FunctionID.SHRINE_HURDLE) then
		return
	end

	if not xyd.models.shrineHurdleModel:checkFuctionOpen() then
		local functionOpenTime = xyd.tables.miscTable:getVal("shrine_time_start")

		if xyd.getServerTime() < tonumber(functionOpenTime) then
			xyd.alertTips(__("DRESS_GACHA_OPEN_TIME", xyd.getRoughDisplayTime(tonumber(functionOpenTime) - xyd.getServerTime())))

			return
		end

		local towerStage = xyd.models.towerMap.stage
		local needTowerStage = tonumber(xyd.tables.miscTable:getVal("shrine_open_limit", "value"))

		if towerStage < needTowerStage + 1 then
			xyd.alertTips(__("OLD_SCHOOL_OPEN_FLOOR", needTowerStage))
		else
			xyd.alertTips(__("OLD_SCHOOL_OPEN_STAR"))
		end

		return
	end

	xyd.WindowManager.get():openWindow("chime_main_window", {})
	xyd.WindowManager.get():closeWindowsOnLayer(6)
	xyd.WindowManager.get():closeWindowsOnLayer(4)
end

function ItemTips:skinDetailTouch()
	local tableIDs = xyd.tables.partnerPictureTable:getSkinPartner(self.itemID)
	local tableID = tableIDs[1]

	if not tableID then
		return
	end

	local params = {
		skin_id = self.itemID,
		closeCallBack = function ()
			local win = xyd.WindowManager.get():getWindow("collection_skin_window")

			if not win:getFromSchoolChoose() then
				xyd.WindowManager.get():closeWindow("collection_skin_window")
			end
		end
	}
	local win = xyd.WindowManager.get():getWindow("item_tips_window")
	local winType = nil

	if win then
		winType = win:getWinType()
	end

	xyd.WindowManager.get():openWindow("collection_skin_window", {
		closeCallBack = function ()
			if self.parent_item_ and tonumber(self.parent_item_) > 0 then
				local params = {
					showGetWays = false,
					notShowGetWayBtn = true,
					itemID = self.parent_item_,
					itemNum = xyd.models.backpack:getItemNumByID(self.parent_item_),
					wndType = winType
				}

				xyd.WindowManager.get():openWindow("item_tips_window", params, function ()
					self:openDropProbabilityWindow({
						isShowProbalitity = false,
						itemId = self.parent_item_
					})
				end)
			end
		end,
		collectionInfo = self.collectionInfo_
	}, function ()
		xyd.WindowManager.get():openWindow("collection_skin_detail_window", params, function ()
			xyd.WindowManager.get():closeWindowsOnLayer(6)
		end)
	end)
end

function ItemTips:sellTouch()
	local canSell = ItemTable:isSell(self.itemID)

	if canSell then
		xyd.WindowManager.get():openWindow("item_sell_window", {
			itemID = self.itemID,
			itemNum = self.itemNum
		})
	else
		xyd.alertTips(__("NOT_SELL"))
	end
end

function ItemTips:useTouch()
	xyd.WindowManager.get():openWindow("item_use_window", {
		itemID = self.itemID,
		itemNum = self.itemNum
	})
end

function ItemTips:treasureTouch()
	xyd.openWindow("award_select_window", {
		itemID = self.itemID,
		itemNum = self.itemNum,
		itemType = xyd.ItemType.OPTIONAL_TREASURE_CHEST
	})
end

function ItemTips:summonTouch()
	local function summonItem(self, itemID, num)
		local summonID = ItemTable:getSummonID(itemID)

		Summon:summonPartner(summonID, num)
	end

	if ItemTable:getType(self.itemID) == nil then
		local treasureCost = ItemTable:treasureCost(self.itemID)

		if treasureCost[1] <= self.itemNum then
			summonItem(_G, self.itemID, 1)
			xyd.WindowManager.get():closeWindow("item_tips_window")
		end
	else
		local type = ItemTable:getType(self.itemID)
		local partnerCost = nil

		if type ~= xyd.ItemType.ARTIFACT_DEBRIS and type ~= xyd.ItemType.DRESS_DEBRIS then
			partnerCost = ItemTable:partnerCost(self.itemID)
		elseif type == xyd.ItemType.DRESS_DEBRIS then
			local dress_summon_id = xyd.tables.itemTable:getSummonID(self.itemID)
			partnerCost = xyd.tables.summonDressTable:getCost(dress_summon_id)
		else
			partnerCost = ItemTable:treasureCost(self.itemID)
		end

		if type == xyd.ItemType.HERO_RANDOM_DEBRIS and xyd.tables.itemTable:getGroup(self.itemID) == xyd.PartnerGroup.TIANYI and math.floor(self.itemNum / partnerCost[2]) >= 1 then
			local sommum_group7_ids = xyd.tables.miscTable:split2num("partner_group7_summon", "value", "|")
			local items = {}

			for i, summon_id in pairs(sommum_group7_ids) do
				local dropbox_id = xyd.tables.summonTable:getDropboxId(summon_id)
				local showAwards = xyd.tables.dropboxShowTable:getIdsByBoxId(dropbox_id)

				if showAwards.list then
					for k, id in pairs(showAwards.list) do
						local item = xyd.tables.dropboxShowTable:getItem(id)

						table.insert(items, {
							itemID = item[1],
							itemNum = item[2],
							summonID = summon_id
						})
					end
				end
			end

			local tempParams = {
				selectMinNum = 1
			}

			function tempParams.sureCallback(itemID, num)
				for i, item in pairs(items) do
					if item.itemID == itemID then
						Summon:summonPartner(item.summonID, num)
						xyd.WindowManager.get():closeWindow("award_select_window")
						xyd.WindowManager.get():closeWindow("item_tips_window")

						break
					end
				end
			end

			tempParams.itemsInfo = items
			tempParams.itemNum = math.floor(self.itemNum / partnerCost[2])

			xyd.WindowManager.get():openWindow("award_select_window", tempParams)

			return true
		end

		if math.floor(self.itemNum / partnerCost[2]) > 1 then
			local params = {
				itemID = self.itemID,
				itemNum = self.itemNum
			}

			xyd.WindowManager.get():openWindow("debris_summon_window", params)

			return true
		else
			if type == xyd.ItemType.ARTIFACT_DEBRIS then
				summonItem(_G, self.itemID, 1)
				xyd.WindowManager.get():closeWindow("item_tips_window")

				return true
			end

			if type == xyd.ItemType.DRESS_DEBRIS then
				local dress_summon_id = xyd.tables.itemTable:getSummonID(self.itemID)

				Summon:reqSummonDress(dress_summon_id, 1)
				xyd.WindowManager.get():closeWindow("item_tips_window")

				return true
			end

			if Slot:getCanSummonNum() > 0 then
				summonItem(_G, self.itemID, 1)
				xyd.WindowManager.get():closeWindow("item_tips_window")
			else
				xyd.openWindow("partner_slot_increase_window")
			end
		end
	end
end

function ItemTips:giftsTouch()
	local params = {
		isBackToBackpack = true,
		item_id = self.itemID
	}

	xyd.WindowManager.get():closeWindow("item_tips_window")
	xyd.WindowManager.get():openWindow("dates_list_window", params)
end

function ItemTips:datesGiftsTouch()
	local wnd = xyd.WindowManager.get():getWindow("dates_window")

	if not wnd then
		return
	end

	if wnd:isMaxLovePoint() then
		xyd.showToast(__("DATES_TEXT19"))

		return
	end

	local num = Backpack:getItemNumByID(self.itemID)
	local params = {
		item_id = self.itemID,
		item_num = num
	}

	xyd.WindowManager.get():openWindow("dates_gifts_send_window", params)
end

function ItemTips:hideWays()
	local mainPos = self.groupMain_.transform.localPosition
	local curY = mainPos.y
	local go = self.groupMain_.gameObject
	local waysGO = self.groupWays_.gameObject
	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Append(waysGO.transform:DOScale(1.05, 0.13))
	sequence:Insert(0.13, waysGO.transform:DOScale(0.5, 0.1))

	local function setter(value)
		self.groupWays_.color = value
	end

	local function getter()
		return self.groupWays_.color
	end

	sequence:Insert(0.13, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.5, 0.1))
	sequence:InsertCallback(0.23, function ()
		self.groupWays_:SetActive(false)
	end)

	local groupMainCurY = self.groupMain_.height / 2
	local sequence2 = DG.Tweening.DOTween.Sequence()

	sequence2:AppendInterval(0.1)
	sequence2:Append(go.transform:DOLocalMoveY(curY - 10, 0.13))
	sequence2:Append(go.transform:DOLocalMoveY(groupMainCurY + 10, 0.13))
	sequence2:Append(go.transform:DOLocalMoveY(groupMainCurY, 0.1))
end

function ItemTips:showWaysNoAction()
	if not self.isWaysCreate_ then
		local len = self:createWays()
		self.isWaysCreate_ = true
	end

	local mainHeight = self.groupMain_.height
	local mainPos = self.groupMain_.transform.localPosition
	local curY = mainPos.y
	local waysHeight = self.groupWays_.height
	local newY = (waysHeight + mainHeight) / 2
	local waysPos = self.groupWays_.transform.localPosition

	self.groupMain_:SetLocalPosition(mainPos.x, newY, mainPos.z)
	self.groupWays_:SetLocalPosition(waysPos.x, newY - mainHeight, waysPos.z)
	self.groupWays_:SetActive(true)

	self.isShowWays = not self.isShowWays
end

function ItemTips:showWays()
	if not self.isWaysCreate_ then
		self:createWays()

		self.isWaysCreate_ = true
	end

	local mainHeight = self.groupMain_.height
	local mainPos = self.groupMain_.transform.localPosition
	local curY = mainPos.y
	local waysHeight = self.groupWays_.height
	local newY = (waysHeight + mainHeight) / 2
	local waysPos = self.groupWays_.transform.localPosition
	local go = self.groupMain_.gameObject
	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Append(go.transform:DOLocalMoveY(curY + 10, 0.1))
	sequence:Append(go.transform:DOLocalMoveY(newY - 10, 0.13))
	sequence:Append(go.transform:DOLocalMoveY(newY, 0.13))
	self.groupWays_:SetLocalPosition(waysPos.x, newY - mainHeight, 0)

	self.groupWays_.alpha = 0.5

	self.groupWays_:SetLocalScale(0.5, 0.5, 1)
	self.groupWays_:SetActive(true)

	local sequence2 = DG.Tweening.DOTween.Sequence()
	local waysGO = self.groupWays_.gameObject

	sequence2:Insert(0.1, waysGO.transform:DOScale(1.05, 0.13))

	local function setter(value)
		self.groupWays_.color = value
	end

	local function getter()
		return self.groupWays_.color
	end

	sequence2:Insert(0.1, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.13))
	sequence:Insert(0.23, waysGO.transform:DOScale(1, 0.2))
end

function ItemTips:createWays()
	self.labelWaysDesc_.text = __("GET_WAYS")
	local ways = {}

	if self.wndType_ == xyd.ItemTipsWndType.BACKPACK or self.wndType_ == xyd.ItemTipsWndType.ACTIVITY then
		ways = ItemTable:getWays(self.itemID)
	elseif self.wndType_ == xyd.ItemTipsWndType.SMITHY then
		ways = GetWayEquipTable:getStagesByEuqipID(self.itemID, Backpack:getLev())
	end

	if self.itemID == xyd.ItemID.ACTIVITY_FIT_UP_DORM then
		local activityData = ActivityModel:getActivity(xyd.ActivityID.FIT_UP_DORM)

		if activityData and activityData.detail then
			local ways_val = activityData.detail.award_times or 0
			self.ways_val = ways_val
		end
	end

	if self.itemID == xyd.ItemID.ICE_SUMMER_COIN then
		ways = ItemTable:getWays(self.itemID)
		local params = {}

		for i = 1, #ways do
			local way = ways[i]

			if self.ways_val ~= nil then
				table.insert(params, {
					wndType = self.wndType_,
					id = way,
					ways_val = self.ways_val[i],
					item_id = self.itemID
				})
			else
				local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ICE_SUMMER)
				local data = 0

				if activityData ~= nil and i == 2 then
					data = activityData.detail.missions[1].complete_times * 3
				elseif activityData ~= nil and i == 3 then
					data = activityData.detail.missions[2].complete_times
				end

				table.insert(params, {
					wndType = self.wndType_,
					id = way,
					ways_val = data,
					item_id = self.itemID
				})
			end
		end

		self.groupWaysList_.height = #ways * 69 + (#ways - 1) * 10
		self.groupWays_.height = self.groupWaysList_.height + 108
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ICE_SUMMER)

		for i = 1, #ways do
			local wayItem = SingleWayItem.new(self.groupWaysList_.gameObject, params[i])

			table.insert(self.ways, wayItem)

			if activityData == nil then
				wayItem.maskImg:SetActive(true)
				xyd.setTouchEnable(wayItem.btnSelect_, false)
			end
		end

		return #ways
	end

	if self.itemID == xyd.ItemID.SPROUTS_ITEM then
		ways = ItemTable:getWays(self.itemID)
		local params = {}

		for i = 1, #ways do
			local way = ways[i]
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.SPROUTS)
			local data = 0

			if activityData ~= nil and i == 1 then
				data = activityData.detail.missions[1].complete_times * 2
			end

			table.insert(params, {
				wndType = self.wndType_,
				id = way,
				ways_val = data,
				item_id = self.itemID
			})
		end

		self.groupWaysList_.height = #ways * 69 + (#ways - 1) * 10
		self.groupWays_.height = self.groupWaysList_.height + 108
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.SPROUTS)

		for i = 1, #ways do
			local wayItem = SingleWayItem.new(self.groupWaysList_.gameObject, params[i])

			table.insert(self.ways, wayItem)

			if activityData == nil then
				wayItem.maskImg:SetActive(true)
				xyd.setTouchEnable(wayItem.btnSelect_, false)
			end
		end

		return #ways
	end

	if self.itemID == xyd.ItemID.LOVE_LETTER or self.itemID == xyd.ItemID.LOVE_LETTER2 then
		if xyd.models.activity:getActivity(xyd.ActivityID.CANDY_COLLECT) == nil then
			return 0
		end

		ways = ItemTable:getWays(self.itemID)
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.CANDY_COLLECT)
		local params = {}

		for i = 1, #ways do
			local way = ways[i]
			local data = 0

			if activityData ~= nil then
				data = activityData.detail.tasks[i]
			end

			table.insert(params, {
				use_val = true,
				wndType = self.wndType_,
				id = way,
				ways_val = data,
				item_id = self.itemID
			})
		end

		self.groupWaysList_.height = #ways * 69 + (#ways - 1) * 10
		self.groupWays_.height = self.groupWaysList_.height + 108

		for i = 1, #ways do
			local wayItem = SingleWayItem.new(self.groupWaysList_.gameObject, params[i])

			table.insert(self.ways, wayItem)

			if activityData == nil then
				wayItem.maskImg:SetActive(true)
				xyd.setTouchEnable(wayItem.btnSelect_, false)
			end
		end

		return #ways
	end

	if self.itemID == xyd.ItemID.EQUIP_GACHA then
		local activityData = ActivityModel:getActivity(xyd.ActivityID.EQUIP_GACHA)

		if activityData and activityData.detail then
			local ways_val = activityData.detail.tasks or 0
			self.ways_val = __TS__ArrayConcat({
				0,
				0
			}, ways_val)
		else
			self.ways_val = {
				0,
				0,
				0,
				0,
				0
			}
		end

		local params = {}
		local i = 0

		while i < #ways do
			local way = ways[i + 1]

			table.insert(params, {
				wndType = self.wndType_,
				id = way,
				ways_val = self.ways_val[i],
				item_id = self.itemID
			})

			i = i + 1
		end
	end

	if self.itemID == xyd.ItemID.LUCKYBOXES_COIN then
		if xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LUCKYBOXES) == nil then
			return 0
		end

		ways = ItemTable:getWays(self.itemID)
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LUCKYBOXES)
		local params = {}

		for i = 1, #ways do
			local way = ways[i]
			local index = 1
			local ids = xyd.tables.activityLuckyboxesMissonTable:getIDs()

			for j = 1, #ids do
				if xyd.tables.activityLuckyboxesMissonTable:getWay(j) == way then
					index = j

					break
				end
			end

			local data = 0

			if activityData ~= nil then
				data = activityData.detail.is_completeds[index]
			end

			table.insert(params, {
				use_val = true,
				wndType = self.wndType_,
				id = way,
				ways_val = data,
				item_id = self.itemID
			})
		end

		self.groupWaysList_.height = #ways * 69 + (#ways - 1) * 10
		self.groupWays_.height = self.groupWaysList_.height + 108

		for i = 1, #ways do
			local wayItem = SingleWayItem.new(self.groupWaysList_.gameObject, params[i])

			table.insert(self.ways, wayItem)

			if activityData == nil then
				wayItem.maskImg:SetActive(true)
				xyd.setTouchEnable(wayItem.btnSelect_, false)
			end
		end

		return #ways
	end

	local lev = xyd.models.backpack:getLev()
	local params = {}

	for i = 1, #ways do
		local way = ways[i]
		local hideLev = xyd.tables.getWayTable:getHideLv(way)

		if not hideLev or hideLev == 0 or lev <= hideLev then
			table.insert(params, {
				wndType = self.wndType_,
				id = way,
				ways_val = self.ways_val,
				item_id = self.itemID,
				wndName = self.wndName_
			})
		end
	end

	self.groupWaysList_.height = #params * 69 + (#params - 1) * 10
	self.groupWays_.height = self.groupWaysList_.height + 108

	for i = 1, #params do
		local wayItem = SingleWayItem.new(self.groupWaysList_.gameObject, params[i])

		table.insert(self.ways, wayItem)
	end

	return #ways
end

function ItemTips:onBoxBtnOptionalTreasureChest()
	xyd.WindowManager.get():closeWindow("drop_probability_window")
	self:openDropProbabilityWindow({
		isShowProbalitity = false,
		itemId = self.itemID
	})
end

function ItemTips:onBoxBtnNormal()
	local dropProWnd = xyd.WindowManager.get():getWindow("drop_probability_window")

	if dropProWnd then
		local itemTipsWnd = xyd.WindowManager.get():getWindow("item_tips_window")
		local dropProWndParams = dropProWnd:getParams() or nil
		local itemTipsWndParams = itemTipsWnd and itemTipsWnd:getParams() or nil

		xyd.WindowManager.get():closeWindow("drop_probability_window")
		xyd.WindowManager.get():closeWindow("item_tips_window")
		xyd.WindowManager.get():closeWindow("award_item_tips_window")
		self:openDropProbabilityWindow({
			box_id = ItemTable:getDropBoxShow(self.itemID),
			closeCallBack = function ()
				if itemTipsWndParams then
					xyd.WindowManager.get():openWindow("item_tips_window", itemTipsWndParams)
				end

				if dropProWndParams then
					self:openDropProbabilityWindow(dropProWndParams)
				end
			end
		})

		return
	end

	self:openDropProbabilityWindow({
		box_id = ItemTable:getDropBoxShow(self.itemID)
	})
end

function ItemTips:iosTestChangeUI1()
	xyd.setUISprite(self.btnBotLeft_:GetComponent(typeof(UISprite)), nil, "white_btn_65_65_ios_test")
	xyd.setUISprite(self.btnBotRight_:GetComponent(typeof(UISprite)), nil, "blue_btn_65_65_ios_test")
	xyd.setUISprite(self.btnBotMid_:GetComponent(typeof(UISprite)), nil, "blue_btn_65_65_ios_test")
	xyd.setUISprite(self.imgBG2, nil, "9gongge26_ios_test")
	xyd.setUISprite(self.btnBox_:GetComponent(typeof(UISprite)), nil, "check_white_btn_ios_test")
end

function ItemTips:setMultilingualText()
	if (self.itemID == xyd.ItemID.NEWYEAR_WELFARE_GIFTBAG2022 or xyd.ItemID.NEWYEAR_SUPER_GIFTBAG2022) and xyd.Global.lang == "fr_fr" then
		self.labelName_.fontSize = 21
	end
end

function ItemTips:openDropProbabilityWindow(params)
	local type = ItemTable:getType(self.itemID)

	if type == xyd.ItemType.HERO_RANDOM_DEBRIS and xyd.tables.itemTable:getGroup(self.itemID) == xyd.PartnerGroup.TIANYI then
		xyd.openWindow("drop_probability_window", {
			isShowProbalitity = false,
			itemId = self.itemID
		})
	else
		xyd.openWindow("drop_probability_window", params)
	end
end

function ItemTips:showCollectionGroup()
	self.groupColletion:SetActive(true)

	local collectionid = xyd.tables.itemTable:getCollectionId(self.itemID)
	local gotStr = "collection_got_" .. tostring(xyd.Global.lang)
	local noGotStr = "collection_no_get_" .. tostring(xyd.Global.lang)
	self.labelResNum.text = xyd.tables.collectionTable:getCoin(collectionid)
	local isGot = false
	local str = noGotStr

	if xyd.models.collection:isGot(collectionid) then
		isGot = true
		str = gotStr
	end

	xyd.setUISpriteAsync(self.gotImg, nil, str)

	self.groupMain_.height = self.groupMain_.height + 70

	self.groupDesc_:Y(self.groupDesc_.gameObject.transform.localPosition.y - 70)
	self.groupIcon_:Y(self.groupIcon_.gameObject.transform.localPosition.y - 70)

	local top_left = self.groupMain_:NodeByName("top_left").gameObject

	self:waitForFrame(1, function ()
		top_left:Y(top_left.gameObject.transform.localPosition.y - 70)
	end)
end

return ItemTips
