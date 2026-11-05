local SceneEffectMediator = class('SceneEffectMediator', framework.Mediator)
SceneEffectMediator.NAME  = "SceneEffectMediator"


function SceneEffectMediator:ctor()
	SceneEffectMediator.super.ctor(self, self.NAME)
end

function SceneEffectMediator:listNotificationInterests()
	local noticeTable = global.NoticeTable
	return {
		noticeTable.PlayerPropertyInited,
		noticeTable.ReleaseMemory,
		noticeTable.MapPickCursorPosChange,
	}
end


function SceneEffectMediator:handleNotification(notification)
	local noticeID = notification:getName()
	local notices  = global.NoticeTable
	local data     = notification:getBody()

	if notices.ReleaseMemory == noticeID then
		self:OnClose()

	elseif notices.PlayerPropertyInited == noticeID then
		self:OnInit()

	elseif notices.MapPickCursorPosChange == noticeID then
		self:OnMapPickCursorPosChange(data)
	end
end

function SceneEffectMediator:OnInit()
	if not self._viewComponent then
		local SceneEffectLayout = requireView("scene/SceneEffectLayout")
		self._viewComponent = SceneEffectLayout.create()
	end   
end

function SceneEffectMediator:OnClose()
	if self._viewComponent then
		self._viewComponent:OnClose()
		self._viewComponent = nil
	end
end

function SceneEffectMediator:OnMapPickCursorPosChange(pick)
	if self._viewComponent then
		local wPosX, wPosY = global.sceneManager:MapPos2WorldPos(pick.xGridPicked, pick.yGridPicked, true)
		self._viewComponent:OnMapPickCursorShow(wPosX, wPosY)
	end
end

return SceneEffectMediator
