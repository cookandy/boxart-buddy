---@class UpdateDirectHandler
local M = class({
    name = "UpdateDirectHandler",
    implements = { require("worker.handler.abstract") },
})

function M:new(DIC)
    self.DIC = DIC
    return self
end

function M:handle(task)
    task.parameters = task.parameters or {}
    local directUpdater = require("module.direct_updater")(
        self.DIC.environment,
        self.DIC.logger,
        self.DIC.database,
        self.DIC.platform
    )

    if task.type == "updateOne" then
        return pcall(function()
            return directUpdater:updateOne(task.parameters.romUuid, task.parameters.options)
        end)
    end

    error("cannot handle unknown task type: " .. task.type)
end

return M
