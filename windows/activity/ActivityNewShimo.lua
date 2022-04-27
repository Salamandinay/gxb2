local CountDown = import("app.components.CountDown")
local ActivityContent = import(".ActivityContent")
local ActivityNewShimo = class("ActivityNewShimo", ActivityContent)
local ActivityNewShimoItem = class("ValueGiftBagItem", import("app.components.CopyComponent"))
ActivityNewShimo.ActivityNewShimoItem = ActivityNewShimoItem
local posX = {
	-20,
	20,
	2,
	-12
}
local posY = {
	-90,
	-120,
	-170,
	-190
}
local myScale = {
	0.56,
	0.56,
	0.54,
	0.52
}

function ActivityNewShimo:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.curModel = 4
	self.onAni = false

	xyd.models.activity:reqActivityByID(self.id)
end

function ActivityNewShimo:getPrefabPath()
	return "Prefabs/Windows/activity/activity_new_shimo"
end

function ActivityNewShimo:resizeToParent()
	ActivityNewShimo.super.resizeToParent(self)

	local height = self.go:GetComponent(typeof(UIWidget)).height

	self.midGroup:Y(-0.337 * (height - 869))
	self.nameGroup:Y(0.174 * (height - 869) - 151)
end

function ActivityNewShimo:initUI()
	self:getUIComponent()
	ActivityNewShimo.super.initUI(self)
	self:layout()
end

function ActivityNewShimo:getUIComponent()
	local go = self.go
	self.groupMain = go:NodeByName("groupMain").gameObject
	self.textImg = self.groupMain:ComponentByName("textImg", typeof(UISprite))
	self.helpBtn = self.groupMain:NodeByName("helpBtn").gameObject
	self.midGroup = self.groupMain:NodeByName("midGroup").gameObject
	self.nameGroup = self.midGroup:NodeByName("nameGroup").gameObject
	self.nameLabel1 = self.midGroup:ComponentByName("nameGroup/label1", typeof(UILabel))
	self.nameLabel2 = self.midGroup:ComponentByName("nameGroup/label2", typeof(UILabel))
	self.model1 = self.midGroup:NodeByName("model1").gameObject
	self.model2 = self.midGroup:NodeByName("model2").gameObject
	self.arrow1 = self.midGroup:NodeByName("arrow1").gameObject
	self.arrow2 = self.midGroup:NodeByName("arrow2").gameObject
	self.buttomGroup = self.groupMain:NodeByName("buttomGroup").gameObject
	self.descGroup = self.buttomGroup:NodeByName("descGroup").gameObject
	self.timeLabel = self.descGroup:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.endLabel = self.descGroup:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.descLabel = self.descGroup:ComponentByName("descLabel", typeof(UILabel))
	self.jumpBtn = self.buttomGroup:NodeByName("btn").gameObject
	self.jumpBtnLabel = self.jumpBtn:ComponentByName("label", typeof(UILabel))
	self.e_Scroller = self.buttomGroup:ComponentByName("e:Scroller", typeof(UIScrollView))
	self.e_Scroller_uiPanel = self.buttomGroup:ComponentByName("e:Scroller", typeof(UIPanel))
	self.groupItem = self.e_Scroller_uiPanel:NodeByName("groupItem")
	self.groupItem_uigrid = self.groupItem:GetComponent(typeof(UIGrid))
	self.littleItem = go.transform:Find("level_fund_item")
end

function ActivityNewShimo:layout()
	xyd.setUISpriteAsync(self.textImg, nil, "activity_new_shimo_logo_" .. xyd.Global.lang)
	self:setText()

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	local model = xyd.Spine.new(self.model1)

	model:setInfo("shimo_golem_4", function ()
		model:SetLocalPosition(posX[4], posY[4], 0)
		model:SetLocalScale(myScale[4], myScale[4], myScale[4])
		model:play("idle", 0)
	end)
end

function ActivityNewShimo:setText()
	self.endLabel.text = __("TEXT_END")
	self.descLabel.text = __("ACTIVITY_NEW_SHIMO_MASK_TEXT05")
	self.nameLabel2.text = __("ACTIVITY_NEW_SHIMO_MASK_TEXT04")
	self.nameLabel1.text = xyd.tables.petTextTable:getName(xyd.PetId.GOLEM)
	self.jumpBtnLabel.text = __("ACTIVITY_NEW_SHIMO_MASK_GO")
end

function ActivityNewShimo:setItem()
	local ids = xyd.tables.activityPetTaskTable:getIDs()
	self.data = {}

	for i, v in pairs(ids) do
		local id = ids[i]
		local param = {
			id = id,
			isCompleted = self.activityData.detail.m_awarded[id],
			max_point = xyd.tables.activityPetTaskTable:getComplete(id),
			point = self.activityData.detail.m_value[id],
			awarded = xyd.tables.activityPetTaskTable:getAwards(id),
			scroll = self.e_Scroller
		}

		table.insert(self.data, param)
	end

	table.sort(self.data, function (a, b)
		if a.isCompleted == b.isCompleted then
			return tonumber(a.id) < tonumber(b.id)
		else
			return a.isCompleted < b.isCompleted
		end
	end)

	local tempArr = {}

	NGUITools.DestroyChildren(self.groupItem.transform)

	for i in ipairs(self.data) do
		local tmp = NGUITools.AddChild(self.groupItem.gameObject, self.littleItem.gameObject)

		table.insert(tempArr, tmp)

		local item = ActivityNewShimoItem.new(tmp, self.data[i])
	end

	self.littleItem:SetActive(false)
	self.groupItem_uigrid:Reposition()
end

function ActivityNewShimo:onRegister()
	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_NEW_SHIMO_MASK_HELP"
		})
	end)
	UIEventListener.Get(self.jumpBtn).onClick = handler(self, function ()
		if xyd.models.petSlot:getPetByID(xyd.PetId.GOLEM):getLevel() <= 0 then
			xyd.WindowManager.get():openWindow("pet_window", {
				jumpIndex = xyd.PetId.GOLEM
			})
		else
			xyd.WindowManager.get():openWindow("pet_detail_window", {
				pet_id = xyd.PetId.GOLEM
			})
		end
	end)
	UIEventListener.Get(self.arrow1).onClick = handler(self, function ()
		if not self.onAni then
			self:changeModel(-1)
		end
	end)
	UIEventListener.Get(self.arrow2).onClick = handler(self, function ()
		if not self.onAni then
			self:changeModel(1)
		end
	end)

	self:registerEvent(xyd.event.WINDOW_WILL_CLOSE, handler(self, self.onWndClose))
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, function ()
		self:setItem()
		dump(self.activityData.detail)
	end))
end

function ActivityNewShimo:onWndClose(event)
	local windowName = event.params.windowName

	if windowName == "pet_window" or windowName == "pet_detail_window" then
		xyd.models.activity:reqActivityByID(self.id)
	end
end

function ActivityNewShimo:changeModel(i)
	self.onAni = true
	local model2 = xyd.Spine.new(self.model2)

	model2:setInfo("shimo_golem_" .. self.curModel, function ()
		model2:SetLocalPosition(posX[self.curModel], posY[self.curModel], 0)
		model2:SetLocalScale(myScale[self.curModel], myScale[self.curModel], myScale[self.curModel])
		model2:play("idle", 0)
	end)
	self.model2:X(-9)

	self.curModel = self.curModel + i

	if self.curModel == 5 then
		self.curModel = 1
	elseif self.curModel == 0 then
		self.curModel = 4
	end

	self.nameLabel2.text = __("ACTIVITY_NEW_SHIMO_MASK_TEXT0" .. self.curModel)

	NGUITools.DestroyChildren(self.model1.transform)

	local model1 = xyd.Spine.new(self.model1)

	model1:setInfo("shimo_golem_" .. self.curModel, function ()
		model1:SetLocalPosition(posX[self.curModel], posY[self.curModel], 0)
		model1:SetLocalScale(myScale[self.curModel], myScale[self.curModel], myScale[self.curModel])
		model1:play("idle", 0)
	end)

	local sequence = self:getSequence()
	local w1 = self.model1:GetComponent(typeof(UIWidget))
	local height = w1.transform.localPosition.y
	local dis = 0

	if i > 0 then
		self.model1:X(-800)

		dis = 782
	else
		self.model1:X(782)

		dis = -800
	end

	sequence:Append(self.model1.transform:DOLocalMove(Vector3(-9, height, 0), 1):SetEase(DG.Tweening.Ease.OutSine)):Join(self.model2.transform:DOLocalMove(Vector3(dis, height, 0), 1):SetEase(DG.Tweening.Ease.OutSine)):AppendCallback(function ()
		self.onAni = false

		NGUITools.DestroyChildren(self.model2.transform)
	end)
end

function ActivityNewShimoItem:ctor(goItem, itemdata)
	ActivityNewShimoItem.super.ctor(self, goItem)

	self.goItem_ = goItem
	local transGo = goItem.transform
	self.itemdata = itemdata
	self.id = tonumber(itemdata.id)
	self.imgbg = transGo:ComponentByName("e:Image", typeof(UITexture))
	self.progressBar_ = transGo:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressImg = transGo:ComponentByName("progressBar_/progressImg", typeof(UISprite))
	self.progressDesc = transGo:ComponentByName("progressBar_/progressLabel", typeof(UILabel))
	self.labelTitle_ = transGo:ComponentByName("labelTitle", typeof(UILabel))
	self.itemsGroup_ = transGo:Find("itemsGroup")

	self:initItem()
	self:initBaseInfo()
end

function ActivityNewShimoItem:initBaseInfo()
	self.labelTitle_.text = xyd.tables.activityPetTaskTextTable:getDesc(self.id)

	xyd.setUITextureAsync(self.imgbg, "Textures/activity_web/miracle_giftbag/miracle_giftbag_special_item_bg")
end

function ActivityNewShimoItem:initItem()
	self.progressBar_.value = math.min(self.itemdata.point, self.itemdata.max_point) / self.itemdata.max_point
	self.progressDesc.text = math.min(self.itemdata.point, self.itemdata.max_point) .. "/" .. self.itemdata.max_point

	for i, reward in pairs(self.itemdata.awarded) do
		local icon = xyd.getItemIcon({
			show_has_num = true,
			itemID = reward[1],
			num = reward[2],
			uiRoot = self.itemsGroup_.gameObject,
			scale = Vector3(0.6, 0.6, 1),
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.itemdata.scroll
		})

		if self.itemdata.isCompleted == 0 then
			icon:setChoose(false)
		else
			icon:setChoose(true)
			self:waitForFrame(1, function ()
				xyd.setUISpriteAsync(self.progressImg, nil, "activity_bar_thumb_2")
			end)
		end
	end

	self.itemsGroup_:GetComponent(typeof(UILayout)):Reposition()
end

return ActivityNewShimo
