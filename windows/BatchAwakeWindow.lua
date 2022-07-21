local BaseWindow = import(".BaseWindow")
local BatchAwakeWindow = class("BatchAwakeWindow", BaseWindow)
local BatchAwakeWindowItem = class("BatchAwakeWindowItem")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")

function BatchAwakeWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.filterIndex = 0
	self.isSelectAll = false
	self.selectedPartners = {}
	self.infos = {}
	self.shenXueFinish = true
	self.shenXueNum = 0
	self.items = {}
	self.sendMsgDataList = {}
	self.destStar = params.destStar or 9
	self.hostStar = params.hostStar or 5
	self.canChooseMaterialPartnerTableIDs = xyd.models.shenxue:getMaterialPartnerRecordTableIDs()
	self.helpCanChooseArr = {}

	for i = 1, #self.canChooseMaterialPartnerTableIDs do
		self.helpCanChooseArr[self.canChooseMaterialPartnerTableIDs[i]] = 1
	end
end

function BatchAwakeWindow:initWindow()
	self:getUIComponent()
	BatchAwakeWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function BatchAwakeWindow:sortByTableID()
	local partners = xyd.models.slot:getPartners()
	local partnerIDs = {}

	for key in pairs(partners) do
		table.insert(partnerIDs, key)
	end

	table.sort(partnerIDs, function (a, b)
		local aIsFeiTai5 = false
		local bIsFeiTai5 = false
		local aTableID = partners[a]:getTableID()
		local bTableID = partners[b]:getTableID()
		local aStar = xyd.tables.partnerTable:getStar(aTableID)
		local aTenStarTableID = xyd.tables.partnerTable:getTenStarTableID(aTableID)
		local bStar = xyd.tables.partnerTable:getStar(bTableID)
		local bTenStarTableID = xyd.tables.partnerTable:getTenStarTableID(bTableID)

		if aStar == 5 and (not aTenStarTableID or aTenStarTableID <= 0) then
			aIsFeiTai5 = true
		end

		if bStar == 5 and (not bTenStarTableID or bTenStarTableID <= 0) then
			bIsFeiTai5 = true
		end

		if aIsFeiTai5 ~= bIsFeiTai5 then
			return aIsFeiTai5
		else
			return aTableID < bTableID
		end
	end)

	return partnerIDs
end

function BatchAwakeWindow:updateData()
	local partners = xyd.models.slot:getPartners()
	local partnerIDSortByTableID = self:sortByTableID()

	for i, key in ipairs(partnerIDSortByTableID) do
		if partners[key]:getStar() == self.hostStar then
			local tableID = partners[key]:getTableID()
			local destTableID = xyd.tables.partnerTable:getSixStarTableID(tableID)
			local newTableID = nil

			if self.destStar == 9 then
				newTableID = xyd.tables.partnerTable:getSixStarTableID(tableID)
			elseif self.destStar == 10 then
				newTableID = xyd.tables.partnerTable:getTenStarTableID(tableID)
			end

			if newTableID and not self.selectedPartners[partners[key]:getPartnerID()] and not partners[key]:isLockFlag() and not xyd.tables.partnerTable:checkPuppetPartner(partners[key]:getTableID()) and newTableID > 0 then
				local material = xyd.models.shenxue:getMaterial({
					star = self.destStar,
					tableID = destTableID
				})

				for key, value in pairs(material) do
					material[key] = tonumber(value)
				end

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

					material_detail[mTableID].noClickSelected = true
					material_detail[mTableID].notPlaySaoguang = true
				end

				material_detail[tableID].needNum = (material_detail[tableID].needNum or 0) + 1

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
							local curTableId = partners[keyid]:getTableID()
							local sameListFlag = false
							local tempHeroList = xyd.tables.partnerTable:getHeroList(curTableId)

							if tempHeroList and #tempHeroList > 0 then
								for i = 1, #tempHeroList do
									if tonumber(destTableID) == tempHeroList[i] then
										sameListFlag = true
									end
								end
							end

							local needCheckFlag = false

							if partners[keyid]:getTableID() == material_detail[mTableID].tableID then
								needCheckFlag = true
							end

							if needCheckFlag then
								if not self.selectedPartners[partners[keyid]:getPartnerID()] and not selectedPartners[partners[keyid]:getPartnerID()] and not partners[keyid]:isLockFlag() then
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
							local tempFlag = xyd.tables.partnerTable:checkPuppetPartner(partners[keyid]:getTableID()) or self.helpCanChooseArr[partners[keyid]:getTableID()]

							if material_detail[mTableID].star > 5 then
								local fiveStarTableID = xyd.tables.partnerTable:getFiveStarTableID(partners[keyid]:getTableID())

								if fiveStarTableID then
									tempFlag = tempFlag or self.helpCanChooseArr[fiveStarTableID]
								end
							end

							if (partners[keyid]:getGroup() == material_detail[mTableID].group or material_detail[mTableID].group == 0) and partners[keyid]:getStar() == material_detail[mTableID].star and tempFlag then
								if not self.selectedPartners[partners[keyid]:getPartnerID()] and not selectedPartners[partners[keyid]:getPartnerID()] and not partners[keyid]:isLockFlag() then
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
					self.selectedPartners[partners[key]:getPartnerID()] = true

					for keyid in pairs(selectedPartners) do
						self.selectedPartners[keyid] = true
					end

					local info = {
						isSelected = false,
						hostID = partners[key]:getPartnerID(),
						hostTableID = partners[key]:getTableID(),
						destTableID = destTableID,
						material_detail = material_detail,
						dragScrollView = self.scrollView,
						confirmCallback = function (oriPartners, curPartners, mTableID)
							for _, partnerID in pairs(oriPartners) do
								self.selectedPartners[partnerID] = nil
							end

							for _, partnerID in pairs(curPartners) do
								self.selectedPartners[partnerID] = true
							end

							for _, m_info in pairs(self.infos[0]) do
								if partners[key]:getPartnerID() == m_info.hostID then
									m_info.material_detail[mTableID].partners = curPartners

									break
								end
							end

							for _, m_info in pairs(self.infos[partners[key]:getGroup()]) do
								if partners[key]:getPartnerID() == m_info.hostID then
									m_info.material_detail[mTableID].partners = curPartners

									break
								end
							end

							self:updateBenchPartners()
						end,
						selectCallback = function (flag)
							for _, m_info in pairs(self.infos[0]) do
								if partners[key]:getPartnerID() == m_info.hostID then
									m_info.isSelected = flag

									break
								end
							end

							for _, m_info in pairs(self.infos[partners[key]:getGroup()]) do
								if partners[key]:getPartnerID() == m_info.hostID then
									m_info.isSelected = flag

									break
								end
							end
						end
					}
					local group = partners[key]:getGroup()

					if not self.infos[0] then
						self.infos[0] = {}
					end

					if not self.infos[group] then
						self.infos[group] = {}
					end

					table.insert(self.infos[0], info)
					table.insert(self.infos[group], info)
				end
			end
		end
	end

	self:updateBenchPartners()
end

function BatchAwakeWindow:updateBenchPartners()
	local partners = xyd.models.slot:getPartners()

	for _, infos in pairs(self.infos) do
		for __, info in pairs(infos) do
			for ___, detail in pairs(info.material_detail) do
				detail.benchPartners = {}

				for ____, partnerID in pairs(detail.partners) do
					table.insert(detail.benchPartners, partners[partnerID])
				end

				if detail.tableID then
					for key in pairs(partners) do
						if partners[key]:getTableID() == detail.tableID and self.selectedPartners[partners[key]:getPartnerID()] ~= true then
							table.insert(detail.benchPartners, partners[key])
						end
					end
				else
					for key in pairs(partners) do
						if (partners[key]:getGroup() == detail.group or detail.group == 0) and partners[key]:getStar() == detail.star and self.selectedPartners[partners[key]:getPartnerID()] ~= true then
							table.insert(detail.benchPartners, partners[key])
						end
					end
				end
			end
		end
	end
end

function BatchAwakeWindow:updateScroller()
	if self.infos[self.filterIndex] and #self.infos[self.filterIndex] > 0 then
		self.groupNone:SetActive(false)
		self.scrollView:SetActive(true)

		local infos = {}

		for i = #self.infos[self.filterIndex], 1, -1 do
			table.insert(infos, self.infos[self.filterIndex][i])
		end

		for i = 1, #infos do
			if not self.items[i] then
				local tmp = NGUITools.AddChild(self.groupItem.gameObject, self.item.gameObject)
				local item = BatchAwakeWindowItem.new(tmp, self)

				item:setInfo(infos[i])

				self.items[i] = item
			else
				self.items[i]:SetActive(true)
				self.items[i]:setInfo(infos[i])
			end
		end

		for i = #infos + 1, #self.items do
			self.items[i]:SetActive(false)
		end

		self.grid:Reposition()
		self.scrollView:ResetPosition()
	else
		self.groupNone:SetActive(true)
		self.scrollView:SetActive(false)
	end
end

function BatchAwakeWindow:updateSelectItem()
	local infos = self.infos[self.filterIndex]

	for i = 1, #infos do
		self.items[i]:updateSelect(infos[i].isSelected)
	end
end

function BatchAwakeWindow:onClickFilter(filterIndex)
	self.filterIndex = filterIndex
	self.isSelectAll = true

	if self.infos[self.filterIndex] and #self.infos[self.filterIndex] > 0 then
		for _, info in pairs(self.infos[self.filterIndex]) do
			if info.isSelected == false then
				self.isSelectAll = false

				break
			end
		end
	else
		self.isSelectAll = false
	end

	for i = 0, 6 do
		self["filterChosen" .. i]:SetActive(i == self.filterIndex)
	end

	self:updateScroller()
	self:updateSelectAllBtn()
end

function BatchAwakeWindow:onClickBatchShenXue()
	if self.shenXueFinish == false or self.shenXueNum ~= 0 then
		return
	end

	if not self.infos[0] or #self.infos[0] == 0 then
		self:close()

		return
	end

	local tempPartners = {}

	for _, info in pairs(self.infos[0]) do
		if info.isSelected == true then
			local isCanForge = true

			for mTableID in pairs(info.material_detail) do
				if info.material_detail[mTableID].needNum > #info.material_detail[mTableID].partners then
					isCanForge = false

					break
				end
			end

			if isCanForge then
				local hostPartner = xyd.models.slot:getPartner(info.hostID)

				table.insert(tempPartners, hostPartner)

				for mTableID, m_detail in pairs(info.material_detail) do
					for i = 1, #m_detail.partners do
						table.insert(tempPartners, xyd.models.slot:getPartner(m_detail.partners[i]))
					end
				end
			end
		end
	end

	xyd.checkHasMarriedAndNotice(tempPartners, function ()
		self.shenXueFinish = false
		self.shenXueNum = 0

		for _, info in pairs(self.infos[0]) do
			if info.isSelected == true then
				self.selectFlag = true
				local isCanForge = true

				for mTableID in pairs(info.material_detail) do
					if info.material_detail[mTableID].needNum > #info.material_detail[mTableID].partners then
						isCanForge = false

						break
					end
				end

				if isCanForge then
					self.shenXueNum = self.shenXueNum + 1
					local hostPartner = xyd.models.slot:getPartner(info.hostID)
					local hostTableID = hostPartner:getTableID()
					local materialIdList_ = {}
					local destPartnerInfo = {
						star = self.destStar
					}

					for mTableID, m_detail in pairs(info.material_detail) do
						mTableID = tostring(mTableID)

						for i = 1, #m_detail.partners do
							if not materialIdList_[mTableID] then
								materialIdList_[mTableID] = {}
							end

							if hostPartner:getPartnerID() ~= m_detail.partners[i] then
								table.insert(materialIdList_[mTableID], {
									partnerID = m_detail.partners[i]
								})
							end
						end
					end

					if not xyd.models.shenxue:getIsDoingReq() and #self.sendMsgDataList == 0 then
						local resCost = xyd.models.shenxue:getResCost(hostPartner, self.destStar)
						local canAwake = true
						local helpArr = {
							xyd.ItemID.MANA,
							xyd.ItemID.PARTNER_EXP,
							xyd.ItemID.GRADE_STONE
						}

						for i = 1, 3 do
							xyd.setUISpriteAsync(self["res" .. i], nil, xyd.tables.itemTable:getIcon(helpArr[i]))

							local costNum = resCost[helpArr[i]]
							local resNum = xyd.models.backpack:getItemNumByID(helpArr[i])

							if resNum < costNum then
								canAwake = false
								self.shenXueNum = 0
								self.shenXueFinish = true
								self.sendMsgDataList = {}
								self.sendMsg = false

								xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(helpArr[i])))

								return
							end
						end

						if canAwake then
							xyd.models.shenxue:reqAwakeOfShenXue(hostPartner, materialIdList_, destPartnerInfo)
						else
							xyd.alert(xyd.AlertType.TIPS, __("SHENXUE_CAN_NOT_FORGE"))

							return
						end
					else
						table.insert(self.sendMsgDataList, {
							hostPartner = hostPartner,
							materialIdList_ = materialIdList_,
							destPartnerInfo = destPartnerInfo
						})
					end

					self.sendMsg = true
				end
			end
		end

		if not self.sendMsg then
			if self.selectFlag then
				xyd.alert(xyd.AlertType.TIPS, __("SHENXUE_CAN_NOT_FORGE"))
			end

			self:close()
		else
			self.shenXueFinish = true

			self.loadingComponent:SetActive(true)
		end
	end)
end

function BatchAwakeWindow:onAwakePartner(event)
	if xyd.models.shenxue:getIsDoingReq() then
		return
	end

	self.shenXueNum = self.shenXueNum - 1

	if not self.awardItem or not self.partnerItems then
		self.awardItem = {}
		self.partnerItems = {}
	end

	local items = xyd.models.shenxue:getTempItems()

	for i = 1, #items do
		table.insert(self.awardItem, {
			item_id = items[i].item_id,
			item_num = tonumber(items[i].item_num)
		})
	end

	local partnerItems = event.data.partner_info

	table.insert(self.partnerItems, {
		item_num = 1,
		item_id = partnerItems.table_id,
		partnerID = partnerItems.partner_id,
		star = self.destStar
	})

	if #self.sendMsgDataList > 0 then
		local hostPartner = self.sendMsgDataList[1].hostPartner
		local materialIdList_ = self.sendMsgDataList[1].materialIdList_
		local destPartnerInfo = self.sendMsgDataList[1].destPartnerInfo
		local resCost = xyd.models.shenxue:getResCost(self.sendMsgDataList[1].hostPartner, self.destStar)
		local canAwake = true
		local helpArr = {
			xyd.ItemID.MANA,
			xyd.ItemID.PARTNER_EXP,
			xyd.ItemID.GRADE_STONE
		}

		for i = 1, 3 do
			xyd.setUISpriteAsync(self["res" .. i], nil, xyd.tables.itemTable:getIcon(helpArr[i]))

			local costNum = resCost[helpArr[i]]
			local resNum = xyd.models.backpack:getItemNumByID(helpArr[i])

			if resNum < costNum then
				canAwake = false
				self.shenXueNum = 0
				self.sendMsgDataList = {}

				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(helpArr[i])))

				break
			end
		end

		if canAwake then
			xyd.models.shenxue:reqAwakeOfShenXue(hostPartner, materialIdList_, destPartnerInfo)
			table.remove(self.sendMsgDataList, 1)
		end
	else
		self.shenXueNum = 0
	end

	if self.shenXueFinish == true and self.shenXueNum == 0 and #self.awardItem > 0 then
		self:hide()

		local params = {
			items = self.partnerItems,
			callback = function ()
				local win = xyd.WindowManager.get():getWindow("shenxue_window")

				if win then
					win:onBatchShenXue()
				end

				xyd.models.itemFloatModel:pushNewItems(self.awardItem)

				self.awardItem = {}
				self.partnerItems = {}

				self:close()
			end,
			title = __("SHENXUE_GET_WINDOW")
		}

		if #self.partnerItems == 1 then
			xyd.WindowManager.get():openWindow("alert_award_window", params)
		else
			xyd.WindowManager.get():openWindow("alert_item_window", params)
		end
	end
end

function BatchAwakeWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.scrollView = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.groupItem = self.scrollView:NodeByName("groupItem").gameObject
	self.grid = self.scrollView:ComponentByName("groupItem", typeof(UIGrid))
	self.item = winTrans:NodeByName("item").gameObject
	local filterGroup = groupAction:NodeByName("filterGroup").gameObject

	for i = 0, 6 do
		self["filter" .. i] = filterGroup:NodeByName("group" .. i).gameObject
		self["filterChosen" .. i] = self["filter" .. i]:NodeByName("chosen").gameObject
	end

	self.batchShenXueBtn = groupAction:NodeByName("batchShenXueBtn").gameObject
	self.batchShenXueBtnLabel = self.batchShenXueBtn:ComponentByName("button_label", typeof(UILabel))
	self.allSelectBtn = groupAction:NodeByName("allSelectBtn").gameObject
	self.allSelectBtnLabel = self.allSelectBtn:ComponentByName("button_label", typeof(UILabel))
	self.materialBtn = groupAction:NodeByName("materialBtn").gameObject
	self.redPointImg = self.materialBtn:ComponentByName("redPointImg", typeof(UISprite))
	self.groupNone = groupAction:NodeByName("groupNone").gameObject
	self.labelNoneTips = self.groupNone:ComponentByName("labelNoneTips", typeof(UILabel))
	self.loadingComponent = groupAction:NodeByName("loadingComponent").gameObject
	self.loadingEffect = self.loadingComponent:NodeByName("loadingEffect").gameObject
	self.loadingText = self.loadingComponent:ComponentByName("loadingText", typeof(UILabel))
end

function BatchAwakeWindow:initUIComponent()
	self.labelTitle.text = __("SHENXUE_TEXT03", self.destStar)
	self.batchShenXueBtnLabel.text = __("SHENXUE_TEXT05")
	self.labelNoneTips.text = __("QUICK_STARS_TEXT04")
	self.loadingText.text = __("SHENXUE_TEXT06")

	self:updateSelectAllBtn()

	for i = 0, 6 do
		self["filterChosen" .. i]:SetActive(i == self.filterIndex)
	end

	self:updateData()
	self:updateScroller()

	local effect = xyd.Spine.new(self.loadingEffect)

	effect:setInfo("loading", function ()
		effect:SetLocalScale(0.95, 0.95, 0.95)
		effect:play("idle", 0, 1)
	end)

	self.effect = effect

	self.materialBtn:SetActive(true)

	if not xyd.db.misc:getValue("shenxue_first_set_material") then
		self.redPointImg:SetActive(true)
		xyd.db.misc:setValue({
			value = 1,
			key = "shenxue_first_set_material"
		})
	end
end

function BatchAwakeWindow:updateSelectAllBtn()
	if self.isSelectAll == false then
		self.allSelectBtnLabel.text = __("SELECT_ALL_YES")

		xyd.setBgColorType(self.allSelectBtn, xyd.ButtonBgColorType.blue_btn_60_60)
	else
		self.allSelectBtnLabel.text = __("SELECT_ALL_NO")

		xyd.setBgColorType(self.allSelectBtn, xyd.ButtonBgColorType.white_btn_60_60)
	end
end

function BatchAwakeWindow:onClickSelectAllBtn()
	if self.infos[self.filterIndex] and #self.infos[self.filterIndex] > 0 then
		self.isSelectAll = not self.isSelectAll

		for _, info in pairs(self.infos[self.filterIndex]) do
			info.isSelected = self.isSelectAll
		end

		self:updateSelectAllBtn()
		self:updateSelectItem()
	else
		xyd.alert(xyd.AlertType.TIPS, __("SELECT_ALL_TEXT01"))
	end
end

function BatchAwakeWindow:onClickMaterialBtn()
	local materialPartnerRecordTableIDs = xyd.models.shenxue:getMaterialPartnerRecordTableIDs()
	local helpArr = {}

	for i = 1, #materialPartnerRecordTableIDs do
		helpArr[materialPartnerRecordTableIDs[i]] = 1
	end

	local ids = xyd.models.shenxue:getAllFiveStarPartnerTableIDs()
	local benchPartners = {}
	local selectedPartners = {}

	for i = 1, #ids do
		local tenStarTableID = xyd.tables.partnerTable:getTenStarTableID(ids[i])

		if tenStarTableID then
			local partner = Partner.new()

			partner:populate({
				star = 5,
				tableID = ids[i],
				partnerID = ids[i]
			})
			table.insert(benchPartners, partner)

			if helpArr[ids[i]] then
				table.insert(selectedPartners, ids[i])
			end
		end
	end

	local params = {
		isShowLovePoint = false,
		benchPartners = benchPartners,
		partners = selectedPartners,
		confirmCallback = function ()
			local win = xyd.WindowManager:get():getWindow("choose_partner_with_filter_window")
			local selectPartnerIDs = win:getSelected() or {}
			local result = {}

			for key, value in ipairs(selectPartnerIDs) do
				table.insert(result, value)
			end

			for key, value in ipairs(ids) do
				local tenStarTableID = xyd.tables.partnerTable:getTenStarTableID(value)

				if not tenStarTableID then
					table.insert(result, value)
				end
			end

			xyd.models.shenxue:setMaterialPartnerRecordTableIDs(result)

			local win = xyd.WindowManager:get():getWindow("shenxue_window")

			if win then
				win:updateMaterialPartnerhelpArr()
			end
		end,
		closeCallback = function ()
			xyd.openWindow("batch_awake_window", {
				destStar = self.destStar
			})
		end
	}

	xyd.openWindow("choose_partner_with_filter_window", params)
	self:close()
end

function BatchAwakeWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	for i = 0, 6 do
		UIEventListener.Get(self["filter" .. i]).onClick = function ()
			self:onClickFilter(i)
		end
	end

	UIEventListener.Get(self.batchShenXueBtn).onClick = function ()
		self:onClickBatchShenXue()
	end

	UIEventListener.Get(self.allSelectBtn).onClick = function ()
		self:onClickSelectAllBtn()
	end

	UIEventListener.Get(self.materialBtn).onClick = function ()
		self:onClickMaterialBtn()
	end

	self.eventProxy_:addEventListener(xyd.event.AWAKE_PARTNER, self.onAwakePartner, self)
end

function BatchAwakeWindow:hideEffect(callback)
	local action = self:getSequence()

	local function setter(value)
		self.loadingComponent:GetComponent(typeof(UIWidget)).alpha = value

		if self.effect and self.effect.spAnim then
			self.effect.spAnim:setAlpha(value)
		end
	end

	action:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0.01, 1))
	action:AppendCallback(callback)
end

function BatchAwakeWindowItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.icons = {}
	self.groupIcons = {}

	self:getUIComponent()
end

function BatchAwakeWindowItem:SetActive(flag)
	self.go:SetActive(flag)
end

function BatchAwakeWindowItem:getUIComponent()
	self.feedIcons = self.go:NodeByName("feedIcons").gameObject
	self.feedIconsGrid = self.feedIcons:GetComponent(typeof(UIGrid))
	self.feedIconGroup = self.go:NodeByName("feedIconGroup").gameObject
	self.partnerGroup = self.go:NodeByName("partnerGroup").gameObject
	self.selectBtn = self.go:NodeByName("selectBtn").gameObject
	self.selectImg = self.selectBtn:ComponentByName("selectImg", typeof(UISprite))
	self.imgEqual = self.go:NodeByName("imgEqual").gameObject
end

function BatchAwakeWindowItem:setInfo(data)
	self.data = data
	self.destTableID = self.data.destTableID
	self.material_detail = {}
	self.isSelected = self.data.isSelected

	for key, m_detail in pairs(self.data.material_detail) do
		table.insert(self.material_detail, m_detail)
	end

	table.sort(self.material_detail, function (a, b)
		local pointa = a.mTableID
		local pointb = b.mTableID

		if a.mTableID == self.data.hostTableID then
			pointa = 0
		end

		if b.mTableID == self.data.hostTableID then
			pointb = 0
		end

		return pointa < pointb
	end)

	if #self.material_detail == 4 then
		self.feedIconsGrid.cellWidth = 90

		self.imgEqual:X(78)
	else
		self.feedIconsGrid.cellWidth = 120

		self.imgEqual:X(57.5)
	end

	for i = 1, #self.material_detail do
		local key = self.material_detail[i].mTableID
		local m_detail = self.material_detail[i]
		local group, icon = nil

		if not self.groupIcons[i] then
			group = NGUITools.AddChild(self.feedIcons, self.feedIconGroup)
			local heroIconContainer = group:NodeByName("heroIcon").gameObject
			icon = HeroIcon.new(heroIconContainer)
			self.icons[i] = icon
			self.groupIcons[i] = group
		else
			group = self.groupIcons[i]
			icon = self.icons[i]
		end

		icon:setInfo({
			dragScrollView = self.data.dragScrollView
		})

		local label = group:ComponentByName("labelAwakeFeed", typeof(UILabel))
		local imgPlus = group:ComponentByName("addIcon", typeof(UISprite))
		local originPartners = {}

		for i = 1, #m_detail.partners do
			table.insert(originPartners, m_detail.partners[i])
		end

		function m_detail.callback()
			local params = m_detail

			table.sort(params.benchPartners, function (a, b)
				local selectA = self.parent.selectedPartners[a:getPartnerID()]
				local selectB = self.parent.selectedPartners[b:getPartnerID()]

				if selectA ~= selectB then
					return selectA == true
				elseif a:getTableID() == b:getTableID() then
					return a:getPartnerID() < b:getPartnerID()
				else
					return a:getTableID() < b:getTableID()
				end
			end)

			params.mTableID = key
			params.this_icon = icon
			params.this_label = label
			params.this_imgPlus = imgPlus
			params.isShenxue = true

			function params.confirmCallback()
				m_detail.partners = icon:getPartnerInfo().partners

				if self.data.confirmCallback then
					self.data.confirmCallback(originPartners, m_detail.partners, key)
				end

				if m_detail.needNum <= #m_detail.benchPartners then
					icon:showRedMark(true)
				else
					icon:showRedMark(false)
				end

				if m_detail.needNum <= #m_detail.partners then
					icon:setOrigin()

					label.color = Color.New2(915996927)

					imgPlus:SetActive(false)
				else
					imgPlus:SetActive(true)

					label.color = Color.New2(1432789759)

					icon:setGrey()
				end

				label.text = #m_detail.partners .. "/" .. m_detail.needNum
				icon.selected = false
			end

			function params.debrisCloseCallBack()
				local win = xyd.WindowManager.get():getWindow("batch_shen_xue_window")

				if not win then
					return
				end

				win:updateData()
				win:updateScroller()

				m_detail.partners = icon:getPartnerInfo().partners

				if self.data.confirmCallback then
					self.data.confirmCallback(m_detail.partners, m_detail.partners, key)
				end

				xyd.WindowManager:get():openWindow("choose_partner_window", params)
			end

			xyd.WindowManager:get():openWindow("choose_partner_window", params)
		end

		icon:setInfo(m_detail)
		icon:setScale(0.7777777777777778)

		if m_detail.needNum <= #m_detail.benchPartners then
			icon:showRedMark(true)
		else
			icon:showRedMark(false)
		end

		if m_detail.needNum <= #m_detail.partners then
			icon:setOrigin()

			label.color = Color.New2(915996927)

			imgPlus:SetActive(false)
		else
			imgPlus:SetActive(true)

			label.color = Color.New2(1432789759)

			icon:setGrey()
		end

		label.text = #m_detail.partners .. "/" .. m_detail.needNum
		icon.selected = false
	end

	self.feedIconsGrid:Reposition()
	NGUITools.DestroyChildren(self.partnerGroup.transform)

	local partnerAfter = HeroIcon.new(self.partnerGroup)

	partnerAfter:setInfo({
		noClick = true,
		tableID = self.destTableID,
		star = self.parent.destStar
	})
	partnerAfter:setScale(0.8703703703703703)
	self.selectImg:SetActive(self.isSelected)

	UIEventListener.Get(self.selectBtn).onClick = function ()
		self.isSelected = not self.isSelected

		self.selectImg:SetActive(self.isSelected)

		if self.data.selectCallback then
			self.data.selectCallback(self.isSelected)
		end
	end
end

function BatchAwakeWindowItem:updateSelect(isSelected)
	self.isSelected = isSelected

	self.selectImg:SetActive(self.isSelected)
end

return BatchAwakeWindow
