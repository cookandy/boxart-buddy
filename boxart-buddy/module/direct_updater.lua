local filesystem = require("lib.nativefs")
local path = require("util.path")
local mediaUtil = require("util.media")
local stringUtil = require("util.string")
local image = require("util.image")

---@class DirectUpdater
local M = class({
    name = "DirectUpdater",
})

function M:new(environment, logger, database, platform)
    self.environment = environment
    self.logger = logger
    self.platform = platform
    self.romRepository = require("repository.rom")(database)
    self.mediaRepository = require("repository.media")(database, environment)
end

function M:orchestrate(options)
    options = options or {}
    self.logger:log("info", "direct_updater", "starting direct update process")
    local tasks = {}
    local steps = {}
    local platforms = options and options.platforms or nil

    -- select roms from database then produce tasks from them
    local roms = self.romRepository:getFreshRoms(platforms)
    for __, row in ipairs(roms) do
        local task = {
            type = "updateOne",
            parameters = {
                romUuid = row.uuid,
                options = {},
            },
        }
        table.insert(tasks, task)
        table.insert(steps, row.filename)
    end

    local orchestrationText = "Updating Images Directly"

    return { tasks = tasks, steps = steps, text = orchestrationText }
end

function M:updateOne(romUuid, options)
    options = options or {}

    -- Get the catalog path (info/catalogue/<system>)
    local catalogBasePath = self.environment:muosCatalogFolder()

    if not filesystem.getInfo(catalogBasePath, "directory") then
        error("Catalog folder path could not be found: " .. catalogBasePath)
    end

    local rom = self.romRepository:getRom(romUuid)
    local media = self.romRepository:getMediaForRom(romUuid)

    -- Get the platform info
    local p = self.platform:getPlatformByKey(rom.platform)

    -- Only process mix images (which is what's displayed in muOS)
    if media.mix then
        local from = mediaUtil.mediaPath(self.environment:getPath("cache"), "mix", media.mix.filename)

        -- Target directory is info/catalogue/<system>/box/
        local toDir = path.join(catalogBasePath, p.muos, "box")
        local to = path.join(toDir, path.swapExtension(rom.filename, "png"))

        -- Check if we should skip based on overwrite setting
        local overwrite = self.environment:getConfig("direct_update_overwrite")
        if not overwrite and filesystem.getInfo(to, "file") then
            self.logger:log("debug", "direct_updater", string.format("Skipping %s (already exists)", rom.filename))
            return
        end

        -- Create target directory if it doesn't exist
        if not filesystem.getInfo(toDir, "directory") then
            filesystem.createDirectory(toDir)
        end

        -- Copy the file
        local cmd = string.format(
            "cp %s %s",
            stringUtil.shellQuote(from),
            stringUtil.shellQuote(to)
        )
        local success = os.execute(cmd)

        if success then
            self.logger:log("info", "direct_updater", string.format("Updated %s", rom.filename))
        else
            self.logger:log("error", "direct_updater", string.format("Failed to update %s", rom.filename))
        end
    else
        self.logger:log("debug", "direct_updater", string.format("No mix image for %s", rom.filename))
    end

    -- Also handle screenshot/preview if it exists
    if media.screenshot then
        local from = mediaUtil.mediaPath(self.environment:getPath("cache"), "screenshot", media.screenshot.filename)

        -- Target directory is info/catalogue/<system>/preview/
        local toDir = path.join(catalogBasePath, p.muos, "preview")
        local to = path.join(toDir, path.swapExtension(rom.filename, "png"))

        -- Check if we should skip based on overwrite setting
        local overwrite = self.environment:getConfig("direct_update_overwrite")
        if not overwrite and filesystem.getInfo(to, "file") then
            self.logger:log("debug", "direct_updater", string.format("Skipping preview for %s (already exists)", rom.filename))
            return
        end

        -- Create target directory if it doesn't exist
        if not filesystem.getInfo(toDir, "directory") then
            filesystem.createDirectory(toDir)
        end

        -- Copy the file
        local cmd = string.format(
            "cp %s %s",
            stringUtil.shellQuote(from),
            stringUtil.shellQuote(to)
        )
        local success = os.execute(cmd)

        if success then
            -- Resize preview to 515px (max allowed by muos)
            local r, err = image.rescale(to, 515)
            self.logger:log("info", "direct_updater", string.format("Updated preview for %s", rom.filename))
        else
            self.logger:log("error", "direct_updater", string.format("Failed to update preview for %s", rom.filename))
        end
    end
end

return M
