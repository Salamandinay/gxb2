local BaseWindow = import(".BaseWindow")
local DatesDataWindow = class("DatesDataWindow", BaseWindow)

function DatesDataWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.slot = xyd.models.slot
	self.tableID = tonumber(params.tableID)
	local partnerID = params.partner_id

	if partnerID then
		self.partner = self.slot:getPartner(partnerID)
	end
end

function DatesDataWindow:initWindow()
	BaseWindow.initWindow()
	self:getUIComponent()
	self:registerEvent()

	if not self.partner or self.slot:isRequireMaxLovePoint(self.tableID, self.partner) then
		self.slot:reqMaxLovePoint(self.tableID)
	else
		self:layout()
	end
end

function DatesDataWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.groupItems = groupAction:ComponentByName("scroller/groupItems", typeof(UITable))

	for i = 0, 3 do
		self["labelTitle" .. i] = self.groupItems:ComponentByName("groupContent" .. i .. "/labelTitle" .. i, typeof(UILabel))
		self["labelText" .. i] = self.groupItems:ComponentByName("groupContent" .. i .. "/labelText" .. i, typeof(UILabel))
		self["redIcon" .. i] = self.groupItems:NodeByName("groupContent" .. i .. "/redIcon" .. i).gameObject
	end
end

function DatesDataWindow:registerEvent()
	self:register()
	self.eventProxy_:addEventListener(xyd.event.GET_MAX_LOVE_POINT, handler(self, self.layout))
end

function DatesDataWindow:layout()
	self.lovePoint = self.slot:getMaxLovePoint(self.tableID)
	local dataIDs = xyd.tables.partnerTable:getDataID(self.tableID)
	local unLock = xyd.tables.miscTable:split2num("partner_data_lev", "value", "|")
	local DatesDataTextTable = xyd.tables.datesDataTextTable
	local key = xyd.tables.partnerTable:getShowIds(self.tableID)[1]
	local lastIndex = xyd.db.misc:getValue("partner_data_unlock_point_index" .. key) or 0
	lastIndex = tonumber(lastIndex)

	for i = 1, 4 do
		local id = dataIDs[i]
		local labelTitle = self["labelTitle" .. i - 1]
		local labelText = self["labelText" .. i - 1]
		local redIcon = self["redIcon" .. i - 1]

		if id and unLock[i] <= self.lovePoint then
			local title = DatesDataTextTable:getTitle(id)
			local text = DatesDataTextTable:getText(id)

			if lastIndex < i then
				redIcon:SetActive(true)
				xyd.db.misc:setValue({
					key = "partner_data_unlock_point_index" .. key,
					value = i
				})
			end

			if i == 1 then
				text = xyd.stringFormat(text, xyd.tables.itemTextTable:getName(xyd.tables.partnerTable:getGiftsDislike(self.tableID)[1]), xyd.tables.itemTextTable:getName(xyd.tables.partnerTable:getGiftsDislike(self.tableID)[2]), xyd.tables.itemTextTable:getName(xyd.tables.partnerTable:getGiftsLike(self.tableID)[1]), xyd.tables.itemTextTable:getName(xyd.tables.partnerTable:getGiftsLike(self.tableID)[2]))
			end

			labelTitle.text = title
			labelText.text = text

			xyd.setLabel(labelText, {
				color = 1549556991,
				size = 20,
				textAlign = NGUIText.Alignment.Left
			})
		else
			labelText.text = xyd.checkCondition(id, __("DATES_TEXT08", math.floor(unLock[i] / 100)), __("DATES_TEXT07"))
			labelTitle.text = xyd.checkCondition(id, DatesDataTextTable:getTitle(id), "")

			xyd.setLabel(labelText, {
				color = 2998055679.0,
				size = 24,
				textAlign = NGUIText.Alignment.Center
			})
		end
	end

	XYDCo.WaitForFrame(1, function ()
		if not tolua.isnull(self.window_) then
			self.groupItems:Reposition()
		end
	end, nil)
end

return DatesDataWindow
