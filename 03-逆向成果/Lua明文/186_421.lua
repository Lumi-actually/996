local LoadingCompletedCommand = class('LoadingCompletedCommand', framework.SimpleCommand)

function LoadingCompletedCommand:ctor()

end

function LoadingCompletedCommand:execute(note)
    UIOperator:OpenGameWorld()
    -- global.Facade:sendNotification(global.NoticeTable.GameWorldConfirm)
    -- global.Facade:sendNotification(global.NoticeTable.GameWorldCheckTimeout)
end


return LoadingCompletedCommand
