local PartnerTable = xyd.tables.partnerTable
local PartnerDirectTable = xyd.tables.partnerDirectTable
local MiscTable = xyd.tables.miscTable
local FilterWordTable = xyd.tables.filterWordTable
local SkillTextTable = xyd.tables.skillTextTable
local DirectArtifactTextTable = xyd.tables.directArtifactTextTable
local PartnerLabelTypeTable = xyd.tables.partnerLabelTypeTable
local PartnerLabelTable = xyd.tables.partnerLabelTable
local PartnerArrayTable = xyd.tables.partnerArrayTable
local PartnerDataStation = xyd.models.partnerDataStation
local PartnerComment = xyd.models.partnerComment
local Partner = import("app.models.Partner")
local Monster = import("app.models.Monster")
local Slot = xyd.models.slot
local SelfPlayer = xyd.models.selfPlayer
local PartnerCard = import("app.components.PartnerCard")
local SkillIcon = import("app.components.SkillIcon")
local ItemIcon = import("app.components.ItemIcon")
local HeroIcon = import("app.components.HeroIcon")
local CommentPage = import("app.components.CommentPage")
local PlayerIcon = import("app.components.PlayerIcon")
local PartnerCommentComponent = class("PartnerCommentComponent", import("app.components.BaseComponent"))
local PartnerDirectionLabelComponent = class("PartnerDirectionLabelComponent", import("app.components.BaseComponent"))
local PartnerDirectionSkillComponent = class("PartnerDirectionSkillComponent", import("app.components.BaseComponent"))
local PartnerDirectionArtifactComponent = class("PartnerDirectionArtifactComponent", import("app.components.BaseComponent"))
local PartnerDirectionComponent = class("PartnerDirectionComponent", import("app.components.BaseComponent"))
local PartnerDataStationWindow = class("PartnerDataStationWindow", import(".BaseWindow"))
local PartnerStationFormation = class("PartnerStationFormation", import("app.components.BaseComponent"))
local PartnerArrayComponent = class("PartnerArrayComponent", import("app.components.BaseComponent"))
local TYPE = {
	HOT = 1,
	COMMON = 2
}

function PartnerCommentComponent:ctor(parentGO, params)
	PartnerCommentComponent.super.ctor(self, parentGO)

	self.itemList = {}
	self.hotList = {}
	self.collection = {}
	self.commentModel = PartnerComment
	self.default_label_num_ = 3
	self.table_id = params.table_id
	self.partner_table_id = params.partner_table_id
	self.eventProxy_ = self.eventProxyInner_
	self.parentWin = params.parentWin

	self:initSprite()
	self:createChildren()

	self.scrollerPanel.depth = self.parentWin.window_:GetComponent(typeof(UIPanel)).depth + 2
	self.inputPanel.depth = self.parentWin.window_:GetComponent(typeof(UIPanel)).depth + 3
end

function PartnerCommentComponent:getPrefabPath()
	return "Prefabs/Components/partner_comment_component"
end

function PartnerCommentComponent:initUI()
	PartnerCommentComponent.super.initUI(self)

	local go = self.go
	self.imgTitle = go:ComponentByName("imgTitle", typeof(UISprite))
	self.labelTitle = go:ComponentByName("labelTitle", typeof(UILabel))
	self.likeBtn = go:ComponentByName("likeBtn", typeof(UISprite))
	self.likeBtnLabel = go:ComponentByName("likeBtn/likeBtnLabel", typeof(UILabel))
	self.likeLabel = go:ComponentByName("likeLabel", typeof(UILabel))
	self.likeNum = go:ComponentByName("likeNum", typeof(UILabel))
	self.groupMain_ = go:NodeByName("groupMain_").gameObject
	self.group1 = self.groupMain_:NodeByName("group1").gameObject
	self.image1_1 = self.group1:ComponentByName("image1_1", typeof(UISprite))
	self.image1_2 = self.group1:ComponentByName("image1_2", typeof(UISprite))
	self.image1_3 = self.group1:ComponentByName("image1_3", typeof(UISprite))
	self.labelPartnerLabel = self.group1:ComponentByName("labelPartnerLabel", typeof(UILabel))
	self.groupAllLabels = self.group1:NodeByName("groupAllLabels").gameObject
	self.groupLabels = self.groupAllLabels:NodeByName("groupLabels").gameObject
	self.groupCustom = self.groupAllLabels:NodeByName("groupCustom").gameObject
	self.image1_4 = self.groupCustom:ComponentByName("image1_4", typeof(UISprite))
	self.labelCustom = self.groupCustom:ComponentByName("labelCustom", typeof(UILabel))
	self.group2 = self.groupMain_:NodeByName("group2").gameObject
	self.image2_1 = self.group2:ComponentByName("image2_1", typeof(UISprite))
	self.image2_2 = self.group2:ComponentByName("image2_2", typeof(UISprite))
	self.labelPartnerLabel0 = self.group2:ComponentByName("labelPartnerLabel0", typeof(UILabel))
	self.mainContent = self.group2:NodeByName("mainContent").gameObject
	self.scrollerPanel = self.mainContent:ComponentByName("scroller", typeof(UIPanel))
	self.container = self.mainContent:NodeByName("scroller/container").gameObject
	local textInputGroup = go:NodeByName("textInputGroup").gameObject
	self.avatarImg = textInputGroup:ComponentByName("avatarImg", typeof(UISprite))
	self.inputPanel = textInputGroup:ComponentByName("inputPanel", typeof(UIPanel))
	self.textInput = textInputGroup:ComponentByName("inputPanel/textInput", typeof(UIInput))
	self.textInputLabel = textInputGroup:ComponentByName("inputPanel/textInput/GameObject", typeof(UILabel))
	self.sendBtn = textInputGroup:ComponentByName("sendBtn", typeof(UISprite))
	self.imgTextInput = textInputGroup:ComponentByName("imgTextInput", typeof(UISprite))

	xyd.addTextInput(self.textInputLabel, {
		type = xyd.TextInputArea.InputSingleLine,
		getText = function ()
			if not self.isFirstOpenText then
				self.isFirstOpenText = true

				return ""
			end

			return self.textInputLabel.text
		end,
		callback = function ()
			self.textInputLabel.color = Color.New2(1179277055)
		end
	})

	self.textInput:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
end

function PartnerCommentComponent:initSprite()
	xyd.setUISpriteAsync(self.imgTitle, nil, "station_title_bg")
	xyd.setUISpriteAsync(self.image1_1, nil, "station_formation_bg")
	xyd.setUISpriteAsync(self.image1_2, nil, "station_bg_cell")
	xyd.setUISpriteAsync(self.image1_3, nil, "station_small_formation_bg")
	xyd.setUISpriteAsync(self.image1_4, nil, "station_label_custom")
	xyd.setUISpriteAsync(self.image2_1, nil, "station_formation_bg")
	xyd.setUISpriteAsync(self.image2_2, nil, "station_small_formation_bg")
	xyd.setUISpriteAsync(self.imgTextInput, nil, "comic_comment_input_bg")
	xyd.setUISpriteAsync(self.sendBtn, nil, "comic_comment_send_btn")
end

function PartnerCommentComponent:createChildren()
	self:registerEvent()
	self:setWndComplete()
	self:updateLabelGroup()
	self.commentModel:reqCommentsData(self.table_id)
end

function PartnerCommentComponent:registerEvent()
	UIEventListener.Get(self.groupCustom.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("partner_label_select_window", {
			table_id = self.table_id
		})
	end

	UIEventListener.Get(self.sendBtn.gameObject).onClick = handler(self, self.onSend)

	self.eventProxy_:addEventListener(xyd.event.COMMENT_PARTNER, handler(self, self.onComment))
	self.eventProxy_:addEventListener(xyd.event.GET_PARTNER_COMMENTS, handler(self, self.onGetComment))

	UIEventListener.Get(self.likeBtn.gameObject).onClick = function ()
		if self.commentModel:getIsLike(self.table_id) == 0 then
			self.commentModel:incrLikeNum(self.table_id)

			self.likeNum.text = self.commentModel:getLikeNum(self.table_id)
		end

		self.commentModel:reqLikePartner(self.table_id)
		xyd.setUISpriteAsync(self.likeBtn, nil, "partner_like01")
	end

	self.eventProxy_:addEventListener(xyd.event.UPDATE_PARTNER_TAGS, handler(self, self.updateLabelGroup))
end

function PartnerCommentComponent:setWndComplete()
	self.textInputLabel.text = __("PARTNER_WAIT_TO_ADD_COMMENT")
	self.labelTitle.text = __("PARTNER_COMMENTS")
	self.likeLabel.text = __("RECEIVE_LIKE")
	self.likeBtnLabel.text = __("LIKE")
	self.labelPartnerLabel.text = __("PARTNER_STATION_LABEL_TITLE")
	self.labelPartnerLabel0.text = __("PARTNER_COMMENT_ALL")
	self.labelCustom.text = __("PARTNER_STATION_LABEL_CUSTOMIZE")

	if xyd.Global.lang == "ja_jp" then
		self.imgTextInput.height = 60
		self.textInputLabel.overflowMethod = UILabel.Overflow.ClampContent
		self.textInputLabel.width = 410
		self.textInputLabel.height = 50
		self.textInputLabel:GetComponent(typeof(UnityEngine.BoxCollider)).size = Vector3(410, 50, 0)
		self.textInputLabel:GetComponent(typeof(UnityEngine.BoxCollider)).center = Vector3(205, 0, 0)
	else
		self.imgTextInput.height = 40
		self.textInputLabel.overflowMethod = UILabel.Overflow.ClampContent
		self.textInputLabel.width = 410
		self.textInputLabel.height = 30
		self.textInputLabel:GetComponent(typeof(UnityEngine.BoxCollider)).size = Vector3(410, 30, 0)
		self.textInputLabel:GetComponent(typeof(UnityEngine.BoxCollider)).center = Vector3(205, 0, 0)
	end

	if xyd.Global.lang == "de_de" then
		self.labelCustom:X(-35)

		self.labelCustom.fontSize = 20
	end

	self:setAvatar()
end

function PartnerCommentComponent:updateLabelGroup()
	NGUITools.DestroyChildren(self.groupLabels.transform)

	local ids = PartnerDataStation:getSelfLabels(self.table_id)

	for _, id in pairs(ids) do
		local labelComp = PartnerDirectionLabelComponent.new(self.groupLabels, {
			no_click = true,
			id = id
		})
	end

	self.groupLabels:GetComponent(typeof(UILayout)):Reposition()

	local bound = NGUITools.CalculateRelativeWidgetBounds(self.go.transform, self.groupLabels.transform)
	self.groupLabels:GetComponent(typeof(UIWidget)).height = bound.size.y
	self.groupAllLabels:GetComponent(typeof(UIWidget)).height = bound.size.y + 57
	self.group1:GetComponent(typeof(UIWidget)).height = bound.size.y + 142
	self.group2:GetComponent(typeof(UIWidget)).height = 702 - (bound.size.y + 142) - 10
end

function PartnerCommentComponent:onSend()
	local msg = self.textInputLabel.text

	if not self.isFirstOpenText then
		msg = ""
	end

	if not self:checkMsg(msg) then
		return
	end

	self.commentModel:reqComment(self.table_id, msg)
end

function PartnerCommentComponent:checkMsg(msg)
	local collection = Slot:getCollection()
	local hasFlag = false
	local partnerIds = PartnerDirectTable:getTableIds(self.table_id)

	for i = 1, #partnerIds do
		if collection[partnerIds[i]] then
			hasFlag = true

			break
		end
	end

	if not hasFlag then
		xyd.showToast(__("PARTNER_COMMENT_LOCKED"))

		return false
	end

	local data = MiscTable:split2Cost("partner_comment_length_limit" .. "_" .. tostring(xyd.Global.lang), "value", "|")

	if not msg or xyd.getStrLength(msg) < data[1] then
		xyd.showToast(__("PARTNER_COMMENT_MSG_LESS"))

		return false
	elseif data[2] < xyd.getStrLength(msg) then
		xyd.showToast(__("PARTNER_COMMENT_MSG_LIMIT"))

		return false
	elseif FilterWordTable:isInWords(msg) then
		xyd.showToast(__("COMIC_COMMENT_DIRTY"))

		return false
	elseif self.commentModel:checkIsBanner() then
		local bannerCD = self.commentModel:getBannerEndTime()
		bannerCD = math.ceil(bannerCD / 60)

		xyd.showToast(__("BAN_COMMENT_TIPS", bannerCD))

		return false
	end

	return true
end

function PartnerCommentComponent:onComment(event)
	local data = event.data

	if data.table_id ~= self.table_id then
		return
	end

	self.textInput.value = ""
	self.textInputLabel.text = ""

	xyd.showToast(__("PARTNER_COMMENT_SUCCESSFULLY_SEND"))
	self:initAllItems()
end

function PartnerCommentComponent:onGetComment(event)
	self:initAllItems()
end

function PartnerCommentComponent:initAllItems()
	self:initHot()
	self:initCommon()
	self:initDataGroup()
	self:initLikeDetail()
end

function PartnerCommentComponent:initLikeDetail()
	local isLike = self.commentModel:getIsLike(self.table_id)

	if isLike > 0 then
		xyd.setUISpriteAsync(self.likeBtn, nil, "partner_like01")
	else
		xyd.setUISpriteAsync(self.likeBtn, nil, "partner_like02")
	end

	self.likeNum.text = self.commentModel:getLikeNum(self.table_id)
end

function PartnerCommentComponent:initDataGroup()
	if not self.commentPage_ then
		self.commentPage_ = CommentPage.new(self.mainContent, self, self.table_id)
	end

	self.commentPage_:setInfo(self.collection)
	self.commentPage_:init()
end

function PartnerCommentComponent:initHot()
	self.collection = {}
	local comments = self.commentModel:getHotComment(self.table_id)

	for i = 1, #comments do
		local tmpComment = table.clone(comments[i])
		tmpComment.type = TYPE.HOT
		tmpComment.index = i

		table.insert(self.collection, tmpComment)
	end
end

function PartnerCommentComponent:initCommon()
	self.itemList = {}
	local comments = self.commentModel:getComments(self.table_id)

	table.sort(comments, function (a, b)
		return b.created_time < a.created_time
	end)

	for i = 1, #comments do
		local tmpComment = table.clone(comments[i])
		tmpComment.index = i
		tmpComment.type = TYPE.COMMON
		tmpComment.table_id = self.table_id

		table.insert(self.collection, tmpComment)
	end
end

function PartnerCommentComponent:setAvatar()
	local avatarID = SelfPlayer:getAvatarID()
	local iconType = xyd.tables.itemTable:getType(avatarID)
	local iconName = ""

	if iconType == xyd.ItemType.HERO_DEBRIS then
		local partnerCost = xyd.tables.itemTable:partnerCost(avatarID)
		iconName = xyd.tables.partnerTable:getAvatar(partnerCost[1])
	elseif iconType == xyd.ItemType.HERO then
		iconName = xyd.tables.partnerTable:getAvatar(avatarID)
	elseif iconType == xyd.ItemType.SKIN then
		iconName = xyd.tables.equipTable:getSkinAvatar(avatarID)
	else
		iconName = xyd.tables.itemTable:getIcon(avatarID)
	end

	if avatarID and avatarID > 0 then
		xyd.setUISpriteAsync(self.avatarImg, nil, iconName)
		self.avatarImg:SetActive(true)
	else
		self.avatarImg:SetActive(false)
	end
end

function PartnerCommentComponent:updateReportItem(newReportItem)
end

function PartnerDirectionLabelComponent:ctor(parentGo, params)
	PartnerDirectionLabelComponent.super.ctor(self, parentGo)

	self.id = params.id
	self.noClick = params.no_click
	self.ifChoose = false
	self.ifSelfLabel = params.if_self_label

	self:layout()
	self:registerEvent()
end

function PartnerDirectionLabelComponent:getPrefabPath()
	return "Prefabs/Components/partner_direction_label_component"
end

function PartnerDirectionLabelComponent:initUI()
	PartnerDirectionLabelComponent.super.initUI(self)

	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UISprite))
	self.labelTag = go:ComponentByName("labelTag", typeof(UILabel))
	self.imgSelect = go:ComponentByName("imgSelect", typeof(UISprite))
end

function PartnerDirectionLabelComponent:layout()
	local tables = PartnerLabelTable
	local src = PartnerLabelTypeTable:getLabelIcon(tables:getLabelType(self.id))
	local text = tables:getLabelText(self.id)

	if not text then
		return
	end

	if not self.ifSelfLabel and PartnerDataStation:checkIfEnough(self.id) then
		text = text .. "(" .. PartnerDataStation:getLabelNum(self.id) .. ")"
	end

	xyd.setUISpriteAsync(self.imgBg, nil, src)

	self.labelTag.text = text
	self.labelTag.effectColor = Color.New2(PartnerLabelTypeTable:getLabelTextColor(tables:getLabelType(self.id)))

	xyd.setUISpriteAsync(self.imgSelect, nil, "select")

	local width = self.labelTag:GetComponent(typeof(UIWidget)).width
	self.imgBg:GetComponent(typeof(UIWidget)).width = width + 60
	self.go:GetComponent(typeof(UIWidget)).width = width + 60
end

function PartnerDirectionLabelComponent:registerEvent()
	if not self.noClick then
		UIEventListener.Get(self.go).onClick = function ()
			self.ifChoose = not self.ifChoose

			self.imgSelect:SetActive(self.ifChoose)
		end
	end
end

function PartnerDirectionSkillComponent:ctor(parentGo, parentWindow, params)
	PartnerDirectionSkillComponent.super.ctor(self, parentGo)

	self.parentWnd = parentWindow
	self.partner_id_ = params.partner_id
	self.id = params.id

	self:onRegister()
	self:layout()
end

function PartnerDirectionSkillComponent:getPrefabPath()
	return "Prefabs/Components/partner_direction_skill_component"
end

function PartnerDirectionSkillComponent:initUI()
	PartnerDirectionSkillComponent.super.initUI(self)

	local skilliconRoot = self.go:NodeByName("skillIconRoot").gameObject
	self.skillIconRoot = skilliconRoot
	self.skillIcon = SkillIcon.new(skilliconRoot)
	self.labelPartnerSkillName = self.go:ComponentByName("labelPartnerSkillName", typeof(UILabel))
	self.labelPartnerSkillDesc = self.go:ComponentByName("labelPartnerSkillDesc", typeof(UILabel))
	self.showGroup = NGUITools.AddChild(self.go, "tipGroup")
	self.showGroup:AddComponent(typeof(UIWidget)).depth = 130
	self.showGroup:GetComponent(typeof(UIWidget)).pivot = UIWidget.Pivot.Top

	self.showGroup:SetLocalPosition(0, -110, 0)
end

function PartnerDirectionSkillComponent:onRegister()
	UIEventListener.Get(self.skillIconRoot).onClick = function ()
		self.skillIcon:showTips(true, self.skillIcon.showGroup, true, nil, 0)
		self.parentWnd:clearSkillTips()
		self.parentWnd:setGroupY(self.skillIcon)
		self.parentWnd.imgSkill:SetActive(true)
		XYDCo.WaitForFrame(1, function ()
			self.showGroup:SetActive(true)
		end, nil)
	end
end

function PartnerDirectionSkillComponent:layout()
	local tables = PartnerDirectTable
	local skillID = tables:getSkillId(self.partner_id_, self.id)

	self.skillIcon:setInfo(skillID, {
		scale = 0.83,
		showGroup = self.showGroup
	})

	self.labelPartnerSkillName.text = SkillTextTable:getName(skillID)
	self.labelPartnerSkillDesc.text = tables:getSkillDesc(self.partner_id_, self.id)
	self.go:GetComponent(typeof(UIWidget)).height = math.max(90, self.labelPartnerSkillDesc:GetComponent(typeof(UIWidget)).height + 34)
end

function PartnerDirectionSkillComponent:getSkillIcon()
	return self.skillIcon
end

function PartnerDirectionArtifactComponent:ctor(parentGo, parentWindow, params)
	PartnerDirectionArtifactComponent.super.ctor(self, parentGo)

	self.partner_id_ = params.partner_id
	self.id = params.id

	self:layout()
end

function PartnerDirectionArtifactComponent:getPrefabPath()
	return "Prefabs/Components/partner_direction_skill_component"
end

function PartnerDirectionArtifactComponent:initUI()
	PartnerDirectionArtifactComponent.super.initUI(self)

	local skilliconRoot = self.go:NodeByName("skillIconRoot").gameObject
	skilliconRoot:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	self.itemIcon = ItemIcon.new(skilliconRoot)
	self.labelPartnerSkillName = self.go:ComponentByName("labelPartnerSkillName", typeof(UILabel))
	self.labelPartnerSkillDesc = self.go:ComponentByName("labelPartnerSkillDesc", typeof(UILabel))
end

function PartnerDirectionArtifactComponent:layout()
	local tables = PartnerDirectTable
	local id = tables:getArtifactId(self.partner_id_, self.id)

	self.itemIcon:setInfo({
		scale = 0.83,
		itemID = tables:getArtifactIcon(self.partner_id_, self.id)
	})

	self.labelPartnerSkillName.text = DirectArtifactTextTable:getName(id)
	self.labelPartnerSkillDesc.text = DirectArtifactTextTable:getDesc(id)
	self.go:GetComponent(typeof(UIWidget)).height = math.max(90, self.labelPartnerSkillDesc:GetComponent(typeof(UIWidget)).height + 34)
end

function PartnerDirectionComponent:ctor(parentGo, params)
	PartnerDirectionComponent.super.ctor(self, parentGo)

	self.label_num_ = 3
	self.skill_num_ = 4
	self.artifact_num_ = 2
	self.default_label_num_ = 3
	self.eventProxy_ = self.eventProxyInner_
	self.table_id_ = params.table_id
	self.scrollDepth = params.depth or 0
	self.groupSkillComp = {}

	self:registerEvent()
	self:initLayout()
end

function PartnerDirectionComponent:getPrefabPath()
	return "Prefabs/Components/partner_direction_component"
end

function PartnerDirectionComponent:initUI()
	PartnerDirectionComponent.super.initUI(self)

	local go = self.go
	local groupTitle = go:NodeByName("groupTitle").gameObject
	self.labelTitle = groupTitle:ComponentByName("labelTitle", typeof(UILabel))
	self.imgTitle = groupTitle:ComponentByName("imgTitle", typeof(UISprite))
	self.radarShadeTexture = go:ComponentByName("radar_shade_texture", typeof(UITexture))
	self.pentagonForce = go:ComponentByName("radar_shade_texture/pentagonForce", typeof(Radar))
	self.imgSkill = go:ComponentByName("imgSkill", typeof(UISprite))
	self.scrollerPanel = go:ComponentByName("scroller", typeof(UIPanel))
	local groupScroller = go:NodeByName("scroller/groupScroll").gameObject
	self.scrollerUIScrollView = go:ComponentByName("scroller", typeof(UIScrollView))
	self.groupScroll = groupScroller
	local group1 = groupScroller:NodeByName("group1").gameObject
	self.group1 = group1
	self.image1_2 = group1:ComponentByName("image1_2", typeof(UISprite))
	self.labelPartnerLabel = group1:ComponentByName("labelPartnerLabel", typeof(UILabel))
	self.groupLabels = group1:NodeByName("groupLabels").gameObject
	local group2 = groupScroller:NodeByName("group2").gameObject
	self.group2 = group2
	self.labelPartnerDesc = group2:ComponentByName("labelPartnerDesc", typeof(UILabel))
	self.labelPartnerReview = group2:ComponentByName("labelPartnerReview", typeof(UILabel))
	local group3 = groupScroller:NodeByName("group3").gameObject
	self.group3 = group3
	self.labelPartnerAppearRate = group3:ComponentByName("labelPartnerAppearRate", typeof(UILabel))

	for i = 0, 1 do
		self["labelPartnerDungeon" .. i] = group3:ComponentByName("labelPartnerDungeon" .. i, typeof(UILabel))
		self["labelPartnerArena" .. i] = group3:ComponentByName("labelPartnerArena" .. i, typeof(UILabel))
		self["labelPartnerTower" .. i] = group3:ComponentByName("labelPartnerTower" .. i, typeof(UILabel))
		self["labelPartnerGuildBoss" .. i] = group3:ComponentByName("labelPartnerGuildBoss" .. i, typeof(UILabel))
	end

	local group4 = groupScroller:NodeByName("group4").gameObject
	self.group4 = group4
	self.labelPartnerSkill = group4:ComponentByName("labelPartnerSkill", typeof(UILabel))
	self.groupSkills = group4:NodeByName("groupSkills").gameObject
	local group5 = groupScroller:NodeByName("group5").gameObject
	self.group5 = group5
	self.labelPartnerEquip = group5:ComponentByName("labelPartnerEquip", typeof(UILabel))
	self.groupArtifacts = group5:NodeByName("groupArtifacts").gameObject

	for i = 1, 5 do
		self["image" .. i .. "_1"] = self["group" .. i]:ComponentByName("image" .. i .. "_1", typeof(UISprite))
		self["image" .. i .. "_3"] = self["group" .. i]:ComponentByName("image" .. i .. "_3", typeof(UISprite))
	end

	local names = {
		"Atk",
		"Arm",
		"Spd",
		"Ctr",
		"Hp"
	}
	local text = {
		"ATK",
		"ARM",
		"SPD",
		"CTL",
		"HP"
	}

	for i, name in ipairs(names) do
		self["label" .. name] = go:ComponentByName("label" .. name, typeof(UILabel))
		self["label" .. name].text = __("PARTNER_STATION_POINT_" .. text[i])
	end
end

function PartnerDirectionComponent:registerEvent()
	UIEventListener.Get(self.imgSkill.gameObject).onClick = handler(self, self.clearSkillTips)

	self.eventProxy_:addEventListener(xyd.event.UPDATE_PARTNER_TAGS, handler(self, self.initLabelGroup))
end

function PartnerDirectionComponent:setGroupY(icon)
end

function PartnerDirectionComponent:clearSkillTips()
	for _, comp in ipairs(self.groupSkillComp) do
		if comp.showGroup ~= nil then
			comp.showGroup:SetActive(false)
		end
	end

	self.imgSkill:SetActive(false)
end

function PartnerDirectionComponent:initLayout()
	self.scrollerPanel.depth = self.scrollDepth

	self:initPentagonForce()
	self:initText()
	self:initSprite()
	self:initLabelGroup()
	self.scrollerUIScrollView:ResetPosition()
end

function PartnerDirectionComponent:autoFit()
	for i = 1, 5 do
		if i ~= 3 then
			self["group" .. i]:GetComponent(typeof(UIWidget)).height = self["image" .. i .. "_1"].height + 18
		end
	end

	self.groupScroll:GetComponent(typeof(UILayout)):Reposition()
end

function PartnerDirectionComponent:initSprite()
	for i = 1, 5 do
		xyd.setUISpriteAsync(self["image" .. i .. "_1"], nil, "station_formation_bg")
		xyd.setUISpriteAsync(self["image" .. i .. "_3"], nil, "station_small_formation_bg")
	end

	xyd.setUISpriteAsync(self.imgTitle, nil, "station_title_bg")
	xyd.setUISpriteAsync(self.image1_2, nil, "station_bg_cell")
end

function PartnerDirectionComponent:initPentagonForce()
	local scores = {}
	local totals = {}
	local total = tonumber(MiscTable:getVal("direct_partner_point_full", "val"))
	local tables = PartnerDirectTable
	local id = self.table_id_

	table.insert(scores, tables:getPointAtk(id))
	table.insert(scores, tables:getPointArm(id))
	table.insert(scores, tables:getPointSpd(id))
	table.insert(scores, tables:getPointCtrl(id))
	table.insert(scores, tables:getPointSup(id))

	for i = 1, 5 do
		table.insert(totals, total)
	end

	self:waitForTime(1, function ()
		self.pentagonForce:SetInfo(totals, scores, 92, Color.New2(1454897825), self.radarShadeTexture)
	end)
end

function PartnerDirectionComponent:initText()
	local tables = PartnerDirectTable
	local model = PartnerDataStation
	local id = self.table_id_
	local partnerNum = #tables.ids - 1
	self.labelTitle.text = __("PARTNER_STATION_DIRECTION_TITLE")
	self.labelPartnerLabel.text = __("PARTNER_STATION_LABEL_TITLE")
	self.labelPartnerDesc.text = __("PARTNER_STATION_DESC_TITLE")
	self.labelPartnerAppearRate.text = __("PARTNER_STATION_APPEAR_RATE_TITLE")
	self.labelPartnerSkill.text = __("PARTNER_STATION_SKILL_TITLE")
	self.labelPartnerEquip.text = __("PARTNER_STATION_EQUIP_TITLE")
	self.labelPartnerReview.text = tables:getDesc(id)

	if xyd.Global.lang == "ko_kr" then
		self.labelPartnerReview.text = xyd.replaceSpace(tables:getDesc(id))
	end

	self.group2:GetComponent(typeof(UIWidget)).height = self.labelPartnerReview:GetComponent(typeof(UIWidget)).height + 72
	self.labelPartnerDungeon0.text = __("PARTNER_STATION_APPEAR_DUNGEON")
	self.labelPartnerArena0.text = __("PARTNER_STATION_APPEAR_ARENA")
	self.labelPartnerTower0.text = __("PARTNER_STATION_APPEAR_TOWER")
	self.labelPartnerGuildBoss0.text = __("PARTNER_STATION_APPEAR_GUILD_BOSS")
	local str = {}
	local nonTips = __("PARTNER_STATION_NO_APPEAR")

	for i = 1, 4 do
		local rank = model:getRank(i)

		if rank == -1 then
			table.insert(str, nonTips)
		else
			table.insert(str, tostring(tostring(rank)) .. "/" .. tostring(partnerNum))
		end
	end

	self.labelPartnerDungeon1.text = str[1]
	self.labelPartnerArena1.text = str[2]
	self.labelPartnerTower1.text = str[3]
	self.labelPartnerGuildBoss1.text = str[4]

	for i = 1, self.skill_num_ do
		if tables:getSkillId(self.table_id_, i) then
			local comp = PartnerDirectionSkillComponent.new(self.groupSkills, self, {
				partner_id = self.table_id_,
				id = i
			})

			table.insert(self.groupSkillComp, comp)
		end
	end

	self.groupSkills:GetComponent(typeof(UILayout)):Reposition()

	self.groupSkills:GetComponent(typeof(UILayout)).repositionNow = true
	local bound = NGUITools.CalculateRelativeWidgetBounds(self.go.transform, self.groupSkills.transform, true)
	self.groupSkills:GetComponent(typeof(UIWidget)).height = bound.size.y
	self.group4:GetComponent(typeof(UIWidget)).height = bound.size.y + 88

	for i = 1, self.artifact_num_ do
		local comp = tables:getArtifactId(self.table_id_, i) and PartnerDirectionArtifactComponent.new(self.groupArtifacts, self, {
			partner_id = self.table_id_,
			id = i
		})
	end

	self.groupArtifacts:GetComponent(typeof(UILayout)):Reposition()

	bound = NGUITools.CalculateRelativeWidgetBounds(self.go.transform, self.groupArtifacts.transform, true)
	self.groupArtifacts:GetComponent(typeof(UIWidget)).height = bound.size.y
	self.group5:GetComponent(typeof(UIWidget)).height = bound.size.y + 88
end

function PartnerDirectionComponent:initLabelGroup()
	NGUITools.DestroyChildren(self.groupLabels.transform)

	local ids = PartnerDataStation:getThreeLabel(self.table_id_)

	for _, id in pairs(ids) do
		local labelComp = PartnerDirectionLabelComponent.new(self.groupLabels, {
			no_click = true,
			id = id
		})
	end

	self.groupLabels:GetComponent(typeof(UILayout)):Reposition()

	local bound = NGUITools.CalculateRelativeWidgetBounds(self.go.transform, self.groupLabels.transform, true)
	self.groupLabels:GetComponent(typeof(UIWidget)).height = bound.size.y
	self.group1:GetComponent(typeof(UIWidget)).height = bound.size.y + 79
end

function PartnerDirectionComponent:getGroupSkill()
	return self.groupSkill
end

function PartnerArrayComponent:ctor(parentGo, params)
	PartnerArrayComponent.super.ctor(self, parentGo)

	self.curId = 0
	self.label_num_ = 4
	self.eventProxy_ = self.eventProxyInner_
	self.table_id_ = params.table_id
	self.parentWin = params.window

	self:initLayout()
	self:registerEvent()
end

function PartnerArrayComponent:getPrefabPath()
	return "Prefabs/Components/partner_array_component"
end

function PartnerArrayComponent:initUI()
	PartnerArrayComponent.super.initUI(self)

	local go = self.go
	self.imgTitle = go:ComponentByName("imgTitle", typeof(UISprite))
	self.labelTitle = go:ComponentByName("labelTitle", typeof(UILabel))
	self.radarShadeTexture = go:ComponentByName("radar_shade_texture", typeof(UITexture))
	self.pentagonForce = go:ComponentByName("radar_shade_texture/pentagonForce", typeof(Radar))
	self.groupMain = go:NodeByName("groupMain").gameObject
	self.imgBg1 = self.groupMain:ComponentByName("imgBg1", typeof(UISprite))

	for i = 0, 3 do
		self["group" .. i] = self.groupMain:NodeByName("group" .. i).gameObject
		self["img" .. i] = self["group" .. i]:ComponentByName("img" .. i, typeof(UISprite))
		self["labelTitle" .. i] = self["group" .. i]:ComponentByName("labelTitle" .. i, typeof(UILabel))
	end

	self.groupContent = self.groupMain:NodeByName("groupContent").gameObject
	self.imgBg2 = self.groupContent:ComponentByName("imgBg2", typeof(UISprite))
	self.imgBg3 = self.groupContent:ComponentByName("imgBg3", typeof(UISprite))
	self.labelPartnerRecommend = self.groupContent:ComponentByName("labelPartnerRecommend", typeof(UILabel))
	self.scroller = self.groupContent:NodeByName("scroller").gameObject
	self.scrollerUIScrollView = self.groupContent:ComponentByName("scroller", typeof(UIScrollView))
	self.groupFormation = self.scroller:NodeByName("groupFormation").gameObject
	self.btnFight = self.groupContent:NodeByName("btnFight").gameObject
	self.btnFightLabel = self.btnFight:ComponentByName("btnFightLabel", typeof(UILabel))
	self.groupNone_ = go:NodeByName("groupNone_").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips_", typeof(UILabel))
	local names = {
		"Atk",
		"Arm",
		"Spd",
		"Ctr",
		"Hp"
	}
	local text = {
		"ATK",
		"ARM",
		"SPD",
		"CTL",
		"HP"
	}

	for i, name in ipairs(names) do
		self["label" .. name] = go:ComponentByName("label" .. name, typeof(UILabel))
		self["label" .. name].text = __("PARTNER_STATION_POINT_" .. text[i])
	end
end

function PartnerArrayComponent:initLayout()
	self.scroller:GetComponent(typeof(UIPanel)).depth = self.parentWin.scrollerPanel.depth + 2

	self:initSprite()
	self:initPentagonForce()
	self:initText()
	self:initFormation()
	self:updateChoose(self.curId)
end

function PartnerArrayComponent:initSprite()
	xyd.setUISpriteAsync(self.imgTitle, nil, "station_title_bg")
	xyd.setUISpriteAsync(self.imgBg1, nil, "station_small_label_bg")
	xyd.setUISpriteAsync(self.imgBg2, nil, "station_bg", function ()
		self.imgBg2.color = Color.New2(4042128639.0)
	end)
	xyd.setUISpriteAsync(self.imgBg3, nil, "station_small_title_bg")
end

function PartnerArrayComponent:initPentagonForce()
	local scores = {}
	local totals = {}
	local total = tonumber(MiscTable:getVal("direct_partner_point_full", "val"))
	local tables = PartnerDirectTable
	local id = self.table_id_

	table.insert(scores, tables:getPointAtk(id))
	table.insert(scores, tables:getPointArm(id))
	table.insert(scores, tables:getPointSpd(id))
	table.insert(scores, tables:getPointCtrl(id))
	table.insert(scores, tables:getPointSup(id))

	for i = 1, 5 do
		table.insert(totals, total)
	end

	self:waitForTime(1, function ()
		self.pentagonForce:SetInfo(totals, scores, 92, Color.New2(1454897825), self.radarShadeTexture)
	end)
end

function PartnerArrayComponent:initText()
	self.labelTitle.text = __("PARTNER_STATION_FORMATION_TITLE")
	self.labelPartnerRecommend.text = __("PARTNER_STATION_FORMATION_RECOMMEND")
	self.btnFightLabel.text = __("PARTNER_STATION_TRYSELF")
	self.labelTitle0.text = __("PARTNER_FORMATION_STAKE")
	self.labelTitle1.text = __("PARTNER_FORMATION_TOWER")
	self.labelTitle2.text = __("PARTNER_FORMATION_GUILD")
	self.labelTitle3.text = __("PARTNER_FORMATION_JJC")
	self.labelNoneTips_.text = __("FORMATION_RECOMMEND_TIPS01")

	if xyd.Global.lang == "ja_jp" then
		self.labelTitle0.fontSize = 20
		self.labelTitle1.fontSize = 20
		self.labelTitle2.fontSize = 20
		self.labelTitle3.fontSize = 20
		self.labelPartnerRecommend.fontSize = 22
		self.imgBg3.width = 175

		self.imgBg3:X(-223)
		self.labelPartnerRecommend:X(-223)

		self.labelPartnerRecommend.width = 160
	end

	if xyd.Global.lang == "de_de" then
		for i = 0, 3 do
			self["labelTitle" .. i].fontSize = 20
		end
	end
end

function PartnerArrayComponent:initFormation()
	NGUITools.DestroyChildren(self.groupFormation.transform)

	if self.curId < 3 then
		local heros = PartnerArrayTable:getMonster(self.table_id_, self.curId + 1)

		for _, hero in pairs(heros) do
			if not hero or not tonumber(hero) then
				return
			end
		end

		if #heros <= 0 then
			return
		end

		PartnerStationFormation.new(self.groupFormation, {
			if_recommend = true,
			table_id = self.table_id_,
			curId = self.curId
		})
	end

	if self.curId > 0 then
		local records = PartnerDataStation:getRecord(self.curId)

		for i = 1, #records.record do
			local record = records.record[i]
			local showIndex = 0

			if #records.record > 1 then
				showIndex = i
			end

			if record then
				PartnerStationFormation.new(self.groupFormation, {
					if_recommend = false,
					table_id = self.table_id_,
					curId = self.curId,
					index = i,
					record = record,
					showIndex = showIndex
				})
			end
		end
	end

	if self.groupFormation.transform.childCount <= 0 then
		self.groupNone_:SetActive(true)
	else
		self.groupNone_:SetActive(false)
	end

	self.groupFormation:GetComponent(typeof(UILayout)):Reposition()

	if not self.firstChange then
		self:waitForFrame(10, function ()
			self.scrollerUIScrollView:ResetPosition()
		end)
	else
		self.scrollerUIScrollView:ResetPosition()
	end
end

function PartnerArrayComponent:registerEvent()
	for i = 0, self.label_num_ - 1 do
		UIEventListener.Get(self["group" .. i]).onClick = function ()
			if self.curId == i then
				return
			end

			self:updateChoose(i)
		end
	end

	UIEventListener.Get(self.btnFight).onClick = function ()
		xyd.WindowManager.get():openWindow("station_battle_formation_window", {
			curId = 4,
			battleType = xyd.BattleType.PARTNER_STATION,
			table_id = self.table_id_
		})
	end
end

function PartnerArrayComponent:updateChoose(index)
	PartnerDataStation:reqTouchId(index + 6)

	self.curId = index

	for i = 0, self.label_num_ - 1 do
		local source = nil

		if index == i then
			source = "station_small_label_click"
		else
			source = "station_small_label"
		end

		xyd.setUISpriteAsync(self["img" .. i], nil, source)
	end

	if index == 1 or index == 2 or index == 3 then
		self.btnFight:SetActive(false)
		self.scroller:GetComponent(typeof(UIPanel)):SetBottomAnchor(self.groupContent, 0, 5)
	else
		self.btnFight:SetActive(true)
		self.scroller:GetComponent(typeof(UIPanel)):SetBottomAnchor(self.groupContent, 0, 90)
	end

	for i = 0, 3 do
		if index == i then
			self["labelTitle" .. tostring(i)].color = Color.New2(1549556991)
		else
			self["labelTitle" .. tostring(i)].color = Color.New2(1267713279)
		end
	end

	self:initFormation()
end

function PartnerStationFormation:ctor(parentGo, params)
	PartnerStationFormation.super.ctor(self, parentGo)

	self.partners = {}
	self.showIndex = 0
	self.type = {
		OTHERS = 2,
		RECOMMEND = 1
	}
	self.table_id_ = params.table_id
	self.index = params.index
	self.if_recommend_ = params.if_recommend or false
	self.curId = params.curId + 1

	if not self.if_recommend_ then
		self.curId = self.curId + 3
	end

	self.record = params.record
	self.showIndex = params.showIndex

	self:registerEvent()
	self:initLayout()
end

function PartnerStationFormation:getPrefabPath()
	return "Prefabs/Components/partner_station_formation"
end

function PartnerStationFormation:initUI()
	PartnerStationFormation.super.initUI(self)

	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UISprite))
	self.labelName = go:ComponentByName("labelName", typeof(UILabel))
	self.groupRecommend = go:NodeByName("groupRecommend").gameObject
	self.labelRecommend = self.groupRecommend:ComponentByName("labelRecommend", typeof(UILabel))
	self.groupStars = self.groupRecommend:NodeByName("groupStars").gameObject

	for i = 1, 5 do
		self["star" .. i] = self.groupStars:ComponentByName("star" .. i, typeof(UISprite))
	end

	self.groupStrong = go:NodeByName("groupStrong").gameObject
	local playerIcon = self.groupStrong:NodeByName("playerIcon").gameObject
	self.playerIcon = PlayerIcon.new(playerIcon)
	self.groupStrongLabels = self.groupStrong:NodeByName("groupStrongLabels").gameObject
	self.labelPlayerName = self.groupStrongLabels:ComponentByName("labelPlayerName", typeof(UILabel))
	self.labelPlayerLevel = self.groupStrongLabels:ComponentByName("labelPlayerLevel", typeof(UILabel))
	self.groupFront = go:NodeByName("groupFront").gameObject
	self.groupBack = go:NodeByName("groupBack").gameObject
	self.btnDetail = go:NodeByName("btnDetail").gameObject
	self.btnDetailLabel = self.btnDetail:ComponentByName("btnDetailLabel", typeof(UILabel))
	self.btnFight = go:NodeByName("btnFight").gameObject
	self.btnFightLabel = self.btnFight:ComponentByName("btnFightLabel", typeof(UILabel))
end

function PartnerStationFormation:registerEvent()
	UIEventListener.Get(self.btnDetail).onClick = function ()
		xyd.WindowManager.get():openWindow("partner_station_battle_detail_window", {
			partner_infos = self.partners,
			pet = self.petId
		})

		if self.if_recommend_ then
			PartnerDataStation:reqTouchId(10)
		end
	end

	UIEventListener.Get(self.btnFight).onClick = function ()
		xyd.WindowManager.get():openWindow("partner_station_battle_formation_window", {
			partner_list = self.partners,
			id = self.curId,
			index = self.index,
			table_id = self.table_id_,
			pet = self.petId
		})

		if self.if_recommend_ then
			PartnerDataStation:reqTouchId(11)
		end
	end
end

function PartnerStationFormation:initLayout()
	self:initSprite()
	self:layout()
	self:initIcons()
end

function PartnerStationFormation:initSprite()
	xyd.setUISpriteAsync(self.imgBg, nil, "station_formation_bg01")

	for i = 1, 5 do
		xyd.setUISpriteAsync(self["star" .. i], nil, "station_star")
	end
end

function PartnerStationFormation:layout()
	local table = PartnerArrayTable
	local id = self.table_id_

	if self.if_recommend_ then
		self.labelName.text = __("FORMATION_RECOMMEND_HOT")

		self.groupRecommend:SetActive(true)
		self.groupStrong:SetActive(false)

		self.labelRecommend.text = __("FORMATION_RECOMMEND_HOT_RATE")
		local rate = table:getPoint(id, self.curId)

		for i = 1, rate do
			self["star" .. i]:SetActive(true)
		end

		self.groupStars:GetComponent(typeof(UIWidget)).width = rate * 22 + 3 * (rate - 1)

		self.groupStars:GetComponent(typeof(UILayout)):Reposition()
		self.groupRecommend:GetComponent(typeof(UILayout)):Reposition()
	else
		local data = self.record
		local playerInfo = data.player_info
		local text = __("FORMATION_RECOMMEND_PLAYER")

		if self.showIndex then
			text = text .. self.showIndex
		end

		self.labelName.text = text

		self.groupRecommend:SetActive(false)
		self.groupStrong:SetActive(true)
		self.playerIcon:setInfo(playerInfo)
		self.playerIcon:setScale(0.4)

		self.labelPlayerName.text = playerInfo.player_name
		local preText = ""
		local value = data.value

		if self.curId == 5 then
			preText = __("RANK_TEXT02") .. ": "
			value = data.params.stage_id
		elseif self.curId == 6 then
			preText = __("FRIEND_HARM")
		elseif self.curId == 7 then
			preText = __("RANK") .. ": "
		end

		self.labelPlayerLevel.text = tostring(preText) .. tostring(value)
		local labelWidth = math.max(self.labelPlayerLevel.width, self.labelPlayerName.width)
		self.groupStrongLabels:GetComponent(typeof(UIWidget)).width = labelWidth

		self.groupStrong:GetComponent(typeof(UILayout)):Reposition()
	end

	self.btnDetailLabel.text = __("ITEM_DETAIL")
	self.btnFightLabel.text = __("FORMATION_TRY_FIGHT")
end

function PartnerStationFormation:initIcons()
	if self.if_recommend_ then
		local ids = PartnerArrayTable:getMonster(self.table_id_, self.curId)
		local petId = PartnerArrayTable:getPet(self.table_id_, self.curId)
		self.partners = {}

		for i = 1, #ids do
			local np = Monster.new()
			local id = ids[i]

			np:populateWithTableID(id, {
				partnerID = i
			})
			table.insert(self.partners, np)
		end

		if #self.partners < 6 then
			return
		end

		for i = 1, 2 do
			local icon = HeroIcon.new(self.groupFront)

			icon:setInfo(self.partners[i]:getInfo())
			icon:setScale(0.74)
			icon:setPetFrame(petId)
		end

		for i = 3, #self.partners do
			local icon = HeroIcon.new(self.groupBack)

			icon:setInfo(self.partners[i]:getInfo())
			icon:setScale(0.74)
			icon:setPetFrame(petId)
		end

		self.petId = petId
	else
		local record = self.record
		local partners = record.partners
		local params = record.params
		local petId = 0

		if params then
			local pet_info_A = params.pet_info_A

			if pet_info_A then
				petId = pet_info_A.pet_id
			end
		end

		for i = 1, #partners do
			local partner = partners[i]
			local np = Partner.new()

			np:populate(partner)

			np.pos = partner.pos
			np.lev = partner.level

			table.insert(self.partners, np)
		end

		for i = 1, #partners do
			local partner = partners[i]
			local icon = nil

			if partner.pos <= 2 then
				icon = HeroIcon.new(self.groupFront)

				icon:setInfo(self.partners[i]:getInfo())
			else
				icon = HeroIcon.new(self.groupBack)

				icon:setInfo(self.partners[i]:getInfo())
			end

			icon:setScale(0.74)
			icon:setPetFrame(petId)
		end

		self.petId = petId
	end
end

function PartnerDataStationWindow:ctor(name, params)
	PartnerDataStationWindow.super.ctor(self, name, params)

	self.cur_index_ = 0
	self.last_index_ = 0
	self.skinCards = {}
	self.currentSkin = 1
	self.partners = {}
	self.lock = 2
	self.isPlayingAction = false
	self.isFirstOpen = true
	self.actions = {}
	self.effectFanye = nil
	self.effectKaiChang = nil
	self.num_label_ = 3
	self.imgSource = {
		"station_img_direction",
		"station_img_array",
		"station_img_comment"
	}
	self.iconSource = {
		"station_icon_direction",
		"station_icon_array",
		"station_icon_comment"
	}
	self.reses = {
		"partner_station_sheet_json",
		"station_bg_top1_png",
		"station_bg_top2_png"
	}
	self.depth = {
		{
			12,
			14,
			15,
			16,
			17
		},
		{
			19,
			21,
			22,
			23,
			24
		},
		{
			26,
			28,
			29,
			30,
			31
		}
	}
	self.lang2Index = {
		ko_kr = 0,
		ja_jp = 1,
		en_en = 0,
		fr_fr = 2,
		de_de = 0,
		zh_tw = 3
	}
	self.comment_id_ = params.table_id
	self.partner_table_id_ = params.partner_table_id
	self.cur_index_ = params.curId or 0
end

function PartnerDataStationWindow:playOpenAnimation(callback)
	PartnerDataStationWindow.super.playOpenAnimation(self, callback)
	self:registerEvent()
	PartnerDataStation:reqFormation({
		table_id = self.comment_id_
	})
	PartnerComment:reqCommentsData(self.comment_id_)
end

function PartnerDataStationWindow:initWindow()
	PartnerDataStationWindow.super.initWindow(self)
	self:getUIComponent()
	self:initTexture()
	self:solveMultiLang()
end

function PartnerDataStationWindow:solveMultiLang()
	local width = 100
	local pos = Vector3(-22, 13, 0)
	local size = 22

	if xyd.Global.lang ~= "zh_tw" then
		for i = 1, 3 do
			local tmpLabel = self["label" .. i .. "_1"]
			tmpLabel.width = width
			tmpLabel.transform.localPosition = pos
			tmpLabel.fontSize = size
		end
	end
end

function PartnerDataStationWindow:initTexture()
	xyd.setUITextureAsync(self.imgTop1, "Textures/partner_station_web/station_bg_top2", nil, false)
	xyd.setUITextureAsync(self.imgBottom1, "Textures/partner_station_web/station_bg_top1", nil, false)
end

function PartnerDataStationWindow:getUIComponent()
	local go = self.window_
	self.imgMask = go:ComponentByName("imgMask", typeof(UISprite))
	self.groupTopModel = go:NodeByName("groupTopModel").gameObject
	self.titleTexture = go:ComponentByName("titleTexture", typeof(UITexture))
	self.groupMain = go:NodeByName("groupMain").gameObject
	self.closeBtn = self.groupMain:NodeByName("closeBtn").gameObject

	for i = 0, 2 do
		self["topLabel" .. i] = self.groupMain:NodeByName("topLabel" .. i).gameObject
		self["img" .. i] = self["topLabel" .. i]:ComponentByName("img" .. i, typeof(UISprite))
		self["topContent" .. i] = self["topLabel" .. i]:NodeByName("topContent" .. i).gameObject
		self["touchTop" .. i] = self["topLabel" .. i]:NodeByName("touchTop" .. i).gameObject
		self["icon" .. i] = self["topContent" .. i]:ComponentByName("icon" .. i, typeof(UISprite))
		self["label" .. i + 1 .. "_1"] = self["topContent" .. i]:ComponentByName("label" .. i + 1 .. "_1", typeof(UILabel))
		self["label" .. i + 1 .. "_2"] = self["topContent" .. i]:ComponentByName("label" .. i + 1 .. "_2", typeof(UILabel))
	end

	self.scroller = self.groupMain:NodeByName("scroller").gameObject
	self.scrollerPanel = self.groupMain:ComponentByName("scroller", typeof(UIPanel))
	self.groupContent = self.scroller:NodeByName("groupContent").gameObject

	for i = 0, 2 do
		self["group" .. i] = self.groupContent:NodeByName("group" .. i).gameObject
	end

	self.gCardTouch = self.groupContent:NodeByName("gCardTouch").gameObject
	local group3 = self.groupMain:NodeByName("group3").gameObject
	self.groupModel = group3:NodeByName("groupModel").gameObject
	local group4 = self.groupContent:NodeByName("group4").gameObject
	self.cardComponents = group4:NodeByName("scrollCard/cardComponents").gameObject
	self.btnChange = self.groupContent:NodeByName("btnChange").gameObject
	local groupTop = self.groupMain:NodeByName("groupTop").gameObject

	for i = 1, 2 do
		self["imgTop" .. i] = groupTop:ComponentByName("imgTop" .. i, typeof(UITexture))
	end

	local groupBottom = self.groupMain:NodeByName("groupBottom").gameObject

	for i = 1, 2 do
		self["imgBottom" .. i] = groupBottom:ComponentByName("imgBottom" .. i, typeof(UITexture))
	end
end

function PartnerDataStationWindow:initData()
	local tableIDs = PartnerDirectTable:getTableIds(self.comment_id_)

	for i = 1, #tableIDs do
		local np = Partner.new()

		np:populate({
			table_id = tableIDs[i],
			star = PartnerTable:getStar(tableIDs[i]),
			lev = PartnerTable:getMaxlev(tableIDs[i])
		})
		table.insert(self.partners, np)
	end
end

function PartnerDataStationWindow:layout()
	self:updateChooseIndex(self.cur_index_)
	self:initLayout()
	self:updatePartnerSkin()

	self.label1_1.text = __("PARTNER_STATION_DIRECTION_C")
	self.label2_1.text = __("PARTNER_STATION_LINEUP_C")
	self.label3_1.text = __("PARTNER_STATION_COMMENT_C")

	if xyd.Global.lang == "zh_tw" then
		self.label3_2.text = __("PARTNER_STATION_COMMENT_E")
		self.label2_2.text = __("PARTNER_STATION_LINEUP_E")
		self.label1_2.text = __("PARTNER_STATION_DIRECTION_E")
	end
end

function PartnerDataStationWindow:initLayout()
	local count = self["group" .. self.cur_index_].transform.childCount

	if count > 0 then
		return
	end

	if self.cur_index_ == 0 then
		self:initPartnerDirection()
	elseif self.cur_index_ == 1 then
		self:initPartnerArray()
	else
		self:initPartnerComment()
	end
end

function PartnerDataStationWindow:initPartnerDirection()
	self.comp1 = PartnerDirectionComponent.new(self.group0, {
		table_id = self.comment_id_,
		depth = self.scrollerPanel.depth + 1
	})
end

function PartnerDataStationWindow:initPartnerArray()
	self.comp2 = PartnerArrayComponent.new(self.group1, {
		table_id = self.comment_id_,
		window = self
	})
end

function PartnerDataStationWindow:initPartnerComment()
	self.group2:SetActive(true)

	self.comp3 = PartnerCommentComponent.new(self.group2, {
		partner_table_id = self.partner_table_id,
		table_id = self.comment_id_,
		parentWin = self
	})
end

function PartnerDataStationWindow:getCommentComponent()
	local transParent = self.group2.transform
	local count = transParent.childCount

	if count > 0 then
		return transParent:GetChild(0)
	end

	return nil
end

function PartnerDataStationWindow:setChildIndex(i, up)
	if up then
		self["img" .. i].depth = self.depth[i + 1][1]
		self["icon" .. i].depth = self.depth[i + 1][2]
		self["label" .. i + 1 .. "_1"].depth = self.depth[i + 1][3]
		self["label" .. i + 1 .. "_2"].depth = self.depth[i + 1][4]
		self["touchTop" .. i]:GetComponent(typeof(UIWidget)).depth = self.depth[i + 1][5]
	else
		self["img" .. i].depth = 0
		self["icon" .. i].depth = 1
		self["label" .. i + 1 .. "_1"].depth = 1
		self["label" .. i + 1 .. "_2"].depth = 1
		self["touchTop" .. i]:GetComponent(typeof(UIWidget)).depth = 2
	end
end

function PartnerDataStationWindow:updateChooseIndex(index)
	if index == self.cur_index_ and not self.isFirstOpen then
		return
	end

	if self.isPlayingAction then
		return
	end

	if self.comp1 and self.cur_index_ == 0 then
		self.comp1:clearSkillTips()
	end

	if not PartnerTable:checkIfTaiWu(self.partner_table_id_) and index ~= 2 then
		xyd.showToast(__("STATION_NO_FORMATION"))

		return
	end

	PartnerDataStation:reqTouchId(index + 3)

	self.last_index_ = self.cur_index_
	self.cur_index_ = index

	for i = 0, self.num_label_ - 1 do
		local y = 534
		local y1 = 14
		local y2 = 21
		local imgSource = self.imgSource[i + 1]
		local iconSource = self.iconSource[i + 1]

		if i == index then
			imgSource = tostring(imgSource) .. "_click"
			iconSource = tostring(iconSource) .. "_click"
		end

		self:setChildIndex(i, false)

		local xyz1 = self["topLabel" .. i].transform.localPosition
		local xyz2 = self["topContent" .. i].transform.localPosition
		local xyz3 = self["label" .. tostring(i + 1) .. "_1"].transform.localPosition

		self["topLabel" .. tostring(i)]:SetLocalPosition(xyz1.x, y, xyz1.z)
		self["topContent" .. tostring(i)]:SetLocalPosition(xyz2.x, y1, xyz2.z)
		xyd.setUISpriteAsync(self["img" .. i], nil, imgSource)
		xyd.setUISpriteAsync(self["icon" .. i], nil, iconSource)

		if xyd.Global.lang ~= "zh_tw" then
			self["label" .. tostring(i + 1) .. "_1"]:SetLocalPosition(xyz3.x, y2, xyz3.z)
		end
	end

	self:initLayout()

	if self.isFirstOpen then
		self:chooseIndex(index)

		self.isFirstOpen = false
		local xyz1 = self["topLabel" .. index].transform.localPosition
		local xyz2 = self["topContent" .. index].transform.localPosition
		local xyz3 = self["label" .. tostring(index + 1) .. "_1"].transform.localPosition

		self:setChildIndex(index, true)
		self["topLabel" .. tostring(index)]:SetLocalPosition(xyz1.x, 560, xyz1.z)
		self["topContent" .. tostring(index)]:SetLocalPosition(xyz2.x, 0, xyz2.z)

		if xyd.Global.lang ~= "zh_tw" then
			self["label" .. tostring(index + 1) .. "_1"]:SetLocalPosition(xyz3.x, 8, xyz3.z)
		end

		return
	end

	self.isPlayingAction = true

	if not self.effectFanye then
		local effect = xyd.Spine.new(self.groupModel)

		effect:setInfo("fx_ui_direct_fanye", function ()
			xyd.SoundManager.get():playSound(2142)
			effect:play("animation", 1, 1, function ()
			end)
			self:addEffect(index)
		end)

		self.effectFanye = effect

		return
	end

	self.groupModel:SetActive(true)
	self:addEffect(index)
	self.effectFanye:stop()
	self.effectFanye:play("animation", 1)
	xyd.SoundManager.get():playSound(2142)
end

function PartnerDataStationWindow:addEffect(index)
	local oldWidth = 720
	local dur = 0.33
	local action1 = nil

	local function completeFunction1()
		for i = 1, #self.actions do
			if self.actions[i] == action1 then
				table.remove(self.actions, i)

				break
			end
		end
	end

	local function setter(value)
		self.scrollerPanel:SetLeftAnchor(self.groupMain, 0, value)
		self.scroller:SetActive(false)
		self.scroller:SetActive(true)
	end

	self.scrollerPanel:SetLeftAnchor(self.groupMain, 0, 720)

	action1 = DG.Tweening.DOTween.Sequence():OnComplete(completeFunction1)

	action1:AppendInterval((dur + 0.08) / 2)
	action1:AppendCallback(function ()
		self:setChildIndex(index, true)

		local xyz1 = self["topLabel" .. index].transform.localPosition
		local xyz2 = self["topContent" .. index].transform.localPosition
		local xyz3 = self["label" .. tostring(index + 1) .. "_1"].transform.localPosition

		self["topLabel" .. tostring(index)]:SetLocalPosition(xyz1.x, 560, xyz1.z)
		self["topContent" .. tostring(index)]:SetLocalPosition(xyz2.x, 0, xyz2.z)

		if xyd.Global.lang ~= "zh_tw" then
			self["label" .. tostring(index + 1) .. "_1"]:SetLocalPosition(xyz3.x, 8, xyz3.z)
		end
	end)
	action1:AppendInterval((dur - 0.08) / 2)
	action1:AppendCallback(function ()
		self:chooseIndex(index)
	end)
	action1:Insert(dur, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 720, 0, dur - 0.1))
	action1:AppendCallback(function ()
		self.isPlayingAction = false
	end)
	table.insert(self.actions, action1)
end

function PartnerDataStationWindow:chooseIndex(index)
	for i = 0, self.num_label_ - 1 do
		local v = false

		if i == index then
			v = true
		end

		self["group" .. tostring(i)]:SetActive(v)

		if self["comp" .. i] and self["comp" .. tostring(i)].pentagonForce then
			self:waitForTime(1, function ()
				self["comp" .. tostring(i)].pentagonForce:SetQueue()
			end)
		end
	end
end

function PartnerDataStationWindow:registerEvent()
	PartnerDataStationWindow.super.register(self)

	for i = 0, self.num_label_ - 1 do
		UIEventListener.Get(self["touchTop" .. tostring(i)]).onClick = function ()
			self:updateChooseIndex(i)
		end
	end

	UIEventListener.Get(self.gCardTouch).onDragStart = function ()
		self:onScrollBegin()
	end

	UIEventListener.Get(self.gCardTouch).onDrag = function (go, delta)
		self:onScrollMove(delta)
	end

	UIEventListener.Get(self.gCardTouch).onDragEnd = function ()
		self:onScrollEnd()
	end

	UIEventListener.Get(self.btnChange).onClick = function ()
		xyd.WindowManager:get():openWindow("edit_station_partner_window", {})
	end

	UIEventListener.Get(self.imgMask.gameObject).onClick = function ()
		self:onClickCloseButton()
	end

	self.eventProxy_:addEventListener(xyd.event.GET_PARTNER_DATA_INFO, handler(self, self.onInfo))
	self.eventProxy_:addEventListener(xyd.event.GET_PARTNER_COMMENTS, handler(self, self.onInfo))
	self.eventProxy_:addEventListener(xyd.event.REPORT_MESSAGE, handler(self, self.onReportMessage))
end

function PartnerDataStationWindow:onInfo(event)
	self.lock = self.lock - 1

	if self.lock ~= 0 then
		return
	end

	self:initData()
	self:layout()

	self.isPlayingAction = true

	XYDCo.WaitForTime(0.5, function ()
		local action = DG.Tweening.DOTween.Sequence()

		local function setter(value)
			self.groupMain:GetComponent(typeof(UIWidget)).alpha = value
		end

		table.insert(self.actions, action)

		if not self.effectKaiChang then
			self.effectKaiChang = xyd.Spine.new(self.groupTopModel)

			self.effectKaiChang:setInfo("fx_ui_direct", function ()
				xyd.setUITextureByNameAsync(self.titleTexture, "station_title_" .. xyd.Global.lang, true, function ()
					self.effectKaiChang:changeAttachment("title", self.titleTexture)
					self.effectKaiChang:setRenderTarget(self.groupTopModel:GetComponent(typeof(UIWidget)), 1)

					self.isPlayingAction = true

					xyd.SoundManager.get():playSound(2142)
					self.effectKaiChang:play("fx_ui_direct_open", 1, 1, function ()
						self.effectKaiChang:SetActive(false)

						self.isPlayingAction = false
					end)
					action:Insert(0.4, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0.01, 1, 0.4))
				end)
			end)
		end
	end, nil)
end

function PartnerDataStationWindow:resetWindow(params)
	self.comment_id_ = params.comment_id
	self.partner_table_id_ = params.partner_table_id
	self.cur_index_ = params.curId or 0

	NGUITools.DestroyChildren(self.cardComponents.transform)

	for i = 0, 2 do
		NGUITools.DestroyChildren(self["group" .. i].transform)
	end

	self.partners = {}

	self:initData()
	self:layout()
end

function PartnerDataStationWindow:onScrollBegin(event)
	self.scrollX = 0
end

function PartnerDataStationWindow:onScrollMove(delta)
	self.scrollX = self.scrollX + delta.x

	dump(delta)
end

function PartnerDataStationWindow:onScrollEnd(event)
	if self.isMove then
		return
	end

	if self.scrollX > 10 and self.currentSkin > 1 then
		self.currentSkin = self.currentSkin - 1

		self:setSkinState(0.6)
	elseif self.scrollX < -10 and self.currentSkin < #self.partners then
		self.currentSkin = self.currentSkin + 1

		self:setSkinState(0.6)
	end
end

function PartnerDataStationWindow:updatePartnerSkin()
	self.skinCards = {}
	local dressSkinID = self.partner_table_id_

	for i = 1, #self.partners do
		local card = PartnerCard.new(self.cardComponents)

		card:setInfo(self.partners[i]:getInfo())
		table.insert(self.skinCards, card)

		if self.partners[i]:getTableID() == self.partner_table_id_ then
			self.currentSkin = i
		end
	end

	self.cardComponents:GetComponent(typeof(UIGrid)):Reposition()
	self:setSkinState(0)
end

function PartnerDataStationWindow:setSkinState(ease)
	if ease == nil then
		ease = 0
	end

	if self.isMove then
		return
	end

	if ease == 0 then
		local transform = self.cardComponents.transform

		self.cardComponents:SetLocalPosition(-166 * (self.currentSkin - 1), transform.localPosition.y, transform.localPosition.z)
	else
		self.isMove = true
		local action = DG.Tweening.DOTween.Sequence()

		action:Append(self.cardComponents.transform:DOLocalMoveX(-166 * (self.currentSkin - 1), ease))
		action:AppendCallback(function ()
			action:Kill(false)

			action = nil
			self.isMove = false
		end)
	end

	for i = 1, #self.skinCards do
		local card = self.skinCards[i]

		if self.currentSkin == i then
			card:setGroupScale(1, ease)
		else
			card:setGroupScale(0.9, ease)
		end
	end
end

function PartnerDataStationWindow:willClose()
	PartnerDataStationWindow.super.willClose(self)

	for i = 1, #self.actions do
		if self.actions[i] then
			self.actions[i]:Kill()
		end
	end

	self.actions = {}
end

function PartnerDataStationWindow:onClickCloseButton()
	if self.isPlayingAction or not self.effectKaiChang then
		return
	end

	self.isPlayingAction = true

	self.groupMain:SetActive(false)
	self.effectKaiChang:SetActive(true)
	xyd.SoundManager.get():playSound(2143)
	self.effectKaiChang:play("fx_ui_direct_close", 1, 1, function ()
		self.effectKaiChang:SetActive(false)
		NGUITools.DestroyChildren(self.groupTopModel.transform)

		self.effectKaiChang = nil

		PartnerDataStationWindow.super.onClickCloseButton(self)
	end)

	local function setter(value)
		self.effectKaiChang.alpha = value
	end

	local action = DG.Tweening.DOTween.Sequence()

	action:Insert(0.2, DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0.01, 0.6))
	table.insert(self.actions, action)
end

function PartnerDataStationWindow:updateReportItem(newReportItem)
	if self.reportItem then
		self.reportItem:removeReportBtn()

		self.reportItem = nil
	end

	if newReportItem then
		self.reportItem = newReportItem
	end
end

function PartnerDataStationWindow:onReportMessage()
	if self.reportItem then
		self.reportItem:removeReportBtn()

		self.reportItem = nil
	end
end

return PartnerDataStationWindow
