local BaseWindow = import(".BaseWindow")
local BackgroundPreviewWindow = class("BackgroundPreviewWindow", BaseWindow)
local PartnerImg = import("app.components.PartnerImg")
local WindowTop = import("app.components.WindowTop")

function BackgroundPreviewWindow:ctor(name, params)
	self.isCollection = params.isCollection

	BaseWindow.ctor(self, name, params)

	self.timelinelite_pool_ = {}
	self.destory_list_ = {}
	self.timeout_id_ = nil
	self.hide_status_ = 0
	self.scroller_x_ = 0
	self.destory_loading_list_ = {}
	self.skinName = "BackgroundPreviewWindowSkin"
	self.id_ = params.id
end

function BackgroundPreviewWindow:getCurPic()
	return self.id_
end

function BackgroundPreviewWindow:getScreenHeight()
	local width, height = xyd.getScreenSize()

	if height > 1458 then
		height = 1458
	end

	if UnityEngine.Screen.height / UnityEngine.Screen.width > xyd.Global.getRealHeight() / xyd.Global.getRealWidth() then
		return xyd.Global.getMaxBgHeight()
	end

	return height
end

function BackgroundPreviewWindow:layout()
	self:hideBottom()
	self:hideHideBtn()
	self:hideLeft()
	self:hideRight()

	self.windowTop = WindowTop.new(self.window_, self.name_, 10)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
	self.windowTop:setTitle(__("BIG_MAP"))

	self.topY = self.windowTop.go.transform.localPosition.y
	UIEventListener.Get(self.leftArr).onClick = handler(self, function ()
		self:nextPage(-1)
	end)
	UIEventListener.Get(self.rightArr).onClick = handler(self, function ()
		self:nextPage(1)
	end)

	xyd.setDarkenBtnBehavior(self.hideBtn, self, function ()
		if not self.timeout_key_ then
			self:hideUI()
		else
			self:showUI()
			XYDCo.StopWait(self.timeout_key_)

			self.timeout_key_ = nil
		end
	end)
	xyd.setDarkenBtnBehavior(self.showPartnerBtn, self, function ()
		if not self.partnerImg then
			self:initPartner()
		end

		local flag = nil

		print(tostring(self.partnerGroup.activeSelf))

		flag = not self.partnerGroup.activeSelf

		self.partnerGroup:SetActive(flag)
		print(tostring(self.partnerGroup.activeSelf))

		if self.partnerGroup.activeSelf == true then
			xyd.setUISpriteAsync(self.showPartnerBtnBgImg, nil, "background_partner_show_btn1", function ()
			end)
		else
			xyd.setUISpriteAsync(self.showPartnerBtnBgImg, nil, "background_partner_show_btn0", function ()
			end)
		end
	end)
	xyd.setDarkenBtnBehavior(self.showEffectBtn, self, function ()
		if not self:checkHasEffect() then
			xyd.showToast(__("BACKGROUND_TEXT07"))

			return
		end

		if not xyd.models.background:checkOwn(self.id_) then
			xyd.showToast(__("BACKGROUND_TEXT08"))

			return
		end

		self.effectGroup:SetActive(not self.effectGroup.activeSelf)

		if self.effectGroup.activeSelf then
			if self.effectGroup.transform.childCount == 0 then
				xyd.setUISpriteAsync(self.showEffectBtnBgImg, nil, "background_effect_show_btn1")

				local effect = xyd.Spine.new(self.effectGroup)
				local spineName = xyd.tables.customBackgroundTable:getEffect(self.id_)

				effect:setInfo(spineName, function ()
					local animation = xyd.tables.customBackgroundTable:getAnimation(self.id_)
					local height = self:getScreenHeight()
					local effect_scale = height / self.bgImg.height * 0.656 * 1.0517241379310345

					effect:SetLocalScale(effect_scale, effect_scale, 1)

					local effect_offset = xyd.tables.customBackgroundTable:getOffset(self.id_)
					local effect_offect_scale = height / self.bgImg.height / 1.25

					if effect_offset then
						self.effectGroup.transform:SetLocalPosition(effect_offset[1] * effect_offect_scale, -effect_offset[2] * effect_offect_scale, 0)
					end

					effect:play(animation, 0)

					local src = tostring(xyd.tables.customBackgroundTable:getEffectBackground(self.id_))

					xyd.setUITextureByNameAsync(self.bgImg, src, true, function ()
						local height = self:getScreenHeight()
						local scale = height / self.bgImg.height

						self.bgImg:SetLocalScale(scale, scale, 1)
					end)
					self.bgImg:SetActive(true)
				end)

				return
			end

			local src = tostring(xyd.tables.customBackgroundTable:getEffectBackground(self.id_))

			xyd.setUITextureByNameAsync(self.bgImg, src, true, function ()
				local height = self:getScreenHeight()
				local scale = height / self.bgImg.height

				self.bgImg:SetLocalScale(scale, scale, 1)
			end)
			self.bgImg:SetActive(true)
		else
			xyd.setUISpriteAsync(self.showEffectBtnBgImg, nil, "background_effect_show_btn0")

			local src = xyd.tables.customBackgroundTable:getPicture(self.id_)

			xyd.setUITextureByNameAsync(self.bgImg, src, true, function ()
				local height = self:getScreenHeight()
				local scale = height / self.bgImg.height

				self.bgImg:SetLocalScale(scale, scale, 1)
			end)
		end
	end)

	UIEventListener.Get(self.slideGroup).onDrag = function (go, delta)
		self.scroller_x_ = self.scroller_x_ + delta.x
	end

	UIEventListener.Get(self.touchGroup).onDrag = function (go, delta)
		self.scroller_x_ = self.scroller_x_ + delta.x
	end

	UIEventListener.Get(self.touchGroup).onDragEnd = function (go)
		self:onTouchEnd()
	end

	UIEventListener.Get(self.slideGroup).onDragEnd = function (go)
		self:onTouchEnd()
	end

	UIEventListener.Get(self.touchGroup).onClick = handler(self, function ()
		self:onTouchEnd()
	end)

	xyd.setDarkenBtnBehavior(self.setBtn, self, function ()
		if xyd.models.background:checkOwn(self.id_) then
			local type = xyd.tables.customBackgroundTable:getType(self.id_)

			if type == 1 then
				xyd.models.background:reqChooseBg(self.id_)
			else
				local in_use = xyd.models.background:checkInUse(self.id_)

				if in_use and in_use ~= 0 then
					self.destory_list_[self.id_] = 1
				end

				local effect = xyd.tables.customBackgroundTable:getEffect(self.id_)

				if effect and #effect > 0 and not xyd.models.background:checkInUse(self.id_) then
					xyd.WindowManager.get():openWindow("background_preview_confirm_window", {
						id = self.id_
					})
				else
					xyd.models.background:reqAddSelect(self.id_)
				end
			end
		elseif xyd.models.background:checkLock(self.id_) then
			xyd.showToast(__("BACKGROUND_LOCK"))

			return
		else
			local cost = xyd.tables.customBackgroundTable:getPrice(self.id_)

			if cost[1] and cost[2] and xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(cost[1])))

				return
			else
				local win = xyd.WindowManager.get():getWindow("alert_window")

				if win then
					xyd.WindowManager.get():closeWindow("alert_window", function ()
						xyd.WindowManager.get():openWindow("alert_window", {
							alertType = xyd.AlertType.YES_NO,
							message = __("BACKGROUND_CONFIRM"),
							callback = function (flag)
								if not flag then
									return
								end

								xyd.models.background:reqBuyBackground(self.id_)
							end
						})
					end)
				else
					xyd.WindowManager.get():openWindow("alert_window", {
						alertType = xyd.AlertType.YES_NO,
						message = __("BACKGROUND_CONFIRM"),
						callback = function (flag)
							if not flag then
								return
							end

							xyd.models.background:reqBuyBackground(self.id_)
						end
					})
				end
			end
		end
	end)
	self.eventProxy_:addEventListener(xyd.event.BUY_BACKGROUND, function (event)
		local data = event.data

		if tonumber(data.table_id) == tonumber(self.id_) then
			self:setLayout()
		end
	end)
	self.eventProxy_:addEventListener(xyd.event.SET_BACKGROUND, function ()
		self:setLayout()
	end)
	self:setLayout(true)
	self:deleteRetResource()
	self:collectionModeLayout()
end

function BackgroundPreviewWindow:collectionModeLayout()
	if self.isCollection then
		self.collection:SetActive(true)

		self.descLabel.alignment = NGUIText.Alignment.Left

		self.setBtn:SetActive(false)
	end
end

function BackgroundPreviewWindow:showEffect(is_first)
	if is_first == nil then
		is_first = false
	end

	self.touchRejectGroup:SetActive(false)
	self.btnMoveGroup:SetActive(true)
	self.bottomGroup:SetActive(true)

	if is_first then
		self:showLeft()
		self:showRight()
	end

	self:showBottom()
	self:showHideBtn()
end

function BackgroundPreviewWindow:deleteRetResource()
	local type = xyd.tables.customBackgroundTable:getType(self.id_)

	if type == 1 then
		self.showEffectBtn:SetActive(false)
	else
		self.showPartnerBtn:SetActive(false)
	end
end

function BackgroundPreviewWindow:checkHasEffect()
	local effect = xyd.tables.customBackgroundTable:getEffect(self.id_)

	if effect and #effect ~= 0 then
		return true
	else
		return false
	end
end

function BackgroundPreviewWindow:onTouchEnd(event)
	if self.scroller_x_ and self.scroller_x_ < -20 then
		self:nextPage(1)
	elseif self.scroller_x_ and self.scroller_x_ > 20 then
		self:nextPage(-1)
	elseif self.hide_status_ == 1 then
		self:showHideBtn()

		self.timeout_key_ = "HIDE_BTN_KEY"

		self:waitForTime(3, function ()
			self:hideHideBtn()
		end, self.timeout_key_)
	end
end

function BackgroundPreviewWindow:nextPage(delta)
	local next = xyd.models.background:getNext(self.id_, delta)

	if next == nil then
		return
	end

	self.scroller_x_ = 0

	XYDCo.StopWait(self.timeout_key_)

	self.id_ = tonumber(next)

	self.bottomGroup:SetActive(false)
	self.btnMoveGroup:SetActive(false)
	self:hideBottom()
	self:hideHideBtn()
	self.touchRejectGroup:SetActive(true)
	xyd.models.background:resetNew(self.id_, xyd.tables.customBackgroundTable:getType(self.id_))
	self:setLayout()
end

function BackgroundPreviewWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
end

function BackgroundPreviewWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.bgImg = winTrans:ComponentByName("bgImg", typeof(UITexture))
	self.maskRect = winTrans:ComponentByName("maskRect", typeof(UISprite))
	self.lockImg = winTrans:ComponentByName("lockImg", typeof(UISprite))
	self.partnerGroup = winTrans:NodeByName("partnerGroup").gameObject
	self.effectGroup = winTrans:NodeByName("effectGroup").gameObject
	self.slideGroup = winTrans:NodeByName("slideGroup").gameObject
	self.leftArr = winTrans:NodeByName("leftArr").gameObject
	self.rightArr = winTrans:NodeByName("rightArr").gameObject
	self.bottomGroup = winTrans:NodeByName("bottom/bottomGroup").gameObject
	self.nameLabel = self.bottomGroup:ComponentByName("nameLabel", typeof(UILabel))
	self.descLabel = self.bottomGroup:ComponentByName("descLabel", typeof(UILabel))
	local btnsGroup = self.bottomGroup:NodeByName("btnsGroup").gameObject
	self.showPartnerBtn = btnsGroup:NodeByName("showPartnerBtn").gameObject
	self.showPartnerBtnBgImg = btnsGroup:ComponentByName("showPartnerBtn", typeof(UISprite))
	self.showEffectBtn = btnsGroup:NodeByName("showEffectBtn").gameObject
	self.showEffectBtnBgImg = btnsGroup:ComponentByName("showEffectBtn", typeof(UISprite))
	self.setBtn = self.bottomGroup:NodeByName("setBtn").gameObject
	self.setBtnBgImg = self.setBtn:GetComponent(typeof(UISprite))
	self.labelDisplay = self.setBtn:ComponentByName("button_label", typeof(UILabel))
	self.contentGroup1 = self.setBtn:NodeByName("contentGroup1").gameObject
	self.contentGroupLayout1 = self.contentGroup1:GetComponent(typeof(UILayout))
	self.labelDisplay1 = self.contentGroup1:ComponentByName("labelDisplay1", typeof(UILabel))
	self.itemGroup = self.contentGroup1:NodeByName("itemGroup").gameObject
	self.iconImg = self.itemGroup:ComponentByName("iconImg", typeof(UISprite))
	self.countLabel = self.itemGroup:ComponentByName("countLabel", typeof(UILabel))
	self.labelDisplay2 = self.contentGroup1:ComponentByName("labelDisplay2", typeof(UILabel))
	self.contentGroup2 = self.setBtn:NodeByName("contentGroup2").gameObject
	self.contentGroupLayout2 = self.contentGroup2:GetComponent(typeof(UILayout))
	self.itemGroup2 = self.contentGroup2:NodeByName("itemGroup2").gameObject
	self.iconImg2 = self.itemGroup2:ComponentByName("iconImg2", typeof(UISprite))
	self.countLabel2 = self.itemGroup2:ComponentByName("countLabel2", typeof(UILabel))
	self.labelDisplay3 = self.contentGroup2:ComponentByName("labelDisplay3", typeof(UILabel))
	self.touchGroup = winTrans:NodeByName("touchGroup").gameObject
	self.touchRejectGroup = winTrans:NodeByName("touchRejectGroup").gameObject
	self.btnMoveGroup = winTrans:NodeByName("bottom/btnMoveGroup").gameObject
	self.hideBtn = self.btnMoveGroup:NodeByName("hideBtnGroup/hideBtn").gameObject
	self.collection = winTrans:NodeByName("bottom/bottomGroup/collection").gameObject
	self.gotImg = self.collection:ComponentByName("gotImg", typeof(UISprite))
	self.resItem = self.collection:NodeByName("resItem").gameObject
	self.specialImg = winTrans:ComponentByName("specialImg", typeof(UITexture))
end

function BackgroundPreviewWindow:addDestory()
end

function BackgroundPreviewWindow:deleteRes(id)
	local name = xyd.tables.customBackgroundTable:getPicture(id)
end

function BackgroundPreviewWindow:setLayout(is_first)
	if is_first == nil then
		is_first = false
	end

	local s = self:getSource()

	xyd.setUITextureByNameAsync(self.bgImg, self:getSource(), true, function ()
		if tolua.isnull(self.window_) then
			return
		end

		local height = self:getScreenHeight()
		local scale = height / self.bgImg.height

		self.bgImg:SetLocalScale(scale, scale, 1)
		self:addDestory()

		local tt = xyd.tables.customBackgroundTable:getType(self.id_)

		xyd.models.background:resetNew(self.id_, tt)
		xyd.models.background:resetRed(self.id_)

		local win = xyd.WindowManager.get():getWindow("background_window")

		if win then
			win:refreshState(self.id_, {})
		end

		local group_win = xyd.WindowManager.get():getWindow("background_group_window")

		if group_win then
			group_win:buildCollection()
		end

		local next = xyd.models.background:getNext(self.id_, 1)

		if next == nil then
			self.rightArr:SetActive(false)
		else
			self.rightArr:SetActive(true)
		end

		local pre = xyd.models.background:getNext(self.id_, -1)

		if pre == nil then
			self.leftArr:SetActive(false)
		else
			self.leftArr:SetActive(true)
		end

		self:showEffect(is_first)

		local bg_offset = xyd.tables.customBackgroundTable:getPictureOffset(self.id_)

		self.bgImg.transform:SetLocalPosition(bg_offset[1] or 0, bg_offset[2] or 0, 0)
		self.effectGroup:SetActive(false)
		NGUITools.DestroyChildren(self.effectGroup.transform)
		xyd.setUISpriteAsync(self.showEffectBtnBgImg, nil, "background_effect_show_btn0", function ()
		end)

		if xyd.models.background:checkLock(self.id_) then
			self.lockImg:SetActive(true)
			self.maskRect:SetActive(true)

			self.maskRect.alpha = 0.4
		else
			self.lockImg:SetActive(false)
			self.maskRect:SetActive(false)
		end

		if self.isCollection then
			self.lockImg:SetActive(false)
			self.maskRect:SetActive(false)
		end

		local model = xyd.models.background

		self.labelDisplay:SetActive(false)
		self.contentGroup1:SetActive(false)
		self.contentGroup2:SetActive(false)

		local type = xyd.tables.customBackgroundTable:getType(self.id_)

		if model:checkInUse(self.id_) then
			xyd.setUISpriteAsync(self.setBtnBgImg, nil, "white_btn_65_65", function ()
			end)

			if type == xyd.BackgroundType.BACKGROUND then
				self.labelDisplay.text = __("BACKGROUND_TEXT01")
			else
				self.labelDisplay.text = __("BACKGROUND_TEXT09")
			end

			self.labelDisplay:SetActive(true)

			local c = self.setBtn:GetComponent(typeof(UnityEngine.BoxCollider))

			if type == 1 then
				c.enabled = false
			else
				c.enabled = true
			end

			if type == xyd.BackgroundType.BACKGROUND then
				self.labelDisplay.color = Color.New2(1012112383)
				self.labelDisplay.effectColor = Color.New2(4294967295.0)
			else
				xyd.setUISpriteAsync(self.setBtnBgImg, nil, "blue_btn_65_65", function ()
				end)

				self.labelDisplay.color = Color.New2(4294967295.0)
				self.labelDisplay.effectColor = Color.New2(1012112383)
			end
		elseif model:checkOwn(self.id_) then
			xyd.setUISpriteAsync(self.setBtnBgImg, nil, "blue_btn_65_65", function ()
			end)

			self.labelDisplay.color = Color.New2(4294967295.0)
			self.labelDisplay.effectColor = Color.New2(1012112383)

			if type == xyd.BackgroundType.BACKGROUND then
				self.labelDisplay.text = __("BACKGROUND_TEXT02")
			else
				self.labelDisplay.text = __("BACKGROUND_TEXT10")
			end

			self.labelDisplay:SetActive(true)

			local c = self.setBtn:GetComponent(typeof(UnityEngine.BoxCollider))
			c.enabled = true
		else
			xyd.setUISpriteAsync(self.setBtnBgImg, nil, "white_btn_65_65", function ()
			end)

			self.labelDisplay.color = Color.New2(1012112383)
			self.labelDisplay.effectColor = Color.New2(4294967295.0)
			local cost = xyd.tables.customBackgroundTable:getPrice(self.id_)
			local c = self.setBtn:GetComponent(typeof(UnityEngine.BoxCollider))
			c.enabled = true

			if model:checkLock(self.id_) then
				if cost and #cost > 0 then
					self.labelDisplay1.text = __("BACKGROUND_TEXT04")

					if xyd.Global.lang == "fr_fr" then
						self.labelDisplay1.fontSize = 18
					end

					xyd.setUISpriteAsync(self.iconImg, nil, xyd.tables.itemTable:getIcon(cost[1]), function ()
					end)

					self.countLabel.text = xyd.getRoughDisplayNumber(tonumber(cost[2]))
					self.labelDisplay2.text = __("BACKGROUND_TEXT05")

					self.contentGroup1:SetActive(true)
					self.contentGroupLayout1:Reposition()
				else
					self.labelDisplay.text = __("BACKGROUND_TEXT03")

					self.labelDisplay:SetActive(true)
				end
			elseif cost and #cost > 0 then
				xyd.setUISpriteAsync(self.iconImg2, nil, xyd.tables.itemTable:getIcon(cost[1]), function ()
				end)

				self.countLabel2.text = xyd.getRoughDisplayNumber(tonumber(cost[2]))
				self.labelDisplay3.text = __("BACKGROUND_TEXT05")

				self.contentGroup2:SetActive(true)
				self.contentGroupLayout2:Reposition()
			else
				self.labelDisplay.text = __("BACKGROUND_TEXT06")

				self.labelDisplay:SetActive(true)
			end
		end

		if self.isCollection then
			local collectionId = xyd.models.collection:getBgCollectionId(self.id_)
			self.resItem:ComponentByName("labelRes", typeof(UILabel)).text = xyd.tables.collectionTable:getCoin(collectionId)

			self.gotImg:SetActive(true)

			local gotStr = "collection_got_" .. xyd.Global.lang
			local noGotStr = "collection_no_get_" .. xyd.Global.lang

			if xyd.models.collection:isGot(collectionId) then
				xyd.setUISpriteAsync(self.gotImg, nil, gotStr)
			else
				xyd.setUISpriteAsync(self.gotImg, nil, noGotStr)
			end

			self.setBtn:SetActive(false)
		end
	end)

	if self.id_ == 40 then
		self.specialImg:SetActive(true)
		xyd.setUITextureByNameAsync(self.specialImg, "chunjie_" .. xyd.Global.lang, true)
	else
		self.specialImg:SetActive(false)
	end

	local showID = xyd.models.selfPlayer:getPictureID()
	local xy = xyd.tables.partnerPictureTable:getPartnerPicXY(showID)

	self.partnerGroup:Y(-xy.y)

	local info = self:getTextInfo()
	self.nameLabel.text = info.name
	self.descLabel.text = info.desc

	if self.id_ == xyd.ParticularBackground.DaoChang and not self.isCollection then
		self:setDojoText()
	end
end

function BackgroundPreviewWindow:setDojoText()
	local str = xyd.tables.customBackgroundTextTable:getText(self.id_)
	local data = xyd.models.background:getItemData(self.id_)
	local count_ = 0
	local is_complete = 0

	if data then
		count_ = data.count
		is_complete = data.is_complete
	end

	if is_complete ~= 0 then
		count_ = xyd.tables.customBackgroundTable:getUnclockValue(self.id_)
	end

	self.descLabel.text = xyd.stringFormat(str, count_)
end

function BackgroundPreviewWindow:getSource()
	return tostring(xyd.tables.customBackgroundTable:getPicture(self.id_))
end

function BackgroundPreviewWindow:getTextInfo()
	local name = xyd.tables.customBackgroundTextTable:getName(self.id_)
	local desc = xyd.tables.customBackgroundTextTable:getText(self.id_)

	if self.isCollection then
		local collectionId = xyd.models.collection:getBgCollectionId(self.id_)
		desc = xyd.tables.collectionTextTable:getDesc(collectionId)
	end

	return {
		name = name,
		desc = desc
	}
end

function BackgroundPreviewWindow:initPartner()
	if not self.partnerImg then
		self.partnerImg = PartnerImg.new(self.partnerGroup)
	else
		return
	end

	local id = xyd.models.selfPlayer:getPictureID()

	self.partnerImg:setImg({
		itemID = xyd.models.selfPlayer:getPictureID()
	})

	local scale = xyd.tables.partnerPictureTable:getPartnerPicScale(id)

	self.partnerImg:SetLocalScale(scale, scale, 1)

	local xy = xyd.tables.partnerPictureTable:partnerPictureXy2(id)

	if not self.pMoveSequence then
		local transform = self.partnerImg:getGameObject().transform
		local posY = transform.localPosition.y - 10
		self.pMoveSequence = self:getSequence()

		self.pMoveSequence:SetLoops(-1)
		self.pMoveSequence:Append(transform:DOLocalMoveY(posY - 10, 3)):Append(transform:DOLocalMoveY(posY + 10, 3))
	end
end

function BackgroundPreviewWindow:hideUI()
	self:hideTop()
	self:hideBottom()
	self:hideLeft()
	self:hideRight()
	self:hideHideBtn()
end

function BackgroundPreviewWindow:hideTop()
	if not self.topSeq then
		self.topSeq = self:getSequence()
	end

	local y = self.topY

	self.topSeq:Append(self.windowTop.go.transform:DOLocalMoveY(y + 160, 0.2))
end

function BackgroundPreviewWindow:hideBottom()
	if not self.bottomSeq then
		self.bottomSeq = self:getSequence()
	end

	local y = self.bottomGroup.transform.localPosition.y
	local h = self.bottomGroup:GetComponent(typeof(UIWidget)).localSize.y

	self.bottomSeq:Append(self.bottomGroup.transform:DOLocalMoveY(-y - h - 50, 0.2))
end

function BackgroundPreviewWindow:hideLeft()
	if not self.leftSeq then
		self.leftSeq = self:getSequence()
	end

	local left = self.leftArr:GetComponent(typeof(UIWidget)).localSize.x
	local x = self.leftArr.transform.localPosition.x

	self.leftSeq:Append(self.leftArr.transform:DOLocalMoveX(x - left - 100, 0.2))
end

function BackgroundPreviewWindow:hideRight()
	if not self.rightSeq then
		self.rightSeq = self:getSequence()
	end

	local right = self.rightArr:GetComponent(typeof(UIWidget)).localSize.x
	local x = self.rightArr.transform.localPosition.x

	self.rightSeq:Append(self.rightArr.transform:DOLocalMoveX(x + right + 50, 0.2))
end

function BackgroundPreviewWindow:hideHideBtn()
	if not self.hideBtnSeq then
		self.hideBtnSeq = self:getSequence()
	end

	self.hide_status_ = 1

	self.touchGroup:SetActive(true)

	local c = self.touchGroup:GetComponent(typeof(UnityEngine.BoxCollider))

	c:SetActive(true)

	local y = self.btnMoveGroup.transform.localPosition.y
	local h = self.btnMoveGroup:GetComponent(typeof(UIWidget)).localSize.y

	self.hideBtnSeq:Append(self.btnMoveGroup.transform:DOLocalMoveY(-y - h - 50, 0.2))
end

function BackgroundPreviewWindow:showHideBtn()
	if not self.hideBtnSeq2 then
		self.hideBtnSeq2 = self:getSequence()
	end

	self.hide_status_ = 0

	self.hideBtnSeq2:Append(self.btnMoveGroup.transform:DOLocalMoveY(184, 0.2))
	self.hideBtnSeq2:AppendCallback(function ()
		self:delSequene(self.hideBtnSeq2)
		self.touchGroup:SetActive(false)

		self.hideBtnSeq2 = nil
	end)
end

function BackgroundPreviewWindow:showUI()
	self:showTop()
	self:showBottom()
	self:showLeft()
	self:showRight()
end

function BackgroundPreviewWindow:showTop()
	if not self.topSeq then
		self.topSeq = self:getSequence()
	end

	local y = self.topY

	self.topSeq:Append(self.windowTop.go.transform:DOLocalMoveY(y, 0.2))
end

function BackgroundPreviewWindow:showBottom()
	if not self.bottomSeq then
		self.bottomSeq = self:getSequence()
	end

	self.bottomSeq:Append(self.bottomGroup.transform:DOLocalMoveY(184, 0.2))
end

function BackgroundPreviewWindow:showLeft()
	if not self.leftSeq then
		self.leftSeq = self:getSequence()
	end

	self.leftSeq:Append(self.leftArr.transform:DOLocalMoveX(-334, 0.2))
end

function BackgroundPreviewWindow:showRight()
	if not self.rightSeq then
		self.rightSeq = self:getSequence()
	end

	self.rightSeq:Append(self.rightArr.transform:DOLocalMoveX(334, 0.2))
end

function BackgroundPreviewWindow:didClose(params)
	BaseWindow.didClose(self, params)
end

return BackgroundPreviewWindow
