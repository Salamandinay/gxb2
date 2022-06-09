local ActivitySpfarmRecordDetailWindow = class("ActivitySpfarmRecordDetailWindow", import(".BaseWindow"))

function ActivitySpfarmRecordDetailWindow:ctor(name, params)
	ActivitySpfarmRecordDetailWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM)
	self.log = params.log
end

function ActivitySpfarmRecordDetailWindow:initWindow()
	self:getUIComponent()
	self:layout()
end

function ActivitySpfarmRecordDetailWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("scrollView/grid", typeof(UIGrid))
	self.buildItem_ = winTrans:NodeByName("scrollView/buildItem").gameObject
	self.groupNone_ = winTrans:NodeByName("groupNone").gameObject
	self.groupNoneLabel_ = winTrans:ComponentByName("groupNone/labelNoneTips", typeof(UILabel))

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end
end

function ActivitySpfarmRecordDetailWindow:layout()
	local isSelf = false

	if self.log[1] and self.log[1] == 0 then
		self.titleLabel_.text = __("ACTIVITY_SPFARM_TEXT75")
		self.groupNoneLabel_.text = __("ACTIVITY_SPFARM_TEXT115")
	else
		isSelf = true
		self.titleLabel_.text = __("ACTIVITY_SPFARM_TEXT76")
		self.groupNoneLabel_.text = __("ACTIVITY_SPFARM_TEXT114")
	end

	local listNum = 0

	for i = 4, #self.log do
		local info = xyd.split(self.log[i], "#", false)
		local build_id = nil
		local itemNew = NGUITools.AddChild(self.grid_.gameObject, self.buildItem_)

		itemNew:SetActive(true)

		local buildImg = itemNew:ComponentByName("buildImg", typeof(UISprite))
		local lvLabel = itemNew:ComponentByName("lvLabel", typeof(UILabel))
		local indexLabel = itemNew:ComponentByName("infoBg/indexLabel", typeof(UILabel))
		local numLabel = itemNew:ComponentByName("infoBg/numLabel", typeof(UILabel))
		local itemIcon = itemNew:ComponentByName("infoBg/itemIcon", typeof(UISprite))

		if isSelf then
			local build_info = nil

			if self.log[1] and self.log[1] == 1 then
				build_info = self.activityData.detail.build_infos[tonumber(info[1])]
				build_id = build_info.build_id
			else
				build_id = tonumber(info[1])
			end

			numLabel.color = Color.New2(4199102463.0)
			numLabel.text = "-"
		else
			numLabel.color = Color.New2(1291609599)
			build_id = tonumber(info[1])
			numLabel.text = "+"
		end

		indexLabel.text = i - 3
		local outCome = xyd.tables.activitySpfarmBuildingTable:getOutcome(build_id)

		if not outCome or #outCome <= 0 then
			NGUITools.Destroy(itemNew)
		else
			local build_img = xyd.tables.activitySpfarmBuildingTable:getIcon(build_id)

			xyd.setUISpriteAsync(buildImg, nil, build_img)

			lvLabel.text = __("LV", info[2])

			xyd.setUISpriteAsync(itemIcon, nil, xyd.tables.itemTable:getIcon(outCome[1]))

			numLabel.text = numLabel.text .. math.floor(outCome[2] * info[3] * info[2])
			listNum = listNum + 1
		end
	end

	if listNum and listNum <= 0 then
		self.groupNone_:SetActive(true)
	else
		self.groupNone_:SetActive(false)
	end

	self.grid_:Reposition()
	self.scrollView_:ResetPosition()
end

return ActivitySpfarmRecordDetailWindow
