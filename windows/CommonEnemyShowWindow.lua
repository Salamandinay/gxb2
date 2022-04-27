local BaseWindow = import(".BaseWindow")
local CommonEnemyShowWindow = class("CommonEnemyShowWindow", BaseWindow)
local HeroIcon = import("app.components.HeroIcon")

function CommonEnemyShowWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.enemies = {}

	if params.enemies then
		self.enemies = params.enemies
	end
end

function CommonEnemyShowWindow:initWindow()
	CommonEnemyShowWindow.super.initWindow(self)
	self:getUIComponents()
	self:register()
	self:showEnemy()
end

function CommonEnemyShowWindow:getUIComponents()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.groupPreview_ = self.groupAction:NodeByName("groupPreview_").gameObject
	self.labelPreviewTitle_ = self.groupPreview_:ComponentByName("labelPreviewTitle_", typeof(UILabel))
	self.groupPreviewHeros_ = self.groupPreview_:NodeByName("groupPreviewHeros_").gameObject
	self.groupPreviewHeros_UILayout = self.groupPreview_:ComponentByName("groupPreviewHeros_", typeof(UILayout))
	self.groupPreviewBg_ = self.groupPreview_:ComponentByName("e:Image", typeof(UIWidget))
end

function CommonEnemyShowWindow:addTitle()
	if self.labelPreviewTitle_ then
		self.labelPreviewTitle_.text = __("DUNGEON_MONSTER_PREVIEW")
	end
end

function CommonEnemyShowWindow:register()
	CommonEnemyShowWindow.super.register(self)
end

function CommonEnemyShowWindow:showEnemy()
	local enemies = self.enemies

	if #enemies > 0 then
		NGUITools.DestroyChildren(self.groupPreviewHeros_.transform)

		for i = 1, #enemies do
			local tableID = enemies[i]
			local id = xyd.tables.monsterTable:getPartnerLink(tableID)
			local lev = xyd.tables.monsterTable:getShowLev(tableID)
			local icon = HeroIcon.new(self.groupPreviewHeros_)

			icon:setInfo({
				noClick = true,
				tableID = id,
				lev = lev
			})

			if #enemies > 5 then
				local scale = 0.7962962962962963

				icon:SetLocalScale(scale, scale, scale)
			end
		end

		if #enemies > 5 then
			self.groupPreviewBg_.width = 620
			self.groupPreviewHeros_UILayout.gap = Vector2(10, 0)
		elseif #enemies == 5 then
			self.groupPreviewBg_.width = 647
			self.groupPreviewHeros_UILayout.gap = Vector2(12, 0)
		else
			self.groupPreviewBg_.width = 556
			self.groupPreviewHeros_UILayout.gap = Vector2(12, 0)
		end

		self.groupPreview_:SetActive(true)
		self.groupPreviewHeros_UILayout:Reposition()
	end
end

return CommonEnemyShowWindow
