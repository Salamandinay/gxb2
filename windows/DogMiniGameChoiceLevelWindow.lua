local DogMiniGameChoiceLevelWindow = class("DogMiniGameChoiceLevelWindow", import(".BaseWindow"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local DogLevelItem = class("DogLevelItem", import("app.components.CopyComponent"))

function DogMiniGameChoiceLevelWindow:ctor(name, params)
	DogMiniGameChoiceLevelWindow.super.ctor(self, name, params)
end

function DogMiniGameChoiceLevelWindow:initWindow()
	self:getUIComponent()
	DogMiniGameChoiceLevelWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function DogMiniGameChoiceLevelWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.labelWinTitleLabel = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.labelWinTitleLabel.text = __("DOG_MINI_GAME_LEVEL_LABEL")
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.middleGroup = self.groupAction:NodeByName("middleGroup").gameObject
	self.rankListScroller = self.middleGroup:NodeByName("rankListScroller").gameObject
	self.rankListScrollerUIScrollView = self.middleGroup:ComponentByName("rankListScroller", typeof(UIScrollView))
	self.rankListContainer = self.rankListScroller:NodeByName("rankListContainer").gameObject
	self.rankListContainerUIWrapContent = self.rankListScroller:ComponentByName("rankListContainer", typeof(UIWrapContent))
	self.level_item = self.groupAction:NodeByName("level_item").gameObject
	self.wrapContent_ = FixedMultiWrapContent.new(self.rankListScrollerUIScrollView, self.rankListContainerUIWrapContent, self.level_item, DogLevelItem, self)
end

function DogMiniGameChoiceLevelWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

function DogMiniGameChoiceLevelWindow:layout()
	self:update(false)

	if not xyd.GuideController.get():isGuideComplete() then
		self.rankListScrollerUIScrollView.enabled = false
	end
end

function DogMiniGameChoiceLevelWindow:update(keepPosition)
	local ids = xyd.cloneTable(xyd.tables.dogMiniGameLevelTable:getIDs())

	if keepPosition then
		self.wrapContent_:setInfos(ids, {
			keepPosition = true
		})
	else
		self.wrapContent_:setInfos(ids, {})
		self.rankListScrollerUIScrollView:ResetPosition()
	end

	if not xyd.GuideController.get():isGuideComplete() then
		return
	end

	if keepPosition == false then
		local curMaxLevel = xyd.models.selfPlayer:getDogMiniPassLevel() + 1

		if ids[#ids] < curMaxLevel then
			curMaxLevel = ids[#ids]
		end

		if #ids > 12 then
			local moveIndex = math.ceil(curMaxLevel / 2)
			local initPos = self.rankListScrollerUIScrollView.transform.localPosition.y
			moveIndex = math.min(moveIndex, #ids - 1)

			if moveIndex > 3 then
				local sp = self.rankListScrollerUIScrollView.gameObject:GetComponent(typeof(SpringPanel))
				sp = sp or self.rankListScrollerUIScrollView.gameObject:AddComponent(typeof(SpringPanel))
				local moveDis = (moveIndex - 3) * 105
				local max = math.ceil((#ids - 12) / 2) * 105 - 70

				if moveDis > max then
					moveDis = max
				end

				local dis = initPos + moveDis

				sp.Begin(sp.gameObject, Vector3(0, dis, 0), 8)
			end
		end
	end
end

function DogLevelItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	self:getUIComponent()
	DogLevelItem.super.ctor(self, go, parent)
end

function DogLevelItem:getUIComponent()
	self.level_item = self.go
	self.bgImg = self.level_item:ComponentByName("bgImg", typeof(UISprite))
	self.levelLabel = self.level_item:ComponentByName("levelLabel", typeof(UILabel))
	self.awardsCon = self.level_item:NodeByName("awardsCon").gameObject
	self.awardsConUILayout = self.level_item:ComponentByName("awardsCon", typeof(UILayout))
	self.mengbanImg = self.level_item:ComponentByName("mengbanImg", typeof(UISprite))
	self.lockImg = self.level_item:ComponentByName("lockImg", typeof(UISprite))
	UIEventListener.Get(self.bgImg.gameObject).onClick = handler(self, function ()
		self:onClickLevel()
	end)
end

function DogLevelItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.id = info
	self.levelLabel.text = __("DOG_MINI_GAME_STAGE_LABEL", self.id)
	local awards = xyd.tables.dogMiniGameLevelTable:getAwards(self.id)

	if not self.awardsArr then
		self.awardsArr = {}
	end

	for i, data in pairs(awards) do
		local params = {
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = data[1],
			num = data[2],
			scale = Vector3(0.7037037037037037, 0.7037037037037037, 1),
			uiRoot = self.awardsCon.gameObject
		}

		if self.awardsArr[i] then
			self.awardsArr[i]:setInfo(params)
		else
			self.awardsArr[i] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		end

		self.awardsArr[i]:SetActive(true)

		if self.id <= xyd.models.selfPlayer:getDogMiniPassLevel() then
			self.awardsArr[i]:setChoose(true)
		else
			self.awardsArr[i]:setChoose(false)
		end

		if not xyd.GuideController.get():isGuideComplete() then
			local boxCollider = self.awardsArr[i]:getIconRoot().gameObject:GetComponent(typeof(UnityEngine.BoxCollider))
			boxCollider.enabled = false
		end
	end

	for i = #awards + 1, #self.awardsArr do
		self.awardsArr[i]:SetActive(false)
	end

	self.awardsConUILayout:Reposition()

	local stageId = xyd.tables.dogMiniGameLevelTable:getStageId(self.id)
	local mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
	local maxStage = nil

	if mapInfo then
		maxStage = mapInfo.max_stage
	else
		maxStage = 0
	end

	if stageId <= maxStage then
		self.mengbanImg.gameObject:SetActive(false)
		self.lockImg.gameObject:SetActive(false)

		if self.id > xyd.models.selfPlayer:getDogMiniPassLevel() + 1 then
			self.mengbanImg.gameObject:SetActive(true)
			self.lockImg.gameObject:SetActive(true)
		end
	else
		self.mengbanImg.gameObject:SetActive(true)
		self.lockImg.gameObject:SetActive(true)
	end

	self:waitForFrame(3, function ()
		if self.id == 1 then
			self.parent.guideItemClick1 = self.bgImg.gameObject
		elseif self.id == 2 then
			self.parent.guideItemClick2 = self.bgImg.gameObject
		elseif self.id == 3 then
			self.parent.guideItemClick3 = self.bgImg.gameObject
		end
	end)
end

function DogLevelItem:getGameObject()
	return self.go
end

function DogLevelItem:onClickLevel()
	local stageId = xyd.tables.dogMiniGameLevelTable:getStageId(self.id)
	local mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
	local maxStage = nil

	if mapInfo then
		maxStage = mapInfo.max_stage
	else
		maxStage = 0
	end

	if stageId <= maxStage then
		if self.id > xyd.models.selfPlayer:getDogMiniPassLevel() + 1 then
			self.mengbanImg.gameObject:SetActive(true)
			self.lockImg.gameObject:SetActive(true)
			xyd.alertTips(__("DOG_MINI_GAME_BEFORE_LABEL"))
		else
			xyd.WindowManager.get():openWindow("dog_mini_game_window", {
				level = self.id
			})
		end
	else
		local fortId = xyd.tables.stageTable:getFortID(stageId)
		local text = tostring(fortId) .. "-" .. tostring(xyd.tables.stageTable:getName(stageId))

		xyd.showToast(__("FUNC_OPEN_STAGE", text))
	end
end

return DogMiniGameChoiceLevelWindow
