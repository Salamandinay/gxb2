local BaseWindow = import(".BaseWindow")
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local PartnerCard = import("app.components.PartnerCard")
local Partner = import("app.models.Partner")
local ViewDatesItem = class("ViewDatesItem")

function ViewDatesItem:ctor(go, parent)
	self.go = go
	self.parent = parent
end

function ViewDatesItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data = info

	self:initItem()
end

function ViewDatesItem:initItem()
	NGUITools.DestroyChildren(self.go.transform)

	local icon = PartnerCard.new(self.go)
	local skinPictureID = xyd.tables.itemTable:getSkinID(self.data.skin_id)
	local isGray = xyd.models.backpack:getItemNumByID(skinPictureID) <= 0
	self.data.is_gray = isGray

	icon:setSkinCard(self.data)
	icon.go.transform:SetLocalScale(0.93, 0.93, 1)
	self:onClick()
end

function ViewDatesItem:onClick()
	UIEventListener.Get(self.go).onClick = handler(self, function ()
		if not self.data then
			return
		end

		local table_id = self.data.table_id
		local params = {
			partner_id = self.data.partner_id,
			sort_key = self.data.group,
			table_id = self.data.tableID,
			skin_id = self.data.skin_id,
			partners = self.parent.guidePartners[7]
		}

		xyd.WindowManager.get():openWindow("skin_detail_window", params)
	end)
end

function ViewDatesItem:getGameObject()
	return self.go
end

local ViewDatesSkinWindow = class("ViewDatesSkinWindow", BaseWindow)

function ViewDatesSkinWindow:ctor(name, params)
	ViewDatesSkinWindow.super.ctor(self, name, params)

	self.skins_ = {}
	self.sortedPartners = {}
end

function ViewDatesSkinWindow:initWindow()
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
	self:initData()
	self:initDataArr()
end

function ViewDatesSkinWindow:getUIComponent()
	local go = self.window_.transform
	self.itemCell = go:NodeByName("itemCell").gameObject
	local e_Group = go:NodeByName("e:Group").gameObject
	self.e_Image = e_Group:NodeByName("e:Image").gameObject
	self.closeBtn = e_Group:NodeByName("closeBtn").gameObject
	self.labelTitle_ = e_Group:ComponentByName("labelTitle_", typeof(UILabel))
	self.scroller_ = e_Group:ComponentByName("e:Group/scroller_", typeof(UIScrollView))
	self.scroller_UIpanel = e_Group:ComponentByName("e:Group/scroller_", typeof(UIPanel))
	self.groupMain_MultiRowWrapContent = self.scroller_:ComponentByName("groupMain_", typeof(MultiRowWrapContent))
	self.groupMain_ = FixedMultiWrapContent.new(self.scroller_, self.groupMain_MultiRowWrapContent, self.itemCell, ViewDatesItem, self)
	local maxDepth = XYDUtils.GetMaxTargetDepth(self.window_)
	self.scroller_UIpanel.depth = maxDepth + 1
end

function ViewDatesSkinWindow:initUIComponent()
	self.labelTitle_.text = __("VIEW_DATES_SKIN_TITLE")
end

function ViewDatesSkinWindow:registerEvent()
	ViewDatesSkinWindow.super.register(self)
end

function ViewDatesSkinWindow:initData()
	local ids = xyd.tables.equipTable:getIDs()
	local id = 1

	for i = #ids, 1, -1 do
		local skinID = ids[i]

		if xyd.tables.itemTable:getType(skinID) == xyd.ItemType.SKIN then
			local showTime = xyd.tables.partnerPictureTable:getShowTime(skinID)

			if showTime == nil or showTime <= xyd.getServerTime() then
				local pID = xyd.tables.partnerPictureTable:getSkinPartner(skinID)[1]

				if pID ~= nil then
					local ifWedding = xyd.tables.partnerPictureTable:getIsWedding(skinID)

					if ifWedding == true then
						local groupID = xyd.tables.partnerTable:getGroup(pID)
						local skinPictureID = xyd.tables.itemTable:getSkinID(skinID)
						local isGray = false
						local item = {
							name = true,
							is_equip = false,
							skin_id = skinID,
							is_gray = isGray,
							group = groupID,
							tableID = pID
						}

						table.insert(self.skins_, item)

						id = id + 1
					end
				end
			end
		end
	end

	table.sort(self.skins_, function (a, b)
		return b.skin_id < a.skin_id
	end)
	self.groupMain_:setInfos(self.skins_, {})
end

function ViewDatesSkinWindow:initDataArr()
	local guidePartners = {}
	local groupIds = xyd.tables.groupTable:getGroupIds()
	guidePartners[0] = {}

	for i = 1, #groupIds do
		guidePartners[groupIds[i]] = {}
	end

	local heroConf = xyd.tables.partnerTable
	local heroIds = heroConf:getIds()

	for _, id in ipairs(heroIds) do
		for k, v in pairs(self.skins_) do
			if v.tableID == id then
				table.insert(guidePartners[v.group], {
					table_id = v.tableID,
					key = v.group,
					parent = self
				})
			end
		end
	end

	guidePartners[#groupIds + 1] = {}

	for k, v in pairs(self.skins_) do
		table.insert(guidePartners[#groupIds + 1], {
			table_id = v.tableID,
			key = v.group,
			parent = self,
			skin_id = v.skin_id
		})
	end

	self.guidePartners = guidePartners
end

return ViewDatesSkinWindow
