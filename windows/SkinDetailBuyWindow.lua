local MiscTable = xyd.tables.miscTable
local PartnerTable = xyd.tables.partnerTable
local Partner = import("app.models.Partner")
local PartnerCard = import("app.components.PartnerCard")
local PartnerImg = import("app.components.PartnerImg")
local WindowTop = import("app.components.WindowTop")
local PartnerNameTag = import("app.components.PartnerNameTag")
local BaseWindow = import(".BaseWindow")
local SkinDetailBuyWindow = class("SkinDetailBuyWindow", BaseWindow)
local SkinDetailBuyItem = class("SkinDetailBuyItem", import("app.components.BaseComponent"))
local cjson = require("cjson")
local content_height_ = {
	442,
	740
}

function SkinDetailBuyWindow:ctor(name, params)
	SkinDetailBuyWindow.super.ctor(self, name, params)

	self.timerList_ = {}
	self.lock_bubble_ = false
	self.lock_move_ = false
	self.index_ = 1
	self.is_play_sound_ = false
	self.view_state_ = 1
	self.skinByGroup = {}

	for i = 0, xyd.GROUP_NUM do
		self.skinByGroup[i] = {}
	end

	self.datas = {}

	for i = 0, xyd.GROUP_NUM do
		self.datas[i] = {}
	end

	self.cur_index_ = 0
	self.isMoveList = false
	self.isFilter = false
	self.isPartnerFilter = false
	self.isSkinFilter = false
	self.isShowNew = xyd.models.redMark:getRedState(xyd.RedMarkType.SKIN_SHOP)

	self:initData()

	self.curSkinIDs = self.skinByGroup[self.cur_index_]
	self.curSkinDatas = self.datas[self.cur_index_]
	self.current_skin_ = self.curSkinIDs[self.index_]

	self:getTableID()

	self.params_ = params
end

function SkinDetailBuyWindow:getTableID()
	self.current_skin_ = self.curSkinIDs[self.index_]
	self.table_id_ = xyd.tables.partnerPictureTable:getSkinPartner(self.current_skin_)[1]
end

function SkinDetailBuyWindow:initWindow()
	SkinDetailBuyWindow.super.initWindow(self)
	self:getComponent()
	self:updateNameTag()
	self:initTopGroup()
	self:setLayout()

	if self.params_ and self.params_.id then
		self:waitForFrame(1, function ()
			self:updateSelect()
		end)
	end

	self:registerEvent()

	local params = {
		isCanUnSelected = 1,
		scale = 1,
		gap = 13,
		callback = handler(self, function (self, group)
			self:updateSelectGroup(group)
		end),
		width = self.schoolGroupCommon:GetComponent(typeof(UIWidget)).width,
		chosenGroup = self.cur_index_
	}
	local partnerFilter = import("app.components.PartnerFilter").new(self.schoolGroupCommon.gameObject, params)
	self.partnerFilter = partnerFilter
end

function SkinDetailBuyWindow:updateSelect()
	self:selectSkin(self.params_.id)
end

function SkinDetailBuyWindow:getComponent()
	self.imgBg = self.window_:ComponentByName("imgBg", typeof(UITexture))
	self.partnerImgRoot = self.window_:ComponentByName("partnerImg", typeof(UIWidget))
	local conTrans = self.window_:NodeByName("content")
	self.imgModelTouch = conTrans:NodeByName("imgModelTouch").gameObject
	self.groupNameRoot = conTrans:NodeByName("groupName").gameObject
	self.groupName = PartnerNameTag.new(self.groupNameRoot)
	self.page_guide = conTrans:NodeByName("page_guide").gameObject
	self.arrow_left = conTrans:NodeByName("page_guide/arrow_left").gameObject
	self.arrow_left_none = conTrans:NodeByName("page_guide/arrow_left_none").gameObject
	self.arrow_right = conTrans:NodeByName("page_guide/arrow_right").gameObject
	self.arrow_right_none = conTrans:NodeByName("page_guide/arrow_right_none").gameObject
	self.bubbleRoot = conTrans:NodeByName("bubble").gameObject
	self.bubbleTips = conTrans:ComponentByName("bubble/tips", typeof(UILabel))
	self.btnShow = conTrans:NodeByName("groupBtn/btnShow").gameObject
	self.btnZoom = conTrans:NodeByName("groupBtn/btnZoom").gameObject
	self.groupInfo = conTrans:ComponentByName("groupInfoPos/groupInfo", typeof(UIWidget))
	self.scrollView = conTrans:ComponentByName("groupInfoPos/groupInfo/infoContent/scrollView", typeof(UIScrollView))
	self.dataContent = conTrans:ComponentByName("groupInfoPos/groupInfo/infoContent/scrollView/dataContent", typeof(MultiRowWrapContent))
	self.groupNone = conTrans:NodeByName("groupInfoPos/groupInfo/infoContent/groupNone").gameObject
	self.labelNone = self.groupNone:ComponentByName("labelNone", typeof(UILabel))
	local itemRoot = conTrans:NodeByName("groupInfoPos/groupInfo/infoContent/scrollView/itemRoot").gameObject
	self.btnTop = conTrans:NodeByName("groupInfoPos/groupInfo/btnTop").gameObject
	self.btnTopLayout = self.btnTop:GetComponent(typeof(UILayout))
	self.btnTopImg = conTrans:NodeByName("groupInfoPos/groupInfo/btnTop/e:image")
	self.btnTopLabel = conTrans:ComponentByName("groupInfoPos/groupInfo/btnTop/label", typeof(UILabel))
	self.groupFilter = self.groupInfo:NodeByName("groupFilter").gameObject
	self.imgSelect = self.groupFilter:ComponentByName("imgSelect", typeof(UISprite))
	self.filterLabel = self.groupFilter:ComponentByName("filterLabel", typeof(UILabel))
	self.btnFilter = self.groupInfo:NodeByName("btnFilter").gameObject
	self.btnFilterLabel = self.btnFilter:ComponentByName("button_label", typeof(UILabel))
	self.btnFilterImg = self.btnFilter:ComponentByName("buttom_img", typeof(UISprite))
	self.groupFilters = self.groupInfo:ComponentByName("groupFilters", typeof(UIWidget))
	self.btnPartnerFilter = self.groupFilters:NodeByName("groupFilter/groupPartnerFilter/btnPartnerFilter").gameObject
	self.labelPartnerFilter = self.groupFilters:ComponentByName("groupFilter/groupPartnerFilter/labelPartnerFilter", typeof(UILabel))
	self.btnSkinFilter = self.groupFilters:NodeByName("groupFilter/groupSkinFilter/btnSkinFilter").gameObject
	self.labelSkinFilter = self.groupFilters:ComponentByName("groupFilter/groupSkinFilter/labelSkinFilter", typeof(UILabel))
	self.skinEffectGroup = conTrans:NodeByName("skinEffectGroup").gameObject

	self.skinEffectGroup:SetActive(false)

	self.effectGroup1 = self.skinEffectGroup:NodeByName("effectGroup1").gameObject
	self.effectGroup2 = self.skinEffectGroup:NodeByName("effectGroup2").gameObject
	self.effectModel = self.skinEffectGroup:NodeByName("effectModel").gameObject
	self.touchModel = self.skinEffectGroup:NodeByName("touchModel").gameObject
	self.labelName = self.skinEffectGroup:ComponentByName("labelName", typeof(UILabel))
	self.labelAttr = self.skinEffectGroup:ComponentByName("labelAttr", typeof(UILabel))
	self.labelSkinDesc = self.skinEffectGroup:ComponentByName("labelSkinDesc", typeof(UILabel))
	self.cancelEffectGroup = self.skinEffectGroup:NodeByName("cancelEffectGroup").gameObject
	self.partnerImg = PartnerImg.new(self.partnerImgRoot.gameObject)
	self.wrapContent_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView, self.dataContent, itemRoot, SkinDetailBuyItem, self)
	self.schoolGroup = self.groupInfo:NodeByName("schoolGroup").gameObject
	self.schoolGroupCommon = self.groupInfo:NodeByName("schoolGroupCommon").gameObject
end

function SkinDetailBuyWindow:playOpenAnimation(callback)
	SkinDetailBuyWindow.super.playOpenAnimation(self, function ()
		self:updateBg()

		self.openAction_ = self:getSequence()
		local xy = xyd.tables.partnerPictureTable:getPartnerPicXY(self.current_skin_)
		local dragonBoneID = xyd.tables.partnerPictureTable:getDragonBone(self.current_skin_)

		self.partnerImg.go.transform:SetLocalPosition(xy.x, -xy.y, 0)
		self.groupNameRoot.transform:SetLocalPosition(-1278, 507, 0)
		self.groupInfo.transform:SetLocalPosition(xyd.Global:getMaxWidth() + 360, 0, 0)
		self.openAction_:Insert(0, self.groupInfo.transform:DOLocalMove(Vector3(-20, 0, 0), 0.2))
		self.openAction_:Insert(0.2, self.groupInfo.transform:DOLocalMove(Vector3(0, 0, 0), 0.3))
		self.openAction_:Insert(0.1, self.groupNameRoot.transform:DOLocalMove(Vector3(-178, 507, 0), 0.2))
		self.openAction_:Insert(0.1, self.groupNameRoot.transform:DOLocalMove(Vector3(-178, 507, 0), 0.2))
		self.openAction_:Insert(0.3, self.groupNameRoot.transform:DOLocalMove(Vector3(-198, 507, 0), 0.3))
		self.openAction_:AppendCallback(function ()
			self:setWndComplete()
		end)

		if callback then
			callback()
		end
	end)
end

function SkinDetailBuyWindow:updateBg()
	local group = PartnerTable:getGroup(self.table_id_)
	local res = "college_scene" .. group

	if not self.groupBgSource or self.groupBgSource ~= res then
		xyd.setUITextureAsync(self.imgBg, "Textures/scenes_web/" .. res)
	end

	if self.partnerImg and self.partnerImg:getItemID() == self.current_skin_ then
		return
	end

	self.partnerImg:setImg()
	self.partnerImg:setImg({
		showResLoading = true,
		windowName = self.name_,
		itemID = self.current_skin_
	})

	local xy = xyd.tables.partnerPictureTable:getPartnerPicXY(self.current_skin_)
	local scale = xyd.tables.partnerPictureTable:getPartnerPicScale(self.current_skin_)

	self.partnerImg.go.transform:SetLocalPosition(xy.x, -xy.y, 0)
	self.partnerImg.go.transform:SetLocalScale(scale, scale, scale)
end

function SkinDetailBuyWindow:setPartnerRootSatus(flag)
	self.partnerImgRoot:SetActive(flag)
end

function SkinDetailBuyWindow:initTopGroup()
	local items = {
		{
			id = xyd.ItemID.SKIN_COIN,
			callback = function ()
				local params = {
					showGetWays = true,
					itemID = xyd.ItemID.SKIN_COIN,
					itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.SKIN_COIN),
					wndType = xyd.ItemTipsWndType.ACTIVITY,
					wndName = self.name_
				}

				xyd.WindowManager.get():openWindow("item_tips_window", params)
			end
		}
	}

	if not self.windowTop_ then
		self.windowTop_ = WindowTop.new(self.window_, self.name_)
	end

	self.windowTop_:setDepth(50)
	self.windowTop_:setItem(items)
end

function SkinDetailBuyWindow:updateNameTag()
	local name = xyd.tables.equipTextTable:getName(self.current_skin_)
	local partnerName = xyd.tables.partnerTextTable:getName(self.table_id_)
	local group = xyd.tables.partnerTable:getGroup(self.table_id_)

	self.groupName:setSkinName(name, partnerName, group, self.table_id_, {
		effectColor = 960513791
	})
end

function SkinDetailBuyWindow:setLayout()
	self:updateGuideArrow()
	self:initSkinEffect()
	self:updatePartnerSkin(false, self.cur_index_)
	self:updateFilterBtn()

	self.btnTopLabel.text = __("UNFOLD_SKIN")
	self.filterLabel.text = __("SHOP_SKIN_TEXT08")
	self.labelNone.text = __("SHOP_SKIN_TEXT09")
	self.labelPartnerFilter.text = __("SHOP_SKIN_TEXT10")
	self.labelSkinFilter.text = __("SHOP_SKIN_TEXT11")
	self.btnFilterLabel.text = __("SHOP_SKIN_TEXT12")

	self.groupFilter:SetActive(false)
	self.groupFilters:SetActive(false)
	self.btnFilterImg.transform:SetLocalScale(1, 1, 1)
	self:updateFilters()
end

function SkinDetailBuyWindow:updateFilters()
	local groupFiltersSize = {
		height = self.groupFilters.height,
		width = self.groupFilters.width
	}

	if xyd.Global.lang == "de_de" then
		groupFiltersSize.height = 123
		groupFiltersSize.width = 400
		self.labelPartnerFilter.width = 300
		self.labelSkinFilter.width = 300
	elseif xyd.Global.lang == "fr_fr" then
		groupFiltersSize.height = 123
		groupFiltersSize.width = 400
		self.labelPartnerFilter.width = 300
		self.labelSkinFilter.width = 300
	elseif xyd.Global.lang == "en_en" then
		groupFiltersSize.height = 123
		groupFiltersSize.width = 300
		self.labelPartnerFilter.width = 200
		self.labelSkinFilter.width = 200
	end

	self.groupFilters:SetBottomAnchor(self.btnFilter, 1, 16)
	self.groupFilters:SetRightAnchor(self.btnFilter, 1, 0)
	self.groupFilters:SetLeftAnchor(self.btnFilter, 1, 0 - groupFiltersSize.width)
	self.groupFilters:SetTopAnchor(self.btnFilter, 1, 16 + groupFiltersSize.height)
end

function SkinDetailBuyWindow:updateGuideArrow()
	self.arrow_left:SetActive(self.index_ > 1)
	self.arrow_left_none:SetActive(#self.curSkinIDs > 1 and self.index_ <= 1)
	self.arrow_right:SetActive(self.index_ < #self.curSkinIDs)
	self.arrow_right_none:SetActive(#self.curSkinIDs > 1 and self.index_ == #self.curSkinIDs)
end

function SkinDetailBuyWindow:initSkinEffect()
	if self.skinEffect1 and self.skinEffect2 then
		return
	end

	if not self.skinEffect2 then
		self.skinEffect2 = xyd.Spine.new(self.effectGroup2)

		self.skinEffect2:setInfo("fx_ui_fazhen", function ()
			self.skinEffect2:SetLocalPosition(0, 0, 20)
			self.skinEffect2:SetLocalScale(1, 1, 1)
			self.skinEffect2:setRenderTarget(self.effectGroup2:GetComponent(typeof(UIWidget)), 1)
			self.skinEffect2:play("texiao02", -1, 1)
		end)
	end

	if not self.skinEffect1 then
		self.skinEffect1 = xyd.Spine.new(self.effectGroup1)

		self.skinEffect1:setInfo("fx_ui_fazhen", function ()
			self.skinEffect1:SetLocalPosition(0, 0, 30)
			self.skinEffect1:SetLocalScale(1, 1, 1)
			self.skinEffect1:setRenderTarget(self.effectGroup1:GetComponent(typeof(UIWidget)), 1)
			self.skinEffect1:play("texiao01", -1, 1)
		end)
	end
end

function SkinDetailBuyWindow:getSkinIndex(skinId)
	local ids = self.curSkinIDs
	local pos = xyd.arrayIndexOf(ids, skinId)

	if pos < 1 then
		pos = 1
	end

	return pos
end

function SkinDetailBuyWindow:updateChosenGroup(group)
end

function SkinDetailBuyWindow:initData()
	local skinIDs = {}
	local datas = {}
	local ids = xyd.tables.shopSkinTable:getItemIDs()

	for _, id in ipairs(ids) do
		table.insert(skinIDs, id)
	end

	if xyd.Global.isReview == 1 then
		skinIDs = {}
	end

	local nowTime = xyd.getServerTime()

	for idx, skinID in ipairs(skinIDs) do
		local tableID = xyd.tables.partnerPictureTable:getSkinPartner(skinID)[1]
		local group = xyd.tables.partnerTable:getGroup(tableID)
		local showTime = xyd.tables.partnerPictureTable:getShowTime(skinID)
		local id = xyd.tables.shopSkinTable:idByItemID(skinID)
		local hasNew = false
		local endTime = xyd.tables.shopSkinTable:getShopNew(id)
		local collectionID = xyd.tables.itemTable:getCollectionId(skinID)
		local qlt = nil

		if collectionID and collectionID > 0 then
			qlt = xyd.tables.collectionTable:getQlt(collectionID)
		end

		if self.isShowNew and nowTime < endTime then
			hasNew = true
		end

		if not showTime or xyd.getServerTime() >= showTime then
			local data = {
				collect = false,
				is_equip = false,
				tableID = tableID,
				group = group,
				skin_id = skinID,
				hasNew = hasNew,
				qlt = qlt
			}

			if skinID == self.current_skin_ then
				data.collect = true
			end

			table.insert(self.skinByGroup[group], skinID)
			table.insert(self.skinByGroup[0], skinID)
			table.insert(self.datas[0], data)
			table.insert(self.datas[group], data)
		end
	end
end

function SkinDetailBuyWindow:updatePartnerSkin(keepPosition, group)
	self.curSkinDatas, self.curSkinIDs = self:filterSkin(self.datas[self.cur_index_])

	self.wrapContent_:setInfos(self.curSkinDatas, {
		keepPosition = keepPosition
	})
	self.wrapContent_:resetScrollView()

	if #self.curSkinDatas <= 0 then
		self.groupNone:SetActive(true)

		return
	else
		self.groupNone:SetActive(false)
	end

	self.index_ = self:getIndex(self.curSkinDatas, self.current_skin_)

	if self.index_ < 1 or group == 0 then
		self.index_ = 1
		self.current_skin_ = self.curSkinDatas[1].skin_id

		self:setModelLayout(self.current_skin_)
	end

	local tmpSkinId = self.current_skin_
	self.current_skin_ = 0

	self:selectSkin(tmpSkinId)
end

function SkinDetailBuyWindow:filterSkin(skins)
	local data = {}
	local ids = {}

	for _, skin in ipairs(skins) do
		local skinID = skin.skin_id
		local num = self:getRealSkinNum(skinID)

		if (not self.isPartnerFilter or xyd.models.slot:hasSkinPartner(skinID)) and (not self.isSkinFilter or num == 0) then
			table.insert(data, skin)
			table.insert(ids, skin.skin_id)
		end
	end

	return data, ids
end

function SkinDetailBuyWindow:getRealSkinNum(skinID)
	local realNum = xyd.models.backpack:getItemNumByID(skinID)
	local partners = xyd.models.slot:getSortedPartners()["0_0"]

	for _, id in ipairs(partners) do
		local partnerData = xyd.models.slot:getPartner(id)

		if partnerData and partnerData:getSkinID() == skinID then
			realNum = realNum + 1
		end
	end

	return realNum
end

function SkinDetailBuyWindow:updateSelectGroup(index)
	self.cur_index_ = index

	self:updatePartnerSkin(false, self.cur_index_)
end

function SkinDetailBuyWindow:getCurSkinId()
	return self.current_skin_
end

function SkinDetailBuyWindow:selectSkin(skinID)
	if skinID == self.current_skin_ then
		return
	end

	self.curSkinDatas, self.curSkinIDs = self:filterSkin(self.datas[self.cur_index_])

	for _, data in ipairs(self.curSkinDatas) do
		if data.skin_id == skinID then
			data.collect = true
		else
			data.collect = false
		end
	end

	self.wrapContent_:setInfos(self.curSkinDatas, {
		keepPosition = true
	})

	local items = self.wrapContent_:getItems()

	for _, item in ipairs(items) do
		if item:getSkinID() == skinID then
			item:setSelect(true)
		else
			item:setSelect(false)
		end
	end

	self.current_skin_ = skinID
	local index = self:getIndex(self.curSkinDatas, skinID)

	if index ~= self.index_ then
		self.index_ = index

		self:jumpToIndex(self.index_)
	end

	self.index_ = index
	self.table_id_ = xyd.tables.partnerPictureTable:getSkinPartner(skinID)[1]

	self:updateGuideArrow()
	self:setSkinState()
end

function SkinDetailBuyWindow:getIndex(list, skinID)
	for i in ipairs(list) do
		if list[i].skin_id == skinID then
			return i
		end
	end

	return 0
end

function SkinDetailBuyWindow:setSkinState()
	self:loadHeroModel()
	self:updateNameTag()
	self:updateBg()
end

function SkinDetailBuyWindow:jumpToIndex(index)
	if self.view_state_ == 1 then
		local lineNum = math.ceil(index / 4) - 1
		local moveY = lineNum * 340

		self.scrollView.transform:DOLocalMove(Vector3(0, moveY + 190, 0), 0.5)
	end
end

function SkinDetailBuyWindow:loadHeroModel()
	local skinID = self.current_skin_
	local modelID = xyd.tables.equipTable:getSkinModel(skinID)
	self.labelSkinDesc.text = xyd.tables.equipTextTable:getSkinDesc(skinID)
	local name = xyd.tables.modelTable:getModelName(modelID)

	if not modelID or not name then
		return
	end

	if self.skinModel and self.skinModel:getName() == name then
		return
	end

	if not self.skinModel then
		self.skinModel = xyd.Spine.new(self.effectModel)
	else
		NGUITools.DestroyChildren(self.effectModel.transform)

		self.skinModel = xyd.Spine.new(self.effectModel)
	end

	self.skinModel:setInfo(name, function ()
		self.skinModel:SetLocalPosition(0, 0, -10)
		self.skinModel:SetLocalScale(0.7, 0.7, 0.7)

		if self.skinModel.spAnim then
			self.skinModel:setRenderTarget(self.effectModel:GetComponent(typeof(UIWidget)), 1)
			self.skinModel:play("idle", -1, 1)
		end
	end)
end

function SkinDetailBuyWindow:setModelLayout(skin_id)
	self.labelAttr.text = xyd.tables.equipTable:getDesc(skin_id)
	self.labelName.text = xyd.tables.equipTable:getName(skin_id)
end

function SkinDetailBuyWindow:onClickTopBtn()
	if self.isMoveList then
		return
	end

	self.isMoveList = true
	local state = xyd.checkCondition(self.view_state_ == 1, 2, 1)
	local action = self:getSequence(function ()
		self:updateTopBtnState()

		self.isMoveList = false
	end)

	local function setter(value)
		self.groupInfo.height = value

		if self.scrollView:Y() < 500 then
			self.scrollView:ResetPosition()
		end
	end

	action:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), content_height_[self.view_state_], content_height_[state], 0.25))
	action:AppendCallback(function ()
		if self.scrollView:Y() < 500 then
			self.scrollView:ResetPosition()
		end
	end)

	if self.view_state_ == 2 then
		self.btnShow:SetActive(true)
		self.btnZoom:SetActive(true)
	else
		self.btnShow:SetActive(false)
		self.btnZoom:SetActive(false)
	end
end

function SkinDetailBuyWindow:updateTopBtnState()
	local state = xyd.checkCondition(self.view_state_ == 1, 2, 1)
	self.view_state_ = state

	if self.view_state_ == 2 then
		self.lock_move_ = true
		self.btnTopLabel.text = __("FOLD_SKIN")

		self.btnTopImg:SetLocalScale(1, 1, 1)
	else
		self.lock_move_ = false
		self.btnTopLabel.text = __("UNFOLD_SKIN")

		self.btnTopImg:SetLocalScale(1, -1, 1)
	end

	self.btnTopLayout:Reposition()
end

function SkinDetailBuyWindow:registerEvent()
	UIEventListener.Get(self.arrow_left).onClick = function ()
		if self.skinEffectGroup.activeSelf == true then
			return
		end

		self:onclickArrow(-1)
		self:updateGuideArrow()
	end

	UIEventListener.Get(self.arrow_right).onClick = function ()
		if self.skinEffectGroup.activeSelf == true then
			return
		end

		self:onclickArrow(1)
		self:updateGuideArrow()
	end

	UIEventListener.Get(self.btnTop).onClick = handler(self, self.onClickTopBtn)
	UIEventListener.Get(self.touchModel).onClick = handler(self, self.onModelTouch)

	UIEventListener.Get(self.partnerImgRoot.gameObject).onClick = function ()
		self:onclickPartnerImg()
	end

	UIEventListener.Get(self.partnerImgRoot.gameObject).onDragStart = function ()
		self.delta_ = 0
	end

	UIEventListener.Get(self.partnerImgRoot.gameObject).onDrag = function (go, delta)
		self.delta_ = self.delta_ + delta.x
	end

	UIEventListener.Get(self.partnerImgRoot.gameObject).onDragEnd = function ()
		if self.delta_ > 50 then
			self:onclickArrow(-1)
		end

		if self.delta_ < -50 then
			self:onclickArrow(1)
		end
	end

	UIEventListener.Get(self.btnZoom).onClick = handler(self, self.onclickZoom)

	UIEventListener.Get(self.btnShow).onClick = function ()
		if self.skinEffectGroup.activeSelf == false then
			self:setModelLayout(self.current_skin_)
			self.imgModelTouch:SetActive(true)
			self.page_guide:SetActive(false)
		else
			self.imgModelTouch:SetActive(false)
			self.page_guide:SetActive(true)
		end

		self.skinEffectGroup:SetActive(not self.skinEffectGroup.activeSelf)
		self:loadHeroModel()
	end

	UIEventListener.Get(self.imgModelTouch).onClick = function ()
		self.skinEffectGroup:SetActive(false)
		self.imgModelTouch:SetActive(false)
		self.page_guide:SetActive(true)
	end

	UIEventListener.Get(self.cancelEffectGroup).onClick = function ()
		self.skinEffectGroup:SetActive(false)
	end

	UIEventListener.Get(self.groupFilter).onClick = function ()
		self.isFilter = not self.isFilter

		self:updateFilterBtn()
		self:updatePartnerSkin()
	end

	UIEventListener.Get(self.btnFilter).onClick = handler(self, self.onClickBtnFilter)
	UIEventListener.Get(self.btnPartnerFilter).onClick = handler(self, self.onClickPartnerFilter)
	UIEventListener.Get(self.btnSkinFilter).onClick = handler(self, self.onClickSkinFilter)

	self.eventProxy_:addEventListener(xyd.event.BUY_SHOP_ITEM, handler(self, self.onBuyShop))
end

function SkinDetailBuyWindow:updateFilterBtn(delta)
	if self.isFilter then
		xyd.setUISpriteAsync(self.imgSelect, nil, "setting_up_pick")
	else
		xyd.setUISpriteAsync(self.imgSelect, nil, "setting_up_unpick")
	end

	local imgUnselect = self.btnPartnerFilter:ComponentByName("imgUnselect", typeof(UISprite))
	local imgSelect = self.btnPartnerFilter:ComponentByName("imgSelect", typeof(UISprite))

	imgUnselect:SetActive(not self.isPartnerFilter)
	imgSelect:SetActive(self.isPartnerFilter)

	imgUnselect = self.btnSkinFilter:ComponentByName("imgUnselect", typeof(UISprite))
	imgSelect = self.btnSkinFilter:ComponentByName("imgSelect", typeof(UISprite))

	imgUnselect:SetActive(not self.isSkinFilter)
	imgSelect:SetActive(self.isSkinFilter)
end

function SkinDetailBuyWindow:onClickBtnFilter()
	local scaleY = self.btnFilterImg.transform.localScale.y
	scaleY = -1 * scaleY

	self.btnFilterImg.transform:SetLocalScale(1, scaleY, 1)
	self.groupFilters:SetActive(scaleY ~= 1)
	self:updateFilters()
end

function SkinDetailBuyWindow:onClickPartnerFilter()
	self.isPartnerFilter = not self.isPartnerFilter
	local imgUnselect = self.btnPartnerFilter:ComponentByName("imgUnselect", typeof(UISprite))
	local imgSelect = self.btnPartnerFilter:ComponentByName("imgSelect", typeof(UISprite))

	imgUnselect:SetActive(not self.isPartnerFilter)
	imgSelect:SetActive(self.isPartnerFilter)
	self:updatePartnerSkin()
end

function SkinDetailBuyWindow:onClickSkinFilter()
	self.isSkinFilter = not self.isSkinFilter
	local imgUnselect = self.btnSkinFilter:ComponentByName("imgUnselect", typeof(UISprite))
	local imgSelect = self.btnSkinFilter:ComponentByName("imgSelect", typeof(UISprite))

	imgUnselect:SetActive(not self.isSkinFilter)
	imgSelect:SetActive(self.isSkinFilter)
	self:updatePartnerSkin()
end

function SkinDetailBuyWindow:onclickArrow(delta)
	if self.index_ + delta <= 0 or self.index_ + delta > #self.curSkinIDs then
		return
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.SWITCH_PAGE)

	self.index_ = self.index_ + delta

	self:playSwitchAnimation()
	self:selectSkin(self.curSkinIDs[self.index_])
	self:checkStopSound()
end

function SkinDetailBuyWindow:playSwitchAnimation()
	local action = DG.Tweening.DOTween.Sequence()

	if not self.sequence_ then
		self.sequence_ = {}
	end

	table.insert(self.sequence_, action)

	local function setter(value)
		self.partnerImgRoot.alpha = value
	end

	action:Insert(0, self.groupInfo.transform:DOLocalMove(Vector3(0, -630, 0), 0.2))
	action:Insert(0.2, self.groupInfo.transform:DOLocalMove(Vector3(0, 0, 0), 0.2))
	action:Insert(0, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0.01, 1, 0.1):SetEase(DG.Tweening.Ease.Linear))
	action:Insert(0.1, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 1, 0.1):SetEase(DG.Tweening.Ease.Linear))
end

function SkinDetailBuyWindow:onModelTouch()
	if not self.skinModel or not self.skinModel:isValid() then
		return
	end

	local tableID = self.table_id_
	local mp = xyd.tables.partnerTable:getEnergyID(tableID)
	local ack = xyd.tables.partnerTable:getPugongID(tableID)
	local skillID = 0

	if xyd.getServerTime() % 2 > 0 then
		skillID = mp

		self.skinModel:play("skill", 1, 1, function ()
			self.skinModel:play("idle", -1, 1)
		end)
	else
		skillID = ack

		self.skinModel:play("attack", 1, 1, function ()
			self.skinModel:play("idle", -1, 1)
		end)
	end

	if self.skill_sound_ then
		xyd.SoundManager.get():stopSound(self.skill_sound_)
	end

	self.skill_sound_ = tostring(xyd.tables.skillTable:getSound(skillID))

	xyd.SoundManager.get():playSound(self.skill_sound_)
end

function SkinDetailBuyWindow:onBuyShop(event)
	local params = event.data
	local index = params.index
	local items = params.items
	local buyItem = items[index]
	local itemData = buyItem.item

	local function effect_callback()
		xyd.alertItems({
			{
				item_num = 1,
				item_id = tonumber(itemData[1])
			}
		})
		self:setSkinState()

		local items = self.wrapContent_:getItems()

		for _, item in ipairs(items) do
			item:showRealSkinNum()
		end
	end

	if xyd.tables.itemTable:getType(itemData[1]) == xyd.ItemType.SKIN then
		xyd.onGetNewPartnersOrSkins({
			destory_res = false,
			skins = {
				tonumber(itemData[1])
			},
			callback = effect_callback
		})
	else
		effect_callback()
	end
end

function SkinDetailBuyWindow:onclickPartnerImg()
	if self.bubbleRoot.activeSelf or self.is_play_sound_ then
		return
	end

	self.bubbleRoot:SetActive(not self.bubbleRoot.activeSelf)

	local clickSoundNum = xyd.tables.partnerTable:getClickSoundNum(self.table_id_, self.current_skin_)
	local rand = math.floor(math.random() * clickSoundNum + 0.5) + 1
	local index = xyd.checkCondition(clickSoundNum < rand, rand - clickSoundNum, rand)
	local dialogInfo = xyd.tables.partnerTable:getClickDialogInfo(self.table_id_, index, self.current_skin_)
	self.is_play_sound_ = true
	local htmlParser = nil
	self.bubbleTips.text = dialogInfo.dialog

	xyd.SoundManager.get():playSound(dialogInfo.sound)
	XYDCo.WaitForTime(dialogInfo.time, function ()
		if tolua.isnull(self.window_) then
			return
		end

		self.is_play_sound_ = false

		self.bubbleRoot:SetActive(false)
	end, "dialogTimeOut")
	table.insert(self.waitForTimeKeys_, "dialogTimeOut")

	dialogInfo.timeOutId = "dialogTimeOut"
	self.current_dialog_ = dialogInfo
end

function SkinDetailBuyWindow:onclickZoom(event)
	local group = xyd.tables.partnerTable:getGroup(self.table_id_)
	local res = nil

	if xyd.Global.usePvr then
		res = "college_scene" .. group .. "_pvr"
	else
		res = "college_scene" .. group
	end

	local group = xyd.tables.partnerTable:getGroup(self.table_id_)

	xyd.WindowManager.get():openWindow("partner_detail_zoom_window", {
		item_id = self.current_skin_,
		bg_source = res,
		group = group
	})
end

function SkinDetailBuyWindow:updateSkinID(skinID)
	self.current_skin_ = skinID
	self.table_id_ = xyd.tables.partnerPictureTable:getSkinPartner(self.current_skin_)[1]
end

function SkinDetailBuyWindow:checkStopSound()
	if self.is_play_sound_ then
		xyd.SoundManager.get():stopSound(self.current_dialog_.sound)
		XYDCo.StopWait(self.current_dialog_.timeOutId)

		self.is_play_sound_ = false

		if self.bubbleRoot then
			self.bubbleRoot:SetActive(false)
		end
	end
end

function SkinDetailBuyWindow:didClose()
	SkinDetailBuyWindow.super.didClose(self)
	self:checkStopSound()
end

function SkinDetailBuyWindow:willClose()
	SkinDetailBuyWindow.super.willClose(self)

	local wnd = xyd.WindowManager.get():getWindow("res_loading_window")

	if wnd then
		xyd.WindowManager.get():closeWindow("res_loading_window")
	end

	local ans = {}
	local ids = xyd.tables.shopSkinTable:getIds()
	local nowTime = xyd.getServerTime()

	for _, id in ipairs(ids) do
		local endTime = xyd.tables.shopSkinTable:getShopNew(id)

		if nowTime < endTime then
			table.insert(ans, id)
		end
	end

	xyd.db.misc:setValue({
		key = "skin_shop_record_new_ids",
		value = cjson.encode(ans)
	})
	xyd.models.redMark:setMark(xyd.RedMarkType.SKIN_SHOP, false)

	if self.sequence_ then
		for i = 1, #self.sequence_ do
			if self.sequence_[i] then
				self.sequence_[i]:Kill(false)

				self.sequence_[i] = nil
			end
		end
	end
end

function SkinDetailBuyItem:ctor(parentGo, parent)
	self.parent_ = parent
	self.renderPanel = self.parent_.scrollView:GetComponent(typeof(UIPanel))

	SkinDetailBuyItem.super.ctor(self, parentGo)
	self:createChildren()
end

function SkinDetailBuyItem:getPrefabPath()
	return "Prefabs/Components/skin_detail_buy_item"
end

function SkinDetailBuyItem:initUI()
	SkinDetailBuyItem.super.initUI(self)
	self.go.transform:SetLocalPosition(0, 35, 0)

	self.partnerCardRoot = self.go:NodeByName("partnerCardRoot").gameObject
	local dragScrollView = self.partnerCardRoot:AddComponent(typeof(UIDragScrollView))
	dragScrollView.scrollView = self.parent_.scrollView
	self.buyBtn = self.go:NodeByName("buyBtn").gameObject
	self.costImg = self.buyBtn:ComponentByName("e:image", typeof(UISprite))
	self.buyBtnLabel = self.buyBtn:ComponentByName("label", typeof(UILabel))
	self.partnerCard = PartnerCard.new(self.partnerCardRoot, self.renderPanel)
	self.skinImgNew = self.go:ComponentByName("skinImgNew", typeof(UISprite))
	self.buyBtn_image = self.go:ComponentByName("buyBtn/e:image", typeof(UISprite))

	xyd.setUISpriteAsync(self.buyBtn_image, nil, "icon_74")
end

function SkinDetailBuyItem:createChildren()
	UIEventListener.Get(self.partnerCardRoot).onClick = handler(self, self.onTouchTap)

	UIEventListener.Get(self.partnerCardRoot).onDragStart = function ()
		self.onDrag = true
	end

	UIEventListener.Get(self.partnerCardRoot).onDragEnd = function ()
		self.onDrag = false
	end

	UIEventListener.Get(self.partnerCardRoot).onPress = function (go, isPressed)
		if isPressed then
			local function onTime()
				if self.go and not tolua.isnull(self.go.gameObject) then
					self.timer_:Stop()

					if not self.onDrag then
						xyd.WindowManager.get():openWindow("skin_tip_window", {
							skin_id = self.info_.skin_id,
							tableID = self.info_.tableID
						})
					end
				end
			end

			if not self.timer_ then
				self.timer_ = Timer.New(onTime, 1, -1)

				self.timer_:Start()
				table.insert(self.parent_.timerList_, self.timer_)
			else
				self.timer_:Start()
			end
		else
			self.timer_:Stop()
		end
	end

	UIEventListener.Get(self.buyBtn).onClick = handler(self, self.onBuy)
end

function SkinDetailBuyItem:update(index, realindex, info)
	if not info then
		self.parentGo:SetActive(false)

		return
	end

	self.parentGo:SetActive(true)

	if not self.info_ or info.skin_id ~= self.info_.skin_id or info.collect ~= self.info_.collect then
		self.info_ = info

		self.partnerCard:resetData()
		self.partnerCard:setSkinCard(self.info_)
		self.partnerCard:setSkinCollect(self.info_.collect)
		self.partnerCard:setDisplay()
		self.partnerCard:showRealSkinNum()
		self.partnerCard:setQltLowerThanPartnerName()

		local cost = xyd.tables.shopSkinTable:costByItemID(self.info_.skin_id)
		self.buyBtnLabel.text = cost[2]
	elseif self.info_ then
		self.partnerCard:resetData()
		self.partnerCard:showRealSkinNum()
	end

	if self.info_.hasNew then
		self.skinImgNew:SetActive(true)
	else
		self.skinImgNew:SetActive(false)
	end
end

function SkinDetailBuyItem:showRealSkinNum()
	if self.partnerCard then
		self.partnerCard:resetData()
		self.partnerCard:showRealSkinNum()
	end
end

function SkinDetailBuyItem:onTouchTap()
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	local win = xyd.WindowManager.get():getWindow("skin_detail_buy_window")

	if win and win:getCurSkinId() == self.info_.skin_id then
		xyd.WindowManager.get():openWindow("skin_tip_window", {
			skin_id = self.info_.skin_id,
			tableID = self.info_.tableID
		})
	end

	if win then
		win:selectSkin(self.info_.skin_id)
		win:setModelLayout(self.info_.skin_id)
	end
end

function SkinDetailBuyItem:onBuy()
	local skin = self.info_.skin_id
	local cost = xyd.tables.shopSkinTable:costByItemID(skin)

	if not cost or not cost[1] then
		return
	end

	if xyd.isItemAbsence(cost[1], cost[2]) then
		return
	end

	local selfSkinNum = xyd.models.backpack:getItemNumByID(skin)

	if selfSkinNum > 0 then
		xyd.alertYesNo(__("SHOP_SKIN_TEXT01"), function (yes_no)
			if yes_no then
				self:buySkin()
			end
		end)

		return
	end

	local flag = xyd.models.slot:hasSkinPartner(skin)

	if not flag then
		xyd.alertYesNo(__("SHOP_SKIN_TEXT02"), function (yes_no)
			if yes_no then
				self:buySkin()
			end
		end)

		return
	end

	xyd.alertYesNo(__("CONFIRM_BUY"), function (yes_no)
		if yes_no then
			self:buySkin()
		end
	end)
end

function SkinDetailBuyItem:buySkin()
	local skin = self.info_.skin_id
	local cost = xyd.tables.shopSkinTable:costByItemID(skin)

	if not cost or not cost[1] then
		return
	end

	if not xyd.isItemAbsence(cost[1], cost[2], false) then
		local id = xyd.tables.shopSkinTable:idByItemID(skin)

		xyd.models.shop:buyShopItem(xyd.ShopType.SHOP_SKIN, id, 1)
	end
end

function SkinDetailBuyItem:getSkinID()
	if self.info_ then
		return self.info_.skin_id
	else
		return nil
	end
end

function SkinDetailBuyItem:setSelect(state)
	self.partnerCard:setSkinCollect(state)
end

return SkinDetailBuyWindow
