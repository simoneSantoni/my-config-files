return {
  {
    "simoneSantoni/ical.nvim",
    cmd = {
      "IcalAgenda",
      "IcalNewEvent",
      "IcalNewTask",
      "IcalSync",
    },
    keys = {
      { "<leader>ca", "<cmd>IcalAgenda<cr>",   desc = "iCal Agenda" },
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
