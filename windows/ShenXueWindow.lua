local HeroIcon = import("app.components.HeroIcon")
local PartnerIcon = class("PartnerIcon")

function PartnerIcon:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.heroIcon = HeroIcon.new(go)

	self.heroIcon:setDragScrollView(parent.scrollView)
end

function PartnerIcon:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self.heroIcon:setInfo(info)

	if self.parent.choosePartners[info.tableID] then
		self.heroIcon.choose = true
	else
		self.heroIcon.choose = false
	end
end

function PartnerIcon:getGameObject()
	return self.go
end

local BaseWindow = import(".BaseWindow")
local ShenXueWindow = class("ShenXueWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PartnerNameTag = import("app.components.PartnerNameTag")
local WindowTop = import("app.components.WindowTop")
local PartnerImg = import("app.components.PartnerImg")

function ShenXueWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.callback = nil
	self.PartnerTable = xyd.tables.partner
	self.SlotModel = xyd.models.slot
	self.ShenXueModel = xyd.models.shenxue
	self.materialIdList_ = {}
	self.allOptionalList_ = {}
	self.selectedList_ = {}
	self.hostOptionalList_ = {}
	self.mateOptionalList_ = {}
	self.materialKeyList_ = {}
	self.tmpAllOptionalList_ = {}
	self.tmpSelectedList_ = {}
	self.modelList = {}
	self.partnerImgY = 0
	self.isInDialog = false
	self.curIndex = 0
	self.BtnState = {
		"left",
		"mid",
		"mid",
		"mid",
		"mid",
		"right"
	}
	self.currentState = xyd.Global.lang
	self.icons = {}
	self.choosePartners = {}
	self.selectTableID_ = 0
end

function ShenXueWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.top = winTrans:NodeByName("top").gameObject
	self.gAnimation = winTrans:NodeByName("gAnimation").gameObject
	local middle = self.gAnimation:NodeByName("middle").gameObject
	local pictureContainer = middle:NodeByName("pictureContainer").gameObject
	self.partnerImg = PartnerImg.new(pictureContainer)
	self.groupBubble_ = middle:NodeByName("groupBubble_").gameObject
	self.bubbleText_ = self.groupBubble_:ComponentByName("bubbleText_", typeof(UILabel))
	local groupMain = self.gAnimation:NodeByName("groupMain_").gameObject
	local tabGroup = groupMain:NodeByName("tabGroup").gameObject

	for i = 1, 6 do
		local group = tabGroup:NodeByName("group" .. i).gameObject
		self["group" .. i] = group
		self["img" .. i] = group:ComponentByName("img", typeof(UISprite))
		self["label" .. i] = group:ComponentByName("label", typeof(UILabel))
	end

	local groupNameContainer = groupMain:NodeByName("groupName_").gameObject
	self.groupName_ = PartnerNameTag.new(groupNameContainer)
	self.helpBtn = groupMain:NodeByName("helpBtn").gameObject
	self.groupDetail_ = groupMain:NodeByName("groupDetail_").gameObject
	self.detailBtn = self.groupDetail_:NodeByName("detailBtn").gameObject
	local rightGroup = groupMain:NodeByName("rightGroup").gameObject
	local scrollView = rightGroup:ComponentByName("partnerListScroller", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("partnerListVS", typeof(UIWrapContent))
	local iconContainer = scrollView:NodeByName("iconContainer").gameObject
	self.wrapContent = FixedWrapContent.new(scrollView, wrapContent, iconContainer, PartnerIcon, self)
	self.midShowGroup = groupMain:NodeByName("midShowGroup").gameObject

	for i = 1, 4 do
		local selectGroup = self.midShowGroup:NodeByName("selectGroup" .. i).gameObject
		self["selectGroup" .. i] = selectGroup
		self["effectGroup" .. i] = selectGroup:NodeByName("effectGroup").gameObject
		self["iconContainer" .. i] = selectGroup:NodeByName("iconContainer" .. i).gameObject
		self["redPointImg" .. i] = selectGroup:NodeByName("redPointImg" .. i).gameObject
		self["plusIcon" .. i] = selectGroup:ComponentByName("plusIcon" .. i, typeof(UISprite))
		self["labelNum" .. i] = selectGroup:ComponentByName("labelNum" .. i, typeof(UILabel))
	end

	self.shenXueBtn = groupMain:NodeByName("shenXueBtn").gameObject
	self.shenXueBtnLabel = self.shenXueBtn:ComponentByName("button_label", typeof(UILabel))
	self.autoBtn = groupMain:NodeByName("autoBtn").gameObject
	self.autoImg = self.autoBtn:ComponentByName("autoImg", typeof(UISprite))
	self.autoLabel = self.autoBtn:ComponentByName("label", typeof(UILabel))
	self.autoStar5Btn = groupMain:NodeByName("autoStar5Btn").gameObject
	self.autoStar5Img = self.autoStar5Btn:ComponentByName("autoImg", typeof(UISprite))
	self.autoStar5Label = self.autoStar5Btn:ComponentByName("label", typeof(UILabel))
	self.batchShenXueBtn = groupMain:NodeByName("batchShenXueBtn").gameObject
	self.batchShenXueRedPoint = self.batchShenXueBtn:ComponentByName("redPoint", typeof(UISprite))
end

function ShenXueWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initLayOut()
	self:register()
	self:updateAutoBtn()
	self:updateBatchShenXueBtn()
	self:waitForFrame(2, handler(self, self.startAnimation), nil)
end

function ShenXueWindow:updateAutoBtn()
	local state = xyd.db.misc:getValue("shenxue_auto_4_star")
	local star = xyd.tables.partnerTable:getStar(self.selectTableID_)

	if star == 5 then
		self.autoBtn:SetActive(true)
	else
		self.autoBtn:SetActive(false)
	end

	if state == "1" then
		xyd.setUISpriteAsync(self.autoImg, nil, "setting_up_pick")
	else
		xyd.setUISpriteAsync(self.autoImg, nil, "setting_up_unpick")
	end

	local stateStar5 = xyd.db.misc:getValue("shenxue_auto_5_star")

	if star == 6 then
		self.autoStar5Btn:SetActive(true)
	else
		self.autoStar5Btn:SetActive(false)
	end

	if stateStar5 == "1" then
		xyd.setUISpriteAsync(self.autoStar5Img, nil, "setting_up_pick")
	else
		xyd.setUISpriteAsync(self.autoStar5Img, nil, "setting_up_unpick")
	end
end

function ShenXueWindow:updateBatchShenXueBtn()
	if not self.forgetList then
		return
	end

	self.batchShenXueRedState = false
	local partners = xyd.models.slot:getPartners()

	for key in pairs(partners) do
		if partners[key]:getStar() == 4 and not partners[key]:isLockFlag() then
			local tableID = partners[key]:getTableID()
			local star5TableID = xyd.tables.partnerTable:getShenxueTableId(tableID)
			local material = xyd.split(xyd.tables.partnerTable:getMaterial(star5TableID), "|", true)
			local material_detail = {}

			for keyid, mTableID in pairs(material) do
				if not material_detail[mTableID] then
					material_detail[mTableID] = {}
				end

				if mTableID % 1000 == 999 then
					local star = xyd.tables.partnerIDRuleTable:getStar(mTableID)
					local group = xyd.tables.partnerIDRuleTable:getGroup(mTableID)
					local heroIcon = xyd.tables.partnerIDRuleTable:getIcon(mTableID)
					local num = (material_detail[mTableID].needNum or 0) + 1
					material_detail[mTableID] = {
						star = star,
						group = group,
						needNum = num,
						heroIcon = heroIcon,
						partners = {},
						mTableID = mTableID
					}
				else
					material_detail[mTableID].needNum = (material_detail[mTableID].needNum or 0) + 1
					material_detail[mTableID].tableID = material_detail[mTableID].tableID or mTableID
					material_detail[mTableID].partners = {}
					material_detail[mTableID].mTableID = mTableID
				end
			end

			material_detail[tableID].needNum = material_detail[tableID].needNum + 1

			table.insert(material_detail[tableID].partners, partners[key]:getPartnerID())

			local selectedPartners = {
				[partners[key]:getPartnerID()] = true
			}
			local isCanForge = true
			local materialIds = {}

			for i = 1, #material do
				if #materialIds == 0 or materialIds[#materialIds] ~= material[i] then
					materialIds[#materialIds + 1] = material[i]
				end
			end

			for i = 1, #materialIds do
				local mTableID = materialIds[i]

				if material_detail[mTableID].tableID then
					for keyid in pairs(partners) do
						if partners[keyid]:getTableID() == material_detail[mTableID].tableID then
							if not selectedPartners[partners[keyid]:getPartnerID()] and not partners[keyid]:isLockFlag() then
								selectedPartners[partners[keyid]:getPartnerID()] = true

								table.insert(material_detail[mTableID].partners, partners[keyid]:getPartnerID())
							end

							if material_detail[mTableID].needNum <= #material_detail[mTableID].partners then
								break
							end
						end
					end

					if material_detail[mTableID].needNum > #material_detail[mTableID].partners then
						isCanForge = false

						break
					end
				else
					for keyid in pairs(partners) do
						if partners[keyid]:getGroup() == material_detail[mTableID].group and partners[keyid]:getStar() == material_detail[mTableID].star then
							if not selectedPartners[partners[keyid]:getPartnerID()] and not partners[keyid]:isLockFlag() then
								selectedPartners[partners[keyid]:getPartnerID()] = true

								table.insert(material_detail[mTableID].partners, partners[keyid]:getPartnerID())
							end

							if material_detail[mTableID].needNum <= #material_detail[mTableID].partners then
								break
							end
						end
					end

					if material_detail[mTableID].needNum > #material_detail[mTableID].partners then
						isCanForge = false

						break
					end
				end
			end

			if isCanForge then
				self.batchShenXueRedState = true

				break
			end
		end
	end

	if self.batchShenXueRedState == true then
		self.batchShenXueRedPoint:SetActive(true)
	else
		self.batchShenXueRedPoint:SetActive(false)
	end
end

function ShenXueWindow:initLayOut()
	self.windowTop = WindowTop.new(self.top, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)

	for i = 1, 6 do
		self["label" .. i].text = __("GROUP_" .. i)

		if xyd.Global.lang == "de_de" then
			self["label" .. i].fontSize = 16
		end
	end

	self.midShowGroup:SetActive(false)

	self.shenXueBtnLabel.text = __("SHENXUE")
	self.autoLabel.text = __("GAMBLE_AUTO_4_STAR")
	self.autoStar5Label.text = __("QUICK_STARS_TEXT01")

	if xyd.Global.lang == "fr_fr" then
		self.autoLabel.fontSize = 16
		self.autoStar5Label.fontSize = 16
	end

	self.autoBtn:GetComponent(typeof(UISprite)).width = self.autoLabel.width + 80
	self.autoStar5Btn:GetComponent(typeof(UISprite)).width = self.autoStar5Label.width + 80

	for i = 1, 4 do
		local uiId = i

		self["redPointImg" .. uiId]:SetActive(false)
		self["plusIcon" .. uiId]:SetActive(false)

		self["labelNum" .. uiId].text = "0/0"
	end

	self.forgetList = xyd.models.shenxue:getForgeList()

	self:initVSGroup()

	local itemList = self.wrapContent:getItems()
	self.selectedIndex = 1

	self:chooseIconByIndex(1)
	self:updateSelectBtn(1)
end

function ShenXueWindow:initVSGroup()
	local groupIds = xyd.tables.groupTable:getGroupIds()
	self.infos = {}

	for _, group in ipairs(groupIds) do
		self.infos[group] = {}

		for _, id in pairs(self.forgetList[tostring(group)]) do
			local partnerInfo = {
				noClickSelected = true,
				tableID = id,
				needRedPoint = self.ShenXueModel:getStatusByTableID(id),
				callback = function (icon)
					self:onClickheroIcon(icon)
				end
			}

			table.insert(self.infos[group], partnerInfo)
		end
	end

	for i = 1, 6 do
		self:sortPartner(i)
	end

	self.wrapContent:setInfos(self.infos[1], {})
end

function ShenXueWindow:chooseIconByIndex(index)
	local info = self.infos[self.selectedIndex][index]
	local items = self.wrapContent:getItems()

	for _, item in pairs(items) do
		if item.data and item.data.tableID == info.tableID then
			item.heroIcon.choose = false

			self:onClickheroIcon(item.heroIcon)

			break
		end
	end
end

function ShenXueWindow:sortPartner(index)
	local partnerListGroup = self.infos[index]

	table.sort(partnerListGroup, function (a, b)
		local redA = a.needRedPoint == true and 1 or 0
		local redB = b.needRedPoint == true and 1 or 0
		local idA = a.tableID
		local idB = b.tableID

		if redA ~= redB then
			return redB < redA
		else
			return idB < idA
		end
	end)
end

function ShenXueWindow:startAnimation()
	self.gAnimation:SetActive(true)

	local sequene = self:getSequence()
	local transform = self.gAnimation.transform

	transform:SetLocalPosition(-1000, 0, 0)
	sequene:Append(transform:DOLocalMoveX(50, 0.3))
	sequene:Append(transform:DOLocalMoveX(0, 0.27))
	sequene:AppendCallback(function ()
		sequene:Kill(false)

		sequene = nil
	end)
end

function ShenXueWindow:register()
	ShenXueWindow.super.register(self)

	UIEventListener.Get(self.detailBtn).onClick = function ()
		if self.lastSelectId_ then
			xyd.WindowManager.get():openWindow("partner_info", {
				grade = 0,
				lev = 1,
				table_id = self.lastSelectId_
			})
		end
	end

	UIEventListener.Get(self.shenXueBtn).onClick = handler(self, self.onClickShenXueBtn)
	UIEventListener.Get(self.autoBtn).onClick = handler(self, self.onClickAutoBtn)
	UIEventListener.Get(self.autoStar5Btn).onClick = handler(self, self.onClickAutoStar5Btn)
	UIEventListener.Get(self.batchShenXueBtn).onClick = handler(self, self.onClickBatchShenXueBtn)

	self.eventProxy_:addEventListener(xyd.event.COMPOSE_PARTNER, self.onComposePartner, self)
	self.eventProxy_:addEventListener(xyd.event.SUMMON, self.updateBatchShenXueBtn, self)
	self.partnerImg:setTouchListener(function ()
		self:onTouchImg()
	end)

	for i = 1, 6 do
		UIEventListener.Get(self["group" .. i]).onClick = function ()
			if self.selectedIndex == i then
				return
			end

			xyd.SoundManager.get():playSound(xyd.SoundID.TAB)

			self.selectedIndex = i

			self.wrapContent:setInfos(self.infos[i], {})

			local items = self.wrapContent:getItems()

			self:chooseIconByIndex(1)
			self:updateSelectBtn(i)
		end
	end
end

function ShenXueWindow:updateSelectBtn(index)
	for i = 1, 6 do
		if index == i then
			self["img" .. i].spriteName = "nav_btn_blue_" .. self.BtnState[i]
			self["label" .. i].color = Color.New2(4294967295.0)
			self["label" .. i].effectColor = Color.New2(1012112383)
		else
			self["img" .. i].spriteName = "nav_btn_white_" .. self.BtnState[i]
			self["label" .. i].color = Color.New2(960513791)
			self["label" .. i].effectColor = Color.New2(4294967295.0)
		end
	end
end

function ShenXueWindow:onBatchShenXue()
	self:clearSelect()

	for i = 1, 6 do
		self:refreshRedPoint(i)
	end

	self:onClickheroIcon(self.lastSelected_)
	self:updateBatchShenXueBtn()
end

function ShenXueWindow:onComposePartner(event)
	if not self.singleShenXue or self.singleShenXue == false then
		return
	end

	self.singleShenXue = false
	local params = event.data
	local pInfo = params.partner_info
	self.lastTableId = pInfo.table_id
	self.lastPartnerId = pInfo.partner_id
	local items = {}

	for _, i in ipairs(event.data.items) do
		table.insert(items, {
			item_id = i.item_id,
			item_num = tonumber(i.item_num)
		})
	end

	self:playEffect(function ()
		local params = {
			items = {
				{
					item_num = 1,
					item_id = self.lastTableId,
					partnerID = self.lastPartnerId
				}
			},
			callback = function ()
				xyd.models.itemFloatModel:pushNewItems(items)
				self:onClickheroIcon(self.lastSelected_)
			end
		}

		xyd.WindowManager.get():openWindow("alert_award_partner_window", params)
		self:clearSelect()

		local groupId = xyd.tables.partnerTable:getGroup(self.lastTableId)

		self:refreshRedPoint(groupId)
		self:updateBatchShenXueBtn()
	end)
end

function ShenXueWindow:playEffect(callback)
	xyd.SoundManager.get():playSound("2043")

	if not self.shenxueEffect1 then
		self.shenxueEffect1 = xyd.Spine.new(self.effectGroup1)

		self.shenxueEffect1:setInfo("fx_ui_sc", function ()
			if not self then
				return
			end

			self.shenxueEffect1:SetLocalPosition(0, 0, 0)
			self.shenxueEffect1:SetLocalScale(1.27, 1.27, 1.27)
			self.shenxueEffect1:play("texiao01", 1)
		end)

		self.shenxueEffect2 = xyd.Spine.new(self.effectGroup2)

		self.shenxueEffect2:setInfo("fx_ui_sc", function ()
			if not self then
				return
			end

			self.shenxueEffect2:SetLocalPosition(0, 0, 0)
			self.shenxueEffect2:SetLocalScale(1, 1, 1)
			self.shenxueEffect2:play("texiao01", 1)
		end)

		self.shenxueEffect3 = xyd.Spine.new(self.effectGroup3)

		self.shenxueEffect3:setInfo("fx_ui_sc", function ()
			if not self then
				return
			end

			self.shenxueEffect3:SetLocalPosition(0, 0, 0)
			self.shenxueEffect3:SetLocalScale(1, 1, 1)
			self.shenxueEffect3:play("texiao01", 1)
		end)

		self.shenxueEffect4 = xyd.Spine.new(self.effectGroup4)

		self.shenxueEffect4:setInfo("fx_ui_sc", function ()
			if not self then
				return
			end

			self.shenxueEffect4:SetLocalPosition(0, 0, 0)
			self.shenxueEffect4:SetLocalScale(1, 1, 1)
			self.shenxueEffect4:play("texiao01", 1)
		end)
	else
		self.shenxueEffect1:SetActive(true)
		self.shenxueEffect2:SetActive(true)
		self.shenxueEffect3:SetActive(true)
		self.shenxueEffect4:SetActive(true)
		self.shenxueEffect1:play("texiao01", 1)
		self.shenxueEffect2:play("texiao01", 1)
		self.shenxueEffect3:play("texiao01", 1)
		self.shenxueEffect4:play("texiao01", 1)
	end

	self:setTimeout(function ()
		self.shenxueEffect1:SetActive(false)
		self.shenxueEffect2:SetActive(false)
		self.shenxueEffect3:SetActive(false)
		self.shenxueEffect4:SetActive(false)

		if callback then
			callback()
		end
	end, self, 1500)
end

function ShenXueWindow:clearSelect(notClearTable, noClearChoose)
	self.hostPartner_ = nil
	self.allOptionalList_ = {}
	self.selectedList_ = {}
	self.materialIdList_ = {}
	self.hostOptionalList_ = {}
	self.mateOptionalList_ = {}
	self.materialKeyList_ = {}
	self.materialIds_ = {}

	self.midShowGroup:SetActive(false)

	if self.lastSelected_ then
		if not noClearChoose then
			self.lastSelected_.choose = false
		end

		local partnerInfo = self.lastSelected_:getPartnerInfo()
		self.choosePartners[partnerInfo.tableID] = false
	end

	if self.selectTableID_ ~= 0 and not notClearTable then
		self.choosePartners[self.selectTableID_] = false
		self.selectTableID_ = 0
	end
end

function ShenXueWindow:onClickAutoBtn()
	local state = xyd.db.misc:getValue("shenxue_auto_4_star")

	if state == "1" then
		xyd.db.misc:setValue({
			value = "0",
			key = "shenxue_auto_4_star"
		})
	else
		xyd.db.misc:setValue({
			value = "1",
			key = "shenxue_auto_4_star"
		})
		self:autoSelect4StarHero()
	end

	self:updateAutoBtn()
end

function ShenXueWindow:onClickAutoStar5Btn()
	local state = xyd.db.misc:getValue("shenxue_auto_5_star")

	if state == "1" then
		xyd.db.misc:setValue({
			value = "0",
			key = "shenxue_auto_5_star"
		})
	else
		xyd.db.misc:setValue({
			value = "1",
			key = "shenxue_auto_5_star"
		})
		self:autoSelect5StarHero()
	end

	self:updateAutoBtn()
end

function ShenXueWindow:onClickBatchShenXueBtn()
	xyd.WindowManager.get():openWindow("batch_shen_xue_window")
end

function ShenXueWindow:onClickShenXueBtn()
	local isCanForge = true

	if not self.hostPartner_ or self.hostPartner_.tableID ~= self.hostOptionalList_.mTableID then
		isCanForge = false
	end

	if not isCanForge or not self.isCanForge then
		xyd.alert(xyd.AlertType.TIPS, __("SHENXUE_CAN_NOT_FORGE"))

		return
	end

	local partnerList = {}

	table.insert(partnerList, self.hostPartner_.partnerID)

	for _, mTableID in pairs(self.materialKeyList_) do
		local needNum = self.materialIds_[tostring(mTableID)]

		if not self.materialIdList_[tostring(mTableID)] or needNum > #self.materialIdList_[tostring(mTableID)] then
			isCanForge = false

			break
		end

		for _, pInfo in pairs(self.materialIdList_[tostring(mTableID)]) do
			table.insert(partnerList, tonumber(pInfo.partnerID))
		end
	end

	if not isCanForge then
		return
	end

	local params = {
		table_id = tonumber(self.selectTableID_),
		material_ids = partnerList
	}
	local partners = {}

	for i = 1, #partnerList do
		local id = partnerList[i]

		table.insert(partners, xyd.models.slot:getPartner(id))
	end

	xyd.checkHasMarriedAndNotice(partners, function ()
		local msg = messages_pb:compose_partner_req()
		msg.table_id = tonumber(self.selectTableID_)

		for i = 1, #partnerList do
			table.insert(msg.material_ids, partnerList[i])
		end

		xyd.Backend:get():request(xyd.mid.COMPOSE_PARTNER, msg)
	end)

	self.singleShenXue = true
end

function ShenXueWindow:onSelectContainer(id)
	local optionalList, materialList, mTableID = nil

	if id == 1 then
		optionalList = self.hostOptionalList_
		mTableID = self.hostOptionalList_.mTableID
	else
		mTableID = self.materialKeyList_[id - 1]
		optionalList = self.mateOptionalList_[tostring(mTableID)]
		materialList = self.materialIdList_[tostring(mTableID)]
	end

	self.tmpAllOptionalList_ = self.allOptionalList_
	self.tmpSelectedList_ = self.selectedList_
	local params = {
		alpha = 0.7,
		optionalList = optionalList or {},
		materialList = materialList or {},
		hostPartner = self.hostPartner_,
		id = id,
		confirmCallback = function (id, selectList, hostID)
			self:confirmSelectList(id, selectList, hostID)
		end,
		selectCallback = function (id, pInfo, choose)
			self:setSelectList(id, pInfo, choose)
		end,
		mTableID = mTableID,
		partnerInfo = self.partnerInfo_
	}

	xyd.WindowManager:get():openWindow("shenxue_select_window", params)
end

function ShenXueWindow:confirmSelectList(id, selectList, hostPartner)
	if id == 1 then
		if hostPartner and type(hostPartner) == "number" then
			self.hostPartner_ = hostPartner or nil
		elseif hostPartner and next(hostPartner) ~= nil then
			self.hostPartner_ = hostPartner or nil
		else
			self.hostPartner_ = nil
		end
	else
		local mTableID = self.materialKeyList_[id - 1]
		self.materialIdList_[tostring(mTableID)] = selectList
	end

	self.allOptionalList_ = self.tmpAllOptionalList_
	self.selectedList_ = self.tmpSelectedList_

	self:refreshOptionalList()
end

function ShenXueWindow:setSelectList(id, pInfo, choose)
	local partnerID = pInfo.partnerID

	if choose then
		local pOption = self.tmpAllOptionalList_[tostring(partnerID)]

		if pOption then
			self.tmpAllOptionalList_[tostring(partnerID)] = nil
			self.tmpSelectedList_[tostring(partnerID)] = pOption
		end
	else
		local pOption = self.tmpSelectedList_[tostring(partnerID)]

		if pOption then
			self.tmpSelectedList_[tostring(partnerID)] = nil
			self.tmpAllOptionalList_[tostring(partnerID)] = pOption
		end
	end
end

function ShenXueWindow:refreshOptionalList()
	self.hostOptionalList_.pList = {}
	self.hostOptionalList_.redFlag = false

	for i = 1, self.totalShenxueMatNum - 1 do
		local mTableID = self.materialKeyList_[i]
		self.mateOptionalList_[tostring(mTableID)].pList = {}
		self.mateOptionalList_[tostring(mTableID)].redFlag = false
	end

	for partnerID in pairs(self.allOptionalList_) do
		local pInfo = self.SlotModel:getPartner(tonumber(partnerID))
		pInfo.noClick = false
		local containerIds = self.allOptionalList_[partnerID]

		for _, id in pairs(containerIds) do
			if id == 1 then
				table.insert(self.hostOptionalList_.pList, pInfo)
			else
				local mTableID = self.materialKeyList_[id - 1]

				table.insert(self.mateOptionalList_[tostring(mTableID)].pList, pInfo)
			end
		end
	end

	self.isCanForge = true

	for id = 1, self.totalShenxueMatNum do
		local optionalList = nil
		local mateNum = 0
		local mateAllNum = 0

		if id == 1 then
			optionalList = self.hostOptionalList_

			if self.hostPartner_ then
				mateNum = 1
			end
		else
			local mTableID = self.materialKeyList_[id - 1]
			optionalList = self.mateOptionalList_[tostring(mTableID)]
			local materialList = self.materialIdList_[tostring(mTableID)]

			if materialList then
				mateNum = #materialList
			end
		end

		mateAllNum = mateNum + #optionalList.pList

		if optionalList.needNum <= mateAllNum then
			optionalList.redFlag = true
		else
			optionalList.redFlag = false
		end

		local uiId = id

		if optionalList.redFlag == true then
			self["redPointImg" .. uiId]:SetActive(true)
		else
			self["redPointImg" .. uiId]:SetActive(false)
		end

		self["plusIcon" .. uiId]:SetActive(true)

		self["labelNum" .. uiId].text = mateNum .. "/" .. optionalList.needNum
		local obj = self.icons[uiId]

		if optionalList.needNum <= mateNum then
			self["labelNum" .. uiId].color = Color.New2(1807621887)

			obj:setOrigin()
		else
			obj:setGrey()

			self["labelNum" .. uiId].color = Color.New2(1045659391)
			self.isCanForge = false
		end
	end
end

function ShenXueWindow:onClickheroIcon(heroIcon)
	if heroIcon.choose then
		return
	end

	self:partnerStopMove()
	self:stopSound()
	self.groupName_:SetActive(true)
	self.groupDetail_:SetActive(true)

	if self.lastSelected_ then
		self.lastSelected_.choose = false
		local partnerInfo = self.lastSelected_:getPartnerInfo()
		self.choosePartners[partnerInfo.tableID] = false
	end

	if self.selectTableID_ ~= 0 then
		self.choosePartners[self.selectTableID_] = false
	end

	self.shenXueBtn:SetActive(true)

	local partnerInfo = heroIcon:getPartnerInfo()
	heroIcon.choose = true
	self.choosePartners[partnerInfo.tableID] = true
	self.lastSelected_ = heroIcon
	self.lastSelectId_ = self.lastSelected_:getPartnerInfo().tableID
	self.lastSelectTableID = partnerInfo.tableID
	self.hostPartner_ = nil
	self.allOptionalList_ = {}
	self.selectedList_ = {}
	self.materialIdList_ = {}
	self.hostOptionalList_ = {}
	self.mateOptionalList_ = {}
	self.materialKeyList_ = {}
	self.materialIds_ = {}
	self.selectTableID_ = partnerInfo.tableID
	partnerInfo.star = xyd.tables.partnerTable:getStar(self.selectTableID_)

	self:initMidGroup(partnerInfo)

	self.partnerInfo_ = partnerInfo

	self:initPic(partnerInfo)
end

function ShenXueWindow:initPic(partnerInfo)
	local tableID = partnerInfo.tableID
	local params = {
		star = partnerInfo.star,
		name = xyd.tables.partnerTable:getName(tableID),
		group = xyd.tables.partnerTable:getGroup(tableID),
		tableID = tableID
	}

	self.groupName_:paramsSetInfo(params)
	self.partnerImg:setImg({
		showResLoading = true,
		windowName = self.name,
		itemID = tableID,
		onComplete = function ()
			local xy = xyd.tables.partnerPictureTable:starPictureXy(tableID)
			local scale = xyd.tables.partnerPictureTable:starPictureScale(tableID)

			self.partnerImg.go.transform:SetLocalPosition(xy[1] * 0.8 - 6, 145 - xy[2] * 0.8, 0)
			self.partnerImg.go.transform:SetLocalScale(scale, scale, scale)

			self.curBigPicId = tableID

			self.groupBubble_:Y(-51.5)
			self:bigPicMove()
		end
	})
end

function ShenXueWindow:setPartnerImg(imgSource)
	if self.imgBigPic_ then
		xyd.setBigPicSource(self.imgBigPic_, imgSource)
	end
end

function ShenXueWindow:onTouchImg()
	if not self.lastSelected_ then
		return
	end

	if self.isGroupShake then
		return
	end

	self.isGroupShake = true
	local pos = self.partnerImg.go.transform.localPosition

	if not self.gClickSequence then
		local sequene = self:getSequence()
		local transform = self.partnerImg.go.transform

		sequene:Append(transform:DOLocalMoveY(pos.y + 10, 0.1))
		sequene:Append(transform:DOLocalMoveY(pos.y - 10, 0.1))
		sequene:Append(transform:DOLocalMoveY(pos.y, 0.1))
		sequene:AppendCallback(function ()
			if not self then
				return
			end

			self.isGroupShake = false
		end)
		sequene:SetAutoKill(false)

		self.gClickSequence = sequene
	else
		self.gClickSequence:Restart()
	end

	self:playDialog()
end

function ShenXueWindow:bigPicMove()
	local pos = self.partnerImg.go.transform.localPosition

	self.partnerImg.go:SetLocalPosition(pos.x, pos.y - 10, 0)

	self.partnerImgY = pos.y - 10

	if not self.pMoveSequence then
		local sequene = self:getSequence()
		local transform = self.partnerImg.go.transform

		sequene:Append(transform:DOLocalMoveY(self.partnerImgY + 10, 3))
		sequene:Append(transform:DOLocalMoveY(self.partnerImgY, 3))
		sequene:AppendCallback(function ()
			self.pMoveSequence:Restart()
		end)

		self.pMoveSequence = sequene
	end

	local groupBubblePos = self.groupBubble_.transform.localPosition

	self.groupBubble_.transform:SetLocalPosition(groupBubblePos.x, groupBubblePos.y - 10, 0)

	local groupBubbleY = groupBubblePos.y - 10

	if not self.bubbleAction then
		local sequene = self:getSequence()
		local transform = self.groupBubble_.transform

		sequene:SetLoops(-1)
		sequene:Append(transform:DOLocalMoveY(groupBubbleY + 10, 3)):Append(transform:DOLocalMoveY(groupBubbleY, 3))

		self.bubbleAction = sequene
	else
		self.bubbleAction:Restart()
	end

	self:playDialog()
end

function ShenXueWindow:partnerStopMove()
	if self.pMoveSequence then
		self.pMoveSequence:Pause()
		self.pMoveSequence:Kill()

		self.pMoveSequence = nil
	end

	if self.bubbleAction then
		self.bubbleAction:Pause()
		self.bubbleAction:Kill()

		self.bubbleAction = nil
	end

	if self.gClickSequence then
		self.gClickSequence:Pause()
		self.gClickSequence:Kill()

		self.gClickSequence = nil
	end
end

function ShenXueWindow:playDialog()
	if self.isInDialog then
		return
	end

	self.isInDialog = true

	self.groupBubble_:SetActive(true)

	local clickSoundNum = xyd.tables.partnerTable:getClickSoundNum(self.curBigPicId)
	local rand = math.floor(math.random() * clickSoundNum + 0.5) + 1
	local index = clickSoundNum < rand and rand - clickSoundNum or rand
	local dialogInfo = xyd.tables.partnerTable:getClickDialogInfo(self.curBigPicId, index)
	self.bubbleText_.text = dialogInfo.dialog

	xyd.SoundManager.get():playSound(dialogInfo.sound)

	local key = "bubble_dialog_sound_key_shenxue"

	XYDCo.WaitForTime(dialogInfo.time + 1, function ()
		self.isInDialog = false

		if self.groupBubble_ then
			self.groupBubble_:SetActive(false)
		end
	end, key)

	dialogInfo.timeOutId = key
	self.currentDialog = dialogInfo
end

function ShenXueWindow:stopSound()
	if self.currentDialog then
		xyd.SoundManager.get():stopSound(self.currentDialog.sound)
		self.groupBubble_:SetActive(false)

		self.isInDialog = false
	end
end

function ShenXueWindow:initMidGroup(partnerInfo)
	local tableID = partnerInfo.tableID
	local hostID_ = xyd.tables.partnerTable:getHost(tableID)
	local material = xyd.split(xyd.tables.partnerTable:getMaterial(tableID), "|")
	local hPList = self.SlotModel:getListByTableID(hostID_)
	local hRedFlag = false

	if #hPList > 0 then
		hRedFlag = true
	end

	self.hostOptionalList_ = {
		needNum = 1,
		pList = hPList,
		redFlag = hRedFlag,
		mTableID = hostID_
	}
	local showParams = {
		selectGroup2 = false,
		selectGroup4 = false,
		selectGroup3 = false,
		selectGroup1 = false
	}
	local lastTableID = nil
	self.materialKeyList_ = {}
	self.materialIdList_ = {}
	self.totalShenxueMatNum = 1

	for _, mTableID in ipairs(material) do
		if not self.materialIds_[tostring(mTableID)] then
			self.materialIds_[tostring(mTableID)] = 0
		end

		self.materialIds_[tostring(mTableID)] = self.materialIds_[tostring(mTableID)] + 1

		if not lastTableID or tonumber(mTableID) ~= lastTableID then
			table.insert(self.materialKeyList_, tonumber(mTableID))

			lastTableID = tonumber(mTableID)
			self.totalShenxueMatNum = self.totalShenxueMatNum + 1
		end
	end

	for mTableID in pairs(self.materialIds_) do
		local needNum = self.materialIds_[mTableID]
		local redFlag = false
		local pList = nil

		if tonumber(mTableID) % 1000 == 999 then
			local group = math.floor(tonumber(mTableID) % 10000 / 1000)
			local star = math.floor(tonumber(mTableID) / 10000)
			pList = self.SlotModel:getListByGroupAndStar(group, star)
		else
			pList = self.SlotModel:getListByTableID(tonumber(mTableID))
		end

		if needNum <= #pList then
			redFlag = true
		end

		self.mateOptionalList_[tostring(mTableID)] = {
			pList = pList,
			redFlag = redFlag,
			needNum = needNum,
			mTableID = mTableID
		}
	end

	for id = 1, self.totalShenxueMatNum do
		local optionalList = nil
		local mTableID = 0

		if id == 1 then
			optionalList = self.hostOptionalList_
			mTableID = optionalList.mTableID
		else
			mTableID = self.materialKeyList_[id - 1]
			optionalList = self.mateOptionalList_[tostring(mTableID)]
		end

		NGUITools.DestroyChildren(self["iconContainer" .. id].transform)

		local heroIcon = HeroIcon.new(self["iconContainer" .. id])
		local pInfo = nil

		if tonumber(mTableID) % 1000 == 999 then
			pInfo = {
				needRedPoint = false,
				needStarBg = true,
				group = math.floor(tonumber(mTableID) % 10000 / 1000),
				star = math.floor(tonumber(mTableID) / 10000),
				heroIcon = xyd.tables.partnerIDRuleTable:getIcon(tostring(mTableID))
			}
		else
			pInfo = {
				needRedPoint = false,
				tableID = mTableID
			}
		end

		showParams["selectGroup" .. id] = true
		pInfo.noClickSelected = true

		function pInfo.callback()
			self:onSelectContainer(id)
		end

		heroIcon:setInfo(pInfo)

		local uiId = id
		self.icons[uiId] = heroIcon

		heroIcon:setGrey()

		if optionalList.redFlag == true then
			self["redPointImg" .. uiId]:SetActive(true)
		else
			self["redPointImg" .. uiId]:SetActive(false)
		end

		self["plusIcon" .. uiId]:SetActive(true)

		self["labelNum" .. uiId].text = 0 .. "/" .. tostring(optionalList.needNum)
		self["labelNum" .. uiId].color = Color.New2(1045659391)

		if optionalList.pList and #optionalList.pList > 0 then
			for _, pInfo in ipairs(optionalList.pList) do
				local partnerID = pInfo.partnerID

				if not self.allOptionalList_[tostring(partnerID)] then
					self.allOptionalList_[tostring(partnerID)] = {}
				end

				table.insert(self.allOptionalList_[tostring(partnerID)], id)
			end
		end
	end

	for key, status in pairs(showParams) do
		self[key].gameObject:SetActive(status)
	end

	local pos4 = {
		{
			x = -175,
			y = 8
		},
		{
			x = -45,
			y = 6
		},
		{
			x = 70,
			y = 6
		},
		{
			x = 184,
			y = 6
		}
	}
	local pos3 = {
		{
			x = -120,
			y = 8
		},
		{
			y = 6,
			x = -0
		},
		{
			x = 110,
			y = 6
		},
		{
			x = -184,
			y = 6
		}
	}

	if self.totalShenxueMatNum == 3 then
		for i = 1, 4 do
			self["selectGroup" .. i].transform:SetLocalPosition(pos3[i].x, pos3[i].y, 0)
		end
	else
		for i = 1, 4 do
			self["selectGroup" .. i].transform:SetLocalPosition(pos4[i].x, pos4[i].y, 0)
		end
	end

	self.midShowGroup:SetActive(true)
	self:autoPutMaterial()
	self:updateAutoBtn()
end

function ShenXueWindow:autoSelect4StarHero()
	local state = xyd.db.misc:getValue("shenxue_auto_4_star")

	if not state or state == "0" then
		return
	end

	local mTableID = self.materialKeyList_[self.totalShenxueMatNum - 1]
	local star = math.floor(tonumber(mTableID) / 10000)

	if star ~= 4 then
		return
	end

	local optionalList = self.mateOptionalList_[tostring(mTableID)]
	local pushList = self.materialIdList_[tostring(mTableID)] or {}
	local partnerList = optionalList.pList
	local tableList = {}

	for j = 1, #partnerList do
		if not partnerList[j]:isLockFlag() and partnerList[j].lev == 1 and partnerList[j].love_point <= 0 then
			if not tableList[partnerList[j].tableID] then
				tableList[partnerList[j].tableID] = {}
			end

			table.insert(tableList[partnerList[j].tableID], partnerList[j])
		end
	end

	local tableIdLength = {}

	for partnerID, _ in pairs(tableList) do
		if #pushList == optionalList.needNum then
			break
		end

		if #tableList[partnerID] % 2 == 1 then
			table.insert(tableIdLength, {
				length = #tableList[partnerID] - 1,
				partnerID = partnerID
			})
			table.insert(pushList, tableList[partnerID][1])
			self:setSelectList(self.totalShenxueMatNum, tableList[partnerID][1], true)
			table.remove(tableList[partnerID], 1)
		else
			table.insert(tableIdLength, {
				length = #tableList[partnerID],
				partnerID = partnerID
			})
		end
	end

	table.sort(tableIdLength, function (a, b)
		return a.length < b.length
	end)

	for i = 1, #tableIdLength do
		if optionalList.needNum <= #pushList then
			break
		end

		while #tableList[tableIdLength[i].partnerID] > 0 do
			table.insert(pushList, tableList[tableIdLength[i].partnerID][1])
			self:setSelectList(self.totalShenxueMatNum, tableList[tableIdLength[i].partnerID][1], true)
			table.remove(tableList[tableIdLength[i].partnerID], 1)

			if optionalList.needNum <= #pushList then
				break
			end
		end
	end

	self:confirmSelectList(self.totalShenxueMatNum, pushList, {})
end

function ShenXueWindow:autoSelect5StarHero()
	local state = xyd.db.misc:getValue("shenxue_auto_5_star")

	if not state or state == "0" then
		return
	end

	local mTableID = self.materialKeyList_[self.totalShenxueMatNum - 1]
	local star = math.floor(tonumber(mTableID) / 10000)

	if star ~= 5 then
		return
	end

	local optionalList = self.mateOptionalList_[tostring(mTableID)]
	local pushList = self.materialIdList_[tostring(mTableID)] or {}
	local partnerList = optionalList.pList
	local tableList = {}

	for j = 1, #partnerList do
		if not partnerList[j]:isLockFlag() and partnerList[j].lev == 1 and partnerList[j].love_point <= 0 and (not xyd.tables.partnerTable:getStar10(partnerList[j]:getTableID()) or xyd.tables.partnerTable:getStar10(partnerList[j]:getTableID()) == 0) then
			if not tableList[partnerList[j].tableID] then
				tableList[partnerList[j].tableID] = {}
			end

			table.insert(tableList[partnerList[j].tableID], partnerList[j])
		end
	end

	local tableIdLength = {}

	for partnerID, _ in pairs(tableList) do
		if #pushList == optionalList.needNum then
			break
		end

		if #tableList[partnerID] % 2 == 1 then
			table.insert(tableIdLength, {
				length = #tableList[partnerID] - 1,
				partnerID = partnerID
			})
			table.insert(pushList, tableList[partnerID][1])
			self:setSelectList(self.totalShenxueMatNum, tableList[partnerID][1], true)
			table.remove(tableList[partnerID], 1)
		else
			table.insert(tableIdLength, {
				length = #tableList[partnerID],
				partnerID = partnerID
			})
		end
	end

	table.sort(tableIdLength, function (a, b)
		return a.length < b.length
	end)

	for i = 1, #tableIdLength do
		if optionalList.needNum <= #pushList then
			break
		end

		while #tableList[tableIdLength[i].partnerID] > 0 do
			table.insert(pushList, tableList[tableIdLength[i].partnerID][1])
			self:setSelectList(self.totalShenxueMatNum, tableList[tableIdLength[i].partnerID][1], true)
			table.remove(tableList[tableIdLength[i].partnerID], 1)

			if optionalList.needNum <= #pushList then
				break
			end
		end
	end

	self:confirmSelectList(self.totalShenxueMatNum, pushList, {})
end

function ShenXueWindow:autoPutMaterial()
	self.tmpAllOptionalList_ = self.allOptionalList_

	self:autoChooseFirstMaterial()

	for i = 1, self.totalShenxueMatNum - 2 do
		local mTableID = self.materialKeyList_[i]
		local optionalList = self.mateOptionalList_[tostring(mTableID)]
		local pushList = {}
		local partnerList = optionalList.pList

		for j = 1, #partnerList do
			if #pushList == optionalList.needNum then
				break
			end

			if partnerList[j]:isLockFlag() == false and partnerList[j].lev == 1 and partnerList[j]:getLovePoint() <= 0 then
				table.insert(pushList, partnerList[j])
				self:setSelectList(i, partnerList[j], true)
			end
		end

		self:confirmSelectList(i + 1, pushList, {})
	end

	self:autoSelect4StarHero()
	self:autoSelect5StarHero()
end

function ShenXueWindow:autoChooseFirstMaterial()
	local mTableID = self.materialKeyList_[1]
	local optionalList = self.mateOptionalList_[tostring(mTableID)]
	local pushList = {}
	local partnerList = optionalList.pList
	local maxLev = -1
	local maxLovePoint = -1
	local tmpPartner = nil

	for j = 1, #partnerList do
		if #pushList == optionalList.needNum then
			break
		end

		if partnerList[j]:isLockFlag() == false then
			if maxLev < partnerList[j].lev then
				tmpPartner = partnerList[j]
				maxLev = partnerList[j].lev
				maxLovePoint = partnerList[j]:getLovePoint()
			elseif partnerList[j].lev == maxLev and maxLovePoint < partnerList[j]:getLovePoint() then
				tmpPartner = partnerList[j]
				maxLovePoint = partnerList[j]:getLovePoint()
			end
		end
	end

	if not tmpPartner then
		return
	end

	self:setSelectList(1, tmpPartner, true)
	self:confirmSelectList(1, {}, tmpPartner)
end

function ShenXueWindow:refreshRedPoint(groupId)
	local infos = self.infos[groupId]

	for i = 1, #infos do
		local pInfo = infos[i]
		local tableID = pInfo.tableID
		local status = xyd.models.shenxue:getStatusByTableID(tableID)
		pInfo.needRedPoint = status
	end

	self:sortPartner(groupId)

	if self.selectedIndex == groupId then
		self.wrapContent:setInfos(infos, {
			keepPosition = true
		})
	end
end

function ShenXueWindow:clearEffect()
	BaseWindow.clearEffect(self, true)
end

function ShenXueWindow:willClose()
	BaseWindow.willClose(self)
	self:partnerStopMove()

	if self.shenxueEffect1 then
		self.shenxueEffect1 = nil
	end

	if self.shenxueEffect2 then
		self.shenxueEffect2 = nil
	end

	if self.shenxueEffect3 then
		self.shenxueEffect3 = nil
	end

	if self.shenxueEffect4 then
		self.shenxueEffect4 = nil
	end

	local wnd = xyd.WindowManager.get():getWindow("res_loading_window")

	if wnd then
		xyd.WindowManager.get():closeWindow("res_loading_window")
	end

	self:stopSound()
end

return ShenXueWindow
