local BaseWindow = import(".BaseWindow")
local BatchShenXueWindow = class("BatchShenXueWindow", BaseWindow)
local BatchShenXueWindowItem = class("BatchShenXueWindowItem")
local HeroIcon = import("app.components.HeroIcon")

function BatchShenXueWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.filterIndex = 0
	self.isSelectAll = false
	self.selectedPartners = {}
	self.infos = {}
	self.shenXueFinish = true
	self.shenXueNum = 0
	self.items = {}
end

function BatchShenXueWindow:initWindow()
	self:getUIComponent()
	BatchShenXueWindow.super.initWindow(self)
	self:updateData()
	self:initUIComponent()
	self:register()
end

function BatchShenXueWindow:sortByTableID()
	local partners = xyd.models.slot:getPartners()
	local partnerIDs = {}

	for key in pairs(partners) do
		table.insert(partnerIDs, key)
	end

	table.sort(partnerIDs, function (a, b)
		return partners[b]:getTableID() < partners[a]:getTableID()
	end)

	return partnerIDs
end

function BatchShenXueWindow:updateData()
	local partners = xyd.models.slot:getPartners()
	local partnerIDSortByTableID = self:sortByTableID()

	for i, key in ipairs(partnerIDSortByTableID) do
		if partners[key]:getStar() == 4 and not self.selectedPartners[partners[key]:getPartnerID()] and not partners[key]:isLockFlag() then
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

				material_detail[mTableID].noClickSelected = true
				material_detail[mTableID].notPlaySaoguang = true
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
						if partners[keyid]:getGroup() == material_detail[mTableID].group and partners[keyid]:getStar() == material_detail[mTableID].star then
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
					star5TableID = star5TableID,
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

	self:updateBenchPartners()
end

function BatchShenXueWindow:updateBenchPartners()
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
						if partners[key]:getGroup() == detail.group and partners[key]:getStar() == detail.star and self.selectedPartners[partners[key]:getPartnerID()] ~= true then
							table.insert(detail.benchPartners, partners[key])
						end
					end
				end
			end
		end
	end
end

function BatchShenXueWindow:updateScroller()
	if self.infos[self.filterIndex] and #self.infos[self.filterIndex] > 0 then
		self.groupNone:SetActive(false)
		self.scrollView:SetActive(true)

		local infos = self.infos[self.filterIndex]

		for i = 1, #infos do
			if not self.items[i] then
				local tmp = NGUITools.AddChild(self.groupItem.gameObject, self.item.gameObject)
				local item = BatchShenXueWindowItem.new(tmp)

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

function BatchShenXueWindow:updateSelectItem()
	local infos = self.infos[self.filterIndex]

	for i = 1, #infos do
		self.items[i]:updateSelect(infos[i].isSelected)
	end
end

function BatchShenXueWindow:onClickFilter(filterIndex)
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

function BatchShenXueWindow:onClickBatchShenXue()
	if self.shenXueFinish == false or self.shenXueNum ~= 0 then
		return
	end

	self.shenXueFinish = false
	self.shenXueNum = 0

	if not self.infos[0] or #self.infos[0] == 0 then
		self:close()

		return
	end

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
				local msg = messages_pb:compose_partner_req()
				local materialList = {}
				local hostPartner = xyd.models.slot:getPartner(info.hostID)
				local hostTableID = hostPartner:getTableID()
				local star5TableID = xyd.tables.partnerTable:getShenxueTableId(hostTableID)
				local material = xyd.split(xyd.tables.partnerTable:getMaterial(star5TableID), "|", true)
				local materialPlace = {}

				table.insert(materialPlace, hostTableID)

				for i = 1, #material do
					table.insert(materialPlace, material[i])
				end

				for mTableID, m_detail in pairs(info.material_detail) do
					for i = 1, #m_detail.partners do
						local partner = xyd.models.slot:getPartner(m_detail.partners[i])
						local tableID = partner:getTableID()

						for j = 1, #materialPlace do
							if materialPlace[j] % 1000 ~= 999 and materialPlace[j] == tableID then
								materialList[j] = m_detail.partners[i]
								materialPlace[j] = 1

								break
							end

							if materialPlace[j] % 1000 == 999 and materialPlace[j] - materialPlace[j] % 1000 == tableID - tableID % 1000 then
								materialList[j] = m_detail.partners[i]
								materialPlace[j] = 1

								break
							end
						end
					end
				end

				msg.table_id = info.star5TableID

				for i = 1, #materialList do
					table.insert(msg.material_ids, materialList[i])
				end

				xyd.Backend:get():request(xyd.mid.COMPOSE_PARTNER, msg)

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
end

function BatchShenXueWindow:onComposePartner(event)
	self.shenXueNum = self.shenXueNum - 1

	if not self.awardItem or not self.partnerItems then
		self.awardItem = {}
		self.partnerItems = {}
	end

	local items = event.data.items

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
		partnerID = partnerItems.partner_id
	})

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

function BatchShenXueWindow:getUIComponent()
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
	self.groupNone = groupAction:NodeByName("groupNone").gameObject
	self.labelNoneTips = self.groupNone:ComponentByName("labelNoneTips", typeof(UILabel))
	self.loadingComponent = groupAction:NodeByName("loadingComponent").gameObject
	self.loadingEffect = self.loadingComponent:NodeByName("loadingEffect").gameObject
	self.loadingText = self.loadingComponent:ComponentByName("loadingText", typeof(UILabel))
end

function BatchShenXueWindow:initUIComponent()
	self.labelTitle.text = __("QUICK_STARS_TEXT02")
	self.batchShenXueBtnLabel.text = __("QUICK_STARS_TEXT03")
	self.labelNoneTips.text = __("QUICK_STARS_TEXT04")
	self.loadingText.text = __("QUICK_STARS_TEXT05")

	self:updateSelectAllBtn()

	for i = 0, 6 do
		self["filterChosen" .. i]:SetActive(i == self.filterIndex)
	end

	self:updateScroller()

	local effect = xyd.Spine.new(self.loadingEffect)

	effect:setInfo("loading", function ()
		effect:SetLocalScale(0.95, 0.95, 0.95)
		effect:play("idle", 0, 1)
	end)

	self.effect = effect
end

function BatchShenXueWindow:updateSelectAllBtn()
	if self.isSelectAll == false then
		self.allSelectBtnLabel.text = __("SELECT_ALL_YES")

		xyd.setBgColorType(self.allSelectBtn, xyd.ButtonBgColorType.blue_btn_60_60)
	else
		self.allSelectBtnLabel.text = __("SELECT_ALL_NO")

		xyd.setBgColorType(self.allSelectBtn, xyd.ButtonBgColorType.white_btn_60_60)
	end
end

function BatchShenXueWindow:onClickSelectAllBtn()
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

function BatchShenXueWindow:register()
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

	self.eventProxy_:addEventListener(xyd.event.COMPOSE_PARTNER, self.onComposePartner, self)
end

function BatchShenXueWindow:hideEffect(callback)
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

function BatchShenXueWindowItem:ctor(go)
	self.go = go
	self.icons = {}
	self.groupIcons = {}

	self:getUIComponent()
end

function BatchShenXueWindowItem:SetActive(flag)
	self.go:SetActive(flag)
end

function BatchShenXueWindowItem:getUIComponent()
	self.feedIcons = self.go:NodeByName("feedIcons").gameObject
	self.feedIconsGrid = self.feedIcons:GetComponent(typeof(UIGrid))
	self.feedIconGroup = self.go:NodeByName("feedIconGroup").gameObject
	self.partnerGroup = self.go:NodeByName("partnerGroup").gameObject
	self.selectBtn = self.go:NodeByName("selectBtn").gameObject
	self.selectImg = self.selectBtn:ComponentByName("selectImg", typeof(UISprite))
end

function BatchShenXueWindowItem:setInfo(data)
	self.data = data
	self.star5TableID = self.data.star5TableID
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
		tableID = self.star5TableID
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

function BatchShenXueWindowItem:updateSelect(isSelected)
	self.isSelected = isSelected

	self.selectImg:SetActive(self.isSelected)
end

return BatchShenXueWindow
