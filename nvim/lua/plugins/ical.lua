return {
  {
    "simoneSantoni/ical.nvim",
    cmd = {
      "IcalAgenda",
      "IcalDaily",
      "IcalWeekly",
      "IcalMonthly",
      "IcalYearly",
      "IcalNewEvent",
      "IcalNewTask",
      "IcalSync",
    },
    keys = {
      { "<leader>ca", "<cmd>IcalAgenda<cr>",   desc = "iCal Agenda" },
      { "<leader>cd", "<cmd>IcalDaily<cr>",    desc = "iCal Daily" },
      { "<leader>cW", "<cmd>IcalWeekly<cr>",   desc = "iCal Weekly" },
      { "<leader>cM", "<cmd>IcalMonthly<cr>",  desc = "iCal Monthly" },
      { "<leader>cY", "<cmd>IcalYearly<cr>",   desc = "iCal Yearly" },
      { "<leader>ce", "<cmd>IcalNewEvent<cr>", desc = "New Event" },
      { "<leader>ct", "<cmd>IcalNewTask<cr>",  desc = "New Task" },
      { "<leader>cs", "<cmd>IcalSync<cr>",     desc = "Sync to calendar.vim" },
    },
    opts = {
      calendars = {
        { name = "My cal", path = "/home/simon/githubRepos/organization/calendar/source/", color = "#87CEEB", recursive = true }
        --{ name = "Work", path = "~/calendars/work.ics", color = "#FFD700" },
      },
    },
  },
}
