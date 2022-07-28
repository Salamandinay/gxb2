local CollectionSkinDetailWindow = class("CollectionSkinDetailWindow", import(".BaseWindow"))
local Partner = import("app.models.Partner")
local WindowTop = import("app.components.WindowTop")
local PartnerNameTag = import("app.components.PartnerNameTag")
local ParnterImg = import("app.components.PartnerImg")
local PartnerGravityController = import("app.components.PartnerGravityController")

function CollectionSkinDetailWindow:ctor(name, params)
	CollectionSkinDetailWindow.super.ctor(self, name, params)

	self.themeID = params.themeID
	local win = xyd.WindowManager.get():getWindow("collection_skin_window")

	if win then
		if params.themeID then
			self.currentSortedPartners_ = {}
			self.skinIDs = xyd.tables.collectionSkinGroupTable:getSkins(params.themeID)

			for i = 1, #self.skinIDs do
				local skinID = self.skinIDs[i]
				local collectionID = xyd.tables.itemTable:getCollectionId(skinID)

				if win:canShow(collectionID) then
					table.insert(self.currentSortedPartners_, {
						skin_id = skinID,
						collectionID = collectionID,
						tableID = xyd.tables.partnerTable:getPartnerIdBySkinId(tonumber(skinID))[1]
					})
				end
			end
		elseif params.partnerTableID then
			self.currentSortedPartners_ = {}
			local collectionIDs = xyd.tables.collectionTable:getIdsListByType(xyd.CollectionTableType.SKIN)

			for _, collectionID in ipairs(collectionIDs) do
				local skin_id = xyd.tables.collectionTable:getItemId(collectionID)
				local tableList = xyd.tables.partnerPictureTable:getSkinPartner(skin_id)
				local partnerTableID = tonumber(tableList[1])

				if partnerTableID == params.partnerTableID and win:canShow(collectionID) then
					table.insert(self.currentSortedPartners_, {
						skin_id = skin_id,
						collectionID = collectionID,
						tableID = partnerTableID
					})
				end
			end
		else
			self.currentSortedPartners_ = win:getDatas()
		end
	end

	if xyd.getServerTime() - xyd.models.collection:getGetCollectionTime() > 60 then
		xyd.models.collection:reqCollectionInfo()
	end

	self.model_ = xyd.models.slot

	if not self.currentSortedPartners_ then
		self.currentSortedPartners_ = {}
	end

	for idx = 1, #self.currentSortedPartners_ do
		if self.currentSortedPartners_[idx].skin_id == params.skin_id then
			self.currentIdx_ = idx
		end
	end

	if not self.currentIdx_ then
		self.currentIdx_ = 1
		self.currentSortedPartners_ = {
			{
				skin_id = params.skin_id,
				collectionID = params.collectionID,
				tableID = xyd.tables.partnerTable:getPartnerIdBySkinId(tonumber(params.skin_id))[1]
			}
		}
	end
end

function CollectionSkinDetailWindow:initWindow()
	CollectionSkinDetailWindow.super.initWindow(self)
	self:getUIComponent()
	self:initTopGroup()
	self:firstInit()

	if xyd.GuideController.get():isGuideComplete() then
		self.bubbleRoot_:SetActive(false)
	end
end

function CollectionSkinDetailWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupBg_ = winTrans:ComponentByName("groupBg", typeof(UITexture))
	self.partnerImgRoot_ = winTrans:NodeByName("patnerImg").gameObject
	local uiGroup = winTrans:NodeByName("uiGroup")
	self.partnerNameTagRoot_ = uiGroup:NodeByName("partnerNameTag").gameObject
	self.arrow_left_ = uiGroup:NodeByName("pageGuide/arrow_left").gameObject
	self.arrow_right_ = uiGroup:NodeByName("pageGuide/arrow_right").gameObject
	self.btnZoom_ = uiGroup:NodeByName("btnZoom").gameObject
	self.bubbleRoot_ = uiGroup:NodeByName("bubble").gameObject
	self.tips_ = uiGroup:ComponentByName("bubble/tips", typeof(UILabel))
	self.cvGroup_ = uiGroup:NodeByName("cvGroup").gameObject
	self.cvLabel_ = uiGroup:ComponentByName("cvGroup/cvLabel", typeof(UILabel))
	self.cvNameLabel_ = uiGroup:ComponentByName("cvGroup/cvNameLabel", typeof(UILabel))
	self.groupInfo_ = uiGroup:NodeByName("groupInfo/content")
	self.goShopBtn_ = self.groupInfo_:NodeByName("goShopBtn").gameObject
	self.goShopBtnLabel_ = self.groupInfo_:ComponentByName("goShopBtn/label", typeof(UILabel))
	self.gotImg_ = self.groupInfo_:ComponentByName("gotImg", typeof(UISprite))
	self.LabelResNum_ = self.groupInfo_:ComponentByName("resItem/LabelResNum", typeof(UILabel))
	self.attrWords_ = self.groupInfo_:ComponentByName("attrWords", typeof(UILabel))
	self.getWayWords_ = self.groupInfo_:ComponentByName("getWayWords", typeof(UILabel))
	self.labelAttr_ = self.groupInfo_:ComponentByName("labelAttr", typeof(UILabel))
	self.getWayText_ = self.groupInfo_:ComponentByName("getWayText", typeof(UILabel))
	self.labelSkinDesc_ = self.groupInfo_:ComponentByName("skinEffectGroup/labelSkinDesc", typeof(UILabel))
	self.touchGroup_ = self.groupInfo_:NodeByName("skinEffectGroup/touchGroup").gameObject
	self.groupEffect2_ = self.groupInfo_:NodeByName("skinEffectGroup/groupEffect2").gameObject
	self.groupEffect1_ = self.groupInfo_:NodeByName("skinEffectGroup/groupEffect1").gameObject
	self.groupModel_ = self.groupInfo_:NodeByName("skinEffectGroup/groupModel").gameObject
	self.qltGroup = self.groupInfo_:ComponentByName("qltGroup", typeof(UISprite))
	self.labelQlt = self.qltGroup:ComponentByName("labelQlt", typeof(UILabel))
	self.labelTheme = self.groupInfo_:ComponentByName("labelTheme", typeof(UILabel))
	self.themeWords = self.groupInfo_:ComponentByName("themeWords", typeof(UILabel))

	self.bubbleRoot_:SetActive(false)

	self.partnerImg_ = ParnterImg.new(self.partnerImgRoot_)
	self.labelSkinName = self.partnerNameTagRoot_:ComponentByName("labelSkinName", typeof(UILabel))
	self.labelParnerName = self.labelSkinName:ComponentByName("labelParnerName", typeof(UILabel))
end

function CollectionSkinDetailWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_, 25, true, handler(self, self.onClickCloseButton))
	local items = {
		{
			hide_plus = true,
			id = xyd.ItemID.PARTNER_EXP
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function CollectionSkinDetailWindow:firstInit()
	self:updateData()
	self:register()
	self:initSkinEffect()

	self.attrWords_.text = __("COLLECTION_SKIN_TIP_1")
	self.getWayWords_.text = __("COLLECTION_SKIN_TIP_2")
	self.goShopBtnLabel_.text = __("SKIN_TEXT26")
	self.themeWords.text = __("COLLECTION_SKIN_TEXT06")
end

function CollectionSkinDetailWindow:initSkinEffect()
	self.skinEffect1_ = xyd.Spine.new(self.groupEffect1_)

	self.skinEffect1_:setInfo("fx_ui_fazhen", function ()
		self.skinEffect1_:play("texiao01", 0)
	end)

	self.skinEffect2_ = xyd.Spine.new(self.groupEffect2_)

	self.skinEffect2_:setInfo("fx_ui_fazhen", function ()
		self.skinEffect2_:play("texiao02", 0)
	end)
end

function CollectionSkinDetailWindow:updateData()
	self:initVars()
	self:updateBg()
	self:updateGuideArrow()
	self:updateNameTag()
	self:updateCV()
	self:updatePartnerSkin()
end

function CollectionSkinDetailWindow:initVars()
	local partner = Partner.new()
	local skinItem = self.currentSortedPartners_[self.currentIdx_]

	if not skinItem then
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	partner:populate({
		table_id = skinItem.tableID
	})

	local max_lev = partner:getMaxLev()
	local max_grade = partner:getMaxGrade()

	partner:populate({
		isHeroBook = true,
		table_id = skinItem.tableID,
		lev = max_lev,
		grade = max_grade
	})
	partner:setShowID(skinItem.skin_id)

	self.partner_ = partner
end

function CollectionSkinDetailWindow:updateBg()
	if self.partner_:getGroup() == 7 and (UNITY_EDITOR or UNITY_ANDROID and XYDUtils.CompVersion(UnityEngine.Application.version, "1.5.374") >= 0 or UNITY_IOS and XYDUtils.CompVersion(UnityEngine.Application.version, "71.3.444") >= 0) then
		if not self.partnerGravity then
			self.partnerGravity = PartnerGravityController.new(self.groupBg_.gameObject, 5)
		else
			self.partnerGravity:SetActive(true)
		end
	elseif self.partnerGravity then
		self.partnerGravity:SetActive(false)
	end

	local res = "Textures/scenes_web/college_scene" .. tostring(self.partner_:getGroup())

	if self.groupBg_.mainTexture ~= res then
		local miniBgPath = "college_scene" .. tostring(self.partner_:getGroup()) .. "_small"

		xyd.setUITextureAsync(self.groupBg_, res, nil, true)
	end

	local showID = self.partner_:getShowID()
	showID = showID or self.partner_:getTableID()

	if self.partnerImg_:getItemID() == showID then
		return
	end

	self.partnerImg_:setImg()
	self.partnerImg_:setImg({
		showResLoading = true,
		windowName = self.name,
		itemID = showID
	})

	local dragonBoneID = xyd.tables.partnerPictureTable:getDragonBone(showID)
	local xy = xyd.tables.partnerPictureTable:getPartnerPicXY(showID)
	local scale = xyd.tables.partnerPictureTable:getPartnerPicScale(showID)

	if xy and scale then
		self.partnerImg_.go.transform:SetLocalPosition(xy.x, -xy.y, 0)
		self.partnerImg_.go.transform:SetLocalScale(scale, scale, scale)
	end
end

function CollectionSkinDetailWindow:updateGuideArrow()
	if self.unableMove then
		self.arrow_left_:SetActive(false)
		self.arrow_right_:SetActive(false)

		return
	end

	if #self.currentSortedPartners_ == 1 then
		self.arrow_left_:SetActive(false)
		self.arrow_right_:SetActive(false)

		return
	end

	self.arrow_left_:SetActive(true)
	self.arrow_right_:SetActive(true)

	if self.currentIdx_ == 1 then
		self.arrow_left_:SetActive(false)
	end

	if self.currentIdx_ == #self.currentSortedPartners_ then
		self.arrow_right_:SetActive(false)
	end
end

function CollectionSkinDetailWindow:updateNameTag()
	local skinItem = self.currentSortedPartners_[self.currentIdx_]
	local name = xyd.tables.equipTextTable:getName(skinItem.skin_id)
	local partnerName = xyd.tables.partnerTextTable:getName(skinItem.tableID)
	local group = xyd.tables.partnerTable:getGroup(skinItem.tableID)
	self.labelParnerName.text = partnerName
	self.labelSkinName.text = name

	self.labelParnerName:X(self.labelSkinName.width / 2)
end

function CollectionSkinDetailWindow:updateCV()
	local name = self.partner_:getCVName()

	if name ~= nil and name then
		self.cvGroup_:SetActive(false)

		self.cvNameLabel_.text = __("CV") .. " " .. name
	else
		self.cvGroup_:SetActive(false)
	end
end

function CollectionSkinDetailWindow:updatePartnerSkin()
	local skinItem = self.currentSortedPartners_[self.currentIdx_]
	self.labelAttr_.text = xyd.tables.equipTable:getDesc(skinItem.skin_id)
	self.labelSkinDesc_.text = xyd.tables.equipTextTable:getSkinDesc(skinItem.skin_id)

	self.qltGroup:SetActive(false)
	self.labelTheme:SetActive(false)

	if skinItem.skin_id and skinItem.skin_id then
		local collectionID = xyd.tables.itemTable:getCollectionId(skinItem.skin_id)
		local qlt = xyd.tables.collectionTable:getQlt(collectionID)
		local TextArr = {
			__("COLLECTION_SKIN_TEXT13"),
			__("COLLECTION_SKIN_TEXT14"),
			__("COLLECTION_SKIN_TEXT15"),
			__("COLLECTION_SKIN_TEXT16")
		}

		if qlt and qlt > 0 then
			self.qltGroup:SetActive(true)

			self.labelQlt.text = TextArr[qlt]

			xyd.setUISpriteAsync(self.qltGroup, nil, "collection_dress_new_bg_" .. qlt)
		end

		self.themeID = xyd.tables.collectionTable:getGroup(collectionID)

		if self.themeID then
			self.labelTheme.text = xyd.tables.collectionSkinGroupTextTable:getName(self.themeID)

			self.labelTheme:SetActive(true)
		end
	end

	self:loadSkinModel()
end

function CollectionSkinDetailWindow:loadSkinModel()
	local skinItem = self.currentSortedPartners_[self.currentIdx_]
	local skinID = skinItem.skin_id
	local tableID = self.partner_:getTableID()
	local modelID = 0
	local collectionId = xyd.tables.itemTable:getCollectionId(skinID)
	modelID = xyd.tables.equipTable:getSkinModel(skinID)
	local name = xyd.tables.modelTable:getModelName(modelID)
	local scale = xyd.tables.modelTable:getScale(modelID)

	local function playGirlAni()
		self.skinModel_:setInfo(name, function ()
			self.skinModel_:SetLocalScale(scale, scale, scale)
			self.skinModel_:play("idle", 0)
		end)
	end

	if not self.skinModel_ then
		self.skinModel_ = xyd.Spine.new(self.groupModel_)
		self.skinModelID_ = modelID

		playGirlAni()
	elseif self.skinModel_ and modelID ~= self.skinModelID_ then
		NGUITools.DestroyChildren(self.groupModel_.transform)

		self.skinModel_ = xyd.Spine.new(self.groupModel_)
		self.skinModelID_ = modelID

		playGirlAni()
	end

	local canBuy = xyd.tables.collectionTable:getType2(collectionId) == 2
	local hasGot = xyd.models.collection:isGot(collectionId)

	self.goShopBtn_:SetActive(canBuy)
	self.getWayWords_.gameObject:SetActive(not canBuy)
	self.getWayText_.gameObject:SetActive(not canBuy)

	self.getWayText_.text = xyd.tables.collectionTextTable:getDesc(collectionId)
	self.LabelResNum_.text = xyd.tables.collectionTable:getCoin(collectionId)
	local gotStr = "collection_got_" .. xyd.Global.lang
	local noGotStr = "collection_no_get_" .. xyd.Global.lang

	if hasGot then
		xyd.setUISpriteAsync(self.gotImg_, nil, gotStr)
	else
		xyd.setUISpriteAsync(self.gotImg_, nil, noGotStr)
	end
end

function CollectionSkinDetailWindow:updateHasGot()
	local skinItem = self.currentSortedPartners_[self.currentIdx_]
	local skinID = skinItem.skin_id
	local collectionId = xyd.tables.itemTable:getCollectionId(skinID)
	local hasGot = xyd.models.collection:isGot(collectionId)
	local gotStr = "collection_got_" .. xyd.Global.lang
	local noGotStr = "collection_no_get_" .. xyd.Global.lang

	if hasGot then
		xyd.setUISpriteAsync(self.gotImg_, nil, gotStr)
	else
		xyd.setUISpriteAsync(self.gotImg_, nil, noGotStr)
	end
end

function CollectionSkinDetailWindow:register()
	CollectionSkinDetailWindow.super.register(self)

	UIEventListener.Get(self.arrow_left_).onClick = function ()
		self:onclickArrow(-1)
	end

	UIEventListener.Get(self.arrow_right_).onClick = function ()
		self:onclickArrow(1)
	end

	UIEventListener.Get(self.btnZoom_).onClick = handler(self, self.onclickZoom)

	UIEventListener.Get(self.partnerImgRoot_).onDragStart = function ()
		self:onTouchBegin()
	end

	UIEventListener.Get(self.partnerImgRoot_).onDrag = function (go, delta)
		self:onTouchMove(delta)
	end

	UIEventListener.Get(self.partnerImgRoot_).onDragEnd = function (go)
		self:onTouchEnd()
	end

	UIEventListener.Get(self.partnerImgRoot_).onClick = handler(self, self.onclickPartnerImg)
	UIEventListener.Get(self.touchGroup_).onClick = handler(self, self.onModelTouch)

	UIEventListener.Get(self.goShopBtn_).onClick = function ()
		local skinItem = self.currentSortedPartners_[self.currentIdx_]

		if skinItem and skinItem.skin_id then
			local currentSkinID = skinItem.skin_id
			local datas = {
				skin_id = currentSkinID
			}

			xyd.WindowManager.get():openWindow("skin_detail_buy_window", {
				id = currentSkinID,
				datas = datas
			})
		end
	end

	self.eventProxy_:addEventListener(xyd.event.GET_COLLECTION_INFO, function ()
		self:updateHasGot()
	end)
end

function CollectionSkinDetailWindow:onTouchBegin()
	self.slideXY = {
		x = 0,
		y = 0
	}
end

function CollectionSkinDetailWindow:onTouchMove(delta)
	if self.unableMove then
		return
	end

	self.slideXY.x = self.slideXY.x + delta.x
	self.slideXY.y = self.slideXY.y + delta.y

	self.groupInfo_:Y(-math.abs(self.slideXY.x))
end

function CollectionSkinDetailWindow:onTouchEnd()
	if self.unableMove then
		return
	end

	if self.slideXY.x > 50 and self.arrow_left_.activeSelf then
		self:onclickArrow(-1)
	elseif self.slideXY.x < -50 and self.arrow_right_.activeSelf then
		self:onclickArrow(1)
	else
		local action = self:getSequence()

		action:Append(self.groupInfo_.transform:DOLocalMoveY(0, 0.2))
	end
end

function CollectionSkinDetailWindow:onclickArrow(delta)
	if self.currentIdx_ + delta <= 0 or self.currentIdx_ + delta > #self.currentSortedPartners_ then
		self:playSwitchAnimation()

		return
	end

	self.currentIdx_ = self.currentIdx_ + delta

	if self.isPlaySound_ then
		xyd.SoundManager.get():stopSound(self.currentDialog_.sound)
		self.bubbleRoot_:SetActive(false)

		self.isPlaySound_ = false

		XYDCo.StopWait(self.currentDialog_.timeOutId)
	end

	self:updateData()
	self:playSwitchAnimation()
	xyd.SoundManager.get():playSound(xyd.SoundID.SWITCH_PAGE)
end

function CollectionSkinDetailWindow:playSwitchAnimation()
	local sequence = self:getSequence()
	local w = self.groupInfo_:GetComponent(typeof(UIWidget))

	local function getter()
		return w.color
	end

	local function setter(color)
		w.color = color
	end

	local originY = 0

	sequence:Insert(0, self.groupInfo_.transform:DOLocalMoveY(-600, 0.2))
	sequence:Insert(0.2, self.groupInfo_.transform:DOLocalMoveY(originY, 0.2))
	sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 0.1))
	sequence:Insert(0.1, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.1))
end

function CollectionSkinDetailWindow:onclickZoom(event)
	local showID = self.partner_:getShowID()
	showID = showID or self.partner_:getTableID()
	local res = nil

	if xyd.Global.usePvr then
		res = "college_scene" .. self.partner_:getGroup() .. "_pvr"
	else
		res = "college_scene" .. self.partner_:getGroup()
	end

	xyd.WindowManager.get():openWindow("partner_detail_zoom_window", {
		item_id = showID,
		bg_source = res,
		group = self.partner_:getGroup()
	})
end

function CollectionSkinDetailWindow:onclickPartnerImg()
	if xyd.tables.partnerTable:checkPuppetPartner(self.partner_:getTableID()) then
		return
	end

	if self.bubbleRoot_.activeSelf then
		return
	end

	if self.isPlaySound_ then
		return
	end

	self.bubbleRoot_:SetActive(true)

	local clickSoundNum = xyd.tables.partnerTable:getClickSoundNum(self.partner_:getTableID(), self.partner_:getShowID())
	local rand = math.floor(math.random() * clickSoundNum + 0.5) + 1
	local index = clickSoundNum < rand and rand - clickSoundNum or rand
	local dialogInfo = xyd.tables.partnerTable:getClickDialogInfo(self.partner_:getTableID(), index, self.partner_:getShowID())

	if self.currentDialog_ and dialogInfo.sound == self.currentDialog_.sound then
		index = clickSoundNum < index + 1 and index - (clickSoundNum - 1) or index + 1
		dialogInfo = xyd.tables.partnerTable:getClickDialogInfo(self.partner_:getTableID(), index, self.partner_:getShowID())
	end

	self.isPlaySound_ = true
	self.tips_.text = dialogInfo.dialog
	dialogInfo.timeOutId = self:setTimeout(function ()
		self.isPlaySound_ = false

		self.bubbleRoot_:SetActive(false)
	end, self, dialogInfo.time * 1000)
	self.currentDialog_ = dialogInfo
end

function CollectionSkinDetailWindow:onModelTouch()
	if not self.skinModel_ or not self.skinModel_:isValid() then
		return
	end

	local tableID = self.partner_:getTableID()
	local mp = xyd.tables.partnerTable:getEnergyID(tableID)
	local ack = xyd.tables.partnerTable:getPugongID(tableID)
	local skillID = 0

	if xyd.getServerTime() % 2 > 0 then
		skillID = mp

		if tableID ~= 755005 and tableID ~= 55006 and tableID ~= 655015 then
			self.skinModel_:play("skill", 1, 1, function ()
				self.skinModel_:play("idle", 0)
			end)
		else
			self.skinModel_:play("skill01", 1, 1, function ()
				self.skinModel_:play("idle", 0)
			end)
		end
	else
		skillID = ack

		self.skinModel_:play("attack", 1, 1, function ()
			self.skinModel_:play("idle", 0)
		end)
	end

	if self.skillSound_ then
		xyd.SoundManager.get():stopSound(self.skillSound_)
	end

	self.skillSound_ = tostring(xyd.tables.skillTable:getSound(skillID))

	xyd.SoundManager.get():playSound(self.skillSound_)
end

function CollectionSkinDetailWindow:willClose()
	CollectionSkinDetailWindow.super.willClose(self)

	if self.isPlaySound_ then
		xyd.SoundManager.get():stopSound(self.currentDialog_.sound)

		self.isPlaySound_ = false
	end
end

return CollectionSkinDetailWindow
