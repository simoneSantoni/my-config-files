return {
  "R-nvim/R.nvim",
  lazy = false,
  opts = function()
    -- Find R in PATH dynamically for cross-machine compatibility
    local r_path = vim.fn.exepath("R")
    if r_path == "" then
      r_path = "R" -- Fall back to PATH lookup at runtime
    end
    return {
      R_app = "R",
      R_cmd = r_path,
    }
  end,
}
