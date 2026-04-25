local HOT100_QUERY = [[
query studyPlanV2Detail($planSlug: String!) {
    studyPlanV2Detail(planSlug: $planSlug) {
        name
        planSubGroups {
            questions {
                id
                title
                titleSlug
                translatedTitle
                questionFrontendId
                paidOnly
                difficulty
                topicTags {
                    slug
                    name
                    nameTranslated
                }
            }
        }
    }
}
]]

local function normalize_difficulty(difficulty)
    return ({
        EASY = "Easy",
        MEDIUM = "Medium",
        HARD = "Hard",
    })[difficulty] or difficulty
end

local function hot100_questions()
    local api = require("leetcode.api.utils")
    local problemlist = require("leetcode.cache.problemlist")

    local cached = {}
    for _, question in ipairs(problemlist.get()) do
        cached[question.title_slug] = question
    end

    local res, err = api.query(HOT100_QUERY, {
        planSlug = "top-100-liked",
    })
    if err then
        return nil, err
    end

    local detail = (((res or {}).data or {}).studyPlanV2Detail or {})
    if vim.tbl_isempty(detail) then
        return nil, { msg = "Hot 100 response was empty" }
    end

    local questions = {}
    local seen = {}

    for _, group in ipairs(detail.planSubGroups or {}) do
        for _, question in ipairs(group.questions or {}) do
            if not seen[question.titleSlug] then
                seen[question.titleSlug] = true

                local cached_question = cached[question.titleSlug] or {}
                questions[#questions + 1] = {
                    status = cached_question.status or "todo",
                    id = tonumber(question.id) or question.id,
                    frontend_id = question.questionFrontendId,
                    title = question.title,
                    title_cn = question.translatedTitle or cached_question.title_cn or "",
                    title_slug = question.titleSlug,
                    link = ("https://leetcode.cn/problems/%s/"):format(question.titleSlug),
                    paid_only = question.paidOnly or false,
                    ac_rate = cached_question.ac_rate or 0,
                    difficulty = normalize_difficulty(question.difficulty),
                    topic_tags = vim.tbl_map(function(tag)
                        return {
                            name = tag.nameTranslated or tag.name,
                            slug = tag.slug,
                        }
                    end, question.topicTags or {}),
                }
            end
        end
    end

    return questions, detail.name or "LeetCode Hot 100"
end

local function ensure_leetcode_started()
    if _Lc_state and _Lc_state.menu then
        return true
    end

    return require("leetcode").start(false)
end

local function open_hot100()
    local spinner = require("leetcode.logger.spinner"):start("fetching Hot 100", "points")

    local ok, err = pcall(function()
        require("leetcode.utils").auth_guard()
    end)
    if not ok then
        local msg = type(err) == "string" and err:gsub("^%s+", "") or "sign in to LeetCode first"
        return spinner:error(msg)
    end

    if not ensure_leetcode_started() then
        spinner:error("failed to open leetcode.nvim")
        return
    end

    local questions, title = hot100_questions()
    if not questions then
        return spinner:error(title.msg)
    end

    spinner:success(("opened %s"):format(title))
    require("leetcode.picker").question(questions, {})
end

local function highlight_description(question)
    local description = question.description
    if not description or not description.winid then
        return
    end

    if vim.api.nvim_win_is_valid(description.winid) then
        vim.api.nvim_set_option_value(
            "winhighlight",
            "Normal:Normal,FloatBorder:FloatBorder",
            { win = description.winid }
        )
    end
end

return {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html",
    cmd = { "Leet", "LeetHot100" },
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-telescope/telescope.nvim",
    },
    keys = {
        { "<leader>ol", "<cmd>Leet<CR>", desc = "Open LeetCode" },
        { "<leader>oh", "<cmd>LeetHot100<CR>", desc = "Open LeetCode Hot 100" },
    },
    opts = {
        arg = "leetcode.nvim",
        lang = "cpp",
        cn = {
            enabled = true,
            translator = true,
            translate_problems = true,
        },
        storage = {
            home = vim.fn.stdpath("data") .. "/leetcode",
            cache = vim.fn.stdpath("cache") .. "/leetcode",
        },
        plugins = {
            non_standalone = false,
        },
        logging = true,
        cache = {
            update_interval = 60 * 60 * 24 * 7,
        },
        editor = {
            reset_previous_code = true,
            fold_imports = true,
        },
        console = {
            open_on_runcode = true,
            dir = "row",
            size = {
                width = "90%",
                height = "75%",
            },
            result = {
                size = "60%",
            },
            testcase = {
                virt_text = true,
                size = "40%",
            },
        },
        description = {
            position = "left",
            width = "48%",
            show_stats = true,
        },
        picker = {
            provider = "telescope",
        },
        hooks = {
            question_enter = {
                highlight_description,
            },
        },
        injector = {
            ["cpp"] = {
                imports = function()
                    return {
                        "#include <bits/stdc++.h>",
                        "using namespace std;",
                    }
                end,
                after = {
                    "",
                    "int main() {",
                    "    return 0;",
                    "}",
                },
            },
        },
        keys = {
            toggle = { "q" },
            confirm = { "<CR>" },
            reset_testcases = "r",
            use_testcase = "U",
            focus_testcases = "H",
            focus_result = "L",
        },
    },
    config = function(_, opts)
        require("leetcode").setup(opts)

        vim.api.nvim_create_user_command("LeetHot100", open_hot100, {
            desc = "Open LeetCode Hot 100",
        })
    end,
}
