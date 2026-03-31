-- src/core/job_queue.lua
-- Standalone job queue. World posts jobs; units query and claim them.

local Config   = require("src.config.config")
local Registry = require("src.core.registry")

local JobQueue = {
    jobs = {},   -- id -> job
}

--- Create and post a new job to the queue.
--- @param job_type string   keys into Config.jobs
--- @param x number
--- @param y number
--- @param target_id number|nil
--- @param priority number|nil  defaults to Priority.NORMAL
--- @return table job
function JobQueue.post(job_type, x, y, target_id, priority)
    assert(Config.jobs[job_type], "JobQueue.post: unknown job type: " .. tostring(job_type))

    local job = {
        id        = Registry.nextId(),
        type      = job_type,
        priority  = priority or Config.Priority.NORMAL,
        x         = x,
        y         = y,
        target_id = target_id,
        claimed_by = nil,
        progress   = 0,
    }

    JobQueue.jobs[job.id] = job
    Registry.register(job)
    return job
end

--- Find the best unclaimed job for a given unit.
--- Returns nil if nothing is eligible.
--- @param unit table
--- @return table|nil
function JobQueue.findBestFor(unit)
    local best = nil
    local best_score = -1

    for _, job in pairs(JobQueue.jobs) do
        if not job.claimed_by then
            local job_cfg = Config.jobs[job.type]
            -- Eligibility: tier and skill
            if unit.tier >= job_cfg.min_tier and unit.skills[job_cfg.skill] >= job_cfg.min_skill then
                -- Score: priority first, then distance (inverted — closer is better)
                local dx = unit.x - job.x
                local dy = unit.y - job.y
                local dist = math.sqrt(dx * dx + dy * dy)
                local score = job.priority * 10000 - dist

                if score > best_score then
                    best = job
                    best_score = score
                end
            end
        end
    end

    return best
end

--- Claim a job for a unit.
--- @param job table
--- @param unit table
function JobQueue.claim(job, unit)
    job.claimed_by = unit.id
    unit.current_job_id = job.id
end

--- Release a job back to the queue (unit interrupted or abandoned).
--- @param job table
function JobQueue.release(job)
    job.claimed_by = nil
end

--- Remove a completed job from the queue.
--- @param job_id number
function JobQueue.remove(job_id)
    JobQueue.jobs[job_id] = nil
end

return JobQueue
